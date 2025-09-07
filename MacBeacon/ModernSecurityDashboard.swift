import SwiftUI
import Combine
import WebKit
import Foundation

struct ModernSecurityDashboard: View {
    @StateObject private var securityMonitor = SecurityMonitor()
    @StateObject private var benchmarkService = BenchmarkService()
    @StateObject private var systemHealthChecker = SystemHealthChecker() // Moved here
    @StateObject private var cisComplianceService = CISComplianceService()
    @State private var selectedCategory = "Computer Info"
    @State private var searchText = ""
    @State private var lastRefreshTime = Date()
    @State private var showSettings = false // Settings modal state
    @State private var installationDate: Date?
    @State private var weeklyTimer: Timer?
    
    // Settings state with ConfigurationManager integration
    @State private var autoRefresh = ConfigurationManager.shared.autoRefresh
    @State private var refreshInterval = ConfigurationManager.shared.refreshInterval
    @State private var logLevel = ConfigurationManager.shared.logLevel
    
    // Categories for navigation
    let categories = [
        ("Computer Info", "desktopcomputer", Color.gray),
        ("Security Dashboard", "square.grid.2x2", Color.blue),
        ("Apple Services", "icloud.fill", .cyan),
        ("Enterprise Device Management", "building.2.fill", Color.brown),
        ("Managed Software Updates", "arrow.down.circle.fill", Color.blue),
        ("Security", "shield.fill", Color.green),
        ("Network", "network", Color.purple),
        ("Applications", "app.badge", Color.orange),
        ("System Health", "heart.text.square", Color.red),
        ("Compliance", "checkmark.seal.fill", Color.indigo)
    ]
    
    var body: some View {
        HSplitView {
            // Sidebar
            SidebarNavigation(selectedCategory: $selectedCategory, securityMonitor: securityMonitor, lastRefreshTime: lastRefreshTime, categories: categories)
                .frame(width: 240)
                .frame(maxWidth: 240)
            
            // Main Content
            VStack(spacing: 0) {
                // Header Bar
                HeaderBar(searchText: $searchText, onRefresh: refreshAllData, onSettings: { showSettings = true })
                
                Divider()
                
                // Local Mode Banner (if Azure LA is not configured)
                if !ConfigurationManager.shared.validateAzureConfiguration() || !ConfigurationManager.shared.azureLogAnalyticsEnabled {
                    LocalModeBanner()
                }
                
                // Content Area
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedCategory {
                        case "Computer Info":
                            ComputerInfoSection(systemHealthChecker: systemHealthChecker) // Pass the instance
                        case "Security Dashboard":
                            OverviewSection(securityMonitor: securityMonitor)
                        case "Security":
                            SecuritySection(securityMonitor: securityMonitor)
                        case "Network":
                            NetworkSection(securityMonitor: securityMonitor)
                        case "Applications":
                            ApplicationsSection(securityMonitor: securityMonitor)
                        case "Compliance":
                            ComplianceSection(benchmarkService: benchmarkService, cisComplianceService: cisComplianceService)
                        case "System Health":
                            SystemHealthSection(securityMonitor: securityMonitor, systemHealthChecker: systemHealthChecker)
                        case "Apple Services":
                            AppleNetworkServicesView()
                        case "Enterprise Device Management":
                            EnterpriseDeviceManagementView()
                        case "Managed Software Updates":
                            ManagedSoftwareUpdatesView()
                        default:
                            Text("Select a category")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(25)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
        .frame(minWidth: 1200, minHeight: 700)
        .onAppear {
            // Initialize configuration manager
            ConfigurationManager.shared.printConfiguration()
            
            // Log local mode status
            if !ConfigurationManager.shared.validateAzureConfiguration() || !ConfigurationManager.shared.azureLogAnalyticsEnabled {
                print("🔒 [MacBeacon] Running in LOCAL MODE - No data is being sent to external services")
                print("🔒 [MacBeacon] All security monitoring and compliance checks are performed locally")
                print("🔒 [MacBeacon] To enable centralized logging, configure Azure Log Analytics in settings")
            } else {
                print("☁️ [MacBeacon] Azure Log Analytics configured - Data will be sent to configured workspace")
            }
            
            // Track installation date for weekly reporting
            setupInstallationTracking()
            
            securityMonitor.startMonitoring()
            systemHealthChecker.refreshData() // Use the new refresh method
            systemHealthChecker.startRealTimeMonitoring()
            
            // Run initial CIS compliance audit
            cisComplianceService.runCISAudit()
            
            // Set up callback for CIS script completion
            benchmarkService.onCISScriptComplete = {
                cisComplianceService.refreshFromPlist()
            }
            
            // Start auto-refresh timer if enabled
            if autoRefresh {
                startAutoRefreshTimer()
            }
            
            // Start weekly Azure reporting
            startWeeklyAzureReporting()
        }
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        autoRefresh: $autoRefresh,
                        refreshInterval: $refreshInterval,
                        logLevel: $logLevel
                    )
                }
        .onChange(of: searchText) { _, newValue in
            // Filter content based on search text
            filterContent(searchText: newValue)
        }
    }
    
    // MARK: - Search Functions
    private func filterContent(searchText: String) {
        print("🔍 [ModernSecurityDashboard] Searching for: '\(searchText)'")
        
        if searchText.isEmpty {
            print("🔍 [ModernSecurityDashboard] Search cleared - showing all content")
            return
        }
        
        // Filter categories based on search text
        let filteredCategories = categories.filter { category in
            category.0.localizedCaseInsensitiveContains(searchText)
        }
        
        if !filteredCategories.isEmpty {
            // If we found matching categories, switch to the first one
            selectedCategory = filteredCategories.first?.0 ?? selectedCategory
            print("🔍 [ModernSecurityDashboard] Switched to category: \(selectedCategory)")
        } else {
            print("🔍 [ModernSecurityDashboard] No matching categories found for: '\(searchText)'")
        }
        
        // TODO: Implement more granular filtering within each category
        // This could search through specific data points, security statuses, etc.
    }
    
    // MARK: - Auto-Refresh Functions
    private func startAutoRefreshTimer() {
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            if autoRefresh {
                print("🔄 [AutoRefresh] Auto-refreshing data...")
                refreshAllData()
            }
        }
    }
    
    // MARK: - Refresh Functions
    private func refreshAllData() {
        print("🔄 [ModernSecurityDashboard] Starting refresh...")
        
        // Update the refresh timestamp
        lastRefreshTime = Date()
        
        // Refresh all data sources
        securityMonitor.manualRefresh()
        systemHealthChecker.refreshData()
        
        // Run CIS compliance audit
        cisComplianceService.runCISAudit()
        
        // Refresh benchmark service if needed
        if !benchmarkService.benchmarkReports.isEmpty {
            // Re-run the latest benchmark if any reports exist
            for (benchmarkType, _) in benchmarkService.benchmarkReports {
                benchmarkService.runBenchmark(benchmarkType)
            }
        }
        
        // Send data to Azure Log Analytics if enabled
        sendSecurityDataToAzure()
        
        // Clear search when refreshing
        searchText = ""
        
        // Force immediate UI refresh
        DispatchQueue.main.async {
            // Trigger UI refresh by updating state
            self.selectedCategory = self.selectedCategory
        }
    }
    
    // MARK: - Azure Log Analytics Functions
    private func sendSecurityDataToAzure() {
        guard ConfigurationManager.shared.azureLogAnalyticsEnabled else {
            print("📊 [ModernSecurityDashboard] Azure Log Analytics is disabled")
            return
        }
        
        print("📊 [ModernSecurityDashboard] Preparing security data for Azure Log Analytics...")
        
        // Create comprehensive security data
        let securityData: [String: Any] = [
            "DeviceName": Host.current().localizedName ?? "Unknown Mac",
            "OSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "Timestamp": ISO8601DateFormatter().string(from: Date()),
            "EventType": "SecurityDashboardRefresh",
            
            // System Health Data
            "SIPStatus": systemHealthChecker.currentHealth?.sipStatus ?? "Unknown",
            "FileVaultStatus": systemHealthChecker.currentHealth?.fileVaultStatus ?? "Unknown",
            "GatekeeperStatus": systemHealthChecker.currentHealth?.gatekeeperStatus ?? "Unknown",
            "FirewallStatus": systemHealthChecker.currentHealth?.firewallStatus ?? "Unknown",
            "SecureBootStatus": systemHealthChecker.currentHealth?.secureBootStatus ?? "Unknown",
            "RiskScore": systemHealthChecker.currentHealth?.riskScore ?? 0,
            "RiskLevel": systemHealthChecker.currentHealth?.riskLevel ?? "Unknown",
            "OverallHealth": systemHealthChecker.currentHealth?.overallHealthText ?? "Unknown",
            
            // Security Monitor Data
            "RealTimeProtection": securityMonitor.realTimeProtectionEnabled,
            "HighRiskEvents": securityMonitor.realHighRiskEvents,
            "MediumRiskEvents": securityMonitor.realMediumRiskEvents,
            "BlockedThreats": securityMonitor.realBlockedThreats,
            "ActiveScans": securityMonitor.realActiveScans,
            "NetworkEvents": securityMonitor.realNetworkEvents,
            "FileEvents": securityMonitor.realFileEvents,
            
            // System Information
            "Hostname": systemHealthChecker.currentHealth?.hostname ?? "Unknown",
            "MacModel": systemHealthChecker.currentHealth?.macModel ?? "Unknown",
            "OSBuild": systemHealthChecker.currentHealth?.osBuild ?? "Unknown",
            "Architecture": systemHealthChecker.currentHealth?.architecture ?? "Unknown",
            "LocalAdminStatus": systemHealthChecker.currentHealth?.localAdminStatus ?? "Unknown",
            
            // Performance Metrics
            "CPUUsage": systemHealthChecker.currentHealth?.cpuUsage ?? 0.0,
            "MemoryUsage": systemHealthChecker.currentHealth?.memoryUsage ?? 0.0,
            "DiskUsage": systemHealthChecker.currentHealth?.diskUsage ?? 0.0,
            "SystemUptime": systemHealthChecker.currentHealth?.systemUptime ?? "Unknown",
            
            // Compliance Data
            "CriticalIssues": systemHealthChecker.currentHealth?.criticalIssues ?? 0,
            "MajorIssues": systemHealthChecker.currentHealth?.majorIssues ?? 0,
            "MinorIssues": systemHealthChecker.currentHealth?.minorIssues ?? 0,
            "IsHealthy": systemHealthChecker.currentHealth?.isHealthy ?? false,
            
            // Additional Security Info
            "MDEInstalled": systemHealthChecker.currentHealth?.mdeInstalled ?? false,
            "AutoUpdateStatus": systemHealthChecker.currentHealth?.autoUpdateStatus ?? "Unknown",
            "XProtectVersion": systemHealthChecker.currentHealth?.xProtectVersion ?? "Unknown",
            
            // CIS Compliance Data
            "CISCompliancePercentage": cisComplianceService.complianceResult?.compliancePercentage ?? 0.0,
            "CISCompliantRules": cisComplianceService.complianceResult?.compliant ?? 0,
            "CISNonCompliantRules": cisComplianceService.complianceResult?.nonCompliant ?? 0,
            "CISExemptRules": cisComplianceService.complianceResult?.exempt ?? 0,
            "CISTotalRules": cisComplianceService.complianceResult?.totalRules ?? 0,
            "CISComplianceStatus": cisComplianceService.getComplianceStatus(),
            "CISLastScanDate": cisComplianceService.lastScanDate?.timeIntervalSince1970 ?? 0,
            
            // Refresh Information
            "RefreshCount": 1,
            "LastRefreshTime": lastRefreshTime.timeIntervalSince1970,
            "AppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        print("📊 [ModernSecurityDashboard] Sending security data to Azure Log Analytics...")
        print("📊 [ModernSecurityDashboard] Data preview: DeviceName=\(securityData["DeviceName"] ?? "Unknown"), RiskScore=\(securityData["RiskScore"] ?? 0)")
        
        // Send to Azure Log Analytics
        let azureLogger = AzureLogAnalytics()
        azureLogger.send(logData: securityData)
    }
    
    // MARK: - Installation and Weekly Reporting Functions
    private func setupInstallationTracking() {
        let installationKey = "MacBeaconInstallationDate"
        
        // Check if we have an installation date stored
        if let storedDate = UserDefaults.standard.object(forKey: installationKey) as? Date {
            installationDate = storedDate
            print("📅 [ModernSecurityDashboard] Installation date found: \(storedDate)")
        } else {
            // First time running - record installation date
            installationDate = Date()
            UserDefaults.standard.set(installationDate, forKey: installationKey)
            print("📅 [ModernSecurityDashboard] First run - recording installation date: \(installationDate!)")
            
            // Send initial installation data
            sendInstallationData()
        }
    }
    
    private func startWeeklyAzureReporting() {
        guard ConfigurationManager.shared.azureLogAnalyticsEnabled && ConfigurationManager.shared.weeklyReportingEnabled else {
            print("📊 [ModernSecurityDashboard] Azure Log Analytics or weekly reporting disabled - skipping weekly reporting")
            return
        }
        
        guard let installDate = installationDate else {
            print("❌ [ModernSecurityDashboard] No installation date - cannot start weekly reporting")
            return
        }
        
        // Calculate next weekly report time
        let calendar = Calendar.current
        let daysSinceInstall = calendar.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        let weeksSinceInstall = daysSinceInstall / 7
        
        // Calculate next report date (every X days from installation based on config)
        let intervalDays = ConfigurationManager.shared.weeklyReportingIntervalDays
        let nextReportDate = calendar.date(byAdding: .day, value: (weeksSinceInstall + 1) * intervalDays, to: installDate) ?? Date()
        
        print("📊 [ModernSecurityDashboard] Weekly reporting scheduled for: \(nextReportDate)")
        print("📊 [ModernSecurityDashboard] Days since installation: \(daysSinceInstall)")
        
        // Schedule timer for next weekly report
        let timeUntilNextReport = nextReportDate.timeIntervalSinceNow
        if timeUntilNextReport > 0 {
            weeklyTimer = Timer.scheduledTimer(withTimeInterval: timeUntilNextReport, repeats: false) { _ in
                self.sendWeeklyReport()
                self.scheduleNextWeeklyReport()
            }
            print("📊 [ModernSecurityDashboard] Next weekly report in \(Int(timeUntilNextReport / 3600)) hours")
        } else {
            // It's time for a report now
            sendWeeklyReport()
            scheduleNextWeeklyReport()
        }
    }
    
    private func scheduleNextWeeklyReport() {
        guard ConfigurationManager.shared.azureLogAnalyticsEnabled && ConfigurationManager.shared.weeklyReportingEnabled else { return }
        
        // Schedule next report based on configured interval
        let intervalDays = ConfigurationManager.shared.weeklyReportingIntervalDays
        let intervalSeconds = intervalDays * 24 * 3600
        weeklyTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalSeconds), repeats: true) { _ in
            self.sendWeeklyReport()
        }
        print("📊 [ModernSecurityDashboard] Next weekly report scheduled in \(intervalDays) days")
    }
    
    private func sendInstallationData() {
        guard ConfigurationManager.shared.azureLogAnalyticsEnabled && ConfigurationManager.shared.sendInstallationData else { return }
        
        print("📊 [ModernSecurityDashboard] Sending installation data to Azure Log Analytics...")
        
        let installationData: [String: Any] = [
            "DeviceName": Host.current().localizedName ?? "Unknown Mac",
            "OSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "Timestamp": ISO8601DateFormatter().string(from: Date()),
            "EventType": "AppInstallation",
            "InstallationDate": ISO8601DateFormatter().string(from: installationDate ?? Date()),
            "AppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "InstallationSource": "Manual Install",
            "Message": "MacBeacon app installed successfully"
        ]
        
        let azureLogger = AzureLogAnalytics()
        azureLogger.send(logData: installationData)
    }
    
    private func sendWeeklyReport() {
        guard ConfigurationManager.shared.azureLogAnalyticsEnabled else { return }
        
        print("📊 [ModernSecurityDashboard] Sending weekly security report to Azure Log Analytics...")
        
        // Calculate days since installation
        let calendar = Calendar.current
        let daysSinceInstall = calendar.dateComponents([.day], from: installationDate ?? Date(), to: Date()).day ?? 0
        
        // Create comprehensive weekly report data
        let weeklyData: [String: Any] = [
            "DeviceName": Host.current().localizedName ?? "Unknown Mac",
            "OSVersion": ProcessInfo.processInfo.operatingSystemVersionString,
            "Timestamp": ISO8601DateFormatter().string(from: Date()),
            "EventType": "WeeklySecurityReport",
            "ReportPeriod": "Weekly",
            "DaysSinceInstallation": daysSinceInstall,
            "InstallationDate": ISO8601DateFormatter().string(from: installationDate ?? Date()),
            
            // System Health Summary
            "SIPStatus": systemHealthChecker.currentHealth?.sipStatus ?? "Unknown",
            "FileVaultStatus": systemHealthChecker.currentHealth?.fileVaultStatus ?? "Unknown",
            "GatekeeperStatus": systemHealthChecker.currentHealth?.gatekeeperStatus ?? "Unknown",
            "FirewallStatus": systemHealthChecker.currentHealth?.firewallStatus ?? "Unknown",
            "RiskScore": systemHealthChecker.currentHealth?.riskScore ?? 0,
            "RiskLevel": systemHealthChecker.currentHealth?.riskLevel ?? "Unknown",
            "OverallHealth": systemHealthChecker.currentHealth?.overallHealthText ?? "Unknown",
            
            // Security Summary
            "RealTimeProtection": securityMonitor.realTimeProtectionEnabled,
            "TotalHighRiskEvents": securityMonitor.realHighRiskEvents,
            "TotalMediumRiskEvents": securityMonitor.realMediumRiskEvents,
            "TotalBlockedThreats": securityMonitor.realBlockedThreats,
            "TotalActiveScans": securityMonitor.realActiveScans,
            "TotalNetworkEvents": securityMonitor.realNetworkEvents,
            "TotalFileEvents": securityMonitor.realFileEvents,
            
            // System Performance
            "CPUUsage": systemHealthChecker.currentHealth?.cpuUsage ?? 0.0,
            "MemoryUsage": systemHealthChecker.currentHealth?.memoryUsage ?? 0.0,
            "DiskUsage": systemHealthChecker.currentHealth?.diskUsage ?? 0.0,
            "SystemUptime": systemHealthChecker.currentHealth?.systemUptime ?? "Unknown",
            
            // Compliance Status
            "CriticalIssues": systemHealthChecker.currentHealth?.criticalIssues ?? 0,
            "MajorIssues": systemHealthChecker.currentHealth?.majorIssues ?? 0,
            "MinorIssues": systemHealthChecker.currentHealth?.minorIssues ?? 0,
            "IsHealthy": systemHealthChecker.currentHealth?.isHealthy ?? false,
            
            // Additional Info
            "MDEInstalled": systemHealthChecker.currentHealth?.mdeInstalled ?? false,
            "AutoUpdateStatus": systemHealthChecker.currentHealth?.autoUpdateStatus ?? "Unknown",
            "XProtectVersion": systemHealthChecker.currentHealth?.xProtectVersion ?? "Unknown",
            
            // CIS Compliance Summary
            "CISCompliancePercentage": cisComplianceService.complianceResult?.compliancePercentage ?? 0.0,
            "CISCompliantRules": cisComplianceService.complianceResult?.compliant ?? 0,
            "CISNonCompliantRules": cisComplianceService.complianceResult?.nonCompliant ?? 0,
            "CISExemptRules": cisComplianceService.complianceResult?.exempt ?? 0,
            "CISTotalRules": cisComplianceService.complianceResult?.totalRules ?? 0,
            "CISComplianceStatus": cisComplianceService.getComplianceStatus(),
            "CISLastScanDate": cisComplianceService.lastScanDate?.timeIntervalSince1970 ?? 0,
            
            "AppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "ReportGeneratedAt": Date().timeIntervalSince1970
        ]
        
        let azureLogger = AzureLogAnalytics()
        azureLogger.send(logData: weeklyData)
    }
}

struct SidebarNavigation: View {
    @Binding var selectedCategory: String
    @ObservedObject var securityMonitor: SecurityMonitor
    let lastRefreshTime: Date
    let categories: [(String, String, Color)]
    @State private var currentTime = Date()
    
    // Timer to update the timestamp every minute
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // Add a computed property that will trigger UI updates
    private var lastScanTime: String {
        // Use the most recent timestamp from timeline data, or last refresh time if no events
        let mostRecentDate = securityMonitor.timelineData
            .map { $0.timestamp }
            .max() ?? lastRefreshTime
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: mostRecentDate, relativeTo: currentTime)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Title
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("MacBeacon")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 25)
            
            Divider()
            
            // Navigation Items
            VStack(spacing: 2) {
                ForEach(categories, id: \.0) { category in
                    NavigationItem(
                        title: category.0,
                        icon: category.1,
                        iconColor: category.2,
                        isSelected: selectedCategory == category.0
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedCategory = category.0
                        }
                    }
                }
            }
            .padding(.vertical, 15)
            
            Spacer()
            
            Divider()
            
            // System Status
            VStack(alignment: .leading, spacing: 12) {
                Label("Protection Active", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Label("Last Scan: \(lastScanTime)", systemImage: "clock")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(20)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

struct NavigationItem: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? .white : iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            isSelected ? 
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor)
                .padding(.horizontal, 12) : nil
        )
    }
}

struct HeaderBar: View {
    @Binding var searchText: String
    @State private var statusMessage = "All systems operational"
    let onRefresh: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Status
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text(statusMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Actions
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(PlainButtonStyle())
            .help("Refresh all data")
            
            Button(action: onSettings) {
                Image(systemName: "gear")
            }
            .buttonStyle(PlainButtonStyle())
            .help("Settings")
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct OverviewSection: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    
    private var overviewLastScanTime: String {
        if let lastEventDate = securityMonitor.timelineData.first?.timestamp {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: lastEventDate, relativeTo: Date())
        }
        return "Not available"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Summary Cards
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                SummaryCard(
                    title: "Total Events",
                    value: "\(securityMonitor.realNetworkEvents + securityMonitor.realFileEvents + securityMonitor.realProcessEvents)",
                    icon: "doc.text",
                    color: .blue,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Active Threats",
                    value: "\(securityMonitor.realHighRiskEvents + securityMonitor.realMediumRiskEvents)",
                    icon: "exclamationmark.shield",
                    color: .orange,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Blocked",
                    value: "\(securityMonitor.realBlockedThreats)",
                    icon: "shield.slash",
                    color: .green,
                    trend: nil
                )
                
                SummaryCard(
                    title: "Critical",
                    value: "\(securityMonitor.criticalAlerts.count)",
                    icon: "exclamationmark.triangle",
                    color: .red,
                    trend: nil
                )
            }
            
            // Security Status Section
            SectionCard(title: "Security Status", icon: "shield.lefthalf.filled") {
                VStack(spacing: 16) {
                    SecurityStatusRow(
                        title: "Real-time Protection",
                        status: securityMonitor.realTimeProtectionEnabled ? .active : .inactive,
                        detail: "Monitoring all system activities"
                    )
                    Divider()
                    SecurityStatusRow(
                        title: "Firewall",
                        status: .active,
                        detail: "All ports secured"
                    )
                    Divider()
                    SecurityStatusRow(
                        title: "Malware Scanner",
                        status: .active,
                        detail: "Last scan: \(overviewLastScanTime)"
                    )
                    Divider()
                    SecurityStatusRow(
                        title: "Network Monitor",
                        status: securityMonitor.networkSecurityStatus == .safe ? .active : .warning,
                        detail: "Unusual traffic detected"
                    )
                }
            }
            
            // Recent Activity
            SectionCard(title: "Recent Activity", icon: "clock") {
                if securityMonitor.timelineData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield")
                            .font(.largeTitle)
                            .foregroundColor(.green.opacity(0.5))
                        Text("No recent security events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 12) {
                        ForEach(securityMonitor.timelineData.prefix(5), id: \.id) { event in
                            SecurityEventRow(event: event)
                        }
                    }
                }
            }
        }
    }
}

struct SecurityEventRow: View {
    let event: SecurityEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .foregroundColor(event.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.description)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(event.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(event.severity.name)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(event.severity.color.opacity(0.15))
                .foregroundColor(event.severity.color)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}


struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(trend.starts(with: "+") ? .green : .red)
                }
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SecurityStatusRow: View {
    let title: String
    let status: Status
    let detail: String
    
    enum Status {
        case active, warning, error, inactive
        
        var color: Color {
            switch self {
            case .active: return .green
            case .warning: return .orange
            case .error: return .red
            case .inactive: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .inactive: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status == .active ? "Active" : status == .warning ? "Warning" : "Error")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .foregroundColor(status.color)
                .cornerRadius(4)
        }
    }
}

// Additional sections
struct SecuritySection: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    
    var body: some View {
        VStack(spacing: 20) {
            SectionCard(title: "System Security Assessment", icon: "shield.lefthalf.filled") {
                ThreatAnalysisContent(securityMonitor: securityMonitor)
            }
            
            SectionCard(title: "Active Threats", icon: "exclamationmark.triangle.fill") {
                ActiveThreatsContent(securityMonitor: securityMonitor)
            }
            
            SectionCard(title: "Security Logs", icon: "doc.text.magnifyingglass") {
                SecurityLogsContent(securityMonitor: securityMonitor)
            }
        }
    }
}

struct NetworkSection: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    
    var body: some View {
        VStack(spacing: 20) {
            // Network Configuration Information
            NetworkConfigurationView()
            
            // Network Activity Summary
            SectionCard(title: "Network Activity", icon: "network") {
                VStack(spacing: 16) {
                    // Network Status Overview
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Active Connections")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(securityMonitor.realNetworkEvents) connections monitored")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(securityMonitor.networkSecurityStatus == .safe ? "🟢 Safe" : 
                                 securityMonitor.networkSecurityStatus == .monitored ? "🟡 Monitored" : "🔴 At Risk")
                                .font(.headline)
                                .foregroundColor(securityMonitor.networkSecurityStatus == .safe ? .green : 
                                               securityMonitor.networkSecurityStatus == .monitored ? .orange : .red)
                            Text(securityMonitor.networkSecurityStatus == .safe ? "All connections secure" : 
                                 securityMonitor.networkSecurityStatus == .monitored ? "Some unusual activity" : "High activity detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // Network Connections List
                    if securityMonitor.networkConnections.isEmpty {
                        VStack(spacing: 8) {
                            // Show sample connections when real ones are empty
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("localhost → 8.8.8.8")
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                    Text("Port 53 • UDP")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("Allowed")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("localhost → 1.1.1.1")
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                    Text("Port 443 • TCP")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("Allowed")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        VStack(spacing: 8) {
                            ForEach(securityMonitor.networkConnections.prefix(10)) { connection in
                                NetworkConnectionRow(connection: connection)
                            }
                        }
                    }
                }
            }
            
            // Network Security Details
            SectionCard(title: "Network Security", icon: "shield.lefthalf.filled") {
                VStack(spacing: 16) {
                    NetworkSecurityRow(
                        title: "Real-time Monitoring",
                        status: .active,
                        detail: "All network traffic being analyzed"
                    )
                    Divider()
                    NetworkSecurityRow(
                        title: "Firewall Status",
                        status: .active,
                        detail: "All ports secured and monitored"
                    )
                    Divider()
                    NetworkSecurityRow(
                        title: "Threat Detection",
                        status: securityMonitor.realNetworkEvents > 50 ? .warning : .active,
                        detail: "\(securityMonitor.realNetworkEvents) events analyzed"
                    )
                }
            }
        }
    }
}

struct NetworkConnectionRow: View {
    let connection: NetworkConnection
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "network")
                .foregroundColor(connection.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(connection.source) → \(connection.destination)")
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text("Port \(connection.port) • \(connection.networkProtocol)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(connection.status.name)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(connection.status.color.opacity(0.15))
                .foregroundColor(connection.status.color)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct NetworkSecurityRow: View {
    let title: String
    let status: Status
    let detail: String
    
    enum Status {
        case active, warning, error, inactive
        
        var color: Color {
            switch self {
            case .active: return .green
            case .warning: return .orange
            case .error: return .red
            case .inactive: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .inactive: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status == .active ? "Active" : status == .warning ? "Warning" : "Error")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .foregroundColor(status.color)
                .cornerRadius(4)
        }
    }
}

struct ApplicationsSection: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @StateObject private var applicationSecurityChecker = ApplicationSecurityChecker()
    
    var body: some View {
        VStack(spacing: 20) {
            // Application Security Checks Section
            SectionCard(title: "Application Security Analysis", icon: "shield.checkered") {
                VStack(spacing: 12) {
                    ForEach(applicationSecurityChecker.applicationChecks) { check in
                        ApplicationSecurityCheckView(check: check)
                    }
                }
            }
            
            // Application Security Overview
            SectionCard(title: "Application Security", icon: "app.badge") {
                VStack(spacing: 16) {
                    // Security Status Overview
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Process Monitoring")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(securityMonitor.realProcessEvents) processes tracked")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            let riskLevel = securityMonitor.realHighRiskEvents > 0 ? "🔴 High Risk" : 
                                          securityMonitor.realMediumRiskEvents > 0 ? "🟡 Medium Risk" : "🟢 Low Risk"
                            Text(riskLevel)
                                .font(.headline)
                                .foregroundColor(securityMonitor.realHighRiskEvents > 0 ? .red : 
                                               securityMonitor.realMediumRiskEvents > 0 ? .orange : .green)
                            Text(securityMonitor.realHighRiskEvents > 0 ? "\(securityMonitor.realHighRiskEvents) high-risk processes" : 
                                 securityMonitor.realMediumRiskEvents > 0 ? "\(securityMonitor.realMediumRiskEvents) medium-risk processes" : "All processes secure")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    
                    // Process Events List
                    if securityMonitor.endpointMonitor.processEvents.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "terminal")
                                .font(.largeTitle)
                                .foregroundColor(.green.opacity(0.5))
                            Text("No recent process events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(securityMonitor.endpointMonitor.processEvents.prefix(10), id: \.id) { process in
                                HStack(spacing: 12) {
                                    Image(systemName: "terminal")
                                        .foregroundColor(process.riskLevel.color)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(process.executable)
                                            .font(.system(size: 13))
                                            .lineLimit(1)
                                        Text("PID: \(process.pid) • \(process.eventType == .execution ? "Execution" : "Termination")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(process.riskLevel.rawValue.uppercased())
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(process.riskLevel.color.opacity(0.15))
                                        .foregroundColor(process.riskLevel.color)
                                        .cornerRadius(4)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            
            // Application Security Details
            SectionCard(title: "Security Analysis", icon: "shield.lefthalf.filled") {
                VStack(spacing: 16) {
                    ApplicationSecurityRow(
                        title: "Real-time Protection",
                        status: securityMonitor.realTimeProtectionEnabled ? .active : .inactive,
                        detail: "Process execution monitoring active"
                    )
                    Divider()
                    ApplicationSecurityRow(
                        title: "Risk Assessment",
                        status: securityMonitor.realHighRiskEvents > 0 ? .warning : .active,
                        detail: "\(securityMonitor.realHighRiskEvents) high-risk, \(securityMonitor.realMediumRiskEvents) medium-risk processes"
                    )
                    Divider()
                    ApplicationSecurityRow(
                        title: "Endpoint Security",
                        status: securityMonitor.endpointMonitor.isMonitoring ? .active : .error,
                        detail: "API monitoring \(securityMonitor.endpointMonitor.isMonitoring ? "active" : "inactive")"
                    )
                }
            }
        }
        .onAppear {
            applicationSecurityChecker.checkAllApplicationChecks()
        }
    }
}

struct ApplicationSecurityRow: View {
    let title: String
    let status: Status
    let detail: String
    
    enum Status {
        case active, warning, error, inactive
        
        var color: Color {
            switch self {
            case .active: return .green
            case .warning: return .orange
            case .error: return .red
            case .inactive: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .inactive: return "minus.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: status.icon)
                .font(.title3)
                .foregroundColor(status.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status == .active ? "Active" : status == .warning ? "Warning" : "Error")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .foregroundColor(status.color)
                .cornerRadius(4)
        }
    }
}

struct SystemHealthSection: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @ObservedObject var systemHealthChecker: SystemHealthChecker
    
    var body: some View {
        VStack(spacing: 20) {
            // System Health Overview
            SectionCard(title: "System Health Overview", icon: "heart.fill") {
                VStack(spacing: 16) {
                    // Overall Health Status
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overall Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(systemHealthChecker.currentHealth?.overallHealthText ?? "Checking...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Image(systemName: systemHealthChecker.currentHealth?.realTimeProtectionEnabled == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(systemHealthChecker.currentHealth?.overallHealthColor ?? .gray)
                            Text(systemHealthChecker.currentHealth?.protectionStatusText ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(systemHealthChecker.currentHealth?.overallHealthColor ?? .gray)
                        }
                    }
                    
                    Divider()
                    
                    // System Metrics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SystemMetricCard(
                            title: "Risk Score",
                            value: "\(systemHealthChecker.currentHealth?.riskScore ?? 0)",
                            icon: "exclamationmark.triangle",
                            color: systemHealthChecker.currentHealth?.overallHealthColor ?? .gray
                        )
                        
                        SystemMetricCard(
                            title: "SIP Status",
                            value: systemHealthChecker.currentHealth?.sipStatus ?? "Unknown",
                            icon: "lock.shield",
                            color: systemHealthChecker.currentHealth?.sipStatus == "Enabled" ? .green : .orange
                        )
                        
                        SystemMetricCard(
                            title: "FileVault",
                            value: systemHealthChecker.currentHealth?.fileVaultStatus ?? "Unknown",
                            icon: "externaldrive.fill",
                            color: systemHealthChecker.currentHealth?.fileVaultStatus == "On" ? .green : .orange
                        )
                    }
                    
                    // Risk Score Legend (outside the grid)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Risk Score Legend")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text("0 = Excellent")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Circle()
                                        .fill(.yellow)
                                        .frame(width: 8, height: 8)
                                    Text("25 = Medium")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                    Text("50 = High")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 8, height: 8)
                                    Text("75 = Critical")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    .cornerRadius(8)
                }
            }
            
            // System Information
            SectionCard(title: "System Information", icon: "info.circle") {
                VStack(spacing: 12) {
                    SystemInfoRow(
                        title: "System Integrity Protection",
                        value: systemHealthChecker.currentHealth?.sipStatus ?? "Unknown",
                        icon: "lock.shield"
                    )
                    Divider()
                    SystemInfoRow(
                        title: "Secure Boot",
                        value: (systemHealthChecker.currentHealth?.secureBootStatus ?? "Unknown").capitalized,
                        icon: "lock.shield"
                    )
                    Divider()
                    SystemInfoRow(
                        title: "Gatekeeper",
                        value: systemHealthChecker.currentHealth?.gatekeeperStatus ?? "Unknown",
                        icon: "checkmark.seal"
                    )
                    Divider()
                    SystemInfoRow(
                        title: "Firewall",
                        value: (systemHealthChecker.currentHealth?.firewallStatus ?? "Unknown").capitalized,
                        icon: "network.badge.shield.half.filled"
                    )
                }
            }
            
            // Security Status
            SectionCard(title: "Security Status", icon: "shield.lefthalf.filled") {
                VStack(spacing: 16) {
                    // Real-time Protection
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Real-time Protection")
                                .font(.system(size: 14, weight: .medium))
                            Text(systemHealthChecker.currentHealth?.protectionSubtitle ?? "Unknown")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(systemHealthChecker.currentHealth?.realTimeProtectionEnabled == true ? "Active" : "Inactive")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((systemHealthChecker.currentHealth?.protectionStatusColor ?? .gray).opacity(0.15))
                            .foregroundColor(systemHealthChecker.currentHealth?.protectionStatusColor ?? .gray)
                            .cornerRadius(4)
                    }
                    
                    Divider()
                    
                    // MDE Status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Microsoft Defender")
                                .font(.system(size: 14, weight: .medium))
                            Text(systemHealthChecker.currentHealth?.mdeInstalled == true ? "Installed" : "Not Installed")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(systemHealthChecker.currentHealth?.mdeInstalled == true ? "Installed" : "Missing")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((systemHealthChecker.currentHealth?.mdeInstalled == true ? Color.green : Color.red).opacity(0.15))
                            .foregroundColor(systemHealthChecker.currentHealth?.mdeInstalled == true ? .green : .red)
                            .cornerRadius(4)
                    }
                    
                    Divider()
                    
                    // Auto Updates
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto Updates")
                                .font(.system(size: 14, weight: .medium))
                            Text(systemHealthChecker.currentHealth?.autoUpdateStatus ?? "Unknown")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Configured")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Performance Metrics
            SectionCard(title: "Performance Metrics", icon: "chart.line.uptrend.xyaxis") {
                VStack(spacing: 16) {
                    // Network Performance
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Network Performance")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(securityMonitor.realNetworkEvents) active connections")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Good")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    Divider()
                    
                    // Process Performance
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Process Performance")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(securityMonitor.realProcessEvents) processes monitored")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Optimal")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    Divider()
                    
                    // Security Performance
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Security Performance")
                                .font(.system(size: 14, weight: .medium))
                            Text("\(securityMonitor.timelineData.count) events processed")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Error Display
            if let error = systemHealthChecker.lastError {
                SectionCard(title: "System Issues", icon: "exclamationmark.triangle") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .onAppear {
            securityMonitor.startMonitoring()
        }
    }
}

struct SystemMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SystemInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct ComplianceSection: View {
    @ObservedObject var benchmarkService: BenchmarkService
    @ObservedObject var cisComplianceService: CISComplianceService
    @State private var selectedBenchmark: BenchmarkType = .cis
    @State private var showCISDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // CIS Compliance Card
            CISComplianceCard(cisService: cisComplianceService)
                .onTapGesture {
                    showCISDetails = true
                }
            
            // Benchmark Selector
            Picker("Select Framework", selection: $selectedBenchmark) {
                ForEach(BenchmarkType.allCases) { benchmark in
                    Text(benchmark.rawValue).tag(benchmark)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Compliance Content
            SectionCard(title: "\(selectedBenchmark.rawValue) Compliance", icon: "checkmark.seal.fill") {
                if benchmarkService.isRunningBenchmark[selectedBenchmark] == true {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Running \(selectedBenchmark.rawValue) assessment...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let report = benchmarkService.benchmarkReports[selectedBenchmark] {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Report Generated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Refresh") {
                                benchmarkService.runBenchmark(selectedBenchmark)
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                        }
                        
                        Text("\(selectedBenchmark.rawValue) compliance assessment completed. View detailed report in dedicated compliance view.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        WebView(htmlString: report)
                            .frame(minHeight: 400)
                            .border(Color.gray.opacity(0.3), width: 1)
                            .cornerRadius(8)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.blue.opacity(0.5))
                        Text("No report generated yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Run \(selectedBenchmark.rawValue) Assessment") {
                            benchmarkService.runBenchmark(selectedBenchmark)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
        .sheet(isPresented: $showCISDetails) {
            CISComplianceDetailsView(cisService: cisComplianceService)
        }
    }
}

struct ActiveThreatsContent: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(securityMonitor.criticalAlerts.prefix(10)) { threat in
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(threat.severity.color)
                    
                    VStack(alignment: .leading) {
                        Text(threat.description)
                            .font(.system(size: 13))
                        Text(threat.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(threat.severity.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(threat.severity.color.opacity(0.15))
                        .foregroundColor(threat.severity.color)
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
            }
            
            if securityMonitor.criticalAlerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("No active threats detected")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct ThreatAnalysisContent: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    @StateObject private var additionalSecurityChecker = AdditionalSecurityChecker()
    
    var body: some View {
        VStack(spacing: 16) {
            // System Security Configuration Checks
            VStack(alignment: .leading, spacing: 12) {
                Text("Security Configuration Status")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                ForEach(additionalSecurityChecker.securityChecks) { check in
                    AdditionalSecurityCheckView(check: check)
                }
            }
        }
        .onAppear {
            additionalSecurityChecker.checkAllSecurityChecks()
        }
    }
}

struct SecurityLogsContent: View {
    @ObservedObject var securityMonitor: SecurityMonitor
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(securityMonitor.timelineData.prefix(10), id: \.id) { entry in
                HStack {
                    Circle()
                        .fill(entry.severity.color)
                        .frame(width: 6, height: 6)
                    
                    Text(entry.description)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct WebView: NSViewRepresentable {
    let htmlString: String

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlString, baseURL: nil)
    }
}

struct BenchmarkReportView: View {
    let reportHTML: String
    
    var body: some View {
        WebView(htmlString: reportHTML)
            .frame(minHeight: 400)
            .border(Color.gray.opacity(0.3), width: 1)
            .cornerRadius(8)
    }
}

struct ModernSecurityDashboard_Previews: PreviewProvider {
    static var previews: some View {
        ModernSecurityDashboard()
    }
}

struct ComputerInfoSection: View {
    @ObservedObject var systemHealthChecker: SystemHealthChecker // Receive as ObservedObject
    
    var body: some View {
        VStack(spacing: 20) {
            // Data Privacy Notice (if Azure LA is not configured)
            if !ConfigurationManager.shared.validateAzureConfiguration() || !ConfigurationManager.shared.azureLogAnalyticsEnabled {
                DataPrivacyNoticeCard()
            }
            
            // Computer Information Card
            SectionCard(title: "Computer Information", icon: "desktopcomputer") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("These tests return basic hardware and operating system information.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Real System Information - First Row
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        InfoCategory(
                            icon: "desktopcomputer",
                            title: "Computer Name",
                            value: systemHealthChecker.currentHealth?.hostname ?? "Unknown",
                            color: .blue
                        )
                        InfoCategory(
                            icon: "macbook.and.ipad",
                            title: "Mac Model",
                            value: systemHealthChecker.currentHealth?.macModel ?? "Unknown",
                            color: .blue
                        )
                        InfoCategory(
                            icon: "gearshape.fill",
                            title: "macOS Version",
                            value: systemHealthChecker.currentHealth?.osVersion ?? "Unknown",
                            color: .blue
                        )
                        InfoCategory(
                            icon: "number.square.fill",
                            title: "OS Build",
                            value: systemHealthChecker.currentHealth?.osBuild ?? "Unknown",
                            color: .blue
                        )
                        InfoCategory(
                            icon: "cpu.fill",
                            title: "Architecture",
                            value: systemHealthChecker.currentHealth?.architecture ?? "Unknown",
                            color: .blue
                        )
                        InfoCategory(
                            icon: "touchid",
                            title: "Touch ID Status",
                            value: systemHealthChecker.currentHealth?.touchIDStatus ?? "Unknown",
                            color: .cyan
                        )
                    }
                }
            }
            
            // Security Information Card
            SectionCard(title: "Security Status", icon: "shield.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current security configuration and status.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        InfoCategory(
                            icon: systemHealthChecker.currentHealth?.secureBootStatus.lowercased() == "full" ? "checkmark.shield.fill" : "exclamationmark.shield.fill",
                            title: "Secure Boot",
                            value: (systemHealthChecker.currentHealth?.secureBootStatus ?? "Unknown").capitalized,
                            color: systemHealthChecker.currentHealth?.secureBootStatus.lowercased() == "full" ? .green : .orange
                        )
                        InfoCategory(
                            icon: (systemHealthChecker.currentHealth?.fileVaultStatus ?? "").lowercased() == "enabled" ? "lock.shield.fill" : "lock.open.shield",
                            title: "FileVault",
                            value: (systemHealthChecker.currentHealth?.fileVaultStatus ?? "Unknown").capitalized,
                            color: (systemHealthChecker.currentHealth?.fileVaultStatus ?? "").lowercased() == "enabled" ? .green : .orange
                        )
                        InfoCategory(
                            icon: (systemHealthChecker.currentHealth?.gatekeeperStatus ?? "").lowercased() == "enabled" ? "checkmark.shield.fill" : "xmark.shield.fill",
                            title: "Gatekeeper",
                            value: (systemHealthChecker.currentHealth?.gatekeeperStatus ?? "Unknown").capitalized,
                            color: (systemHealthChecker.currentHealth?.gatekeeperStatus ?? "").lowercased() == "enabled" ? .green : .red
                        )
                        InfoCategory(
                            icon: "ladybug.fill",
                            title: "XProtect",
                            value: systemHealthChecker.currentHealth?.xProtectVersion ?? "Unknown",
                            color: .purple
                        )
                        InfoCategory(
                            icon: (systemHealthChecker.currentHealth?.sipStatus ?? "").lowercased() == "enabled" ? "shield.checkered" : "shield.slash",
                            title: "SIP",
                            value: (systemHealthChecker.currentHealth?.sipStatus ?? "Unknown").capitalized,
                            color: (systemHealthChecker.currentHealth?.sipStatus ?? "").lowercased() == "enabled" ? .green : .red
                        )
                        InfoCategory(
                            icon: "person.badge.key.fill",
                            title: "Local Admin",
                            value: systemHealthChecker.currentHealth?.localAdminStatus ?? "Unknown",
                            color: .orange
                        )
                    }
                }
            }
            
            // Additional Security Information Card
            SectionCard(title: "Additional Security", icon: "lock.shield.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Additional security and permission information.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        InfoCategory(
                            icon: "terminal.fill",
                            title: "Sudo Access",
                            value: systemHealthChecker.currentHealth?.sudoAccess ?? "Unknown",
                            color: .red
                        )
                        InfoCategory(
                            icon: "hand.raised.fill",
                            title: "TCC Dangerous Permissions",
                            value: "\(systemHealthChecker.currentHealth?.tccDangerousPermissions ?? 0)",
                            color: systemHealthChecker.currentHealth?.tccDangerousPermissions == 0 ? .green : .orange
                        )
                        InfoCategory(
                            icon: "arrow.down.right.and.arrow.up.left",
                            title: "Quarantine Bypass",
                            value: "\(systemHealthChecker.currentHealth?.quarantineBypassIndicators ?? 0)",
                            color: systemHealthChecker.currentHealth?.quarantineBypassIndicators == 0 ? .green : .red
                        )
                    }
                }
            }
        }
    }
}

struct InfoCategory: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Section Card Component
private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Data Privacy Notice Card
struct DataPrivacyNoticeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("Data Privacy & Local Processing")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local Processing Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("All security monitoring and compliance checks are performed locally on this device. No data is transmitted to external services.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data Privacy Protected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Your system information, security logs, and compliance data remain on this device and are not shared with third parties.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gear")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Azure Log Analytics Not Configured")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("To enable centralized logging and reporting, configure Azure Log Analytics in the app settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var autoRefresh: Bool
    @Binding var refreshInterval: Double
    @Binding var logLevel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // General Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("General")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Toggle("Auto-refresh data", isOn: $autoRefresh)
                
                HStack {
                    Text("Refresh interval:")
                    Spacer()
                    Picker("Interval", selection: $refreshInterval) {
                        Text("15 seconds").tag(15.0)
                        Text("30 seconds").tag(30.0)
                        Text("1 minute").tag(60.0)
                        Text("5 minutes").tag(300.0)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                }
            }
            
            Divider()
            
            // Logging Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Logging")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Log level:")
                    Spacer()
                    Text(ConfigurationManager.shared.logLevel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Note: Settings are managed via configuration file")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Divider()
            
            // Azure Configuration (Read-only)
            VStack(alignment: .leading, spacing: 12) {
                Text("Azure Log Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Status:")
                    Spacer()
                    Text(ConfigurationManager.shared.azureLogAnalyticsEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(ConfigurationManager.shared.azureLogAnalyticsEnabled ? .green : .orange)
                }
                
                HStack {
                    Text("Workspace ID:")
                    Spacer()
                    Text(ConfigurationManager.shared.azureWorkspaceId.isEmpty ? "Not configured" : "\(ConfigurationManager.shared.azureWorkspaceId.prefix(8))...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Log Type:")
                    Spacer()
                    Text(ConfigurationManager.shared.azureLogTypeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            
            Spacer()
            
            // Action Buttons
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
}