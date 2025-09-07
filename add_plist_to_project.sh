#!/bin/bash

# Script to add MacBeaconConfig.plist to Xcode project
# Run this script from the MacBeacon project root directory

echo "Adding MacBeaconConfig.plist to Xcode project..."

# Check if the plist file exists
if [ ! -f "MacBeacon/Resources/MacBeaconConfig.plist" ]; then
    echo "Error: MacBeaconConfig.plist not found in MacBeacon/Resources/"
    exit 1
fi

# Check if Xcode project exists
if [ ! -f "MacBeacon.xcodeproj/project.pbxproj" ]; then
    echo "Error: MacBeacon.xcodeproj not found"
    exit 1
fi

echo "✅ MacBeaconConfig.plist found in Resources directory"
echo "✅ Xcode project found"

echo ""
echo "To add the plist file to your Xcode project:"
echo "1. Open MacBeacon.xcodeproj in Xcode"
echo "2. Right-click on the 'MacBeacon' group in the Project Navigator"
echo "3. Select 'Add Files to MacBeacon...'"
echo "4. Navigate to MacBeacon/Resources/"
echo "5. Select MacBeaconConfig.plist"
echo "6. Make sure 'Add to target: MacBeacon' is checked"
echo "7. Click 'Add'"
echo ""
echo "Alternatively, you can drag and drop MacBeaconConfig.plist from Finder"
echo "into the MacBeacon group in Xcode's Project Navigator."
echo ""
echo "After adding the file, it will be automatically bundled with the app"
echo "and the ConfigurationManager will be able to load it."
