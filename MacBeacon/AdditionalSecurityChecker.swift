import SwiftUI
import Foundation

// MARK: - Additional Security Check
struct AdditionalSecurityCheck: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: SecurityCheckStatus = .unknown
    var detail: String = ""
    var severity: SecuritySeverity = .low

    enum SecurityCheckStatus {
        case unknown
        case checking
        case secure
        case warning
        case critical
        case info
    }
    
    enum SecuritySeverity {
        case low
        case medium
        case high
        case critical
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var name: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
}

// MARK: - Additional Security Checker
class AdditionalSecurityChecker: ObservableObject {
    @Published var securityChecks: [AdditionalSecurityCheck] = []
    
    init() {
        setupSecurityChecks()
    }
    
    private func setupSecurityChecks() {
        securityChecks = [
            AdditionalSecurityCheck(
                name: "Current User Account Type",
                command: "groups | grep -w admin",
                severity: .medium
            ),
            AdditionalSecurityCheck(
                name: "Bootstrap Token Status",
                command: "profiles status -type bootstraptoken",
                severity: .high
            ),
            AdditionalSecurityCheck(
                name: "FileVault Status",
                command: "fdesetup status",
                severity: .high
            ),
            AdditionalSecurityCheck(
                name: "Firewall Status",
                command: "defaults read /Library/Preferences/com.apple.alf globalstate",
                severity: .medium
            ),
            AdditionalSecurityCheck(
                name: "Gatekeeper Administrator Override",
                command: "defaults read com.apple.systempolicy.managed DisableOverride 2>/dev/null || echo 'Not managed'",
                severity: .medium
            ),
            AdditionalSecurityCheck(
                name: "Gatekeeper Status",
                command: "defaults read com.apple.systempolicy.control EnableAssessment 2>/dev/null || echo 'Not managed'",
                severity: .medium
            ),
            AdditionalSecurityCheck(
                name: "Guest User Status",
                command: "defaults read com.apple.MCX DisableGuestAccount 2>/dev/null || echo 'Not managed'",
                severity: .low
            ),
            AdditionalSecurityCheck(
                name: "Root User Status",
                command: "dscl . -read /Users/root AuthenticationAuthority 2>/dev/null | grep -q 'No such key' && echo 'Disabled' || echo 'Enabled'",
                severity: .high
            ),
            AdditionalSecurityCheck(
                name: "Secure Token Status",
                command: "dscl . -read /Users/$(whoami) GeneratedUID 2>/dev/null | awk '{print $2}' | xargs -I {} dscl . -read /Users/$(whoami) AuthenticationAuthority 2>/dev/null | grep -q 'SecureToken' && echo 'Has Secure Token' || echo 'No Secure Token'",
                severity: .high
            ),
            AdditionalSecurityCheck(
                name: "System Integrity Protection Status",
                command: "csrutil status",
                severity: .critical
            )
        ]
    }
    
    func checkAllSecurityChecks() {
        print("AdditionalSecurityChecker: Starting checkAllSecurityChecks")
        for (index, _) in securityChecks.enumerated() {
            checkSecurityCheck(at: index)
        }
    }
    
    private func checkSecurityCheck(at index: Int) {
        print("AdditionalSecurityChecker: Checking security check \(index): \(securityChecks[index].name)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runCommand(self.securityChecks[index].command)
            
            DispatchQueue.main.async {
                self.processSecurityResult(for: index, result: result, checkName: self.securityChecks[index].name)
            }
        }
    }
    
    private func runCommand(_ command: String) -> String {
        print("AdditionalSecurityChecker: Running command: \(command)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let result = String(data: data, encoding: .utf8) ?? ""
            
            print("AdditionalSecurityChecker: Command '\(command)' returned: \(result)")
            print("AdditionalSecurityChecker: Exit code: \(process.terminationStatus)")
            
            return result
        } catch {
            print("AdditionalSecurityChecker: Error running command: \(error)")
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func processSecurityResult(for index: Int, result: String, checkName: String) {
        print("AdditionalSecurityChecker: Processing \(checkName): \(result)")
        
        var status: AdditionalSecurityCheck.SecurityCheckStatus
        var detail: String
        
        switch checkName {
        case "Current User Account Type":
            if result.contains("admin") {
                status = .warning
                detail = "User is in admin group - elevated privileges"
            } else {
                status = .secure
                detail = "User has standard privileges"
            }
            
        case "Bootstrap Token Status":
            if result.contains("enabled") || result.contains("present") {
                status = .secure
                detail = "Bootstrap token is enabled"
            } else if result.contains("not present") || result.contains("disabled") {
                status = .warning
                detail = "Bootstrap token is not present"
            } else {
                status = .info
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        case "FileVault Status":
            if result.contains("FileVault is On") {
                status = .secure
                detail = "FileVault encryption is enabled"
            } else if result.contains("FileVault is Off") {
                status = .critical
                detail = "FileVault encryption is disabled"
            } else {
                status = .info
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        case "Firewall Status":
            if result.contains("1") {
                status = .secure
                detail = "Firewall is enabled"
            } else if result.contains("0") {
                status = .warning
                detail = "Firewall is disabled"
            } else {
                status = .info
                detail = "Firewall status: \(result.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            
        case "Gatekeeper Administrator Override":
            if result.contains("Not managed") {
                status = .info
                detail = "Gatekeeper override not managed by MDM"
            } else if result.contains("1") {
                status = .warning
                detail = "Gatekeeper override is disabled"
            } else {
                status = .secure
                detail = "Gatekeeper override is enabled"
            }
            
        case "Gatekeeper Status":
            if result.contains("Not managed") {
                status = .info
                detail = "Gatekeeper not managed by MDM"
            } else if result.contains("1") {
                status = .secure
                detail = "Gatekeeper assessment is enabled"
            } else {
                status = .warning
                detail = "Gatekeeper assessment is disabled"
            }
            
        case "Guest User Status":
            if result.contains("Not managed") {
                status = .info
                detail = "Guest user not managed by MDM"
            } else if result.contains("1") {
                status = .secure
                detail = "Guest user is disabled"
            } else {
                status = .warning
                detail = "Guest user is enabled"
            }
            
        case "Root User Status":
            if result.contains("Disabled") {
                status = .secure
                detail = "Root user is disabled"
            } else if result.contains("Enabled") {
                status = .critical
                detail = "Root user is enabled"
            } else {
                status = .info
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        case "Secure Token Status":
            if result.contains("Has Secure Token") {
                status = .secure
                detail = "User has secure token"
            } else if result.contains("No Secure Token") {
                status = .warning
                detail = "User does not have secure token"
            } else {
                status = .info
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        case "System Integrity Protection Status":
            if result.contains("enabled") {
                status = .secure
                detail = "System Integrity Protection is enabled"
            } else if result.contains("disabled") {
                status = .critical
                detail = "System Integrity Protection is disabled"
            } else {
                status = .info
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
        default:
            status = .info
            detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        securityChecks[index].status = status
        securityChecks[index].detail = detail
    }
}

// MARK: - Additional Security Check View
struct AdditionalSecurityCheckView: View {
    let check: AdditionalSecurityCheck
    
    var body: some View {
        HStack(spacing: 8) {
            switch check.status {
            case .unknown:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            case .checking:
                ProgressView()
                    .frame(width: 20, height: 20)
                    .scaleEffect(0.8)
            case .secure:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            case .critical:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            case .info:
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(check.name)
                    .font(.system(size: 13, weight: .medium))
                
                if !check.detail.isEmpty {
                    Text(check.detail)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            Text(check.severity.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(check.severity.color.opacity(0.15))
                .foregroundColor(check.severity.color)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}
