import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from tqdm import tqdm

from dataset.dataset_loader import FaceDataset
from models.face_model import FaceNetModel


class TrainingService:
    def __init__(self, data_dir):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
 
        self.dataset = FaceDataset(data_dir)
        self.loader = DataLoader(
            self.dataset,
            batch_size=64,
            shuffle=True,
            num_workers=0,
            drop_last=True
        )
 
        self.model = FaceNetModel(self.dataset.num_classes).to(self.device)
 
        self.criterion = nn.CrossEntropyLoss()
 
        self.optimizer = torch.optim.Adam(self.model.parameters(), lr=1e-3)
 
        self.scheduler = torch.optim.lr_scheduler.StepLR(
            self.optimizer, step_size=10, gamma=0.1
        )

    def train(self, epochs=30):
        print("Start training...")
        print("Classes:", self.dataset.num_classes)
        print("Samples:", len(self.dataset))

        best_loss = float("inf")

        for epoch in range(epochs):
            self.model.train()
            total_loss = 0
 
            pbar = tqdm(self.loader, desc=f"Epoch {epoch+1}/{epochs}", ncols=100)

            for imgs, labels in pbar:
                imgs = imgs.to(self.device)
                labels = labels.to(self.device)
 
                logits = self.model(imgs, labels)
 
                loss = self.criterion(logits, labels)
 
                self.optimizer.zero_grad()
                loss.backward()
                self.optimizer.step()

                total_loss += loss.item()
 
                pbar.set_postfix(loss=loss.item())

            avg_loss = total_loss / len(self.loader)

            print(f"\nEpoch [{epoch+1}/{epochs}] - Avg Loss: {avg_loss:.4f}")
 
            if avg_loss < best_loss:
                best_loss = avg_loss
                torch.save(self.model.state_dict(), "weights/best_model.pth")
                print("🔥 Saved best_model.pth")
 
            self.scheduler.step()
 
        torch.save(self.model.state_dict(), "weights/face_model.pth")
 
        print("Best model: weights/best_model.pth")