# get the development image from nvidia cuda 12.4 (using devel for full CUDA toolkit)
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL name="hunyuan3d21" maintainer="hunyuan3d21"

# --- User‑configurable clone settings ---
ARG HY_REMOTE=https://github.com/uaineteine/Hunyuan3D-2.1.git
ARG HY_BRANCH=KDNLO-97-remove-the-conda-install-from-image
# --- User‑configurable CUDA arch list ---
ARG HY_CUDA_ARCH="8.0;8.6;8.9;9.0"

# set cache dirs
ENV HF_HOME=/workspace/.hf_cache
ENV TRANSFORMERS_CACHE=/workspace/.hf_cache

# use rust based downloader for a faster experience in downloading models
ENV HF_XET_HIGH_PERFORMANCE=1

# create workspace folder and set it as working directory
RUN mkdir -p /workspace
WORKDIR /workspace

# update package lists and install git, wget, nano, libegl1-mesa-dev, libglib2.0-0, and python3.10
RUN apt-get update && apt-get install -y build-essential git wget nano libegl1-mesa-dev libglib2.0-0 unzip git-lfs python3.10 python3.10-venv python3.10-dev

# Set Python 3.10 as the default python3 and bootstrap pip
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    python3.10 -m ensurepip --upgrade && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.10 1

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends pkg-config libglvnd0 libgl1 libglx0 libegl1 libgles2 libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev cmake curl mesa-utils-extra libxrender1

# Install additional dependencies for compilation
RUN apt-get install -y libeigen3-dev python3-dev python3-setuptools libcgal-dev

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
ENV PYOPENGL_PLATFORM=egl

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV TORCH_CUDA_ARCH_LIST="${HY_CUDA_ARCH}"

# Install torch
RUN pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

# Clone Hunyuan3D-2.1 repository
RUN git clone -b "$HY_BRANCH" "$HY_REMOTE"
# Cleanup .git folder to save space
RUN rm -rf Hunyuan3D-2.1/.git

# Install Python dependencies with uv
RUN pip install uv
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_general.txt
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_ml.txt
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_build_tools.txt
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_utils.txt
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_config.txt
RUN uv pip install --system -r Hunyuan3D-2.1/pyreqs/requirements_mesh.txt

# Install custom_rasterizer
RUN cd /workspace/Hunyuan3D-2.1/hy3dpaint/custom_rasterizer && \
    # Set compilation environment variables
    export TORCH_CUDA_ARCH_LIST="${HY_CUDA_ARCH}" && \
    export CUDA_NVCC_FLAGS="-allow-unsupported-compiler" && \
    # Install with editable mode
    pip install -e . --no-build-isolation --no-deps

# Install DifferentiableRenderer
RUN cd /workspace/Hunyuan3D-2.1/hy3dpaint/DifferentiableRenderer && \
    bash compile_mesh_painter.sh

# Create ckpt folder in hy3dpaint and download RealESRGAN model
RUN cd /workspace/Hunyuan3D-2.1/hy3dpaint && \
    mkdir -p ckpt && \
    wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth -P ckpt

# Modify textureGenPipeline.py to update config path
RUN cd /workspace/Hunyuan3D-2.1/hy3dpaint && \
    sed -i 's/self\.multiview_cfg_path = "cfgs\/hunyuan-paint-pbr\.yaml"/self.multiview_cfg_path = "hy3dpaint\/cfgs\/hunyuan-paint-pbr.yaml"/' textureGenPipeline.py

# Modify multiview_utils.py to update custom_pipeline path
RUN cd /workspace/Hunyuan3D-2.1/hy3dpaint/utils && \
    sed -i 's/custom_pipeline = config\.custom_pipeline/custom_pipeline = os.path.join(os.path.dirname(__file__),"..","hunyuanpaintpbr")/' multiview_utils.py

# Set working directory to the cloned repository
WORKDIR /workspace/Hunyuan3D-2.1

RUN apt-get install -y libxi6 libgconf-2-4 libxkbcommon-x11-0 libsm6 libxext6 libxrender-dev

#exposing 7860 port
EXPOSE 7860

# Cleanup of installs and temporary files
RUN rm -f /workspace/*.zip
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf "$(pip cache dir)" || true
RUN uv cache clean --all || true

# --- CUDA compiler cleanup (safe) ---
# Remove PTX intermediate files
RUN find / -type f -name "*.ptx" -delete || true
# Remove CUDA static libraries (not needed at runtime)
RUN rm -rf /usr/local/cuda/lib64/*.a || true
# Remove CUDA debug symbol bundles
RUN rm -rf /usr/local/cuda/lib64/*debug* || true
# Remove leftover host object files
RUN find /workspace -type f -name "*.o" -delete || true
# Remove NVCC temp directories
RUN rm -rf /tmp/* || true
RUN rm -rf /var/tmp/* || true
# Remove CUDA samples + docs (you already do some)
RUN rm -rf /usr/local/cuda/samples || true
RUN rm -rf /usr/local/cuda/doc || true
# Remove NVCC host-side include files (safe after build)
RUN rm -rf /usr/local/cuda/include || true

# Image general reduction
# 1. remove manuals 
RUN rm -rf /usr/share/man/*
# 2. remove share docs
RUN rm -rf /usr/share/doc/*
# 3. remove unused cuda docs and samples
RUN rm -rf /usr/local/cuda/samples
RUN rm -rf /usr/local/cuda/doc

# Set default command
WORKDIR /workspace/Hunyuan3D-2.1
RUN mkdir gradio_cache
CMD ["python", "api_server.py"]
