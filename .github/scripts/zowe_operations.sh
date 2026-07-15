#!/bin/bash

# Disable OS keychain/credential store — not available on CI runners
export ZOWE_CLI_PLUGINS_DIR=""
export ZOWE_SECURE_CREDENTIALS_ENABLED=false

# Convert username to lowercase
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

# ZOWE CLI Profile init
zowe config init --global-config --no-prompt

# ZOWE CLI Profile setting (ZOSMF)
zowe config set profiles.zosmf.type            "zosmf"      --global-config
zowe config set profiles.zosmf.properties.host "$ZOWE_HOST" --global-config
zowe config set profiles.zosmf.properties.port "$ZOWE_PORT" --global-config

# ZOWE CLI Profile setting (Global Base)
# Credentials are stored as plain text in the ephemeral runner config.
# They originate from GitHub Secrets and are never persisted beyond the job.
zowe config set profiles.global_base.type                           "base"           --global-config
zowe config set profiles.global_base.properties.host                "$ZOWE_HOST"     --global-config
zowe config set profiles.global_base.properties.rejectUnauthorized  "false"          --global-config
zowe config set profiles.global_base.properties.user                "$ZOWE_USERNAME" --global-config
zowe config set profiles.global_base.properties.password            "$ZOWE_PASSWORD" --global-config

# ZOWE CLI Profile setting (Bind to Defaults)
zowe config set defaults.zosmf  "zosmf"       --global-config
zowe config set defaults.base   "global_base" --global-config

# Validate ZOSMF connection
echo "Testing z/OSMF connection..."
if ! zowe zosmf check status; then
    echo "ERROR: Could not connect to z/OSMF. Aborting."
    exit 1
fi
echo "Connection OK."

# Check if directory exists, create if does not
if ! zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck" &>/dev/null; then
    echo "Directory does not exist. Creating it..."
    zowe zos-files create uss-directory /z/$LOWERCASE_USERNAME/cobolcheck
else
    echo "Directory already exists."
fi

# Upload files
zowe zos-files upload dir-to-uss "./cobol-check" "/z/$LOWERCASE_USERNAME/cobolcheck" --recursive
  --binary-files "cobol-check-0.2.19.jar"

# Verify upload
echo "Verifying upload:"
zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck"