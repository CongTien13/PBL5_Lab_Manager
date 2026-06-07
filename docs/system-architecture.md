# System Architecture

## Overview

The PBL5 Lab Manager system consists of three main components that communicate through Firebase as the central data store:

1. **Mobile App** - Flutter-based client for user authentication, booking, and device monitoring
2. **AI Model Server** - PyTorch-based face recognition model for embedding generation
3. **Raspberry Pi Station** - Hardware controller with face scanning capability

## High-Level Architecture

```mermaid
flowchart TB
    subgraph Mobile["Mobile App (Flutter)"]
        Auth[Authentication]
        Booking[Booking UI]
        Device[Device Status]
    end

    subgraph Firebase["Firebase Backend"]
        AuthService[Firebase Auth]
        Firestore[Firestore DB]
        Storage[Cloud Storage]
    end

    subgraph AIBackend["AI Model Server"]
        Main[main.py]
        UpdateDB[update_db.py]
        Sync[sync_firestore_face_db.py]
    end

    subgraph Raspberry["Raspberry Pi Station"]
        Listener[scan_listener.py]
        Hardware[hardware_gpio.py]
        Camera[OpenCV Camera]
    end

    Mobile -->|Email/Password| AuthService
    Mobile -->|Read/Write| Firestore
    Mobile -->|Upload Images| Storage
    Storage -->|Face Images| Firestore

    Firestore -->|New User| Main
    Main -->|Face DB| Sync
    Sync -->|SSH Upload| Raspberry
    Raspberry -->|Scan Request| Firestore
    Raspberry -->|Relay Control| Hardware
```

## Data Flow Diagram

### User Registration Flow

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Mobile App
    participant Firebase as Firebase
    participant AI as AI Model Server
    participant Raspberry as Raspberry Pi

    User->>Mobile: Register with 5 face photos
    Mobile->>Firebase: Upload images to Storage
    Firebase-->>Mobile: Return image URLs
    Mobile->>Firebase: Create user with faceImageUrls
    Firebase->>AI: Poll for pending users
    AI->>Firebase: Download face images
    AI->>AI: Generate 128-dim embeddings
    AI->>AI: Build face_db.npy
    AI->>Raspberry: SSH upload face_db.npy
```

### Device Access Flow

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Mobile App
    participant Firebase as Firebase
    participant Raspberry as Raspberry Pi

    User->>Mobile: Book device (dev01)
    Mobile->>Firebase: Create booking
    Firebase-->>Mobile: Booking approved

    User->>Raspberry: Press scan button
    Raspberry->>Raspberry: Scan face (8 seconds)
    Raspberry->>Raspberry: Match against face_db
    Raspberry->>Firebase: Check valid booking

    alt Booking valid
        Raspberry->>Raspberry: Turn on relay + LED
        Raspberry->>Firebase: Update device status = in_use
    else No booking
        Raspberry->>Raspberry: Blink LED (denied)
    end
```

## Component Architecture

### Mobile App Architecture

```mermaid
flowchart TB
    subgraph Presentation
        Login[Login Page]
        Register[Registration Pages]
        Home[Home Page]
        Lab[Lab/Booking Page]
        Info[Info/Settings Page]
    end

    subgraph State["State Management (flutter_bloc)"]
        AuthCubit[AuthCubit]
        DeviceCubit[DeviceCubit]
        BookingCubit[BookingCubit]
        AdminBookingCubit[AdminBookingCubit]
    end

    subgraph Data["Data Layer"]
        AuthRepo[AuthRepository]
        HomeRepo[HomeRepository]
        LabRepo[LabRepository]
    end

    subgraph Services
        AuthService[AuthService]
        FirestoreService[FirestoreService]
    end

    Presentation --> State
    State --> Data
    Data --> Services
    Services --> Firebase
```

### AI Model Pipeline

```mermaid
flowchart LR
    subgraph Input
        Image[Face Image URL]
    end

    subgraph Detection["MTCNN Face Detection"]
        Detect[Detect face]
        Crop[Crop to 112x112]
    end

    subgraph Embedding["MobileFaceNet"]
        Forward[Forward pass]
        Extract[Extract 128-dim]
    end

    subgraph Output
        Embed[Face Embedding]
    end

    Image --> Detect
    Detect --> Crop
    Crop --> Forward
    Forward --> Extract
    Extract --> Embed
```

### Raspberry Pi State Machine

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Pending: Scan request received
    Pending --> Scanning: Start 8-second scan
    Scanning --> Success: Face recognized + valid booking
    Scanning --> Denied: Face not recognized
    Scanning --> Failed: No face detected
    Success --> DeviceOn: Relay ON
    DeviceOn --> Idle: Booking ended
    Denied --> Idle: Blink LED
    Failed --> Idle: Blink LED
```

## Network Architecture

```mermaid
flowchart TB
    subgraph LAN["Lab Network 172.20.10.0/24"]
        RPI["Raspberry Pi\n172.20.10.2"]
        Cam["USB Camera"]
        Relay["Relay Module"]
        LED["Status LED"]
        Button["Scan Button"]
    end

    subgraph Cloud["Internet"]
        Firebase["Firebase\n(Auth, Firestore, Storage)"]
    end

    subgraph Server["AI Model Server"]
        AI["Python Scripts\n(main.py, update_db.py)"]
    end

    RPI --> Cam
    RPI --> Relay
    RPI --> LED
    RPI --> Button
    RPI -->|HTTPS| Firebase
    AI -->|SSH| RPI
    AI -->|HTTPS| Firebase
```

## Security Considerations

1. **Face Data**: Stored as 128-dimensional embeddings, not raw images
2. **SSH Access**: Raspberry Pi accessible only within local network
3. **Firebase Rules**: Role-based access control in Firestore security rules
4. **Booking Validation**: Time-based validation prevents unauthorized access

## Hardware Pin Configuration

| GPIO Pin | Function | Device |
|---------|----------|--------|
| 17 | Input | Scan Button |
| 22 | Output | LED (dev01) |
| 23 | Output | LED (dev02) |
| 24 | Output | LED (dev03) |
| 27 | Output | Relay (dev01) |
| 5 | Output | Relay (dev02) |
| 6 | Output | Relay (dev03) |

## Component Communication

| From | To | Protocol | Data |
|------|-------|---------|------|
| Mobile App | Firebase | REST API | User, Booking, Device data |
| AI Model | Firebase | REST API | User embeddings |
| AI Model | Raspberry | SFTP (SSH) | face_db.npy |
| Raspberry | Firebase | Firestore SDK | Scan requests, device status |
| Raspberry | Hardware | GPIO | Relay, LED control |

## Deployment Topology

```mermaid
flowchart TB
    subgraph Lab["Laboratory"]
        Desk1["Desk 1 - Ender 3"]
        Desk2["Desk 2 - Microscope"]
        Desk3["Desk 3 - Soldering"]
    end

    subgraph PiStation["Raspberry Pi"]
        RPI1["RPI dev01"]
        RPI2["RPI dev02"]
        RPI3["RPI dev03"]
    end

    subgraph Cloud["Firebase Cloud"]
        FB["Firebase Project"]
    end

    subgraph MobileUsers["Mobile Users"]
        Phone1["User Phone"]
        Phone2["Admin Phone"]
    end

    Desk1 --> RPI1
    Desk2 --> RPI2
    Desk3 --> RPI3
    RPI1 --> FB
    RPI2 --> FB
    RPI3 --> FB
    Phone1 --> FB
    Phone2 --> FB
```