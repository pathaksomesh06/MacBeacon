import SwiftUI

// MARK: - Enterprise Device Management Service
struct EnterpriseManagementService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: EnterpriseStatus = .unknown
    var detail: String = ""

    enum EnterpriseStatus {
        case unknown
        case checking
        case enrolled
        case notEnrolled
        case managed
        case unmanaged
        case configured
        case notConfigured
        case available
        case unavailable
        case yes
        case no
    }
}

// MARK: - Enterprise Device Management Checker
class EnterpriseDeviceManagementChecker: ObservableObject {
    @Published var enterpriseServices: [EnterpriseManagementService] = []
    
    init() {
        setupEnterpriseServices()
    }
    
    private func setupEnterpriseServices() {
        enterpriseServices = [
            EnterpriseManagementService(
                name: "Device Management Service",
                command: "system_profiler SPConfigurationProfileDataType | grep -i 'organization' | head -1 || echo 'No enrollment profiles'"
            ),
            EnterpriseManagementService(
                name: "Device Management Service Type",
                command: "system_profiler SPConfigurationProfileDataType | grep -i 'jamf\\|microsoft\\|intune\\|workspace' || echo 'No ADE/DEP detected'"
            ),
            EnterpriseManagementService(
                name: "Device Management Service URL",
                command: "system_profiler SPConfigurationProfileDataType | grep -A 10 -B 5 'ServerURL\\|MDM Server\\|SCEP Server' | grep -E 'ServerURL|Description.*Server' || echo 'No management server URL'"
            ),
            EnterpriseManagementService(
                name: "Managed User Account",
                command: "system_profiler SPConfigurationProfileDataType | grep 'Managed User'"
            ),
            EnterpriseManagementService(
                name: "Organization Name",
                command: "system_profiler SPConfigurationProfileDataType | grep -A 1 -B 1 'Organization:' | grep -E 'Organization:|Name:' | head -2 || echo 'No organization found'"
            ),
            EnterpriseManagementService(
                name: "PPPC Status",
                command: "system_profiler SPConfigurationProfileDataType | grep -A 5 -B 5 'SystemPolicyAllFiles'"
            ),
            EnterpriseManagementService(
                name: "Extensible Single Sign-on",
                command: "app-sso -j -l 2>/dev/null; app-sso platform --state 2>/dev/null || echo 'No SSO extensions'"
            ),
            EnterpriseManagementService(
                name: "Kerberos SSO Extension",
                command: "app-sso -j -l 2>/dev/null | grep -i kerberos || echo 'Kerberos SSO not configured'"
            ),
            EnterpriseManagementService(
                name: "Platform SSO",
                command: "app-sso platform --state 2>/dev/null || echo 'Platform SSO not configured'"
            )
        ]
    }
    
    func checkAllEnterpriseServices() {
        print("EnterpriseDeviceManagementChecker: Starting checkAllEnterpriseServices")
        for (index, _) in enterpriseServices.enumerated() {
            checkEnterpriseService(at: index)
        }
    }
    
    private func checkEnterpriseService(at index: Int) {
        print("EnterpriseDeviceManagementChecker: Checking enterprise service \(index): \(enterpriseServices[index].name)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.runCommand(self.enterpriseServices[index].command)
            
            DispatchQueue.main.async {
                self.processEnterpriseResult(for: index, result: result, serviceName: self.enterpriseServices[index].name)
            }
        }
    }
    
    private func runCommand(_ command: String) -> String {
        print("EnterpriseDeviceManagementChecker: Running command: \(command)")
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
            
            print("EnterpriseDeviceManagementChecker: Command '\(command)' returned: \(result)")
            print("EnterpriseDeviceManagementChecker: Exit code: \(process.terminationStatus)")
            
            return result
        } catch {
            print("EnterpriseDeviceManagementChecker: Error running command: \(error)")
            return "Error: \(error.localizedDescription)"
        }
    }
    
    private func processEnterpriseResult(for index: Int, result: String, serviceName: String) {
        print("EnterpriseDeviceManagementChecker: Processing \(serviceName): \(result)")
        
        var status: EnterpriseManagementService.EnterpriseStatus
        var detail: String
        
        switch serviceName {
        case "Device Management Service":
            if result.contains("Organization:") && !result.contains("No enrollment profiles") {
                status = .enrolled
                detail = "Device enrolled in management"
            } else {
                status = .notEnrolled
                detail = "Device not enrolled"
            }
            
        case "Device Management Service Type":
            if result.contains("jamf") || result.contains("JAMF") || result.contains("microsoft") || result.contains("intune") || result.contains("workspace") {
                status = .enrolled
                detail = "Enterprise management detected"
            } else {
                status = .notEnrolled
                detail = "No enterprise management detected"
            }
            
        case "Device Management Service URL":
            if result.contains("ServerURL") {
                let lines = result.components(separatedBy: "\n")
                var serverURL = "Unknown Server"
                
                for line in lines {
                    if line.contains("ServerURL") {
                        serverURL = line.replacingOccurrences(of: "ServerURL =", with: "").replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
                
                status = .configured
                detail = "MDM Server: \(serverURL)"
            } else if result.contains("Description.*Server") {
                status = .configured
                detail = "Management server configured"
            } else {
                status = .notConfigured
                detail = "No management server URL"
            }
            
        case "Managed User Account":
            if result.contains("Managed User:") && result.contains("(") {
                status = .managed
                detail = "Logged in with managed user account"
            } else {
                status = .unmanaged
                detail = "Not using managed user account"
            }
            
        case "Organization Name":
            if result.contains("Organization:") {
                let lines = result.components(separatedBy: "\n")
                var orgName = "Unknown Organization"
                var profileName = "Unknown Profile"
                
                for line in lines {
                    if line.contains("Organization:") {
                        orgName = line.replacingOccurrences(of: "Organization:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    } else if line.contains("Name:") {
                        profileName = line.replacingOccurrences(of: "Name:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                status = .configured
                detail = "\(orgName) - \(profileName)"
            } else {
                status = .notConfigured
                detail = "No organization found"
            }
            
        case "PPPC Status":
            if result.contains("SystemPolicyAllFiles") && result.contains("Allowed = 1") {
                status = .managed
                detail = "PPPC managed - Yes"
            } else {
                status = .unmanaged
                detail = "PPPC managed - No"
            }
            
        case "Extensible Single Sign-on":
            if result.contains("identifier") || result.contains("kerberos") || result.contains("Microsoft Entra") || result.contains("CompanyPortalMac") || result.contains("Platform SSO") || result.contains("platform") {
                status = .configured
                detail = "SSO extensions configured"
            } else if result.contains("No SSO extensions") {
                status = .notConfigured
                detail = "No SSO extensions"
            } else {
                status = .notConfigured
                detail = "No SSO extensions"
            }
            
        case "Kerberos SSO Extension":
            if result.contains("kerberos") || result.contains("Kerberos") {
                status = .configured
                detail = "Kerberos SSO configured"
            } else {
                status = .notConfigured
                detail = "Kerberos SSO not configured"
            }
            
        case "Platform SSO":
            if result.contains("Microsoft Entra") || result.contains("CompanyPortalMac") || result.contains("Platform SSO") || result.contains("platform") || result.contains("Platform") {
                status = .configured
                detail = "Platform SSO configured"
            } else if result.contains("Platform SSO not configured") {
                status = .notConfigured
                detail = "Platform SSO not configured"
            } else {
                status = .notConfigured
                detail = "Platform SSO not configured"
            }
            
        default:
            status = .unknown
            detail = "Unknown service"
        }
        
        enterpriseServices[index].status = status
        enterpriseServices[index].detail = detail
    }
}

// MARK: - Enterprise Device Management View
struct EnterpriseDeviceManagementView: View {
    @StateObject private var checker = EnterpriseDeviceManagementChecker()
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(.brown)
                
                VStack(alignment: .leading) {
                    Text("Enterprise Device Management")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("MDM enrollment, user account management, and SSO configuration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 10)
            
            // Enterprise Device Management Section
            SectionCard(title: "Enterprise Device Management", icon: "building.2.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This panel displays enterprise device management status including MDM enrollment, user account management, and SSO configuration.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(checker.enterpriseServices) { service in
                            EnterpriseServiceStatusView(service: service)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("EnterpriseDeviceManagementView appeared - starting service check")
            checker.checkAllEnterpriseServices()
        }
    }
}

// MARK: - Enterprise Service Status View
struct EnterpriseServiceStatusView: View {
    let service: EnterpriseManagementService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                switch service.status {
                case .unknown:
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                case .checking:
                    ProgressView()
                        .frame(width: 20, height: 20)
                        .scaleEffect(0.8)
                case .enrolled, .managed, .configured, .yes:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                case .notEnrolled, .unmanaged, .notConfigured, .no:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                case .available:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                case .unavailable:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }

            Text(service.name)
                    .font(.system(size: 13, weight: .medium))
            
            Spacer()
            }

            if !service.detail.isEmpty {
                Text(service.detail)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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

