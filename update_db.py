import os
import cv2
import numpy as np
import tensorflow as tf
import pickle
from config.settings import MODEL_PATH, DB_PATH, IMG_SIZE

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

def update_database():
    if not os.path.exists(MODEL_PATH):
        print("Model file not found")
        return

    model = tf.keras.models.load_model(MODEL_PATH)
    database = {}
    clean_data_path = "dataset_clean"

    for person_name in os.listdir(clean_data_path):
        person_dir = os.path.join(clean_data_path, person_name)
        if not os.path.isdir(person_dir):
            continue

        embeddings = []
        for img_name in os.listdir(person_dir):
            img_path = os.path.join(person_dir, img_name)
            img = cv2.imread(img_path)
            if img is None:
                continue

            img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
            img = img.astype('float32') / 255.0
            img = np.expand_dims(img, axis=0)

            vec = model.predict(img, verbose=0)[0]
            vec = vec / np.linalg.norm(vec)
            embeddings.append(vec)

        if len(embeddings) > 0:
            database[person_name] = np.array(embeddings)
            print(f"Stored {len(embeddings)} vectors for {person_name}")

    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    with open(DB_PATH, "wb") as f:
        pickle.dump(database, f)
    print(f"Database saved to {DB_PATH}")

if __name__ == "__main__":
    update_database()