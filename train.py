import os
from services.training_service import TrainingService


def start_training():
    if not os.path.exists("weights"):
        os.makedirs("weights")
 
    trainer = TrainingService("casia")
    trainer.train(epochs=10)


if __name__ == "__main__":
    start_training()