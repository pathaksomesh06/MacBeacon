#!/bin/bash

# CIS Controls Level 1 - Comprehensive macOS Security Audit
# Aligned with mSCP (macOS Security Compliance Project)
# Based on CIS Controls Version 8
# Version 2.0

REPORT_FILE="audit_reports/cis_level1_comprehensive_report.html"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
MACOS_VERSION=$(sw_vers -productVersion)
BUILD_VERSION=$(sw_vers -buildVersion)

# Counters for each CIS Control category
IG1_TOTAL=0; IG1_PASS=0; IG1_FAIL=0; IG1_MANUAL=0
OVERALL_SCORE=0

# Initialize comprehensive HTML report
init_html_report() {
    mkdir -p audit_reports
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CIS Controls Level 1 - Comprehensive macOS Security Audit</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1600px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 10px 40px rgba(0,0,0,0.15); }
        .header { background: linear-gradient(135deg, #4169E1, #6495ED); color: white; padding: 50px; border-radius: 15px 15px 0 0; position: relative; overflow: hidden; }
        .header::before { content: ''; position: absolute; top: -50%; right: -50%; width: 200%; height: 200%; background: repeating-linear-gradient(45deg, transparent, transparent 1px, rgba(255,255,255,0.1) 1px, rgba(255,255,255,0.1) 20px); }
        .header h1 { margin: 0; font-size: 24px; font-weight: 300; position: relative; z-index: 1; }
        .header .subtitle { font-size: 14px; opacity: 0.9; margin-top: 8px; position: relative; z-index: 1; }
        .header .system-info { font-size: 10px; opacity: 0.8; margin-top: 12px; position: relative; z-index: 1; }
        .content { padding: 20px; }
        
        .dashboard-container {
            background-color: #f8f9fa;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 15px;
        }

        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 10px;
        }

        .dashboard-card {
            background-color: #ffffff;
            border-radius: 6px;
            padding: 10px;
            display: flex;
            align-items: center;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
        }

        .dashboard-card .icon {
            font-size: 16px;
            margin-right: 8px;
            padding: 6px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .dashboard-card .details {
            flex-grow: 1;
        }

        .dashboard-card h3 {
            margin: 0 0 3px 0;
            font-size: 10px;
            color: #6c757d;
            font-weight: 500;
        }

        .dashboard-card .value {
            margin: 0;
            font-size: 18px;
            font-weight: 700;
        }
        
        .dashboard-card .sub-text {
            margin: 3px 0 0 0;
            font-size: 8px;
            color: #6c757d;
        }
        
        /* Card Specific Colors */
        .overall-risk { border-top: 4px solid #dc3545; }
        .overall-risk .icon { background-color: #f8d7da; color: #721c24; }
        .overall-risk .value { color: #dc3545; }

        .manual-reviews { border-top: 4px solid #ffc107; }
        .manual-reviews .icon { background-color: #fff3cd; color: #856404; }
        .manual-reviews .value { color: #856404; }

        .failed-controls { border-top: 4px solid #fd7e14; }
        .failed-controls .icon { background-color: #ffe8d6; color: #c05300; }
        .failed-controls .value { color: #fd7e14; }

        .passed-controls { border-top: 4px solid #28a745; }
        .passed-controls .icon { background-color: #d4edda; color: #155724; }
        .passed-controls .value { color: #28a745; }


        .summary-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
            margin-top: 15px;
        }

        .summary-card {
            color: white;
            padding: 8px;
            border-radius: 6px;
            text-align: center;
        }

        .summary-card h4 {
            margin: 0 0 4px 0;
            font-size: 9px;
            font-weight: 500;
        }

        .summary-card .value {
            font-size: 16px;
            font-weight: 700;
        }

        .summary-passed { background-color: #007bff; }
        .summary-score { background-color: #28a745; }
        .summary-manual { background-color: #ffc107; }
        .summary-failed { background-color: #dc3545; }

        .executive-summary { background: linear-gradient(135deg, #f8f9fa, #e9ecef); padding: 40px; border-radius: 15px; margin-bottom: 40px; border-left: 6px solid #4169E1; }
        
        .cis-control-section { margin-bottom: 20px; padding: 15px; border: 1px solid #e1e5e9; border-radius: 8px; background: #fafbfc; }
        .cis-control-header { border-bottom: 2px solid #4169E1; padding-bottom: 10px; margin-bottom: 15px; }
        .cis-control-title { color: #2c3e50; font-size: 16px; font-weight: 600; margin: 0; }
        .cis-control-description { color: #6c757d; font-size: 12px; margin-top: 5px; line-height: 1.4; }
        .cis-control-id { background: #4169E1; color: white; padding: 4px 8px; border-radius: 12px; font-size: 10px; font-weight: bold; display: inline-block; margin-bottom: 8px; }
        
        .sub-control { background: white; border: 1px solid #dee2e6; border-radius: 6px; margin: 10px 0; overflow: hidden; }
        .sub-control-header { background: linear-gradient(90deg, #f8f9fa, #e9ecef); padding: 10px; border-bottom: 1px solid #dee2e6; }
        .sub-control-id { font-family: 'Monaco', 'Courier New', monospace; font-size: 10px; background: #495057; color: white; padding: 2px 6px; border-radius: 8px; display: inline-block; margin-right: 8px; }
        .sub-control-title { font-weight: 600; color: #2c3e50; font-size: 12px; }
        .sub-control-body { padding: 12px; }
        .sub-control-description { color: #6c757d; margin-bottom: 10px; line-height: 1.3; font-size: 11px; }
        
        .check-result { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-bottom: 1px solid #f0f0f0; }
        .check-result:last-child { border-bottom: none; }
        .check-details { flex: 1; }
        .check-title { font-weight: 500; color: #2c3e50; margin-bottom: 5px; }
        .check-description { font-size: 14px; color: #6c757d; }
        .check-technical { font-size: 12px; color: #868e96; font-family: 'Monaco', 'Courier New', monospace; margin-top: 5px; }
        
        .status-badge { padding: 8px 16px; border-radius: 20px; font-weight: bold; font-size: 13px; text-transform: uppercase; }
        .status-pass { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .status-fail { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .status-manual { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
        .status-na { background: #e2e3e5; color: #383d41; border: 1px solid #c6c8ca; }
        
        .remediation { background: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; margin: 15px 0; border-radius: 5px; }
        .remediation h4 { color: #856404; margin-top: 0; }
        
        .implementation-guide { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 20px; margin: 15px 0; border-radius: 5px; }
        .implementation-guide h4 { color: #0c5460; margin-top: 0; }
        
        .progress-container { margin: 30px 0; }
        .progress-bar { width: 100%; height: 40px; background: #e9ecef; border-radius: 20px; overflow: hidden; position: relative; }
        .progress-fill { height: 100%; transition: width 1s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 16px; }
        .progress-excellent { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-good { background: linear-gradient(90deg, #17a2b8, #138496); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #e0a800); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #c82333); }
        
        .recommendations { background: #f8f9fa; padding: 40px; border-radius: 15px; margin-top: 40px; }
        .priority-high { border-left: 4px solid #dc3545; }
        .priority-medium { border-left: 4px solid #ffc107; }
        .priority-low { border-left: 4px solid #28a745; }
        
        .mscp-reference { background: #e7f3ff; border: 1px solid #b3d9ff; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .mscp-reference h5 { color: #0066cc; margin-top: 0; }
        
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .header::before { display: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ CIS Controls Level 1 - Comprehensive Security Audit</h1>
            <div class="subtitle">Implementation Group 1 (IG1) - Essential Cyber Hygiene</div>
            <div class="system-info">
                System: macOS $MACOS_VERSION (Build $BUILD_VERSION) |
                Assessment Date: $TIMESTAMP |
                Standard: CIS Controls v8.0 |
                Compliance Framework: mSCP Aligned
            </div>
        </div>
        <div class="content">
EOF
}

# Function to add check result with enhanced details
add_cis_check() {
    local control_id="$1"
    local title="$2"
    local status="$3"
    local description="$4"
    local technical_details="$5"
    local remediation="$6"
    
    IG1_TOTAL=$((IG1_TOTAL + 1))
    case $status in
        "PASS") IG1_PASS=$((IG1_PASS + 1)) ;;
        "FAIL") IG1_FAIL=$((IG1_FAIL + 1)) ;;
        "MANUAL") IG1_MANUAL=$((IG1_MANUAL + 1)) ;;
    esac
    
    local status_class=$(echo $status | tr '[:upper:]' '[:lower:]')
    
    cat >> "$REPORT_FILE" << EOF
                <div class="check-result">
                    <div class="check-details">
                        <div class="check-title">$title</div>
                        <div class="check-description">$description</div>
                        <div class="check-technical">Technical: $technical_details</div>
                    </div>
                    <div class="status-badge status-$status_class">$status</div>
                </div>
EOF

    if [ "$status" = "FAIL" ] && [ -n "$remediation" ]; then
        cat >> "$REPORT_FILE" << EOF
                <div class="remediation">
                    <h4>🔧 Immediate Remediation Required</h4>
                    <p>$remediation</p>
                </div>
EOF
    fi
}

# CIS Control 1: Inventory and Control of Enterprise Assets
check_cis_control_1() {
    echo "🔍 Auditing CIS Control 1: Inventory and Control of Enterprise Assets..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 1</div>
                    <h2 class="cis-control-title">Inventory and Control of Enterprise Assets</h2>
                    <p class="cis-control-description">Actively manage (inventory, track, and correct) all enterprise assets (end-user devices, including portable and mobile; network devices; non-computing/IoT devices; and servers) connected to the infrastructure physically, virtually, remotely, and those within cloud environments, to accurately know the totals and details of assets, in order to monitor and control what is connecting to the network.</p>
                </div>
                
                <div class="mscp-reference">
                    <h5>📋 mSCP Reference</h5>
                    <p>This control aligns with mSCP baseline requirements for asset management, system inventory, and device tracking in macOS environments.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">1.1</span>
                        <span class="sub-control-title">Establish and Maintain Detailed Enterprise Asset Inventory</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Establish and maintain an accurate, detailed, and up-to-date inventory of all enterprise assets with the potential to store or process data, to include: end-user devices (including portable and mobile), network devices, non-computing/IoT devices, and servers.</div>
EOF

    # Check system profiler availability for asset inventory
    local system_profiler_available=$(which system_profiler >/dev/null 2>&1 && echo "1" || echo "0")
    local hardware_overview=$(system_profiler SPHardwareDataType 2>/dev/null | grep -E "(Model Name|Serial Number|Hardware UUID)" | wc -l)
    
    if [ "$system_profiler_available" = "1" ] && [ "$hardware_overview" -ge 3 ]; then
        add_cis_check "1.1" "System Asset Inventory Available" "PASS" "System profiler provides comprehensive hardware inventory" "system_profiler SPHardwareDataType available" ""
    else
        add_cis_check "1.1" "System Asset Inventory Available" "FAIL" "Limited asset inventory capabilities" "system_profiler not available or incomplete" "Install and configure automated asset discovery tools"
    fi

    # Check for third-party asset management tools
    local jamf_binary=$(ls /usr/local/bin/jamf 2>/dev/null | wc -l)
    local munki_tools=$(ls /usr/local/munki 2>/dev/null | wc -l)
    
    if [ "$jamf_binary" -gt 0 ] || [ "$munki_tools" -gt 0 ]; then
        add_cis_check "1.1" "Enterprise Asset Management Tool" "PASS" "Third-party asset management solution detected" "JAMF or Munki tools present" ""
    else
        add_cis_check "1.1" "Enterprise Asset Management Tool" "MANUAL" "Manual verification required for asset management solution" "No standard MDM tools detected" "Deploy enterprise asset management solution (JAMF, Munki, etc.)"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">1.2</span>
                        <span class="sub-control-title">Address Unauthorized Assets</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Ensure that a process exists to address unauthorized assets on a weekly basis.</div>
EOF

    # Check for unauthorized device detection capabilities
    local network_interfaces=$(ifconfig -a | grep -E "^[a-z]" | wc -l)
    local active_connections=$(netstat -an | grep ESTABLISHED | wc -l)
    
    if [ "$network_interfaces" -le 5 ] && [ "$active_connections" -lt 50 ]; then
        add_cis_check "1.2" "Unauthorized Asset Detection" "PASS" "Limited network interfaces suggest controlled environment" "Network interfaces: $network_interfaces, Active connections: $active_connections" ""
    else
        add_cis_check "1.2" "Unauthorized Asset Detection" "MANUAL" "High number of network interfaces or connections" "Network interfaces: $network_interfaces, Active connections: $active_connections" "Implement network access control and unauthorized device detection"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 2: Inventory and Control of Software Assets
check_cis_control_2() {
    echo "🔍 Auditing CIS Control 2: Inventory and Control of Software Assets..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 2</div>
                    <h2 class="cis-control-title">Inventory and Control of Software Assets</h2>
                    <p class="cis-control-description">Actively manage (inventory, track, and correct) all software (operating systems and applications) on the network so that only authorized software is installed and can execute, and that unauthorized and unmanaged software is found and prevented from installation or execution.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">2.1</span>
                        <span class="sub-control-title">Establish and Maintain a Software Inventory</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Establish and maintain a detailed inventory of all licensed software installed on enterprise assets.</div>
EOF

    # Check Gatekeeper for software control
    local gatekeeper_status=$(spctl --status 2>/dev/null)
    local gatekeeper_enabled=$(echo "$gatekeeper_status" | grep "assessments enabled" | wc -l)
    
    if [ "$gatekeeper_enabled" -eq 1 ]; then
        add_cis_check "2.1" "Software Execution Control (Gatekeeper)" "PASS" "Gatekeeper enforces software verification" "spctl --status: $gatekeeper_status" ""
    else
        add_cis_check "2.1" "Software Execution Control (Gatekeeper)" "FAIL" "Gatekeeper disabled - unauthorized software can execute" "spctl --status: $gatekeeper_status" "Enable Gatekeeper: sudo spctl --master-enable"
    fi

    # Check System Integrity Protection
    local sip_status=$(csrutil status 2>/dev/null)
    local sip_enabled=$(echo "$sip_status" | grep "enabled" | wc -l)
    
    if [ "$sip_enabled" -eq 1 ]; then
        add_cis_check "2.1" "System Integrity Protection" "PASS" "SIP prevents unauthorized system software modification" "csrutil status: $sip_status" ""
    else
        add_cis_check "2.1" "System Integrity Protection" "FAIL" "SIP disabled - system integrity compromised" "csrutil status: $sip_status" "Re-enable SIP in Recovery mode: csrutil enable"
    fi

    # Check for software inventory tools
    local app_count=$(find /Applications -maxdepth 1 -name "*.app" | wc -l)
    local system_apps=$(find /System/Applications -maxdepth 1 -name "*.app" 2>/dev/null | wc -l)
    
    add_cis_check "2.1" "Application Inventory" "MANUAL" "Manual verification of installed applications required" "Applications: $app_count user apps, $system_apps system apps" "Implement automated software inventory solution"

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">2.2</span>
                        <span class="sub-control-title">Ensure Authorized Software is Currently Supported</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Ensure that only currently supported software is designated as authorized in the software inventory for enterprise assets.</div>
EOF

    # Check macOS version support status
    local macos_major=$(echo $MACOS_VERSION | cut -d. -f1)
    local macos_minor=$(echo $MACOS_VERSION | cut -d. -f2)
    local current_year=$(date +%Y)
    
    # macOS typically supports current and 2 previous major versions
    if [ "$macos_major" -ge 12 ] || ([ "$macos_major" -eq 11 ] && [ "$current_year" -le 2024 ]); then
        add_cis_check "2.2" "Operating System Support Status" "PASS" "macOS version is currently supported by Apple" "macOS $MACOS_VERSION (supported)" ""
    else
        add_cis_check "2.2" "Operating System Support Status" "FAIL" "macOS version may be end-of-life" "macOS $MACOS_VERSION (verify support status)" "Upgrade to supported macOS version"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 3: Data Protection
check_cis_control_3() {
    echo "🔍 Auditing CIS Control 3: Data Protection..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 3</div>
                    <h2 class="cis-control-title">Data Protection</h2>
                    <p class="cis-control-description">Develop processes and technical controls to identify, classify, securely handle, retain, and dispose of data.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">3.11</span>
                        <span class="sub-control-title">Encrypt Sensitive Data at Rest</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Encrypt sensitive data at rest on servers, applications, and databases containing sensitive data.</div>
EOF

    # Check FileVault encryption
    local filevault_status=$(fdesetup status 2>/dev/null)
    local filevault_enabled=$(echo "$filevault_status" | grep "FileVault is On" | wc -l)
    
    if [ "$filevault_enabled" -eq 1 ]; then
        add_cis_check "3.11" "Full Disk Encryption (FileVault)" "PASS" "FileVault provides comprehensive data-at-rest encryption" "fdesetup status: $filevault_status" ""
    else
        add_cis_check "3.11" "Full Disk Encryption (FileVault)" "FAIL" "FileVault not enabled - sensitive data unencrypted" "fdesetup status: $filevault_status" "Enable FileVault: System Preferences > Security & Privacy > FileVault"
    fi

    # Check secure boot and hardware security
    local secure_boot=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "secure boot" | wc -l)
    local t2_chip=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "Apple T2" | wc -l)
    
    if [ "$secure_boot" -gt 0 ] || [ "$t2_chip" -gt 0 ]; then
        add_cis_check "3.11" "Hardware Security Features" "PASS" "Hardware-based security features detected" "Secure boot/T2 chip present" ""
    else
        add_cis_check "3.11" "Hardware Security Features" "MANUAL" "Verify hardware security capabilities" "No T2/Secure Enclave detected (may be newer Apple Silicon)" "Verify hardware encryption capabilities"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 4: Secure Configuration of Enterprise Assets and Software
check_cis_control_4() {
    echo "🔍 Auditing CIS Control 4: Secure Configuration of Enterprise Assets and Software..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 4</div>
                    <h2 class="cis-control-title">Secure Configuration of Enterprise Assets and Software</h2>
                    <p class="cis-control-description">Establish and maintain the secure configuration of enterprise assets (end-user devices, including portable and mobile; network devices; non-computing/IoT devices; and servers) and software (operating systems and applications).</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">4.1</span>
                        <span class="sub-control-title">Establish and Maintain a Secure Configuration Process</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Establish and maintain a secure configuration process for enterprise assets (end-user devices, including portable and mobile; network devices; non-computing/IoT devices; and servers) and software (operating systems and applications).</div>
EOF

    # Check automatic security updates
    local auto_check=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
    local auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "0")
    local auto_install=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null || echo "0")
    
    if [ "$auto_check" = "1" ] && [ "$auto_download" = "1" ]; then
        add_cis_check "4.1" "Automatic Security Updates" "PASS" "System configured for automatic security updates" "AutoCheck: $auto_check, AutoDownload: $auto_download, AutoInstall: $auto_install" ""
    else
        add_cis_check "4.1" "Automatic Security Updates" "FAIL" "Automatic security updates not fully configured" "AutoCheck: $auto_check, AutoDownload: $auto_download" "Enable automatic updates: System Preferences > Software Update"
    fi

    # Check screen saver and lock settings
    local screensaver_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    local screensaver_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || echo "999")
    
    if [ "$screensaver_password" = "1" ] && [ "$screensaver_delay" -le 5 ]; then
        add_cis_check "4.1" "Screen Lock Configuration" "PASS" "Screen saver requires immediate password" "askForPassword: $screensaver_password, delay: $screensaver_delay seconds" ""
    else
        add_cis_check "4.1" "Screen Lock Configuration" "FAIL" "Screen lock not properly configured" "askForPassword: $screensaver_password, delay: $screensaver_delay seconds" "Configure immediate screen lock: System Preferences > Security & Privacy"
    fi

    # Check guest account status
    local guest_enabled=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "1")
    
    if [ "$guest_enabled" = "0" ]; then
        add_cis_check "4.1" "Guest Account Disabled" "PASS" "Guest account properly disabled" "GuestEnabled: $guest_enabled" ""
    else
        add_cis_check "4.1" "Guest Account Disabled" "FAIL" "Guest account enabled - unauthorized access risk" "GuestEnabled: $guest_enabled" "Disable guest account: System Preferences > Users & Groups"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 5: Account Management
check_cis_control_5() {
    echo "🔍 Auditing CIS Control 5: Account Management..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 5</div>
                    <h2 class="cis-control-title">Account Management</h2>
                    <p class="cis-control-description">Use processes and tools to assign and manage authorization to credentials for user accounts, including administrator accounts, as well as service accounts, to enterprise assets and software.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">5.1</span>
                        <span class="sub-control-title">Establish and Maintain an Inventory of Accounts</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Establish and maintain an inventory of all accounts managed in the enterprise.</div>
EOF

    # Check user account inventory
    local total_users=$(dscl . list /Users | grep -v "^_" | grep -v "daemon\|nobody\|root" | wc -l)
    local admin_users=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | wc -w)
    local enabled_users=$(dscl . list /Users | grep -v "^_" | wc -l)
    
    if [ "$total_users" -le 10 ] && [ "$admin_users" -le 3 ]; then
        add_cis_check "5.1" "User Account Management" "PASS" "Reasonable number of user accounts" "Total users: $total_users, Admin users: $admin_users" ""
    else
        add_cis_check "5.1" "User Account Management" "MANUAL" "High number of user accounts - review required" "Total users: $total_users, Admin users: $admin_users" "Review and audit all user accounts regularly"
    fi

    # Check for shared accounts
    local shared_accounts=$(dscl . list /Users | grep -E "(shared|common|temp|test)" | wc -l)
    
    if [ "$shared_accounts" -eq 0 ]; then
        add_cis_check "5.1" "Shared Account Prevention" "PASS" "No obvious shared accounts detected" "Shared-named accounts: $shared_accounts" ""
    else
        add_cis_check "5.1" "Shared Account Prevention" "FAIL" "Potential shared accounts detected" "Shared-named accounts: $shared_accounts" "Remove shared accounts and implement individual user accounts"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 6: Access Control Management
check_cis_control_6() {
    echo "🔍 Auditing CIS Control 6: Access Control Management..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 6</div>
                    <h2 class="cis-control-title">Access Control Management</h2>
                    <p class="cis-control-description">Use processes and tools to create, assign, manage, and revoke access credentials and privileges for user, administrator, and service accounts for enterprise assets and software.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">6.1</span>
                        <span class="sub-control-title">Establish an Access Granting Process</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Establish and follow a process, preferably automated, for granting access to enterprise assets upon new hire, promotion, or role change of a user.</div>
EOF

    # Check password policy
    local password_policy=$(pwpolicy getaccountpolicies 2>/dev/null)
    local password_length=$(echo "$password_policy" | grep -i "minChars" | head -1)
    
    if [ -n "$password_policy" ]; then
        add_cis_check "6.1" "Password Policy Configuration" "PASS" "Password policies are configured" "pwpolicy configured with policies" ""
    else
        add_cis_check "6.1" "Password Policy Configuration" "FAIL" "No password policies configured" "pwpolicy shows no policies" "Configure password policies: pwpolicy setaccountpolicies"
    fi

    # Check sudo configuration
    local sudo_config=$(grep -v "^#" /etc/sudoers 2>/dev/null | grep -v "^$" | wc -l)
    local sudo_timeout=$(grep "timestamp_timeout" /etc/sudoers 2>/dev/null | wc -l)
    
    if [ "$sudo_config" -gt 0 ]; then
        add_cis_check "6.1" "Privileged Access Control" "PASS" "Sudo configuration present" "Sudo rules configured: $sudo_config lines" ""
    else
        add_cis_check "6.1" "Privileged Access Control" "MANUAL" "Verify sudo configuration" "Basic sudo config detected" "Review and harden sudo configuration"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# CIS Control 12: Network Infrastructure Management
check_cis_control_12() {
    echo "🔍 Auditing CIS Control 12: Network Infrastructure Management..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="cis-control-section">
                <div class="cis-control-header">
                    <div class="cis-control-id">CIS Control 12</div>
                    <h2 class="cis-control-title">Network Infrastructure Management</h2>
                    <p class="cis-control-description">Establish, implement, and actively manage (track, report, correct) network devices, in order to prevent attackers from exploiting vulnerable network services and access points.</p>
                </div>
                
                <div class="sub-control">
                    <div class="sub-control-header">
                        <span class="sub-control-id">12.1</span>
                        <span class="sub-control-title">Ensure Network Infrastructure is Up-to-Date</span>
                    </div>
                    <div class="sub-control-body">
                        <div class="sub-control-description">Ensure that network infrastructure is kept up-to-date.</div>
EOF

    # Check firewall status
    local firewall_state=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
    local firewall_stealth=$(defaults read /Library/Preferences/com.apple.alf stealthenabled 2>/dev/null || echo "0")
    local firewall_logging=$(defaults read /Library/Preferences/com.apple.alf loggingenabled 2>/dev/null || echo "0")
    
    case $firewall_state in
        0) firewall_status="disabled" ;;
        1) firewall_status="enabled for specific services" ;;
        2) firewall_status="enabled for essential services" ;;
        *) firewall_status="unknown" ;;
    esac
    
    if [ "$firewall_state" -ge 1 ]; then
        add_cis_check "12.1" "Host-based Firewall" "PASS" "Firewall is enabled and configured" "State: $firewall_status, Stealth: $firewall_stealth, Logging: $firewall_logging" ""
    else
        add_cis_check "12.1" "Host-based Firewall" "FAIL" "Firewall is disabled" "State: $firewall_status" "Enable firewall: System Preferences > Security & Privacy > Firewall"
    fi

    # Check network services
    local sharing_services=$(launchctl list | grep -E "(ssh|screen|file|remote)" | wc -l)
    local network_services=$(networksetup -listallnetworkservices | wc -l)
    
    if [ "$sharing_services" -eq 0 ]; then
        add_cis_check "12.1" "Network Sharing Services" "PASS" "No unnecessary sharing services enabled" "Active sharing services: $sharing_services" ""
    else
        add_cis_check "12.1" "Network Sharing Services" "FAIL" "Sharing services detected" "Active sharing services: $sharing_services" "Disable unnecessary sharing: System Preferences > Sharing"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# Helper function to get risk level text and class
get_risk_level() {
    local score=$1
    if [ "$score" -ge 90 ]; then
        echo "LOW risk-low"
    elif [ "$score" -ge 75 ]; then
        echo "MEDIUM risk-medium"
    elif [ "$score" -ge 60 ]; then
        echo "HIGH risk-high"
    else
        echo "CRITICAL risk-critical"
    fi
}

# Helper function to get risk rating text
get_risk_rating() {
    local score=$1
    if [ "$score" -ge 90 ]; then
        echo "Excellent"
    elif [ "$score" -ge 70 ]; then
        echo "Good"
    elif [ "$score" -ge 50 ]; then
        echo "Fair"
    else
        echo "Poor"
    fi
}

# Generate Executive Summary and Dashboard
generate_executive_summary() {
    echo "📊 Generating executive summary and compliance dashboard..."
    
    local overall_score=0
    if [ $IG1_TOTAL -gt 0 ]; then
        overall_score=$(( (IG1_PASS * 100) / IG1_TOTAL ))
    fi
    
    local risk_info=($(get_risk_level $overall_score))
    local risk_level=${risk_info[0]}
    local risk_class=${risk_info[1]}
    local risk_rating=$(get_risk_rating $overall_score)
    
    cat >> "$REPORT_FILE" << EOF
            <div class="dashboard-container">
                <h2 style="font-weight: 500; font-size: 14px; color: #2c3e50; margin-bottom: 10px;">📊 Risk Assessment Dashboard</h2>
                <div class="dashboard-grid">
                    <div class="dashboard-card overall-risk">
                        <div class="icon">🔍</div>
                        <div class="details">
                            <h3>Overall Risk Level</h3>
                            <p class="value">$risk_level</p>
                            <p class="sub-text">Score: $overall_score% | $risk_rating</p>
                        </div>
                    </div>
                    <div class="dashboard-card manual-reviews">
                        <div class="icon">⚠️</div>
                        <div class="details">
                            <h3>Manual Reviews</h3>
                            <p class="value">$IG1_MANUAL</p>
                            <p class="sub-text">Controls needing manual verification</p>
                        </div>
                    </div>
                    <div class="dashboard-card failed-controls">
                        <div class="icon">❌</div>
                        <div class="details">
                            <h3>Failed Controls</h3>
                            <p class="value">$IG1_FAIL</p>
                            <p class="sub-text">Critical security gaps requiring action</p>
                        </div>
                    </div>
                    <div class="dashboard-card passed-controls">
                        <div class="icon">✅</div>
                        <div class="details">
                            <h3>Passed Controls</h3>
                            <p class="value">$IG1_PASS</p>
                            <p class="sub-text">Controls meeting CIS requirements</p>
                        </div>
                    </div>
                </div>

                <div class="summary-grid">
                    <div class="summary-card summary-passed">
                        <h4>CIS IG1 Controls Passed</h4>
                        <p class="value">$IG1_PASS / $IG1_TOTAL</p>
                    </div>
                    <div class="summary-card summary-score">
                        <h4>Compliance Score</h4>
                        <p class="value">$overall_score%</p>
                    </div>
                    <div class="summary-card summary-manual">
                        <h4>Manual Reviews</h4>
                        <p class="value">$IG1_MANUAL</p>
                    </div>
                    <div class="summary-card summary-failed">
                        <h4>Failed Controls</h4>
                        <p class="value">$IG1_FAIL</p>
                    </div>
                </div>
            </div>
EOF
}

# Generate recommendations and action plan
generate_recommendations() {
    cat >> "$REPORT_FILE" << EOF
            <div class="recommendations">
                <h2>🚀 Strategic Recommendations & Action Plan</h2>
                
                <div class="implementation-guide priority-high">
                    <h4>🔴 CRITICAL - Immediate Action Required (0-30 days)</h4>
                    <ul>
                        <li><strong>Enable FileVault Encryption:</strong> Protect sensitive data with full disk encryption</li>
                        <li><strong>Configure Host Firewall:</strong> Enable and properly configure macOS application firewall</li>
                        <li><strong>Disable Guest Account:</strong> Prevent unauthorized system access</li>
                        <li><strong>Enable Automatic Security Updates:</strong> Ensure timely installation of critical patches</li>
                        <li><strong>Configure Screen Lock:</strong> Implement immediate password requirement for screen saver</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-medium">
                    <h4>🟡 HIGH PRIORITY - Implement within 90 days</h4>
                    <ul>
                        <li><strong>Deploy Asset Management Solution:</strong> Implement JAMF or similar MDM solution</li>
                        <li><strong>Establish Password Policies:</strong> Configure and enforce strong password requirements</li>
                        <li><strong>Review User Accounts:</strong> Audit and clean up unnecessary user accounts</li>
                        <li><strong>Harden Network Services:</strong> Disable unnecessary network sharing services</li>
                        <li><strong>Implement Software Inventory:</strong> Deploy automated software discovery and control</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-low">
                    <h4>🟢 MEDIUM PRIORITY - Ongoing improvements</h4>
                    <ul>
                        <li><strong>Regular Security Assessments:</strong> Schedule quarterly CIS compliance audits</li>
                        <li><strong>Staff Security Training:</strong> Implement comprehensive cybersecurity awareness program</li>
                        <li><strong>Incident Response Planning:</strong> Develop and test incident response procedures</li>
                        <li><strong>Backup and Recovery:</strong> Implement comprehensive data backup strategy</li>
                        <li><strong>Documentation:</strong> Maintain updated security policies and procedures</li>
                    </ul>
                </div>
                
                <div class="mscp-reference">
                    <h5>📚 Additional Resources</h5>
                    <ul>
                        <li><strong>mSCP Project:</strong> <a href="https://github.com/usnistgov/macos_security">https://github.com/usnistgov/macos_security</a></li>
                        <li><strong>CIS Controls:</strong> <a href="https://www.cisecurity.org/controls/">https://www.cisecurity.org/controls/</a></li>
                        <li><strong>Apple Security Guide:</strong> <a href="https://support.apple.com/guide/security/">https://support.apple.com/guide/security/</a></li>
                        <li><strong>NIST Cybersecurity Framework:</strong> <a href="https://www.nist.gov/cyberframework">https://www.nist.gov/cyberframework</a></li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF
}

# Main execution
echo "🚀 CIS Controls Level 1 - Comprehensive macOS Security Audit"
echo "============================================================"
echo "Assessment Date: $TIMESTAMP"
echo "System: macOS $MACOS_VERSION (Build $BUILD_VERSION)"
echo "Standard: CIS Controls v8.0 Implementation Group 1"
echo "Framework Alignment: mSCP (macOS Security Compliance Project)"
echo "============================================================"
echo

# Initialize HTML report
init_html_report

# Execute all CIS Control checks
check_cis_control_1    # Inventory and Control of Enterprise Assets
check_cis_control_2    # Inventory and Control of Software Assets
check_cis_control_3    # Data Protection
check_cis_control_4    # Secure Configuration of Enterprise Assets and Software
check_cis_control_5    # Account Management
check_cis_control_6    # Access Control Management
check_cis_control_12   # Network Infrastructure Management

# Generate executive summary and recommendations
generate_executive_summary
generate_recommendations

# Final output
echo "✅ CIS Controls Level 1 comprehensive audit complete!"
echo "📊 Assessment Summary:"
echo "   Total Controls Evaluated: $IG1_TOTAL"
echo "   Controls Passed: $IG1_PASS"
echo "   Controls Failed: $IG1_FAIL"
echo "   Manual Reviews Required: $IG1_MANUAL"
if [ $IG1_TOTAL -gt 0 ]; then
    echo "   Overall Compliance Score: $(( (IG1_PASS * 100) / IG1_TOTAL ))%"
else
    echo "   Overall Compliance Score: 0%"
fi
echo
echo "📋 Detailed Report: $REPORT_FILE"
echo "🌐 Open report: open $REPORT_FILE"
echo
echo "🎯 Next Steps:"
echo "   1. Review failed controls and implement immediate remediation"
echo "   2. Address manual review items with appropriate stakeholders"
echo "   3. Develop timeline for implementing recommended improvements"
echo "   4. Schedule regular compliance assessments"
