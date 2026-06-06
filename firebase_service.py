import os
from datetime import datetime, timezone

import firebase_admin
from firebase_admin import credentials, firestore


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVICE_ACCOUNT = os.path.join(BASE_DIR, "serviceAccountKey.json")

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)

db = firestore.client()


def check_valid_booking(user_id, device_id, check_time=False):
    bookings_ref = db.collection("bookings")

    query = (
        bookings_ref
        .where("userId", "==", user_id)
        .where("deviceId", "==", device_id)
        .where("status", "==", "approved")
        .stream()
    )

    now = datetime.now(timezone.utc)

    for doc in query:
        data = doc.to_dict()

        if not check_time:
            return doc.id, data

        start_time = data.get("startTime")
        end_time = data.get("endTime")

        if start_time and end_time and start_time <= now <= end_time:
            return doc.id, data

    return None, None


def update_device_in_use(device_id, user_id):
    db.collection("devices").document(device_id).update({
        "status": "in_use",
        "currentUserId": user_id,
        "updatedAt": firestore.SERVER_TIMESTAMP
    })


def update_device_ready(device_id):
    db.collection("devices").document(device_id).update({
        "status": "ready",
        "currentUserId": None,
        "currentUserName": None,
        "updatedAt": firestore.SERVER_TIMESTAMP
    })


def update_booking_status(booking_id, status):
    db.collection("bookings").document(booking_id).update({
        "status": status,
        "updatedAt": firestore.SERVER_TIMESTAMP
    })


def update_scan_request(request_id, data):
    db.collection("scanRequests").document(request_id).update({
        **data,
        "updatedAt": firestore.SERVER_TIMESTAMP
    })


if __name__ == "__main__":
    print("[TEST] Firebase connected OK")

    booking_id, booking_data = check_valid_booking(
        "VAwQ9sogfLTbE4fAUkiEbAQAUeh1",
        "dev01",
        check_time=False
    )

    print("VALID BOOKING:", booking_id)
    print(booking_data)