import Foundation
import Combine

enum BenchmarkType: String, CaseIterable, Identifiable {
    case gdpr = "GDPR Compliance Benchmark"
    case nist = "NIST Compliance Benchmark"
    case cis = "CIS Compliance Benchmark"

    var id: String { self.rawValue }

    var scriptName: String {
        switch self {
        case .gdpr:
            return "gdpr_audit_script.sh"
        case .nist:
            return "nist_audit_script.sh"
        case .cis:
            return "cis_compliance_script.sh"
        }
    }
}

class BenchmarkService: ObservableObject {
    @Published var benchmarkReports: [BenchmarkType: String] = [:]
    @Published var isRunningBenchmark: [BenchmarkType: Bool] = [:]

    private var cancellables = Set<AnyCancellable>()
    var onCISScriptComplete: (() -> Void)?
    
    private func readHTMLReport(from htmlPath: String) -> String {
        do {
            let htmlContent = try String(contentsOfFile: htmlPath, encoding: .utf8)
            return htmlContent
        } catch {
            print("❌ Error reading HTML report: \(error)")
            return "Error reading HTML report: \(error.localizedDescription)"
        }
    }
    
    private func generateCISReport(from plistPath: String) -> String {
        let process = Process()
        process.launchPath = "/usr/bin/defaults"
        process.arguments = ["read", plistPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return "Error: Could not read CIS audit data"
            }
            
            return self.parseCISOutput(output)
        } catch {
            return "Error running CIS audit: \(error.localizedDescription)"
        }
    }
    
    private func parseCISOutput(_ output: String) -> String {
        var report = "CIS Level 1 Compliance Report\n"
        report += "=============================\n\n"
        
        let lines = output.components(separatedBy: .newlines)
        var compliantCount = 0
        var nonCompliantCount = 0
        var exemptCount = 0
        var totalCount = 0
        
        var findings: [(String, String, String)] = []
        
        for line in lines {
            if line.contains("=") && line.contains("audit_") {
                let components = line.components(separatedBy: "=")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let ruleName = self.getRuleName(from: key)
                    let status = self.getStatus(from: value)
                    
                    findings.append((ruleName, status, value))
                    totalCount += 1
                    
                    if status == "✅ Compliant" {
                        compliantCount += 1
                    } else if status == "❌ Non-Compliant" {
                        nonCompliantCount += 1
                    } else if status == "⚠️ Exempt" {
                        exemptCount += 1
                    }
                }
            }
        }
        
        let compliancePercentage = totalCount > 0 ? Int((Double(compliantCount) / Double(totalCount)) * 100) : 0
        
        report += "Summary: \(compliantCount)/\(totalCount) rules compliant (\(compliancePercentage)%)\n"
        report += "Compliant: \(compliantCount)\n"
        report += "Non-Compliant: \(nonCompliantCount)\n"
        report += "Exempt: \(exemptCount)\n\n"
        
        report += "Detailed Findings:\n"
        report += "==================\n"
        
        for (ruleName, status, value) in findings {
            report += "\(status) \(ruleName) (\(value))\n"
        }
        
        return report
    }
    
    private func getRuleName(from key: String) -> String {
        let ruleNames: [String: String] = [
            "audit_os_sip_enable": "SIP Enable",
            "audit_os_filevault_enable": "FileVault Enable", 
            "audit_os_gatekeeper_enable": "Gatekeeper Enable",
            "audit_os_firewall_enable": "Firewall Enable",
            "audit_os_airdrop_disable": "AirDrop Disable",
            "audit_os_handoff_disable": "Handoff Disable",
            "audit_os_automatic_login_disable": "Automatic Login Disable",
            "audit_os_password_policy_enable": "Password Policy Enable",
            "audit_os_screensaver_lock_enable": "Screensaver Lock Enable",
            "audit_os_remote_login_disable": "Remote Login Disable",
            "audit_os_bluetooth_disable": "Bluetooth Disable",
            "audit_os_antivirus_installed": "Anti-Virus Installed",
            "audit_os_acls_files_configure": "ACLs Files Configure"
        ]
        
        return ruleNames[key] ?? key.replacingOccurrences(of: "audit_os_", with: "").replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    private func getStatus(from value: String) -> String {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanValue == "1" || cleanValue == "1;" || cleanValue.hasPrefix("1") {
            return "✅ Compliant"
        } else if cleanValue == "exempt" {
            return "⚠️ Exempt"
        } else {
            return "❌ Non-Compliant"
        }
    }

    func runBenchmark(_ benchmark: BenchmarkType) {
        print("🔍 Starting benchmark: \(benchmark.rawValue)")
        guard let scriptURL = Bundle.main.url(forResource: benchmark.scriptName.replacingOccurrences(of: ".sh", with: ""), withExtension: "sh") else {
            print("❌ Script not found: \(benchmark.scriptName)")
            DispatchQueue.main.async {
                self.benchmarkReports[benchmark] = "Error: Script not found for \(benchmark.rawValue). Looking for: \(benchmark.scriptName)"
            }
            return
        }
        
        let scriptPath = scriptURL.path
        print("✅ Script found at: \(scriptPath)")

        let tempDir = FileManager.default.temporaryDirectory
        let reportURL = tempDir.appendingPathComponent("\(benchmark.scriptName)_report.html")
        let reportPath = reportURL.path

        DispatchQueue.main.async {
            self.isRunningBenchmark[benchmark] = true
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.launchPath = "/bin/sh"
            
            // For CIS script, use 'scan' argument and set working directory
            if benchmark == .cis {
                process.arguments = [scriptPath, "scan"]
                process.currentDirectoryPath = scriptURL.deletingLastPathComponent().path
            } else {
                process.arguments = [scriptPath, reportPath]
            }
            
            print("🚀 Executing script: \(scriptPath) with arguments: \(process.arguments ?? [])")
            if benchmark == .cis {
                print("📁 Working directory: \(process.currentDirectoryPath)")
            }
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.launch()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                self.isRunningBenchmark[benchmark] = false
                if process.terminationStatus == 0 {
                    print("✅ Script completed successfully with exit code: \(process.terminationStatus)")
                    
                    // For all scripts, read the generated HTML report from the script's working directory
                    let scriptDir = scriptURL.deletingLastPathComponent().path
                    var htmlReportPath: String
                    
                    switch benchmark {
                    case .cis:
                        htmlReportPath = "\(scriptDir)/audit_reports/cis_level1_comprehensive_report.html"
                    case .nist:
                        htmlReportPath = "\(scriptDir)/nist_800_171_comprehensive_report.html"
                    case .gdpr:
                        htmlReportPath = "\(scriptDir)/gdpr_comprehensive_report.html"
                    }
                    
                    let reportContent = self.readHTMLReport(from: htmlReportPath)
                    self.benchmarkReports[benchmark] = reportContent
                    print("📊 \(benchmark.rawValue) audit completed - HTML report loaded from: \(htmlReportPath)")
                    
                    // Notify CISComplianceService to refresh its data for CIS
                    if benchmark == .cis {
                        self.onCISScriptComplete?()
                    }
                } else {
                    print("❌ Script failed with exit code: \(process.terminationStatus)")
                    print("📄 Script output: \(output ?? "No output")")
                    self.benchmarkReports[benchmark] = "Error running script for \(benchmark.rawValue). Exit code: \(process.terminationStatus)\nOutput:\n\(output ?? "")"
                }
            }
        }
    }
    
    private func readReport(for benchmark: BenchmarkType) {
        let fileManager = FileManager.default
        let reportFileName = benchmark.scriptName.replacingOccurrences(of: "script", with: "report").replacingOccurrences(of: ".sh", with: ".html")
        
        // The scripts write to the current working directory.
        // We need to figure out where that is when run from the app.
        // For now, let's assume it's the user's home directory for testing.
        // A better approach would be to have the script output to stdout.
        let reportPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(reportFileName).path

        do {
            let reportContent = try String(contentsOfFile: reportPath, encoding: .utf8)
            DispatchQueue.main.async {
                self.benchmarkReports[benchmark] = reportContent
            }
        } catch {
            print("Error reading report file \(reportFileName): \(error)")
            DispatchQueue.main.async {
                self.benchmarkReports[benchmark] = "<html><body><h1>Error</h1><p>Could not load report: \(error.localizedDescription)</p></body></html>"
            }
        }
    }
}
