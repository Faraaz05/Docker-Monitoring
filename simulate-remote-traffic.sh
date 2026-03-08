#!/bin/bash

# Usage: ./simulate-remote-traffic.sh <EC2_PUBLIC_IP>
# Example: ./simulate-remote-traffic.sh 13.204.68.212

if [ -z "$1" ]; then
    echo "Usage: $0 <EC2_PUBLIC_IP>"
    echo "Example: $0 13.204.68.212"
    exit 1
fi

EC2_IP="$1"
BASE_URL="http://${EC2_IP}:80"

echo "Starting traffic simulation to $BASE_URL"
echo "Press Ctrl+C to stop"
echo "-------------------------------------------"

# --------------------------
# Lightweight settings for 2GB EC2 instance
# --------------------------
MAX_CONCURRENCY=3          # Very low concurrency to avoid overwhelming
MIN_REQUESTS=3             # Minimal requests per batch
MAX_REQUESTS=8             # Low max to prevent memory issues
SLEEP_BETWEEN=8            # Longer sleep between requests

# Route distribution optimized for low resource usage
SAFE_ROUTES=(
  "/app1/ping"
  "/app1/ping"
  "/app1/ping"
  "/app1/data"
  "/app1/data"
  "/app2/ping"
  "/app2/ping"
  "/app1/wrong"
)

# Moderate load routes - use sparingly
MODERATE_ROUTES=(
  "/app2/simulate-network-lag"
  "/app2/slow"
  "/app2/error"
)

# Heavy routes - very rare
HEAVY_ROUTES=(
  "/app2/disk"
  "/app2/leak"
)

# Extremely heavy routes - almost never hit
VERY_HEAVY_ROUTES=(
  "/app2/cpu"
  "/app2/random-crash"
  "/app2/crash"
)

send_requests() {
    local C=$1

    # Random total request count in a safe range
    local N=$(( (RANDOM % (MAX_REQUESTS - MIN_REQUESTS + 1)) + MIN_REQUESTS ))

    # Route selection with probabilities optimized for low resource usage:
    #  - 70% SAFE_ROUTES (lightweight)
    #  - 20% MODERATE_ROUTES
    #  - 8% HEAVY_ROUTES
    #  - 2% VERY_HEAVY_ROUTES (computational intensive - rare)
    local R=$(( RANDOM % 100 ))
    if (( R < 70 )); then
        ROUTE=${SAFE_ROUTES[$RANDOM % ${#SAFE_ROUTES[@]}]}
    elif (( R < 90 )); then
        ROUTE=${MODERATE_ROUTES[$RANDOM % ${#MODERATE_ROUTES[@]}]}
    elif (( R < 98 )); then
        ROUTE=${HEAVY_ROUTES[$RANDOM % ${#HEAVY_ROUTES[@]}]}
    else
        ROUTE=${VERY_HEAVY_ROUTES[$RANDOM % ${#VERY_HEAVY_ROUTES[@]}]}
    fi

    echo "[$(date '+%H:%M:%S')] concurrency=$C requests=$N → $ROUTE"
    
    # Use curl instead of hey if hey is not available
    if command -v hey &> /dev/null; then
        hey -n "$N" -c "$C" "$BASE_URL$ROUTE" >/dev/null 2>&1
    else
        # Fallback to curl in a loop
        for ((i=0; i<N; i++)); do
            curl -s "$BASE_URL$ROUTE" >/dev/null 2>&1 &
            if (( i % C == 0 )); then
                wait
            fi
        done
        wait
    fi
}

# Check if hey is installed, suggest installation if not
if ! command -v hey &> /dev/null; then
    echo "Warning: 'hey' is not installed. Using curl as fallback (less efficient)."
    echo "To install hey: go install github.com/rakyll/hey@latest"
    echo "Or on Mac: brew install hey"
    echo ""
fi

# Very gentle ramp to avoid overwhelming the EC2 instance
while true; do
    # Gradual ramp-up
    for ((c=1; c<=MAX_CONCURRENCY; c++)); do
        send_requests $c
        sleep $SLEEP_BETWEEN
    done

    # Extra pause at peak to let system recover
    echo "[$(date '+%H:%M:%S')] Peak reached, pausing to let system recover..."
    sleep 15

    # Gradual ramp-down
    for ((c=MAX_CONCURRENCY; c>=1; c--)); do
        send_requests $c
        sleep $SLEEP_BETWEEN
    done
    
    # Longer pause between cycles to prevent sustained high load
    echo "[$(date '+%H:%M:%S')] Cycle complete, pausing before next cycle..."
    sleep 20
done
