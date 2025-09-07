#!/bin/bash

# NIST 800-171 Rev 2 - Comprehensive Controlled Unclassified Information (CUI) Protection Audit
# Aligned with mSCP (macOS Security Compliance Project)
# Based on NIST Special Publication 800-171 Revision 2
# Version 2.0

REPORT_FILE="audit_reports/nist_800_171_comprehensive_report.html"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
MACOS_VERSION=$(sw_vers -productVersion)
BUILD_VERSION=$(sw_vers -buildVersion)
SYSTEM_SERIAL=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $4}')

# Counters for NIST Cybersecurity Framework Functions
IDENTIFY_TOTAL=0; IDENTIFY_PASS=0
PROTECT_TOTAL=0; PROTECT_PASS=0
DETECT_TOTAL=0; DETECT_PASS=0
RESPOND_TOTAL=0; RESPOND_PASS=0
RECOVER_TOTAL=0; RECOVER_PASS=0

# Initialize comprehensive HTML report
init_html_report() {
    mkdir -p audit_reports
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <title>NIST 800-171 CUI Compliance Report</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #2E8B57 0%, #3CB371 100%); min-height: 100vh; }
        .container { max-width: 1800px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 15px 50px rgba(0,0,0,0.2); }
        .header { background: linear-gradient(135deg, #2E8B57, #3CB371); color: white; padding: 60px; border-radius: 15px 15px 0 0; position: relative; overflow: hidden; }
        .header::before { content: '🔒'; position: absolute; top: 20px; right: 40px; font-size: 120px; opacity: 0.1; }
        .header h1 { margin: 0; font-size: 24px; font-weight: 300; position: relative; z-index: 1; }
        .header .subtitle { font-size: 14px; opacity: 0.9; margin-top: 8px; position: relative; z-index: 1; }
        .header .compliance-info { font-size: 10px; opacity: 0.8; margin-top: 12px; position: relative; z-index: 1; line-height: 1.4; }
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
        
        .full-width-card {
            grid-column: 1 / -1;
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
        
        /* NIST Function Colors */
        .identify { border-top: 4px solid #2575fc; }
        .identify .icon { background-color: #e9f1ff; color: #2575fc; }
        .identify .value { color: #2575fc; }

        .protect { border-top: 4px solid #ec008c; }
        .protect .icon { background-color: #fde6f4; color: #ec008c; }
        .protect .value { color: #ec008c; }

        .detect { border-top: 4px solid #00c6ff; }
        .detect .icon { background-color: #e6f9ff; color: #00c6ff; }
        .detect .value { color: #00c6ff; }
        
        .respond { border-top: 4px solid #f857a6; }
        .respond .icon { background-color: #ffeff7; color: #f857a6; }
        .respond .value { color: #f857a6; }

        .recover { border-top: 4px solid #43e97b; }
        .recover .icon { background-color: #e9fdf2; color: #43e97b; }
        .recover .value { color: #43e97b; }

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

        .summary-compliant { background-color: #28a745; }
        .summary-score { background-color: #007bff; }
        .summary-noncompliant { background-color: #dc3545; }
        .summary-total { background-color: #6c757d; }
        
        .cui-notice { background: linear-gradient(135deg, #ffeaa7, #fdcb6e); padding: 30px; border-radius: 15px; margin-bottom: 40px; border-left: 8px solid #e17055; }
        .cui-notice h2 { color: #d63031; margin-top: 0; font-size: 24px; }
        .cui-notice p { color: #2d3436; line-height: 1.6; margin-bottom: 0; }
        
        .nist-control-section { margin-bottom: 20px; padding: 15px; border: 1px solid #e1e5e9; border-radius: 8px; background: linear-gradient(135deg, #fafbfc, #f8f9fa); }
        .nist-control-header { border-bottom: 2px solid #2E8B57; padding-bottom: 8px; margin-bottom: 10px; }
        .nist-control-title { color: #2c3e50; font-size: 14px; font-weight: 600; margin: 0; }
        .nist-control-description { color: #6c757d; font-size: 10px; margin-top: 5px; line-height: 1.4; }
        .nist-control-id { background: #2E8B57; color: white; padding: 4px 8px; border-radius: 12px; font-size: 8px; font-weight: bold; display: inline-block; margin-bottom: 6px; }
        
        .requirement { background: white; border: 1px solid #dee2e6; border-radius: 6px; margin: 8px 0; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.05); }
        .requirement-header { background: linear-gradient(90deg, #f8f9fa, #e9ecef); padding: 8px; border-bottom: 1px solid #dee2e6; }
        .requirement-id { font-family: 'Monaco', 'Courier New', monospace; font-size: 8px; background: #495057; color: white; padding: 2px 6px; border-radius: 8px; display: inline-block; margin-right: 6px; }
        .requirement-title { font-weight: 600; color: #2c3e50; font-size: 10px; }
        .requirement-body { padding: 8px; }
        .requirement-description { color: #6c757d; margin-bottom: 8px; line-height: 1.3; font-size: 9px; }
        
        .cui-consideration { background: #e7f3ff; border-left: 3px solid #0066cc; padding: 8px; margin: 8px 0; border-radius: 4px; }
        .cui-consideration h5 { color: #0066cc; margin-top: 0; font-size: 9px; }
        
        .check-result { display: flex; justify-content: space-between; align-items: flex-start; padding: 6px 0; border-bottom: 1px solid #f0f0f0; }
        .check-result:last-child { border-bottom: none; }
        .check-details { flex: 1; margin-right: 8px; }
        .check-title { font-weight: 600; color: #2c3e50; margin-bottom: 3px; font-size: 9px; }
        .check-description { font-size: 8px; color: #6c757d; line-height: 1.3; margin-bottom: 3px; }
        .check-technical { font-size: 7px; color: #868e96; font-family: 'Monaco', 'Courier New', monospace; margin-top: 3px; background: #f8f9fa; padding: 4px; border-radius: 3px; }
        .check-cui-impact { font-size: 8px; color: #d63031; font-weight: 500; margin-top: 3px; }
        
        .status-badge { padding: 4px 8px; border-radius: 10px; font-weight: bold; font-size: 8px; text-transform: uppercase; min-width: 40px; text-align: center; }
        .status-pass { background: #d4edda; color: #155724; border: 2px solid #c3e6cb; }
        .status-fail { background: #f8d7da; color: #721c24; border: 2px solid #f5c6cb; }
        .status-manual { background: #fff3cd; color: #856404; border: 2px solid #ffeaa7; }
        .status-na { background: #e2e3e5; color: #383d41; border: 2px solid #c6c8ca; }
        
        .remediation { background: #f8d7da; border-left: 5px solid #dc3545; padding: 25px; margin: 20px 0; border-radius: 8px; }
        .remediation h4 { color: #721c24; margin-top: 0; font-size: 18px; }
        .remediation-steps { color: #721c24; }
        
        .implementation-guide { background: #d1ecf1; border-left: 5px solid #17a2b8; padding: 25px; margin: 20px 0; border-radius: 8px; }
        .implementation-guide h4 { color: #0c5460; margin-top: 0; font-size: 18px; }
        
        .progress-container { margin: 40px 0; }
        .progress-bar { width: 100%; height: 45px; background: #e9ecef; border-radius: 25px; overflow: hidden; position: relative; box-shadow: inset 0 2px 4px rgba(0,0,0,0.1); }
        .progress-fill { height: 100%; transition: width 1.5s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 18px; }
        .progress-excellent { background: linear-gradient(90deg, #00b894, #00a085); }
        .progress-good { background: linear-gradient(90deg, #2E8B57, #3CB371); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #e0a800); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #c82333); }
        
        .executive-summary { background: linear-gradient(135deg, #f8f9fa, #e9ecef); padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #2E8B57; }
        
        .mscp-reference { background: #e7f3ff; border: 2px solid #b3d9ff; padding: 20px; border-radius: 10px; margin: 15px 0; }
        .mscp-reference h5 { color: #0066cc; margin-top: 0; font-size: 18px; }
        
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
            <h1>🔒 NIST 800-171 Rev 2 - Comprehensive CUI Protection Audit</h1>
            <div class="subtitle">Protecting Controlled Unclassified Information in Nonfederal Systems</div>
            <div class="compliance-info">
                <strong>System:</strong> macOS $MACOS_VERSION (Build $BUILD_VERSION) |
                <strong>Serial:</strong> $SYSTEM_SERIAL |
                <strong>Assessment Date:</strong> $TIMESTAMP<br>
                <strong>Standard:</strong> NIST Special Publication 800-171 Revision 2 |
                <strong>Framework:</strong> mSCP Aligned |
                <strong>Scope:</strong> CUI Protection Requirements
            </div>
        </div>
        <div class="content">
            
            <div class="cui-notice">
                <h2>⚠️ Controlled Unclassified Information (CUI) Protection Notice</h2>
                <p>This assessment evaluates compliance with NIST 800-171 requirements for protecting Controlled Unclassified Information (CUI) in nonfederal systems. CUI is information that requires safeguarding but is not classified. Organizations handling CUI must implement these security requirements to maintain federal contracts and protect sensitive information.</p>
            </div>
EOF
}

# Function to add NIST 800-171 check result
add_nist_check() {
    local nist_function="$1"
    local control_id="$2"
    local title="$3"
    local status="$4"
    local description="$5"
    local technical_details="$6"
    local cui_impact="$7"
    local remediation="$8"
    
    # Update function counters
    case $nist_function in
        "IDENTIFY")
            IDENTIFY_TOTAL=$((IDENTIFY_TOTAL + 1))
            [ "$status" = "PASS" ] && IDENTIFY_PASS=$((IDENTIFY_PASS + 1))
            ;;
        "PROTECT")
            PROTECT_TOTAL=$((PROTECT_TOTAL + 1))
            [ "$status" = "PASS" ] && PROTECT_PASS=$((PROTECT_PASS + 1))
            ;;
        "DETECT")
            DETECT_TOTAL=$((DETECT_TOTAL + 1))
            [ "$status" = "PASS" ] && DETECT_PASS=$((DETECT_PASS + 1))
            ;;
        "RESPOND")
            RESPOND_TOTAL=$((RESPOND_TOTAL + 1))
            [ "$status" = "PASS" ] && RESPOND_PASS=$((RESPOND_PASS + 1))
            ;;
        "RECOVER")
            RECOVER_TOTAL=$((RECOVER_TOTAL + 1))
            [ "$status" = "PASS" ] && RECOVER_PASS=$((RECOVER_PASS + 1))
            ;;
    esac
    
    local status_class=$(echo $status | tr '[:upper:]' '[:lower:]')
    
    cat >> "$REPORT_FILE" << EOF
                <div class="check-result">
                    <div class="check-details">
                        <div class="check-title">$title</div>
                        <div class="check-description">$description</div>
                        <div class="check-technical">Technical Validation: $technical_details</div>
                        <div class="check-cui-impact">CUI Impact: $cui_impact</div>
                    </div>
                    <div class="status-badge status-$status_class">$status</div>
                </div>
EOF

    if [ "$status" = "FAIL" ] && [ -n "$remediation" ]; then
        cat >> "$REPORT_FILE" << EOF
                <div class="remediation">
                    <h4>🚨 Critical CUI Protection Gap - Immediate Action Required</h4>
                    <div class="remediation-steps">$remediation</div>
                </div>
EOF
    fi
}

# NIST 800-171 Control Family 3.1 - Access Control
check_nist_access_control() {
    echo "🔍 Auditing NIST 800-171 Access Control (3.1.x) - CUI Access Protection..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="nist-control-section">
                <div class="nist-control-header">
                    <div class="nist-control-id">3.1 - Access Control</div>
                    <h2 class="nist-control-title">Limit System Access to Authorized Users</h2>
                    <p class="nist-control-description">Access control requirements ensure that only authorized users, processes, and devices can access CUI systems and data. These controls prevent unauthorized disclosure of CUI and maintain the confidentiality of sensitive information.</p>
                </div>
                
                <div class="mscp-reference">
                    <h5>📋 mSCP Alignment</h5>
                    <p>These controls align with mSCP baseline requirements for user authentication, session management, and privilege escalation in macOS environments handling CUI.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.1.1</span>
                        <span class="requirement-title">Limit system access to authorized users, processes acting on behalf of authorized users, or devices (including other systems).</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">This requirement ensures that only authorized entities can access systems processing CUI. Unauthorized access could lead to CUI disclosure, modification, or destruction.</div>
                        
                        <div class="cui-consideration">
                            <h5>🔐 CUI Protection Consideration</h5>
                            <p>Effective access control is fundamental to CUI protection. Systems without proper access controls cannot ensure CUI confidentiality and may violate federal requirements.</p>
                        </div>
EOF

    # Check Gatekeeper for application access control
    local gatekeeper_status=$(spctl --status 2>/dev/null)
    local gatekeeper_enabled=$(echo "$gatekeeper_status" | grep "assessments enabled" | wc -l)
    
    if [ "$gatekeeper_enabled" -eq 1 ]; then
        add_nist_check "IDENTIFY" "3.1.1" "Application Execution Control (Gatekeeper)" "PASS" "Gatekeeper prevents unauthorized applications from accessing CUI" "spctl --status: $gatekeeper_status" "Prevents unauthorized software from executing and accessing CUI data" ""
    else
        add_nist_check "IDENTIFY" "3.1.1" "Application Execution Control (Gatekeeper)" "FAIL" "Gatekeeper disabled - unauthorized applications can access CUI" "spctl --status: $gatekeeper_status" "CRITICAL: Unauthorized software can execute and access CUI data" "Enable Gatekeeper immediately: sudo spctl --master-enable"
    fi

    # Check System Integrity Protection
    local sip_status=$(csrutil status 2>/dev/null)
    local sip_enabled=$(echo "$sip_status" | grep "enabled" | wc -l)
    
    if [ "$sip_enabled" -eq 1 ]; then
        add_nist_check "PROTECT" "3.1.1" "System Integrity Protection" "PASS" "SIP prevents unauthorized system modification that could compromise CUI protection" "csrutil status: $sip_status" "Prevents system-level changes that could bypass CUI protection mechanisms" ""
    else
        add_nist_check "PROTECT" "3.1.1" "System Integrity Protection" "FAIL" "SIP disabled - system integrity compromised" "csrutil status: $sip_status" "CRITICAL: System modifications could bypass CUI protection" "Re-enable SIP in Recovery mode: csrutil enable"
    fi

    # Check guest account status
    local guest_enabled=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null || echo "1")
    
    if [ "$guest_enabled" = "0" ]; then
        add_nist_check "IDENTIFY" "3.1.1" "Guest Account Disabled" "PASS" "Guest account disabled prevents unauthorized CUI access" "GuestEnabled: $guest_enabled" "Prevents anonymous access to systems that may contain CUI" ""
    else
        add_nist_check "IDENTIFY" "3.1.1" "Guest Account Disabled" "FAIL" "Guest account enabled allows unauthorized access" "GuestEnabled: $guest_enabled" "CRITICAL: Guest account could provide unauthorized access to CUI" "Disable guest account: System Preferences > Users & Groups"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.1.2</span>
                        <span class="requirement-title">Limit system access to the types of transactions and functions that authorized users are permitted to execute.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">This requirement implements the principle of least privilege, ensuring users can only perform authorized functions. Role-based access control limits CUI exposure.</div>
EOF

    # Check sudo configuration and privilege escalation
    local admin_users=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | wc -w)
    local total_users=$(dscl . list /Users | grep -v "^_" | grep -v "daemon\|nobody\|root" | wc -l)
    
    if [ "$admin_users" -le 2 ] && [ "$total_users" -le 10 ]; then
        add_nist_check "IDENTIFY" "3.1.2" "Privileged User Management" "PASS" "Limited number of administrative users" "Admin users: $admin_users, Total users: $total_users" "Reduces CUI exposure through principle of least privilege" ""
    else
        add_nist_check "IDENTIFY" "3.1.2" "Privileged User Management" "FAIL" "Excessive administrative privileges detected" "Admin users: $admin_users, Total users: $total_users" "Excessive privileges increase CUI exposure risk" "Review and reduce administrative accounts"
    fi

    # Check password policy configuration
    local password_policy=$(pwpolicy getaccountpolicies 2>/dev/null)
    
    if [ -n "$password_policy" ]; then
        add_nist_check "PROTECT" "3.1.2" "Password Policy Enforcement" "PASS" "Password policies configured to protect CUI access" "pwpolicy configured with account policies" "Strong passwords protect CUI from unauthorized access" ""
    else
        add_nist_check "PROTECT" "3.1.2" "Password Policy Enforcement" "FAIL" "No password policies configured" "pwpolicy shows no account policies" "Weak passwords increase CUI unauthorized access risk" "Configure password policies: sudo pwpolicy setaccountpolicies"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.1.10</span>
                        <span class="requirement-title">Use session lock with pattern-hiding displays to prevent access and viewing of data after a period of inactivity.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Session locks prevent unauthorized viewing of CUI when users step away from their systems. Pattern-hiding displays prevent shoulder surfing attacks.</div>
EOF

    # Check screen saver and lock settings
    local screensaver_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    local screensaver_delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null || echo "999")
    local screensaver_timeout=$(defaults read com.apple.screensaver idleTime 2>/dev/null || echo "3600")
    
    if [ "$screensaver_password" = "1" ] && [ "$screensaver_delay" -le 5 ]; then
        add_nist_check "PROTECT" "3.1.10" "Session Lock Configuration" "PASS" "Screen saver locks session to protect CUI from unauthorized viewing" "askForPassword: $screensaver_password, delay: $screensaver_delay seconds" "Prevents unauthorized CUI viewing when user is away" ""
    else
        add_nist_check "PROTECT" "3.1.10" "Session Lock Configuration" "FAIL" "Session lock not properly configured" "askForPassword: $screensaver_password, delay: $screensaver_delay seconds" "CRITICAL: CUI visible to unauthorized users when session unlocked" "Configure immediate session lock: System Preferences > Security & Privacy"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# NIST 800-171 Control Family 3.3 - Audit and Accountability
check_nist_audit_accountability() {
    echo "🔍 Auditing NIST 800-171 Audit and Accountability (3.3.x) - CUI Activity Monitoring..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="nist-control-section">
                <div class="nist-control-header">
                    <div class="nist-control-id">3.3 - Audit and Accountability</div>
                    <h2 class="nist-control-title">Create and Retain System Audit Logs</h2>
                    <p class="nist-control-description">Audit and accountability controls ensure that activities affecting CUI are logged, monitored, and can be traced to specific users. These controls are essential for detecting unauthorized CUI access and supporting incident response.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.3.1</span>
                        <span class="requirement-title">Create and retain system audit logs and records to the extent needed to enable the monitoring, analysis, investigation, and reporting of unlawful or unauthorized system activity.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Comprehensive audit logging is critical for CUI protection, enabling detection of unauthorized access attempts and supporting forensic analysis of security incidents.</div>
EOF

    # Check system audit daemon
    local audit_enabled=$(launchctl list | grep auditd | wc -l)
    local audit_running=$(ps aux | grep auditd | grep -v grep | wc -l)
    
    if [ "$audit_enabled" -gt 0 ] && [ "$audit_running" -gt 0 ]; then
        add_nist_check "DETECT" "3.3.1" "System Audit Daemon" "PASS" "macOS audit daemon logging system events for CUI protection" "auditd service active and running" "Provides audit trail for CUI access and system changes" ""
    else
        add_nist_check "DETECT" "3.3.1" "System Audit Daemon" "FAIL" "System audit daemon not running" "auditd service: enabled=$audit_enabled, running=$audit_running" "CRITICAL: No audit trail for CUI access and modifications" "Enable audit daemon: sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist"
    fi

    # Check security log configuration
    local security_logs=$(ls /var/log/system.log 2>/dev/null | wc -l)
    local auth_logs=$(grep -l "authentication" /var/log/*.log 2>/dev/null | wc -l)
    
    if [ "$security_logs" -gt 0 ]; then
        add_nist_check "DETECT" "3.3.1" "Security Event Logging" "PASS" "System logging capturing security events" "System logs available: $security_logs" "Security events logged for CUI protection monitoring" ""
    else
        add_nist_check "DETECT" "3.3.1" "Security Event Logging" "FAIL" "Limited security event logging" "System logs: $security_logs" "Insufficient audit trail for CUI security events" "Configure comprehensive security logging"
    fi

    # Check firewall logging
    local firewall_logging=$(defaults read /Library/Preferences/com.apple.alf loggingenabled 2>/dev/null || echo "0")
    local firewall_state=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
    
    if [ "$firewall_logging" = "1" ] && [ "$firewall_state" -ge 1 ]; then
        add_nist_check "DETECT" "3.3.1" "Network Access Logging" "PASS" "Firewall logging network access attempts" "Firewall logging: enabled, state: $firewall_state" "Network access to CUI systems is logged" ""
    else
        add_nist_check "DETECT" "3.3.1" "Network Access Logging" "FAIL" "Firewall logging not enabled" "Firewall logging: $firewall_logging, state: $firewall_state" "Network access to CUI systems not logged" "Enable firewall logging: System Preferences > Security & Privacy > Firewall > Options"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# NIST 800-171 Control Family 3.4 - Configuration Management
check_nist_configuration_management() {
    echo "🔍 Auditing NIST 800-171 Configuration Management (3.4.x) - CUI System Configuration..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="nist-control-section">
                <div class="nist-control-header">
                    <div class="nist-control-id">3.4 - Configuration Management</div>
                    <h2 class="nist-control-title">Establish and Maintain Baseline Configurations</h2>
                    <p class="nist-control-description">Configuration management ensures CUI systems maintain secure configurations and that changes are controlled, documented, and authorized. Proper configuration management prevents security misconfigurations that could expose CUI.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.4.1</span>
                        <span class="requirement-title">Establish and maintain baseline configurations and inventories of organizational systems (including hardware, software, firmware, and documentation) as the basis for building and maintaining secure configurations.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Baseline configurations provide a secure foundation for CUI systems. Regular inventory and configuration management prevent unauthorized changes that could compromise CUI protection.</div>
EOF

    # Check automatic security updates
    local auto_check=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
    local auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "0")
    local auto_install_security=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates 2>/dev/null || echo "0")
    local config_data_install=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall 2>/dev/null || echo "0")
    
    if [ "$auto_check" = "1" ] && [ "$auto_download" = "1" ] && [ "$config_data_install" = "1" ]; then
        add_nist_check "PROTECT" "3.4.1" "Automated Security Configuration Updates" "PASS" "System configured for automatic security updates to maintain CUI protection" "AutoCheck: $auto_check, AutoDownload: $auto_download, ConfigData: $config_data_install" "Maintains secure baseline configuration for CUI protection" ""
    else
        add_nist_check "PROTECT" "3.4.1" "Automated Security Configuration Updates" "FAIL" "Automatic security updates not fully configured" "AutoCheck: $auto_check, AutoDownload: $auto_download, ConfigData: $config_data_install" "CRITICAL: Security vulnerabilities may remain unpatched, exposing CUI" "Enable automatic security updates: System Preferences > Software Update"
    fi

    # Check system configuration profile management
    local profiles_installed=$(profiles list 2>/dev/null | grep -c "Configuration Profile" || echo "0")
    local mdm_enrollment=$(profiles status -type enrollment 2>/dev/null | grep "Enrolled via DEP" | wc -l)
    
    if [ "$profiles_installed" -gt 0 ] || [ "$mdm_enrollment" -gt 0 ]; then
        add_nist_check "IDENTIFY" "3.4.1" "Configuration Profile Management" "PASS" "Configuration profiles managing system security settings" "Profiles installed: $profiles_installed, MDM enrolled: $mdm_enrollment" "Centralized configuration management supports CUI protection" ""
    else
        add_nist_check "IDENTIFY" "3.4.1" "Configuration Profile Management" "MANUAL" "Manual configuration management verification required" "Profiles: $profiles_installed, MDM: $mdm_enrollment" "Manual configuration management increases CUI misconfiguration risk" "Implement enterprise configuration management solution"
    fi

    # Check for unauthorized software installation prevention
    local gatekeeper_status=$(spctl --status 2>/dev/null | grep "assessments enabled" | wc -l)
    local sip_status=$(csrutil status 2>/dev/null | grep "enabled" | wc -l)
    
    if [ "$gatekeeper_status" -eq 1 ] && [ "$sip_status" -eq 1 ]; then
        add_nist_check "PROTECT" "3.4.1" "Unauthorized Software Prevention" "PASS" "Gatekeeper and SIP prevent unauthorized software installation" "Gatekeeper: enabled, SIP: enabled" "Prevents unauthorized software that could compromise CUI" ""
    else
        add_nist_check "PROTECT" "3.4.1" "Unauthorized Software Prevention" "FAIL" "Software installation controls not properly configured" "Gatekeeper: $gatekeeper_status, SIP: $sip_status" "Unauthorized software installation could compromise CUI protection" "Enable Gatekeeper and SIP protection"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# NIST 800-171 Control Family 3.13 - System and Communications Protection
check_nist_system_protection() {
    echo "🔍 Auditing NIST 800-171 System and Communications Protection (3.13.x) - CUI Data Protection..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="nist-control-section">
                <div class="nist-control-header">
                    <div class="nist-control-id">3.13 - System and Communications Protection</div>
                    <h2 class="nist-control-title">Protect System and Communications</h2>
                    <p class="nist-control-description">System and communications protection controls ensure CUI confidentiality, integrity, and availability during storage, processing, and transmission. These controls are fundamental to CUI protection requirements.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.13.11</span>
                        <span class="requirement-title">Employ FIPS-validated cryptography when used to protect the confidentiality of CUI.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">FIPS-validated cryptography ensures that CUI encryption meets federal standards. Non-validated cryptography may not provide adequate protection for CUI.</div>
EOF

    # Check FileVault encryption
    local filevault_status=$(fdesetup status 2>/dev/null)
    local filevault_enabled=$(echo "$filevault_status" | grep "FileVault is On" | wc -l)
    local encryption_type=$(diskutil info / | grep "Encryption Type" | awk '{print $3}' || echo "None")
    
    if [ "$filevault_enabled" -eq 1 ]; then
        add_nist_check "PROTECT" "3.13.11" "FIPS-Validated Encryption (FileVault)" "PASS" "FileVault provides FIPS 140-2 validated encryption for CUI data-at-rest" "FileVault status: On, Encryption: $encryption_type" "CUI data protected with federal-grade encryption" ""
    else
        add_nist_check "PROTECT" "3.13.11" "FIPS-Validated Encryption (FileVault)" "FAIL" "FileVault not enabled - CUI data unencrypted" "FileVault status: Off" "CRITICAL: CUI data stored in plaintext violates federal requirements" "Enable FileVault immediately: System Preferences > Security & Privacy > FileVault"
    fi

    # Check secure boot capability
    local secure_boot_info=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "secure boot" | wc -l)
    local t2_chip=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "Apple T2" | wc -l)
    local apple_silicon=$(sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -i "apple" | wc -l)
    
    if [ "$secure_boot_info" -gt 0 ] || [ "$t2_chip" -gt 0 ] || [ "$apple_silicon" -gt 0 ]; then
        add_nist_check "PROTECT" "3.13.11" "Hardware-based Security" "PASS" "Hardware security features provide additional CUI protection" "Secure boot/T2/Apple Silicon detected" "Hardware-based cryptography enhances CUI protection" ""
    else
        add_nist_check "PROTECT" "3.13.11" "Hardware-based Security" "MANUAL" "Verify hardware security capabilities" "Hardware security features not detected" "Hardware-based security enhances CUI protection" "Verify hardware security capabilities and configuration"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">3.13.1</span>
                        <span class="requirement-title">Monitor, control, and protect communications (i.e., information transmitted or received by organizational systems) at the external boundaries and key internal boundaries of organizational systems.</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Boundary protection prevents unauthorized access to CUI systems and monitors CUI transmission. Firewalls and network controls are essential for CUI protection.</div>
EOF

    # Check firewall configuration
    local firewall_state=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")
    local firewall_stealth=$(defaults read /Library/Preferences/com.apple.alf stealthenabled 2>/dev/null || echo "0")
    local firewall_logging=$(defaults read /Library/Preferences/com.apple.alf loggingenabled 2>/dev/null || echo "0")
    
    case $firewall_state in
        0) firewall_status="disabled" ;;
        1) firewall_status="enabled for specific services" ;;
        2) firewall_status="enabled for essential services" ;;
        *) firewall_status="unknown" ;;
    esac
    
    if [ "$firewall_state" -ge 1 ] && [ "$firewall_stealth" = "1" ]; then
        add_nist_check "PROTECT" "3.13.1" "Network Boundary Protection" "PASS" "Firewall provides boundary protection for CUI systems" "State: $firewall_status, Stealth: enabled, Logging: $firewall_logging" "Network boundary controls protect CUI from unauthorized access" ""
    else
        add_nist_check "PROTECT" "3.13.1" "Network Boundary Protection" "FAIL" "Firewall not properly configured for CUI protection" "State: $firewall_status, Stealth: $firewall_stealth" "CRITICAL: Inadequate network protection exposes CUI to unauthorized access" "Configure firewall: System Preferences > Security & Privacy > Firewall"
    fi

    # Check for unnecessary network services
    local sharing_services=$(launchctl list | grep -E "(ssh|screen|file|remote|vnc)" | wc -l)
    local network_sharing=$(sharing -l 2>/dev/null | grep "enabled" | wc -l || echo "0")
    
    if [ "$sharing_services" -eq 0 ] && [ "$network_sharing" -eq 0 ]; then
        add_nist_check "PROTECT" "3.13.1" "Network Service Minimization" "PASS" "Unnecessary network services disabled to reduce CUI exposure" "Sharing services: $sharing_services, Network sharing: $network_sharing" "Reduced attack surface protects CUI from network-based threats" ""
    else
        add_nist_check "PROTECT" "3.13.1" "Network Service Minimization" "FAIL" "Unnecessary network services enabled" "Sharing services: $sharing_services, Network sharing: $network_sharing" "Unnecessary services increase CUI exposure risk" "Disable unnecessary network services: System Preferences > Sharing"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# Generate comprehensive executive summary
generate_executive_summary() {
    echo "📊 Generating comprehensive NIST 800-171 executive summary..."
    
    local identify_score=0; [ $IDENTIFY_TOTAL -gt 0 ] && identify_score=$(( (IDENTIFY_PASS * 100) / IDENTIFY_TOTAL ))
    local protect_score=0; [ $PROTECT_TOTAL -gt 0 ] && protect_score=$(( (PROTECT_PASS * 100) / PROTECT_TOTAL ))
    local detect_score=0; [ $DETECT_TOTAL -gt 0 ] && detect_score=$(( (DETECT_PASS * 100) / DETECT_TOTAL ))
    local respond_score=0; [ $RESPOND_TOTAL -gt 0 ] && respond_score=$(( (RESPOND_PASS * 100) / RESPOND_TOTAL ))
    local recover_score=0; [ $RECOVER_TOTAL -gt 0 ] && recover_score=$(( (RECOVER_PASS * 100) / RECOVER_TOTAL ))

    local total_checks=$((IDENTIFY_TOTAL + PROTECT_TOTAL + DETECT_TOTAL + RESPOND_TOTAL + RECOVER_TOTAL))
    local total_pass=$((IDENTIFY_PASS + PROTECT_PASS + DETECT_PASS + RESPOND_PASS + RECOVER_PASS))
    local total_fail=$((total_checks - total_pass))
    
    local overall_score=0
    if [ $total_checks -gt 0 ]; then
        overall_score=$(( (total_pass * 100) / total_checks ))
    fi
    
    cat >> "$REPORT_FILE" << EOF
            <div class="dashboard-container">
                <h2 style="font-weight: 500; font-size: 22px; color: #2c3e50; margin-bottom: 20px;">📊 NIST 800-171 CUI Assessment</h2>
                <div class="dashboard-grid">
                    <div class="dashboard-card identify">
                        <div class="icon">🎯</div>
                        <div class="details">
                            <h3>IDENTIFY</h3>
                            <p class="value">$identify_score%</p>
                            <p class="sub-text">$IDENTIFY_PASS / $IDENTIFY_TOTAL Compliant</p>
                        </div>
                    </div>
                    <div class="dashboard-card protect">
                        <div class="icon">🛡️</div>
                        <div class="details">
                            <h3>PROTECT</h3>
                            <p class="value">$protect_score%</p>
                            <p class="sub-text">$PROTECT_PASS / $PROTECT_TOTAL Compliant</p>
                        </div>
                    </div>
                    <div class="dashboard-card detect">
                        <div class="icon">👁️</div>
                        <div class="details">
                            <h3>DETECT</h3>
                            <p class="value">$detect_score%</p>
                            <p class="sub-text">$DETECT_PASS / $DETECT_TOTAL Compliant</p>
                        </div>
                    </div>
                    <div class="dashboard-card respond">
                        <div class="icon">⚡️</div>
                        <div class="details">
                            <h3>RESPOND</h3>
                            <p class="value">$respond_score%</p>
                            <p class="sub-text">$RESPOND_PASS / $RESPOND_TOTAL Compliant</p>
                        </div>
                    </div>
                    <div class="dashboard-card recover full-width-card">
                        <div class="icon">🔄</div>
                        <div class="details">
                            <h3>RECOVER</h3>
                            <p class="value">$recover_score%</p>
                            <p class="sub-text">$RECOVER_PASS / $RECOVER_TOTAL Compliant</p>
                        </div>
                    </div>
                </div>

                <div class="summary-grid">
                    <div class="summary-card summary-compliant">
                        <h4>Compliant Controls</h4>
                        <p class="value">$total_pass</p>
                    </div>
                    <div class="summary-card summary-score">
                        <h4>Compliance Score</h4>
                        <p class="value">$overall_score%</p>
                    </div>
                    <div class="summary-card summary-noncompliant">
                        <h4>Non-Compliant</h4>
                        <p class="value">$total_fail</p>
                    </div>
                    <div class="summary-card summary-total">
                        <h4>Total Controls</h4>
                        <p class="value">$total_checks</p>
                    </div>
                </div>
            </div>
EOF
}

# Generate CUI-specific recommendations
generate_cui_recommendations() {
    cat >> "$REPORT_FILE" << EOF
            <div class="cui-recommendations">
                <h2>🚀 CUI Protection Action Plan & Federal Compliance Roadmap</h2>
                
                <div class="implementation-guide priority-critical">
                    <h4>🔴 CRITICAL - Immediate CUI Protection Gaps (0-7 days)</h4>
                    <ul>
                        <li><strong>Enable FileVault Encryption:</strong> FIPS-validated encryption required for CUI data-at-rest protection</li>
                        <li><strong>Configure Network Boundary Protection:</strong> Enable and harden application firewall for CUI system protection</li>
                        <li><strong>Disable Guest Account:</strong> Prevent unauthorized CUI access through anonymous accounts</li>
                        <li><strong>Enable System Integrity Protection:</strong> Prevent unauthorized system modifications that could compromise CUI</li>
                        <li><strong>Configure Session Locks:</strong> Immediate password requirement to prevent unauthorized CUI viewing</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-high">
                    <h4>🟡 HIGH PRIORITY - Federal Contract Compliance (7-30 days)</h4>
                    <ul>
                        <li><strong>Implement Comprehensive Audit Logging:</strong> Enable system audit daemon and security event logging</li>
                        <li><strong>Deploy Configuration Management:</strong> Implement automated security updates and configuration profiles</li>
                        <li><strong>Establish Password Policies:</strong> Configure NIST-compliant password requirements</li>
                        <li><strong>Review Privileged Access:</strong> Implement principle of least privilege for CUI access</li>
                        <li><strong>Document CUI Handling Procedures:</strong> Create System Security Plan (SSP) and CUI policies</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-medium">
                    <h4>🟢 MEDIUM PRIORITY - Continuous Compliance (30-90 days)</h4>
                    <ul>
                        <li><strong>Deploy Enterprise MDM Solution:</strong> Centralized configuration management for CUI systems</li>
                        <li><strong>Implement Continuous Monitoring:</strong> Real-time security monitoring and incident detection</li>
                        <li><strong>Conduct Security Awareness Training:</strong> CUI handling and protection training for personnel</li>
                        <li><strong>Establish Incident Response:</strong> CUI breach notification and response procedures</li>
                        <li><strong>Schedule Regular Assessments:</strong> Quarterly NIST 800-171 compliance validation</li>
                    </ul>
                </div>
                
                <div class="mscp-reference">
                    <h5>📚 Federal Compliance Resources</h5>
                    <ul>
                        <li><strong>NIST 800-171 Rev 2:</strong> <a href="https://csrc.nist.gov/publications/detail/sp/800-171/rev-2/final">Official NIST Publication</a></li>
                        <li><strong>mSCP Project:</strong> <a href="https://github.com/usnistgov/macos_security">macOS Security Compliance Project</a></li>
                        <li><strong>DFARS 252.204-7012:</strong> Safeguarding Covered Defense Information and Cyber Incident Reporting</li>
                        <li><strong>CMMC Model:</strong> <a href="https://www.acq.osd.mil/cmmc/">Cybersecurity Maturity Model Certification</a></li>
                        <li><strong>CUI Registry:</strong> <a href="https://www.archives.gov/cui">National Archives CUI Program</a></li>
                    </ul>
                </div>
                
                <div class="cui-consideration">
                    <h5>⚖️ Legal and Contractual Implications</h5>
                    <p><strong>Contract Compliance:</strong> Non-compliance with NIST 800-171 requirements may result in loss of federal contracts, financial penalties, and exclusion from future government work. Organizations must demonstrate continuous compliance to maintain federal contracting eligibility.</p>
                    <p><strong>CUI Incident Reporting:</strong> Any suspected or confirmed CUI compromise must be reported to contracting officers within 72 hours per DFARS 252.204-7012 requirements.</p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF
}

# Main execution
echo "🚀 NIST 800-171 Rev 2 - Comprehensive CUI Protection Audit"
echo "========================================================="
echo "Assessment Date: $TIMESTAMP"
echo "System: macOS $MACOS_VERSION (Build $BUILD_VERSION)"
echo "Serial: $SYSTEM_SERIAL"
echo "Standard: NIST Special Publication 800-171 Revision 2"
echo "Framework: mSCP (macOS Security Compliance Project) Aligned"
echo "Scope: Controlled Unclassified Information (CUI) Protection"
echo "========================================================="
echo

# Initialize comprehensive HTML report
init_html_report

# Execute all NIST 800-171 control family assessments
check_nist_access_control         # 3.1.x - Access Control
check_nist_audit_accountability   # 3.3.x - Audit and Accountability
check_nist_configuration_management # 3.4.x - Configuration Management
check_nist_system_protection      # 3.13.x - System and Communications Protection

# Generate executive summary and CUI recommendations
generate_executive_summary
generate_cui_recommendations

# Calculate final compliance metrics
total_checks=$((IDENTIFY_TOTAL + PROTECT_TOTAL + DETECT_TOTAL + RESPOND_TOTAL + RECOVER_TOTAL))
total_pass=$((IDENTIFY_PASS + PROTECT_PASS + DETECT_PASS + RESPOND_PASS + RECOVER_PASS))
total_fail=$((IDENTIFY_TOTAL - IDENTIFY_PASS + PROTECT_TOTAL - PROTECT_PASS + DETECT_TOTAL - DETECT_PASS + RESPOND_TOTAL - RESPOND_PASS + RECOVER_TOTAL - RECOVER_PASS))
total_manual=$((IDENTIFY_TOTAL - IDENTIFY_PASS + PROTECT_TOTAL - PROTECT_PASS + DETECT_TOTAL - DETECT_PASS + RESPOND_TOTAL - RESPOND_PASS + RECOVER_TOTAL - RECOVER_PASS))

echo "✅ NIST 800-171 comprehensive CUI protection audit complete!"
echo "📊 CUI Protection Assessment Summary:"
echo "   Total Requirements Evaluated: $total_checks"
echo "   Requirements Compliant: $total_pass"
echo "   Requirements Non-Compliant: $total_fail"
echo "   Manual Reviews Required: $total_manual"
if [ $total_checks -gt 0 ]; then
    echo "   Overall CUI Compliance Score: $(( (total_pass * 100) / total_checks ))%"
else
    echo "   Overall CUI Compliance Score: 0%"
fi
echo
echo "📋 Comprehensive Report: $REPORT_FILE"
echo "🌐 Open CUI protection report: open $REPORT_FILE"
echo
echo "🎯 Federal Compliance Next Steps:"
echo "   1. Address CRITICAL CUI protection gaps immediately (0-7 days)"
echo "   2. Implement HIGH priority federal contract requirements (7-30 days)"
echo "   3. Establish continuous CUI protection monitoring (30-90 days)"
echo "   4. Document System Security Plan (SSP) and CUI handling procedures"
echo "   5. Schedule quarterly NIST 800-171 compliance assessments"
