import os
import cv2
import torch

def load_database(dataset_path, detector, model):
    database = {}

    for user in os.listdir(dataset_path):
        user_path = os.path.join(dataset_path, user)

        embeddings = []

        for img_name in os.listdir(user_path):
            img_path = os.path.join(user_path, img_name)

            img = cv2.imread(img_path)
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

            face = detector.detect(img)
            if face is None:
                continue

            emb = model.get_embedding(face.unsqueeze(0))
            embeddings.append(emb)

        if len(embeddings) > 0:
            database[user] = torch.mean(torch.stack(embeddings), dim=0)

    return database