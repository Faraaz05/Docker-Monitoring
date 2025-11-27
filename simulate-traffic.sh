#!/bin/bash

BASE_URL="http://localhost:80/"

# --------------------------
# Adjustable settings
# --------------------------
MAX_CONCURRENCY=10      # safe for your CPU
MIN_REQUESTS=10          # min total requests
MAX_REQUESTS=40          # max total requests
SLEEP_BETWEEN=5       # seconds

SAFE_ROUTES=(
  "/app1/wrong"
  "/app1/ping"
  "/app1/ping"
  "/app1/data"
  "/app1/data"
  "/app2/ping"
  "/app2/simulate-network-lag"
)

HEAVY_ROUTES=(
  "/app2/slow"
  "/app2/disk"
  "/app2/leak"
  "/app2/crash"
  "/app2/random-crash"
  "/app2/error"
)

VERY_HEAVY_ROUTES=(
    "/app2/cpu"
)

send_requests() {
    local C=$1

    # random total request count in a safe range
    local N=$(( (RANDOM % (MAX_REQUESTS - MIN_REQUESTS + 1)) + MIN_REQUESTS ))

    # route selection with probabilities:
    #  - 2% VERY_HEAVY_ROUTES
    #  - 78% SAFE_ROUTES
    #  - 20% HEAVY_ROUTES
    local R=$(( RANDOM % 100 ))
    if (( R < 2 )); then
        ROUTE=${VERY_HEAVY_ROUTES[$RANDOM % ${#VERY_HEAVY_ROUTES[@]}]}
    elif (( R < 70 )); then
        ROUTE=${SAFE_ROUTES[$RANDOM % ${#SAFE_ROUTES[@]}]}
    else
        ROUTE=${HEAVY_ROUTES[$RANDOM % ${#HEAVY_ROUTES[@]}]}
    fi

    echo "[$(date '+%H:%M:%S')] c=$C n=$N → $ROUTE"
    hey -n "$N" -c "$C" "$BASE_URL$ROUTE" >/dev/null 2>&1
}

# Gentle ramp (you can increase MAX_CONCURRENCY for more load)
while true; do
    # ramp-up
    for ((c=1; c<=MAX_CONCURRENCY; c++)); do
        send_requests $c
        sleep $SLEEP_BETWEEN
    done

    # ramp-down
    for ((c=MAX_CONCURRENCY; c>=1; c--)); do
        send_requests $c
        sleep $SLEEP_BETWEEN
    done
done
