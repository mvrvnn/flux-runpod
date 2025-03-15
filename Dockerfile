FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    APP_DIR=/runpod-volume/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /runpod-volume
RUN mkdir -p /runpod-volume/app \
    /runpod-volume/models/flux1 \
    /runpod-volume/models/lora \
    /runpod-volume/outputs

# Copy application files
COPY app/ /runpod-volume/app/
COPY requirements.txt /runpod-volume/
COPY signal_handler.sh /usr/local/bin/

# Make signal handler executable
RUN chmod +x /usr/local/bin/signal_handler.sh

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Set permissions
RUN chmod -R 777 /runpod-volume

# Use Tini as PID 1
ENTRYPOINT ["/usr/bin/tini", "-s", "--"]

# Run the signal handler
CMD ["/usr/local/bin/signal_handler.sh"]