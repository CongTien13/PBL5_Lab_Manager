# note pbl

ssh pi@172.20.10.2

cài

sudo apt install ffmpeg -y

checkcam

ffmpeg -f v4l2 -framerate 30 -video_size 640x480 -i /dev/video0 \
-c:v libx264 -preset ultrafast -tune zerolatency \
-f mpegts tcp://0.0.0.0:8888?listen=1

xem trên

tcp://172.20.10.2:8888

tắt

sudo shutdown now

đợi nó hết chớp mới rút 

yolo ổn=)))

python dataset/preprocess_dataset.py

python dataset/augment_dataset.py

python train.py

python -m uvicorn main:app --reload

pip install facenet-pytorch opencv-python numpy torch torchvision

env:     

```jsx
source myenv/bin/activate
```

---

luồng chạy toàn dự án hiện tại:

```jsx
1. User đăng ký trên app
→ upload 5 ảnh mặt lên Cloudinary
→ Firestore lưu user + embeddingStatus = pending

2. Server AI (Windows)
→ tự detect user pending
→ tạo embedding bằng MobileFaceNet
→ lưu vào face_db.npy
→ tự sync file sang Raspberry
→ đổi status = done

3. User đặt thiết bị trên app
→ tạo booking
status = approved

4. User bấm nút cứng
→ Raspberry mở camera quét mặt 8 giây

5. Raspberry nhận diện khuôn mặt
→ so với face_db.npy

6. Check booking hợp lệ
(user đúng + device đúng + đúng thời gian + approved)

7. Nếu pass
→ booking: approved → using
→ device: available → in_use
→ relay bật thiết bị

8. Raspberry theo dõi endTime
→ hết giờ tự relay OFF
→ booking = finished
→ device = available
```

các lỗi hiện tại

- quét xong nó đéo chuyển sang đang sài trên db;))) còn đâu ok hết rồi
- cách chạy

```jsx
lên cái git của công tiến
down cái nhánh ai-model về
cái code mobile = nhánh mobile-dev
code trên raspberry = nhánh raspberry-sync

```

---

hướng dẫn cắm;))) 

đầu tiên bật mạng ở điện thoại lên

tên mạng :     pitest

pass: 12345678

xong phát cho lap 

cắm cái cục nguồn vô ổ điện đảm bảo hắn k bị tụt r mới cắm vô pi

mở cmd gõ:  arp -a 

rồi gởi gpt kiếm địa chỉ rasp xong connect

ví dụ

ssh pi@172.20.10.2

xong rồi pass: **12345678**

xong mở cái chế độ code bằng cách:

cài extension trên vs code **Remote - SSH**

Nhấn:

```
Ctrl + Shift + P
```

Gõ:

```
Remote-SSH: Connect to Host
```

Chọn:

```
Add New SSH Host
```

xong ssh cái địa chỉ nãy m soi ra 

ví dụ **ssh pi@172.20.10.2**

… đoạn sau tra gpt đi 

# HƯỚNG DẪN CHẠY HỆ THỐNG PBL5 HARDWARE + FIREBASE + RASPBERRY

## 1. Lấy `serviceAccountKey.json` từ Firebase

### Bước 1: vào Firebase Console

Chọn project đang dùng.

```
Project Settings
→ Service Accounts
→ Generate new private key
```

Tải file:

```
serviceAccountKey.json
```

Đặt file vào:

```
PBL5/
├── serviceAccountKey.json
```

và trên Raspberry:

```
PBL5_HARDWARE/
├── serviceAccountKey.json
```

---

## 2. Clone source code

### Windows Server AI

```bash
git clone https://github.com/CongTien13/PBL5_Lab_Manager.git
cd PBL5_Lab_Manager
```



---

## 3. Tạo môi trường ảo

### Windows

```bash
python -m venv myenv
myenv\Scripts\activate
```

### Raspberry

```bash
python3 -m venv myenv
source myenv/bin/activate
```

---

## 4. Cài thư viện

### Windows

```bash
pip install -r requirements.txt
```

### Raspberry

```bash
pip install -r requirements.txt
pip install rpi-lgpio
sudo apt install python3-rpi.gpio
```

---

## 5. Kiểm tra Firebase

### Windows hoặc Raspberry

Chạy:

```bash
python firebase_service.py
```

Nếu đúng sẽ hiện:

```
[TEST] Firebase connected OK
```

và list bookings.

---

## 6. Chạy server tạo embedding (Windows)

Mục đích:

```
Tự detect user mới
→ tạo embedding
→ cập nhật face_db.npy
→ sync sang Raspberry
```

Chạy:

```bash
python sync_firestore_face_db.py
```

Nếu chưa có user mới:

```
[WAIT] không có user pending
```

Nếu có user mới:

```
[OK] embedded
[UPLOAD] Gửi face_db.npy sang Raspberry thành công
[DONE]
```

---

## 7. Chạy phần cứng Raspberry

Vào env:

```bash
source myenv/bin/activate
```

Chạy:

```bash
python scan_listener.py
```

Nếu đúng:

```
[LISTENER] Raspberry scan listener started
[LISTENER] Waiting scanRequests or button press...
DEVICE_ID: dev01
```

---

## 8. Nối phần cứng

### Relay

```
Pin 2   → Relay VCC
Pin 6   → Relay GND

Pin 13  → Relay IN1
Pin 16  → Relay IN2
Pin 18  → Relay IN3
```

### Nút bấm

```
Pin 11 → Button
Pin 9  → Button GND
```

---

## 9. Test relay

Mở Python:

```bash
python
```

Test:

```python
from hardware_gpio import relay_on, relay_off

relay_on("dev01")
relay_off("dev01")
```

Relay phải kêu:

```
tạch
```

---

## 10. Flow sử dụng

### Đăng ký user trên app

User tạo tài khoản.

Firestore:

```
embeddingStatus = pending
```

### Server AI

Tự tạo embedding:

```
pending
→ processing
→ done
```

### Đặt thiết bị

Firestore booking:

```
status = approved
```

### Quét

Có 2 cách:

```
Bấm nút cứng
hoặc
App gửi scanRequest
```

### Nếu đúng mặt + đúng lịch

```
approved → using
relay ON
device = in_use
```

### Hết giờ

```
relay OFF
using → finished
device = available
```