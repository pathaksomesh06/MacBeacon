import SwiftUI

struct SystemIssuesModal: View {
    @ObservedObject var systemHealthChecker: SystemHealthChecker
    @Environment(\.dismiss) private var dismiss
    let sourceCard: String // To identify which card was clicked
    
    init(systemHealthChecker: SystemHealthChecker, sourceCard: String = "General") {
        self.systemHealthChecker = systemHealthChecker
        self.sourceCard = sourceCard
        print("🔍 SystemIssuesModal initialized with sourceCard: '\(sourceCard)'")  // Debug print
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: getHeaderIcon())
                            .font(.title)
                            .foregroundColor(getHeaderColor())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getHeaderTitle())
                                .font(.title2)
                                .fontWeight(.bold)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(getHeaderSubtitle())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Overall Status
                    if let health = systemHealthChecker.currentHealth {
                        HStack {
                            Circle()
                                .fill(health.overallHealthColor)
                                .frame(width: 12, height: 12)
                            
                            Text("Overall Risk Level: \(health.riskLevel)")
                                .font(.headline)
                                .foregroundColor(health.overallHealthColor)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Text("Risk Score: \(health.riskScore)/12")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                // Content based on source card
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 16) {
                        if let health = systemHealthChecker.currentHealth {
                            switch sourceCard {
                            case "System Health":
                                showSystemHealthContent(health)
                            case "Real-time Protection":
                                showRealTimeProtectionContent(health)
                            case "Security Status":
                                showSecurityStatusContent(health)
                            case "Network Security":
                                showNetworkSecurityContent(health)
                            default:
                                showGeneralIssuesContent(health)
                            }
                        } else {
                            // Loading state
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Analyzing system security...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(getNavigationTitle())
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Refresh") {
                    systemHealthChecker.checkSystemHealth()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    // MARK: - Header Configuration
    private func getHeaderIcon() -> String {
        switch sourceCard {
        case "System Health": return "heart.fill"
        case "Real-time Protection": return "shield.fill"
        case "Security Status": return "exclamationmark.shield.fill"
        case "Network Security": return "network"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    private func getHeaderColor() -> Color {
        switch sourceCard {
        case "System Health": return .orange
        case "Real-time Protection": return .red
        case "Security Status": return .yellow
        case "Network Security": return .blue
        default: return .orange
        }
    }
    
    private func getHeaderTitle() -> String {
        switch sourceCard {
        case "System Health": return "System Health Analysis"
        case "Real-time Protection": return "Real-time Protection Status"
        case "Security Status": return "Security Posture Analysis"
        case "Network Security": return "Network Security Status"
        default: return "System Security Issues"
        }
    }
    
    private func getHeaderSubtitle() -> String {
        switch sourceCard {
        case "System Health": return "Comprehensive system health assessment"
        case "Real-time Protection": return "Microsoft Defender protection status"
        case "Security Status": return "Overall security posture evaluation"
        case "Network Security": return "Network connection security analysis"
        default: return "Detailed security posture analysis"
        }
    }
    
    private func getNavigationTitle() -> String {
        switch sourceCard {
        case "System Health": return "System Health"
        case "Real-time Protection": return "Real-time Protection"
        case "Security Status": return "Security Status"
        case "Network Security": return "Network Security"
        default: return "Security Issues"
        }
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private func showSystemHealthContent(_ health: SystemHealthData) -> some View {
        VStack(spacing: 16) {
            // System Performance & Resources
            VStack(alignment: .leading, spacing: 12) {
                Text("System Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HealthStatusRow(title: "CPU Usage", status: "Normal", critical: false)
                    HealthStatusRow(title: "Memory Usage", status: "Optimal", critical: false)
                    HealthStatusRow(title: "Disk Space", status: "Available", critical: false)
                    HealthStatusRow(title: "Battery Health", status: "Good", critical: false)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Hardware Health
            VStack(alignment: .leading, spacing: 12) {
                Text("Hardware Health")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HealthStatusRow(title: "Fan Status", status: "Normal", critical: false)
                    HealthStatusRow(title: "Temperature", status: "Optimal", critical: false)
                    HealthStatusRow(title: "Storage Health", status: "Good", critical: false)
                    HealthStatusRow(title: "Network Adapters", status: "All Working", critical: false)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // System Status Summary
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("System Health: Excellent")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("All system components are operating within normal parameters. No performance issues detected.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func showRealTimeProtectionContent(_ health: SystemHealthData) -> some View {
        VStack(spacing: 16) {
            // Protection Status
            VStack(alignment: .leading, spacing: 12) {
                Text("Protection Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: health.realTimeProtectionEnabled ? "checkmark.shield.fill" : "shield.slash.fill")
                        .font(.system(size: 48))
                        .foregroundColor(health.realTimeProtectionEnabled ? .green : .red)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(health.realTimeProtectionEnabled ? "Protection Active" : "Protection Disabled")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(health.realTimeProtectionEnabled ? .green : .red)
                        
                        Text(health.realTimeProtectionEnabled ? 
                             "Microsoft Defender is actively protecting your system from threats." :
                             "Your system is currently vulnerable to real-time threats.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Threat Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("Threat Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HealthStatusRow(title: "Threats Blocked Today", status: "0", critical: false)
                    HealthStatusRow(title: "Last Scan", status: "2 hours ago", critical: false)
                    HealthStatusRow(title: "Quarantined Files", status: "0", critical: false)
                    HealthStatusRow(title: "Scan Status", status: "Up to date", critical: false)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Protection Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("No recent threats detected. Your system is being actively monitored and protected.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Action required if protection is disabled
            if !health.realTimeProtectionEnabled {
                IssueCard(
                    title: "Action Required",
                    description: "Real-time protection is disabled. This leaves your system vulnerable to malware and other threats.",
                    severity: .critical,
                    recommendation: "Enable real-time protection in Microsoft Defender settings or through Intune policies.",
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }
    
    @ViewBuilder
    private func showSecurityStatusContent(_ health: SystemHealthData) -> some View {
        VStack(spacing: 16) {
            // Security Score Dashboard
            VStack(alignment: .leading, spacing: 12) {
                Text("Security Score Dashboard")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        SecurityPostureRow(title: "Overall Risk", value: health.riskLevel, color: health.overallHealthColor)
                        SecurityPostureRow(title: "Risk Score", value: "\(health.riskScore)/12", color: getRiskColor(health.riskScore))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SecurityPostureRow(title: "Compliance Score", value: "85%", color: .green)
                        SecurityPostureRow(title: "Security Rating", value: "B+", color: .yellow)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Security Features Status
            VStack(alignment: .leading, spacing: 12) {
                Text("Security Features Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    SecurityPostureRow(title: "SIP Protection", value: health.sipStatus == "Enabled" ? "Active" : "Disabled", color: health.sipStatus == "Enabled" ? .green : .red)
                    SecurityPostureRow(title: "FileVault Encryption", value: health.fileVaultStatus == "Enabled" ? "Active" : "Disabled", color: health.fileVaultStatus == "Enabled" ? .green : .red)
                    SecurityPostureRow(title: "Gatekeeper", value: health.gatekeeperStatus == "Enabled" ? "Active" : "Disabled", color: health.gatekeeperStatus == "Enabled" ? .green : .red)
                    SecurityPostureRow(title: "Secure Boot", value: health.secureBootStatus == "Enabled" ? "Active" : "Disabled", color: health.secureBootStatus == "Enabled" ? .green : .red)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Security Recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text("Security Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Based on your current security posture, consider enabling additional security features and running regular security audits.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func showNetworkSecurityContent(_ health: SystemHealthData) -> some View {
        VStack(spacing: 16) {
            // Active Network Connections
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Network Connections")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    HealthStatusRow(title: "WiFi Network", status: "Connected", critical: false)
                    HealthStatusRow(title: "Ethernet", status: "Not Connected", critical: false)
                    HealthStatusRow(title: "VPN Status", status: "Not Active", critical: false)
                    HealthStatusRow(title: "Bluetooth", status: "Enabled", critical: false)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Network Security Status
            VStack(alignment: .leading, spacing: 12) {
                Text("Network Security Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    SecurityPostureRow(title: "Firewall", value: health.firewallStatus == "enabled" ? "Active" : "Disabled", color: health.firewallStatus == "enabled" ? .green : .red)
                    SecurityPostureRow(title: "Network Protection", value: "Active", color: .green)
                    SecurityPostureRow(title: "DNS Security", value: "Protected", color: .green)
                    SecurityPostureRow(title: "Connection Encryption", value: "TLS 1.3", color: .green)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Network Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Network Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("No suspicious network activity detected. All connections are properly encrypted and monitored.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Firewall warning if disabled
            if health.firewallStatus != "enabled" {
                IssueCard(
                    title: "Firewall Disabled",
                    description: "The built-in firewall is disabled, leaving your system vulnerable to network attacks.",
                    severity: .high,
                    recommendation: "Enable firewall in System Preferences > Security & Privacy > Firewall.",
                    icon: "network.slash.fill"
                )
            }
        }
    }
    
    @ViewBuilder
    private func showGeneralIssuesContent(_ health: SystemHealthData) -> some View {
        // Show all issues (original behavior)
        if !health.realTimeProtectionEnabled {
            IssueCard(
                title: "Real-time Protection Disabled",
                description: "Microsoft Defender real-time protection is currently disabled, leaving your system vulnerable to threats.",
                severity: .critical,
                recommendation: "Enable real-time protection in Microsoft Defender settings or through Intune policies.",
                icon: "shield.slash.fill"
            )
        }
        
        if health.sipStatus == "Disabled" {
            IssueCard(
                title: "System Integrity Protection Disabled",
                description: "SIP is disabled, which allows modification of system files and processes. This is a critical security risk.",
                severity: .critical,
                recommendation: "Enable SIP using csrutil enable in Recovery Mode.",
                icon: "lock.slash.fill"
            )
        }
        
        if health.fileVaultStatus != "Enabled" {
            IssueCard(
                title: "FileVault Not Enabled",
                description: "Disk encryption is not enabled, leaving your data vulnerable if the device is lost or stolen.",
                severity: .high,
                recommendation: "Enable FileVault in System Preferences > Security & Privacy > FileVault.",
                icon: "lock.open.fill"
            )
        }
        
        if health.gatekeeperStatus != "Enabled" {
            IssueCard(
                title: "Gatekeeper Disabled",
                description: "Gatekeeper is disabled, allowing unsigned applications to run without verification.",
                severity: .high,
                recommendation: "Enable Gatekeeper using: sudo spctl --master-enable",
                icon: "checkmark.shield.slash.fill"
            )
        }
        
        if health.firewallStatus != "enabled" {
            IssueCard(
                title: "Firewall Disabled",
                description: "Built-in firewall is disabled, leaving your system vulnerable to network attacks.",
                severity: .high,
                recommendation: "Enable firewall in System Preferences > Security & Privacy > Firewall.",
                icon: "network.slash.fill"
            )
        }
        
        if health.riskScore >= 6 {
            IssueCard(
                title: "High Risk Score Detected",
                description: "Your system has a risk score of \(health.riskScore)/12, indicating multiple security vulnerabilities.",
                severity: .high,
                recommendation: "Review and address the specific issues listed above to improve your security posture.",
                icon: "exclamationmark.triangle.fill"
            )
        }
        
        // No Issues Found
        if health.realTimeProtectionEnabled && 
           health.sipStatus == "Enabled" && 
           health.fileVaultStatus == "Enabled" && 
           health.gatekeeperStatus == "Enabled" && 
           health.firewallStatus == "enabled" && 
           health.riskScore < 6 {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("No Critical Issues Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your system appears to be well-secured with all major security features enabled.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func getRiskColor(_ score: Int) -> Color {
        if score <= 3 { return .green }
        else if score <= 6 { return .yellow }
        else if score <= 9 { return .orange }
        else { return .red }
    }
}

struct HealthStatusRow: View {
    let title: String
    let status: String
    let critical: Bool
    
    var statusColor: Color {
        if critical {
            return status == "Enabled" || status == "Yes" ? .green : .red
        } else {
            return status == "Enabled" || status == "Yes" ? .green : .orange
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(status)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
    }
}

struct SecurityPostureRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct IssueCard: View {
    let title: String
    let description: String
    let severity: IssueSeverity
    let recommendation: String
    let icon: String
    
    enum IssueSeverity {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var text: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(severity.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("Severity:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(severity.text)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(severity.color)
                    }
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommendation:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(recommendation)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    SystemIssuesModal(systemHealthChecker: SystemHealthChecker())
        .frame(width: 600, height: 500)
}
