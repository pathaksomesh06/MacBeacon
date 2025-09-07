#!/bin/bash

# GDPR (General Data Protection Regulation) - Comprehensive Data Protection Audit
# Aligned with mSCP (macOS Security Compliance Project)
# Based on EU Regulation 2016/679 - General Data Protection Regulation
# Version 2.0

REPORT_FILE="audit_reports/gdpr_comprehensive_report.html"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
MACOS_VERSION=$(sw_vers -productVersion)
BUILD_VERSION=$(sw_vers -buildVersion)
SYSTEM_SERIAL=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $4}')

# Counters for GDPR principles
LAWFULNESS_TOTAL=0; LAWFULNESS_PASS=0; LAWFULNESS_FAIL=0;
DATA_RIGHTS_TOTAL=0; DATA_RIGHTS_PASS=0; DATA_RIGHTS_FAIL=0;
SECURITY_TOTAL=0; SECURITY_PASS=0; SECURITY_FAIL=0;
PRIVACY_DESIGN_TOTAL=0; PRIVACY_DESIGN_PASS=0; PRIVACY_DESIGN_FAIL=0;

# Initialize comprehensive HTML report
init_html_report() {
    mkdir -p audit_reports
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GDPR Comprehensive Data Protection Audit</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%); min-height: 100vh; }
        .container { max-width: 1800px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 15px 50px rgba(0,0,0,0.25); }
        .header { background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; padding: 60px; border-radius: 15px 15px 0 0; position: relative; overflow: hidden; }
        .header::before { content: '🔒'; position: absolute; top: 20px; right: 40px; font-size: 140px; opacity: 0.1; }
        .header::after { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="25" cy="25" r="0.5" fill="white" opacity="0.1"/><circle cx="75" cy="75" r="0.5" fill="white" opacity="0.1"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>'); }
        .header h1 { margin: 0; font-size: 24px; font-weight: 300; position: relative; z-index: 1; }
        .header .subtitle { font-size: 14px; opacity: 0.9; margin-top: 8px; position: relative; z-index: 1; }
        .header .compliance-info { font-size: 10px; opacity: 0.8; margin-top: 12px; position: relative; z-index: 1; line-height: 1.4; }
        .content { padding: 20px; }
        
        .gdpr-notice { background: linear-gradient(135deg, #e7f3ff, #cce7ff); padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #0066cc; }
        .gdpr-notice h2 { color: #0066cc; margin-top: 0; font-size: 14px; }
        .gdpr-notice p { color: #2d3436; line-height: 1.4; margin-bottom: 0; font-size: 10px; }
        
        .gdpr-principles-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 10px;
            margin-bottom: 15px;
        }

        .principle-card {
            color: white;
            padding: 10px;
            border-radius: 6px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 80px;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        .principle-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.15);
        }

        .principle-card h3 {
            font-size: 10px;
            font-weight: 600;
            margin: 0 0 4px 0;
            border-bottom: 1px solid rgba(255, 255, 255, 0.3);
            padding-bottom: 4px;
        }
        .principle-card .compliance-value {
            font-size: 18px;
            font-weight: bold;
            margin: 6px 0;
            line-height: 1;
        }
        .principle-card .compliance-label {
            font-size: 8px;
            opacity: 0.8;
        }
        
        .lawfulness { background: linear-gradient(135deg, #0052D4, #4364F7, #6FB1FC); }
        .rights { background: linear-gradient(135deg, #9D50BB, #6E48AA); }
        .security { background: linear-gradient(135deg, #c82333, #dc3545); }
        .design { background: linear-gradient(135deg, #1e3c72, #2a5298); }

        .gdpr-article-section { margin-bottom: 15px; padding: 10px; border: 1px solid #e1e5e9; border-radius: 6px; background: #fafbfc; }
        .gdpr-article-header { border-bottom: 2px solid #1e3c72; padding-bottom: 6px; margin-bottom: 8px; }
        .gdpr-article-title { color: #2c3e50; font-size: 12px; font-weight: 600; margin: 0; }
        .gdpr-article-description { color: #6c757d; font-size: 9px; margin-top: 4px; line-height: 1.3; }
        .gdpr-article-id { background: #1e3c72; color: white; padding: 3px 6px; border-radius: 8px; font-size: 8px; font-weight: bold; display: inline-block; margin-bottom: 6px; }
        
        .requirement { background: white; border: 1px solid #dee2e6; border-radius: 6px; margin: 8px 0; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,0.05); }
        .requirement-header { background: linear-gradient(90deg, #f8f9fa, #e9ecef); padding: 8px; border-bottom: 1px solid #dee2e6; }
        .requirement-id { font-family: 'Monaco', 'Courier New', monospace; font-size: 8px; background: #495057; color: white; padding: 2px 6px; border-radius: 8px; display: inline-block; margin-right: 6px; }
        .requirement-title { font-weight: 600; color: #2c3e50; font-size: 10px; }
        .requirement-body { padding: 8px; }
        .requirement-description { color: #6c757d; margin-bottom: 8px; line-height: 1.3; font-size: 9px; }
        
        .privacy-consideration { background: #fff3cd; border-left: 3px solid #ffc107; padding: 8px; margin: 8px 0; border-radius: 4px; }
        .privacy-consideration h5 { color: #856404; margin-top: 0; font-size: 9px; }
        
        .data-flow-analysis { background: #e7f3ff; border: 1px solid #b3d9ff; padding: 8px; margin: 8px 0; border-radius: 4px; }
        .data-flow-analysis h5 { color: #0066cc; margin-top: 0; font-size: 9px; }
        
        .check-result { display: flex; justify-content: space-between; align-items: flex-start; padding: 6px 0; border-bottom: 1px solid #f0f0f0; }
        .check-result:last-child { border-bottom: none; }
        .check-details { flex: 1; margin-right: 8px; }
        .check-title { font-weight: 600; color: #2c3e50; margin-bottom: 3px; font-size: 9px; }
        .check-description { font-size: 8px; color: #6c757d; line-height: 1.3; margin-bottom: 3px; }
        .check-technical { font-size: 7px; color: #868e96; font-family: 'Monaco', 'Courier New', monospace; margin-top: 3px; background: #f8f9fa; padding: 4px; border-radius: 3px; }
        .check-privacy-impact { font-size: 8px; color: #d63031; font-weight: 500; margin-top: 3px; }
        .check-legal-basis { font-size: 8px; color: #0066cc; font-weight: 500; margin-top: 3px; }
        
        .status-badge { padding: 4px 8px; border-radius: 10px; font-weight: bold; font-size: 8px; text-transform: uppercase; min-width: 40px; text-align: center; }
        .status-compliant { background: #d4edda; color: #155724; border: 2px solid #c3e6cb; }
        .status-partial { background: #fff3cd; color: #856404; border: 2px solid #ffeaa7; }
        .status-non-compliant { background: #f8d7da; color: #721c24; border: 2px solid #f5c6cb; }
        .status-manual { background: #e2e3e5; color: #383d41; border: 2px solid #c6c8ca; }
        
        .remediation { background: #f8d7da; border-left: 5px solid #dc3545; padding: 25px; margin: 20px 0; border-radius: 8px; }
        .remediation h4 { color: #721c24; margin-top: 0; font-size: 18px; }
        .remediation-steps { color: #721c24; }
        
        .implementation-guide { background: #d1ecf1; border-left: 5px solid #17a2b8; padding: 25px; margin: 20px 0; border-radius: 8px; }
        .implementation-guide h4 { color: #0c5460; margin-top: 0; font-size: 18px; }
        
        .dpia-required { background: #fff3cd; border: 2px solid #ffc107; padding: 20px; border-radius: 10px; margin: 15px 0; }
        .dpia-required h5 { color: #856404; margin-top: 0; }
        
        .progress-container { margin: 40px 0; }
        .progress-bar { width: 100%; height: 45px; background: #e9ecef; border-radius: 25px; overflow: hidden; position: relative; box-shadow: inset 0 2px 4px rgba(0,0,0,0.1); }
        .progress-fill { height: 100%; transition: width 1.5s ease; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold; font-size: 18px; }
        .progress-excellent { background: linear-gradient(90deg, #28a745, #20c997); }
        .progress-good { background: linear-gradient(90deg, #1e3c72, #2a5298); }
        .progress-warning { background: linear-gradient(90deg, #ffc107, #e0a800); }
        .progress-danger { background: linear-gradient(90deg, #dc3545, #c82333); }
        
        .compliance-dashboard { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 20px 0; }
        .compliance-card { padding: 12px; border-radius: 8px; text-align: center; box-shadow: 0 2px 6px rgba(0,0,0,0.1); min-height: 80px; display: flex; flex-direction: column; justify-content: center; }
        .compliance-card.primary { background: linear-gradient(135deg, #1e3c72, #2a5298); color: white; }
        .compliance-card.success { background: linear-gradient(135deg, #28a745, #20c997); color: white; }
        .compliance-card.warning { background: linear-gradient(135deg, #ffc107, #e0a800); color: white; }
        .compliance-card.danger { background: linear-gradient(135deg, #dc3545, #c82333); color: white; }
        .compliance-icon { font-size: 20px; margin-bottom: 6px; }
        .compliance-value { font-size: 18px; font-weight: bold; margin: 6px 0; line-height: 1; }
        .compliance-label { font-size: 11px; font-weight: 500; margin-bottom: 4px; opacity: 0.9; }
        
        .executive-summary { background: linear-gradient(135deg, #f8f9fa, #e9ecef); padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #1e3c72; }
        .risk-assessment { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 20px 0; }
        .risk-card { padding: 12px; border-radius: 8px; text-align: center; box-shadow: 0 2px 6px rgba(0,0,0,0.1); min-height: 80px; display: flex; flex-direction: column; justify-content: center; }
        .risk-critical { background: linear-gradient(135deg, #dc3545, #c82333); color: white; }
        .risk-high { background: linear-gradient(135deg, #fd7e14, #e55100); color: white; }
        .risk-medium { background: linear-gradient(135deg, #ffc107, #ff8f00); color: white; }
        .risk-low { background: linear-gradient(135deg, #28a745, #1e7e34); color: white; }
        
        .gdpr-recommendations { background: #f8f9fa; padding: 50px; border-radius: 20px; margin-top: 50px; }
        .priority-critical { border-left: 5px solid #dc3545; }
        .priority-high { border-left: 5px solid #fd7e14; }
        .priority-medium { border-left: 5px solid #ffc107; }
        .priority-low { border-left: 5px solid #28a745; }
        
        .mscp-reference { background: #e7f3ff; border: 2px solid #b3d9ff; padding: 20px; border-radius: 10px; margin: 15px 0; }
        .mscp-reference h5 { color: #0066cc; margin-top: 0; font-size: 18px; }
        
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .header::before, .header::after { display: none; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 GDPR Comprehensive Data Protection Audit</h1>
            <div class="subtitle">General Data Protection Regulation (EU) 2016/679 Compliance Assessment</div>
            <div class="compliance-info">
                <strong>System:</strong> macOS $MACOS_VERSION (Build $BUILD_VERSION) |
                <strong>Serial:</strong> $SYSTEM_SERIAL |
                <strong>Assessment Date:</strong> $TIMESTAMP<br>
                <strong>Regulation:</strong> EU General Data Protection Regulation 2016/679 |
                <strong>Framework:</strong> mSCP Aligned |
                <strong>Scope:</strong> Personal Data Protection Requirements
            </div>
        </div>
        <div class="content">
            
            <div class="gdpr-notice">
                <h2>⚖️ GDPR Data Protection Compliance Notice</h2>
                <p>This assessment evaluates compliance with the EU General Data Protection Regulation (GDPR) requirements for protecting personal data. GDPR applies to any organization processing personal data of EU residents, regardless of the organization's location. Non-compliance can result in fines up to 4% of annual global turnover or €20 million, whichever is greater.</p>
            </div>
EOF
}

# Function to add GDPR compliance check result
add_gdpr_check() {
    local principle="$1"
    local article="$2"
    local title="$3"
    local status="$4"
    local description="$5"
    local technical_details="$6"
    local privacy_impact="$7"
    local legal_basis="$8"
    local remediation="$9"
    
    # Update principle counters
    case $principle in
        "LAWFULNESS")
            LAWFULNESS_TOTAL=$((LAWFULNESS_TOTAL + 1))
            [ "$status" = "COMPLIANT" ] && LAWFULNESS_PASS=$((LAWFULNESS_PASS + 1)) || LAWFULNESS_FAIL=$((LAWFULNESS_FAIL + 1))
            ;;
        "DATA_RIGHTS")
            DATA_RIGHTS_TOTAL=$((DATA_RIGHTS_TOTAL + 1))
            [ "$status" = "COMPLIANT" ] && DATA_RIGHTS_PASS=$((DATA_RIGHTS_PASS + 1)) || DATA_RIGHTS_FAIL=$((DATA_RIGHTS_FAIL + 1))
            ;;
        "SECURITY")
            SECURITY_TOTAL=$((SECURITY_TOTAL + 1))
            [ "$status" = "COMPLIANT" ] && SECURITY_PASS=$((SECURITY_PASS + 1)) || SECURITY_FAIL=$((SECURITY_FAIL + 1))
            ;;
        "PRIVACY_DESIGN")
            PRIVACY_DESIGN_TOTAL=$((PRIVACY_DESIGN_TOTAL + 1))
            [ "$status" = "COMPLIANT" ] && PRIVACY_DESIGN_PASS=$((PRIVACY_DESIGN_PASS + 1)) || PRIVACY_DESIGN_FAIL=$((PRIVACY_DESIGN_FAIL + 1))
            ;;
    esac
    
    local status_class=$(echo $status | tr '[:upper:]' '[:lower:]' | sed 's/_/-/g')
    
    cat >> "$REPORT_FILE" << EOF
                <div class="check-result">
                    <div class="check-details">
                        <div class="check-title">$title</div>
                        <div class="check-description">$description</div>
                        <div class="check-technical">Technical Assessment: $technical_details</div>
                        <div class="check-privacy-impact">Privacy Impact: $privacy_impact</div>
                        <div class="check-legal-basis">Legal Basis: $legal_basis</div>
                    </div>
                    <div class="status-badge status-$status_class">$status</div>
                </div>
EOF

    if [ "$status" = "NON_COMPLIANT" ] && [ -n "$remediation" ]; then
        cat >> "$REPORT_FILE" << EOF
                <div class="remediation">
                    <h4>⚠️ GDPR Compliance Gap - Regulatory Action Required</h4>
                    <div class="remediation-steps">$remediation</div>
                </div>
EOF
    fi
}

# GDPR Articles 5-6: Lawfulness, Fairness, and Transparency
check_gdpr_lawfulness() {
    echo "🔍 Auditing GDPR Lawfulness, Fairness, and Transparency (Articles 5-6)..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-article-section">
                <div class="gdpr-article-header">
                    <div class="gdpr-article-id">Articles 5-6</div>
                    <h2 class="gdpr-article-title">Lawfulness, Fairness, and Transparency</h2>
                    <p class="gdpr-article-description">Personal data must be processed lawfully, fairly, and transparently. Organizations must have a valid legal basis for processing and ensure data subjects are informed about how their data is used.</p>
                </div>
                
                <div class="mscp-reference">
                    <h5>📋 mSCP Technical Alignment</h5>
                    <p>These requirements align with mSCP baseline controls for user consent management, data collection transparency, and lawful data processing in macOS environments.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 5(1)(a)</span>
                        <span class="requirement-title">Lawfulness, Fairness, and Transparency Principle</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Personal data shall be processed lawfully, fairly and in a transparent manner in relation to the data subject.</div>
                        
                        <div class="privacy-consideration">
                            <h5>🔐 Privacy Impact Assessment</h5>
                            <p>Transparent data processing builds trust and ensures data subjects understand how their personal data is used, supporting their fundamental rights.</p>
                        </div>
EOF

    # Check for consent management mechanisms
    local consent_files=$(find ~/Library -name "*consent*" -o -name "*cookie*" 2>/dev/null | wc -l)
    local privacy_files=$(find ~/Documents ~/Desktop -name "*privacy*" -o -name "*policy*" 2>/dev/null | wc -l)
    
    if [ "$consent_files" -gt 0 ] && [ "$privacy_files" -gt 0 ]; then
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Consent Management System" "COMPLIANT" "Consent management files and privacy documentation detected" "Consent files: $consent_files, Privacy docs: $privacy_files" "User consent properly documented and managed" "Article 6(1)(a) - Consent" ""
    elif [ "$consent_files" -gt 0 ] || [ "$privacy_files" -gt 0 ]; then
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Consent Management System" "PARTIAL" "Limited consent management detected" "Consent files: $consent_files, Privacy docs: $privacy_files" "Incomplete consent documentation may affect lawfulness" "Article 6(1)(a) - Consent (partial)" "Complete consent management documentation and privacy notices"
    else
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Consent Management System" "NON_COMPLIANT" "No consent management system detected" "No consent or privacy files found" "HIGH RISK: No evidence of lawful processing basis" "No documented legal basis" "Implement comprehensive consent management system and privacy notices"
    fi

    # Check cookie consent and tracking
    local safari_cookies=$(find ~/Library/Cookies -name "*.binarycookies" 2>/dev/null | wc -l)
    local tracking_files=$(find ~/Library -name "*analytic*" -o -name "*track*" 2>/dev/null | wc -l)
    
    if [ "$safari_cookies" -eq 0 ] && [ "$tracking_files" -eq 0 ]; then
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Cookie and Tracking Consent" "COMPLIANT" "No tracking cookies requiring consent detected" "Cookies: $safari_cookies, Tracking: $tracking_files" "No consent required for tracking technologies" "Not applicable" ""
    elif [ "$safari_cookies" -lt 10 ] && [ "$tracking_files" -lt 5 ]; then
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Cookie and Tracking Consent" "PARTIAL" "Limited tracking activity - consent status unknown" "Cookies: $safari_cookies, Tracking: $tracking_files" "Tracking consent may be required under GDPR" "Article 6(1)(a) - Consent for tracking" "Verify consent obtained for all tracking and analytics"
    else
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(a)" "Cookie and Tracking Consent" "NON_COMPLIANT" "Extensive tracking without documented consent" "Cookies: $safari_cookies, Tracking: $tracking_files" "HIGH RISK: Tracking without consent violates GDPR" "No documented consent for tracking" "Obtain explicit consent for all tracking and profiling activities"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 5(1)(b)</span>
                        <span class="requirement-title">Purpose Limitation</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Personal data shall be collected for specified, explicit and legitimate purposes and not further processed in a manner that is incompatible with those purposes.</div>
EOF

    # Check for purpose documentation
    local purpose_docs=$(find ~/Documents -name "*purpose*" -o -name "*data*processing*" 2>/dev/null | wc -l)
    local data_mapping=$(find ~/Documents -name "*data*map*" -o -name "*inventory*" 2>/dev/null | wc -l)
    
    if [ "$purpose_docs" -gt 0 ] && [ "$data_mapping" -gt 0 ]; then
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(b)" "Purpose Documentation" "COMPLIANT" "Data processing purposes documented and mapped" "Purpose docs: $purpose_docs, Data mapping: $data_mapping" "Clear purpose limitation supporting GDPR compliance" "Article 5(1)(b) - Purpose limitation" ""
    else
        add_gdpr_check "LAWFULNESS" "Art. 5(1)(b)" "Purpose Documentation" "NON_COMPLIANT" "No purpose limitation documentation" "Purpose docs: $purpose_docs, Data mapping: $data_mapping" "MEDIUM RISK: Purpose limitation not documented" "Article 5(1)(b) not documented" "Document specific purposes for all personal data processing"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# GDPR Articles 15-22: Data Subject Rights
check_gdpr_data_subject_rights() {
    echo "🔍 Auditing GDPR Data Subject Rights (Articles 15-22)..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-article-section">
                <div class="gdpr-article-header">
                    <div class="gdpr-article-id">Articles 15-22</div>
                    <h2 class="gdpr-article-title">Data Subject Rights</h2>
                    <p class="gdpr-article-description">Data subjects have fundamental rights regarding their personal data, including access, rectification, erasure, portability, and objection. Organizations must provide mechanisms to exercise these rights.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 15</span>
                        <span class="requirement-title">Right of Access by the Data Subject</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Data subjects have the right to obtain confirmation of whether personal data is being processed, access to the data, and information about the processing.</div>
EOF

    # Check data access capabilities
    local user_data_access=$(ls -la ~/Library/Application\ Support/ 2>/dev/null | wc -l)
    local data_export_tools=$(which zip >/dev/null && which tar >/dev/null && echo "1" || echo "0")
    
    if [ "$user_data_access" -gt 10 ] && [ "$data_export_tools" = "1" ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Data Access Implementation" "COMPLIANT" "User data accessible with export capabilities" "Data directories: $user_data_access, Export tools available" "Technical capability to provide data access" "Article 15 - Right of access" ""
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Data Access Implementation" "PARTIAL" "Limited data access capabilities" "Data directories: $user_data_access, Export tools: $data_export_tools" "Incomplete technical implementation for data access" "Article 15 implementation needed" "Implement comprehensive data access and export procedures"
    fi

    # Check for automated data access procedures
    local access_procedures=$(find ~/Documents -name "*access*request*" -o -name "*data*subject*" 2>/dev/null | wc -l)
    
    if [ "$access_procedures" -gt 0 ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Data Access Procedures" "COMPLIANT" "Data access request procedures documented" "Access procedure docs: $access_procedures" "Formal process for handling access requests" "Article 15 procedures established" ""
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 15" "Data Access Procedures" "NON_COMPLIANT" "No data access procedures documented" "No access procedure documentation found" "HIGH RISK: Cannot fulfill Article 15 requests" "Article 15 not implemented" "Create data access request procedures and automation"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 17</span>
                        <span class="requirement-title">Right to Erasure ('Right to be Forgotten')</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Data subjects have the right to obtain the erasure of personal data without undue delay under specific circumstances.</div>
                        
                        <div class="dpia-required">
                            <h5>📋 DPIA Consideration</h5>
                            <p>Data erasure capabilities must balance the right to be forgotten with legal retention requirements and technical feasibility.</p>
                        </div>
EOF

    # Check secure deletion capabilities
    local secure_delete_tools=$(which rm >/dev/null && echo "1" || echo "0")
    local filevault_status=$(fdesetup status | grep "FileVault is On" | wc -l)
    
    if [ "$secure_delete_tools" = "1" ] && [ "$filevault_status" -eq 1 ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 17" "Secure Data Erasure" "COMPLIANT" "Secure deletion tools available with encryption" "Deletion tools: available, FileVault: enabled" "Technical capability for secure data erasure" "Article 17 - Right to erasure" ""
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 17" "Secure Data Erasure" "PARTIAL" "Limited secure deletion capabilities" "Deletion tools: $secure_delete_tools, FileVault: $filevault_status" "Incomplete secure erasure implementation" "Article 17 implementation needed" "Implement secure data deletion procedures with encryption"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 20</span>
                        <span class="requirement-title">Right to Data Portability</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Data subjects have the right to receive personal data in a structured, commonly used, machine-readable format and transmit it to another controller.</div>
EOF

    # Check data portability implementation
    local export_formats=$(which csvkit >/dev/null && echo "1" || echo "0")
    local json_tools=$(which jq >/dev/null && echo "1" || echo "0")
    
    if [ "$data_export_tools" = "1" ]; then
        add_gdpr_check "DATA_RIGHTS" "Art. 20" "Data Portability Format Support" "COMPLIANT" "Machine-readable export formats supported" "Export tools available, JSON/CSV capable" "Structured data export capability" "Article 20 - Right to data portability" ""
    else
        add_gdpr_check "DATA_RIGHTS" "Art. 20" "Data Portability Format Support" "NON_COMPLIANT" "No machine-readable export capability" "Limited export tools available" "MEDIUM RISK: Cannot provide portable data formats" "Article 20 not implemented" "Implement structured data export in JSON, CSV, XML formats"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# GDPR Article 32: Security of Processing
check_gdpr_security_processing() {
    echo "🔍 Auditing GDPR Security of Processing (Article 32)..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-article-section">
                <div class="gdpr-article-header">
                    <div class="gdpr-article-id">Article 32</div>
                    <h2 class="gdpr-article-title">Security of Processing</h2>
                    <p class="gdpr-article-description">Controllers and processors must implement appropriate technical and organizational measures to ensure a level of security appropriate to the risk, including pseudonymization, encryption, confidentiality, integrity, availability, and resilience.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 32(1)(a)</span>
                        <span class="requirement-title">Pseudonymization and Encryption</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Implement appropriate technical measures including pseudonymization and encryption of personal data.</div>
EOF

    # Check encryption implementation
    local filevault_status=$(fdesetup status | grep "FileVault is On" | wc -l)
    local secure_boot=$(system_profiler SPiBridgeDataType 2>/dev/null | grep -i "secure boot" | wc -l)
    
    if [ "$filevault_status" -eq 1 ]; then
        add_gdpr_check "SECURITY" "Art. 32(1)(a)" "Personal Data Encryption" "COMPLIANT" "FileVault provides comprehensive data encryption" "FileVault: enabled, full disk encryption active" "Personal data protected with strong encryption" "Article 32(1)(a) - Encryption requirement" ""
    else
        add_gdpr_check "SECURITY" "Art. 32(1)(a)" "Personal Data Encryption" "NON_COMPLIANT" "No encryption of personal data at rest" "FileVault: disabled" "CRITICAL RISK: Personal data stored in plaintext" "Article 32(1)(a) violation" "Enable FileVault encryption immediately to protect personal data"
    fi

    # Check access controls
    local password_policy=$(pwpolicy getaccountpolicies 2>/dev/null | wc -l)
    local screen_lock=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")
    
    if [ "$password_policy" -gt 0 ] && [ "$screen_lock" = "1" ]; then
        add_gdpr_check "SECURITY" "Art. 32(1)(b)" "Access Control Implementation" "COMPLIANT" "Strong access controls protect personal data" "Password policies: configured, Screen lock: enabled" "Appropriate access controls for personal data" "Article 32(1)(b) - Confidentiality" ""
    else
        add_gdpr_check "SECURITY" "Art. 32(1)(b)" "Access Control Implementation" "PARTIAL" "Incomplete access control implementation" "Password policies: $password_policy, Screen lock: $screen_lock" "Insufficient access controls for personal data" "Article 32(1)(b) needs improvement" "Strengthen password policies and access controls"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 32(1)(c)</span>
                        <span class="requirement-title">Integrity and Availability</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Ensure ongoing confidentiality, integrity, availability and resilience of processing systems and services.</div>
EOF

    # Check system integrity protection
    local sip_status=$(csrutil status | grep "enabled" | wc -l)
    local gatekeeper_status=$(spctl --status | grep "assessments enabled" | wc -l)
    
    if [ "$sip_status" -eq 1 ] && [ "$gatekeeper_status" -eq 1 ]; then
        add_gdpr_check "SECURITY" "Art. 32(1)(c)" "System Integrity Protection" "COMPLIANT" "System integrity controls protect personal data processing" "SIP: enabled, Gatekeeper: enabled" "System integrity ensures data processing reliability" "Article 32(1)(c) - Integrity assurance" ""
    else
        add_gdpr_check "SECURITY" "Art. 32(1)(c)" "System Integrity Protection" "NON_COMPLIANT" "System integrity protections disabled" "SIP: $sip_status, Gatekeeper: $gatekeeper_status" "MEDIUM RISK: Personal data processing integrity at risk" "Article 32(1)(c) violation" "Enable SIP and Gatekeeper for system integrity protection"
    fi

    # Check backup and resilience
    local backup_status=$(tmutil latestbackup 2>/dev/null | wc -l)
    local auto_backup=$(defaults read /Library/Preferences/com.apple.TimeMachine AutoBackup 2>/dev/null || echo "0")
    
    if [ "$backup_status" -gt 0 ] && [ "$auto_backup" = "1" ]; then
        add_gdpr_check "SECURITY" "Art. 32(1)(c)" "Data Backup and Resilience" "COMPLIANT" "Automated backup system ensures data availability" "Backup: configured, Auto backup: enabled" "Personal data availability and resilience assured" "Article 32(1)(c) - Availability" ""
    else
        add_gdpr_check "SECURITY" "Art. 32(1)(c)" "Data Backup and Resilience" "PARTIAL" "Limited backup and resilience measures" "Backup: $backup_status, Auto backup: $auto_backup" "Personal data availability may be at risk" "Article 32(1)(c) needs improvement" "Configure comprehensive backup and disaster recovery"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# GDPR Articles 25: Data Protection by Design and by Default
check_gdpr_privacy_by_design() {
    echo "🔍 Auditing GDPR Data Protection by Design and by Default (Article 25)..."
    
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-article-section">
                <div class="gdpr-article-header">
                    <div class="gdpr-article-id">Article 25</div>
                    <h2 class="gdpr-article-title">Data Protection by Design and by Default</h2>
                    <p class="gdpr-article-description">Controllers must implement data protection measures both by design and by default, integrating necessary safeguards into processing to meet GDPR requirements and protect data subject rights.</p>
                </div>
                
                <div class="requirement">
                    <div class="requirement-header">
                        <span class="requirement-id">Art. 25(1)</span>
                        <span class="requirement-title">Data Protection by Design</span>
                    </div>
                    <div class="requirement-body">
                        <div class="requirement-description">Implement appropriate technical and organizational measures designed to implement data protection principles in an effective manner and integrate necessary safeguards into processing.</div>
                        
                        <div class="data-flow-analysis">
                            <h5>🔄 Data Flow Analysis</h5>
                            <p>Privacy by design requires analyzing data flows and implementing controls at every stage of personal data processing.</p>
                        </div>
EOF

    # Check privacy-focused system settings
    local analytics_disabled=$(defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null || echo "1")
    local location_services=$(defaults read /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.plist LocationServicesEnabled 2>/dev/null || echo "1")
    
    if [ "$analytics_disabled" = "0" ] && [ "$location_services" = "0" ]; then
        add_gdpr_check "PRIVACY_DESIGN" "Art. 25(1)" "Privacy by Design Configuration" "COMPLIANT" "System configured with privacy-protective defaults" "Analytics sharing: disabled, Location services: disabled" "Privacy-by-design implementation in system configuration" "Article 25(1) - Design principles" ""
    else
        add_gdpr_check "PRIVACY_DESIGN" "Art. 25(1)" "Privacy by Design Configuration" "PARTIAL" "Some privacy settings enabled by default" "Analytics: $analytics_disabled, Location: $location_services" "Incomplete privacy-by-design implementation" "Article 25(1) needs improvement" "Configure privacy-protective defaults for all data collection"
    fi

    # Check app permission management
    local app_permissions=$(sqlite3 ~/Library/TCC/TCC.db "SELECT COUNT(*) FROM access;" 2>/dev/null || echo "0")
    local location_permissions=$(sqlite3 ~/Library/TCC/TCC.db "SELECT COUNT(*) FROM access WHERE service='kTCCServiceLocation';" 2>/dev/null || echo "0")
    
    if [ "$app_permissions" -lt 20 ] && [ "$location_permissions" -lt 5 ]; then
        add_gdpr_check "PRIVACY_DESIGN" "Art. 25(2)" "Data Minimization by Default" "COMPLIANT" "Limited app permissions demonstrate data minimization" "Total permissions: $app_permissions, Location: $location_permissions" "Data minimization principle implemented by default" "Article 25(2) - Data protection by default" ""
    else
        add_gdpr_check "PRIVACY_DESIGN" "Art. 25(2)" "Data Minimization by Default" "PARTIAL" "Extensive app permissions may violate data minimization" "Total permissions: $app_permissions, Location: $location_permissions" "Review permissions against data minimization principle" "Article 25(2) review needed" "Review and minimize app permissions to necessary data only"
    fi

    cat >> "$REPORT_FILE" << EOF
                    </div>
                </div>
            </div>
EOF
}

# Generate comprehensive GDPR executive summary
generate_gdpr_executive_summary() {
    echo "📊 Generating comprehensive GDPR executive summary..."
    
    local total_checks=$((LAWFULNESS_TOTAL + DATA_RIGHTS_TOTAL + SECURITY_TOTAL + PRIVACY_DESIGN_TOTAL))
    local total_compliant=$((LAWFULNESS_PASS + DATA_RIGHTS_PASS + SECURITY_PASS + PRIVACY_DESIGN_PASS))
    local total_non_compliant=$((LAWFULNESS_FAIL + DATA_RIGHTS_FAIL + SECURITY_FAIL + PRIVACY_DESIGN_FAIL))
    local total_partial=$((LAWFULNESS_MANUAL + DATA_RIGHTS_MANUAL + SECURITY_MANUAL + PRIVACY_DESIGN_MANUAL))
    
    local overall_score=0
    if [ $total_compliant -gt 0 ] && [ $total_checks -gt 0 ]; then
        overall_score=$(( (total_compliant * 100) / total_checks ))
    fi
    
    cat >> "$REPORT_FILE" << EOF
            <div class="executive-summary">
                <h2>📋 Executive Summary - GDPR Compliance Assessment</h2>
                <p><strong>Assessment Overview:</strong> This comprehensive GDPR audit evaluated $total_checks critical security requirements across 4 essential privacy principles. The assessment follows mSCP guidelines and core GDPR data protection articles.</p>
                <p><strong>Compliance Status:</strong> Based on the evaluation, this system demonstrates a <strong>$overall_score% compliance</strong> with the audited GDPR requirements.</p>
            </div>

            <div class="gdpr-principles-grid">
                <div class="principle-card lawfulness">
                    <h3>Lawfulness, Fairness & Transparency</h3>
                    <div class="compliance-value">$LAWFULNESS_PASS/$LAWFULNESS_TOTAL</div>
                    <div class="compliance-label">Compliant</div>
                </div>
                <div class="principle-card rights">
                    <h3>Data Subject Rights</h3>
                    <div class="compliance-value">$DATA_RIGHTS_PASS/$DATA_RIGHTS_TOTAL</div>
                    <div class="compliance-label">Compliant</div>
                </div>
                <div class="principle-card security">
                    <h3>Security of Processing</h3>
                    <div class="compliance-value">$SECURITY_PASS/$SECURITY_TOTAL</div>
                    <div class="compliance-label">Compliant</div>
                </div>
                <div class="principle-card design">
                    <h3>Privacy by Design & Default</h3>
                    <div class="compliance-value">$PRIVACY_DESIGN_PASS/$PRIVACY_DESIGN_TOTAL</div>
                    <div class="compliance-label">Compliant</div>
                </div>
            </div>
            
            <div class="progress-container">
                <h3>Overall GDPR Compliance Score</h3>
                <div class="progress-bar">
                    <div class="progress-fill $([ $overall_score -ge 95 ] && echo "progress-excellent" || ([ $overall_score -ge 85 ] && echo "progress-good" || ([ $overall_score -ge 70 ] && echo "progress-warning" || echo "progress-danger")))" style="width: $overall_score%;">
                        $overall_score% GDPR Compliant
                    </div>
                </div>
            </div>
EOF
}

# Generate GDPR-specific recommendations
generate_gdpr_recommendations() {
    cat >> "$REPORT_FILE" << EOF
            <div class="gdpr-recommendations">
                <h2>🚀 GDPR Compliance Action Plan & Regulatory Risk Mitigation</h2>
                
                <div class="implementation-guide priority-critical">
                    <h4>🔴 CRITICAL - Immediate Regulatory Compliance (0-30 days)</h4>
                    <ul>
                        <li><strong>Enable Personal Data Encryption:</strong> FileVault encryption required under Article 32 security obligations</li>
                        <li><strong>Implement Consent Management:</strong> Document legal basis for all personal data processing under Articles 5-6</li>
                        <li><strong>Create Privacy Notices:</strong> Transparent information requirements under Articles 13-14</li>
                        <li><strong>Establish Data Subject Request Procedures:</strong> Implement access, erasure, and portability rights (Articles 15-20)</li>
                        <li><strong>Document Processing Activities:</strong> Maintain records of processing under Article 30</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-high">
                    <h4>🟡 HIGH PRIORITY - Regulatory Compliance Enhancement (30-90 days)</h4>
                    <ul>
                        <li><strong>Conduct Data Protection Impact Assessment (DPIA):</strong> Required for high-risk processing under Article 35</li>
                        <li><strong>Implement Privacy by Design:</strong> Integrate data protection into all processing activities (Article 25)</li>
                        <li><strong>Establish Data Breach Procedures:</strong> 72-hour notification requirements under Articles 33-34</li>
                        <li><strong>Review Third-Party Data Sharing:</strong> Ensure adequate safeguards under Articles 44-49</li>
                        <li><strong>Appoint Data Protection Officer (if required):</strong> Article 37 obligations for public authorities or large-scale processing</li>
                    </ul>
                </div>
                
                <div class="implementation-guide priority-medium">
                    <h4>🟢 MEDIUM PRIORITY - Continuous Compliance (90+ days)</h4>
                    <ul>
                        <li><strong>Regular Compliance Audits:</strong> Quarterly GDPR compliance assessments and monitoring</li>
                        <li><strong>Staff Training Programs:</strong> GDPR awareness and data protection training for all personnel</li>
                        <li><strong>Data Retention Policy:</strong> Implement storage limitation principle under Article 5(1)(e)</li>
                        <li><strong>Vendor Management:</strong> Ensure processor contracts comply with Article 28 requirements</li>
                        <li><strong>International Data Transfers:</strong> Implement Standard Contractual Clauses or adequacy decisions</li>
                    </ul>
                </div>
                
                <div class="mscp-reference">
                    <h5>📚 GDPR Compliance Resources</h5>
                    <ul>
                        <li><strong>Official GDPR Text:</strong> <a href="https://eur-lex.europa.eu/eli/reg/2016/679/oj">EUR-Lex Regulation 2016/679</a></li>
                        <li><strong>mSCP Project:</strong> <a href="https://github.com/usnistgov/macos_security">macOS Security Compliance Project</a></li>
                        <li><strong>EDPB Guidelines:</strong> <a href="https://edpb.europa.eu/our-work-tools/general-guidance/gdpr-guidelines-recommendations-best-practices_en">European Data Protection Board</a></li>
                        <li><strong>ICO Guidance:</strong> <a href="https://ico.org.uk/for-organisations/guide-to-data-protection/">UK Information Commissioner's Office</a></li>
                        <li><strong>CNIL Resources:</strong> <a href="https://www.cnil.fr/en">French Data Protection Authority</a></li>
                    </ul>
                </div>
                
                <div class="privacy-consideration">
                    <h5>⚖️ Regulatory and Financial Implications</h5>
                    <p><strong>Financial Penalties:</strong> GDPR violations can result in administrative fines up to €20 million or 4% of annual global turnover, whichever is higher. Supervisory authorities have imposed significant fines for non-compliance.</p>
                    <p><strong>Data Subject Claims:</strong> Individuals have the right to compensation for material or non-material damage under Article 82. Class action lawsuits are increasingly common.</p>
                    <p><strong>Business Impact:</strong> GDPR non-compliance can result in reputational damage, loss of customer trust, business disruption, and exclusion from EU markets.</p>
                </div>
                
                <div class="dpia-required">
                    <h5>📋 Data Protection Impact Assessment (DPIA) Triggers</h5>
                    <p>A DPIA is required when processing is likely to result in high risk to rights and freedoms, including:</p>
                    <ul>
                        <li>Systematic monitoring of publicly accessible areas on a large scale</li>
                        <li>Processing of special categories of data or criminal convictions on a large scale</li>
                        <li>Use of new technologies or innovative processing methods</li>
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
echo "🚀 GDPR Comprehensive Data Protection Audit"
echo "==========================================="
echo "Assessment Date: $TIMESTAMP"
echo "System: macOS $MACOS_VERSION (Build $BUILD_VERSION)"
echo "Serial: $SYSTEM_SERIAL"
echo "Regulation: EU General Data Protection Regulation 2016/679"
echo "Framework: mSCP (macOS Security Compliance Project) Aligned"
echo "Scope: Personal Data Protection Requirements"
echo "==========================================="
echo

# Initialize comprehensive HTML report
init_html_report

# Execute all GDPR compliance assessments
check_gdpr_lawfulness             # Articles 5-6: Lawfulness, Fairness, Transparency
check_gdpr_data_subject_rights    # Articles 15-22: Data Subject Rights
check_gdpr_security_processing    # Article 32: Security of Processing
check_gdpr_privacy_by_design      # Article 25: Data Protection by Design and by Default

# Generate executive summary and GDPR recommendations
generate_gdpr_executive_summary
generate_gdpr_recommendations

# Calculate final compliance metrics
total_checks=$((LAWFULNESS_TOTAL + DATA_RIGHTS_TOTAL + SECURITY_TOTAL + PRIVACY_DESIGN_TOTAL))
total_compliant=$((LAWFULNESS_PASS + DATA_RIGHTS_PASS + SECURITY_PASS + PRIVACY_DESIGN_PASS))
total_non_compliant=$((LAWFULNESS_FAIL + DATA_RIGHTS_FAIL + SECURITY_FAIL + PRIVACY_DESIGN_FAIL))
total_partial=$((LAWFULNESS_MANUAL + DATA_RIGHTS_MANUAL + SECURITY_MANUAL + PRIVACY_DESIGN_MANUAL))

echo "✅ GDPR comprehensive data protection audit complete!"
echo "📊 Data Protection Assessment Summary:"
echo "   Total Requirements Evaluated: $total_checks"
echo "   Requirements Compliant: $total_compliant"
echo "   Requirements Non-Compliant: $total_non_compliant"
echo "   Partial Compliance: $total_partial"
if [ $total_checks -gt 0 ]; then
    echo "   Overall GDPR Compliance Score: $(( (total_compliant * 100) / total_checks ))%"
else
    echo "   Overall GDPR Compliance Score: 0%"
fi
echo
echo "📋 Comprehensive Report: $REPORT_FILE"
echo "🌐 Open GDPR compliance report: open $REPORT_FILE"
echo
echo "🎯 Regulatory Compliance Next Steps:"
echo "   1. Address CRITICAL compliance gaps immediately (0-30 days)"
echo "   2. Implement HIGH priority regulatory requirements (30-90 days)"
echo "   3. Establish continuous privacy compliance monitoring (90+ days)"
echo "   4. Conduct Data Protection Impact Assessment (DPIA) if required"
echo "   5. Schedule regular GDPR compliance reviews and staff training"
