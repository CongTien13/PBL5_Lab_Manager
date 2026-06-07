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
│   ├── main.py       # Inference script
│   ├── update_db.py   # Face database builder
│   └── sync_firestore_face_db.py  # Firebase sync
├── mobile_app/         # Flutter mobile application
│   └── lib/
│       ├── core/     # Models, services, theme
│       └── modules/  # Auth, home, lab, info
├── raspberry-sync/   # Raspberry Pi hardware control
│   ├── main.py       # Face scanning
│   ├── scan_listener.py  # Firestore listener
│   ├── hardware_gpio.py # GPIO control
│   └── firebase_service.py # Firebase operations
└── docs/            # Documentation
```

## Supported Devices

| Device ID | Name | Location |
|----------|------|---------|
| dev01 | Ender 3 3D Printer | Lab bench 1 |
| dev02 | Microscope | Lab bench 2 |
| dev03 | Soldering Station | Lab bench 3 |

## Quick Start

### Prerequisites

- Python 3.8+
- Flutter 3.0+
- Firebase project
- Raspberry Pi 4 with camera

### Setup AI Model

```bash
cd ai_model
pip install -r requirements.txt
```

### Setup Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

### Setup Raspberry Pi

```bash
cd raspberry-sync
pip install -r requirements.txt
python main.py
```

## Documentation

- [System Architecture](system-architecture.md)
- [AI Model Documentation](ai-model.md)
- [Mobile App Documentation](mobile-app.md)
- [Raspberry Sync Documentation](raspberry-sync.md)
- [Database Schema](database.md)
- [API Reference](api.md)
- [Deployment Guide](deployment.md)
- [Troubleshooting](troubleshooting.md)

## License

This project is for educational purposes as part of PBL5 course.