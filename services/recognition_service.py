import os
import cv2
import numpy as np
from models.face_recognizer import FaceRecognizer


class RecognitionService:
    def __init__(self, data_dir="dataset_clean"):
        self.num_classes = len(os.listdir(data_dir))
        self.recognizer = FaceRecognizer("weights/face_model.pth", self.num_classes)

        self.database = self.build_database(data_dir)
        self.threshold = 0.5

    def build_database(self, path):
        db = {}

        for person in os.listdir(path):
            person_path = os.path.join(path, person)

            if not os.path.isdir(person_path):
                continue

            embeddings = []

            for img_name in os.listdir(person_path):
                img_path = os.path.join(person_path, img_name)
                img = cv2.imread(img_path)

                if img is None:
                    continue

                emb = self.recognizer.get_embedding(img)
                embeddings.append(emb)

            if embeddings:
                db[person] = np.mean(embeddings, axis=0)

        return db

    def recognize(self, img):
        emb = self.recognizer.get_embedding(img)

        best_name = "Unknown"
        best_score = -1

        for name, db_emb in self.database.items():
            score = self.recognizer.cosine_similarity(emb, db_emb)

            if score > best_score:
                best_score = score
                best_name = name

        if best_score < self.threshold:
            return "Unknown"

        return best_name