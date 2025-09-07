import Foundation
import SwiftUI
import Darwin

struct SystemHealthData {
    let sipStatus: String
    let secureBootStatus: String
    let fileVaultStatus: String
    let gatekeeperStatus: String
    let firewallStatus: String
    let autoUpdateStatus: String
    let realTimeProtectionEnabled: Bool
    let mdeInstalled: Bool
    let riskScore: Int
    let riskLevel: String
    let lastUpdated: Date
    
    // Computer Information
    let hostname: String
    let macModel: String
    let osVersion: String
    let touchIDStatus: String
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let systemUptime: String
    let securityRiskScore: Int
    let criticalIssues: Int
    let majorIssues: Int
    let minorIssues: Int
    let isHealthy: Bool
    
    // Additional System Information
    let osBuild: String
    let architecture: String
    let localAdminStatus: String
    let sudoAccess: String
    let tccDangerousPermissions: Int
    let quarantineBypassIndicators: Int
    let xProtectVersion: String
    
    var overallHealthColor: Color {
        switch riskLevel.lowercased() {
        case "low": return .green
        case "medium": return .yellow
        case "high": return .orange
        case "critical": return .red
        default: return .gray
        }
    }
    
    var overallHealthText: String {
        switch riskLevel.lowercased() {
        case "low": return "🟢 Excellent"
        case "medium": return "🟡 Good"
        case "high": return "🟠 Warning"
        case "critical": return "🔴 Critical"
        default: return "⚪ Unknown"
        }
    }
    
    var protectionStatusColor: Color {
        return realTimeProtectionEnabled ? .green : .red
    }
    
    var protectionStatusText: String {
        return realTimeProtectionEnabled ? "🟢 Active" : "🔴 Disabled"
    }
    
    var protectionSubtitle: String {
        return realTimeProtectionEnabled ? "Protection Enabled" : "Protection Disabled"
    }
}

class SystemHealthChecker: ObservableObject {
    @Published var currentHealth: SystemHealthData?
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var updateTimer: Timer?
    private let instanceId = UUID().uuidString.prefix(8)
    
    init() {
        print("🏗️ SystemHealthChecker instance created: \(instanceId)")
    }
    
    deinit {
        stopRealTimeMonitoring()
    }
    
    func refreshData() {
        print("🔄 refreshData() called on instance: \(instanceId)")
        checkSystemHealth()
        gatherSystemInformation()
    }

    func startRealTimeMonitoring() {
        // Check every 30 seconds for general system health
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkSystemHealth()
        }
        
        // Check real-time protection status more frequently (every 10 seconds)
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkRealTimeProtectionStatus()
        }
    }
    
    func stopRealTimeMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func checkSystemHealth() {
        isLoading = true
        lastError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.executeHealthCheck()
        }
    }
    
    private func executeHealthCheck() {
        // Run security checks directly instead of using a script
        let sipStatus = checkSIPStatus()
        let fileVaultStatus = checkFileVaultStatus()
        let gatekeeperStatus = checkGatekeeperStatus()
        let secureBootStatus = checkSecureBootStatus()
        let xProtectVersion = getXProtectVersion()
        let firewallStatus = checkFirewallStatus()
        let autoUpdateStatus = checkAutoUpdateStatus()
        let mdeInstalled = checkMDEInstalled()
        
        print("🔍 Collected values:")
        print("   SIP: \(sipStatus)")
        print("   FileVault: \(fileVaultStatus)")
        print("   Gatekeeper: \(gatekeeperStatus)")
        print("   Secure Boot: \(secureBootStatus)")
        print("   XProtect: \(xProtectVersion)")
        print("   Firewall: \(firewallStatus)")
        print("   Auto Updates: \(autoUpdateStatus)")
        print("   MDE Installed: \(mdeInstalled)")
        
        // Create a simulated log output for parsing
        let logOutput = """
        2025-09-06 00:16:10 [INFO]  mac_audit_enhanced starting (PID $$)
        2025-09-06 00:16:10 [INFO]  Version: 1.0.0
        2025-09-06 00:16:10 [INFO]  Logging to stderr
        2025-09-06 00:16:10 [INFO]  Starting security collection
        2025-09-06 00:16:10 [INFO]  OS: 26.0 [25A5351b] arm64
        2025-09-06 00:16:10 [INFO]  FileVault: \(fileVaultStatus)
        2025-09-06 00:16:10 [INFO]  Gatekeeper: \(gatekeeperStatus)
        2025-09-06 00:16:10 [INFO]  XProtect: \(xProtectVersion)
        2025-09-06 00:16:10 [INFO]  SIP: \(sipStatus)
        2025-09-06 00:16:10 [INFO]  Secure Boot: \(secureBootStatus)
        2025-09-06 00:16:10 [INFO]  Firewall: \(firewallStatus)
        2025-09-06 00:16:10 [INFO]  Auto Updates: \(autoUpdateStatus)
        2025-09-06 00:16:10 [INFO]  MDE Installed: \(mdeInstalled)
        2025-09-06 00:16:10 [INFO]  Collection complete
        2025-09-06 00:16:10 [INFO]  Run complete
        """
        
        DispatchQueue.main.async { [weak self] in
            self?.parseHealthData(logOutput)
        }
    }
    
    private func checkSIPStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/csrutil")
        task.arguments = ["status"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.contains("enabled") ? "Enabled" : "Disabled"
        } catch {
            return "Unknown"
        }
    }
    
    private func checkFileVaultStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/fdesetup")
        task.arguments = ["status"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.contains("On") ? "Enabled" : "Disabled"
        } catch {
            return "Unknown"
        }
    }
    
    private func checkGatekeeperStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/spctl")
        task.arguments = ["--status"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.contains("assessments enabled") ? "Enabled" : "Disabled"
        } catch {
            return "Unknown"
        }
    }
    
    private func checkSecureBootStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/nvram")
        task.arguments = ["boot-args"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.isEmpty ? "Full" : "Reduced"
        } catch {
            return "Unknown"
        }
    }
    
    private func parseHealthData(_ logString: String) {
        let lines = logString.components(separatedBy: .newlines)
        var healthData: [String: String] = [:]
        
        let parsingRules: [String: String] = [
            "SIP": "SIP:",
            "Secure Boot": "Secure Boot:",
            "FileVault": "FileVault:",
            "Gatekeeper": "Gatekeeper:",
            "XProtect": "XProtect:",
            "Firewall": "Firewall:",
            "Auto Updates": "Auto Updates:",
            "MDE Installed": "MDE Installed:"
        ]
        
        for line in lines {
            for (key, prefix) in parsingRules {
                if line.contains(prefix) {
                    healthData[key] = extractValue(from: line, after: prefix) ?? "Unknown"
                }
            }
        }
        
        let sipStatus = healthData["SIP"] ?? "Unknown"
        let secureBootStatus = healthData["Secure Boot"] ?? "Unknown"
        let fileVaultStatus = healthData["FileVault"] ?? "Unknown"
        let gatekeeperStatus = healthData["Gatekeeper"] ?? "Unknown"
        let xProtectVersion = healthData["XProtect"] ?? "Unknown"
        let firewallStatus = healthData["Firewall"] ?? "Unknown"
        let autoUpdateStatus = healthData["Auto Updates"] ?? "Unknown"
        let mdeInstalledString = healthData["MDE Installed"] ?? "false"
        let mdeInstalled = mdeInstalledString.lowercased() == "true"
        
        // Determine risk level based on security status
        var riskFactors = 0
        if sipStatus != "Enabled" { riskFactors += 1 }
        if fileVaultStatus != "Enabled" { riskFactors += 1 }
        if gatekeeperStatus != "Enabled" { riskFactors += 1 }
        
        let riskLevel: String
        let riskScore: Int
        
        switch riskFactors {
        case 0:
            riskLevel = "Low"
            riskScore = 0
        case 1:
            riskLevel = "Medium"
            riskScore = 25
        case 2:
            riskLevel = "High"
            riskScore = 50
        default:
            riskLevel = "Critical"
            riskScore = 75
        }
        
        // Update state using the new central method
        updateHealthData { currentData in
            SystemHealthData(
                sipStatus: sipStatus,
                secureBootStatus: secureBootStatus,
                fileVaultStatus: fileVaultStatus,
                gatekeeperStatus: gatekeeperStatus,
                firewallStatus: firewallStatus,
                autoUpdateStatus: autoUpdateStatus,
                realTimeProtectionEnabled: currentData.realTimeProtectionEnabled, // Preserve existing
                mdeInstalled: mdeInstalled,
                riskScore: riskScore,
                riskLevel: riskLevel,
                lastUpdated: Date(),
                hostname: currentData.hostname, // Preserve existing data
                macModel: currentData.macModel, // Preserve existing data
                osVersion: currentData.osVersion, // Preserve existing data
                touchIDStatus: currentData.touchIDStatus, // Preserve existing data
                cpuUsage: currentData.cpuUsage,
                memoryUsage: currentData.memoryUsage,
                diskUsage: currentData.diskUsage,
                systemUptime: currentData.systemUptime,
                securityRiskScore: currentData.securityRiskScore,
                criticalIssues: currentData.criticalIssues,
                majorIssues: currentData.majorIssues,
                minorIssues: currentData.minorIssues,
                isHealthy: currentData.isHealthy,
                osBuild: currentData.osBuild, // Preserve existing data
                architecture: currentData.architecture, // Preserve existing data
                localAdminStatus: currentData.localAdminStatus, // Preserve existing data
                sudoAccess: currentData.sudoAccess, // Preserve existing data
                tccDangerousPermissions: currentData.tccDangerousPermissions,
                quarantineBypassIndicators: currentData.quarantineBypassIndicators,
                xProtectVersion: xProtectVersion
            )
        }
    }
    
    private func extractValue(from line: String, after prefix: String) -> String? {
        guard let range = line.range(of: prefix) else { return nil }
        let value = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    
    private func checkFirewallStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPFirewallDataType"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                let output = outputString.lowercased()
                if output.contains("mode:") && (output.contains("limit incoming") || output.contains("block all")) {
                    return "Enabled"
                } else if output.contains("mode:") && output.contains("allow all") {
                    return "Disabled"
                } else {
                    return "Unknown"
                }
            }
        } catch {
            print("Error checking firewall status: \(error)")
        }
        
        return "Unknown"
    }
    
    private func checkAutoUpdateStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
        task.arguments = ["--schedule"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                let output = outputString.lowercased()
                if output.contains("turned on") {
                    return "Enabled"
                } else if output.contains("turned off") {
                    return "Disabled"
                } else {
                    return "Unknown"
                }
            }
        } catch {
            print("Error checking auto-update status: \(error)")
        }
        
        return "Unknown"
    }
    
    private func checkMDEInstalled() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/mdatp")
        task.arguments = ["health", "--field", "licensed"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                let output = outputString.trimmingCharacters(in: .whitespacesAndNewlines)
                return output.lowercased() == "true"
            }
        } catch {
            print("Error checking MDE installation: \(error)")
        }
        
        return false
    }
    
    private func checkRealTimeProtectionStatus() {
        // Quick check for real-time protection status only
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/mdatp")
        task.arguments = ["health", "--field", "real_time_protection_enabled"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                let isEnabled = outputString.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
                
                DispatchQueue.main.async { [weak self] in
                    if let currentHealth = self?.currentHealth {
                        // Update only the real-time protection status
                        let updatedHealth = SystemHealthData(
                            sipStatus: currentHealth.sipStatus,
                            secureBootStatus: currentHealth.secureBootStatus,
                            fileVaultStatus: currentHealth.fileVaultStatus,
                            gatekeeperStatus: currentHealth.gatekeeperStatus,
                            firewallStatus: currentHealth.firewallStatus,
                            autoUpdateStatus: currentHealth.autoUpdateStatus,
                            realTimeProtectionEnabled: isEnabled,
                            mdeInstalled: currentHealth.mdeInstalled,
                            riskScore: currentHealth.riskScore,
                            riskLevel: currentHealth.riskLevel,
                            lastUpdated: Date(),
                            hostname: currentHealth.hostname, // Keep existing
                            macModel: currentHealth.macModel, // Keep existing
                            osVersion: currentHealth.osVersion, // Keep existing
                            touchIDStatus: currentHealth.touchIDStatus, // Keep existing
                            cpuUsage: currentHealth.cpuUsage, // Keep existing
                            memoryUsage: currentHealth.memoryUsage, // Keep existing
                            diskUsage: currentHealth.diskUsage, // Keep existing
                            systemUptime: currentHealth.systemUptime, // Keep existing
                            securityRiskScore: currentHealth.securityRiskScore, // Keep existing
                            criticalIssues: currentHealth.criticalIssues, // Keep existing
                            majorIssues: currentHealth.majorIssues, // Keep existing
                            minorIssues: currentHealth.minorIssues, // Keep existing
                            isHealthy: currentHealth.isHealthy, // Keep existing
                            osBuild: currentHealth.osBuild, // Keep existing
                            architecture: currentHealth.architecture, // Keep existing
                            localAdminStatus: currentHealth.localAdminStatus, // Keep existing
                            sudoAccess: currentHealth.sudoAccess, // Keep existing
                            tccDangerousPermissions: currentHealth.tccDangerousPermissions, // Keep existing
                            quarantineBypassIndicators: currentHealth.quarantineBypassIndicators, // Keep existing
                            xProtectVersion: currentHealth.xProtectVersion // Keep existing
                        )
                        self?.currentHealth = updatedHealth
                    }
                }
            }
        } catch {
            // Silently fail for quick checks
            print("Quick RTP check failed: \(error.localizedDescription)")
        }
    }
    
    func gatherSystemInformation() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("🔍 Starting system information gathering...")
            
            let hostname = self?.getHostname() ?? "Unknown"
            print("📱 Hostname: \(hostname)")
            
            let macModel = self?.getMacModel() ?? "Unknown"
            print("💻 Mac Model: \(macModel)")
            
            let osVersion = self?.getOSVersion() ?? "Unknown"
            print("🖥️ OS Version: \(osVersion)")
            
            let touchIDStatus = self?.getTouchIDStatus() ?? "Unknown"
            print("👆 Touch ID Status: \(touchIDStatus)")
            
            let osBuild = self?.getOSBuild() ?? "Unknown"
            print("🏗️ OS Build: \(osBuild)")
            
            let architecture = self?.getArchitecture() ?? "Unknown"
            print("🏛️ Architecture: \(architecture)")
            
            let localAdminStatus = self?.getLocalAdminStatus() ?? "Unknown"
            print("👤 Local Admin: \(localAdminStatus)")
            
            let sudoAccess = self?.getSudoAccess() ?? "Unknown"
            print("🔐 Sudo Access: \(sudoAccess)")
            
            let tccDangerousPermissions = self?.getTCCDangerousPermissions() ?? 0
            print("⚠️ TCC Dangerous Permissions: \(tccDangerousPermissions)")
            
            let quarantineBypassIndicators = self?.getQuarantineBypassIndicators() ?? 0
            print("🚫 Quarantine Bypass Indicators: \(quarantineBypassIndicators)")
            
            let xProtectVersion = self?.getXProtectVersion() ?? "Unknown"
            print("🛡️ XProtect Version: \(xProtectVersion)")

            // Update state using the new central method
            self?.updateHealthData { currentData in
                SystemHealthData(
                    sipStatus: currentData.sipStatus, // Preserve existing
                    secureBootStatus: currentData.secureBootStatus, // Preserve existing
                    fileVaultStatus: currentData.fileVaultStatus, // Preserve existing
                    gatekeeperStatus: currentData.gatekeeperStatus, // Preserve existing
                    firewallStatus: currentData.firewallStatus, // Preserve existing
                    autoUpdateStatus: currentData.autoUpdateStatus, // Preserve existing
                    realTimeProtectionEnabled: currentData.realTimeProtectionEnabled, // Preserve existing
                    mdeInstalled: currentData.mdeInstalled, // Preserve existing
                    riskScore: currentData.riskScore, // Preserve existing
                    riskLevel: currentData.riskLevel, // Preserve existing
                    lastUpdated: Date(),
                    hostname: hostname,
                    macModel: macModel,
                    osVersion: osVersion,
                    touchIDStatus: touchIDStatus,
                    cpuUsage: currentData.cpuUsage,
                    memoryUsage: currentData.memoryUsage,
                    diskUsage: currentData.diskUsage,
                    systemUptime: currentData.systemUptime,
                    securityRiskScore: currentData.securityRiskScore,
                    criticalIssues: currentData.criticalIssues,
                    majorIssues: currentData.majorIssues,
                    minorIssues: currentData.minorIssues,
                    isHealthy: currentData.isHealthy,
                    osBuild: osBuild,
                    architecture: architecture,
                    localAdminStatus: localAdminStatus,
                    sudoAccess: sudoAccess,
                    tccDangerousPermissions: tccDangerousPermissions,
                    quarantineBypassIndicators: quarantineBypassIndicators,
                    xProtectVersion: xProtectVersion
                )
            }
        }
    }
    
    private func updateHealthData(with builder: @escaping (SystemHealthData) -> SystemHealthData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let currentData = self.currentHealth ?? SystemHealthData(
                sipStatus: "Unknown", secureBootStatus: "Unknown", fileVaultStatus: "Unknown",
                gatekeeperStatus: "Unknown", firewallStatus: "Unknown", autoUpdateStatus: "Unknown",
                realTimeProtectionEnabled: false, mdeInstalled: false, riskScore: 0, riskLevel: "Unknown",
                lastUpdated: Date(), hostname: "Unknown", macModel: "Unknown", osVersion: "Unknown",
                touchIDStatus: "Unknown", cpuUsage: 0, memoryUsage: 0, diskUsage: 0, systemUptime: "Unknown",
                securityRiskScore: 0, criticalIssues: 0, majorIssues: 0, minorIssues: 0, isHealthy: false,
                osBuild: "Unknown", architecture: "Unknown", localAdminStatus: "Unknown", sudoAccess: "Unknown",
                tccDangerousPermissions: 0, quarantineBypassIndicators: 0, xProtectVersion: "Unknown"
            )
            
            self.currentHealth = builder(currentData)
            self.isLoading = false
            print("✅ System Health Data updated on instance: \(self.instanceId)")
            print("📊 SIP: \(self.currentHealth?.sipStatus ?? "nil")")
            print("📊 FileVault: \(self.currentHealth?.fileVaultStatus ?? "nil")")
            print("📊 Gatekeeper: \(self.currentHealth?.gatekeeperStatus ?? "nil")")
            print("📊 Risk Level: \(self.currentHealth?.riskLevel ?? "nil")")
        }
    }
    
    private func getHostname() -> String {
        // Try scutil first to get the user-friendly name
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        task.arguments = ["--get", "ComputerName"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe

        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let computerName = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !computerName.isEmpty {
                print("[\(#function)] Found hostname using scutil: \(computerName)")
                return computerName
            }
        } catch {
            print("[\(#function)] Failed to get hostname with scutil: \(error)")
        }
        
        // Fallback to ProcessInfo
        let hostname = ProcessInfo.processInfo.hostName
        if !hostname.isEmpty && hostname != "localhost" {
            print("[\(#function)] Found hostname using ProcessInfo: \(hostname)")
            return hostname.components(separatedBy: ".").first ?? hostname
        }

        // Fallback to system property
        var size = 0
        sysctlbyname("kern.hostname", nil, &size, nil, 0)
        if size > 0 {
            var hostnameChars = [CChar](repeating: 0, count: size)
            if sysctlbyname("kern.hostname", &hostnameChars, &size, nil, 0) == 0 {
                let hostname = String(cString: hostnameChars)
                print("[\(#function)] Found hostname using sysctlbyname: \(hostname)")
                return hostname.components(separatedBy: ".").first ?? hostname
            }
        }

        // Final fallback to command line
        let fallbackTask = Process()
        fallbackTask.executableURL = URL(fileURLWithPath: "/bin/hostname")
        let fallbackPipe = Pipe()
        fallbackTask.standardOutput = fallbackPipe
        
        do {
            try fallbackTask.run()
            fallbackTask.waitUntilExit()
            let outputData = fallbackPipe.fileHandleForReading.readDataToEndOfFile()
            let hostname = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
            print("[\(#function)] Found hostname using /bin/hostname: \(hostname)")
            return hostname.components(separatedBy: ".").first ?? hostname
        } catch {
            print("[\(#function)] Failed to get hostname: \(error)")
            return "Unknown"
        }
    }
    
    private func getMacModel() -> String {
        // Use system property first (most reliable)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        if size > 0 {
            var model = [CChar](repeating: 0, count: size)
            if sysctlbyname("hw.model", &model, &size, nil, 0) == 0 {
                return String(cString: model)
            }
        }
        
        // Fallback to system_profiler
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPHardwareDataType", "-json"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8),
               let data = outputString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let hardware = json["SPHardwareDataType"] as? [[String: Any]],
               let firstHardware = hardware.first,
               let model = firstHardware["machine_model"] as? String {
                return model
            }
            return "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private func getOSVersion() -> String {
        // Use ProcessInfo first (most reliable)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        if osVersion != "0.0.0" {
            return osVersion
        }
        
        // Fallback to sw_vers
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sw_vers")
        task.arguments = ["-productVersion"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private func getTouchIDStatus() -> String {
        // Check if Touch ID is available by looking for biometric hardware
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        task.arguments = ["SPiBridgeDataType", "-json"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.contains("Touch ID") ? "Available" : "Not Available"
        } catch {
            return "Unknown"
        }
    }
    
    private func getOSBuild() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sw_vers")
        task.arguments = ["-buildVersion"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private func getArchitecture() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
        task.arguments = ["-m"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
    
    private func getLocalAdminStatus() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscl")
        task.arguments = [".", "-read", "/Groups/admin", "GroupMembership"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            return output.contains(NSUserName()) ? "Yes" : "No"
        } catch {
            return "Unknown"
        }
    }
    
    private func getSudoAccess() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        task.arguments = ["-n", "true"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0 ? "Available" : "None"
        } catch {
            return "None"
        }
    }
    
    private func getTCCDangerousPermissions() -> Int {
        // This would require more complex TCC database access
        // For now, return a placeholder
        return 0
    }
    
    private func getQuarantineBypassIndicators() -> Int {
        // This would require checking for quarantine bypass indicators
        // For now, return a placeholder
        return 0
    }
    
    private func getXProtectVersion() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", "/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist", "CFBundleShortVersionString"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }
}

#Preview {
    VStack {
        Text("System Health Checker")
            .font(.headline)
        
        if let health = SystemHealthChecker().currentHealth {
            Text(health.overallHealthText)
                .foregroundColor(health.overallHealthColor)
        } else {
            Text("No data")
                .foregroundColor(.gray)
        }
    }
}
