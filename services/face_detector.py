from facenet_pytorch import MTCNN

class FaceDetector:
    def __init__(self, device):
        self.mtcnn = MTCNN(
            image_size=112,
            margin=10,
            device=device
        )

    def detect(self, frame):
        face = self.mtcnn(frame)
        return face  