import torch
import torch.nn as nn
import torch.nn.functional as F
import math


class ArcMarginProduct(nn.Module):
    def __init__(self, in_features=128, out_features=1000, s=32.0, m=0.5):
        super().__init__()

        self.weight = nn.Parameter(torch.FloatTensor(out_features, in_features))
        nn.init.xavier_uniform_(self.weight)

        self.s = s
        self.m = m

        self.cos_m = math.cos(m)
        self.sin_m = math.sin(m)

    def forward(self, x, label):
        cosine = F.linear(F.normalize(x), F.normalize(self.weight))
        sine = torch.sqrt(1.0 - cosine ** 2)

        phi = cosine * self.cos_m - sine * self.sin_m

        one_hot = torch.zeros_like(cosine)
        one_hot.scatter_(1, label.view(-1, 1), 1)

        output = one_hot * phi + (1 - one_hot) * cosine
        return output * self.s