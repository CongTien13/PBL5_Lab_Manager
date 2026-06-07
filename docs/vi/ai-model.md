# Tài liệu Mô hình AI

## Tổng quan

Thành phần mô hình AI cung cấp khả năng nhận dạng khuôn mặt sử dụng MobileFaceNet để tạo embedding 128 chiều. Nó xử lý ảnh khuôn mặt từ ứng dụng di động và đồng bộ cơ sở dữ liệu khuôn mặt đến các trạm Raspberry Pi.

## Kiến trúc Mô hình

### MobileFaceNet

MobileFaceNet là kiến trúc CNN nhẹ được tối ưu hóa cho thiết bị di động, tạo embedding khuôn mặt 128 chiều.

**Chi tiết kiến trúc:**

```python
# Từ ai_model/models/mobilefacenet.py

class MobileFaceNet(nn.Module):
    def __init__(self, embedding_size=128):
        # Tích chập ban đầu: 3 -> 64 kênh
        self.conv1 = ConvBlock(3, 64, 3, 2, 1)

        # Tích chập theo chiều sâu
        self.dw_conv1 = ConvBlock(64, 64, 3, 1, 1, dw=True)

        # Các khối bottleneck
        setting = [
            [2, 64, 5, 2],    # Giai đoạn 2: 64 kênh, 5 khối
            [4, 128, 1, 2],   # Giai đoạn 3: 128 kênh, 1 khối
            [2, 128, 6, 1],    # Giai đoạn 4: 128 kênh, 6 khối
            [4, 128, 1, 2],   # Giai đoạn 5: 128 kênh, 1 khối
            [2, 128, 2, 1],   # Giai đoạn 6: 128 kênh, 2 khối
        ]

        # Đầu ra: 512 -> embedding_size
        self.linear1 = ConvBlock(512, embedding_size, 1, 1, 0, linear=True)
```

**Tính năng chính:**
- Tích chập tách biệt theo chiều sâu để tăng hiệu suất
- Hàm kích hoạt PReLU
- Chuẩn hóa batch
- Đầu ra L2 chuẩn hóa (vector 128 chiều)

### MTCNN Face Detector

Sử dụng MTCNN (Multi-task Cascaded Convolutional Networks) để phát hiện và căn chỉnh khuôn mặt.

```python
# Từ ai_model/services/face_detector.py

class FaceDetector:
    def __init__(self, device):
        self.mtcnn = MTCNN(
            image_size=112,  # Kích thước đầu ra khuôn mặt
            margin=10,       # Lề xung quanh khuôn mặt
            device=device
        )

    def detect(self, frame):
        # Trả về: Tensor có shape (3, 112, 112)
        face = self.mtcnn(frame)
        return face
```

### FaceModel Wrapper

```python
# Từ ai_model/models/face_model.py

class FaceModel:
    def __init__(self, weight_path, device):
        self.device = device
        self.model = MobileFaceNet(embedding_size=128).to(device)

        # Tải trọng đã huấn luyện
        checkpoint = torch.load(weight_path, map_location=device)
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model.eval()

    def get_embedding(self, face_tensor):
        # Đầu vào: Tensor (N, 3, 112, 112)
        # Đầu ra: Embedding chuẩn hóa (N, 128)
        with torch.no_grad():
            emb = self.model(face_tensor.to(self.device))
        return emb
```

## Huấn luyện

### Cấu hình Huấn luyện

Mô hình được huấn luyện sử dụng Google Colab với cấu hình sau:

- **Dataset**: CASIA-WebFace (10,572 lớp)
- **Loss**: ArcMarginProduct (Angular Margin Loss)
- **Optimizer**: SGD với momentum
- **Script Huấn luyện**: `facemodel.ipynb`

### Vị trí Script Huấn luyện

```
ai_model/facemodel.ipynb
```

### Trọng lượng Mô hình

```
ai_model/weights/last_checkpoint.pth
```

## Scripts

### 1. main.py - Suy luận Thời gian thực

**Vị trí**: `ai_model/main.py`

Nhận dạng khuôn mặt thời gian thực sử dụng webcam với đối chiếu cosine similarity.

```python
# Các hàm chính
def recognize(embedding, database, threshold=0.5):
    """So sánh embedding với cơ sở dữ liệu khuôn mặt sử dụng cosine similarity"""
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

**Cách sử dụng**:
```bash
python ai_model/main.py
```

### 2. update_db.py - Trình tạo Cơ sở Dữ liệu Khuôn mặt

**Vị trí**: `ai_model/update_db.py`

Xây dựng face_db.npy từ người dùng Firebase để suy luận cục bộ.

```python
# Các hàm chính
def extract_embedding(img_path):
    """Trích xuất embedding 128 chiều từ file ảnh"""
    img = cv2.imread(img_path)
    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face = detector.detect(rgb)
    face = face.unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        emb = model.get_embedding(face)
    return emb.cpu().numpy()[0]
```

**Cách sử dụng**:
```bash
python ai_model/update_db.py
```

**Đầu ra**: `ai_model/weights/face_db.npy`

### 3. sync_firestore_face_db.py - Đồng bộ Firebase + Tải lên SSH

**Vị trí**: `ai_model/sync_firestore_face_db.py`

Đồng bộ embedding khuôn mặt đến Firestore và tải lên Raspberry Pi qua SSH.

**Các hàm chính:**

```python
def process_user(doc):
    """Xử lý một người dùng: tải ảnh, trích xuất embedding, tải lên"""
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
    upload_face_db_to_raspberry()  # Tải lên SSH

    doc.reference.update({
        "embeddingStatus": "done",
        "embeddingUpdatedAt": firestore.SERVER_TIMESTAMP
    })
```

**Cách sử dụng**:
```bash
python ai_model/sync_firestore_face_db.py
```

**Cấu hình**:
```python
RASPBERRY_HOST = "172.20.10.2"
RASPBERRY_PORT = 22
RASPBERRY_USER = "pi"
RASPBERRY_PASSWORD = "12345678"
RASPBERRY_DB_PATH = "/home/pi/Desktop/PBL5_HARDWARE/weights/face_db.npy"
```

## Định dạng Cơ sở Dữ liệu Khuôn mặt

Cơ sở dữ liệu khuôn mặt được lưu trữ dưới dạng file NumPy với cấu trúc sau:

```python
# Định dạng face_db.npy
{
    "user_id_1": np.array([emb1, emb2, emb3, ...]),  # Nhiều embedding mỗi người dùng
    "user_id_2": np.array([emb1, emb2, ...]),
}
```

- Key: UID người dùng Firebase
- Value: Mảng NumPy có shape (n, 128) trong đó n là số ảnh khuôn mặt

## Thuật toán Nhận dạng

### Đối chiếu Cosine Similarity

```python
def recognize(embedding, database, threshold=0.5):
    best_score = -1
    best_name = "Unknown"

    for name, db_embs in database.items():
        # Mở rộng embedding để khớp với các embedding trong CSDL
        emb_expand = embedding.expand_as(db_embs)

        # Tính cosine similarity
        scores = F.cosine_similarity(emb_expand, db_embs)
        max_score = torch.max(scores).item()

        if max_score > best_score:
            best_score = max_score
            best_name = name

    if best_score < threshold:
        return "Unknown", best_score

    return best_name, best_score
```

### Cấu hình Ngưỡng

| Môi trường | Ngưỡng |
|-------------|-----------|
| Raspberry Pi | 0.05 |
| Suy luận cục bộ | 0.5 |

Lưu ý: Raspberry Pi sử dụng ngưỡng thấp hơn nhiều (0.05) do điều kiện chụp khuôn mặt khác nhau.

## Phụ thuộc

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

Xem `ai_model/requirements.txt` để biết phiên bản chính xác.

## Lược đồ Firestore

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
    "embeddingError": "thông báo lỗi nếu thất bại"
  }
}
```

## Xử lý Lỗi

| Lỗi | Nguyên nhân | Giải pháp |
|-------|-------|-------------|
| Không phát hiện khuôn mặt | Chất lượng ảnh, ánh sáng | Chụp lại ảnh khuôn mặt |
| Embedding thất bại | Khuôn mặt không căn chỉnh | Kiểm tra phát hiện MTCNN |
| Tải lên SSH thất bại | Vấn đề mạng | Kiểm tra kết nối Raspberry |
| Truy cập Firebase | Thông tin xác thực | Xác minh serviceAccountKey.json |

## Hiệu suất

| Chỉ số | Giá trị |
|--------|-------|
| Chiều embedding | 128 |
| Kích thước đầu vào khuôn mặt | 112x112 |
| Thời gian suy luận (CPU) | ~50ms |
| Kích thước mô hình | ~5MB |
| Tra cứu CSDL | O(n) với n = số người dùng |