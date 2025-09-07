import SwiftUI

struct ThreatEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let type: EventType
    let severity: Severity
    let component: String
    let description: String
    let count: Int
    let duration: TimeInterval?
    let status: Status
    let relatedLogs: [LogEntry]
    
    enum EventType: String, CaseIterable {
        case threat = "Threat Detected"
        case scan = "Scan Event"
        case update = "Definition Update"
        case network = "Network Event"
        case realtime = "Real-time Protection"
        case quarantine = "Quarantine Action"
        
        var icon: String {
            switch self {
            case .threat: return "exclamationmark.shield.fill"
            case .scan: return "magnifyingglass.circle.fill"
            case .update: return "arrow.down.circle.fill"
            case .network: return "network"
            case .realtime: return "shield.fill"
            case .quarantine: return "lock.shield.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .threat: return .red
            case .scan: return .blue
            case .update: return .green
            case .network: return .orange
            case .realtime: return .purple
            case .quarantine: return .yellow
            }
        }
    }
    
    enum Severity: String {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            case .info: return .gray
            }
        }
    }
    
    enum Status: String {
        case active = "ACTIVE"
        case resolved = "RESOLVED"
        case blocked = "BLOCKED"
        case allowed = "ALLOWED"
        case quarantined = "QUARANTINED"
        
        var color: Color {
            switch self {
            case .active: return .orange
            case .resolved: return .green
            case .blocked: return .red
            case .allowed: return .blue
            case .quarantined: return .purple
            }
        }
    }
}

class ThreatAnalyzer: ObservableObject {
    @Published var threatEvents: [ThreatEvent] = []
    @Published var activeThreats = 0
    @Published var blockedThreats = 0
    @Published var scanEvents = 0
    
    func analyze(logs: [LogEntry]) {
        var events: [ThreatEvent] = []
        
        // Group logs by component and time window
        let grouped = Dictionary(grouping: logs) { log in
            "\(log.component)_\(Int(log.timestamp.timeIntervalSince1970 / 60))" // Group by minute
        }
        
        for (_, groupedLogs) in grouped {
            guard let firstLog = groupedLogs.first else { continue }
            
            let eventType = detectEventType(from: firstLog)
            let severity = detectSeverity(from: groupedLogs)
            let status = detectStatus(from: groupedLogs)
            
            let event = ThreatEvent(
                timestamp: firstLog.timestamp,
                type: eventType,
                severity: severity,
                component: firstLog.component,
                description: summarizeEvent(logs: groupedLogs),
                count: groupedLogs.count,
                duration: calculateDuration(logs: groupedLogs),
                status: status,
                relatedLogs: groupedLogs
            )
            
            events.append(event)
        }
        
        // Sort by timestamp descending
        threatEvents = events.sorted { $0.timestamp > $1.timestamp }
        
        // Update counts
        activeThreats = threatEvents.filter { $0.status == .active }.count
        blockedThreats = threatEvents.filter { $0.status == .blocked }.count
        scanEvents = threatEvents.filter { $0.type == .scan }.count
    }
    
    private func detectEventType(from log: LogEntry) -> ThreatEvent.EventType {
        let message = log.message.lowercased()
        let component = log.component.lowercased()
        
        if message.contains("threat") || message.contains("malware") || message.contains("virus") {
            return .threat
        }
        if component.contains("scan") || message.contains("scan") {
            return .scan
        }
        if component.contains("update") || message.contains("definition") {
            return .update
        }
        if component.contains("network") || message.contains("connection") {
            return .network
        }
        if component.contains("realtime") || message.contains("real-time") {
            return .realtime
        }
        if message.contains("quarantine") {
            return .quarantine
        }
        
        return .scan
    }
    
    private func detectSeverity(from logs: [LogEntry]) -> ThreatEvent.Severity {
        if logs.contains(where: { $0.level == .critical }) {
            return .critical
        }
        if logs.contains(where: { $0.level == .error }) {
            return .high
        }
        if logs.contains(where: { $0.level == .warning }) {
            return .medium
        }
        return .info
    }
    
    private func detectStatus(from logs: [LogEntry]) -> ThreatEvent.Status {
        let messages = logs.map { $0.message.lowercased() }.joined(separator: " ")
        
        if messages.contains("blocked") {
            return .blocked
        }
        if messages.contains("quarantine") {
            return .quarantined
        }
        if messages.contains("resolved") || messages.contains("cleaned") {
            return .resolved
        }
        if messages.contains("allowed") {
            return .allowed
        }
        
        return .active
    }
    
    private func summarizeEvent(logs: [LogEntry]) -> String {
        // Get the most important message
        if let criticalLog = logs.first(where: { $0.level == .critical }) {
            return criticalLog.message
        }
        if let errorLog = logs.first(where: { $0.level == .error }) {
            return errorLog.message
        }
        return logs.first?.message ?? "Event detected"
    }
    
    private func calculateDuration(logs: [LogEntry]) -> TimeInterval? {
        guard logs.count > 1,
              let first = logs.first?.timestamp,
              let last = logs.last?.timestamp else {
            return nil
        }
        return last.timeIntervalSince(first)
    }
}