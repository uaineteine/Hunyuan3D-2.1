@echo off
echo Running builder...

docker run -it --name hy3d21 -p 7860:7860 --gpus all hunyuan3d21 python gradio_app.py --port 7860

pause