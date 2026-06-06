import os
import time
import cv2
import torch
import numpy as np
import torch.nn.functional as F

from models.face_model import FaceModel
from services.face_detector import FaceDetector


BASE_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_PATH = os.path.join(BASE_DIR, "weights", "last_checkpoint.pth")
FACE_DB_PATH = os.path.join(BASE_DIR, "weights", "face_db.npy")

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

THRESHOLD = 0.05
SCAN_SECONDS = 8


if not os.path.exists(MODEL_PATH):
    raise Exception(f"Không tìm thấy model: {MODEL_PATH}")

if not os.path.exists(FACE_DB_PATH):
    raise Exception(f"Không tìm thấy face_db.npy: {FACE_DB_PATH}")


print("[INFO] Loading model...")
model = FaceModel(MODEL_PATH, DEVICE)

print("[INFO] Loading face detector...")
detector = FaceDetector(DEVICE)

db = np.load(FACE_DB_PATH, allow_pickle=True).item()

db_tensor = {}

print("\n========== FACE DB ==========")
for name, emb_list in db.items():
    db_tensor[name] = torch.tensor(
        emb_list,
        dtype=torch.float32
    ).to(DEVICE)

    print(f"{name}: {len(emb_list)} embeddings")

print("=============================\n")


def get_embedding(frame):
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    face = detector.detect(rgb)

    if face is None:
        return None

    face = face.unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        emb = model.get_embedding(face)

    return emb


def load_face_database():
    global db_tensor

    db = np.load(FACE_DB_PATH, allow_pickle=True).item()

    db_tensor = {}

    print("\n========== RELOAD FACE DB ==========")

    for name, emb_list in db.items():
        db_tensor[name] = torch.tensor(
            emb_list,
            dtype=torch.float32
        ).to(DEVICE)

        print(f"{name}: {len(emb_list)} embeddings")

    print("====================================\n")


def recognize(frame):
    embedding = get_embedding(frame)

    if embedding is None:
        return "No Face", None

    best_score = -1
    best_name = "Unknown"

    for name, db_embs in db_tensor.items():
        emb_expand = embedding.expand_as(db_embs)

        scores = F.cosine_similarity(
            emb_expand,
            db_embs
        )

        max_score = torch.max(scores).item()

        if max_score > best_score:
            best_score = max_score
            best_name = name

    if best_score < THRESHOLD:
        return "Unknown", best_score

    return best_name, best_score


def scan_face_once():
    load_face_database()
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("[ERROR] Không mở được camera")
        return {
            "success": False,
            "userId": None,
            "score": None,
            "message": "Không mở được camera"
        }

    print("[READY] Camera running...")
    print(f"[INFO] Quét mặt trong {SCAN_SECONDS} giây...")

    start_time = time.time()

    vote_count = {}
    score_sum = {}

    while time.time() - start_time < SCAN_SECONDS:
        ret, frame = cap.read()

        if not ret:
            print("[WARN] Không đọc được frame")
            time.sleep(0.2)
            continue

        name, score = recognize(frame)

        if name != "Unknown" and name != "No Face":
            vote_count[name] = vote_count.get(name, 0) + 1
            score_sum[name] = score_sum.get(name, 0) + score

            print(
                f"[VOTE] {name} | "
                f"score={score:.4f} | "
                f"count={vote_count[name]}"
            )
        else:
            if score is not None:
                print(f"[UNKNOWN] best score={score:.4f}")
            else:
                print("[NO FACE]")

        time.sleep(0.2)

    cap.release()

    print("\n========== SCAN RESULT ==========")

    if not vote_count:
        print("[FAILED] Không nhận diện được ai trong 8 giây")
        print("=================================\n")

        return {
            "success": False,
            "userId": None,
            "score": None,
            "message": "Không nhận diện được khuôn mặt"
        }

    final_user_id = max(
        vote_count,
        key=vote_count.get
    )

    final_count = vote_count[final_user_id]
    avg_score = score_sum[final_user_id] / final_count

    print(f"[SUCCESS] Người được nhận diện nhiều nhất: {final_user_id}")
    print(f"Số frame match: {final_count}")
    print(f"Điểm trung bình: {avg_score:.4f}")

    print("\nChi tiết vote:")
    for name, count in vote_count.items():
        avg = score_sum[name] / count
        print(f"- {name}: {count} lần | avg score={avg:.4f}")

    print("=================================\n")

    return {
        "success": True,
        "userId": final_user_id,
        "score": avg_score,
        "message": "Nhận diện thành công"
    }


def main():
    result = scan_face_once()
    print(result)


if __name__ == "__main__":
    main()