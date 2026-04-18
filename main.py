import cv2
import torch
import numpy as np
import torch.nn.functional as F

from models.face_model import FaceModel
from services.face_detector import FaceDetector

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
MODEL_PATH = "weights/last_checkpoint.pth"
DB_PATH = "weights/face_db.npy"
THRESHOLD = 0.5

model = FaceModel(MODEL_PATH, DEVICE)
detector = FaceDetector(DEVICE)

db = np.load(DB_PATH, allow_pickle=True).item()
print("Database loaded:", list(db.keys()))

db_tensor = {}
for name, emb_list in db.items():
    db_tensor[name] = torch.tensor(emb_list, dtype=torch.float32).to(DEVICE)


def recognize(embedding, database, threshold=0.5):
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


cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("Cannot open camera")
    exit()

while True:
    ret, frame = cap.read()
    if not ret:
        print("Cannot read frame")
        break

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    face = detector.detect(rgb)

    if face is not None:
        face = face.unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            emb = model.get_embedding(face)

        name, score = recognize(emb, db_tensor, THRESHOLD)

        cv2.putText(frame,
                    f"{name} ({score:.2f})",
                    (30, 40),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (0, 255, 0),
                    2)
    else:
        cv2.putText(frame,
                    "No Face",
                    (30, 40),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1,
                    (0, 0, 255),
                    2)

    cv2.imshow("Face Recognition", frame)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()