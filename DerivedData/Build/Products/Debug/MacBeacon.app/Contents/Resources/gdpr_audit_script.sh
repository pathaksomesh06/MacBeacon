#!/bin/bash

# macOS GDPR Compliance Audit Script with Comprehensive HTML Report
# Version 3.0 - Full GDPR Article Coverage

REPORT_FILE=${1:-"gdpr_compliance_report.html"}
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Initialize counters for GDPR compliance areas
LEGAL_BASIS_SCORE=0; LEGAL_BASIS_TOTAL=0
DATA_RIGHTS_SCORE=0; DATA_RIGHTS_TOTAL=0
SECURITY_SCORE=0; SECURITY_TOTAL=0
ACCOUNTABILITY_SCORE=0; ACCOUNTABILITY_TOTAL=0
TRANSPARENCY_SCORE=0; TRANSPARENCY_TOTAL=0

# Initialize HTML report with comprehensive GDPR styling
init_html_report() {
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>macOS GDPR Compliance Audit Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); overflow: hidden; }
        .header { background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); color: white; padding: 40px; position: relative; }
        .header::before { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="25" cy="25" r="1" fill="white" opacity="0.1"/><circle cx="75" cy="75" r="1" fill="white" opacity="0.1"/><circle cx="50" cy="10" r="1" fill="white" opacity="0.1"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>'); }
        .header h1 { margin: 0; font-size: 32px; font-weight: 300; position: relative; z-index: 1; }
        .header .subtitle { font-size: 16px; opacity: 0.9; margin-top: 10px; position: relative; z-index: 1; }
        .timestamp { opacity: 0.8; margin-top: 5px; position: relative; z-index: 1; }
        .content { padding: 40px; }
        .gdpr-overview { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 25px; margin-bottom: 40px; }
        .overview-card { padding: 30px; border-radius: 12px; text-align: center; box-shadow: 0 4px 20px rgba(0,0,0,0.08); position: relative; overflow: hidden; }
        .legal-basis { background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
        .data-rights { background: linear-gradient(135deg, #f093fb, #f5576c); color: white; }
        .security { background: linear-gradient(135deg, #4facfe, #00f2fe); color: white; }
        .accountability { background: linear-gradient(135deg, #43e97b, #38f9d7); color: #333; }
        .transparency { background: linear-gradient(135deg, #fa709a, #fee140); color: white; }
        .section { margin-bottom: 35px; padding: 30px; border: 1px solid #e1e5e9; border-radius: 12px; background: #fafbfc; }
        .section h2 { color: #2c3e50; margin-top: 0; font-size: 24px; border-bottom: 3px solid #3498db; padding-bottom: 12px; }
        .gdpr-article { font-family: 'Monaco', 'Courier New', monospace; font-size: 11px; background: #e74c3c; color: white; padding: 3px 8px; border-radius: 12px; display: inline-block; margin-right: 10px; }
        .compliance-status { font-weight: bold; padding: 8px 16px; border-radius: 20px; display: inline-block; }
        .compliant { background: #d4edda; color: #155724; }
        .partial { background: #fff3cd; color: #856404; }
        .non-compliant { background: #f8d7da; color: #721c24; }
        .risk-high { background: #dc3545; color: white; }
        .metric { display: flex; justify-content: space-between; align-items: center; padding: 18px 0; border-bottom: 1px solid #e9ecef; }
        .metric:last-child { border-bottom: none; }
        .metric-description { flex: 1; }
        .metric-title { font-weight: 600; color: #2c3e50; margin-bottom: 5px; }
        .metric-detail { font-size: 14px; color: #6c757d; }
        .progress-bar { width: 100%; height: 32px; background: #e9ecef; border-radius: 16px; overflow: hidden; margin: 20px 0; position: relative; }
        .progress-fill { height: 100%; transition: all 0.6s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 15px; position: relative; }
        .progress-excellent { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-good { background: linear-gradient(90deg, #17a2b8, #6f42c1); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #fd7e14); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #e83e8c); }
        .icon { font-size: 42px; margin-bottom: 18px; }
        .score-display { font-size: 28px; font-weight: bold; margin-top: 15px; }
        .remediation { background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px; margin: 15px 0; }
        .remediation h4 { color: #495057; margin-top: 0; }
        .data-flow { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #007bff; }
        .privacy-notice { background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 15px 0; border: 1px solid #b3d9ff; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 GDPR Compliance Audit</h1>
            <div class="subtitle">General Data Protection Regulation (EU) 2016/679</div>
            <div class="timestamp">Assessment Date: $TIMESTAMP</div>
        </div>
        <div class="content">
EOF
}

# Function to add GDPR compliance check
add_gdpr_check() {
    local category="$1"
    local article="$2"
    local title="$3"
    local status="$4"
    local details="$5"
    local remediation="$6"
    
    # Update category scores
    case $category in
        "LEGAL_BASIS") LEGAL_BASIS_TOTAL=$((LEGAL_BASIS_TOTAL + 1)); [ "$status" = "COMPLIANT" ] && LEGAL_BASIS_SCORE=$((LEGAL_BASIS_SCORE + 1)) ;;
        "DATA_RIGHTS") DATA_RIGHTS_TOTAL=$((DATA_RIGHTS_TOTAL + 1)); [ "$status" = "COMPLIANT" ] && DATA_RIGHTS_SCORE=$((DATA_RIGHTS_SCORE + 1)) ;;
        "SECURITY") SECURITY_TOTAL=$((SECURITY_TOTAL + 1)); [ "$status" = "COMPLIANT" ] && SECURITY_SCORE=$((SECURITY_SCORE + 1)) ;;
        "ACCOUNTABILITY") ACCOUNTABILITY_TOTAL=$((ACCOUNTABILITY_TOTAL + 1)); [ "$status" = "COMPLIANT" ] && ACCOUNTABILITY_SCORE=$((ACCOUNTABILITY_SCORE + 1)) ;;
        "TRANSPARENCY") TRANSPARENCY_TOTAL=$((TRANSPARENCY_TOTAL + 1)); [ "$status" = "COMPLIANT" ] && TRANSPARENCY_SCORE=$((TRANSPARENCY_SCORE + 1)) ;;
    esac
    
    local status_class=$(echo $status | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
    
    cat >> "$REPORT_FILE" << EOF
                <div class="metric">
                    <div class="metric-description">
                        <div class="metric-title">
                            <span class="gdpr-article">$article</span>$title
                        </div>
                        <div class="metric-detail">$details</div>
                    </div>
                    <div>
                        <span class="compliance-status $status_class">$status</span>
                    </div>
                </div>
EOF

    if [ "$status" != "COMPLIANT" ] && [ -n "$remediation" ]; then
        cat >> "$REPORT_FILE" << EOF
                <div class="remediation">
                    <h4>📋 Remediation Required:</h4>
                    <p>$remediation</p>
                </div>
EOF
    fi
}

# GDPR Article 6 - Lawfulness of Processing
check_legal_basis() {
    echo "Assessing lawfulness of processing..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>⚖️ Legal Basis for Processing</h2>
EOF
    
    # Check for consent management
    local consent_mechanism=$(find ~/Library -name "*consent*" -o -name "*cookie*" 2>/dev/null | wc -l)
    if [ "$consent_mechanism" -gt 0 ]; then
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Legal basis documented" "PARTIAL" "Some consent-related files found" "Document legal basis for all data processing activities"
    else
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Legal basis documented" "NON_COMPLIANT" "No consent management mechanism detected" "Implement consent management system and document legal basis for all processing"
    fi
    
    # Check for cookie consent (browser data)
    local safari_cookies=$(find ~/Library/Cookies -name "*.binarycookies" 2>/dev/null | wc -l)
    if [ "$safari_cookies" -gt 0 ]; then
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Cookie consent management" "PARTIAL" "Cookies present - consent status unknown" "Implement cookie consent banner and document cookie purposes"
    else
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Cookie consent management" "COMPLIANT" "No cookies requiring consent detected" ""
    fi
    
    # Check for marketing/tracking files
    local tracking_files=$(find ~/Library -name "*analytic*" -o -name "*track*" -o -name "*marketing*" 2>/dev/null | wc -l)
    if [ "$tracking_files" -gt 5 ]; then
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Marketing consent obtained" "NON_COMPLIANT" "Multiple tracking/analytics files without documented consent" "Obtain explicit consent for marketing and tracking activities"
    else
        add_gdpr_check "LEGAL_BASIS" "Art. 6" "Marketing consent obtained" "COMPLIANT" "Limited tracking activity detected" ""
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# GDPR Articles 15-22 - Data Subject Rights
check_data_subject_rights() {
    echo "Assessing data subject rights implementation..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>👤 Data Subject Rights</h2>
EOF
    
    # Right of Access (Article 15)
    local user_data_access=$(ls -la ~/Library/Application\ Support/ 2>/dev/null | wc -l)
    if [ "$user_data_access" -gt 10 ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Right of access implementable" "PARTIAL" "User data accessible but no formal process" "Create data access request procedure and automate data export"
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Right of access implementable" "NON_COMPLIANT" "Limited user data accessibility" "Implement comprehensive data access mechanisms"
    fi
    
    # Right to Rectification (Article 16)
    local editable_profiles=$(find ~/Library/Preferences -name "*.plist" 2>/dev/null | head -5 | wc -l)
    if [ "$editable_profiles" -gt 0 ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 16" "Right to rectification supported" "COMPLIANT" "User preferences are editable" ""
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 16" "Right to rectification supported" "NON_COMPLIANT" "No user data modification capability" "Implement data correction procedures"
    fi
    
    # Right to Erasure (Article 17)
    local deletion_capability=$(which rm >/dev/null && echo "1" || echo "0")
    if [ "$deletion_capability" = "1" ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 17" "Right to erasure implementable" "PARTIAL" "System deletion tools available" "Create automated data deletion procedures with retention policy compliance"
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 17" "Right to erasure implementable" "NON_COMPLIANT" "No data deletion capability" "Implement secure data deletion mechanisms"
    fi
    
    # Data Portability (Article 20)
    local export_formats=$(which zip >/dev/null && which tar >/dev/null && echo "1" || echo "0")
    if [ "$export_formats" = "1" ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 20" "Data portability supported" "PARTIAL" "Basic export tools available" "Create structured data export in machine-readable formats (JSON, CSV, XML)"
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 20" "Data portability supported" "NON_COMPLIANT" "No data export capability" "Implement comprehensive data portability features"
    fi
    
    # Right to Object (Article 21)
    local opt_out_mechanism=$(defaults read NSGlobalDomain | grep -i "opt" | wc -l)
    if [ "$opt_out_mechanism" -gt 0 ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 21" "Right to object mechanisms" "PARTIAL" "Some opt-out preferences found" "Implement comprehensive objection mechanisms for all processing activities"
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 21" "Right to object mechanisms" "NON_COMPLIANT" "No objection mechanisms detected" "Create user-friendly opt-out systems for all data processing"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# GDPR Article 32 - Security of Processing
check_security_measures() {
    echo "Assessing security of processing..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🔐 Security of Processing</h2>
EOF
    
    # Encryption at rest
    local filevault_status=$(fdesetup status | grep "FileVault is On" | wc -l)
    if [ "$filevault_status" -eq 1 ]; then
        add_gdpr_check "SECURITY" "Art. 32" "Encryption of personal data at rest" "COMPLIANT" "FileVault full-disk encryption enabled" ""
    else
        add_gdpr_check "SECURITY" "Art. 32" "Encryption of personal data at rest" "NON_COMPLIANT" "No disk encryption detected" "Enable FileVault encryption immediately to protect personal data"
    fi
    
    # Access controls
    local password_required=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
    if [ "$password_required" = "1" ]; then
        add_gdpr_check "SECURITY" "Art. 32" "Access controls implemented" "COMPLIANT" "Screen lock with password enabled" ""
    else
        add_gdpr_check "SECURITY" "Art. 32" "Access controls implemented" "NON_COMPLIANT" "No screen lock password required" "Enable immediate screen lock with password requirement"
    fi
    
    # System integrity
    local sip_status=$(csrutil status | grep "enabled" | wc -l)
    if [ "$sip_status" -eq 1 ]; then
        add_gdpr_check "SECURITY" "Art. 32" "System integrity protection" "COMPLIANT" "System Integrity Protection enabled" ""
    else
        add_gdpr_check "SECURITY" "Art. 32" "System integrity protection" "NON_COMPLIANT" "System integrity compromised" "Re-enable System Integrity Protection"
    fi
    
    # Network security
    local firewall_status=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
    if [ "$firewall_status" = "1" ] || [ "$firewall_status" = "2" ]; then
        add_gdpr_check "SECURITY" "Art. 32" "Network security measures" "COMPLIANT" "Firewall protection enabled" ""
    else
        add_gdpr_check "SECURITY" "Art. 32" "Network security measures" "NON_COMPLIANT" "No network firewall protection" "Enable and configure firewall protection"
    fi
    
    # Backup security
    local backup_encryption=$(tmutil islocal 2>/dev/null && echo "encrypted" || echo "unknown")
    if [ "$backup_encryption" = "encrypted" ]; then
        add_gdpr_check "SECURITY" "Art. 32" "Secure backup procedures" "COMPLIANT" "Encrypted backup system configured" ""
    else
        add_gdpr_check "SECURITY" "Art. 32" "Secure backup procedures" "PARTIAL" "Backup status unclear - verify encryption" "Ensure all backups containing personal data are encrypted"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# GDPR Articles 5, 25, 30 - Accountability and Data Protection by Design
check_accountability() {
    echo "Assessing accountability measures..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>📋 Accountability & Documentation</h2>
EOF
    
    # Records of processing (Article 30)
    local processing_records=$(find ~/Documents -name "*gdpr*" -o -name "*processing*" -o -name "*privacy*" 2>/dev/null | wc -l)
    if [ "$processing_records" -gt 0 ]; then
        add_gdpr_check "ACCOUNTABILITY" "Art. 30" "Records of processing activities" "PARTIAL" "Some privacy-related documents found" "Complete comprehensive processing activity records with legal basis, purposes, and retention periods"
    else
        add_gdpr_check "ACCOUNTABILITY" "Art. 30" "Records of processing activities" "NON_COMPLIANT" "No processing records documented" "Create detailed records of all personal data processing activities"
    fi
    
    # Data minimisation (Article 5)
    local app_permissions=$(sqlite3 ~/Library/TCC/TCC.db "SELECT COUNT(*) FROM access;" 2>/dev/null || echo "0")
    if [ "$app_permissions" -lt 10 ]; then
        add_gdpr_check "ACCOUNTABILITY" "Art. 5" "Data minimisation principle" "COMPLIANT" "Limited app permissions - good data minimisation" ""
    else
        add_gdpr_check "ACCOUNTABILITY" "Art. 5" "Data minimisation principle" "PARTIAL" "$app_permissions app permissions granted - review necessity" "Review all app permissions and revoke unnecessary access to personal data"
    fi
    
    # Purpose limitation (Article 5)
    local purpose_documentation=$(find ~/Documents -name "*purpose*" -o -name "*policy*" 2>/dev/null | wc -l)
    if [ "$purpose_documentation" -gt 0 ]; then
        add_gdpr_check "ACCOUNTABILITY" "Art. 5" "Purpose limitation documented" "PARTIAL" "Some policy documentation found" "Document specific purposes for all data processing and ensure compatibility"
    else
        add_gdpr_check "ACCOUNTABILITY" "Art. 5" "Purpose limitation documented" "NON_COMPLIANT" "No purpose limitation documentation" "Document specific, explicit, and legitimate purposes for all data processing"
    fi
    
    # Data Protection by Design (Article 25)
    local privacy_settings=$(defaults read NSGlobalDomain | grep -i privacy | wc -l)
    if [ "$privacy_settings" -gt 0 ]; then
        add_gdpr_check "ACCOUNTABILITY" "Art. 25" "Privacy by design implemented" "PARTIAL" "Some privacy settings configured" "Implement comprehensive privacy-by-design measures in all data processing systems"
    else
        add_gdpr_check "ACCOUNTABILITY" "Art. 25" "Privacy by design implemented" "NON_COMPLIANT" "No privacy-by-design measures detected" "Integrate privacy protection into all data processing activities by design and by default"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# GDPR Articles 12-14 - Transparency and Information
check_transparency() {
    echo "Assessing transparency obligations..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>📋 Transparency & Information</h2>
EOF
    
    # Privacy notices (Article 13-14)
    local privacy_notices=$(find ~/Documents ~/Desktop -name "*privacy*" -o -name "*notice*" -o -name "*policy*" 2>/dev/null | wc -l)
    if [ "$privacy_notices" -gt 0 ]; then
        add_gdpr_check "TRANSPARENCY" "Art. 13-14" "Privacy notices provided" "PARTIAL" "Privacy-related documents found" "Ensure privacy notices contain all required GDPR information and are easily accessible"
    else
        add_gdpr_check "TRANSPARENCY" "Art. 13-14" "Privacy notices provided" "NON_COMPLIANT" "No privacy notices found" "Create comprehensive privacy notices with controller identity, purposes, legal basis, retention periods, and data subject rights"
    fi
    
    # Transparent communication (Article 12)
    local user_documentation=$(find ~/Documents -name "*help*" -o -name "*user*" -o -name "*guide*" 2>/dev/null | wc -l)
    if [ "$user_documentation" -gt 2 ]; then
        add_gdpr_check "TRANSPARENCY" "Art. 12" "Clear and plain language" "COMPLIANT" "User documentation available in accessible format" ""
    else
        add_gdpr_check "TRANSPARENCY" "Art. 12" "Clear and plain language" "PARTIAL" "Limited user documentation" "Provide clear, plain language information about data processing activities"
    fi
    
    # Contact information for data protection
    local contact_info=$(grep -r "privacy\|data.protection\|gdpr" ~/Documents 2>/dev/null | wc -l)
    if [ "$contact_info" -gt 0 ]; then
        add_gdpr_check "TRANSPARENCY" "Art. 13" "Contact information provided" "PARTIAL" "Some privacy contact information found" "Provide clear contact information for data protection officer or responsible person"
    else
        add_gdpr_check "TRANSPARENCY" "Art. 13" "Contact information provided" "NON_COMPLIANT" "No privacy contact information found" "Provide contact details for data protection inquiries and complaints"
    fi
    
    echo "            </div>" >> "$REPORT_FILE"
}

# Function to generate GDPR overview cards
add_gdpr_overview() {
    local legal_score=$(( LEGAL_BASIS_TOTAL > 0 ? LEGAL_BASIS_SCORE * 100 / LEGAL_BASIS_TOTAL : 0 ))
    local rights_score=$(( DATA_RIGHTS_TOTAL > 0 ? DATA_RIGHTS_SCORE * 100 / DATA_RIGHTS_TOTAL : 0 ))
    local security_score=$(( SECURITY_TOTAL > 0 ? SECURITY_SCORE * 100 / SECURITY_TOTAL : 0 ))
    local accountability_score=$(( ACCOUNTABILITY_TOTAL > 0 ? ACCOUNTABILITY_SCORE * 100 / ACCOUNTABILITY_TOTAL : 0 ))
    local transparency_score=$(( TRANSPARENCY_TOTAL > 0 ? TRANSPARENCY_SCORE * 100 / TRANSPARENCY_TOTAL : 0 ))
    
    local overall_score=$(( (legal_score + rights_score + security_score + accountability_score + transparency_score) / 5 ))
    
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-overview">
                <div class="overview-card legal-basis">
                    <div class="icon">⚖️</div>
                    <h3>Legal Basis</h3>
                    <p>Lawfulness of Processing<br>Consent Management<br>Purpose Limitation</p>
                    <div class="score-display">$legal_score%</div>
                </div>
                <div class="overview-card data-rights">
                    <div class="icon">👤</div>
                    <h3>Data Subject Rights</h3>
                    <p>Access, Rectification<br>Erasure, Portability<br>Objection Rights</p>
                    <div class="score-display">$rights_score%</div>
                </div>
                <div class="overview-card security">
                    <div class="icon">🔐</div>
                    <h3>Security Measures</h3>
                    <p>Encryption, Access Control<br>Integrity Protection<br>Secure Backups</p>
                    <div class="score-display">$security_score%</div>
                </div>
                <div class="overview-card accountability">
                    <div class="icon">📋</div>
                    <h3>Accountability</h3>
                    <p>Processing Records<br>Data Minimisation<br>Privacy by Design</p>
                    <div class="score-display">$accountability_score%</div>
                </div>
                <div class="overview-card transparency">
                    <div class="icon">📄</div>
                    <h3>Transparency</h3>
                    <p>Privacy Notices<br>Clear Communication<br>Contact Information</p>
                    <div class="score-display">$transparency_score%</div>
                </div>
            </div>
            
            <div class="section">
                <h2>📊 Overall GDPR Compliance Score</h2>
                <div class="progress-bar">
                    <div class="progress-fill $([ $overall_score -ge 90 ] && echo "progress-excellent" || ([ $overall_score -ge 70 ] && echo "progress-good" || ([ $overall_score -ge 50 ] && echo "progress-warning" || echo "progress-danger")))" style="width: $overall_score%;">
                        $overall_score% GDPR Compliant
                    </div>
                </div>
                <div class="privacy-notice">
                    <strong>Compliance Level:</strong> $([ $overall_score -ge 90 ] && echo "Excellent - Well-prepared for GDPR audits" || ([ $overall_score -ge 70 ] && echo "Good - Minor improvements needed" || ([ $overall_score -ge 50 ] && echo "Moderate - Significant work required" || echo "Poor - Major compliance gaps identified")))
                    <br><strong>Risk Assessment:</strong> $([ $overall_score -ge 70 ] && echo "Low risk of regulatory action" || ([ $overall_score -ge 50 ] && echo "Medium risk - address critical gaps immediately" || echo "High risk - immediate remediation required"))
                </div>
            </div>
EOF
}

# Function to finish HTML report with comprehensive recommendations
finish_html_report() {
    cat >> "$REPORT_FILE" << EOF
            <div class="section">
                <h2>🚀 GDPR Compliance Action Plan</h2>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 25px;">
                    <div class="data-flow">
                        <h4>🔴 Critical Actions (Complete within 30 days)</h4>
                        <ul>
                            <li>Enable FileVault encryption for all devices</li>
                            <li>Document legal basis for all data processing</li>
                            <li>Create comprehensive privacy notices</li>
                            <li>Implement data subject request procedures</li>
                            <li>Establish data breach notification process</li>
                        </ul>
                    </div>
                    <div class="data-flow">
                        <h4>🟡 Important Actions (Complete within 90 days)</h4>
                        <ul>
                            <li>Complete records of processing activities</li>
                            <li>Implement privacy by design measures</li>
                            <li>Review and minimize app permissions</li>
                            <li>Create data retention and deletion policies</li>
                            <li>Train staff on GDPR compliance</li>
                        </ul>
                    </div>
                    <div class="data-flow">
                        <h4>🔵 Ongoing Actions</h4>
                        <ul>
                            <li>Regular privacy impact assessments</li>
                            <li>Continuous monitoring of data flows</li>
                            <li>Annual GDPR compliance audits</li>
                            <li>Update privacy notices as needed</li>
                            <li>Monitor regulatory guidance updates</li>
                        </ul>
                    </div>
                </div>
                
                <div class="privacy-notice">
                    <h4>⚠️ Legal Disclaimer</h4>
                    <p>This automated audit provides a technical assessment only. GDPR compliance requires legal review of your specific data processing activities, purposes, and legal basis. Consult with qualified data protection professionals and legal counsel for comprehensive compliance guidance.</p>
                </div>
                
                <div class="data-flow">
                    <h4>📞 Next Steps</h4>
                    <ol>
                        <li>Address all NON-COMPLIANT items immediately</li>
                        <li>Review and complete all PARTIAL compliance items</li>
                        <li>Document all remediation actions taken</li>
                        <li>Schedule regular compliance reviews</li>
                        <li>Consider appointing a Data Protection Officer if required</li>
                    </ol>
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
echo "GDPR Compliance Audit"
echo "=================================="
echo "2025-09-02 21:31:43 [INFO]  mac_audit_enhanced starting (PID $$)"
echo "Analyzing GDPR compliance across all requirements..."
echo

# Initialize HTML report
init_html_report

# Run comprehensive GDPR assessments
check_legal_basis
check_data_subject_rights
check_security_measures
check_accountability
check_transparency

# Add overview dashboard
add_gdpr_overview

# Finish HTML report
finish_html_report

# Calculate final scores
total_checks=$((LEGAL_BASIS_TOTAL + DATA_RIGHTS_TOTAL + SECURITY_TOTAL + ACCOUNTABILITY_TOTAL + TRANSPARENCY_TOTAL))
total_compliant=$((LEGAL_BASIS_SCORE + DATA_RIGHTS_SCORE + SECURITY_SCORE + ACCOUNTABILITY_SCORE + TRANSPARENCY_SCORE))
overall_compliance=$(( total_checks > 0 ? total_compliant * 100 / total_checks : 0 ))

echo "✅ GDPR compliance audit complete!"
echo "📊 Report saved to: $REPORT_FILE"
echo "🌐 Open in browser: open $REPORT_FILE"
echo "📋 Overall Compliance: $overall_compliance% ($total_compliant/$total_checks requirements met)"
echo "⚖️ $([ $overall_compliance -ge 70 ] && echo "Low regulatory risk" || echo "⚠️ High regulatory risk - immediate action required")"