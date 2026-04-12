import torch
import torch.nn.functional as F
import cv2
import numpy as np
from models.face_model import FaceNetModel


class FaceRecognizer:
    def __init__(self, model_path, num_classes):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        self.model = FaceNetModel(num_classes)
        self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()

    def preprocess(self, img):
        img = cv2.resize(img, (96, 112))
        img = (img - 127.5) / 128.0
        img = np.transpose(img, (2, 0, 1))
        return torch.tensor(img).float().unsqueeze(0)

    def get_embedding(self, img):
        img = self.preprocess(img).to(self.device)

        with torch.no_grad():
            emb = self.model(img)

        return F.normalize(emb).cpu().numpy()[0]

    def cosine_similarity(self, emb1, emb2):
        return np.dot(emb1, emb2)