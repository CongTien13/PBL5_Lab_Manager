# PBL5 Lab Manager

A laboratory equipment management system with face recognition-based access control for a university lab environment.

## Overview

The PBL5 Lab Manager system provides secure, automated access control for laboratory equipment using face recognition authentication. Users can book laboratory devices through a mobile application, and their face is verified at the Raspberry Pi-controlled hardware station before device activation.

## Main Features

- **Face Recognition Authentication**: MobileFaceNet-based 128-dimensional embedding for user verification
- **Device Booking System**: Mobile app for reserving lab equipment (3D printers, microscopes, soldering stations)
- **Real-time Hardware Control**: Raspberry Pi controls relays and LEDs based on booking status
- **Role-based Access**: Separate admin and user interfaces
- **Firebase Backend**: Authentication, Firestore database, and Cloud Storage

## System Flow

```
1. User registers on app → uploads 5 face photos to Cloudinary → Firestore saves user + embeddingStatus = pending

2. AI Server (Windows) → detects pending users → generates embeddings using MobileFaceNet
   → saves to face_db.npy → syncs to Raspberry via SSH → updates status = done

3. User books device on app → creates booking with status = approved

4. User presses hardware button → Raspberry opens camera, scans face for 8 seconds

5. Raspberry recognizes face → compares against face_db.npy

6. Validates booking (correct user + correct device + correct time + approved)

7. If validated:
   - booking: approved → using
   - device: available → in_use
   - relay turns ON device

8. Raspberry monitors endTime → when time expires, relay turns OFF
   - booking = finished
   - device = available
```

## Technology Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter with flutter_bloc |
| AI Model | PyTorch, MobileFaceNet, MTCNN |
| Hardware | Raspberry Pi 4, Python, OpenCV |
| Backend | Firebase (Auth, Firestore, Storage) |
| Database | Cloud Firestore |

## Project Structure

```
PBL5_Lab_Manager/
├── ai_model/           # Face recognition model & training
│   ├── models/        # MobileFaceNet, FaceModel
│   ├── services/      # FaceDetector, FaceRecognition
│   ├── weights/     # Model weights, face_db.npy
│   ├── main.py       # Inference script
│   ├── update_db.py # Face database builder
│   └── sync_firestore_face_db.py  # Firebase sync + SSH upload
├── mobile_app/         # Flutter mobile application
│   └── lib/
│       ├── core/     # Models, services, theme
│       └── modules/  # Auth, home, lab, info
├── raspberry-sync/   # Raspberry Pi hardware control
│   ├── main.py       # Face scanning
│   ├── scan_listener.py  # Firestore listener
│   ├── hardware_gpio.py # GPIO control
│   ├── firebase_service.py # Firebase operations
│   └── weights/     # face_db.npy, model weights
└── docs/            # Documentation
```

## Supported Devices

| Device ID | Name | Location |
|----------|------|---------|
| dev01 | Ender 3 3D Printer | Lab bench 1 |
| dev02 | Microscope | Lab bench 2 |
| dev03 | Soldering Station | Lab bench 3 |

## Prerequisites

- Python 3.8+
- Flutter 3.0+
- Firebase project
- Raspberry Pi 4 with camera

## Network Configuration

| Setting | Value |
|---------|-------|
| Network Name | pitest |
| Password | 12345678 |
| Raspberry IP | 172.20.10.2 |

## Detailed Setup

### Step 1: Get serviceAccountKey.json from Firebase

1. Go to Firebase Console
2. Select your project
3. Project Settings → Service Accounts → Generate new private key
4. Download `serviceAccountKey.json`
5. Place in:
   - `ai_model/serviceAccountKey.json`
   - `raspberry-sync/serviceAccountKey.json`

### Step 2: Clone Source Code

```bash
git clone https://github.com/CongTien13/PBL5_Lab_Manager.git
cd PBL5_Lab_Manager
```

### Step 3: Create Virtual Environment

**Windows:**
```bash
cd ai_model
python -m venv myenv
myenv\Scripts\activate
```

**Raspberry Pi:**
```bash
cd raspberry-sync
python3 -m venv myenv
source myenv/bin/activate
```

### Step 4: Install Dependencies

**Windows (AI Model):**
```bash
pip install -r requirements.txt
```

**Raspberry Pi:**
```bash
pip install -r requirements.txt
pip install rpi-lgpio
sudo apt install python3-rpi.gpio
```

### Step 5: Test Firebase Connection

```bash
python firebase_service.py
```

Expected output:
```
[TEST] Firebase connected OK
```

### Step 6: Run AI Server (Windows)

This detects new pending users, generates embeddings, and syncs to Raspberry:

```bash
python sync_firestore_face_db.py
```

If no new users:
```
[WAIT] No pending users
```

If new users found:
```
[OK] Embedded
[UPLOAD] face_db.npy synced to Raspberry
[DONE]
```

### Step 7: Run Raspberry Listener

```bash
python scan_listener.py
```

Expected output:
```
[LISTENER] Raspberry scan listener started
[LISTENER] Waiting scanRequests or button press...
DEVICE_ID: dev01
```

### Step 8: Hardware Connection

**Relay Module:**
```
Pin 2   → Relay VCC
Pin 6   → Relay GND
Pin 13  → Relay IN1 (dev01)
Pin 16  → Relay IN2 (dev02)
Pin 18  → Relay IN3 (dev03)
```

**Push Button:**
```
Pin 11 → Button
Pin 9  → Button GND
```

**LEDs:**
```
Pin 22 → LED (dev01)
Pin 23 → LED (dev02)
Pin 24 → LED (dev03)
```

### Step 9: Test Relay

```bash
python
```

```python
from hardware_gpio import relay_on, relay_off

relay_on("dev01")  # Should click
relay_off("dev01") # Should click
```

### Step 10: Mobile App Setup

```bash
cd mobile_app
flutter pub get
flutter run
```

## Running the System

### 1. User Registration (Mobile App)

1. User creates account on app
2. Uploads 5 face photos
3. Firestore stores: `embeddingStatus = pending`

### 2. AI Server Processing

Automatically detects pending users and processes:
```
pending → processing → done
```

### 3. Device Booking (Mobile App)

1. User selects device
2. Selects date/time
3. Creates booking (status = pending)
4. Admin approves (status = approved)

### 4. Face Scanning

Two methods:
- Press hardware button
- Send scanRequest from app

### 5. Access Control

If face matches + valid booking:
```
approved → using
relay ON
device = in_use
```

### 6. Session End

When endTime reached:
```
relay OFF
using → finished
device = ready
```

## Hardware Testing Commands

### Check Camera on Raspberry

```bash
ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video0 \
-c:v libx264 -preset ultrafast -tune zerolatency \
-f mpegts tcp://0.0.0.0:8888?listen=1
```

View stream:
```
tcp://172.20.10.2:8888
```

### SSH Connection

```bash
ssh pi@172.20.10.2
# Password: 12345678
```

### Shutdown Raspberry

```bash
sudo shutdown now
```

## GPIO Pin Configuration

| GPIO Pin | Function | Device |
|---------|----------|--------|
| 17 | Input | Scan Button |
| 22 | Output | LED (dev01) |
| 23 | Output | LED (dev02) |
| 24 | Output | LED (dev03) |
| 27 | Output | Relay (dev01) |
| 5 | Output | Relay (dev02) |
| 6 | Output | Relay (dev03) |

## Documentation

- [System Architecture](docs/system-architecture.md)
- [AI Model Documentation](docs/ai-model.md)
- [Mobile App Documentation](docs/mobile-app.md)
- [Raspberry Sync Documentation](docs/raspberry-sync.md)
- [Database Schema](docs/database.md)
- [API Reference](docs/api.md)
- [Deployment Guide](docs/deployment.md)
- [Troubleshooting](docs/troubleshooting.md)

## Vietnamese Version

See [Vietnamese Documentation](docs/vi/)

## License

This project is for educational purposes as part of PBL5 course.