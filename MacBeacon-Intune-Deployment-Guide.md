# MacBeacon Intune Deployment Guide

## Overview
This guide explains how to deploy MacBeacon via Microsoft Intune using Configuration Profiles for Azure Log Analytics configuration.

## Files Required
- `MacBeacon.pkg` - The application package
- `MacBeaconConfig.plist` - Configuration file with your Azure Log Analytics details

## Deployment Steps

### 1. Create Configuration File
1. Create a file named `MacBeaconConfig.plist` with your Azure Log Analytics details:
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
        <string>YOUR_WORKSPACE_ID</string>
        <key>primaryKey</key>
        <string>YOUR_PRIMARY_KEY</string>
        <key>logTypeName</key>
        <string>MacBeaconLogs</string>
        <key>weeklyReporting</key>
        <dict>
            <key>enabled</key>
            <true/>
            <key>intervalDays</key>
            <integer>7</integer>
            <key>sendInstallationData</key>
            <true/>
        </dict>
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
2. Replace `YOUR_WORKSPACE_ID` and `YOUR_PRIMARY_KEY` with your actual Azure Log Analytics credentials

### 2. Upload Application Package
1. Go to **Microsoft Endpoint Manager** (https://endpoint.microsoft.com)
2. Navigate to **Apps** → **macOS** → **Add** → **macOS app (PKG)**
3. Upload `MacBeacon.pkg`
4. Configure app information:
   - **Name**: MacBeacon Security Monitor
   - **Description**: Enterprise security monitoring and compliance reporting application
   - **Publisher**: Maverick Labs
   - **Category**: Security
   - **Minimum OS**: macOS 15.5
5. Assign to your target groups (Required or Available)

### 3. Deploy Configuration File
**Option A: Include in App Bundle (Recommended)**
1. Include `MacBeaconConfig.plist` in your app bundle during the build process
2. The app will automatically read the configuration on startup

**Option B: Deploy via Intune Configuration Profile (Recommended)**
1. Go to **Devices** → **macOS** → **Configuration profiles**
2. Click **Add** → **Custom configuration**
3. Upload your `MacBeaconConfig.mobileconfig` file (or XML format)
4. **Important**: The configuration profile must target bundle identifier: `com.mavericklabs.MacBeacon`
5. **No need to specify exact location** - the app will automatically find it in common Intune deployment locations:
   - `/Library/Managed Preferences/MacBeaconConfig.plist`
   - `/Library/Preferences/MacBeaconConfig.plist`
   - `/var/db/ConfigurationProfiles/MacBeaconConfig.plist`
   - `/Library/Application Support/MacBeacon/MacBeaconConfig.plist`
   - `/Users/Shared/MacBeaconConfig.plist`
   - `/tmp/MacBeaconConfig.plist`
6. Assign to the same groups as the application

### 4. Configuration Profile Structure

**Option A: .mobileconfig Format (Recommended)**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadIdentifier</key>
            <string>com.mavericklabs.MacBeacon.config</string>
            <key>PayloadType</key>
            <string>com.apple.ManagedClient.preferences</string>
            <key>PayloadUUID</key>
            <string>1230B747-8BF0-45F9-B6EC-BFDE2322CCD4</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            <key>PayloadEnabled</key>
            <true/>
            <key>PayloadContent</key>
            <dict>
                <key>com.mavericklabs.MacBeacon</key>
                <dict>
                    <key>Forced</key>
                    <array>
                        <dict>
                            <key>mcx_preference_settings</key>
                            <dict>
                                <key>azureLogAnalytics</key>
                                <dict>
                                    <key>enabled</key>
                                    <true/>
                                    <key>workspaceId</key>
                                    <string>YOUR_WORKSPACE_ID</string>
                                    <key>primaryKey</key>
                                    <string>YOUR_PRIMARY_KEY</string>
                                    <key>logType</key>
                                    <string>MacBeaconLogs</string>
                                    <key>weeklyReporting</key>
                                    <dict>
                                        <key>enabled</key>
                                        <true/>
                                        <key>intervalDays</key>
                                        <integer>7</integer>
                                        <key>sendInstallationData</key>
                                        <true/>
                                    </dict>
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
                        </dict>
                    </array>
                </dict>
            </dict>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>MacBeacon Security Monitor Configuration</string>
    <key>PayloadDisplayName</key>
    <string>MacBeacon Configuration</string>
    <key>PayloadIdentifier</key>
    <string>com.mavericklabs.MacBeacon.featurecontrol</string>
    <key>PayloadOrganization</key>
    <string>Maverick Labs</string>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>92B11F89-C204-48C1-9654-A6C4E355C6D8</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
    <key>PayloadRemovalDisallowed</key>
    <true/>
</dict>
</plist>
```

**Option B: Simple XML Format**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <bundleIdentifier>com.mavericklabs.MacBeacon</bundleIdentifier>
    <azureLogAnalytics>
        <enabled>true</enabled>
        <workspaceId>YOUR_WORKSPACE_ID</workspaceId>
        <primaryKey>YOUR_PRIMARY_KEY</primaryKey>
        <logType>MacBeaconLogs</logType>
        <weeklyReporting>
            <enabled>true</enabled>
            <intervalDays>7</intervalDays>
            <sendInstallationData>true</sendInstallationData>
        </weeklyReporting>
    </azureLogAnalytics>
    <logging>
        <level>Info</level>
        <enableConsoleLogging>true</enableConsoleLogging>
    </logging>
    <refresh>
        <autoRefresh>true</autoRefresh>
        <interval>30.0</interval>
    </refresh>
</configuration>
```

**Key Configuration Fields:**
- **bundleIdentifier**: Must match your app: `com.mavericklabs.MacBeacon`
- **azureLogAnalytics.workspaceId**: Your Azure Log Analytics workspace ID
- **azureLogAnalytics.primaryKey**: Your Azure Log Analytics primary key
- **azureLogAnalytics.logType**: Log type name (default: "MacBeaconLogs")
- **logging.level**: Log level (Debug, Info, Warning, Error)
- **refresh.interval**: Auto-refresh interval in seconds

## How It Works

1. **App Installation**: Intune installs MacBeacon.pkg to `/Applications/MacBeacon.app`
2. **Configuration Deployment**: Intune deploys the configuration profile to the device
3. **App Startup**: MacBeacon reads configuration from the system configuration profile
4. **Azure Connection**: App automatically connects to your Azure Log Analytics workspace

## Verification

After deployment, you can verify the configuration by:

1. **Check Console Logs**: Look for configuration loading messages:
   - `✅ [ConfigurationManager] Loaded configuration from Intune Configuration Profile`
   - `✅ [ConfigurationManager] Azure Log Analytics configuration is valid`

2. **App Interface**: The app will show "Azure Log Analytics configured" instead of "Running in Local Mode"

3. **Azure Log Analytics**: Check your workspace for incoming MacBeacon logs

## Troubleshooting

### App Shows "Local Mode"
- Verify the configuration profile is assigned to the same groups as the app
- Check that the configuration profile was successfully deployed
- Ensure the Workspace ID and Primary Key are correctly set

### Configuration Not Loading
- Verify the configuration profile structure matches the template
- Check that all required keys are present
- Ensure the PayloadIdentifier matches the app's bundle identifier

### Azure Connection Issues
- Verify the Workspace ID and Primary Key are correct
- Check Azure Log Analytics workspace permissions
- Ensure the device has internet connectivity

## Support

For technical support or questions about MacBeacon deployment, contact Maverick Labs support team.

---
**Version**: 1.0  
**Last Updated**: September 2024  
**Compatible with**: MacBeacon v1.0+, macOS 15.5+
