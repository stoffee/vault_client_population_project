# Database Credential Rotation Client Documentation

## Overview

This document describes the Vault database credential rotation client that we've configured for the `thiccboi` and `nugget` nodes in our HashiStack homelab. This client simulates the generation and rotation of database credentials using Vault's AppRole authentication method.

## Purpose

The database credential rotation client demonstrates how applications can securely retrieve dynamic database credentials from Vault. This implementation:

1. Authenticates to Vault using the AppRole auth method
2. Simulates the retrieval of dynamic database credentials
3. Saves the credentials to a secure file on the host
4. Automatically rotates credentials every 4 hours

## Initial Setup

Before deploying the Nomad job, you need to create and register the host volumes on each server that will run this job. Run the following script on each target server:

```bash
#!/bin/bash
# setup_vault_clients_volume.sh
# Create directory structure
sudo mkdir -p /opt/nomad/vault-clients/{logs,creds,scripts}
sudo chmod -R 755 /opt/nomad/vault-clients
# Get hostname
HOSTNAME=$(hostname)
# Create registration config
cat > /tmp/vault-clients-register.hcl << EOF
type = "host"
name = "vault-clients-${HOSTNAME}"
node_id = "$(nomad node status -self -t '{{ .ID }}')"
host_path = "/opt/nomad/vault-clients"
EOF
# Register the volume
nomad volume register /tmp/vault-clients-register.hcl
```

This script performs the following actions:
1. Creates the necessary directory structure on the host server
2. Sets appropriate permissions for the directories
3. Generates a Nomad volume configuration based on the hostname
4. Registers the volume with Nomad

After running this script, verify that the volume was created successfully:

```bash
nomad volume status -type=host "vault-clients-$(hostname)"
```

## Implementation Details

### Job Configuration

The client is implemented as a Nomad batch job with the following characteristics:

- **Job Type**: `batch`
- **Scheduling**: Runs every 4 hours using Nomad's built-in periodic scheduler
- **Node Targeting**: Constrained to run only on specific nodes (`thiccboi` and `nugget`)
- **Volume**: Uses a host volume named `vault-clients-thiccboi` or `vault-clients-nugget` to persist data
- **Authentication**: Uses Vault AppRole auth with role ID and secret ID

### Script Functionality

The client script performs the following steps:

1. **Authentication**: Logs in to Vault using AppRole credentials
2. **Credential Generation**: Simulates generation of database credentials
3. **Credential Storage**: Stores generated credentials in a secure JSON file
4. **Rotation Simulation**: Simulates a database connection test and credential rotation
5. **Logging**: Maintains a detailed log of all operations for troubleshooting

### Files and Directories

The client uses the following file structure on each host:

- `/opt/vault-clients/logs/db-rotation.log` - Log file for all operations
- `/opt/vault-clients/db-rotation-creds.json` - Secure file containing current database credentials
- `/opt/vault-clients/last_rotation_<nodename>.json` - Metadata about the last credential rotation

## Deployment

The client has been deployed to both `thiccboi` and `nugget` nodes. Each node has a dedicated job configured with the appropriate node constraint.

### Job Files

- `vault-clients-db-rotation-thiccboi.nomad.hcl` - Job file for thiccboi node
- `vault-clients-db-rotation-nugget.nomad.hcl` - Job file for nugget node

These job files are identical except for the node constraint and job ID.

### Vault Configuration

The client uses the following Vault configuration:

- **Namespace**: `admin/client_population/databases`
- **Auth Method**: AppRole
- **Role**: Database client role with appropriate policy
- **Endpoint**: Database credentials endpoint (simulated in this implementation)

## Monitoring

### Logs

You can check the client logs in two ways:

1. **Job Logs**: `nomad job logs -stderr <alloc-id>` for real-time execution logs
2. **Persistent Logs**: `/opt/vault-clients/logs/db-rotation.log` on the host for historical logs

### Status

To check job status and schedule:

```bash
# List all periodic jobs
nomad job status

# See when the next run is scheduled
nomad job status vault-clients-db-rotation-thiccboi

# See the most recent allocations
nomad job allocs vault-clients-db-rotation-thiccboi
```

## Troubleshooting

Common issues and their solutions:

1. **Authentication Failures**
   - Check that the AppRole credentials are valid
   - Ensure the Vault endpoint is accessible
   - Verify the namespace is correct

2. **UUID Generation Errors**
   - The script implements a custom UUID generator for nodes that don't have `uuidgen`
   - If this fails, check that bash's `RANDOM` function is working

3. **File Permission Issues**
   - Check that the Nomad job has write permissions to the host volume
   - Verify that the directories exist and have appropriate permissions

4. **Volume Not Found Error**
   - Ensure you've run the setup script to create and register the host volume
   - Check that the volume name in the job matches the registered volume name
   - Verify with `nomad volume status -type=host <volume-name>`

## Future Enhancements

Potential improvements for this client:

1. **Real Database Integration**: Connect to an actual database instance
2. **Credential Leasing**: Implement proper lease management, including renewal and revocation
3. **Health Monitoring**: Add proper health checks and integration with monitoring systems
4. **Secret Zero Problem**: Implement a more secure method for AppRole credential delivery