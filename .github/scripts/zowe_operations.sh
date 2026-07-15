#!/bin/bash

# Disable OS keychain — not available on CI runners.
# ZOWE_CLI_PLUGINS_DIR is unrelated; the correct knob is the credential store
# env var and explicitly clearing the "secure" arrays in each profile.
export ZOWE_APP_LOG_LEVEL=ERROR

# Convert username to lowercase
LOWERCASE_USERNAME=$(echo "$ZOWE_USERNAME" | tr '[:upper:]' '[:lower:]')

# ZOWE CLI Profile init (plain-text, no secure credential store)
echo "Initializing ZOWE CLI Profile..."
zowe config init --global-config --no-prompt

# -----------------------------------------------------------------------
# All "config set" calls use --secure false so Zowe writes the value as
# plain text instead of delegating to the OS keychain (unavailable in CI).
# Credentials come from GitHub Secrets and are never stored beyond the job.
# -----------------------------------------------------------------------

# ZOWE CLI Profile setting (ZOSMF)
echo "Setting ZOSMF profile..."
zowe config set profiles.zosmf.type                              "zosmf"  --global-config
zowe config set profiles.zosmf.properties.host                 "$ZOWE_HOST" --global-config
zowe config set profiles.zosmf.properties.port                 "$ZOWE_PORT" --global-config
zowe config set profiles.zosmf.properties.rejectUnauthorized   "false"   --global-config
zowe config set profiles.zosmf.secure                          "[]"      --global-config

# ZOWE CLI Profile setting (Global Base)
echo "Setting GLOBAL_BASE profile..."
zowe config set profiles.global_base.type                           "base"           --global-config
zowe config set profiles.global_base.properties.host                "$ZOWE_HOST"     --global-config
zowe config set profiles.global_base.properties.rejectUnauthorized  "false"          --global-config
zowe config set profiles.global_base.properties.user                "$ZOWE_USERNAME" --global-config --secure false
zowe config set profiles.global_base.properties.password            "$ZOWE_PASSWORD" --global-config --secure false
zowe config set profiles.global_base.secure                         "[]"             --global-config

# ZOWE CLI Profile setting (Bind to Defaults)
echo "Binding ZOSMF and GLOBAL_BASE profiles to Defaults..."
zowe config set defaults.zosmf  "zosmf"       --global-config
zowe config set defaults.base   "global_base" --global-config

# Validate ZOSMF connection
echo "Testing z/OSMF connection..."
if ! zowe zosmf check status; then
    echo "ERROR: Could not connect to z/OSMF. Aborting."
    exit 1
fi
echo "Connection OK."

# Check if directory exists, create if it does not
if ! zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck" &>/dev/null; then
    echo "Directory does not exist. Creating it..."
    zowe zos-files create uss-directory "/z/$LOWERCASE_USERNAME/cobolcheck"
else
    echo "Directory already exists."
fi

# Upload files (note: --binary-files must be on the same logical line)
zowe zos-files upload dir-to-uss "./cobol-check" "/z/$LOWERCASE_USERNAME/cobolcheck" \
  --recursive \
  --binary-files "cobol-check-0.2.19.jar"

# Verify upload
echo "Verifying upload:"
zowe zos-files list uss-files "/z/$LOWERCASE_USERNAME/cobolcheck"
