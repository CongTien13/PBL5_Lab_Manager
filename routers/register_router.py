from fastapi import APIRouter,UploadFile,File
from controllers.register_controller import RegisterController

router = APIRouter()

controller = RegisterController()

@router.post("/register")

async def register(name:str,files:list[UploadFile]=File(...)):

    images = []

    for file in files:

        images.append(await file.read())

    return controller.register_user(name,images)