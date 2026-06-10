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

## Sequence Diagrams

### 1. User Registration Flow

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Mobile App
    participant Firebase as Firebase
    participant Storage as Cloud Storage
    participant AI as AI Model Server
    participant Raspberry as Raspberry Pi

    Note over User,Mobile: Step 1: Create Account
    User->>Mobile: Enter email, password
    Mobile->>Firebase: createUserWithEmailAndPassword()
    Firebase-->>Mobile: User created

    Note over User,Mobile: Step 2: Register Info
    User->>Mobile: Enter name, num, job, birthday
    Mobile->>Firebase: Create user document

    Note over User,Mobile: Step 3: Face Scan
    User->>Mobile: Take 5 face photos
    Mobile->>Storage: Upload face_0.jpg
    Mobile->>Storage: Upload face_1.jpg
    Mobile->>Storage: Upload face_2.jpg
    Mobile->>Storage: Upload face_3.jpg
    Mobile->>Storage: Upload face_4.jpg
    Storage-->>Mobile: Return 5 image URLs
    Mobile->>Firebase: Update user.faceImageUrls
    Mobile->>Firebase: Update user.embeddingStatus = "pending"

    Note over AI: Background Process
    AI->>Firebase: Poll for pending users
    AI->>Firebase: Get user faceImageUrls
    AI->>Storage: Download all images
    AI->>AI: Extract 128-dim embeddings
    AI->>AI: Build face_db.npy
    AI->>Raspberry: SSH upload face_db.npy
    AI->>Firebase: Update embeddingStatus = "done"
```

### 2. Device Booking Flow

```mermaid
sequenceDiagram
    participant User
    participant Mobile as Mobile App
    participant Firebase as Firebase
    participant Admin as Admin
    participant Raspberry as Raspberry Pi

    Note over User,Mobile: Create Booking
    User->>Mobile: Select device (dev01)
    User->>Mobile: Select date/time
    Mobile->>Firebase: Create booking (status: pending)
    Firebase-->>Mobile: Booking created

    Note over Admin,Firebase: Admin Approval
    Admin->>Firebase: View pending bookings
    Admin->>Firebase: Approve booking
    Firebase->>Firebase: Update status = approved

    Note over User,Raspberry: User Access
    User->>Raspberry: Press scan button
    Raspberry->>Firebase: Check valid booking
    Firebase-->>Raspberry: Booking found (approved, current time)

    alt Booking valid
        Raspberry->>Raspberry: Turn on relay
        Raspberry->>Firebase: Update device status = in_use
        Raspberry->>Firebase: Update booking status = using
        Note over Raspberry: Monitor until end time
        Raspberry->>Raspberry: Turn off relay
        Raspberry->>Firebase: Update booking = finished
        Raspberry->>Firebase: Update device = ready
    else No valid booking
        Raspberry->>Raspberry: Blink LED (denied)
    end
```

### 3. Device Access (Face Scan) Flow

```mermaid
sequenceDiagram
    participant User
    participant Raspberry as Raspberry Pi
    participant Firebase as Firebase

    Note over User,Raspberry: Hardware Button Press
    User->>Raspberry: Press scan button (GPIO 26)
    Raspberry->>Raspberry: Debounce check (2s cooldown)

    Note over Raspberry,Raspberry: Face Scanning
    Raspberry->>Raspberry: Initialize camera
    Raspberry->>Raspberry: Scan for 8 seconds
    Note over Raspberry: Capture ~40 frames
    Note over Raspberry: Voting system

    Note over Raspberry,Raspberry: Face Recognition
    Raspberry->>Raspberry: Load face_db.npy
    Raspberry->>Raspberry: Extract embedding
    Raspberry->>Raspberry: Cosine similarity matching

    alt Face recognized
        Note over Raspberry: Get recognized_user_id
        Note over Raspberry: Check all valid bookings

        alt Has valid booking(s)
            Note over Raspberry: Activate all valid devices
            Note over Raspberry: Update Firestore status
            Note over Raspberry: Start monitor threads
            Raspberry->>Firebase: Update device(s) = in_use
            Raspberry->>Firebase: Update booking(s) = using
        else No valid booking
            Raspberry->>Raspberry: Blink LED (5x)
            Raspberry->>Firebase: Update scanRequest = denied
        end

    else Face not recognized
        Raspberry->>Raspberry: Blink LED (5x)
        Raspberry->>Firebase: Update scanRequest = failed
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
| 26 | Input | Scan Button |
| 18 | Output | LED (dev01) |
| 23 | Output | LED (dev02) |
| 24 | Output | LED (dev03) |
| 17 | Output | Relay (dev01) |
| 27 | Output | Relay (dev02) |
| 22 | Output | Relay (dev03) |

## Component Communication

| From | To | Protocol | Data |
|------|-------|---------|------|
| Mobile App | Firebase | REST API | User, Booking, Device data |
| AI Model | Firebase | REST API | User embeddings |
| AI Model | Raspberry | SFTP (SSH) | face_db.npy |
| Raspberry | Firebase | Firestore SDK | Scan requests, device status |
| Raspberry | Hardware | GPIO | Relay, LED control |

## System Block Diagram

```mermaid
flowchart TB
    subgraph Users["Users"]
        direction TB
        User1["User"]
        Admin["Admin"]
    end

    subgraph MobileApp["Mobile App (Flutter)"]
        direction LR
        Auth[Auth Module]
        Booking[Booking Module]
        Device[Device Status]
    end

    subgraph Firebase["Firebase Cloud"]
        direction LR
        FireAuth[Firebase Auth]
        Firestore[Firestore DB]
        Storage[Cloud Storage]
    end

    subgraph AIModel["AI Model Server"]
        direction TB
        MTCNN[MTCNN Face Detector]
        MobileNet[MobileFaceNet]
        Embed[128-dim Embeddings]
        Sync[Sync Daemon]
    end

    subgraph Raspberry["Raspberry Pi Station"]
        direction LR
        Camera[USB Camera]
        Listener[Scan Listener]
        FaceRec[Face Recognition]
        GPIO[ GPIO Control]
    end

    subgraph Hardware["Lab Equipment"]
        direction LR
        Dev01["dev01: 3D Printer"]
        Dev02["dev02: Microscope"]
        Dev03["dev03: Soldering"]
    end

    User1 -->|Book Device| MobileApp
    Admin -->|Manage| MobileApp
    MobileApp -->|Auth| FireAuth
    MobileApp -->|CRUD| Firestore
    MobileApp -->|Upload Faces| Storage

    Firestore -->|New User| Sync
    Sync -->|Extract| MTCNN
    MTCNN -->|Face| MobileNet
    MobileNet -->|Embedding| Embed
    Embed -->|Upload DB| Sync
    Sync -->|SSH| Raspberry

    Camera -->|Capture| FaceRec
    Listener -->|Listen| Firestore
    FaceRec -->|Match| Embed
    GPIO -->|Control| Hardware

    style Users fill:#e1f5fe
    style Firebase fill:#fff3e0
    style AIModel fill:#e8f5e9
    style Raspberry fill:#fce4ec
    style Hardware fill:#fff9c4
```

## Use Case Diagram

```mermaid
flowchart TB
    subgraph Actors
        User["User"]
        Admin["Admin"]
        System["System"]
    end

    subgraph UserUseCases
        UC1["Login/Logout"]
        UC2["Register Account"]
        UC3["Scan Face (5 photos)"]
        UC4["View Devices"]
        UC5["Book Device"]
        UC6["Cancel Booking"]
        UC7["Scan to Access Device"]
        UC8["View Profile"]
    end

    subgraph AdminUseCases
        AC1["View All Bookings"]
        AC2["Approve Booking"]
        AC3["Reject Booking"]
        AC4["View All Users"]
        AC5["Manage Devices"]
    end

    User --> UC1
    User --> UC2
    User --> UC3
    User --> UC4
    User --> UC5
    User --> UC6
    User --> UC7
    User --> UC8

    Admin --> AC1
    Admin --> AC2
    Admin --> AC3
    Admin --> AC4
    Admin --> AC5

    UC5 -->|Approved| System
    AC2 -->|Approved| System
    UC7 -->|Valid Booking| System
```

## Entity-Relationship Diagram

```mermaid
erDiagram
  USERS ||--o{ BOOKINGS : "creates"
  DEVICES ||--o{ BOOKINGS : "has"
  BOOKINGS ||--o{ SCAN_REQUESTS : "triggers"
  DEVICES ||--o{ SCAN_REQUESTS : "targets"

  USERS {
    string uid PK
    string name
    string email
    string role
    string num
    string job
    string birthday
    array faceImageUrls
    string embeddingStatus
    timestamp embeddingUpdatedAt
  }

  DEVICES {
    string deviceId PK
    string name
    string status
    string currentUserId
    string currentUserName
    string description
    string location
    timestamp updatedAt
  }

  BOOKINGS {
    string bookingId PK
    string userId FK
    string userName
    string deviceId FK
    string deviceName
    timestamp startTime
    timestamp endTime
    string status
    timestamp createdAt
    timestamp updatedAt
    timestamp approvedAt
    timestamp finishedAt
  }

  SCAN_REQUESTS {
    string requestId PK
    string userId FK
    string deviceId FK
    string status
    string recognizedUserId
    float score
    string bookingId
    string message
    timestamp createdAt
    timestamp updatedAt
  }
```

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