# AI Model Documentation

## Overview

The AI model component provides face recognition capabilities using MobileFaceNet for 128-dimensional embedding generation. It processes face images from the mobile app and synchronizes the face database to Raspberry Pi stations.

## Model Architecture

### MobileFaceNet

MobileFaceNet is a lightweight CNN architecture optimized for mobile devices, producing 128-dimensional face embeddings.

**Architecture Details:**

```python
# From ai_model/models/mobilefacenet.py

class MobileFaceNet(nn.Module):
    def __init__(self, embedding_size=128):
        # Initial convolution: 3 -> 64 channels
        self.conv1 = ConvBlock(3, 64, 3, 2, 1)

        # Depthwise convolution
        self.dw_conv1 = ConvBlock(64, 64, 3, 1, 1, dw=True)

        # Bottleneck blocks
        setting = [
            [2, 64, 5, 2],    # Stage 2: 64 channels, 5 blocks
            [4, 128, 1, 2],   # Stage 3: 128 channels, 1 block
            [2, 128, 6, 1],    # Stage 4: 128 channels, 6 blocks
            [4, 128, 1, 2],   # Stage 5: 128 channels, 1 block
            [2, 128, 2, 1],   # Stage 6: 128 channels, 2 blocks
        ]

        # Output: 512 -> embedding_size
        self.linear1 = ConvBlock(512, embedding_size, 1, 1, 0, linear=True)
```

**Key Features:**
- Depthwise separable convolutions for efficiency
- PReLU activation functions
- Batch normalization
- L2 normalized output (128-dim vector)

### MTCNN Face Detector

Uses MTCNN (Multi-task Cascaded Convolutional Networks) for face detection and alignment.

```python
# From ai_model/services/face_detector.py

class FaceDetector:
    def __init__(self, device):
        self.mtcnn = MTCNN(
            image_size=112,  # Output face size
            margin=10,       # Margin around face
            device=device
        )

    def detect(self, frame):
        # Returns: Tensor of shape (3, 112, 112)
        face = self.mtcnn(frame)
        return face
```

### FaceModel Wrapper

```python
# From ai_model/models/face_model.py

class FaceModel:
    def __init__(self, weight_path, device):
        self.device = device
        self.model = MobileFaceNet(embedding_size=128).to(device)

        # Load trained weights
        checkpoint = torch.load(weight_path, map_location=device)
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model.eval()

    def get_embedding(self, face_tensor):
        # Input: (N, 3, 112, 112) tensor
        # Output: (N, 128) normalized embedding
        with torch.no_grad():
            emb = self.model(face_tensor.to(self.device))
        return emb
```

## Training

### Training Configuration

The model is trained using Google Colab with the following setup:

- **Dataset**: CASIA-WebFace (10,572 classes)
- **Loss**: ArcMarginProduct (Angular Margin Loss)
- **Optimizer**: SGD with momentum
- **Training Script**: `facemodel.ipynb`

### Training Script Location

```
ai_model/facemodel.ipynb
```

### Model Weights

```
ai_model/weights/last_checkpoint.pth
```

## Scripts

### 1. main.py - Real-time Inference

**Location**: `ai_model/main.py`

Real-time face recognition using webcam with cosine similarity matching.

```python
# Key functions
def recognize(embedding, database, threshold=0.5):
    """Compare embedding against face database using cosine similarity"""
    best_score = -1
    best_name = "Unknown"

    for name, db_embs in database.items():
        emb_expand = embedding.expand_as(db_embs)
        scores = F.cosine_similarity(emb_expand, db_embs)
        max_score = torch.max(scores).item()

        if max_score > best_score:
            best_score = max_score
            best_name = name

    if best_score < threshold:
        return "Unknown", best_score

    return best_name, best_score
```

**Usage**:
```bash
python ai_model/main.py
```

### 2. update_db.py - Face Database Builder

**Location**: `ai_model/update_db.py`

Builds face_db.npy from Firebase users for local inference.

```python
# Key functions
def extract_embedding(img_path):
    """Extract 128-dim embedding from image file"""
    img = cv2.imread(img_path)
    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face = detector.detect(rgb)
    face = face.unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        emb = model.get_embedding(face)
    return emb.cpu().numpy()[0]
```

**Usage**:
```bash
python ai_model/update_db.py
```

**Output**: `ai_model/weights/face_db.npy`

### 3. sync_firestore_face_db.py - Firebase Sync + SSH Upload

**Location**: `ai_model/sync_firestore_face_db.py`

Synchronizes face embeddings to Firestore and uploads to Raspberry Pi via SSH.

**Key Functions**:

```python
def process_user(doc):
    """Process single user: download images, extract embeddings, upload"""
    uid = doc.id
    urls = data.get("faceImageUrls", [])

    embeddings = []
    for url in urls:
        img_path = download_image(url)
        emb = embed_image(img_path)
        if emb is not None:
            embeddings.append(emb)

    face_db = load_face_db()
    face_db[uid] = np.array(embeddings)
    save_face_db(face_db)
    upload_face_db_to_raspberry()  # SSH upload

    doc.reference.update({
        "embeddingStatus": "done",
        "embeddingUpdatedAt": firestore.SERVER_TIMESTAMP
    })
```

**Usage**:
```bash
python ai_model/sync_firestore_face_db.py
```

**Configuration**:
```python
RASPBERRY_HOST = "172.20.10.2"
RASPBERRY_PORT = 22
RASPBERRY_USER = "pi"
RASPBERRY_PASSWORD = "12345678"
RASPBERRY_DB_PATH = "/home/pi/Desktop/PBL5_HARDWARE/weights/face_db.npy"
```

## Face Database Format

The face database is stored as a NumPy file with the following structure:

```python
# face_db.npy format
{
    "user_id_1": np.array([emb1, emb2, emb3, ...]),  # Multiple embeddings per user
    "user_id_2": np.array([emb1, emb2, ...]),
}
```

- Key: Firebase user UID
- Value: NumPy array of shape (n, 128) where n is number of face images

## Recognition Algorithm

### Cosine Similarity Matching

```python
def recognize(embedding, database, threshold=0.5):
    best_score = -1
    best_name = "Unknown"

    for name, db_embs in database.items():
        # Expand embedding to match database embeddings
        emb_expand = embedding.expand_as(db_embs)

        # Compute cosine similarity
        scores = F.cosine_similarity(emb_expand, db_embs)
        max_score = torch.max(scores).item()

        if max_score > best_score:
            best_score = max_score
            best_name = name

    if best_score < threshold:
        return "Unknown", best_score

    return best_name, best_score
```

### Threshold Configuration

| Environment | Threshold |
|-------------|-----------|
| Raspberry Pi | 0.05 |
| Local inference | 0.5 |

Note: The Raspberry Pi uses a much lower threshold (0.05) due to different face capture conditions.

## Dependencies

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

See `ai_model/requirements.txt` for exact versions.

## Firestore Schema

### users Collection

```json
{
  "uid": {
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "faceImageUrls": [
      "https://.../face_0.jpg",
      "https://.../face_1.jpg",
      "https://.../face_2.jpg",
      "https://.../face_3.jpg",
      "https://.../face_4.jpg"
    ],
    "embeddingStatus": "pending|processing|done|failed",
    "embeddingUpdatedAt": timestamp,
    "embeddingError": "error message if failed"
  }
}
```

## Error Handling

| Error | Cause | Resolution |
|-------|-------|-------------|
| No face detected | Image quality, lighting | Recapture face images |
| Embedding failed | Face not aligned | Check MTCNN detection |
| SSH upload failed | Network issues | Check Raspberry connectivity |
| Firebase access | Credentials | Verify serviceAccountKey.json |

## Performance

| Metric | Value |
|--------|-------|
| Embedding dimension | 128 |
| Face input size | 112x112 |
| Inference time (CPU) | ~50ms |
| Model size | ~5MB |
| Database lookup | O(n) where n = number of users |