import SwiftUI

struct NetworkConfigItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: NetworkConfigStatus = .unknown
    var detail: String = ""
    var description: String = ""

    enum NetworkConfigStatus {
        case unknown
        case checking
        case available
        case unavailable
        case modified
        case unmodified
    }
}

class NetworkConfigurationChecker: ObservableObject {
    @Published var configItems: [NetworkConfigItem] = []

    init() {
        setupConfigItems()
    }

    private func setupConfigItems() {
        configItems = [
            NetworkConfigItem(
                name: "DNS",
                command: "system_profiler SPNetworkDataType | grep 'Server Addresses:'",
                description: "DNS server addresses"
            ),
            NetworkConfigItem(
                name: "DNS Name",
                command: "/bin/hostname",
                description: "System hostname"
            ),
            NetworkConfigItem(
                name: "Primary Search Domain",
                command: "system_profiler SPNetworkDataType | grep 'Domain Name:'",
                description: "Primary domain name"
            ),
            NetworkConfigItem(
                name: "Host File",
                command: "ls -l /etc/hosts",
                description: "Host file modification status"
            ),
            NetworkConfigItem(
                name: "Proxy Details",
                command: "system_profiler SPNetworkDataType",
                description: "Network proxy configuration"
            ),
            NetworkConfigItem(
                name: "WiFi Details",
                command: "system_profiler SPAirPortDataType",
                description: "WiFi adapter information"
            ),
            NetworkConfigItem(
                name: "AirDrop",
                command: "system_profiler SPAirPortDataType | grep 'AirDrop:'"
            )
        ]
    }

    func checkAllConfiguration() {
        print("NetworkConfigurationChecker: Starting checkAllConfiguration")
        for i in 0..<configItems.count {
            configItems[i].status = .checking
            print("NetworkConfigurationChecker: Checking item \(i): \(configItems[i].name)")
            checkConfiguration(at: i)
        }
    }

    private func checkConfiguration(at index: Int) {
        let item = configItems[index]
        
        DispatchQueue.global(qos: .background).async {
            let result = self.runCommand(item.command)
            
            DispatchQueue.main.async {
                self.processResult(for: index, result: result, itemName: item.name)
            }
        }
    }

    private func runCommand(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()

        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.launchPath = "/bin/zsh"

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let result = String(data: data, encoding: .utf8) ?? ""
            print("NetworkConfig Command '\(command)' returned: \(result)")
            print("NetworkConfig Exit code: \(process.terminationStatus)")
            return result
        } catch {
            let errorMsg = "Error: \(error.localizedDescription)"
            print("NetworkConfig Command '\(command)' failed: \(errorMsg)")
            return errorMsg
        }
    }

    private func processResult(for index: Int, result: String, itemName: String) {
        var status: NetworkConfigItem.NetworkConfigStatus = .unavailable
        var detail = ""

        print("NetworkConfig Processing \(itemName): \(result)")

        switch itemName {
        case "DNS":
            if result.contains("Server Addresses:") {
                status = .available
                // Extract DNS servers from the result
                let lines = result.components(separatedBy: "\n")
                let dnsLines = lines.filter { $0.contains("Server Addresses:") }
                if !dnsLines.isEmpty {
                    let servers = dnsLines.compactMap { line in
                        line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
                    }.joined(separator: ", ")
                    detail = "Servers: \(servers)"
                } else {
                    detail = "DNS servers configured"
                }
            } else {
                status = .unavailable
                detail = "No DNS servers found"
            }

        case "DNS Name":
            if !result.isEmpty && !result.contains("Error") {
                status = .available
                detail = result.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                status = .unavailable
                detail = "Hostname not available"
            }

        case "Primary Search Domain":
            if result.contains("Domain Name:") {
                status = .available
                let lines = result.components(separatedBy: "\n")
                let domainLines = lines.filter { $0.contains("Domain Name:") }
                if !domainLines.isEmpty {
                    let domains = domainLines.compactMap { line in
                        line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces)
                    }.joined(separator: ", ")
                    detail = "Domain: \(domains)"
                } else {
                    detail = "Domain configured"
                }
            } else {
                status = .unavailable
                detail = "No domain configured"
            }

        case "Host File":
            if result.contains("/etc/hosts") {
                status = .available
                // Extract file details from ls -l output
                // Format: -rw-r--r--  1 root  wheel  213 Sep  5 10:31 /etc/hosts
                let components = result.components(separatedBy: " ").filter { !$0.isEmpty }
                if components.count >= 9 {
                    let permissions = components[0]
                    let links = components[1]
                    let owner = components[2]
                    let group = components[3]
                    let size = components[4]
                    let month = components[5]
                    let day = components[6]
                    let time = components[7]
                    let filename = components[8]
                    
                    status = .modified
                    detail = "Modified: \(month) \(day) \(time) (\(size) bytes)"
                } else {
                    status = .modified
                    detail = "Host file exists"
                }
            } else {
                status = .unavailable
                detail = "Host file not found"
            }

        case "Proxy Details":
            if result.contains("HTTP Proxy") || result.contains("HTTPS Proxy") || result.contains("SOCKS Proxy") {
                status = .available
                // Extract proxy details
                let lines = result.components(separatedBy: "\n")
                var proxyInfo: [String] = []
                
                for line in lines {
                    if line.contains("HTTP Proxy Enabled:") {
                        let enabled = line.contains("Yes") ? "Enabled" : "Disabled"
                        proxyInfo.append("HTTP: \(enabled)")
                    } else if line.contains("HTTPS Proxy Enabled:") {
                        let enabled = line.contains("Yes") ? "Enabled" : "Disabled"
                        proxyInfo.append("HTTPS: \(enabled)")
                    } else if line.contains("SOCKS Proxy Enabled:") {
                        let enabled = line.contains("Yes") ? "Enabled" : "Disabled"
                        proxyInfo.append("SOCKS: \(enabled)")
                    }
                }
                
                if !proxyInfo.isEmpty {
                    detail = proxyInfo.joined(separator: ", ")
                } else {
                    detail = "Proxy configuration found"
                }
            } else {
                status = .unavailable
                detail = "No proxy configuration"
            }

        case "WiFi Details":
            if result.contains("AirPort") || result.contains("WiFi") || result.contains("802.11") {
                status = .available
                // Extract WiFi details
                let lines = result.components(separatedBy: "\n")
                var wifiInfo: [String] = []
                
                for line in lines {
                    if line.contains("Card Type:") {
                        let cardType = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                        wifiInfo.append("Type: \(cardType)")
                    } else if line.contains("MAC Address:") {
                        let macAddress = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                        wifiInfo.append("MAC: \(macAddress)")
                    } else if line.contains("Supported PHY Modes:") {
                        let phyModes = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                        wifiInfo.append("Modes: \(phyModes)")
                    }
                }
                
                if !wifiInfo.isEmpty {
                    detail = wifiInfo.joined(separator: ", ")
                } else {
                    detail = "WiFi adapter detected"
                }
            } else {
                status = .unavailable
                detail = "No WiFi adapter found"
            }

        case "AirDrop":
            // Check if AirDrop is supported by looking at WiFi details
            if result.contains("AirDrop: Supported") {
                status = .available
                detail = "AirDrop services found - Yes"
            } else if result.contains("AirDrop") {
                status = .available
                detail = "AirDrop services found - Yes"
            } else {
                status = .unavailable
                detail = "AirDrop services found - No"
            }

        default:
            status = .unavailable
            detail = "Unknown configuration"
        }

        configItems[index].status = status
        configItems[index].detail = detail
    }
}

struct NetworkConfigurationView: View {
    @StateObject private var checker = NetworkConfigurationChecker()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        SectionCard(title: "Network Configuration", icon: "gear") {
            VStack(alignment: .leading, spacing: 16) {
                Text("This panel displays essential network configuration information including DNS settings, hostname, domain configuration, and network adapter details.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(checker.configItems) { item in
                        NetworkConfigStatusView(item: item)
                    }
                }
            }
        }
        .onAppear {
            print("NetworkConfigurationView appeared - starting configuration check")
            checker.checkAllConfiguration()
        }
    }
}

struct NetworkConfigStatusView: View {
    let item: NetworkConfigItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Group {
                    switch item.status {
                    case .unknown:
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.gray)
                    case .checking:
                        ProgressView()
                            .frame(width: 20, height: 20)
                            .scaleEffect(0.8)
                    case .available, .modified:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .unavailable, .unmodified:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.title3)

                Text(item.name)
                    .font(.system(size: 13, weight: .medium))

                Spacer()
            }

            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            if !item.description.isEmpty {
                Text(item.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
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
