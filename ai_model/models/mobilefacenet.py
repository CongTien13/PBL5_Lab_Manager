import torch
import torch.nn as nn
import torch.nn.functional as F

class ConvBlock(nn.Module):
    def __init__(self, inp, oup, k, s, p, dw=False, linear=False):
        super().__init__()
        self.linear = linear
        if dw:
            self.conv = nn.Conv2d(inp, oup, k, s, p, groups=inp, bias=False)
        else:
            self.conv = nn.Conv2d(inp, oup, k, s, p, bias=False)
        self.bn = nn.BatchNorm2d(oup)
        if not linear:
            self.prelu = nn.PReLU(oup)

    def forward(self, x):
        x = self.bn(self.conv(x))
        return x if self.linear else self.prelu(x)

class Bottleneck(nn.Module):
    def __init__(self, inp, oup, stride, expansion):
        super().__init__()
        self.connect = stride == 1 and inp == oup
        self.conv = nn.Sequential(
            ConvBlock(inp, inp * expansion, 1, 1, 0),
            ConvBlock(inp * expansion, inp * expansion, 3, stride, 1, dw=True),
            ConvBlock(inp * expansion, oup, 1, 1, 0, linear=True),
        )

    def forward(self, x):
        return x + self.conv(x) if self.connect else self.conv(x)

class MobileFaceNet(nn.Module):
    def __init__(self, embedding_size=128):
        super().__init__()
        self.conv1 = ConvBlock(3, 64, 3, 2, 1)
        self.dw_conv1 = ConvBlock(64, 64, 3, 1, 1, dw=True)

        self.inplanes = 64
        setting = [
            [2, 64, 5, 2],
            [4, 128, 1, 2],
            [2, 128, 6, 1],
            [4, 128, 1, 2],
            [2, 128, 2, 1]
        ]

        layers = []
        for t, c, n, s in setting:
            for i in range(n):
                stride = s if i == 0 else 1
                layers.append(Bottleneck(self.inplanes, c, stride, t))
                self.inplanes = c
        self.blocks = nn.Sequential(*layers)

        self.conv2 = ConvBlock(128, 512, 1, 1, 0)
        self.linear7 = ConvBlock(512, 512, (7, 6), 1, 0, dw=True, linear=True)
        self.linear1 = ConvBlock(512, embedding_size, 1, 1, 0, linear=True)

    def forward(self, x):
        x = self.conv1(x)
        x = self.dw_conv1(x)
        x = self.blocks(x)
        x = self.conv2(x)
        x = self.linear7(x)
        x = self.linear1(x)
        x = x.view(x.size(0), -1)
        return F.normalize(x)