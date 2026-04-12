import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Đường dẫn Model
FACENET_MODEL_PATH = os.path.join(BASE_DIR, 'weights', '20180402-114759.pb')
CLASSIFIER_PATH = os.path.join(BASE_DIR, 'weights', 'facemodel.pkl')

# Tham số AI
IMAGE_SIZE = 160
MIN_FACE_SIZE = 20
THRESHOLD = [0.6, 0.7, 0.7]
FACTOR = 0.709
RECOGNITION_THRESHOLD = 0.85

# Dữ liệu
DATASET_DIR = os.path.join(BASE_DIR, 'dataset')