import time
from firebase_admin import firestore

from main import scan_face_once
from firebase_service import (
    db,
    check_valid_booking,
    update_device_in_use,
    update_booking_status,
    update_scan_request
)


DEVICE_ID = "dev01"

is_scanning = False
processed_requests = set()


def handle_scan_request(doc_id, data):
    global is_scanning

    if is_scanning:
        print("[BUSY] Đang quét, bỏ qua request mới")
        return

    is_scanning = True

    try:
        request_user_id = data.get("userId")
        device_id = data.get("deviceId")

        print("\n========== NEW SCAN REQUEST ==========")
        print("Request ID:", doc_id)
        print("Request userId:", request_user_id)
        print("Device ID:", device_id)

        if device_id != DEVICE_ID:
            print("[SKIP] Request không thuộc thiết bị này")
            return

        update_scan_request(doc_id, {
            "status": "scanning",
            "message": "Raspberry đang quét khuôn mặt"
        })

        scan_result = scan_face_once()

        if not scan_result["success"]:
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

        if recognized_user_id != request_user_id:
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
            check_time=False
        )

        if booking_id is None:
            update_scan_request(doc_id, {
                "status": "denied",
                "recognizedUserId": recognized_user_id,
                "score": score,
                "message": "Không có lịch đặt hợp lệ"
            })
            print("[DENIED] Không có booking hợp lệ")
            return

        update_device_in_use(DEVICE_ID, recognized_user_id)
        update_booking_status(booking_id, "using")

        update_scan_request(doc_id, {
            "status": "success",
            "recognizedUserId": recognized_user_id,
            "score": score,
            "bookingId": booking_id,
            "message": "Xác thực thành công, thiết bị đã được mở"
        })

        print("[AUTHORIZED] Xác thực thành công")
        print("[RELAY] Tới đây bật relay GPIO")

    except Exception as e:
        print("[ERROR]", e)

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
    print("[LISTENER] Waiting scanRequests...")
    print("DEVICE_ID:", DEVICE_ID)

    query = (
        db.collection("scanRequests")
        .where("deviceId", "==", DEVICE_ID)
        .where("status", "==", "pending")
    )

    query.on_snapshot(on_snapshot)

    while True:
        time.sleep(1)


if __name__ == "__main__":
    main()