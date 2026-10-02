from fastapi import FastAPI, File, UploadFile
from fastapi.responses import Response
from rembg import remove

app = FastAPI()

@app.post("/remove-bg/")
async def remove_background(file: UploadFile = File(...)):
    # Read the incoming image bytes from Flutter
    input_image = await file.read()
    
    # Process through rembg's machine learning model
    output_image = remove(input_image)
    
    # Return the perfectly cropped, transparent PNG
    return Response(content=output_image, media_type="image/png")