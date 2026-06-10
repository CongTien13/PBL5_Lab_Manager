# PBL5 Lab Manager - Codebase Summary

## Overview

This document provides a comprehensive summary of the PBL5 Lab Manager codebase, including the three main components: mobile_app, raspberry-sync, and ai_model.

## Project Structure

```
PBL5_Lab_Manager/
├── mobile_app/           # Flutter mobile application
│   └── lib/
│       ├── main.dart
│       ├── core/
│       │   ├── models/
│       │   ├── services/
│       │   ├── theme/
│       │   └── utils/
│       └── modules/
│           ├── auth/
│           ├── home/
│           ├── lab/
│           ├── info/
│           └── common/
├── raspberry-sync/      # Raspberry Pi hardware control
│   ├── main.py
│   ├── scan_listener.py
│   ├── hardware_gpio.py
│   ├── firebase_service.py
│   ├── camera_debug.py
│   └── requirements.txt
├── ai_model/            # Face recognition model
│   ├── main.py
│   ├── update_db.py
│   ├── sync_firestore_face_db.py
│   ├── models/
│   ├── services/
│   └── weights/
├── docs/               # Documentation
└── plans/              # Planning documents
```

## Mobile App (Flutter)

### Technology Stack

- **Framework**: Flutter 3.0+
- **State Management**: flutter_bloc (Cubit pattern)
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Face Detection**: google_mlkit_face_detection

### Key Files

| File | Purpose |
|------|---------|
| `main.dart` | App entry point, initializes services and cubits |
| `core/models/user_model.dart` | User data model |
| `core/models/device_model.dart` | Device data model |
| `core/models/booking_model.dart` | Booking data model |
| `core/services/auth_service.dart` | Firebase Auth operations |
| `core/services/firestore_service.dart` | Firestore CRUD operations |
| `modules/auth/presentation/application/cubit/auth_cubit.dart` | Authentication state management |
| `modules/home/presentation/application/cubit/device_cubit.dart` | Device list state |
| `modules/lab/presentation/application/cubit/booking_cubit.dart` | Booking management |

### Authentication Flow

1. **Login**: Email/password via Firebase Auth
2. **Registration**: 3-step process
   - Step 1: RegisterAccountPage (email, password)
   - Step 2: RegisterInfoPage (name, num, job, birthday)
   - Step 3: FaceScanPage (5 face photos)
3. **Auth Token Handling**: Waits for token ready before Firestore queries

### Booking Status Flow

```
pending -> approved -> using -> finished
              |
              v
           cancelled
```

## Raspberry Sync (Python)

### Technology Stack

- **Hardware**: Raspberry Pi 4, GPIO, Relay Module, LED, Button
- **Face Recognition**: MobileFaceNet, OpenCV
- **Backend**: Firebase Admin SDK

### Key Files

| File | Purpose |
|------|---------|
| `scan_listener.py` | Firestore listener, handles scan requests |
| `hardware_gpio.py` | GPIO control for relays and LEDs |
| `firebase_service.py` | Firestore operations |
| `main.py` | Face scanning logic |

### GPIO Pin Configuration

| GPIO Pin | Function | Device |
|---------|----------|--------|
| 26 | Input | Scan Button |
| 18 | Output | LED (dev01) |
| 23 | Output | LED (dev02) |
| 24 | Output | LED (dev03) |
| 17 | Output | Relay (dev01 - 3D Printer) |
| 27 | Output | Relay (dev02 - Microscope) |
| 22 | Output | Relay (dev03 - Soldering) |

### Device Configuration

```python
DEVICE_CONFIG = {
    "dev01": {
        "relay": 17,
        "led": 18,
        "name": "Máy in 3D Ender 3"
    },
    "dev02": {
        "relay": 27,
        "led": 23,
        "name": "Kính hiển vi"
    },
    "dev03": {
        "relay": 22,
        "led": 24,
        "name": "Trạm hàn"
    },
}
```

### Key Functions

| Function | Purpose |
|----------|---------|
| `check_valid_booking()` | Check valid booking for specific device |
| `check_all_valid_bookings()` | Check all valid bookings across devices |
| `update_device_in_use()` | Update device status to in_use |
| `finish_booking_and_release_device()` | Mark booking finished, reset device |
| `handle_scan_request()` | Process scan request |
| `monitor_device_until_end()` | Monitor device until booking end |

### Scan Flow

1. Listen for scan requests or button press
2. Perform 8-second face scan with voting
3. Recognize face against face_db.npy
4. Check for valid bookings
5. Activate relay(s) for valid devices
6. Monitor until booking end time

## AI Model (Python)

### Technology Stack

- **Framework**: PyTorch
- **Face Detection**: MTCNN
- **Model**: MobileFaceNet (128-dim embeddings)
- **Backend**: Firebase Admin SDK

### Key Files

| File | Purpose |
|------|---------|
| `main.py` | Real-time face recognition |
| `update_db.py` | Build face_db.npy from images |
| `sync_firestore_face_db.py` | Sync from Firebase + SSH upload |
| `models/mobilefacenet.py` | MobileFaceNet architecture |
| `models/face_model.py` | FaceModel wrapper |
| `services/face_detector.py` | MTCNN face detector |

### Recognition Algorithm

- Uses cosine similarity matching
- Threshold: 0.05 (Raspberry Pi), 0.5 (local inference)
- 128-dimensional embeddings

## Firestore Collections

### users Collection

```json
{
  "uid": {
    "name": "string",
    "email": "string",
    "role": "user|admin",
    "num": "string",
    "job": "string",
    "birthday": "string",
    "faceImageUrls": ["url1", ...],
    "embeddingStatus": "pending|processing|done|failed",
    "embeddingUpdatedAt": "timestamp"
  }
}
```

### devices Collection

```json
{
  "deviceId": {
    "name": "string",
    "status": "ready|in_use|maintenance",
    "currentUserId": "string|null",
    "currentUserName": "string|null",
    "updatedAt": "timestamp"
  }
}
```

### bookings Collection

```json
{
  "bookingId": {
    "userId": "string",
    "userName": "string",
    "deviceId": "string",
    "deviceName": "string",
    "startTime": "timestamp",
    "endTime": "timestamp",
    "status": "pending|approved|using|finished|cancelled",
    "createdAt": "timestamp",
    "updatedAt": "timestamp",
    "approvedAt": "timestamp|null",
    "finishedAt": "timestamp|null"
  }
}
```

### scanRequests Collection

```json
{
  "requestId": {
    "userId": "string|null",
    "deviceId": "string",
    "status": "pending|scanning|success|denied|failed|error",
    "recognizedUserId": "string|null",
    "score": "number|null",
    "bookingId": "string|null",
    "message": "string",
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

## Recent Code Updates

### 1. GPIO Pin Assignments (Latest Commit)

Changed from:
- Button: GPIO 17 -> GPIO 26
- Relay dev01: GPIO 27 -> GPIO 17
- LED dev01: GPIO 22 -> GPIO 18
- Relay dev02: GPIO 5 -> GPIO 27
- Relay dev03: GPIO 6 -> GPIO 22

### 2. Auth Token Handling

Added in `main.dart`:
```dart
final currentUserCheck = FirebaseAuth.instance.currentUser;
if (currentUserCheck != null) {
  await currentUserCheck.getIdTokenResult(true);
}
```

### 3. check_all_valid_bookings()

Added in `firebase_service.py`:
- Checks all valid bookings for a user across all devices
- Enables multi-device activation from single scan

### 4. User Name Handling

- Added `userName` field in bookings
- Added `deviceName` field in bookings
- Added `currentUserName` field in devices

## Data Flow Summary

### User Registration

1. User creates account (email/password)
2. User fills profile info
3. User captures 5 face photos
4. Photos uploaded to Firebase Storage
5. AI model extracts embeddings
6. Embeddings uploaded to Raspberry Pi

### Device Booking

1. User books device via mobile app
2. Booking created with status "pending"
3. Admin approves booking
4. User goes to lab and presses button
5. Raspberry Pi scans face
6. Valid booking verified
7. Device relay turned on
8. Device status updated to "in_use"
9. Monitoring until booking end
10. Device released, booking marked "finished"

## Dependencies

### Mobile App (pubspec.yaml)

- firebase_core: ^2.0.0
- firebase_auth: ^4.0.0
- cloud_firestore: ^4.0.0
- firebase_storage: ^11.0.0
- flutter_bloc: ^8.0.0
- equatable: ^2.0.0
- google_mlkit_face_detection: ^0.5.0

### Raspberry Sync (requirements.txt)

- torch
- opencv-python
- numpy
- firebase-admin
- RPi.GPIO

### AI Model (requirements.txt)

- torch
- torchvision
- facenet-pytorch
- mtcnn
- opencv-python
- numpy
- firebase-admin
- requests
- paramiko

## Last Updated

This summary was generated based on the current codebase structure as of the latest commits.