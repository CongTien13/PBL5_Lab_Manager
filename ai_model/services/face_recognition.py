import torch
import torch.nn.functional as F

class FaceRecognitionService:
    def __init__(self, model):
        self.model = model
        self.database = {}

    def load_database(self, database):
        self.database = database

    def add_user(self, name, embeddings):
        self.database[name] = embeddings

    def recognize(self, embedding, threshold=0.5):
        best_score = -1
        best_name = "Unknown"

        for name, emb_list in self.database.items():
            db_embs = torch.tensor(emb_list, dtype=torch.float32).to(embedding.device)

            embedding_expand = embedding.expand_as(db_embs)

            scores = F.cosine_similarity(embedding_expand, db_embs)

            max_score = torch.max(scores).item()

            if max_score > best_score:
                best_score = max_score
                best_name = name

        if best_score < threshold:
            return "Unknown", best_score

        return best_name, best_score