#!/bin/bash

# A simple script to check basic macOS security settings.

# Get current date and time for logging
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# --- Helper Functions ---
log_info() {
    echo "$TIMESTAMP [INFO]  $1" >&2
}

# --- Main Logic ---
log_info "mac_audit_enhanced starting (PID $$)"
log_info "Version: 1.0.0"
log_info "Logging to stderr"
log_info "Starting security collection"

# --- System Information ---
OS_VERSION=$(sw_vers -productVersion)
OS_BUILD=$(sw_vers -buildVersion)
ARCH=$(uname -m)
log_info "OS: $OS_VERSION [$OS_BUILD] $ARCH"

# --- Security Checks ---

# Check FileVault Status
FV_STATUS=$(fdesetup status)
if [[ $FV_STATUS == *"On"* ]]; then
    log_info "FileVault: Enabled"
else
    log_info "FileVault: Disabled"
fi

# Check Gatekeeper Status
GK_STATUS=$(spctl --status)
if [[ $GK_STATUS == *"assessments enabled"* ]]; then
    log_info "Gatekeeper: Enabled"
else
    log_info "Gatekeeper: Disabled"
fi

# Check XProtect Version
XPROTECT_VERSION=$(defaults read /System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "Unknown")
log_info "XProtect: $XPROTECT_VERSION"

# Check System Integrity Protection (SIP)
SIP_STATUS=$(csrutil status)
if [[ $SIP_STATUS == *"enabled"* ]]; then
    log_info "SIP: Enabled"
else
    log_info "SIP: Disabled"
fi

# Check Secure Boot Level
# Note: This is a simplified check. A full check is more complex.
SECURE_BOOT_LEVEL=$(nvram boot-args 2>/dev/null)
if [[ -z "$SECURE_BOOT_LEVEL" ]]; then
    log_info "Secure Boot: Full"
else
    log_info "Secure Boot: Reduced"
fi


log_info "Collection complete"
log_info "Run complete"

exit 0
