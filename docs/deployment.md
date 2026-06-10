# Deployment Guide

## Overview

This guide covers local development setup and production deployment for all PBL5 Lab Manager components.

## Prerequisites

| Component | Requirement |
|-----------|------------|
| Python | 3.8+ |
| Flutter | 3.0+ |
| Node.js | 16+ |
| Firebase CLI | Latest |
| Raspberry Pi OS | Latest (Raspberry Pi 4) |

## Firebase Project Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: `pbl5-lab`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Enable Services

In Firebase Console:

1. **Authentication**: Build -> Authentication -> Get started -> Enable Email/Password
2. **Firestore**: Build -> Firestore Database -> Create database -> Start in production mode
3. **Storage**: Build -> Storage -> Get started -> Start in production mode

### 3. Create Service Account

1. Project Settings -> Service accounts
2. Click "Generate new private key"
3. Download `serviceAccountKey.json`
4. Place in:
   - `ai_model/serviceAccountKey.json`
   - `raspberry-sync/serviceAccountKey.json`

### 4. Configure Firebase App

1. Project Overview -> Add app -> Web (</>)
2. Register app
3. Copy Firebase config object

## AI Model Server Setup

### Local Development

```bash
# Navigate to AI model directory
cd ai_model

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Download model weights
# Place last_checkpoint.pth in ai_model/weights/
```

### Dependencies

```
torch
torchvision
facenet-pytorch
mtcnn
opencv-python
numpy
firebase-admin
requests
paramiko
```

### Configuration

Edit `ai_model/main.py`:

```python
RASPBERRY_HOST = "172.20.10.2"  # Raspberry Pi IP
RASPBERRY_USER = "pi"
RASPBERRY_PASSWORD = "12345678"
RASPBERRY_DB_PATH = "/home/pi/Desktop/PBL5_HARDWARE/weights/face_db.npy"
```

### Running

```bash
# Start sync service
python sync_firestore_face_db.py
```

## Mobile App Setup

### Prerequisites

1. Install Flutter SDK
2. Install Android Studio / Xcode

### Configuration

Update `mobile_app/lib/firebase_options.dart`:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "pbl5-lab",
      storageBucket: "pbl5-lab.appspot.com",
    );
  }
}
```

### Build for Android

```bash
cd mobile_app

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release
```

### Build for iOS

```bash
# Open iOS simulator
open -a Simulator

# Run on simulator
flutter run
```

### Build for Web

```bash
flutter build web
```

## Raspberry Pi Setup

### OS Installation

1. Download Raspberry Pi Imager
2. Select Raspberry Pi OS (64-bit)
3. Write to SD card
4. Configure Wi-Fi and SSH

### Initial Setup

```bash
# Update system
sudo apt update
sudo apt upgrade

# Enable camera
sudo raspi-config
# Interface Options -> Camera -> Yes
```

### Install Dependencies

```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Install OpenCV
sudo apt install libopencv-dev

# Install GPIO library
sudo apt install python3-rpi.gpioi
```

### Dependencies

```
torch
opencv-python
numpy
firebase-admin
RPi.GPIO
```

### Configure Service Account

Place `serviceAccountKey.json` in the project directory.

### Hardware Setup

Connect components:
- GPIO 26 -> Scan Button (with pull-up resistor)
- GPIO 18 -> LED (dev01) + 330 ohm resistor
- GPIO 17 -> Relay (dev01) -> Device power

### Running

```bash
# Start scan listener
python3 scan_listener.py

# Or as systemd service
sudo systemctl enable pbl5.service
sudo systemctl start pbl5.service
```

## Network Configuration

### Lab Network

Configure router:

| Setting | Value |
|---------|-------|
| Subnet | 172.20.10.0/24 |
| Gateway | 172.20.10.1 |
| DHCP Range | 172.20.10.100 - 172.20.10.200 |

### Static IP (Raspberry Pi)

Edit `/etc/dhcpcd.conf`:

```conf
interface eth0
static ip_address=172.20.10.2/24
static routers=172.20.10.1
static domain_name_servers=172.20.10.1
```

## Environment Variables

### AI Model

```bash
export RASPBERRY_HOST="172.20.10.2"
export RASPBERRY_USER="pi"
export RASPBERRY_PASSWORD="12345678"
```

### Mobile App

Configure in `firebase_options.dart` or `.env` file.

## Security

### Firestore Rules

See [Database Documentation](database.md#security-rules)

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /faces/{uid}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### Network Security

1. Disable SSH password authentication
2. Use key-based SSH only
3. Configure firewall:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
```

## Monitoring

### Logs

#### Raspberry Pi

```bash
# View logs
journalctl -u pbl5 -f

# Or
tail -f /var/log/pbl5.log
```

#### Firebase

View in Firebase Console:
- Firestore -> Logs
- Storage -> Logs
- Authentication -> Logs

### Health Checks

Create a health check endpoint:

```python
from flask import Flask

app = Flask(__name__)

@app.route('/health')
def health():
    return {'status': 'ok'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

## Backup

### Firestore Export

```bash
gcloud firestore export gs://pbl5-lab-backup/$(date +%Y%m%d)
```

### Face Database Backup

```bash
# On AI server
cp ai_model/weights/face_db.npy face_db_backup_$(date +%Y%m%d).npy

# Upload to cloud storage
gsutil cp face_db_backup_*.npy gs://pbl5-lab-backup/
```

## Production Checklist

- [ ] Firebase project created
- [ ] Authentication enabled
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Service account configured
- [ ] AI model weights downloaded
- [ ] Mobile app built
- [ ] Raspberry Pi configured
- [ ] Hardware connected
- [ ] Network configured
- [ ] Security rules applied
- [ ] Monitoring enabled
- [ ] Backups scheduled

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md)