import cv2
import os
import numpy as np
import shutil
from mtcnn import MTCNN

# cau hinh
IMG_SIZE = 128
INPUT_PATH = "dataset"
OUTPUT_PATH = "dataset_clean"
MAX_FACES_PER_VIDEO = 100 
BLUR_THRESHOLD = 35.0 
SIMILARITY_THRESHOLD = 12.0 

detector = MTCNN()

def reset_output():
    if os.path.exists(OUTPUT_PATH):
        shutil.rmtree(OUTPUT_PATH)
    os.makedirs(OUTPUT_PATH)
    print("Cleaned dataset_clean directory")

def is_blurry(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    score = cv2.Laplacian(gray, cv2.CV_64F).var()
    return score < BLUR_THRESHOLD

def is_different(f1, f2):
    f1_gray = cv2.resize(cv2.cvtColor(f1, cv2.COLOR_BGR2GRAY), (32, 32))
    f2_gray = cv2.resize(cv2.cvtColor(f2, cv2.COLOR_BGR2GRAY), (32, 32))
    diff = cv2.absdiff(f1_gray, f2_gray)
    return np.mean(diff) > SIMILARITY_THRESHOLD

def process_video(video_path, save_folder):
    cap = cv2.VideoCapture(video_path)
    
    saved = 0
    saved_faces = []
    frame_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1 
        if frame_count % 1 != 0: 
            continue 

        if frame is None or frame.size == 0:
            continue

        h_orig, w_orig = frame.shape[:2]
        target_w = 1024
        target_h = int(h_orig * (target_w / w_orig))
        frame_resized = cv2.resize(frame, (target_w, target_h))

        try:
            results = detector.detect_faces(frame_resized)
        except:
            continue

        if len(results) > 0:
            results = sorted(results, key=lambda x: x['box'][2]*x['box'][3], reverse=True)
            x, y, w, h = results[0]['box']
            
            scale = w_orig / target_w
            x, y, w, h = int(x*scale), int(y*scale), int(w*scale), int(h*scale)

            x, y = max(0, x), max(0, y)
            if w < 60 or h < 60:
                continue

            pad = int(0.15 * w)
            x1, y1 = max(0, x-pad), max(0, y-pad)
            x2, y2 = min(w_orig, x+w+pad), min(h_orig, h+y+pad)

            face = frame[y1:y2, x1:x2]
            if face.size == 0:
                continue
            
            face = cv2.resize(face, (IMG_SIZE, IMG_SIZE))

            if is_blurry(face):
                continue

            # So sanh voi tat ca anh da luu truoc do
            is_new = True
            for old_face in saved_faces: 
                if not is_different(face, old_face):
                    is_new = False
                    break

            if is_new:
                file_name = f"face_{saved}.jpg"
                cv2.imwrite(os.path.join(save_folder, file_name), face)
                saved_faces.append(face)
                saved += 1

        if saved >= MAX_FACES_PER_VIDEO:
            break

    cap.release()
    print(f"Finished {os.path.basename(video_path)}: {saved} photos")

def preprocess():
    reset_output()
    if not os.path.exists(INPUT_PATH):
        print("Input path not found")
        return

    for person in os.listdir(INPUT_PATH):
        person_path = os.path.join(INPUT_PATH, person)
        if not os.path.isdir(person_path):
            continue

        save_person_path = os.path.join(OUTPUT_PATH, person)
        os.makedirs(save_person_path, exist_ok=True)

        print(f"Processing: {person}")
        for file in os.listdir(person_path):
            if file.lower().endswith((".mp4", ".avi", ".mov", ".mkv")):
                v_path = os.path.join(person_path, file)
                process_video(v_path, save_person_path)

if __name__ == "__main__":
    preprocess()