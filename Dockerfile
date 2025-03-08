FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    RUNPOD_VOLUME_PATH=/runpod-volume

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /runpod-volume

# Copy application files
COPY app/ /runpod-volume/app/
COPY requirements.txt /runpod-volume/
COPY signal_handler.sh /usr/local/bin/

# Make signal handler executable
RUN chmod +x /usr/local/bin/signal_handler.sh

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Create necessary directories
RUN mkdir -p /runpod-volume/models/flux1 \
    /runpod-volume/models/lora \
    /runpod-volume/outputs

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/signal_handler.sh"]