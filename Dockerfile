FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    RUNPOD_VOLUME_PATH=/runpod-volume \
    APP_DIR=/app \
    TINI_SUBREAPER=true

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR ${APP_DIR}

# Copy application files
COPY app/ ${APP_DIR}/app/
COPY requirements.txt ${APP_DIR}/
COPY signal_handler.sh /usr/local/bin/

# Make signal handler executable and ensure Unix line endings
RUN chmod +x /usr/local/bin/signal_handler.sh && \
    sed -i 's/\r$//' /usr/local/bin/signal_handler.sh

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Create necessary directories in the volume mount point
RUN mkdir -p ${RUNPOD_VOLUME_PATH}/models/flux1 \
    ${RUNPOD_VOLUME_PATH}/models/lora \
    ${RUNPOD_VOLUME_PATH}/outputs

# Use Tini as the init process with subreaper mode
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/usr/local/bin/signal_handler.sh"]