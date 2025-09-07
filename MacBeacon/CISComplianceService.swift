import Foundation
import SwiftUI

// MARK: - CIS Compliance Data Models

struct CISComplianceResult: Codable {
    let auditDate: String
    let auditVersion: String
    let compliant: Int
    let nonCompliant: Int
    let exempt: Int
    let totalRules: Int
    let compliancePercentage: Double
    let findings: [CISFinding]
}

struct CISFinding: Codable, Identifiable {
    let id = UUID()
    let ruleName: String
    let compliant: Bool
    let exempt: Bool
    let description: String
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case ruleName, compliant, exempt, description, category
    }
}

// MARK: - CIS Compliance Service

class CISComplianceService: ObservableObject {
    @Published var complianceResult: CISComplianceResult?
    @Published var isLoading = false
    @Published var lastScanDate: Date?
    @Published var errorMessage: String?
    
    private let scriptPath = "cis_compliance_script.sh"
    private let auditPlistPath = "\(NSHomeDirectory())/Library/Preferences/org.cis_lvl1.audit.plist"
    private let auditLogPath = "\(NSHomeDirectory())/Library/Logs/cis_lvl1_baseline.log"
    
    init() {
        loadLastScanDate()
    }
    
    // MARK: - Public Methods
    
    func runCISAudit() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let result = self.executeCISScript()
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let result = result {
                    self.complianceResult = result
                    self.lastScanDate = Date()
                    self.saveLastScanDate()
                } else {
                    self.errorMessage = "Failed to run CIS audit"
                }
            }
        }
    }
    
    func refreshFromPlist() {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let result = self.parseCISResults()
            
            DispatchQueue.main.async {
                self.isLoading = false
                if let result = result {
                    self.complianceResult = result
                    self.lastScanDate = Date()
                    self.saveLastScanDate()
                } else {
                    self.errorMessage = "Failed to parse CIS audit data"
                }
            }
        }
    }
    
    func getComplianceSummary() -> String {
        guard let result = complianceResult else {
            return "No CIS audit data available"
        }
        
        return "\(result.compliant)/\(result.totalRules) rules compliant (\(Int(result.compliancePercentage))%)"
    }
    
    func getComplianceStatus() -> String {
        guard let result = complianceResult else {
            return "Unknown"
        }
        
        if result.compliancePercentage >= 90 {
            return "Excellent"
        } else if result.compliancePercentage >= 75 {
            return "Good"
        } else if result.compliancePercentage >= 50 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    func getComplianceColor() -> Color {
        guard let result = complianceResult else {
            return .gray
        }
        
        if result.compliancePercentage >= 90 {
            return .green
        } else if result.compliancePercentage >= 75 {
            return .yellow
        } else if result.compliancePercentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    // MARK: - Private Methods
    
    private func executeCISScript() -> CISComplianceResult? {
        // First, ensure the script is executable
        let scriptURL = Bundle.main.url(forResource: "cis_compliance_script", withExtension: "sh")
        guard let scriptURL = scriptURL else {
            print("CIS script not found in bundle")
            return nil
        }
        
        // Copy script to temporary location and make executable
        let tempScriptPath = "/tmp/cis_compliance_script.sh"
        do {
            let scriptContent = try String(contentsOf: scriptURL, encoding: .utf8)
            try scriptContent.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
            
            // Make script executable
            let chmodProcess = Process()
            chmodProcess.launchPath = "/bin/chmod"
            chmodProcess.arguments = ["+x", tempScriptPath]
            chmodProcess.launch()
            chmodProcess.waitUntilExit()
            
        } catch {
            print("Failed to copy CIS script: \(error)")
            return nil
        }
        
        // Execute the CIS script
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = [tempScriptPath, "scan"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        process.waitUntilExit()
        
        // Clean up temporary script
        try? FileManager.default.removeItem(atPath: tempScriptPath)
        
        // Parse the results from the plist file
        return parseCISResults()
    }
    
    private func parseCISResults() -> CISComplianceResult? {
        // Read the audit plist file
        let process = Process()
        process.launchPath = "/usr/bin/defaults"
        process.arguments = ["read", auditPlistPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Parse the plist output
        return parsePlistOutput(output)
    }
    
    private func parsePlistOutput(_ output: String) -> CISComplianceResult? {
        var auditDate = ""
        var auditVersion = ""
        var findings: [CISFinding] = []
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Parse audit date
            if trimmedLine.contains("audit_date") {
                if let range = trimmedLine.range(of: "= \"") {
                    let startIndex = range.upperBound
                    if let endRange = trimmedLine.range(of: "\";", range: startIndex..<trimmedLine.endIndex) {
                        auditDate = String(trimmedLine[startIndex..<endRange.lowerBound])
                    }
                }
            }
            
            // Parse audit version
            if trimmedLine.contains("audit_version") {
                if let range = trimmedLine.range(of: "= \"") {
                    let startIndex = range.upperBound
                    if let endRange = trimmedLine.range(of: "\";", range: startIndex..<trimmedLine.endIndex) {
                        auditVersion = String(trimmedLine[startIndex..<endRange.lowerBound])
                    }
                }
            }
            
            // Parse findings
            if trimmedLine.contains("audit_") && trimmedLine.contains("= ") {
                let components = trimmedLine.components(separatedBy: " = ")
                if components.count == 2 {
                    let ruleName = components[0].trimmingCharacters(in: .whitespaces)
                    let value = components[1].trimmingCharacters(in: .whitespaces)
                    
                    let compliant = value == "1" || value == "true" || value == "1;" || value.hasPrefix("1")
                    let exempt = value == "exempt"
                    
                    let finding = CISFinding(
                        ruleName: ruleName,
                        compliant: compliant,
                        exempt: exempt,
                        description: getRuleDescription(ruleName),
                        category: getRuleCategory(ruleName)
                    )
                    findings.append(finding)
                }
            }
        }
        
        // Calculate compliance metrics
        let compliantCount = findings.filter { $0.compliant && !$0.exempt }.count
        let nonCompliantCount = findings.filter { !$0.compliant && !$0.exempt }.count
        let exemptCount = findings.filter { $0.exempt }.count
        let totalRules = findings.count
        let compliancePercentage = totalRules > 0 ? Double(compliantCount) / Double(totalRules) * 100 : 0
        
        return CISComplianceResult(
            auditDate: auditDate,
            auditVersion: auditVersion,
            compliant: compliantCount,
            nonCompliant: nonCompliantCount,
            exempt: exemptCount,
            totalRules: totalRules,
            compliancePercentage: compliancePercentage,
            findings: findings
        )
    }
    
    private func getRuleDescription(_ ruleName: String) -> String {
        let descriptions: [String: String] = [
            "audit_acls_files_configure": "ACLs are properly configured on system files",
            "audit_os_airdrop_disable": "AirDrop is disabled to prevent unauthorized file sharing",
            "audit_os_anti_virus_installed": "Antivirus software is installed and running",
            "audit_os_sip_enable": "System Integrity Protection (SIP) is enabled",
            "audit_pwpolicy_minimum_length_enforce": "Password policy enforces minimum length requirements",
            "audit_system_settings_firewall_enable": "Firewall is enabled to protect against network threats",
            "audit_system_settings_gatekeeper_enable": "Gatekeeper is enabled to verify application signatures",
            "audit_system_settings_automatic_updates_enable": "Automatic updates are enabled for security patches",
            "audit_system_settings_filevault_enable": "FileVault disk encryption is enabled",
            "audit_system_settings_screensaver_lock_enable": "Screensaver lock is enabled for security"
        ]
        
        return descriptions[ruleName] ?? "CIS Level 1 compliance rule"
    }
    
    private func getRuleCategory(_ ruleName: String) -> String {
        if ruleName.contains("audit_os_") {
            return "Operating System"
        } else if ruleName.contains("audit_system_settings_") {
            return "System Settings"
        } else if ruleName.contains("audit_pwpolicy_") {
            return "Password Policy"
        } else if ruleName.contains("audit_acls_") {
            return "Access Control"
        } else {
            return "Security"
        }
    }
    
    // MARK: - UserDefaults Persistence
    
    private func saveLastScanDate() {
        UserDefaults.standard.set(lastScanDate, forKey: "CISLastScanDate")
    }
    
    private func loadLastScanDate() {
        lastScanDate = UserDefaults.standard.object(forKey: "CISLastScanDate") as? Date
    }
}

// MARK: - CIS Compliance View Components

struct CISComplianceCard: View {
    @ObservedObject var cisService: CISComplianceService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield")
                    .foregroundColor(cisService.getComplianceColor())
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CIS Compliance")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(cisService.getComplianceSummary())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(cisService.getComplianceStatus())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(cisService.getComplianceColor())
                    
                    if let lastScan = cisService.lastScanDate {
                        Text("Last scan: \(lastScan, formatter: RelativeDateTimeFormatter())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if cisService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Running CIS audit...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = cisService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
