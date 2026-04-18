from services.face_service import FaceService

class FaceController:
    def __init__(self):
        self.service = FaceService()
        self.service.build_database()

    def recognize_face(self, img_path):
        user, score = self.service.recognize(img_path)
        print(f"Result: {user} | Score: {score}")
        return user