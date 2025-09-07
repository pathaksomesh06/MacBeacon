#!/bin/bash

# macOS NIST Cybersecurity Framework Audit Script with HTML Report
# Version 1.0 - Based on NIST CSF 2.0

REPORT_FILE=${1:-"nist_cybersecurity_report.html"}
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters for each function
IDENTIFY_TOTAL=0; IDENTIFY_PASS=0
PROTECT_TOTAL=0; PROTECT_PASS=0
DETECT_TOTAL=0; DETECT_PASS=0
RESPOND_TOTAL=0; RESPOND_PASS=0
RECOVER_TOTAL=0; RECOVER_PASS=0

# Initialize HTML report
init_html_report() {
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>macOS NIST Cybersecurity Framework Audit Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f7; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 30px; border-radius: 12px 12px 0 0; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 300; }
        .timestamp { opacity: 0.8; margin-top: 5px; }
        .content { padding: 30px; }
        .section { margin-bottom: 30px; padding: 25px; border: 1px solid #e1e5e9; border-radius: 10px; }
        .section h2 { color: #333; margin-top: 0; font-size: 22px; border-bottom: 2px solid #e1e5e9; padding-bottom: 10px; }
        .status-implemented { color: #28a745; font-weight: bold; }
        .status-partial { color: #ffc107; font-weight: bold; }
        .status-missing { color: #dc3545; font-weight: bold; }
        .progress-bar { width: 100%; height: 28px; background: #e9ecef; border-radius: 14px; overflow: hidden; margin: 15px 0; position: relative; }
        .progress-fill { height: 100%; transition: width 0.5s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 14px; }
        .progress-excellent { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-good { background: linear-gradient(90deg, #17a2b8, #20c997); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #fd7e14); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #e83e8c); }
        .metric { display: flex; justify-content: space-between; align-items: center; padding: 15px 0; border-bottom: 1px solid #f0f0f0; }
        .metric:last-child { border-bottom: none; }
        .nist-functions { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 25px; margin-bottom: 40px; }
        .function-card { padding: 30px; border-radius: 15px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.1); position: relative; }
        .identify { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .protect { background: linear-gradient(135deg, #f093fb, #f5576c); color: white; }
        .detect { background: linear-gradient(135deg, #4facfe, #00f2fe); color: white; }
        .respond { background: linear-gradient(135deg, #fa709a, #fee140); color: white; }
        .recover { background: linear-gradient(135deg, #a8edea, #fed6e3); color: #333; }
        .icon { font-size: 48px; margin-bottom: 20px; }
        .function-score { font-size: 32px; font-weight: bold; margin-top: 15px; }
        .nist-id { font-family: 'Monaco', 'Courier New', monospace; font-size: 11px; color: #666; background: #f8f9fa; padding: 2px 6px; border-radius: 4px; }
        .subcategory { margin-left: 20px; font-size: 14px; color: #555; }
        .maturity-indicator { position: absolute; top: 15px; right: 15px; width: 12px; height: 12px; border-radius: 50%; }
        .maturity-high { background: #28a745; }
        .maturity-medium { background: #ffc107; }
        .maturity-low { background: #dc3545; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ NIST Cybersecurity Framework Assessment</h1>
            <div class="timestamp">Generated: $TIMESTAMP | Framework Version 2.0</div>
        </div>
        <div class="content">
EOF
}

# Function to add a check result
add_nist_check() {
    local function_name="$1"
    local nist_id="$2" 
    local description="$3"
    local status="$4"
    local details="$5"
    
    # Update counters
    case $function_name in
        "IDENTIFY") IDENTIFY_TOTAL=$((IDENTIFY_TOTAL + 1)); [ "$status" = "IMPLEMENTED" ] && IDENTIFY_PASS=$((IDENTIFY_PASS + 1)) ;;
        "PROTECT") PROTECT_TOTAL=$((PROTECT_TOTAL + 1)); [ "$status" = "IMPLEMENTED" ] && PROTECT_PASS=$((PROTECT_PASS + 1)) ;;
        "DETECT") DETECT_TOTAL=$((DETECT_TOTAL + 1)); [ "$status" = "IMPLEMENTED" ] && DETECT_PASS=$((DETECT_PASS + 1)) ;;
        "RESPOND") RESPOND_TOTAL=$((RESPOND_TOTAL + 1)); [ "$status" = "IMPLEMENTED" ] && RESPOND_PASS=$((RESPOND_PASS + 1)) ;;
        "RECOVER") RECOVER_TOTAL=$((RECOVER_TOTAL + 1)); [ "$status" = "IMPLEMENTED" ] && RECOVER_PASS=$((RECOVER_PASS + 1)) ;;
    esac
    
    cat >> "$REPORT_FILE" << EOF
                <div class="metric">
                    <div>
                        <span class="nist-id">$nist_id</span> $description
                        <div class="subcategory">$details</div>
                    </div>
                    <span class="status-$(echo $status | tr '[:upper:]' '[:lower:]')">$status</span>
                </div>
EOF
}

# NIST Function 1: IDENTIFY
check_identify_function() {
    echo "Assessing IDENTIFY function..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🎯 IDENTIFY Function</h2>
EOF
    
    # ID.AM - Asset Management
    local system_profiler_available=$(which system_profiler >/dev/null && echo "1" || echo "0")
    if [ "$system_profiler_available" = "1" ]; then
        add_nist_check "IDENTIFY" "ID.AM-1" "Asset inventory maintained" "IMPLEMENTED" "System profiler available for asset discovery"
    else
        add_nist_check "IDENTIFY" "ID.AM-1" "Asset inventory maintained" "MISSING" "No automated asset discovery mechanism"
    fi
    
    # ID.GV - Governance  
    local security_policy=$(find /etc -name "*security*" 2>/dev/null | wc -l)
    if [ "$security_policy" -gt 0 ]; then
        add_nist_check "IDENTIFY" "ID.GV-1" "Cybersecurity policy established" "PARTIAL" "Some security configurations present"
    else
        add_nist_check "IDENTIFY" "ID.GV-1" "Cybersecurity policy established" "MISSING" "No documented security policies found"
    fi
    
    # ID.RA - Risk Assessment
    local vulnerability_scanner=$(which nmap >/dev/null && echo "1" || echo "0")
    if [ "$vulnerability_scanner" = "1" ]; then
        add_nist_check "IDENTIFY" "ID.RA-1" "Vulnerability assessment capability" "IMPLEMENTED" "Network scanning tools available"
    else
        add_nist_check "IDENTIFY" "ID.RA-1" "Vulnerability assessment capability" "MISSING" "No vulnerability assessment tools detected"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# NIST Function 2: PROTECT
check_protect_function() {
    echo "Assessing PROTECT function..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🛡️ PROTECT Function</h2>
EOF
    
    # PR.AC - Access Control
    local password_policy=$(pwpolicy getaccountpolicies 2>/dev/null | grep -i "password" | wc -l)
    if [ "$password_policy" -gt 0 ]; then
        add_nist_check "PROTECT" "PR.AC-1" "Account management controls" "IMPLEMENTED" "Password policies configured"
    else
        add_nist_check "PROTECT" "PR.AC-1" "Account management controls" "PARTIAL" "Basic access controls present"
    fi
    
    # PR.DS - Data Security
    local filevault_status=$(fdesetup status | grep "FileVault is On" | wc -l)
    if [ "$filevault_status" -eq 1 ]; then
        add_nist_check "PROTECT" "PR.DS-1" "Data-at-rest encryption" "IMPLEMENTED" "FileVault encryption enabled"
    else
        add_nist_check "PROTECT" "PR.DS-1" "Data-at-rest encryption" "MISSING" "Disk encryption not enabled"
    fi
    
    # PR.PT - Protective Technology
    local xprotect_status=$(ls /Library/Apple/System/Library/CoreServices/XProtect.bundle 2>/dev/null | wc -l)
    if [ "$xprotect_status" -gt 0 ]; then
        add_nist_check "PROTECT" "PR.PT-1" "Malware protection" "IMPLEMENTED" "XProtect anti-malware active"
    else
        add_nist_check "PROTECT" "PR.PT-1" "Malware protection" "PARTIAL" "Limited malware protection"
    fi
    
    # PR.IP - Information Protection
    local backup_configured=$(tmutil latestbackup 2>/dev/null | wc -l)
    if [ "$backup_configured" -gt 0 ]; then
        add_nist_check "PROTECT" "PR.IP-4" "Backup and recovery processes" "IMPLEMENTED" "Time Machine backups configured"
    else
        add_nist_check "PROTECT" "PR.IP-4" "Backup and recovery processes" "MISSING" "No backup system detected"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# NIST Function 3: DETECT
check_detect_function() {
    echo "Assessing DETECT function..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>👁️ DETECT Function</h2>
EOF
    
    # DE.AE - Anomalies and Events
    local security_logs=$(ls /var/log/system.log 2>/dev/null | wc -l)
    if [ "$security_logs" -gt 0 ]; then
        add_nist_check "DETECT" "DE.AE-1" "Security event logging" "IMPLEMENTED" "System logs available for analysis"
    else
        add_nist_check "DETECT" "DE.AE-1" "Security event logging" "PARTIAL" "Limited logging capability"
    fi
    
    # DE.CM - Continuous Monitoring
    local activity_monitor_running=$(pgrep -f "Activity Monitor" | wc -l)
    if [ "$activity_monitor_running" -gt 0 ]; then
        add_nist_check "DETECT" "DE.CM-1" "System monitoring" "PARTIAL" "Basic system monitoring active"
    else
        add_nist_check "DETECT" "DE.CM-1" "System monitoring" "MISSING" "No continuous monitoring detected"
    fi
    
    # DE.DP - Detection Processes
    local intrusion_detection=$(netstat -an | grep LISTEN | wc -l)
    if [ "$intrusion_detection" -gt 5 ]; then
        add_nist_check "DETECT" "DE.DP-1" "Network monitoring" "PARTIAL" "Network activity detectable"
    else
        add_nist_check "DETECT" "DE.DP-1" "Network monitoring" "MISSING" "Limited network monitoring"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# NIST Function 4: RESPOND
check_respond_function() {
    echo "Assessing RESPOND function..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>⚡ RESPOND Function</h2>
EOF
    
    # RS.RP - Response Planning
    local incident_response_tools=$(which networkQuality >/dev/null && echo "1" || echo "0")
    if [ "$incident_response_tools" = "1" ]; then
        add_nist_check "RESPOND" "RS.RP-1" "Response capability" "PARTIAL" "Basic network diagnostic tools available"
    else
        add_nist_check "RESPOND" "RS.RP-1" "Response capability" "MISSING" "No response tools detected"
    fi
    
    # RS.CO - Communications
    local notification_system=$(launchctl list | grep notification | wc -l)
    if [ "$notification_system" -gt 0 ]; then
        add_nist_check "RESPOND" "RS.CO-1" "Incident communication" "IMPLEMENTED" "Notification system available"
    else
        add_nist_check "RESPOND" "RS.CO-1" "Incident communication" "MISSING" "No incident communication mechanism"
    fi
    
    # RS.AN - Analysis
    local forensic_capability=$(which log >/dev/null && echo "1" || echo "0")
    if [ "$forensic_capability" = "1" ]; then
        add_nist_check "RESPOND" "RS.AN-1" "Investigation capability" "IMPLEMENTED" "System log analysis tools available"
    else
        add_nist_check "RESPOND" "RS.AN-1" "Investigation capability" "MISSING" "Limited forensic analysis capability"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# NIST Function 5: RECOVER
check_recover_function() {
    echo "Assessing RECOVER function..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🔄 RECOVER Function</h2>
EOF
    
    # RC.RP - Recovery Planning
    local recovery_partition=$(diskutil list | grep "Recovery HD" | wc -l)
    if [ "$recovery_partition" -gt 0 ]; then
        add_nist_check "RECOVER" "RC.RP-1" "System recovery capability" "IMPLEMENTED" "Recovery partition available"
    else
        add_nist_check "RECOVER" "RC.RP-1" "System recovery capability" "PARTIAL" "Limited recovery options"
    fi
    
    # RC.IM - Improvements
    local system_updates=$(softwareupdate -l 2>&1 | grep "No new software available" | wc -l)
    if [ "$system_updates" -gt 0 ]; then
        add_nist_check "RECOVER" "RC.IM-1" "System maintenance" "IMPLEMENTED" "System is up to date"
    else
        add_nist_check "RECOVER" "RC.IM-1" "System maintenance" "PARTIAL" "System updates may be available"
    fi
    
    # RC.CO - Communications
    local emergency_contacts=$(defaults read com.apple.AddressBook 2>/dev/null | grep -i "emergency" | wc -l)
    if [ "$emergency_contacts" -gt 0 ]; then
        add_nist_check "RECOVER" "RC.CO-1" "Recovery communications" "PARTIAL" "Contact information available"
    else
        add_nist_check "RECOVER" "RC.CO-1" "Recovery communications" "MISSING" "No emergency contact plan detected"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# Function to calculate maturity levels and add summary
add_nist_summary() {
    local identify_score=$(( IDENTIFY_PASS * 100 / IDENTIFY_TOTAL ))
    local protect_score=$(( PROTECT_PASS * 100 / PROTECT_TOTAL ))
    local detect_score=$(( DETECT_PASS * 100 / DETECT_TOTAL ))
    local respond_score=$(( RESPOND_PASS * 100 / RESPOND_TOTAL ))
    local recover_score=$(( RECOVER_PASS * 100 / RECOVER_TOTAL ))
    
    local overall_score=$(( (identify_score + protect_score + detect_score + respond_score + recover_score) / 5 ))
    
    cat >> "$REPORT_FILE" << EOF
            <div class="nist-functions">
                <div class="function-card identify">
                    <div class="maturity-indicator $([ $identify_score -ge 75 ] && echo "maturity-high" || ([ $identify_score -ge 50 ] && echo "maturity-medium" || echo "maturity-low"))"></div>
                    <div class="icon">🎯</div>
                    <h3>IDENTIFY</h3>
                    <p>Asset Management<br>Risk Assessment<br>Governance</p>
                    <div class="function-score">$identify_score%</div>
                </div>
                <div class="function-card protect">
                    <div class="maturity-indicator $([ $protect_score -ge 75 ] && echo "maturity-high" || ([ $protect_score -ge 50 ] && echo "maturity-medium" || echo "maturity-low"))"></div>
                    <div class="icon">🛡️</div>
                    <h3>PROTECT</h3>
                    <p>Access Control<br>Data Security<br>Protective Technology</p>
                    <div class="function-score">$protect_score%</div>
                </div>
                <div class="function-card detect">
                    <div class="maturity-indicator $([ $detect_score -ge 75 ] && echo "maturity-high" || ([ $detect_score -ge 50 ] && echo "maturity-medium" || echo "maturity-low"))"></div>
                    <div class="icon">👁️</div>
                    <h3>DETECT</h3>
                    <p>Continuous Monitoring<br>Anomaly Detection<br>Event Analysis</p>
                    <div class="function-score">$detect_score%</div>
                </div>
                <div class="function-card respond">
                    <div class="maturity-indicator $([ $respond_score -ge 75 ] && echo "maturity-high" || ([ $respond_score -ge 50 ] && echo "maturity-medium" || echo "maturity-low"))"></div>
                    <div class="icon">⚡</div>
                    <h3>RESPOND</h3>
                    <p>Response Planning<br>Communications<br>Analysis</p>
                    <div class="function-score">$respond_score%</div>
                </div>
                <div class="function-card recover">
                    <div class="maturity-indicator $([ $recover_score -ge 75 ] && echo "maturity-high" || ([ $recover_score -ge 50 ] && echo "maturity-medium" || echo "maturity-low"))"></div>
                    <div class="icon">🔄</div>
                    <h3>RECOVER</h3>
                    <p>Recovery Planning<br>System Restoration<br>Lessons Learned</p>
                    <div class="function-score">$recover_score%</div>
                </div>
            </div>
            
            <div class="section">
                <h2>📊 Overall Cybersecurity Maturity</h2>
                <div class="progress-bar">
                    <div class="progress-fill $([ $overall_score -ge 80 ] && echo "progress-excellent" || ([ $overall_score -ge 60 ] && echo "progress-good" || ([ $overall_score -ge 40 ] && echo "progress-warning" || echo "progress-danger")))" style="width: $overall_score%;">
                        $overall_score% Mature
                    </div>
                </div>
                <p><strong>NIST CSF Implementation Level:</strong> $([ $overall_score -ge 80 ] && echo "Adaptive (Tier 4)" || ([ $overall_score -ge 60 ] && echo "Repeatable (Tier 3)" || ([ $overall_score -ge 40 ] && echo "Risk Informed (Tier 2)" || echo "Partial (Tier 1)")))</p>
            </div>
EOF
}

# Function to finish HTML report
finish_html_report() {
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🚀 NIST CSF Implementation Roadmap</h2>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px;">
                    <div style="padding: 20px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #667eea;">
                        <h4>🎯 Strengthen IDENTIFY</h4>
                        <ul>
                            <li>Implement comprehensive asset inventory</li>
                            <li>Document cybersecurity policies</li>
                            <li>Conduct regular risk assessments</li>
                        </ul>
                    </div>
                    <div style="padding: 20px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #f5576c;">
                        <h4>🛡️ Enhance PROTECT</h4>
                        <ul>
                            <li>Enable full disk encryption</li>
                            <li>Implement multi-factor authentication</li>
                            <li>Configure automated backups</li>
                        </ul>
                    </div>
                    <div style="padding: 20px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #00f2fe;">
                        <h4>👁️ Improve DETECT</h4>
                        <ul>
                            <li>Deploy continuous monitoring tools</li>
                            <li>Establish security event correlation</li>
                            <li>Implement intrusion detection</li>
                        </ul>
                    </div>
                    <div style="padding: 20px; background: #f8f9fa; border-radius: 8px; border-left: 4px solid #fee140;">
                        <h4>⚡ Develop RESPOND</h4>
                        <ul>
                            <li>Create incident response plan</li>
                            <li>Establish communication procedures</li>
                            <li>Train response team members</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF
}

# Main execution
echo "=================================="
echo "NIST Cybersecurity Framework Assessment"
echo "=================================="
echo "2025-09-02 21:31:43 [INFO]  mac_audit_enhanced starting (PID $$)"
echo "Generating comprehensive HTML report..."
echo

# Initialize HTML report
init_html_report

# Run all NIST function assessments
check_identify_function
check_protect_function  
check_detect_function
check_respond_function
check_recover_function

# Add summary cards and overall scoring
add_nist_summary

# Finish HTML report
finish_html_report

# Calculate totals
total_checks=$((IDENTIFY_TOTAL + PROTECT_TOTAL + DETECT_TOTAL + RESPOND_TOTAL + RECOVER_TOTAL))
total_pass=$((IDENTIFY_PASS + PROTECT_PASS + DETECT_PASS + RESPOND_PASS + RECOVER_PASS))
overall_score=$((total_pass * 100 / total_checks))

echo "✅ NIST Cybersecurity Framework assessment complete!"
echo "📊 Report saved to: $REPORT_FILE"  
echo "🌐 Open in browser: open $REPORT_FILE"
echo "🎯 Overall Maturity: $overall_score% ($total_pass/$total_checks functions implemented)"