import cv2
from services.camera_service import CameraService
from services.face_detection_service import FaceDetectionService
from services.recognition_service import RecognitionService


class ScanController:
    def __init__(self):
        self.camera = CameraService()
        self.detector = FaceDetectionService()
        self.recognition = RecognitionService()

    def run(self):
        while True:
            frame = self.camera.get_frame()
            if frame is None:
                break

            faces = self.detector.detect(frame)

            for (x, y, w, h) in faces:
                face = frame[y:y+h, x:x+w]

                name = self.recognition.recognize(face)

                # draw box
                cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)

                # put text
                cv2.putText(frame, name, (x, y-10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.8,
                            (0, 255, 0), 2)

            cv2.imshow("Face Recognition", frame)

            if cv2.waitKey(1) & 0xFF == 27:  # ESC
                break

        self.camera.release()