# MacBeacon Configuration Guide

## Overview
MacBeacon now supports configuration via plist files for MDM deployment. This allows you to configure Azure Log Analytics workspace details and other settings without hardcoding them in the application.

## Configuration File Locations

The app will look for configuration files in the following order:

1. **App Bundle** (Development): `MacBeacon.app/Contents/Resources/MacBeaconConfig.plist`
2. **User Application Support**: `~/Library/Application Support/MacBeacon/MacBeaconConfig.plist`
3. **System Application Support**: `/Library/Application Support/MacBeacon/MacBeaconConfig.plist`

## Adding Configuration File to Xcode Project

To include the configuration file in your app bundle for development:

1. **Open** `MacBeacon.xcodeproj` in Xcode
2. **Right-click** on the "MacBeacon" group in the Project Navigator
3. **Select** "Add Files to MacBeacon..."
4. **Navigate** to `MacBeacon/Resources/`
5. **Select** `MacBeaconConfig.plist`
6. **Ensure** "Add to target: MacBeacon" is checked
7. **Click** "Add"

Alternatively, you can drag and drop `MacBeaconConfig.plist` from Finder into the MacBeacon group in Xcode's Project Navigator.

**Note**: The plist file is already located in `MacBeacon/Resources/MacBeaconConfig.plist` - you just need to add it to the Xcode project.

## Configuration File Format

Create a plist file named `MacBeaconConfig.plist` with the following structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>azureLogAnalytics</key>
    <dict>
        <key>enabled</key>
        <true/>
        <key>workspaceId</key>
        <string>YOUR_WORKSPACE_ID_HERE</string>
        <key>primaryKey</key>
        <string>YOUR_PRIMARY_KEY_HERE</string>
        <key>logTypeName</key>
        <string>MacBeaconLogs</string>
    </dict>
    <key>logging</key>
    <dict>
        <key>level</key>
        <string>Info</string>
        <key>enableConsoleLogging</key>
        <true/>
    </dict>
    <key>refresh</key>
    <dict>
        <key>autoRefresh</key>
        <true/>
        <key>interval</key>
        <real>30.0</real>
    </dict>
</dict>
</plist>
```

## Configuration Options

### Azure Log Analytics
- **enabled**: `true`/`false` - Enable or disable Azure Log Analytics
- **workspaceId**: Your Azure Log Analytics workspace ID
- **primaryKey**: Your Azure Log Analytics primary key
- **logTypeName**: Custom log type name (default: "MacBeaconLogs")

### Logging
- **level**: Log level - "Debug", "Info", "Warning", "Error"
- **enableConsoleLogging**: `true`/`false` - Enable console logging

### Refresh Settings
- **autoRefresh**: `true`/`false` - Enable automatic data refresh
- **interval**: Refresh interval in seconds (default: 30.0)

## MDM Deployment

### Option 1: Include in Package
1. Add `MacBeaconConfig.plist` to your package
2. Install it to `/Library/Application Support/MacBeacon/`
3. The app will automatically load configuration from this location

### Option 2: Deploy Separately
1. Create a separate package with just the configuration file
2. Deploy it to `/Library/Application Support/MacBeacon/MacBeaconConfig.plist`
3. Deploy the main app package

### Option 3: User-Specific Configuration
1. Deploy configuration to `~/Library/Application Support/MacBeacon/MacBeaconConfig.plist`
2. This allows per-user configuration

## Security Considerations

- **Primary Key Security**: The Azure Log Analytics primary key is stored in plain text in the plist file
- **File Permissions**: Ensure the plist file has appropriate permissions (600 or 644)
- **MDM Management**: Use MDM to manage and update configuration files as needed

## Default Behavior

If no configuration file is found, the app will use these defaults:
- Azure Log Analytics: **Disabled**
- Log Level: **Info**
- Console Logging: **Enabled**
- Auto Refresh: **Enabled**
- Refresh Interval: **30 seconds**

## Troubleshooting

### Check Configuration Loading
The app will print configuration details to the console on startup. Look for:
```
📋 [ConfigurationManager] Loaded configuration from: [path]
📋 [ConfigurationManager] Current configuration:
   Azure Log Analytics:
     Enabled: true/false
     Workspace ID: [masked]
     Primary Key: [masked]
     Log Type: MacBeaconLogs
```

### Common Issues
1. **Configuration not loading**: Check file path and permissions
2. **Azure not working**: Verify workspace ID and primary key are correct
3. **Settings not applying**: Ensure plist format is valid XML

## Example MDM Commands

### Deploy Configuration File
```bash
# Create directory
sudo mkdir -p "/Library/Application Support/MacBeacon"

# Copy configuration file
sudo cp MacBeaconConfig.plist "/Library/Application Support/MacBeacon/"

# Set permissions
sudo chmod 644 "/Library/Application Support/MacBeacon/MacBeaconConfig.plist"
sudo chown root:wheel "/Library/Application Support/MacBeacon/MacBeaconConfig.plist"
```

### Update Configuration
```bash
# Update the configuration file
sudo cp UpdatedMacBeaconConfig.plist "/Library/Application Support/MacBeacon/MacBeaconConfig.plist"

# Restart the app to pick up new configuration
sudo killall MacBeacon
```
