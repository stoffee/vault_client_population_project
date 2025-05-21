# Batch Token Processing Client Documentation

## Overview

This document describes the Vault batch token processing client configured for the `lil-pakalolo` node in our HashiStack homelab. This client simulates batch processing jobs that use Vault for authentication and configuration.

## Purpose

The batch token processing client demonstrates how scheduled batch jobs can securely authenticate to Vault using Username/Password auth, retrieve job configurations, and process them with appropriate security measures. This implementation:

1. Authenticates to Vault using Username/Password authentication
2. Retrieves batch job configurations from the KV store
3. Processes each job with simulated workloads
4. Records results and creates a summary report
5. Properly revokes the Vault token when finished
6. Runs automatically on a daily schedule

## Initial Setup

Before deploying the Nomad job, you need to create and register the host volume on the lil-pakalolo server:

```bash
#!/bin/bash
# setup_vault_clients_volume_hawaii.sh
# Create directory structure for lil-pakalolo
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up vault-clients volume for lil-pakalolo...${NC}"

# Create directory structure
sudo mkdir -p /opt/nomad/vault-clients/{logs,results,scripts}
sudo chmod -R 755 /opt/nomad/vault-clients

# Get node ID
NODE_ID=$(nomad node status -self -t '{{ .ID }}')

if [ -z "$NODE_ID" ]; then
    echo -e "${RED}Failed to get Nomad node ID. Is Nomad running?${NC}"
    exit 1
fi

# Create registration config
echo -e "${BLUE}Creating volume registration file...${NC}"
cat > /tmp/vault-clients-register.hcl << EOF
type = "host"
name = "vault-clients-lil-pakalolo"
node_id = "${NODE_ID}"
host_path = "/opt/nomad/vault-clients"
EOF

# Register the volume
echo -e "${BLUE}Registering volume with Nomad...${NC}"
nomad volume register /tmp/vault-clients-register.hcl

# Check if registration was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Volume registered successfully!${NC}"
    echo -e "${BLUE}Verifying volume status...${NC}"
    nomad volume status -type=host "vault-clients-lil-pakalolo"
else
    echo -e "${RED}Failed to register volume!${NC}"
    exit 1
fi

echo -e "${GREEN}Setup complete! The vault-clients volume is ready for batch processing.${NC}"
```

## Implementation Details

### Job Configuration

The client is implemented as a Nomad batch job with the following characteristics:

- **Job Type**: `batch`
- **Scheduling**: Runs daily at 2:00 AM using Nomad's built-in periodic scheduler
- **Node Targeting**: Constrained to run only on the `lil-pakalolo` node
- **Volume**: Uses a host volume named `vault-clients-lil-pakalolo` to persist data
- **Authentication**: Uses Vault Username/Password auth with pre-configured credentials

### Script Functionality

The client script performs the following steps:

1. **Authentication**: Logs in to Vault using Username/Password credentials
2. **Job Discovery**: Lists available batch jobs in the KV store
3. **Job Processing**: For each job, simulates processing with variable timing based on priority
4. **Result Recording**: Records success/failure status for each job
5. **Summary Generation**: Creates a summary report for the batch run
6. **Token Revocation**: Revokes the Vault token when processing is complete
7. **Logging**: Maintains a detailed log of all operations for troubleshooting

### Files and Directories

The client uses the following file structure on the host:

- `/opt/vault-clients/logs/batch-processing.log` - Log file for all operations
- `/opt/vault-clients/results/<job>_<batch_id>.json` - Individual job results
- `/opt/vault-clients/results/<batch_id>_summary.json` - Batch run summary

## Vault Configuration

The client uses the following Vault configuration:

- **Namespace**: `admin/client_population/batch`
- **Auth Method**: UserPass
- **Username**: `batch-processor`
- **Policy**: `batch-job-policy`
- **KV Data**: Job configurations stored at `kv/data/jobs/*`

## Monitoring

### Logs

You can check the client logs in two ways:

1. **Job Logs**: `nomad job logs -stderr <alloc-id>` for real-time execution logs
2. **Persistent Logs**: `/opt/vault-clients/logs/batch-processing.log` on the host for historical logs

### Results

Review batch processing results:

```bash
# View the most recent summary
ls -lt /opt/vault-clients/results/*_summary.json | head -1 | xargs cat

# Check results for a specific batch ID
ls /opt/vault-clients/results/<batch_id>*.json
```

## Troubleshooting

Common issues and their solutions:

1. **Authentication Failures**
   - Check that the Username/Password credentials are valid
   - Ensure the Vault endpoint is accessible
   - Verify the namespace is correct

2. **No Jobs Found Error**
   - Ensure that batch job configurations exist in the KV store
   - Check that the KV path is correct (`kv/data/jobs/`)
   - Verify that the batch-processor user has list permission on the KV path

3. **File Permission Issues**
   - Check that the Nomad job has write permissions to the host volume
   - Verify that the directories exist and have appropriate permissions

4. **Volume Not Found Error**
   - Ensure you've run the setup script to create and register the host volume
   - Verify with `nomad volume status -type=host vault-clients-lil-pakalolo`