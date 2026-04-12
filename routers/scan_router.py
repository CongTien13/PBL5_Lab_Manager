from fastapi import APIRouter, UploadFile
from controllers.scan_controller import ScanController

router = APIRouter()
controller = ScanController()

@router.post("/scan")
async def scan_face(file: UploadFile):
    return controller.scan(await file.read())