#!/bin/bash
set -e

PG_HOST="10.0.1.20"
PG_USER="ticketapp"
PG_PASSWORD="ddd"
RABBITMQ_HOST="10.0.1.10"
RABBITMQ_USER="admin"
RABBITMQ_PASSWORD="ddd"

RESULTS_DIR="./results"
mkdir -p "$RESULTS_DIR"

cleanup() {
    echo "=== Cleaning environment ==="
    
    # Purgar colas RabbitMQ
    echo "Purging RabbitMQ queues..."
    python3 cleanup.py \
        --pg-host "$PG_HOST" \
        --pg-user "$PG_USER" \
        --pg-password "$PG_PASSWORD" \
        --rabbitmq-host "$RABBITMQ_HOST" \
        --rabbitmq-user "$RABBITMQ_USER" \
        --rabbitmq-password "$RABBITMQ_PASSWORD"
    
    # Verificar que las colas están vacías
    echo "Verifying queues are empty..."
    for i in {1..10}; do
        queue_status=$(curl -s -u "$RABBITMQ_USER:$RABBITMQ_PASSWORD" \
            "http://$RABBITMQ_HOST:15672/api/queues/%2F/tickets.buy" 2>/dev/null | \
            grep -o '"messages":[0-9]*' | cut -d: -f2 || echo "999")
        
        if [ "$queue_status" = "0" ] || [ "$queue_status" = "" ]; then
            echo "Queue is empty"
            break
        fi
        
        echo "Queue has $queue_status messages, waiting... ($i/10)"
        sleep 3
    done
    
    # Verificar que no hay transacciones bloqueadas en PostgreSQL
    echo "Checking for blocked transactions..."
    blocked=$(python3 << EOF
import psycopg2
try:
    conn = psycopg2.connect(host='$PG_HOST', user='$PG_USER', password='$PG_PASSWORD', dbname='$PG_DB', connect_timeout=5)
    cur = conn.cursor()
    cur.execute("""
        SELECT COUNT(*) FROM pg_stat_activity 
        WHERE datname = '$PG_DB' 
        AND state = 'idle in transaction'
        AND age(clock_timestamp(), query_start) > interval '10 seconds'
    """)
    count = cur.fetchone()[0]
    conn.close()
    print(count)
except:
    print("0")
EOF
)
    
    if [ "$blocked" != "0" ] && [ "$blocked" != "" ]; then
        echo "WARNING: $blocked blocked transactions detected. Killing them..."
        python3 << EOF
import psycopg2
conn = psycopg2.connect(host='$PG_HOST', user='postgres', password='$PG_PASSWORD', dbname='$PG_DB', connect_timeout=5)
cur = conn.cursor()
cur.execute("""
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '$PG_DB' AND pid <> pg_backend_pid()
""")
conn.close()
print("Blocked transactions terminated")
EOF
        sleep 2
    fi
    
    echo "Cleanup complete"
}

save_results() {
    local experiment=$1
    local run_name=$2
    local dest="$RESULTS_DIR/$experiment/$run_name"
    mkdir -p "$dest"
    cp exports/*.csv "$dest/" 2>/dev/null || echo "Warning: No CSV files to copy"
    echo "Results saved to $dest"
}

echo "=========================================="
echo "AWSTicket Experiment Suite"
echo "=========================================="
echo "Start time: $(date)"
echo ""

# ==========================================
# A) CALIBRATION
# ==========================================
echo ""
echo "=========================================="
echo "A) CALIBRATION - Measuring worker capacity"
echo "=========================================="

for rate in 10 50 100; do
    echo ""
    echo "--- Calibration: rate=$rate msg/s ---"
    cleanup
    
    PYTHONPATH=../loadgen python3 run_experiment.py \
        --type calibration \
        --rates "$rate" \
        --pg-host "$PG_HOST" \
        --pg-user "$PG_USER" \
        --pg-password "$PG_PASSWORD" \
        --rabbitmq-host "$RABBITMQ_HOST" \
        --rabbitmq-user "$RABBITMQ_USER" \
        --rabbitmq-password "$RABBITMQ_PASSWORD"
    
    save_results "calibration" "rate_${rate}"
    echo "Waiting 10s before next run..."
    sleep 10
done

# ==========================================
# B) SPEEDUP
# ==========================================
echo ""
echo "=========================================="
echo "B) SPEEDUP - Scaling workers"
echo "=========================================="
echo "NOTE: You need to manually scale workers between runs"
echo "Run this from your LOCAL machine:"
echo "  aws ecs update-service --cluster awsticket-cluster --service awsticket-worker-svc --desired-count N --region us-east-1"
echo ""

for workers in 1 2 4 8; do
    echo ""
    echo "--- Speedup: workers=$workers ---"
    echo "ACTION REQUIRED: Scale to $workers workers now"
    read -p "Press Enter when workers are ready (runningCount=$workers)..."
    
    cleanup
    
    PYTHONPATH=../loadgen python3 run_experiment.py \
        --type speedup \
        --workers "$workers" \
        --rate 300 \
        --pg-host "$PG_HOST" \
        --pg-user "$PG_USER" \
        --pg-password "$PG_PASSWORD" \
        --rabbitmq-host "$RABBITMQ_HOST" \
        --rabbitmq-user "$RABBITMQ_USER" \
        --rabbitmq-password "$RABBITMQ_PASSWORD"
    
    save_results "speedup" "workers_${workers}"
    echo "Waiting 15s before next run..."
    sleep 15
done

# ==========================================
# C) STRESS
# ==========================================
echo ""
echo "=========================================="
echo "C) STRESS - Finding saturation point"
echo "=========================================="

cleanup

PYTHONPATH=../loadgen python3 run_experiment.py \
    --type stress \
    --workers 4 \
    --max-rate 1000 \
    --pg-host "$PG_HOST" \
    --pg-user "$PG_USER" \
    --pg-password "$PG_PASSWORD" \
    --rabbitmq-host "$RABBITMQ_HOST" \
    --rabbitmq-user "$RABBITMQ_USER" \
    --rabbitmq-password "$RABBITMQ_PASSWORD"

save_results "stress" "max_rate_1000"

# ==========================================
# D) ELASTICITY
# ==========================================
echo ""
echo "=========================================="
echo "D) ELASTICITY - Z(t) workload with autoscaling"
echo "=========================================="

for run in 1 2; do
    echo ""
    echo "--- Elasticity: run $run/2 ---"
    cleanup
    
    PYTHONPATH=../loadgen python3 run_experiment.py \
        --type elasticity \
        --workers-min 1 \
        --workers-max 20 \
        --pg-host "$PG_HOST" \
        --pg-user "$PG_USER" \
        --pg-password "$PG_PASSWORD" \
        --rabbitmq-host "$RABBITMQ_HOST" \
        --rabbitmq-user "$RABBITMQ_USER" \
        --rabbitmq-password "$RABBITMQ_PASSWORD"
    
    save_results "elasticity" "run_${run}"
    echo "Waiting 20s before next run..."
    sleep 20
done

# ==========================================
# E) CONTENTION
# ==========================================
echo ""
echo "=========================================="
echo "E) CONTENTION - Uniform vs Hotspot"
echo "=========================================="

# Uniform
echo ""
echo "--- Contention: Uniform distribution ---"
cleanup

PYTHONPATH=../loadgen python3 run_experiment.py \
    --type contention \
    --hotspot-pct 100 \
    --hotspot-traffic 100 \
    --pg-host "$PG_HOST" \
    --pg-user "$PG_USER" \
    --pg-password "$PG_PASSWORD" \
    --rabbitmq-host "$RABBITMQ_HOST" \
    --rabbitmq-user "$RABBITMQ_USER" \
    --rabbitmq-password "$RABBITMQ_PASSWORD"

save_results "contention" "uniform"

# Hotspot 80/5
echo ""
echo "--- Contention: Hotspot 80/5 ---"
cleanup

PYTHONPATH=../loadgen python3 run_experiment.py \
    --type contention \
    --hotspot-pct 5 \
    --hotspot-traffic 80 \
    --pg-host "$PG_HOST" \
    --pg-user "$PG_USER" \
    --pg-password "$PG_PASSWORD" \
    --rabbitmq-host "$RABBITMQ_HOST" \
    --rabbitmq-user "$RABBITMQ_USER" \
    --rabbitmq-password "$RABBITMQ_PASSWORD"

save_results "contention" "hotspot_80_5"

echo ""
echo "=========================================="
echo "All experiments complete!"
echo "=========================================="
echo "End time: $(date)"
echo ""
echo "Results saved to: $RESULTS_DIR/"
echo ""
echo "Next steps:"
echo "1. Copy results to your local machine:"
echo "   scp -r user@loadgen:/path/to/results/ ./results/"
echo ""
echo "2. Generate plots:"
echo "   cd analysis"
echo "   python3 plot_results.py --input-dir ../experiments/results --output-dir ./plots"
