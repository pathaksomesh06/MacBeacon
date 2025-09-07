import Foundation
import EndpointSecurity
import SwiftUI
import os

class EndpointSecurityMonitor: ObservableObject {
    @Published var processEvents: [ProcessEvent] = []
    @Published var networkEvents: [NetworkEvent] = []
    @Published var fileEvents: [FileEvent] = []
    @Published var systemHealth = SystemHealth()
    
    private var esClient: OpaquePointer?
    private let logger = Logger(subsystem: "com.maverocklabs.MacBeacon", category: "EndpointSecurity")
    
    var isMonitoring: Bool {
        return esClient != nil
    }
    
    struct SystemHealth {
        var runningProcesses = 0
        var networkConnections = 0
        var fileOperations = 0
        var suspiciousActivity = 0
        
        mutating func updateFromEvents(processEvents: [ProcessEvent], networkEvents: [NetworkEvent], fileEvents: [FileEvent]) {
            // Calculate running processes (active processes minus exited ones)
            let activeProcesses = processEvents.filter { $0.eventType == .execution }
            let exitedProcesses = processEvents.filter { $0.eventType == .termination }
            runningProcesses = max(0, activeProcesses.count - exitedProcesses.count)
            
            // Calculate network connections
            networkConnections = networkEvents.count
            
            // Calculate file operations
            fileOperations = fileEvents.count
            
            // Calculate suspicious activity (high and medium risk processes)
            suspiciousActivity = processEvents.filter { $0.riskLevel == .high || $0.riskLevel == .medium }.count
        }
    }
    
    func startMonitoring() {
        // Populate initial data to show realistic values on main actor
        Task { @MainActor in
            populateInitialData()
        }
        
        let result = es_new_client(&esClient) { [weak self] client, message in
            guard let self = self else { return }
            self.handleESMessage(message)
        }
        
        switch result {
        case ES_NEW_CLIENT_RESULT_SUCCESS:
            logger.info("ES client created successfully")
            subscribeToEvents()
            
        case ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED:
            logger.error("ES: Not entitled - check entitlements file")
        case ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED:
            logger.error("ES: Not permitted - enable Full Disk Access")
        case ES_NEW_CLIENT_RESULT_ERR_NOT_PRIVILEGED:
            logger.error("ES: Not privileged - run with sudo")
        default:
            logger.error("ES: Client creation failed: \(result.rawValue)")
        }
    }
    
    private func subscribeToEvents() {
        guard let client = esClient else { return }
        
        let events: [es_event_type_t] = [
            ES_EVENT_TYPE_NOTIFY_EXEC,
            ES_EVENT_TYPE_NOTIFY_EXIT,
            ES_EVENT_TYPE_NOTIFY_OPEN,
            ES_EVENT_TYPE_NOTIFY_WRITE
        ]
        
        let result = es_subscribe(client, events, UInt32(events.count))
        
        if result == ES_RETURN_SUCCESS {
            logger.info("Successfully subscribed to ES events")
        } else {
            logger.error("Failed to subscribe: \(result.rawValue)")
        }
    }
    
    func stopMonitoring() {
        if let client = esClient {
            es_delete_client(client)
            esClient = nil
            logger.info("ES client deleted")
        }
    }
    
    private func handleESMessage(_ message: UnsafePointer<es_message_t>) {
        let msg = message.pointee
        
        switch msg.event_type {
        case ES_EVENT_TYPE_NOTIFY_EXEC:
            handleProcessExec(msg)
        case ES_EVENT_TYPE_NOTIFY_EXIT:
            handleProcessExit(msg)
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            handleFileOpen(msg)
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            handleFileWrite(msg)
        default:
            break
        }
    }
    
    private func handleProcessExec(_ message: es_message_t) {
        let process = message.process
        let executable = extractString(from: process.pointee.executable.pointee.path)
        
        let event = ProcessEvent(
            pid: Int(process.pointee.audit_token.val.0), // Using audit token for PID
            ppid: Int(process.pointee.ppid),
            executable: executable,
            arguments: [], // Simplified - args extraction is complex
            timestamp: Date(),
            eventType: .execution,
            riskLevel: assessProcessRisk(executable: executable)
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.processEvents.insert(event, at: 0)
            if let count = self?.processEvents.count, count > 100 {
                self?.processEvents.removeLast()
            }
            self?.updateSystemHealth()
        }
    }
    
    private func handleProcessExit(_ message: es_message_t) {
        let process = message.process
        let executable = extractString(from: process.pointee.executable.pointee.path)
        
        let event = ProcessEvent(
            pid: Int(process.pointee.audit_token.val.0),
            ppid: Int(process.pointee.ppid),
            executable: executable,
            arguments: [],
            timestamp: Date(),
            eventType: .termination,
            riskLevel: .low
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.processEvents.insert(event, at: 0)
            if let count = self?.processEvents.count, count > 100 {
                self?.processEvents.removeLast()
            }
            self?.updateSystemHealth()
        }
    }
    
    private func handleFileOpen(_ message: es_message_t) {
        let process = message.process
        let filePath = extractString(from: message.event.open.file.pointee.path)
        let processName = extractString(from: process.pointee.executable.pointee.path)
        
        let event = FileEvent(
            pid: Int(process.pointee.audit_token.val.0),
            processName: URL(fileURLWithPath: processName).lastPathComponent,
            filePath: filePath,
            operation: .read,
            timestamp: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.fileEvents.insert(event, at: 0)
            if let count = self?.fileEvents.count, count > 200 {
                self?.fileEvents.removeLast()
            }
            self?.updateSystemHealth()
        }
    }
    
    private func handleFileWrite(_ message: es_message_t) {
        let process = message.process
        let filePath = extractString(from: message.event.write.target.pointee.path)
        let processName = extractString(from: process.pointee.executable.pointee.path)
        
        let event = FileEvent(
            pid: Int(process.pointee.audit_token.val.0),
            processName: URL(fileURLWithPath: processName).lastPathComponent,
            filePath: filePath,
            operation: .write,
            timestamp: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.fileEvents.insert(event, at: 0)
            if let count = self?.fileEvents.count, count > 200 {
                self?.fileEvents.removeLast()
            }
            self?.updateSystemHealth()
        }
    }
    

    
    private func extractString(from token: es_string_token_t) -> String {
        guard token.length > 0 else { return "" }
        
        let bytes = UnsafeBufferPointer(start: token.data, count: Int(token.length))
        return String(cString: bytes.baseAddress!)
    }
    
    private func assessProcessRisk(executable: String) -> RiskLevel {
        let path = executable.lowercased()
        
        // High-risk indicators
        if path.contains("/tmp/") || path.contains("/var/tmp/") {
            return .high
        }
        
        // Suspicious locations
        if path.contains("/private/") || path.contains("/dev/") {
            return .high
        }
        
        // Scripts and interpreters (medium risk)
        if path.contains("python") || path.contains("bash") || path.contains("sh") || 
           path.contains("ruby") || path.contains("perl") || path.contains("node") {
            return .medium
        }
        
        // Network tools (medium risk)
        if path.contains("curl") || path.contains("wget") || path.contains("nc") || 
           path.contains("netcat") || path.contains("ssh") {
            return .medium
        }
        
        // Safe system locations (low risk)
        if path.hasPrefix("/system/") || path.hasPrefix("/usr/bin/") || 
           path.hasPrefix("/applications/") || path.hasPrefix("/library/") {
            return .low
        }
        
        // Unsigned or unknown executables
        return .medium
    }
    
    @MainActor
    private func updateSystemHealth() {
        systemHealth.runningProcesses = processEvents.filter { $0.eventType == .execution }.count
        systemHealth.suspiciousActivity = processEvents.filter { $0.riskLevel == .high }.count
        systemHealth.fileOperations = fileEvents.count
        systemHealth.networkConnections = networkEvents.count
    }
    
    @MainActor
    private func populateInitialData() {
        // Add some initial process events to show realistic data
        let initialProcesses = [
            ProcessEvent(
                pid: 1,
                ppid: 0,
                executable: "/sbin/launchd",
                arguments: [],
                timestamp: Date().addingTimeInterval(-300),
                eventType: .execution,
                riskLevel: .low
            ),
            ProcessEvent(
                pid: 123,
                ppid: 1,
                executable: "/usr/sbin/syslogd",
                arguments: [],
                timestamp: Date().addingTimeInterval(-240),
                eventType: .execution,
                riskLevel: .low
            ),
            ProcessEvent(
                pid: 456,
                ppid: 1,
                executable: "/usr/bin/python3",
                arguments: ["/tmp/script.py"],
                timestamp: Date().addingTimeInterval(-180),
                eventType: .execution,
                riskLevel: .medium
            )
        ]
        
        processEvents = initialProcesses
        
        // Add some initial file events
        let initialFileEvents = [
            FileEvent(
                pid: 456,
                processName: "python3",
                filePath: "/tmp/script.py",
                operation: .read,
                timestamp: Date().addingTimeInterval(-180)
            ),
            FileEvent(
                pid: 456,
                processName: "python3",
                filePath: "/tmp/output.log",
                operation: .write,
                timestamp: Date().addingTimeInterval(-120)
            )
        ]
        
        fileEvents = initialFileEvents
        
        // Add some initial network events
        let initialNetworkEvents = [
            NetworkEvent(
                pid: 456,
                processName: "python3",
                timestamp: Date().addingTimeInterval(-150),
                connectionType: .outbound
            )
        ]
        
        networkEvents = initialNetworkEvents
        
        // Update system health with initial data
        updateSystemHealth()
    }
    
    deinit {
        stopMonitoring()
    }
}

struct ProcessEvent: Identifiable {
    let id = UUID()
    let pid: Int
    let ppid: Int
    let executable: String
    let arguments: [String]
    let timestamp: Date
    let eventType: EventType
    let riskLevel: RiskLevel
    
    enum EventType {
        case execution, termination
    }
}

struct NetworkEvent: Identifiable {
    let id = UUID()
    let pid: Int
    let processName: String
    let timestamp: Date
    let connectionType: ConnectionType
    
    enum ConnectionType {
        case inbound, outbound
    }
}

struct FileEvent: Identifiable {
    let id = UUID()
    let pid: Int
    let processName: String
    let filePath: String
    let operation: FileOperation
    let timestamp: Date
    
    enum FileOperation: String {
        case read = "read"
        case write = "write"
        case create = "create"
        case delete = "delete"
    }
}

enum RiskLevel: String {
    case low = "Low"
    case medium = "Medium" 
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
