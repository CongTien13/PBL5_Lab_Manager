import torch
import torch.nn as nn
import torch.nn.functional as F

from models.cnn_model import MobileFacenet
from models.arcface import ArcMarginProduct

class FaceNetModel(nn.Module):
    def __init__(self, num_classes):
        super().__init__()

        self.backbone = MobileFacenet()
        self.arcface = ArcMarginProduct(128, num_classes)

    def forward(self, x, label=None):
        emb = self.backbone(x)
    
        emb = torch.nn.functional.normalize(emb)

        if label is not None:
            return self.arcface(emb, label)

        return emb