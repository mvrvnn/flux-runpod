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
echo "Current directory: $(pwd)"
echo "APP_DIR: ${APP_DIR}"
echo "Contents of APP_DIR:"
ls -la ${APP_DIR}
echo "Contents of APP_DIR/app:"
ls -la ${APP_DIR}/app

# Start the Python application
echo "Starting Flux application..."

# Ensure we're in the correct directory and the app exists
cd "${APP_DIR}"
if [ ! -f "app/app.py" ]; then
    echo "Error: app/app.py not found in ${APP_DIR}/app/"
    exit 1
fi

# Run the application
python3 -u app/app.py &

# Store child PID
CHILD_PID=$!

# Wait for the Python process to finish
wait $CHILD_PID
EXIT_CODE=$?

echo "Application exited with code $EXIT_CODE"
exit $EXIT_CODE