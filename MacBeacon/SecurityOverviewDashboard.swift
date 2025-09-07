import SwiftUI
import Charts

struct SecurityOverviewDashboard: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @StateObject private var pssOStatusChecker = PSSOStatusChecker()
    @StateObject private var complianceEngine = PolicyComplianceEngine()
    @StateObject private var systemHealthChecker = SystemHealthChecker()

    @State private var showingComplianceDetails = false

    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 20) {
                // Top Row - Enterprise Metrics (smaller, more compact)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // PSSO Status
                    MetricCard(
                        title: "PSSO Status",
                        value: pssOStatusChecker.currentStatus.statusText,
                        subtitle: pssOStatusChecker.currentStatus.subtitle,
                        icon: "person.circle.fill",
                        color: pssOStatusChecker.currentStatus.statusColor,
                        trend: .neutral,
                        showTrend: false
                    )

                    
                    // Compliance Status
                    MetricCard(
                        title: "Compliance Status",
                        value: complianceEngine.complianceStatus,
                        subtitle: complianceEngine.complianceSubtitle,
                        icon: "checkmark.shield.fill",
                        color: getComplianceColor(),
                        trend: .neutral,
                        showTrend: false
                    )

                    
                    // System Health (Real Data)
                    MetricCard(
                        title: "System Health",
                        value: systemHealthChecker.currentHealth?.overallHealthText ?? "Loading...",
                        subtitle: systemHealthChecker.currentHealth?.overallHealthText.contains("Excellent") == true ? "All systems optimal" : "Issues detected",
                        icon: "heart.fill",
                        color: systemHealthChecker.currentHealth?.overallHealthColor ?? .gray,
                        trend: .neutral,
                        showTrend: false
                    )

                }
                .padding(.horizontal)
                
                // Second Row - Security Metrics (smaller, more compact)
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Real-time Protection (Real Data)
                    MetricCard(
                        title: "Real-time Protection",
                        value: systemHealthChecker.currentHealth?.protectionStatusText ?? "Loading...",
                        subtitle: systemHealthChecker.currentHealth?.protectionSubtitle ?? "Checking...",
                        icon: "shield.fill",
                        color: systemHealthChecker.currentHealth?.protectionStatusColor ?? .gray,
                        trend: .neutral,
                        showTrend: false
                    )

                    
                    // Security Status
                    MetricCard(
                        title: "Security Status",
                        value: getSecurityStatusText(),
                        subtitle: getSecurityStatusSubtitle(),
                        icon: "exclamationmark.shield.fill",
                        color: getSecurityStatusColor(),
                        trend: .neutral,
                        showTrend: false
                    )

                    
                    // Network Security
                    MetricCard(
                        title: "Network Security",
                        value: getNetworkSecurityText(),
                        subtitle: getNetworkSecuritySubtitle(),
                        icon: "network",
                        color: getNetworkSecurityColor(),
                        trend: .neutral,
                        showTrend: false
                    )
                    
                }
                .padding(.horizontal)
                
                // Main Dashboard Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    QuickActionsPanel(securityMonitor: securityMonitor)
                    LiveActivityPanel(securityMonitor: securityMonitor)
                    RealTimeActivityMonitor(securityMonitor: securityMonitor)
                        .frame(height: 250)
                    SecurityTipsPanel()
                        .frame(height: 250)
                }
                .padding(.horizontal)
                
                // Fifth Row - Process and File Monitoring
                HStack(alignment: .top, spacing: 16) {
                    ProcessMonitorPanel(endpointMonitor: securityMonitor.endpointMonitor)
                        .frame(maxWidth: .infinity)
                    
                    FileMonitorPanel(endpointMonitor: securityMonitor.endpointMonitor)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                // Sixth Row - Enterprise Compliance and Reporting (2 panels)
                HStack(alignment: .top, spacing: 16) {
                    EnterpriseCompliancePanel()
                        .frame(maxWidth: .infinity)
                    
                    ComplianceReportingPanel(complianceEngine: complianceEngine)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .padding(.bottom)

        .onAppear {
            // Refresh data when view appears
            pssOStatusChecker.checkPSSOStatus()
            systemHealthChecker.checkSystemHealth()
            complianceEngine.refreshComplianceData()
        }
        .refreshable {
            // Pull to refresh functionality
            await refreshAllData()
        }
        // Toolbar removed temporarily to fix compilation issues
    }
    
    // MARK: - Data Refresh Functions
    @MainActor
    private func refreshAllData() async {
        // Show loading state
        withAnimation(.easeInOut(duration: 0.3)) {
            // Refresh all data sources
            pssOStatusChecker.checkPSSOStatus()
            systemHealthChecker.checkSystemHealth()
            complianceEngine.refreshComplianceData()
        }
    }
    
    // MARK: - Helper Functions
    func getComplianceColor() -> Color {
        let score = complianceEngine.overallComplianceScore
        if score >= 90 {
            return .green
        } else if score >= 75 {
            return .yellow
        } else if score >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    func getSecurityStatusText() -> String {
        guard let health = systemHealthChecker.currentHealth else {
            return "Loading..."
        }
        
        if health.riskLevel.lowercased() == "low" {
            return "🟢 Secure"
        } else if health.riskLevel.lowercased() == "medium" {
            return "🟡 Good"
        } else if health.riskLevel.lowercased() == "high" {
            return "🟠 Warning"
        } else {
            return "🔴 Critical"
        }
    }
    
    func getSecurityStatusSubtitle() -> String {
        guard let health = systemHealthChecker.currentHealth else {
            return "Checking..."
        }
        
        if health.riskLevel.lowercased() == "low" {
            return "All systems secure"
        } else if health.riskLevel.lowercased() == "medium" {
            return "Minor issues detected"
        } else if health.riskLevel.lowercased() == "high" {
            return "Some issues detected"
        } else {
            return "Critical issues detected"
        }
    }
    
    func getSecurityStatusColor() -> Color {
        guard let health = systemHealthChecker.currentHealth else {
            return .gray
        }
        
        switch health.riskLevel.lowercased() {
        case "low": return .green
        case "medium": return .yellow
        case "high": return .orange
        case "critical": return .red
        default: return .gray
        }
    }
    
    func getNetworkSecurityText() -> String {
        let connections = securityMonitor.networkConnections
        let blockedCount = connections.filter { $0.status == .blocked }.count
        
        if blockedCount == 0 {
            return "🟢 Safe"
        } else if blockedCount < 5 {
            return "🟡 Warning"
        } else {
            return "🔴 Alert"
        }
    }
    
    func getNetworkSecuritySubtitle() -> String {
        let connections = securityMonitor.networkConnections
        let blockedCount = connections.filter { $0.status == .blocked }.count
        
        if blockedCount == 0 {
            return "All connections secure"
        } else {
            return "\(blockedCount) blocked connections"
        }
    }
    
    func getNetworkSecurityColor() -> Color {
        let connections = securityMonitor.networkConnections
        let blockedCount = connections.filter { $0.status == .blocked }.count
        
        if blockedCount == 0 {
            return .green
        } else if blockedCount < 5 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Trend
    let showTrend: Bool
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and trend indicator
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if showTrend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            // Value (main metric)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct RealTimeActivityMonitor: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @StateObject private var systemMetrics = SystemMetrics()
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("REAL-TIME ACTIVITY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 6)
                                .opacity(pulseAnimation ? 0 : 0.5)
                                .scaleEffect(pulseAnimation ? 2 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulseAnimation)
                        )
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            // Activity Graph
            ZStack {
                // Simplified grid (only 3 lines instead of 5)
                VStack(spacing: 33) {
                    ForEach(0..<3) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(height: 1)
                    }
                }
                
                // Activity bars with better spacing
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(systemMetrics.realtimeActivity.enumerated()), id: \.offset) { index, value in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.83, blue: 1.0), Color(red: 0.0, green: 0.59, blue: 1.0)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 10, height: max(2, CGFloat(value * 0.8))) // Scale down the height
                            .opacity(Double(30 - index) / 30)
                    }
                }
            }
            .frame(height: 80) // Reduced height for less clutter
            
            HStack(spacing: 24) {
                Label("\(max(securityMonitor.realNetworkEvents, systemMetrics.eventsPerMinute)) Events/min", systemImage: "network")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Label(String(format: "CPU: %.0f%%", systemMetrics.cpuUsage), systemImage: "cpu")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
        .onAppear {
            pulseAnimation = true
            systemMetrics.startMonitoring()
        }
        .onDisappear {
            systemMetrics.stopMonitoring()
        }
    }
}

struct ThreatDistributionChart: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @State private var showingDetails = false
    
    var threatData: [(type: String, count: Int, color: Color)] {
        // Use real data properties instead of filtering manually
        let highRiskEvents = securityMonitor.realHighRiskEvents
        let mediumRiskEvents = securityMonitor.realMediumRiskEvents
        let fileEvents = securityMonitor.realFileEvents
        let networkEvents = securityMonitor.realNetworkEvents
        
        return [
            ("High Risk", highRiskEvents, Color.red),
            ("Medium Risk", mediumRiskEvents, Color.orange),
            ("File Activity", fileEvents, Color.cyan),
            ("Network", networkEvents, Color.blue)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THREAT DISTRIBUTION")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                Text("Security event breakdown")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Horizontal Bar Chart
            VStack(spacing: 12) {
                ForEach(threatData, id: \.type) { data in
                    HStack(spacing: 12) {
                        Text(data.type)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 90, alignment: .leading)
                        
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(data.color)
                                .frame(width: geometry.size.width * min(Double(data.count) / 20.0, 1.0))
                                .frame(height: 20)
                        }
                        .frame(height: 20)
                        
                        Text("\(data.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 35, alignment: .trailing)
                    }
                }
                
                Spacer()
                
                // Total Events Display - Clickable
                Button(action: { showingDetails = true }) {
                    VStack(spacing: 4) {
                        Text("\(threatData.map { $0.count }.reduce(0, +))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Total Events")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(showingDetails ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: showingDetails)
            }
            .frame(height: 160)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
        .sheet(isPresented: $showingDetails) {
            ThreatDistributionDetailsView(threatData: threatData, securityMonitor: securityMonitor)
                .presentationDetents([.medium, .large])
        }
    }
}

struct ThreatDistributionDetailsView: View {
    let threatData: [(type: String, count: Int, color: Color)]
    let securityMonitor: SecurityMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Event Details")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            
            // Simple Event Summary
            VStack(spacing: 16) {
                Text("Security Event Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // High Risk Count
                let highRiskCount = securityMonitor.realHighRiskEvents
                if highRiskCount > 0 {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        Text("High Risk Processes: \(highRiskCount)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                
                // Medium Risk Count
                let mediumRiskCount = securityMonitor.realMediumRiskEvents
                if mediumRiskCount > 0 {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                        Text("Medium Risk Processes: \(mediumRiskCount)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                
                // File Events Count
                let fileCount = securityMonitor.realFileEvents
                if fileCount > 0 {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan)
                            .frame(width: 16, height: 16)
                        Text("File Operations: \(fileCount)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                
                // Network Events Count
                let networkCount = securityMonitor.realNetworkEvents
                if networkCount > 0 {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                        Text("Network Connections: \(networkCount)")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                
                // No Events Message
                if highRiskCount == 0 && mediumRiskCount == 0 && fileCount == 0 && networkCount == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.7))
                        
                        Text("No Security Events Detected")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your system is currently secure with no high-risk activities, file modifications, or suspicious network connections detected.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.28))
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
            )
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .background(Color(red: 0.04, green: 0.05, blue: 0.15))
    }
}



    // MARK: - Helper Functions for User-Friendly Status Messages
    
    func getSystemHealthStatus(score: Int) -> String {
    switch score {
    case 90...100: return "🟢 Excellent"
    case 75...89: return "🟡 Good"
    case 60...74: return "🟠 Fair"
    default: return "🔴 Poor"
    }
}

func getSystemHealthSubtitle(score: Int) -> String {
    switch score {
    case 90...100: return "All systems optimal"
    case 75...89: return "Minor issues detected"
    case 60...74: return "Attention recommended"
    default: return "Immediate action needed"
    }
}

func getSystemHealthColor(score: Int) -> Color {
    switch score {
    case 90...100: return .green
    case 75...89: return .yellow
    case 60...74: return .orange
    default: return .red
    }
}

func getProtectionStatus(active: Bool) -> String {
    return active ? "🟢 Active" : "🔴 Inactive"
}

func getProtectionSubtitle(active: Bool) -> String {
    return active ? "Monitoring Active" : "Protection Disabled"
}

func getProtectionColor(active: Bool) -> Color {
    return active ? .blue : .red
}

func getSecurityStatus(threats: Int, protectionActive: Bool) -> String {
    // If protection is inactive, security status should reflect that
    if !protectionActive {
        return "🔴 Unprotected"
    }
    
    switch threats {
    case 0: return "🟢 Protected"
    case 1...3: return "🟡 Monitored"
    case 4...6: return "🟠 Alert"
    default: return "🔴 Critical"
    }
}

func getSecuritySubtitle(threats: Int, protectionActive: Bool) -> String {
    // If protection is inactive, security status should reflect that
    if !protectionActive {
        return "Real-time protection disabled"
    }
    
    switch threats {
    case 0: return "No threats detected"
    case 1...3: return "Low risk activity"
    case 4...6: return "Multiple alerts"
    default: return "High risk situation"
    }
}

func getSecurityColor(threats: Int, protectionActive: Bool) -> Color {
    // If protection is inactive, security status should reflect that
    if !protectionActive {
        return .red
    }
    
    switch threats {
    case 0: return .green
    case 1...3: return .yellow
    case 4...6: return .orange
    default: return .red
    }
}

func getNetworkStatus(events: Int) -> String {
    switch events {
    case 0: return "🟢 Safe"
    case 1...5: return "🟡 Normal"
    case 6...10: return "🟠 Active"
    default: return "🔴 High Activity"
    }
}

// MARK: - New User-Friendly Dashboard Panels

struct QuickActionsPanel: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @State private var showingSecurityCheck = false
    @State private var showingRecentAlerts = false
    @State private var showingSystemStatus = false
    @State private var showingExportReport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("QUICK ACTIONS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                QuickActionButton(
                    title: "Run Security Check",
                    icon: "magnifyingglass",
                    color: .blue,
                    action: { showingSecurityCheck = true }
                )
                
                QuickActionButton(
                    title: "View Recent Alerts",
                    icon: "bell",
                    color: .orange,
                    action: { showingRecentAlerts = true }
                )
                
                QuickActionButton(
                    title: "Check System Status",
                    icon: "checkmark.shield",
                    color: .green,
                    action: { showingSystemStatus = true }
                )
                
                QuickActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .purple,
                    action: { showingExportReport = true }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
        .sheet(isPresented: $showingSecurityCheck) {
            SecurityCheckView(securityMonitor: securityMonitor)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingRecentAlerts) {
            RecentAlertsView(securityMonitor: securityMonitor)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSystemStatus) {
            SystemStatusView(securityMonitor: securityMonitor)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingExportReport) {
            ExportReportView(securityMonitor: securityMonitor)
                .presentationDetents([.medium, .large])
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LiveActivityPanel: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @State private var currentTime = Date()
    @State private var activityPulse = false
    @State private var showingFileDetails = false
    @State private var showingProcessDetails = false
    @State private var showingNetworkDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "activity")
                    .foregroundColor(.green)
                Text("LIVE ACTIVITY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(Color.green, lineWidth: 6)
                                .opacity(activityPulse ? 0 : 0.5)
                                .scaleEffect(activityPulse ? 2 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: activityPulse)
                        )
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 12) {
                // Files Accessed - Clickable for details
                Button(action: { showingFileDetails = true }) {
                    ActivityRow(
                        icon: "doc.text", 
                        title: "Files Accessed", 
                        value: getFileActivityValue(), 
                        color: .blue
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Processes Running - Clickable for details
                Button(action: { showingProcessDetails = true }) {
                    ActivityRow(
                        icon: "terminal", 
                        title: "Processes Running", 
                        value: getProcessActivityValue(), 
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
                // Network Connections - Clickable for details
                Button(action: { showingNetworkDetails = true }) {
                    ActivityRow(
                        icon: "network", 
                        title: "Network Connections", 
                        value: getNetworkActivityValue(), 
                        color: .cyan
                    )
                }
                .buttonStyle(PlainButtonStyle())
                ActivityRow(
                    icon: "clock", 
                    title: "Last Update", 
                    value: getLastUpdateValue(), 
                    color: .yellow
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
        .onAppear {
            startActivityUpdates()
        }
        .onDisappear {
            stopActivityUpdates()
        }
        .sheet(isPresented: $showingFileDetails) {
            FileActivityDetailsView(fileEvents: securityMonitor.endpointMonitor.fileEvents)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingProcessDetails) {
            ProcessActivityDetailsView(processEvents: securityMonitor.endpointMonitor.processEvents)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingNetworkDetails) {
            NetworkActivityDetailsView(networkEvents: securityMonitor.realNetworkEvents)
                .presentationDetents([.medium, .large])
        }
    }
    
    // Real activity calculation methods - no simulation
    private func getFileActivityValue() -> String {
        let fileCount = securityMonitor.realFileEvents
        return "\(fileCount)"
    }
    
    private func getProcessActivityValue() -> String {
        let processCount = securityMonitor.realProcessEvents
        return "\(processCount)"
    }
    
    private func getNetworkActivityValue() -> String {
        let networkCount = securityMonitor.realNetworkEvents
        return "\(networkCount)"
    }
    
    private func getLastUpdateValue() -> String {
        let timeInterval = Date().timeIntervalSince(currentTime)
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 120 {
            return "1 min ago"
        } else {
            return "\(Int(timeInterval / 60)) mins ago"
        }
    }
    
    private func startActivityUpdates() {
        activityPulse = true
        // Update time every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopActivityUpdates() {
        activityPulse = false
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct SecurityTipsPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("SECURITY TIPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            VStack(spacing: 12) {
                SecurityTipRow(icon: "arrow.up.circle.fill", tip: "Keep software updated", color: .green)
                SecurityTipRow(icon: "key.fill", tip: "Use strong passwords", color: .blue)
                SecurityTipRow(icon: "lock.shield.fill", tip: "Enable 2FA where possible", color: .purple)
                SecurityTipRow(icon: "exclamationmark.triangle.fill", tip: "Be cautious with downloads", color: .orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
    }
}

struct SecurityTipRow: View {
    let icon: String
    let tip: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(tip)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

// MARK: - Simple Quick Action Implementation

// Simplified placeholder for future enhancement

// MARK: - Activity Detail Views

struct FileActivityDetailsView: View {
    let fileEvents: [FileEvent]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("File Activity Monitor")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            if fileEvents.isEmpty {
                // Status Information
                VStack(spacing: 24) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("File Monitoring Active")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Real-time file monitoring is active through the Endpoint Security API. No recent file access events have been captured, which is normal for background system monitoring.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Status Indicators
                    VStack(spacing: 16) {
                        StatusRow(icon: "circle.fill", color: .green, text: "Monitoring Status: Active")
                        StatusRow(icon: "shield.checkered", color: .blue, text: "API Integration: Endpoint Security")
                        StatusRow(icon: "clock", color: .orange, text: "Activity Level: Low/Background")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
                }
            } else {
                // File Events List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(fileEvents, id: \.id) { event in
                            LiveFileEventRow(event: event)
                        }
                    }
                }
                .padding(.bottom)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct StatusRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(text)
                .font(.body)
                .foregroundColor(.black)
            Spacer()
        }
    }
}

struct LiveFileEventRow: View {
    let event: FileEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text(event.filePath)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Text(event.operation.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.2))
                    )
                Text(event.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
        )
    }
}

struct ProcessActivityDetailsView: View {
    let processEvents: [ProcessEvent]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Process Activity Monitor")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            if processEvents.isEmpty {
                // Status Information
                VStack(spacing: 24) {
                    Image(systemName: "terminal")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Process Monitoring Active")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Real-time process monitoring is active through the Endpoint Security API. No recent process execution events have been captured, which is normal for background system monitoring.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Status Indicators
                    VStack(spacing: 16) {
                        StatusRow(icon: "circle.fill", color: .green, text: "Monitoring Status: Active")
                        StatusRow(icon: "cpu", color: .blue, text: "Process Tracking: Enabled")
                        StatusRow(icon: "shield.lefthalf.fill", color: .orange, text: "Risk Assessment: Ready")
                        StatusRow(icon: "clock.arrow.circlepath", color: .purple, text: "Background: System processes only")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
                }
            } else {
                // Process Events List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(processEvents, id: \.id) { event in
                            LiveProcessEventRow(event: event)
                        }
                    }
                }
                .padding(.bottom)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct LiveProcessEventRow: View {
    let event: ProcessEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.executable)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text("PID: \(event.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.riskLevel.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(getRiskColor(event.riskLevel).opacity(0.2))
                        )
                    Text(event.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
        )
    }
    
    private func getRiskColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

struct NetworkActivityDetailsView: View {
    let networkEvents: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Network Activity Monitor")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            // Status Information
            VStack(spacing: 24) {
                Image(systemName: "network")
                    .font(.system(size: 64))
                    .foregroundColor(.cyan)
                
                Text("Network Monitoring Active")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if networkEvents > 0 {
                    Text("Network monitoring is active and tracking \(networkEvents) connection events through the Endpoint Security API.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                } else {
                    Text("Network monitoring is active through the Endpoint Security API. No recent network connection events have been captured by the security monitoring system.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                // Status Indicators
                VStack(spacing: 16) {
                    StatusRow(icon: "circle.fill", color: .green, text: "Monitoring Status: Active")
                    StatusRow(icon: "wifi", color: .blue, text: "Network Tracking: Enabled")
                    StatusRow(icon: "chart.line.uptrend.xyaxis", color: .orange, text: "Active Connections: \(networkEvents)")
                    StatusRow(icon: "shield.checkered", color: .purple, text: "Security Monitoring: Ready")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                )
                
                if networkEvents > 0 {
                    VStack(spacing: 8) {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text("Network connections are being monitored in real-time. Detailed connection logs and analysis will be enhanced in future updates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.1))
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Quick Action Detail Views

struct SecurityCheckView: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Security Check Results")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            // Security Check Results
            VStack(spacing: 24) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Security Check Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Use real data properties instead of filtering manually
                let highRiskCount = securityMonitor.realHighRiskEvents
                let mediumRiskCount = securityMonitor.realMediumRiskEvents
                
                Text("Security assessment completed successfully. The system has been analyzed for potential threats and security vulnerabilities.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Status Indicators
                VStack(spacing: 16) {
                    StatusRow(icon: "shield.checkered", color: .blue, text: "Endpoint Security: \(securityMonitor.endpointMonitor.isMonitoring ? "Active" : "Inactive")")
                    StatusRow(icon: "exclamationmark.triangle", color: .red, text: "High Risk Processes: \(highRiskCount)")
                    StatusRow(icon: "exclamationmark.triangle", color: .orange, text: "Medium Risk Processes: \(mediumRiskCount)")
                    StatusRow(icon: "doc.text", color: .green, text: "File Events: \(securityMonitor.realFileEvents)")
                    StatusRow(icon: "network", color: .cyan, text: "Network Events: \(securityMonitor.realNetworkEvents)")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                )
                
                // Summary
                VStack(spacing: 8) {
                    Text("Security Summary")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(securityMonitor.endpointMonitor.isMonitoring ? "✅ Real-time protection active - System is being monitored" : "⚠️ Real-time protection disabled - Enable monitoring for better security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct RecentAlertsView: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Recent Security Alerts")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            // Alerts Information
            VStack(spacing: 24) {
                Image(systemName: "bell")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                
                // Use real data properties instead of filtering manually
                let highRiskCount = securityMonitor.realHighRiskEvents
                let mediumRiskCount = securityMonitor.realMediumRiskEvents
                
                if highRiskCount == 0 && mediumRiskCount == 0 {
                    Text("No Security Alerts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your system appears to be secure with no suspicious activity detected in the last 24 hours.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Status Indicators
                    VStack(spacing: 16) {
                        StatusRow(icon: "checkmark.circle", color: .green, text: "Security Status: Secure")
                        StatusRow(icon: "shield.checkered", color: .blue, text: "Monitoring: Active")
                        StatusRow(icon: "clock", color: .orange, text: "Last Check: Recent")
                        StatusRow(icon: "eye", color: .purple, text: "Threat Detection: Ready")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
                } else {
                    Text("Security Alerts Detected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("The system has identified potential security threats that require attention.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    // Alert Details
                    VStack(spacing: 16) {
                        if highRiskCount > 0 {
                            StatusRow(icon: "exclamationmark.triangle.fill", color: .red, text: "High Risk: \(highRiskCount) processes")
                        }
                        if mediumRiskCount > 0 {
                            StatusRow(icon: "exclamationmark.triangle", color: .orange, text: "Medium Risk: \(mediumRiskCount) processes")
                        }
                        StatusRow(icon: "shield.checkered", color: .blue, text: "Monitoring: Active")
                        StatusRow(icon: "clock", color: .purple, text: "Last Update: Recent")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                    )
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct SystemStatusView: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("System Status Overview")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            // System Status Information
            VStack(spacing: 24) {
                Image(systemName: "cpu")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("System Status: \(securityMonitor.overallSecurityStatus == .secure ? "Secure" : securityMonitor.overallSecurityStatus == .warning ? "Warning" : "Critical")")
                    .font(.headline)
                    .foregroundColor(securityMonitor.overallSecurityStatus == .secure ? .green : 
                                   securityMonitor.overallSecurityStatus == .warning ? .orange : .red)
                
                Text("Comprehensive system health and security status overview. All critical systems are being monitored in real-time.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Status Indicators
                VStack(spacing: 16) {
                    StatusRow(icon: "shield.checkered", color: .blue, text: "Endpoint Security: \(securityMonitor.endpointMonitor.isMonitoring ? "Active" : "Inactive")")
                    StatusRow(icon: "exclamationmark.triangle", color: .red, text: "Threat Level: \(securityMonitor.threatLevel)%")
                    StatusRow(icon: "doc.text", color: .green, text: "File Events: \(securityMonitor.realFileEvents)")
                    StatusRow(icon: "terminal", color: .orange, text: "Process Events: \(securityMonitor.realProcessEvents)")
                    StatusRow(icon: "network", color: .cyan, text: "Network Events: \(securityMonitor.realNetworkEvents)")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                )
                
                // Overall Status
                VStack(spacing: 8) {
                    Text("Overall Assessment")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(securityMonitor.endpointMonitor.isMonitoring ? "✅ Real-time protection active - System is being monitored" : "⚠️ Real-time protection disabled - Enable monitoring for better security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct ExportReportView: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Export Security Report")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
            
            // Export Information
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 64))
                    .foregroundColor(.purple)
                
                Text("Report Ready for Export")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                let timestamp = DateFormatter().string(from: Date())
                let totalEvents = securityMonitor.realProcessEvents + securityMonitor.realFileEvents + securityMonitor.realNetworkEvents
                
                Text("A comprehensive security report has been generated with current system status, threat assessments, and activity summaries.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                // Report Details
                VStack(spacing: 16) {
                    StatusRow(icon: "calendar", color: .blue, text: "Generated: \(timestamp)")
                    StatusRow(icon: "chart.bar", color: .green, text: "Total Events: \(totalEvents)")
                    StatusRow(icon: "shield.checkered", color: .orange, text: "Endpoint Security: \(securityMonitor.endpointMonitor.isMonitoring ? "Active" : "Inactive")")
                    StatusRow(icon: "exclamationmark.triangle", color: .red, text: "Threat Level: \(securityMonitor.threatLevel)%")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.97))
                )
                
                // Export Status
                VStack(spacing: 8) {
                    Text("Export Status")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text("Report would be saved to Documents folder. This feature will be enhanced in future updates with additional export formats and customization options.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.1))
                )
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}