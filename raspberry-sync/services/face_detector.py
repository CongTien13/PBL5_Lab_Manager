import cv2
import torch


class FaceDetector:

    def __init__(self, device=None):
        self.net = cv2.dnn.readNetFromCaffe(
            "models/deploy.prototxt",
            "models/res10_300x300_ssd_iter_140000.caffemodel"
        )

    def detect(self, image):
        h, w = image.shape[:2]

        blob = cv2.dnn.blobFromImage(
            cv2.resize(image, (300, 300)),
            1.0,
            (300, 300),
            (104.0, 177.0, 123.0)
        )

        self.net.setInput(blob)
        detections = self.net.forward()

        best_box = None
        best_conf = 0

        for i in range(detections.shape[2]):
            confidence = detections[0, 0, i, 2]

            if confidence > best_conf and confidence > 0.6:
                box = detections[0, 0, i, 3:7] * [w, h, w, h]
                best_box = box.astype("int")
                best_conf = confidence

        if best_box is None:
            return None

        x1, y1, x2, y2 = best_box

        x1 = max(0, x1)
        y1 = max(0, y1)
        x2 = min(w, x2)
        y2 = min(h, y2)

        face = image[y1:y2, x1:x2]

        if face.size == 0:
            return None

        face = cv2.resize(face, (112, 112))

        face = torch.tensor(face).permute(2, 0, 1).float()
        face = face / 255.0

        return face