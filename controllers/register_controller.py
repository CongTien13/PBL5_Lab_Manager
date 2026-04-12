from services.dataset_service import DatasetService
from services.training_service import TrainingService


class RegisterController:

    def __init__(self):

        self.dataset = DatasetService()
        self.training = TrainingService()

    def register_user(self,name,images):

        self.dataset.save_images(name,images)
        return {"status":"user added"}