import time
from firebase_admin import firestore

from main import scan_face_once

import threading
from datetime import datetime, timezone

from hardware_gpio import (
    is_button_pressed,
    relay_on,
    relay_off,
    blink_led,
    cleanup_gpio,
    DEVICE_CONFIG
)

from firebase_service import (
    db,
    check_valid_booking,
    check_all_valid_bookings,
    update_device_in_use,
    update_booking_status,
    update_scan_request,
    finish_booking_and_release_device
)

# Support all 3 devices
SUPPORTED_DEVICES = list(DEVICE_CONFIG.keys())

is_scanning = False
processed_requests = set()



active_devices = {}


def monitor_device_until_end(device_id, booking_id, end_time):
    print(f"[MONITOR] {device_id} sẽ bật tới {end_time}")

    relay_on(device_id)

    last_warn_log = False

    while True:
        now = datetime.now(timezone.utc)

        if now >= end_time:
            print(f"[MONITOR] {device_id} hết giờ, tắt relay")

            relay_off(device_id)

            finish_booking_and_release_device(
                booking_id,
                device_id
            )

            active_devices.pop(device_id, None)
            break

        # Blink LED when 10 minutes remaining
        diff = end_time - now
        mins_left = diff.total_seconds() / 60

        if mins_left <= 10:
            if not last_warn_log:
                print(f"[WARN] {device_id}: Còn 10 phút!")
                last_warn_log = True
            blink_led(device_id, times=1, delay=0.3)
        else:
            last_warn_log = False

        time.sleep(1)


def restore_active_devices():
    print("[RESTORE] Checking active devices...")

    found = False

    for device_id in SUPPORTED_DEVICES:
        docs = (
            db.collection("bookings")
            .where("deviceId", "==", device_id)
            .where("status", "==", "using")
            .stream()
        )

        for doc in docs:
            found = True

            booking_data = doc.to_dict()
            booking_id = doc.id
            end_time = booking_data.get("endTime")

            if end_time is None:
                continue

            now = datetime.now(timezone.utc)

            # nếu còn thời gian sử dụng
            if now < end_time:
                print(f"[RESTORE] Resume booking {booking_id} for {device_id}")

                active_devices[device_id] = booking_id

                t = threading.Thread(
                    target=monitor_device_until_end,
                    args=(device_id, booking_id, end_time),
                    daemon=True
                )
                t.start()

            else:
                print(f"[RESTORE] Booking hết giờ -> cleanup")

                finish_booking_and_release_device(
                    booking_id,
                    device_id
                )

    if not found:
        print("[RESTORE] Không có device đang using")

def handle_scan_request(doc_id, data):
    global is_scanning

    if is_scanning:
        print("[BUSY] Đang quét, bỏ qua request mới")
        return

    is_scanning = True

    try:
        request_user_id = data.get("userId")
        device_id = data.get("deviceId")
        is_hardware_button = doc_id == "hardware-button"

        print("\n========== NEW SCAN REQUEST ==========")
        print("Request ID:", doc_id)
        print("Request userId:", request_user_id)
        print("Device ID:", device_id)

        # Support all devices
        if device_id not in SUPPORTED_DEVICES:
            print("[SKIP] Request không thuộc thiết bị được hỗ trợ")
            return

        if not is_hardware_button:
            update_scan_request(doc_id, {
                "status": "scanning",
                "message": "Raspberry đang quét khuôn mặt"
            })
        scan_result = scan_face_once()

        if not scan_result["success"]:
            blink_led(device_id)

            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "failed",
                    "recognizedUserId": None,
                    "score": None,
                    "message": scan_result["message"]
                })
            return

        recognized_user_id = scan_result["userId"]
        score = scan_result["score"]

        print("[INFO] Recognized user:", recognized_user_id)
        print("[INFO] Checking booking...")

        if request_user_id is not None and recognized_user_id != request_user_id:
            blink_led(device_id)
            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "denied",
                    "recognizedUserId": recognized_user_id,
                    "score": score,
                    "message": "Khuôn mặt không khớp với tài khoản đang yêu cầu"
                })
            print("[DENIED] Face không khớp user bấm quét")
            return

        # Check all valid bookings for this user across all devices
        valid_bookings = check_all_valid_bookings(
            recognized_user_id,
            check_time=True
        )

        if not valid_bookings:
            blink_led(device_id)

            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "denied",
                    "recognizedUserId": recognized_user_id,
                    "score": score,
                    "message": "Không có lịch đặt hợp lệ"
                })
            print("[DENIED] Không có booking hợp lệ")
            return

        print(f"[INFO] Tìm thấy {len(valid_bookings)} booking hợp lệ")

        # Activate all valid devices
        for booking_id, booking_data in valid_bookings:
            device_id = booking_data.get("deviceId")
            end_time = booking_data.get("endTime")

            if end_time is None:
                print(f"[ERROR] Booking {booking_id} không có endTime")
                continue

            if device_id in active_devices:
                print(f"[INFO] Device {device_id} đã đang active, bỏ qua")
                continue

            update_device_in_use(device_id, recognized_user_id)
            update_booking_status(booking_id, "using")

            active_devices[device_id] = booking_id

            t = threading.Thread(
                target=monitor_device_until_end,
                args=(device_id, booking_id, end_time),
                daemon=True
            )

            t.start()

            print(f"[AUTHORIZED] Device {device_id} - relay bật tới {end_time}")

        if not is_hardware_button:
            update_scan_request(doc_id, {
                "status": "success",
                "recognizedUserId": recognized_user_id,
                "score": score,
                "message": f"Xác thực thành công, {len(valid_bookings)} thiết bị đã được mở"
            })

        print(f"[AUTHORIZED] Tổng cộng {len(valid_bookings)} relay sẽ bật")

    except Exception as e:
        print("[ERROR]", e)

        if not is_hardware_button:
            update_scan_request(doc_id, {
                "status": "error",
                "message": str(e)
            })

    finally:
        is_scanning = False
        print("========== END SCAN REQUEST ==========\n")


def on_snapshot(col_snapshot, changes, read_time):
    for change in changes:
        doc = change.document
        data = doc.to_dict()

        if change.type.name not in ["ADDED", "MODIFIED"]:
            continue

        if doc.id in processed_requests:
            continue

        device_id = data.get("deviceId")
        if device_id not in SUPPORTED_DEVICES:
            continue

        if data.get("status") != "pending":
            continue

        processed_requests.add(doc.id)

        handle_scan_request(doc.id, data)


def on_device_snapshot(col_snapshot, changes, read_time):
    """Listen for device status changes from mobile app."""
    print(f"[DEVICE] on_device_snapshot called, changes: {len(changes)}")

    for change in changes:
        print(f"[DEVICE] change type: {change.type.name}")
        if change.type.name not in ["ADDED", "MODIFIED"]:
            continue

        doc = change.document
        device_id = doc.id
        data = doc.to_dict()

        print(f"[DEVICE] doc: {device_id}, data: {data}")

        if device_id not in SUPPORTED_DEVICES:
            print(f"[DEVICE] {device_id} not in SUPPORTED_DEVICES")
            continue

        status = data.get("status")
        print(f"[DEVICE] {device_id} status changed to: {status}")

        if status == "ready":
            if device_id in active_devices:
                booking_id = active_devices.pop(device_id)
                print(f"[DEVICE] {device_id} released by mobile app, booking: {booking_id}")

            relay_off(device_id)
            print(f"[DEVICE] {device_id} relay OFF (released from mobile)")


def main():
    print("[LISTENER] Raspberry scan listener started")
    print("[LISTENER] Waiting scanRequests or button press...")
    print("SUPPORTED_DEVICES:", SUPPORTED_DEVICES)

    restore_active_devices()

    # Listen for device status changes from mobile app (release device)
    # Use a query that matches all devices (always true filter)
    db.collection("devices").where("status", "!=", "").on_snapshot(on_device_snapshot)

    # Listen for scan requests on all supported devices
    for device_id in SUPPORTED_DEVICES:
        query = (
            db.collection("scanRequests")
            .where("deviceId", "==", device_id)
            .where("status", "==", "pending")
        )
        query.on_snapshot(on_snapshot)

    last_press = 0

    while True:
        if is_button_pressed():
            now = time.time()

            if now - last_press > 2:
                print("[BUTTON] Nút được bấm, bắt đầu quét")

                # For hardware button, cycle through devices or use dev01
                handle_scan_request("hardware-button", {
                    "userId": None,
                    "deviceId": SUPPORTED_DEVICES[0]
                })

                last_press = now

        time.sleep(0.1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("[STOP] Đang tắt chương trình...")
        cleanup_gpio()