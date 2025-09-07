#!/bin/bash

# This script collects device information and a list of non-Apple applications.
# The output is a single JSON object printed to standard output.

# Retrieve device identifiers
ManagedDeviceID=$(security find-certificate -a | awk -F= '/issu/ && /MICROSOFT INTUNE MDM DEVICE CA/ { getline; gsub(/"/, "", $2); print $2}' | head -n 1)
ComputerName=$(scutil --get ComputerName)
DeviceSerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Start building the JSON output
json_output="{"
json_output+="\"ComputerName\": \"$ComputerName\","
json_output+="\"DeviceSerialNumber\": \"$DeviceSerialNumber\","
json_output+="\"ManagedDeviceID\": \"$ManagedDeviceID\","
json_output+="\"Applications\": ["

# Collecting application data
app_list=""
IFS=$'\n'
for line in $(system_profiler SPApplicationsDataType); do
    if [[ "$line" =~ "Location:" ]]; then
        appPath=$(echo "$line" | awk -F": " '{print $2}')
        appName=$(basename "$appPath" .app)
    elif [[ "$line" =~ "Version:" ]]; then
        bundleId=$(defaults read "$appPath/Contents/Info" CFBundleIdentifier 2>/dev/null)
        if [[ "$bundleId" != *"apple"* ]]; then
            appVersion=$(echo "$line" | awk -F": " '{print $2}')
            # Escape double quotes in appName for valid JSON
            appNameEscaped=$(echo "$appName" | sed 's/"/\\"/g')
            app_list+="{\"AppName\": \"$appNameEscaped\", \"AppVersion\": \"$appVersion\"},"
        fi
    fi
done
IFS=$' \t\n'

# Remove the trailing comma from the app list
if [ -n "$app_list" ]; then
    app_list=${app_list%,}
fi

json_output+="$app_list"
json_output+="]}"

# Print the final JSON object
echo "$json_output"
