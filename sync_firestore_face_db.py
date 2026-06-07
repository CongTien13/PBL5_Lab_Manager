import uuid
import os
import time
import cv2
import torch
import numpy as np
import requests
import firebase_admin
import paramiko

from firebase_admin import credentials, firestore
from models.face_model import FaceModel
from services.face_detector import FaceDetector


DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MODEL_PATH = "weights/last_checkpoint.pth"
DB_PATH = "weights/face_db.npy"
SERVICE_ACCOUNT = "serviceAccountKey.json"
TEMP_DIR = "temp_faces"

# Raspberry config
RASPBERRY_HOST = "172.20.10.2"
RASPBERRY_PORT = 22
RASPBERRY_USER = "pi"
RASPBERRY_PASSWORD = "12345678"
RASPBERRY_DB_PATH = "/home/pi/Desktop/PBL5_HARDWARE/weights/face_db.npy"

os.makedirs(TEMP_DIR, exist_ok=True)

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)

db_fs = firestore.client()

model = FaceModel(MODEL_PATH, DEVICE)
detector = FaceDetector(DEVICE)


def load_face_db():
    if os.path.exists(DB_PATH):
        return np.load(DB_PATH, allow_pickle=True).item()
    return {}


def save_face_db(face_db):
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    np.save(DB_PATH, face_db)


def upload_face_db_to_raspberry():
    print("[UPLOAD] Đang gửi face_db.npy sang Raspberry...")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(
            hostname=RASPBERRY_HOST,
            port=RASPBERRY_PORT,
            username=RASPBERRY_USER,
            password=RASPBERRY_PASSWORD,
            timeout=10
        )

        sftp = ssh.open_sftp()
        sftp.put(DB_PATH, RASPBERRY_DB_PATH)
        sftp.close()

        print("[UPLOAD] Gửi face_db.npy sang Raspberry thành công")

        return True

    except Exception as e:
        print(f"[UPLOAD ERROR] Không gửi được face_db.npy: {e}")

        return False

    finally:
        ssh.close()


def download_image(url, save_path):
    res = requests.get(url, timeout=20)
    res.raise_for_status()

    with open(save_path, "wb") as f:
        f.write(res.content)


def embed_image(img_path):
    img = cv2.imread(img_path)

    if img is None:
        return None

    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face = detector.detect(rgb)

    if face is None:
        return None

    face = face.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        emb = model.get_embedding(face)

    return emb.cpu().numpy()[0]
def remove_deleted_users_from_face_db():
    face_db = load_face_db()

    if not face_db:
        return

    current_user_ids = set()

    users = db_fs.collection("users").stream()

    for doc in users:
        current_user_ids.add(doc.id)

    removed = []

    for uid in list(face_db.keys()):
        if uid not in current_user_ids:
            del face_db[uid]
            removed.append(uid)

    if removed:
        save_face_db(face_db)
        upload_face_db_to_raspberry()

        print("[CLEAN] Đã xóa user khỏi face_db:")
        for uid in removed:
            print("-", uid)

def process_user(doc):
    uid = doc.id
    data = doc.to_dict()

    name = data.get("name", uid)
    urls = data.get("faceImageUrls", [])

    if len(urls) == 0:
        print(f"[SKIP] {uid}: không có faceImageUrls")
        return

    doc.reference.update({
        "embeddingStatus": "processing"
    })

    embeddings = []

    for i, url in enumerate(urls):
        img_path = os.path.join(TEMP_DIR, f"{uid}_{i}.jpg")

        try:
            download_image(url, img_path)
            emb = embed_image(img_path)

            if emb is not None:
                embeddings.append(emb)
                print(f"[OK] {uid} ảnh {i + 1}: embedded")
            else:
                print(f"[WARN] {uid} ảnh {i + 1}: không detect được mặt")

        except Exception as e:
            print(f"[ERR] {uid} ảnh {i + 1}: {e}")

    if len(embeddings) == 0:
        doc.reference.update({
            "embeddingStatus": "failed",
            "embeddingError": "Không tạo được embedding từ ảnh"
        })
        return

    face_db = load_face_db()
    face_db[uid] = np.array(embeddings)

    save_face_db(face_db)

    upload_success = upload_face_db_to_raspberry()

    if not upload_success:
        doc.reference.update({
            "embeddingStatus": "failed",
            "embeddingError": "Không gửi được face_db.npy sang Raspberry"
        })
        return

    doc.reference.update({
        "embeddingStatus": "done",
        "embeddingUpdatedAt": firestore.SERVER_TIMESTAMP,
        "embeddingCount": len(embeddings),
        "embeddingError": None
    })

    print(f"[DONE] {uid} - {name}: lưu {len(embeddings)} embeddings vào {DB_PATH}")


def main_loop():
    while True:
        remove_deleted_users_from_face_db()

        users = (
            db_fs.collection("users")
            .where("embeddingStatus", "==", "pending")
            .stream()
        )

        found = False

        for doc in users:
            found = True
            process_user(doc)

        if not found:
            print("[WAIT] không có user pending")

        time.sleep(10)


if __name__ == "__main__":
    main_loop()