import torch
from .mobilefacenet import MobileFaceNet   

class FaceModel:
    def __init__(self, weight_path, device):
        self.device = device
        self.model = MobileFaceNet(embedding_size=128).to(device)

        checkpoint = torch.load(weight_path, map_location=device)
        self.model.load_state_dict(checkpoint['model_state_dict'])

        self.model.eval()

    def get_embedding(self, face_tensor):
        with torch.no_grad():
            emb = self.model(face_tensor.to(self.device))
        return emb