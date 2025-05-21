job "vault-clients-batch-processing" {
  datacenters = ["awamoa"]
  type = "batch"

  periodic {
    crons             = ["0 2 * * *"]  # Run daily at 2 AM
    prohibit_overlap = true
    time_zone        = "Pacific/Honolulu"
  }

  group "batch-processing" {
    count = 1
    constraint {
      attribute = "${node.unique.name}"
      value     = "lil-pakalolo"
    }

    volume "vault-clients" {
      type = "host"
      read_only = false
      source = "vault-clients-lil-pakalolo"
    }

    task "batch-processor" {
      driver = "exec"

      volume_mount {
        volume      = "vault-clients"
        destination = "/opt/vault-clients"
        read_only   = false
      }

      config {
        command = "/bin/bash"
        args    = ["/local/batch_processing.sh"]
      }

      template {
        data = <<EOT
#!/bin/bash
# Batch token processing client script for {{ env "node.unique.name" }}
# Uses Username/Password auth to access Vault for batch jobs
set -e

# Configuration
LOG_FILE="/opt/vault-clients/logs/batch-processing.log"
RESULT_DIR="/opt/vault-clients/results"
CONFIG_DIR="/opt/vault-clients"
mkdir -p "$(dirname "$LOG_FILE")" "$RESULT_DIR" "$CONFIG_DIR"

# Function to log messages
log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Read credentials from env vars
USERNAME="${VAULT_USERNAME}"
PASSWORD="${VAULT_PASSWORD}"
NAMESPACE="${VAULT_NAMESPACE}"
VAULT_ADDR=${VAULT_ADDR}

# Generate unique batch job ID
BATCH_JOB_ID="batch-$(date +%Y%m%d-%H%M%S)"
log "Starting batch processing job: $BATCH_JOB_ID on node {{ env "node.unique.name" }}"
log "Vault address: $VAULT_ADDR"
log "Namespace: $NAMESPACE"

# Login with Username/Password
log "Authenticating with Username/Password"
VAULT_TOKEN=$(curl -s \
    --request POST \
    --header "X-Vault-Namespace: $NAMESPACE" \
    --data "{\"password\":\"$PASSWORD\"}" \
    "$VAULT_ADDR/v1/auth/userpass/login/$USERNAME" | jq -r '.auth.client_token')

if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" == "null" ]; then
    log "Authentication failed!"
    exit 1
fi

log "Authentication successful!"

# Get batch job configurations
log "Retrieving batch job configurations"
JOBS_LIST=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "X-Vault-Namespace: $NAMESPACE" \
    --request LIST \
    "$VAULT_ADDR/v1/kv/metadata/jobs" | jq -r '.data.keys[]')

if [ -z "$JOBS_LIST" ]; then
    log "No batch jobs found"
    exit 0
fi

log "Found batch jobs: $JOBS_LIST"

# Process each batch job
SUCCESS_COUNT=0
FAILURE_COUNT=0

for JOB in $JOBS_LIST; do
    log "Processing job: $JOB"
    
    # Get job configuration
    JOB_CONFIG=$(curl -s \
        --header "X-Vault-Token: $VAULT_TOKEN" \
        --header "X-Vault-Namespace: $NAMESPACE" \
        --request GET \
        "$VAULT_ADDR/v1/kv/data/jobs/$JOB")
    
    JOB_NAME=$(echo "$JOB_CONFIG" | jq -r '.data.data.job_name')
    JOB_DESC=$(echo "$JOB_CONFIG" | jq -r '.data.data.description')
    JOB_PRIORITY=$(echo "$JOB_CONFIG" | jq -r '.data.data.priority')
    
    log "Job details: $JOB_NAME ($JOB_DESC) - Priority: $JOB_PRIORITY"
    
    # Simulate batch processing
    log "Starting batch process for $JOB_NAME..."
    
    # Create a random processing time based on priority
    case "$JOB_PRIORITY" in
        "high")
            PROCESS_TIME=$((RANDOM % 5 + 1))
            ;;
        "medium")
            PROCESS_TIME=$((RANDOM % 10 + 5))
            ;;
        "low")
            PROCESS_TIME=$((RANDOM % 15 + 10))
            ;;
        *)
            PROCESS_TIME=$((RANDOM % 10 + 5))
            ;;
    esac
    
    log "Processing job $JOB_NAME for $PROCESS_TIME seconds..."
    sleep $PROCESS_TIME
    
    # Simulate success/failure (90% success rate)
    if [ $((RANDOM % 10)) -lt 9 ]; then
        log "Job $JOB_NAME completed successfully"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        
        # Save result
        echo "{\"job_id\": \"$JOB\", \"batch_id\": \"$BATCH_JOB_ID\", \"status\": \"success\", \"timestamp\": \"$(date -Iseconds)\", \"processing_time\": $PROCESS_TIME}" > "$RESULT_DIR/${JOB}_${BATCH_JOB_ID}.json"
    else
        log "Job $JOB_NAME failed"
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        
        # Save result
        echo "{\"job_id\": \"$JOB\", \"batch_id\": \"$BATCH_JOB_ID\", \"status\": \"failed\", \"timestamp\": \"$(date -Iseconds)\", \"processing_time\": $PROCESS_TIME}" > "$RESULT_DIR/${JOB}_${BATCH_JOB_ID}.json"
    fi
done

# Summary
log "Batch processing summary:"
log "  Total jobs: $((SUCCESS_COUNT + FAILURE_COUNT))"
log "  Successful: $SUCCESS_COUNT"
log "  Failed: $FAILURE_COUNT"

# Create summary file
echo "{\"batch_id\": \"$BATCH_JOB_ID\", \"total\": $((SUCCESS_COUNT + FAILURE_COUNT)), \"success\": $SUCCESS_COUNT, \"failed\": $FAILURE_COUNT, \"timestamp\": \"$(date -Iseconds)\"}" > "$RESULT_DIR/${BATCH_JOB_ID}_summary.json"

# Revoke the token when done
log "Revoking Vault token"
curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "X-Vault-Namespace: $NAMESPACE" \
    --request POST \
    "$VAULT_ADDR/v1/auth/token/revoke-self"

log "Batch processing completed!"

# Display a fun ASCII art completion message
cat << 'EOF'
  ____        _       _       ____                                _             
 | __ )  __ _| |_ ___| |__   |  _ \ _ __ ___   ___ ___  ___ ___(_)_ __   __ _ 
 |  _ \ / _` | __/ __| '_ \  | |_) | '__/ _ \ / __/ _ \/ __/ __| | '_ \ / _` |
 | |_) | (_| | || (__| | | | |  __/| | | (_) | (_|  __/\__ \__ \ | | | | (_| |
 |____/ \__,_|\__\___|_| |_| |_|   |_|  \___/ \___\___||___/___/_|_| |_|\__, |
                                                                          |___/ 
   ____                      _      _       _ 
  / ___|___  _ __ ___  _ __ | | ___| |_ ___| |
 | |   / _ \| '_ ` _ \| '_ \| |/ _ \ __/ _ \ |
 | |__| (_) | | | | | | |_) | |  __/ ||  __/_|
  \____\___/|_| |_| |_| .__/|_|\___|\__\___(_)
                      |_|                     
EOF

exit 0
EOT
        destination = "local/batch_processing.sh"
        perms = "0755"
      }

      env {
        VAULT_ADDR = "https://vault.example.com:8200"
        VAULT_NAMESPACE = "admin/client_population/batch"
        VAULT_USERNAME = "batch-processor"
        VAULT_PASSWORD = "dummy-password-for-testing"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }

    ephemeral_disk {
      size = 300
    }
  }
}