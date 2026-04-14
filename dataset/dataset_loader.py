import os
import cv2
import numpy as np
import torch
from torch.utils.data import Dataset


class FaceDataset(Dataset):
    def __init__(self, root_dir):
        self.image_paths = []
        self.labels = []
        self.label_map = {}

        current_label = 0
 
        for person_name in os.listdir(root_dir):
            person_path = os.path.join(root_dir, person_name)

            if not os.path.isdir(person_path):
                continue

            self.label_map[person_name] = current_label

            for img_name in os.listdir(person_path):
                img_path = os.path.join(person_path, img_name)

                if img_path.endswith((".jpg", ".png", ".jpeg")):
                    self.image_paths.append(img_path)
                    self.labels.append(current_label)

            current_label += 1

        self.num_classes = current_label

    def __len__(self):
        return len(self.image_paths)

    def __getitem__(self, idx):
        img_path = self.image_paths[idx]
        label = self.labels[idx]

        img = cv2.imread(img_path)
 
        if img is None:
            img = np.zeros((112, 96, 3), dtype=np.uint8)
 
        img = cv2.resize(img, (96, 112))
 
        img = (img - 127.5) / 128.0
 
        img = np.transpose(img, (2, 0, 1))

        return torch.tensor(img).float(), torch.tensor(label).long()