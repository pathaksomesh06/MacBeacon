import SwiftUI
import Foundation

// MARK: - Application Security Check
struct ApplicationSecurityCheck: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: ApplicationSecurityStatus = .unknown
    var detail: String = ""
    var severity: ApplicationSecuritySeverity = .low

    enum ApplicationSecurityStatus {
        case unknown
        case checking
        case secure
        case warning
        case critical
        case info
    }
    
    enum ApplicationSecuritySeverity {
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

// MARK: - Application Security Checker
class ApplicationSecurityChecker: ObservableObject {
    @Published var applicationChecks: [ApplicationSecurityCheck] = []
    
    init() {
        setupApplicationChecks()
    }
    
    private func setupApplicationChecks() {
        applicationChecks = [
            ApplicationSecurityCheck(
                name: "Non-Notarized Apps",
                command: "system_profiler SPApplicationsDataType 2>/dev/null | grep -c 'Notarized: No' || echo '0'",
                severity: .high
            ),
            ApplicationSecurityCheck(
                name: "Login Items",
                command: "osascript -e 'tell application \"System Events\" to get the name of every login item' 2>/dev/null | wc -w || echo '0'",
                severity: .medium
            ),
            ApplicationSecurityCheck(
                name: "Non-Universal Apps",
                command: "system_profiler SPApplicationsDataType 2>/dev/null | grep -c 'Kind: Intel' || echo '0'",
                severity: .medium
            ),
            ApplicationSecurityCheck(
                name: "Unsigned Apps",
                command: "system_profiler SPApplicationsDataType 2>/dev/null | grep -c 'Signed by: (null)' || echo '0'",
                severity: .critical
            )
        ]
    }
    
    func checkAllApplicationChecks() {
        print("ApplicationSecurityChecker: Starting checkAllApplicationChecks")
        for (index, _) in applicationChecks.enumerated() {
            checkApplicationCheck(at: index)
        }
    }
    
    private func checkApplicationCheck(at index: Int) {
        print("ApplicationSecurityChecker: Checking application check \(index): \(applicationChecks[index].name)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runCommand(self.applicationChecks[index].command)
            
            DispatchQueue.main.async {
                self.processApplicationResult(for: index, result: result, checkName: self.applicationChecks[index].name)
            }
        }
    }
    
    private func runCommand(_ command: String) -> String {
        print("ApplicationSecurityChecker: Running command: \(command)")
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
            
            print("ApplicationSecurityChecker: Command '\(command)' returned: \(result)")
            print("ApplicationSecurityChecker: Exit code: \(process.terminationStatus)")
            
            return result
        } catch {
            print("ApplicationSecurityChecker: Error running command: \(error)")
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func processApplicationResult(for index: Int, result: String, checkName: String) {
        print("ApplicationSecurityChecker: Processing \(checkName): \(result)")
        
        var status: ApplicationSecurityCheck.ApplicationSecurityStatus
        var detail: String
        
        let count = Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        
        switch checkName {
        case "Non-Notarized Apps":
            if count == 0 {
                status = .secure
                detail = "All applications are notarized"
            } else if count <= 5 {
                status = .warning
                detail = "\(count) non-notarized applications found"
            } else {
                status = .critical
                detail = "\(count) non-notarized applications found - security risk"
            }
            
        case "Login Items":
            if count == 0 {
                status = .secure
                detail = "No login items configured"
            } else if count <= 3 {
                status = .info
                detail = "\(count) login items configured"
            } else {
                status = .warning
                detail = "\(count) login items configured - review for security"
            }
            
        case "Non-Universal Apps":
            if count == 0 {
                status = .secure
                detail = "All applications are universal (Apple Silicon compatible)"
            } else if count <= 10 {
                status = .warning
                detail = "\(count) Intel-only applications found"
            } else {
                status = .critical
                detail = "\(count) Intel-only applications found - performance impact"
            }
            
        case "Unsigned Apps":
            if count == 0 {
                status = .secure
                detail = "All applications are properly signed"
            } else if count <= 3 {
                status = .warning
                detail = "\(count) unsigned applications found"
            } else {
                status = .critical
                detail = "\(count) unsigned applications found - security risk"
            }
            
        default:
            status = .info
            detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        applicationChecks[index].status = status
        applicationChecks[index].detail = detail
    }
}

// MARK: - Application Security Check View
struct ApplicationSecurityCheckView: View {
    let check: ApplicationSecurityCheck
    
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
