job "vault-clients-encryption-lilikoi" {
  datacenters = ["awamoa"]
  type = "batch"

  periodic {
    crons        = ["0 */6 * * *"]  # Run every 6 hours
    prohibit_overlap = true
    time_zone        = "America/Los_Angeles"
  }

  group "lilikoi-encryption" {
    count = 1
    constraint {
      attribute = "${node.unique.name}"
      value     = "lilikoi"
    }

    volume "vault-clients" {
      type = "host"
      read_only = false
      source = "vault-clients-lilikoi"
    }

    task "encryption-service" {
      driver = "exec"

      volume_mount {
        volume      = "vault-clients"
        destination = "/opt/vault-clients"
        read_only   = false
      }

      config {
        command = "/bin/bash"
        args    = ["/local/encryption_service.sh"]
      }

      template {
        data = <<EOT
#!/bin/bash
# Encryption as a Service client for {{ env "node.unique.name" }}
# Uses Token auth to access Vault Transit engine
set -e

# Configuration
LOG_FILE="/opt/vault-clients/logs/encryption-service.log"
DATA_DIR="/opt/vault-clients/data"
mkdir -p "$(dirname "$LOG_FILE")" "$DATA_DIR"

# Function to log messages
log() {
    echo "[$(date)] $1" | tee -a "$LOG_FILE"
}

# Colors for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vault configuration from env vars
VAULT_TOKEN="${VAULT_TOKEN}"
VAULT_ADDR="${VAULT_ADDR}"
VAULT_NAMESPACE="${VAULT_NAMESPACE}"

# File to encrypt
SAMPLE_FILE="$DATA_DIR/sample-$(date +%s).txt"
ENCRYPTED_FILE="$DATA_DIR/encrypted-$(date +%s).base64"
DECRYPTED_FILE="$DATA_DIR/decrypted-$(date +%s).txt"
META_FILE="$DATA_DIR/encryption-meta.json"

log "Starting Encryption Service client on {{ env "node.unique.name" }}"
log "Vault address: $VAULT_ADDR"
log "Namespace: $VAULT_NAMESPACE"

# Generate random file content
log "${BLUE}Generating random file content...${NC}"
RANDOM_CONTENT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 200 | head -n 10)
echo "$RANDOM_CONTENT" > "$SAMPLE_FILE"
log "Generated sample file: $SAMPLE_FILE"

# Authenticate to Vault using token
log "${BLUE}Authenticating to Vault...${NC}"
# Verify token is valid
TOKEN_INFO=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "X-Vault-Namespace: $VAULT_NAMESPACE" \
    "$VAULT_ADDR/v1/auth/token/lookup-self")

if echo "$TOKEN_INFO" | grep -q "invalid token"; then
    log "${RED}Authentication failed: Invalid token${NC}"
    exit 1
fi

# Get token TTL and display it
TOKEN_TTL=$(echo "$TOKEN_INFO" | jq -r '.data.ttl')
log "${GREEN}Authentication successful. Token TTL: $TOKEN_TTL seconds${NC}"

# Encrypt the file
log "${BLUE}Encrypting file using Transit engine...${NC}"
# Base64 encode the file first
BASE64_CONTENT=$(base64 -w 0 "$SAMPLE_FILE")

# Use Transit to encrypt
ENCRYPT_RESPONSE=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "X-Vault-Namespace: $VAULT_NAMESPACE" \
    --request POST \
    --data "{\"plaintext\": \"$BASE64_CONTENT\", \"context\": \"$(echo -n "lilikoi-encryption-context" | base64)\"}" \
    "$VAULT_ADDR/v1/transit/encrypt/app-encryption-key")

# Check for error
if echo "$ENCRYPT_RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$ENCRYPT_RESPONSE" | jq -r '.errors[]')
    log "${RED}Encryption failed: $ERROR_MSG${NC}"
    exit 1
fi

# Extract ciphertext
CIPHERTEXT=$(echo "$ENCRYPT_RESPONSE" | jq -r '.data.ciphertext')
log "Encryption successful. Ciphertext: $(echo "$CIPHERTEXT" | cut -c 1-40)..."

# Save ciphertext to file
echo "$CIPHERTEXT" > "$ENCRYPTED_FILE"
log "Saved encrypted data to $ENCRYPTED_FILE"

# Decrypt the file
log "${BLUE}Decrypting file using Transit engine...${NC}"
DECRYPT_RESPONSE=$(curl -s \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --header "X-Vault-Namespace: $VAULT_NAMESPACE" \
    --request POST \
    --data "{\"ciphertext\": \"$CIPHERTEXT\", \"context\": \"$(echo -n "lilikoi-encryption-context" | base64)\"}" \
    "$VAULT_ADDR/v1/transit/decrypt/app-encryption-key")

# Check for error
if echo "$DECRYPT_RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$DECRYPT_RESPONSE" | jq -r '.errors[]')
    log "${RED}Decryption failed: $ERROR_MSG${NC}"
    exit 1
fi

# Extract plaintext
PLAINTEXT=$(echo "$DECRYPT_RESPONSE" | jq -r '.data.plaintext')
log "Decryption successful. Got base64 plaintext."

# Base64 decode and save to file
echo "$PLAINTEXT" | base64 -d > "$DECRYPTED_FILE"
log "Decoded and saved to $DECRYPTED_FILE"

# Verify files match
if diff "$SAMPLE_FILE" "$DECRYPTED_FILE" >/dev/null; then
    log "${GREEN}Verification successful: Original and decrypted files match!${NC}"
else
    log "${RED}Verification failed: Files don't match${NC}"
    exit 1
fi

# Create metadata file with stats
jq -n \
    --arg timestamp "$(date -Iseconds)" \
    --arg node "{{ env "node.unique.name" }}" \
    --arg original_size "$(stat -c%s "$SAMPLE_FILE")" \
    --arg encrypted_size "$(stat -c%s "$ENCRYPTED_FILE")" \
    --arg key "app-encryption-key" \
    '{
        "timestamp": $timestamp,
        "node": $node,
        "original_size_bytes": $original_size,
        "encrypted_size_bytes": $encrypted_size,
        "encryption_key": $key,
        "success": true
    }' > "$META_FILE"

log "${GREEN}Encryption service run complete!${NC}"
log "================================================"

# Display fancy ASCII art completion message
cat << 'EOF'
 _____                             _   _             
| ____|_ __   ___ _ __ _   _ _ __ | |_(_) ___  _ __  
|  _| | '_ \ / __| '__| | | | '_ \| __| |/ _ \| '_ \ 
| |___| | | | (__| |  | |_| | |_) | |_| | (_) | | | |
|_____|_| |_|\___|_|   \__, | .__/ \__|_|\___/|_| |_|
                       |___/|_|                      
  ____                  _          
 / ___|  ___ _ ____   _(_) ___ ___ 
 \___ \ / _ \ '__\ \ / / |/ __/ _ \
  ___) |  __/ |   \ V /| | (_|  __/
 |____/ \___|_|    \_/ |_|\___\___|
EOF

# Cleanup (remove files older than 7 days)
find "$DATA_DIR" -name "sample-*" -mtime +7 -delete
find "$DATA_DIR" -name "encrypted-*" -mtime +7 -delete
find "$DATA_DIR" -name "decrypted-*" -mtime +7 -delete

exit 0
EOT
        destination = "local/encryption_service.sh"
        perms = "0755"
      }

      env {
        VAULT_ADDR = "https://your-vault-cluster:8200"
        VAULT_NAMESPACE = "admin/client_population/encryption"
        VAULT_TOKEN = "YOUR_ENCRYPTION_TOKEN_HERE"
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