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
echo "=== Environment Debug Information ==="
echo "Current directory: $(pwd)"
echo "APP_DIR: ${APP_DIR}"
echo "RUNPOD_VOLUME_PATH: ${RUNPOD_VOLUME_PATH}"
echo ""

echo "=== Directory Structure ==="
echo "Root directory contents:"
ls -la /
echo ""
echo "APP_DIR contents:"
ls -la ${APP_DIR}
echo ""
echo "APP_DIR/app contents:"
ls -la ${APP_DIR}/app
echo ""
echo "RUNPOD_VOLUME_PATH contents:"
ls -la ${RUNPOD_VOLUME_PATH}
echo ""

# Start the Python application
echo "Starting Flux application..."

# Check both potential locations
APP_PATHS=(
    "${APP_DIR}/app/app.py"
    "${RUNPOD_VOLUME_PATH}/app/app.py"
)

FOUND_APP=""
for path in "${APP_PATHS[@]}"; do
    echo "Checking for app at: $path"
    if [ -f "$path" ]; then
        echo "Found app at: $path"
        FOUND_APP="$path"
        break
    fi
done

if [ -z "$FOUND_APP" ]; then
    echo "Error: app.py not found in any of the expected locations!"
    echo "Tried:"
    printf '%s\n' "${APP_PATHS[@]}"
    exit 1
fi

# Run the application from where we found it
echo "Running app from: $FOUND_APP"
python3 -u "$FOUND_APP" &

# Store child PID
CHILD_PID=$!

# Wait for the Python process to finish
wait $CHILD_PID
EXIT_CODE=$?

echo "Application exited with code $EXIT_CODE"
exit $EXIT_CODE