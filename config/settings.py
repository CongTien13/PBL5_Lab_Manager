import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DATASET_DIR = os.path.join(BASE_DIR, "dataset")
WEIGHTS_PATH = os.path.join(BASE_DIR, "weights", "last_checkpoint.pth")

DEVICE = "cuda"   
THRESHOLD = 0.5