import SwiftUI
import Combine

// MARK: - Data Models
struct AppleService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: ServiceStatus = .unknown
    var detail: String = ""

    enum ServiceStatus {
        case unknown
        case checking
        case available
        case unavailable
        case reachable
        case unreachable
        case valid
        case invalid
    }
}

// MARK: - Device Enrollment Service
struct EnrollmentService: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let command: String
    var status: EnrollmentStatus = .unknown
    var detail: String = ""

    enum EnrollmentStatus {
    case unknown
    case checking
        case available
        case unavailable
    case reachable
    case unreachable
        case valid
        case invalid
    }
}


// MARK: - Apple Services Checker
class AppleServicesChecker: ObservableObject {
    @Published var services: [AppleService] = []
    @Published var enrollmentServices: [EnrollmentService] = []
    
    init() {
        setupServices()
        setupEnrollmentServices()
    }

    private func setupServices() {
        services = [
            AppleService(
                name: "Apple Push Notification Service (APNs)",
                command: "/System/Library/PrivateFrameworks/ApplePushService.framework/apsctl status | grep -E -A 20 'connection environment:\\s+production'"
            ),
            AppleService(
                name: "Device Activation Service",
                command: "security verify-cert -v https://albert.apple.com:443"
            ),
            AppleService(
                name: "Captive Portal",
                command: "nc -zv captive.apple.com 80 && security verify-cert -v https://captive.apple.com:443"
            ),
            AppleService(
                name: "Apple's TSS (Signing) Server",
                command: "security verify-cert -v https://gs.apple.com:443"
            ),
            AppleService(
                name: "Apple Device Setup & Enrollment Service",
                command: "security verify-cert -v https://humb.apple.com:443"
            ),
            AppleService(
                name: "Apple eSIM Activation Service",
                command: "security verify-cert -v https://sq-device.apple.com:443"
            ),
            AppleService(
                name: "Apple Static IP Provisioning Service",
                command: "nc -zv static.ips.apple.com 80 && security verify-cert -v https://static.ips.apple.com:443"
            ),
            AppleService(
                name: "Apple TLS Certificate Validation Service",
                command: "security verify-cert -v https://tbsc.apple.com:443"
            )
        ]
    }

    private func setupEnrollmentServices() {
        enrollmentServices = [
            EnrollmentService(
                name: "Apple Push Init Service",
                command: "nc -zv init-p01st.push.apple.com 80"
            ),
            EnrollmentService(
                name: "Apple Push API Service",
                command: "security verify-cert -v https://api.push.apple.com:2197"
            ),
            EnrollmentService(
                name: "Apple Courier Service",
                command: "nc -zv 1-courier.push.apple.com 5223"
            ),
            EnrollmentService(
                name: "Apple Push API HTTPS",
                command: "security verify-cert -v https://api.push.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple Push API Secure",
                command: "security verify-cert -v https://api.push.apple.com:2197"
            ),
            EnrollmentService(
                name: "Apple Service Discovery",
                command: "security verify-cert -v https://axm-servicediscovery.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple Device Enrollment",
                command: "security verify-cert -v https://deviceenrollment.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple Device Services External",
                command: "security verify-cert -v https://deviceservices-external.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple GDMF Service",
                command: "security verify-cert -v https://gdmf.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple Identity Service",
                command: "security verify-cert -v https://identity.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple iProfiles Service",
                command: "security verify-cert -v https://iprofiles.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple MDM Enrollment",
                command: "security verify-cert -v https://mdmenrollment.apple.com:443"
            ),
            EnrollmentService(
                name: "Apple VPP Service",
                command: "security verify-cert -v https://vpp.itunes.apple.com:443"
            )
        ]
    }
    

    func checkAllServices() {
        print("AppleServicesChecker: Starting checkAllServices")
        for i in 0..<services.count {
            services[i].status = .checking
            print("AppleServicesChecker: Checking service \(i): \(services[i].name)")
            checkService(at: i)
        }
        
        // Also check enrollment services
        checkAllEnrollmentServices()
    }
    
    func checkAllEnrollmentServices() {
        print("AppleServicesChecker: Starting checkAllEnrollmentServices")
        for i in 0..<enrollmentServices.count {
            enrollmentServices[i].status = .checking
            print("AppleServicesChecker: Checking enrollment service \(i): \(enrollmentServices[i].name)")
            checkEnrollmentService(at: i)
        }
    }
    

    private func checkService(at index: Int) {
        let service = services[index]

        DispatchQueue.global(qos: .background).async {
            let result = self.runCommand(service.command)
            
            DispatchQueue.main.async {
                self.processResult(for: index, result: result, serviceName: service.name)
            }
        }
    }
    
    private func checkEnrollmentService(at index: Int) {
        let service = enrollmentServices[index]

        DispatchQueue.global(qos: .background).async {
            let result = self.runCommand(service.command)
            
            DispatchQueue.main.async {
                self.processEnrollmentResult(for: index, result: result, serviceName: service.name)
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
            print("Command '\(command)' returned: \(result)")
            print("Exit code: \(process.terminationStatus)")
            return result
        } catch {
            let errorMsg = "Error: \(error.localizedDescription)"
            print("Command '\(command)' failed: \(errorMsg)")
            return errorMsg
        }
    }

    private func processResult(for index: Int, result: String, serviceName: String) {
        var status: AppleService.ServiceStatus = .unavailable
        var detail = ""

        print("Processing \(serviceName): \(result)")

        switch serviceName {
        case "Apple Push Notification Service (APNs)":
            if result.contains("connection environment") && result.contains("production") {
                status = .available
                detail = "APNs production environment connected"
            } else if result.contains("connection environment") {
                status = .available
                detail = "APNs environment connected"
            } else {
                status = .unavailable
                detail = "APNs connection not available"
            }

        case "Device Activation Service":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Captive Portal":
            if result.contains("certificate verification successful") && result.contains("connection to") {
                status = .valid
                detail = "Port 80 & 443 reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Apple's TSS (Signing) Server":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Apple Device Setup & Enrollment Service":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Apple eSIM Activation Service":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Apple Static IP Provisioning Service":
            if result.contains("certificate verification successful") && result.contains("connection to") {
                status = .valid
                detail = "Port 80 & 443 reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        case "Apple TLS Certificate Validation Service":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }

        default:
            status = .unavailable
            detail = "Unknown service"
        }

        services[index].status = status
        services[index].detail = detail
    }
    
    private func processEnrollmentResult(for index: Int, result: String, serviceName: String) {
        print("Processing \(serviceName): \(result)")
        
        var status: EnrollmentService.EnrollmentStatus
        var detail: String
        
        switch serviceName {
        case "Apple Push Init Service":
            if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Port 80 reachable"
            } else {
                status = .unreachable
                detail = "Port 80 unreachable"
            }
            
        case "Apple Push API Service", "Apple Push API HTTPS", "Apple Push API Secure":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }
            
        case "Apple Courier Service":
            if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Port 5223 reachable"
            } else {
                status = .unreachable
                detail = "Port 5223 unreachable"
            }
            
        case "Apple Service Discovery", "Apple Device Enrollment", "Apple Device Services External", 
             "Apple GDMF Service", "Apple Identity Service", "Apple iProfiles Service", 
             "Apple MDM Enrollment", "Apple VPP Service":
            if result.contains("certificate verification successful") {
                status = .valid
                detail = "Host reachable, Certificate valid"
            } else if result.contains("connection to") && result.contains("opened") {
                status = .reachable
                detail = "Host reachable, Certificate issues"
            } else {
                status = .unreachable
                detail = "Host unreachable"
            }
            
        default:
            status = .unavailable
            detail = "Unknown service"
        }
        
        enrollmentServices[index].status = status
        enrollmentServices[index].detail = detail
    }
    
}

// MARK: - Main View
struct AppleNetworkServicesView: View {
    @StateObject private var checker = AppleServicesChecker()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Apple Network Services Section
                SectionCard(title: "Apple Network Services", icon: "cloud.fill") {
            VStack(alignment: .leading, spacing: 16) {
                        Text("This panel displays the status of essential Apple network services including APNs, device installation services, and time synchronization services.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(checker.services) { service in
                        ServiceStatusView(service: service)
                    }
                }
            }
                }
                
                // Device Enrollment Services Section
                SectionCard(title: "Device Enrollment Services", icon: "person.badge.plus.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This panel displays the status of Apple device enrollment services including push notifications, device enrollment, and MDM services.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(checker.enrollmentServices) { service in
                                EnrollmentServiceStatusView(service: service)
                            }
                        }
                    }
                }
                
            }
            .padding()
        }
        .onAppear {
            print("AppleNetworkServicesView appeared - starting service check")
            checker.checkAllServices()
        }
    }
}

// MARK: - Service Status View
struct ServiceStatusView: View {
    let service: AppleService

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
                case .available, .valid, .reachable:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                case .unavailable, .invalid, .unreachable:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
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

// MARK: - Enrollment Service Status View
struct EnrollmentServiceStatusView: View {
    let service: EnrollmentService

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
                case .available, .valid, .reachable:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                case .unavailable, .invalid, .unreachable:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
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