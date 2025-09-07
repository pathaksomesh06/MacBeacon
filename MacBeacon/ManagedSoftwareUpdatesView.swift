import SwiftUI

// MARK: - Managed Software Update Service
struct ManagedSoftwareUpdateService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let domain: String
    let key: String
    var status: SoftwareUpdateStatus = .unknown
    var detail: String = ""
    var isManaged: Bool = false

    enum SoftwareUpdateStatus {
        case unknown
        case checking
        case managed
        case unmanaged
        case enabled
        case disabled
    }
}

// MARK: - Managed Software Updates Checker
class ManagedSoftwareUpdatesChecker: ObservableObject {
    @Published var softwareUpdateServices: [ManagedSoftwareUpdateService] = []
    
    init() {
        setupSoftwareUpdateServices()
    }
    
    private func setupSoftwareUpdateServices() {
        softwareUpdateServices = [
            ManagedSoftwareUpdateService(
                name: "Admin Only Software Updates",
                domain: "com.apple.SoftwareUpdate",
                key: "restrict-software-update-require-admin-to-install"
            ),
            ManagedSoftwareUpdateService(
                name: "Automatic App Updates",
                domain: "com.apple.SoftwareUpdate",
                key: "AutomaticallyInstallAppUpdates"
            ),
            ManagedSoftwareUpdateService(
                name: "Automatic Check Settings",
                domain: "com.apple.SoftwareUpdate",
                key: "AutomaticCheckEnabled"
            ),
            ManagedSoftwareUpdateService(
                name: "Automatic Download Settings",
                domain: "com.apple.SoftwareUpdate",
                key: "AutomaticDownload"
            ),
            ManagedSoftwareUpdateService(
                name: "Automatic System Data Files and Security Updates",
                domain: "com.apple.SoftwareUpdate",
                key: "ConfigDataInstall"
            ),
            ManagedSoftwareUpdateService(
                name: "Automatic macOS Updates",
                domain: "com.apple.SoftwareUpdate",
                key: "AutomaticallyInstallMacOSUpdates"
            ),
            ManagedSoftwareUpdateService(
                name: "Beta Software Configuration",
                domain: "com.apple.SoftwareUpdate",
                key: "AllowPreReleaseInstallation"
            ),
            ManagedSoftwareUpdateService(
                name: "Critical Update Installation",
                domain: "com.apple.SoftwareUpdate",
                key: "CriticalUpdateInstall"
            ),
            ManagedSoftwareUpdateService(
                name: "Rapid Security Response Installation",
                domain: "com.apple.applicationaccess",
                key: "allowRapidSecurityResponseInstallation"
            ),
            ManagedSoftwareUpdateService(
                name: "Rapid Security Response Removal",
                domain: "com.apple.applicationaccess",
                key: "allowRapidSecurityResponseRemoval"
            )
        ]
    }
    
    func checkAllSoftwareUpdateServices() {
        print("ManagedSoftwareUpdatesChecker: Starting checkAllSoftwareUpdateServices")
        for (index, _) in softwareUpdateServices.enumerated() {
            checkSoftwareUpdateService(at: index)
        }
    }
    
    private func checkSoftwareUpdateService(at index: Int) {
        print("ManagedSoftwareUpdatesChecker: Checking software update service \(index): \(softwareUpdateServices[index].name)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runCommand(self.softwareUpdateServices[index].domain, key: self.softwareUpdateServices[index].key)
            
            DispatchQueue.main.async {
                self.processSoftwareUpdateResult(for: index, result: result, serviceName: self.softwareUpdateServices[index].name)
            }
        }
    }
    
    private func runCommand(_ domain: String, key: String) -> String {
        let command = "defaults read \(domain) \(key) 2>/dev/null || echo 'Not Set'"
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let outputString = String(data: outputData, encoding: .utf8) {
                return outputString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Error running command: \(command), error: \(error)")
            return "Error: \(error.localizedDescription)"
        }
        
        return "Unknown"
    }
    
    private func processSoftwareUpdateResult(for index: Int, result: String, serviceName: String) {
        print("ManagedSoftwareUpdatesChecker: Processing \(serviceName): \(result)")
        
        var status: ManagedSoftwareUpdateService.SoftwareUpdateStatus
        var detail: String
        var isManaged: Bool
        
        if result == "Not Set" || result.contains("Error") {
            status = .unmanaged
            detail = "Settings are unmanaged"
            isManaged = false
        } else {
            status = .managed
            isManaged = true
            
            // Parse the actual value
            if result.lowercased() == "true" || result == "1" {
                status = .enabled
                detail = "Managed and enabled"
            } else if result.lowercased() == "false" || result == "0" {
                status = .disabled
                detail = "Managed and disabled"
            } else {
                detail = "Managed (value: \(result))"
            }
        }
        
        DispatchQueue.main.async {
            self.softwareUpdateServices[index].status = status
            self.softwareUpdateServices[index].detail = detail
            self.softwareUpdateServices[index].isManaged = isManaged
        }
    }
}

// MARK: - Managed Software Updates View
struct ManagedSoftwareUpdatesView: View {
    @StateObject private var checker = ManagedSoftwareUpdatesChecker()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Managed Software Updates")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Software update management policies and configuration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Managed Software Updates Section
            SectionCard(title: "Managed Software Updates", icon: "arrow.down.circle.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This panel displays software update management policies including automatic updates, admin restrictions, and security update configurations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(checker.softwareUpdateServices) { service in
                            SoftwareUpdateServiceStatusView(service: service)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("ManagedSoftwareUpdatesView appeared - starting service check")
            checker.checkAllSoftwareUpdateServices()
        }
    }
}

// MARK: - Software Update Service Status View
struct SoftwareUpdateServiceStatusView: View {
    let service: ManagedSoftwareUpdateService
    
    private var statusColor: Color {
        switch service.status {
        case .managed, .enabled:
            return .green
        case .unmanaged:
            return .orange
        case .disabled:
            return .red
        case .unknown, .checking:
            return .gray
        }
    }
    
    private var statusIcon: String {
        switch service.status {
        case .managed, .enabled:
            return "checkmark.circle.fill"
        case .unmanaged:
            return "exclamationmark.triangle.fill"
        case .disabled:
            return "xmark.circle.fill"
        case .unknown, .checking:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch service.status {
        case .managed:
            return "Managed"
        case .enabled:
            return "Enabled"
        case .unmanaged:
            return "Unmanaged"
        case .disabled:
            return "Disabled"
        case .unknown, .checking:
            return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(service.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                    
                    Text(service.detail)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(service.domain)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
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

