#!/bin/bash

# Function to handle SIGTERM
handle_sigterm() {
    echo "Received SIGTERM signal"
    if [ ! -z "$CHILD_PID" ]; then
        kill -TERM "$CHILD_PID" 2>/dev/null
    fi
    exit 0
}

# Function to handle SIGINT
handle_sigint() {
    echo "Received SIGINT signal"
    if [ ! -z "$CHILD_PID" ]; then
        kill -INT "$CHILD_PID" 2>/dev/null
    fi
    exit 0
}

# Set up signal handlers
trap 'handle_sigterm' SIGTERM
trap 'handle_sigint' SIGINT

# Debug information
echo "=== Environment ==="
echo "Current directory: $(pwd)"
echo "APP_DIR: ${APP_DIR}"
echo "Contents of /runpod-volume/app:"
ls -la /runpod-volume/app

# Start the application
echo "Starting Flux application..."
cd /runpod-volume/app
python3 -u app.py &

# Store child PID
CHILD_PID=$!

# Wait for the Python process to finish
wait $CHILD_PID
EXIT_CODE=$?

echo "Application exited with code $EXIT_CODE"
exit $EXIT_CODE