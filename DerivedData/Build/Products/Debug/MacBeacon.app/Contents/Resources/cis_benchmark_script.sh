#!/bin/bash

# macOS CIS Benchmarks Audit Script with HTML Report
# Version 1.0 - Based on CIS Apple macOS Benchmark

REPORT_FILE=${1:-"cis_benchmark_report.html"}
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Initialize HTML report
init_html_report() {
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>macOS CIS Benchmarks Audit Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f7; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #ff7b7b 0%, #667eea 100%); color: white; padding: 30px; border-radius: 12px 12px 0 0; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 300; }
        .timestamp { opacity: 0.8; margin-top: 5px; }
        .content { padding: 30px; }
        .section { margin-bottom: 30px; padding: 20px; border: 1px solid #e1e5e9; border-radius: 8px; }
        .section h2 { color: #333; margin-top: 0; font-size: 20px; }
        .status-pass { color: #28a745; font-weight: bold; }
        .status-fail { color: #dc3545; font-weight: bold; }
        .status-manual { color: #ffc107; font-weight: bold; }
        .progress-bar { width: 100%; height: 25px; background: #e9ecef; border-radius: 12px; overflow: hidden; margin: 10px 0; }
        .progress-fill { height: 100%; transition: width 0.3s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; }
        .progress-good { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #fd7e14); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #e83e8c); }
        .metric { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
        .metric:last-child { border-bottom: none; }
        .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .card { padding: 25px; border-radius: 12px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .card-good { background: linear-gradient(135deg, #d4edda, #c3e6cb); color: #155724; }
        .card-warning { background: linear-gradient(135deg, #fff3cd, #ffeeba); color: #856404; }
        .card-danger { background: linear-gradient(135deg, #f8d7da, #f5c6cb); color: #721c24; }
        .icon { font-size: 32px; margin-bottom: 15px; }
        .cis-control { background: #f8f9fa; padding: 10px; border-left: 4px solid #007bff; margin: 5px 0; }
        .benchmark-id { font-family: 'Monaco', 'Courier New', monospace; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ CIS Benchmarks Security Audit</h1>
            <div class="timestamp">Generated: $TIMESTAMP</div>
        </div>
        <div class="content">
EOF
}

# Function to add a check result
add_check_result() {
    local control_id="$1"
    local description="$2"
    local status="$3"
    local details="$4"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ "$status" = "PASS" ]; then
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
    
    cat >> "$REPORT_FILE" << EOF
                <div class="metric">
                    <div>
                        <div class="benchmark-id">$control_id</div>
                        <span>$description</span>
                        <div><small>$details</small></div>
                    </div>
                    <span class="status-$(echo $status | tr '[:upper:]' '[:lower:]')">$status</span>
                </div>
EOF
}

# CIS Control 1.1 - Check automatic software updates
check_auto_updates() {
    echo "Checking automatic software updates..."
    local auto_update=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)
    local auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null)
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🔄 Software Update Controls</h2>
EOF
    
    if [ "$auto_update" = "1" ]; then
        add_check_result "1.1" "Automatic software update check enabled" "PASS" "System automatically checks for updates"
    else
        add_check_result "1.1" "Automatic software update check enabled" "FAIL" "Manual intervention required"
    fi
    
    if [ "$auto_download" = "1" ]; then
        add_check_result "1.2" "Automatic software update download enabled" "PASS" "Updates download automatically"
    else
        add_check_result "1.2" "Automatic software update download enabled" "FAIL" "Updates must be manually downloaded"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# CIS Control 2 - Check system preferences
check_system_preferences() {
    echo "Checking system security preferences..."
    local gatekeeper=$(spctl --status | grep "assessments enabled" | wc -l)
    local firewall=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
    local sip_status=$(csrutil status | grep "enabled" | wc -l)
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🔒 System Security Controls</h2>
EOF
    
    if [ "$gatekeeper" -eq 1 ]; then
        add_check_result "2.1" "Gatekeeper enabled" "PASS" "Application execution control active"
    else
        add_check_result "2.1" "Gatekeeper enabled" "FAIL" "Unsigned applications can run"
    fi
    
    if [ "$firewall" = "1" ] || [ "$firewall" = "2" ]; then
        add_check_result "2.2" "Firewall enabled" "PASS" "Network traffic filtering active"
    else
        add_check_result "2.2" "Firewall enabled" "FAIL" "System vulnerable to network attacks"
    fi
    
    if [ "$sip_status" -eq 1 ]; then
        add_check_result "2.3" "System Integrity Protection enabled" "PASS" "System files protected from modification"
    else
        add_check_result "2.3" "System Integrity Protection enabled" "FAIL" "System files can be modified"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# CIS Control 3 - Check logging and monitoring
check_logging() {
    echo "Checking logging configuration..."
    local audit_enabled=$(launchctl list | grep auditd | wc -l)
    local security_auditing=$(defaults read /Library/Preferences/com.apple.alf loggingenabled 2>/dev/null)
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>📊 Logging and Monitoring</h2>
EOF
    
    if [ "$audit_enabled" -gt 0 ]; then
        add_check_result "3.1" "Security auditing enabled" "PASS" "System events are being logged"
    else
        add_check_result "3.1" "Security auditing enabled" "FAIL" "No security event logging"
    fi
    
    if [ "$security_auditing" = "1" ]; then
        add_check_result "3.2" "Firewall logging enabled" "PASS" "Network events logged"
    else
        add_check_result "3.2" "Firewall logging enabled" "FAIL" "Network events not logged"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# CIS Control 4 - Check access controls
check_access_controls() {
    echo "Checking access controls..."
    local screensaver_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
    local password_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null)
    local guest_account=$(dscl . -read /Users/Guest | grep "RecordName" | wc -l)
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🔐 Access Controls</h2>
EOF
    
    if [ "$screensaver_password" = "1" ]; then
        add_check_result "4.1" "Screen saver password required" "PASS" "Screen saver requires authentication"
    else
        add_check_result "4.1" "Screen saver password required" "FAIL" "No authentication required after screen saver"
    fi
    
    if [ "$password_delay" -eq 0 ] 2>/dev/null; then
        add_check_result "4.2" "Screen saver password delay minimized" "PASS" "Immediate password required"
    else
        add_check_result "4.2" "Screen saver password delay minimized" "FAIL" "Password delay allows unauthorized access"
    fi
    
    if [ "$guest_account" -eq 0 ]; then
        add_check_result "4.3" "Guest account disabled" "PASS" "No guest account access"
    else
        add_check_result "4.3" "Guest account disabled" "FAIL" "Guest account allows unauthorized access"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# Function to add summary cards
add_summary_cards() {
    local compliance_score=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    local risk_level=""
    local risk_class=""
    
    if [ $compliance_score -ge 80 ]; then
        risk_level="Low Risk"
        risk_class="card-good"
    elif [ $compliance_score -ge 60 ]; then
        risk_level="Medium Risk"
        risk_class="card-warning"
    else
        risk_level="High Risk"
        risk_class="card-danger"
    fi
    
    cat >> "$REPORT_FILE" << EOF
            <div class="summary-cards">
                <div class="card card-good">
                    <div class="icon">✅</div>
                    <h3>Passed Checks</h3>
                    <p>$PASSED_CHECKS / $TOTAL_CHECKS</p>
                </div>
                <div class="card $risk_class">
                    <div class="icon">⚠️</div>
                    <h3>Risk Level</h3>
                    <p>$risk_level</p>
                </div>
                <div class="card card-warning">
                    <div class="icon">📊</div>
                    <h3>Compliance Score</h3>
                    <p>$compliance_score%</p>
                </div>
            </div>
            
            <div class="section">
                <h2>📈 Overall Compliance Score</h2>
                <div class="progress-bar">
                    <div class="progress-fill $([ $compliance_score -ge 80 ] && echo "progress-good" || ([ $compliance_score -ge 60 ] && echo "progress-warning" || echo "progress-danger"))" style="width: $compliance_score%;">
                        $compliance_score%
                    </div>
                </div>
                <p><strong>CIS Benchmark Compliance:</strong> $PASSED_CHECKS out of $TOTAL_CHECKS controls implemented correctly.</p>
            </div>
EOF
}

# Function to finish HTML report
finish_html_report() {
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🚀 CIS Benchmark Recommendations</h2>
                <div class="cis-control">
                    <strong>Critical Actions:</strong>
                    <ul>
                        <li>Enable automatic security updates</li>
                        <li>Configure firewall with logging</li>
                        <li>Disable guest account access</li>
                        <li>Set immediate screen saver password requirement</li>
                    </ul>
                </div>
                <div class="cis-control">
                    <strong>Monitoring:</strong>
                    <ul>
                        <li>Enable comprehensive security auditing</li>
                        <li>Review security logs regularly</li>
                        <li>Implement continuous compliance monitoring</li>
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
echo "=================================="
echo "CIS Benchmarks Security Audit"
echo "=================================="
echo "2025-09-02 21:31:43 [INFO]  mac_audit_enhanced starting (PID $$)"
echo "Generating HTML report..."
echo

# Initialize HTML report
init_html_report

# Run all checks
check_auto_updates
check_system_preferences
check_logging
check_access_controls

# Add summary
add_summary_cards

# Finish HTML report
finish_html_report

echo "✅ CIS Benchmark audit complete!"
echo "📊 Report saved to: $REPORT_FILE"
echo "🌐 Open in browser: open $REPORT_FILE"
echo "📋 Compliance Score: $((PASSED_CHECKS * 100 / TOTAL_CHECKS))% ($PASSED_CHECKS/$TOTAL_CHECKS checks passed)"