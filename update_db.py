import os
import cv2
import torch
import numpy as np

from models.face_model import FaceModel
from services.face_detector import FaceDetector

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model = FaceModel("weights/last_checkpoint.pth", device)
detector = FaceDetector(device)

DATASET_PATH = "dataset"
SAVE_PATH = "weights/face_db.npy"

database = {}

for user in os.listdir(DATASET_PATH):
    user_path = os.path.join(DATASET_PATH, user)

    if not os.path.isdir(user_path):
        continue

    embeddings = []

    for img_name in os.listdir(user_path):
        if not img_name.lower().endswith(('.jpg', '.jpeg', '.png')):
            continue

        img_path = os.path.join(user_path, img_name)
        img = cv2.imread(img_path)

        if img is None:
            continue

        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        face = detector.detect(rgb)

        if face is None:
            continue

        face = face.unsqueeze(0).to(device)

        with torch.no_grad():
            emb = model.get_embedding(face)

        embeddings.append(emb.cpu().numpy()[0])

    if len(embeddings) > 0:
        embeddings = np.array(embeddings)
        # mean_embedding = np.mean(embeddings, axis=0)
        # database[user] = mean_embedding
        database[user] = np.array(embeddings)
np.save(SAVE_PATH, database)

print("Saved face database!")