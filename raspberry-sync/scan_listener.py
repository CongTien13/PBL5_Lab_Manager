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
    cleanup_gpio
)

from firebase_service import (
    db,
    check_valid_booking,
    update_device_in_use,
    update_booking_status,
    update_scan_request,
    finish_booking_and_release_device
)

DEVICE_ID = "dev01"

is_scanning = False
processed_requests = set()



active_devices = {}


def monitor_device_until_end(device_id, booking_id, end_time):
    print(f"[MONITOR] {device_id} sẽ bật tới {end_time}")

    relay_on(device_id)

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

        time.sleep(1)


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

        if device_id != DEVICE_ID:
            print("[SKIP] Request không thuộc thiết bị này")
            return

        if not is_hardware_button:
            update_scan_request(doc_id, {
                "status": "scanning",
                "message": "Raspberry đang quét khuôn mặt"
            })
        scan_result = scan_face_once()

        if not scan_result["success"]:
            blink_led(DEVICE_ID)

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
            blink_led(DEVICE_ID)
            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "denied",
                    "recognizedUserId": recognized_user_id,
                    "score": score,
                    "message": "Khuôn mặt không khớp với tài khoản đang yêu cầu"
                })
            print("[DENIED] Face không khớp user bấm quét")
            return

        booking_id, booking_data = check_valid_booking(
            recognized_user_id,
            DEVICE_ID,
            check_time=True
        )

        if booking_id is None:
            blink_led(DEVICE_ID)

            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "denied",
                    "recognizedUserId": recognized_user_id,
                    "score": score,
                    "message": "Không có lịch đặt hợp lệ"
                })
            print("[DENIED] Không có booking hợp lệ")
            return
 
        end_time = booking_data.get("endTime")

        if end_time is None:
            print("[ERROR] Booking không có endTime")
            blink_led(DEVICE_ID)

            if not is_hardware_button:
                update_scan_request(doc_id, {
                    "status": "error",
                    "recognizedUserId": recognized_user_id,
                    "score": score,
                    "bookingId": booking_id,
                    "message": "Booking không có endTime"
                })
            return

        update_device_in_use(DEVICE_ID, recognized_user_id)
        update_booking_status(booking_id, "using")

        if not is_hardware_button:
            update_scan_request(doc_id, {
                "status": "success",
                "recognizedUserId": recognized_user_id,
                "score": score,
                "bookingId": booking_id,
                "message": "Xác thực thành công, thiết bị đã được mở"
            })

        print("[AUTHORIZED] Xác thực thành công")
  
        if DEVICE_ID not in active_devices:
            active_devices[DEVICE_ID] = booking_id

            t = threading.Thread(
                target=monitor_device_until_end,
                args=(DEVICE_ID, booking_id, end_time),
                daemon=True
            )

            t.start()

        print("[AUTHORIZED] Relay sẽ bật tới khi hết giờ booking")

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

        if data.get("deviceId") != DEVICE_ID:
            continue

        if data.get("status") != "pending":
            continue

        processed_requests.add(doc.id)

        handle_scan_request(doc.id, data)


def main():
    print("[LISTENER] Raspberry scan listener started")
    print("[LISTENER] Waiting scanRequests or button press...")
    print("DEVICE_ID:", DEVICE_ID)

    query = (
        db.collection("scanRequests")
        .where("deviceId", "==", DEVICE_ID)
        .where("status", "==", "pending")
    )

    query.on_snapshot(on_snapshot)

    last_press = 0

    while True:
        if is_button_pressed():
            now = time.time()

            if now - last_press > 2:
                print("[BUTTON] Nút được bấm, bắt đầu quét")

                handle_scan_request("hardware-button", {
                    "userId": None,
                    "deviceId": DEVICE_ID
                })

                last_press = now

        time.sleep(0.1)


if __name__ == "__main__":
    main()