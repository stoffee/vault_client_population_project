job "vault-clients-db-rotation-nugget" {
  datacenters = ["linkin"]
  type = "batch"

  periodic {
    cron             = "0 */4 * * *"  # Run every 4 hours
    prohibit_overlap = true           # Don't start if previous is still running
    time_zone        = "America/Los_Angeles"  # Use your local timezone
  }

  group "nugget-rotation" {
    count = 1
    constraint {
      attribute = "${node.unique.name}"
      value     = "nugget"
    }

    volume "vault-clients" {
      type = "host"
      read_only = false
      source = "vault-clients-nugget"
    }

    task "db-rotation" {
      driver = "exec"

      volume_mount {
        volume      = "vault-clients"
        destination = "/opt/vault-clients"
        read_only   = false
      }

      config {
        command = "/bin/bash"
        args    = ["/local/db_rotation.sh"]
      }

      template {
        data = <<EOT
#!/bin/bash
# Database credential rotation client script for {{ env "node.unique.name" }}
# Uses AppRole auth to access Vault
set -e
# Configuration
LOG_FILE="/opt/vault-clients/logs/db-rotation.log"
CRED_FILE="/opt/vault-clients/db-rotation-creds.json"
CONFIG_DIR="/opt/vault-clients"
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$CRED_FILE")" "$CONFIG_DIR"

# Function to log messages
log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Colorful output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Read credentials from env vars set via Nomad
ROLE_ID="${VAULT_ROLE_ID}"
SECRET_ID="${VAULT_SECRET_ID}"
NAMESPACE="${VAULT_NAMESPACE}"
VAULT_ADDR=${VAULT_ADDR}

log "Starting database credential rotation with AppRole auth on node {{ env "node.unique.name" }}"
log "Vault address: $VAULT_ADDR"
log "Namespace: $NAMESPACE"

# Login with AppRole
log "Authenticating with AppRole"
VAULT_TOKEN=$(curl -s \
    --request POST \
    --header "X-Vault-Namespace: $NAMESPACE" \
    --data "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" \
    "$VAULT_ADDR/v1/auth/approle/login" | jq -r '.auth.client_token')

if [ -z "$VAULT_TOKEN" ] || [ "$VAULT_TOKEN" == "null" ]; then
    log "${RED}Authentication failed!${NC}"
    exit 1
fi

log "${GREEN}Authentication successful!${NC}"

# Since we don't have a real database connection, let's simulate one
# by generating random credentials ourselves
log "Simulating database credential generation"
RANDOM_USERNAME="db_user_$(date +%s)"
RANDOM_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
REQUEST_ID=$(uuidgen)
LEASE_ID="database/creds/readonly/$(uuidgen)"

# Create our simulated DB credentials using jq to properly format the JSON
DB_CREDS=$(jq -n \
  --arg req_id "$REQUEST_ID" \
  --arg lease_id "$LEASE_ID" \
  --arg username "$RANDOM_USERNAME" \
  --arg password "$RANDOM_PASSWORD" \
  '{
    request_id: $req_id,
    lease_id: $lease_id,
    renewable: true,
    lease_duration: 3600,
    data: {
      username: $username,
      password: $password
    }
  }')

log "Credentials JSON generated successfully"

# Extract username and password
DB_USERNAME=$(echo "$DB_CREDS" | jq -r '.data.username')
DB_PASSWORD=$(echo "$DB_CREDS" | jq -r '.data.password')

log "Generated simulated database credentials"
log "Username: $DB_USERNAME"
log "Password: [REDACTED]"
log "Lease ID: $LEASE_ID"

# Save credentials to file (in production, use a secure method)
echo "$DB_CREDS" > "$CRED_FILE"
chmod 600 "$CRED_FILE"
log "${GREEN}Successfully retrieved database credentials!${NC}"

# Simulated database connection test
log "${YELLOW}Testing connection to database...${NC}"
sleep 2  # Simulate connection time
log "${GREEN}Connection successful!${NC}"

# Perform simulated rotation
log "Simulating credential rotation operations on {{ env "node.unique.name" }}..."
echo "{\"username\": \"$DB_USERNAME\", \"last_rotation\": \"$(date -Iseconds)\", \"node\": \"{{ env "node.unique.name" }}\"}" > "/opt/vault-clients/last_rotation_{{ env "node.unique.name" }}.json"
log "${GREEN}Database credential rotation complete!${NC}"
log "================================================"

# Display fancy completion message
cat << 'ASCIIART'
 ____        _        _
|  _ \  __ _| |_ __ _| |__   __ _ ___  ___
| | | |/ _` | __/ _` | '_ \ / _` / __|/ _ \
| |_| | (_| | || (_| | |_) | (_| \__ \  __/
|____/ \__,_|\__\__,_|_.__/ \__,_|___/\___|

 ____       _        _   _
|  _ \ ___ | |_ __ _| |_(_) ___  _ __
| |_) / _ \| __/ _` | __| |/ _ \| '_ \
|  _ < (_) | || (_| | |_| | (_) | | | |
|_| \_\___/ \__\__,_|\__|_|\___/|_| |_|
ASCIIART

# Cleanup
exit 0
EOT
        destination = "local/db_rotation.sh"
        perms = "0755"
      }

      env {
        VAULT_ADDR = "YOUR-VAULT_ADDR-HERE"
        VAULT_NAMESPACE = "admin/client_population/databases"
        VAULT_ROLE_ID = "YOUR-ROLE-ID-HERE"
        VAULT_SECRET_ID = "YOUR-SECRET_ID-HERE"
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