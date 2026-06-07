import os
import re
import cv2
import torch
import numpy as np
import requests
import firebase_admin

from firebase_admin import credentials, firestore
from models.face_model import FaceModel
from services.face_detector import FaceDetector


DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MODEL_PATH = "weights/last_checkpoint.pth"
SAVE_PATH = "weights/face_db.npy"
SERVICE_ACCOUNT = "serviceAccountKey.json"
TEMP_DIR = "temp_faces"

os.makedirs("weights", exist_ok=True)
os.makedirs(TEMP_DIR, exist_ok=True)

if not firebase_admin._apps:
    cred = credentials.Certificate(SERVICE_ACCOUNT)
    firebase_admin.initialize_app(cred)

fs = firestore.client()

model = FaceModel(MODEL_PATH, DEVICE)
detector = FaceDetector(DEVICE)

database = {}


def make_person_key(name, uid):
    safe_name = name.strip().lower()
    safe_name = re.sub(r"\s+", "_", safe_name)
    safe_name = re.sub(r"[^a-zA-Z0-9_]", "", safe_name)

    if not safe_name:
        safe_name = "unknown"

    return f"{safe_name}_{uid[:6]}"


def download_image(url, save_path):
    response = requests.get(url, timeout=20)
    response.raise_for_status()

    with open(save_path, "wb") as f:
        f.write(response.content)


def extract_embedding(img_path):
    img = cv2.imread(img_path)

    if img is None:
        print(f"[SKIP] Không đọc được ảnh: {img_path}")
        return None

    rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    face = detector.detect(rgb)

    if face is None:
        print(f"[SKIP] Không detect được mặt: {img_path}")
        return None

    face = face.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        emb = model.get_embedding(face)

    return emb.cpu().numpy()[0]


def main():
    users = fs.collection("users").stream()

    total_users = 0
    total_embeddings = 0

    for doc in users:
        uid = doc.id
        data = doc.to_dict()

        name = data.get("name", uid)
        urls = data.get("faceImageUrls", [])

        if not urls:
            print(f"[SKIP USER] {uid} - {name}: không có faceImageUrls")
            continue

        person_key = make_person_key(name, uid)

        print(f"\n[USER] {person_key} ({name})")
        embeddings = []

        for index, url in enumerate(urls):
            img_path = os.path.join(TEMP_DIR, f"{person_key}_{index}.jpg")

            try:
                print(f"  [DOWNLOAD] ảnh {index + 1}")
                download_image(url, img_path)

                emb = extract_embedding(img_path)

                if emb is not None:
                    embeddings.append(emb)
                    print(f"  [OK] ảnh {index + 1}: embedded")

            except Exception as e:
                print(f"  [ERR] ảnh {index + 1}: {e}")

        if len(embeddings) > 0:
            database[person_key] = np.array(embeddings)

            total_users += 1
            total_embeddings += len(embeddings)

            print(f"[DONE] {person_key}: {len(embeddings)} embeddings")
        else:
            print(f"[FAILED] {person_key}: không tạo được embedding nào")

    np.save(SAVE_PATH, database)

    print("\n==============================")
    print(f"Saved face database: {SAVE_PATH}")
    print(f"Total users: {total_users}")
    print(f"Total embeddings: {total_embeddings}")
    print("==============================")


if __name__ == "__main__":
    main()