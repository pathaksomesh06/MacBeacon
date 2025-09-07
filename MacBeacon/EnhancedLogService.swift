import Foundation
import SwiftUI

struct DefenderEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let startTime: Date
    let endTime: Date?
    let status: EventStatus
    let threadId: String
    let details: [LogEntry]
    let errorCount: Int
    let warningCount: Int
    
    enum EventType: String, CaseIterable {
        case scan = "Scan"
        case update = "Update"
        case threat = "Threat Detection"
        case quarantine = "Quarantine"
        case realtime = "Real-time Protection"
        case cloud = "Cloud Service"
        
        var icon: String {
            switch self {
            case .scan: return "magnifyingglass.circle"
            case .update: return "arrow.down.circle"
            case .threat: return "exclamationmark.shield"
            case .quarantine: return "lock.shield"
            case .realtime: return "shield"
            case .cloud: return "cloud"
            }
        }
        
        var color: Color {
            switch self {
            case .threat: return .red
            case .quarantine: return .orange
            case .scan: return .blue
            case .update: return .green
            case .realtime: return .purple
            case .cloud: return .cyan
            }
        }
    }
    
    enum EventStatus {
        case completed
        case inProgress
        case failed
        case warning
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .inProgress: return .blue
            case .failed: return .red
            case .warning: return .orange
            }
        }
    }
    
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    var durationString: String {
        guard let duration = duration else { return "In Progress" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

class EnhancedLogService: ObservableObject {
    @Published var logFiles: [LogFile] = []
    @Published var currentFile: LogFile?
    @Published var events: [DefenderEvent] = []
    @Published var rawEntries: [LogEntry] = []
    @Published var isAnalyzing = false
    @Published var selectedEvent: DefenderEvent?
    
    struct LogFile: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let size: Int64
        let modifiedDate: Date
        let entryCount: Int
        let criticalCount: Int
        let errorCount: Int
        let warningCount: Int
    }
    
    private let defenderLogPath = "/Library/Logs/Microsoft/mdatp"
    private var fileMonitors: [String: DispatchSourceFileSystemObject] = [:]
    
    func loadAllLogFiles() {
        let fm = FileManager.default
        logFiles.removeAll()
        
        // Check both main and rotated directories
        let paths = [defenderLogPath, "\(defenderLogPath)/rotated"]
        
        for basePath in paths {
            guard fm.fileExists(atPath: basePath) else { continue }
            
            do {
                let files = try fm.contentsOfDirectory(atPath: basePath)
                for file in files where file.hasSuffix(".log") || file.hasSuffix(".json") {
                    let fullPath = "\(basePath)/\(file)"
                    if let logFile = analyzeLogFile(at: fullPath) {
                        logFiles.append(logFile)
                    }
                }
            } catch {
                print("Error reading \(basePath): \(error)")
            }
        }
        
        // Sort by modified date
        logFiles.sort { $0.modifiedDate > $1.modifiedDate }
        
        // Auto-select most recent
        if let mostRecent = logFiles.first {
            selectLogFile(mostRecent)
        }
    }
    
    private func analyzeLogFile(at path: String) -> LogFile? {
        let fm = FileManager.default
        guard let attributes = try? fm.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64,
              let modDate = attributes[.modificationDate] as? Date else {
            return nil
        }
        
        // Quick scan for counts
        var entryCount = 0
        var criticalCount = 0
        var errorCount = 0
        var warningCount = 0
        
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            entryCount = lines.filter { !$0.isEmpty }.count
            
            for line in lines {
                let lower = line.lowercased()
                if lower.contains("[critical]") || lower.contains("[fatal]") {
                    criticalCount += 1
                } else if lower.contains("[error]") || lower.contains("[err]") {
                    errorCount += 1
                } else if lower.contains("[warning]") || lower.contains("[warn]") {
                    warningCount += 1
                }
            }
        }
        
        return LogFile(
            name: URL(fileURLWithPath: path).lastPathComponent,
            path: path,
            size: size,
            modifiedDate: modDate,
            entryCount: entryCount,
            criticalCount: criticalCount,
            errorCount: errorCount,
            warningCount: warningCount
        )
    }
    
    func selectLogFile(_ file: LogFile) {
        currentFile = file
        loadAndAnalyzeFile(at: file.path)
    }
    
    private func loadAndAnalyzeFile(at path: String) {
        isAnalyzing = true
        rawEntries.removeAll()
        events.removeAll()
        
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            isAnalyzing = false
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        var threadGroups: [String: [LogEntry]] = [:]
        
        // Parse all entries
        for line in lines where !line.isEmpty {
            if let entry = parseDefenderLogLine(line) {
                rawEntries.append(entry)
                
                // Extract thread ID from line
                if let threadId = extractThreadId(from: line) {
                    if threadGroups[threadId] == nil {
                        threadGroups[threadId] = []
                    }
                    threadGroups[threadId]?.append(entry)
                }
            }
        }
        
        // Create events from thread groups
        for (threadId, entries) in threadGroups {
            if let event = createEvent(from: entries, threadId: threadId) {
                events.append(event)
            }
        }
        
        // Sort events by start time
        events.sort { $0.startTime > $1.startTime }
        
        isAnalyzing = false
        startMonitoring(path: path)
    }
    
    private func extractThreadId(from line: String) -> String? {
        // Extract PID from [890] format
        if let match = line.range(of: #"^\[(\d+)\]"#, options: .regularExpression) {
            return String(line[match]).trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        }
        return nil
    }
    
    private func createEvent(from entries: [LogEntry], threadId: String) -> DefenderEvent? {
        guard !entries.isEmpty else { return nil }
        
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        let startTime = sortedEntries.first!.timestamp
        let endTime = sortedEntries.last!.timestamp
        
        // Determine event type from messages
        let eventType = detectEventType(from: entries)
        
        // Count errors/warnings
        let errorCount = entries.filter { $0.level == .error || $0.level == .critical }.count
        let warningCount = entries.filter { $0.level == .warning }.count
        
        // Determine status
        let status: DefenderEvent.EventStatus
        if entries.contains(where: { $0.level == .critical || $0.level == .error }) {
            status = errorCount > 2 ? .failed : .warning
        } else if entries.last?.message.lowercased().contains("complete") ?? false {
            status = .completed
        } else {
            status = .inProgress
        }
        
        return DefenderEvent(
            type: eventType,
            startTime: startTime,
            endTime: startTime == endTime ? nil : endTime,
            status: status,
            threadId: threadId,
            details: sortedEntries,
            errorCount: errorCount,
            warningCount: warningCount
        )
    }
    
    private func detectEventType(from entries: [LogEntry]) -> DefenderEvent.EventType {
        let combinedText = entries.map { $0.message.lowercased() }.joined(separator: " ")
        
        if combinedText.contains("threat") || combinedText.contains("malware") || combinedText.contains("virus") {
            return .threat
        } else if combinedText.contains("quarantine") {
            return .quarantine
        } else if combinedText.contains("scan") {
            return .scan
        } else if combinedText.contains("update") || combinedText.contains("definition") {
            return .update
        } else if combinedText.contains("real-time") || combinedText.contains("realtime") {
            return .realtime
        } else if combinedText.contains("cloud") {
            return .cloud
        }
        
        return .scan // default
    }
    
    private func parseDefenderLogLine(_ line: String) -> LogEntry? {
        let pattern = #"\[(\d+)\]\[([^\]]+)\]\[([^\]]+)\]:\s*\[\{([^}]+)\}\]:\s*(.+)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let timestampStr = String(line[Range(match.range(at: 2), in: line)!])
        let levelStr = String(line[Range(match.range(at: 3), in: line)!])
        let component = String(line[Range(match.range(at: 4), in: line)!])
        let message = String(line[Range(match.range(at: 5), in: line)!])
        
        return LogEntry(
            timestamp: parseDefenderTimestamp(timestampStr),
            level: parseDefenderLevel(levelStr),
            component: component,
            message: message,
            fullText: line
        )
    }
    
    private func parseDefenderTimestamp(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS 'UTC'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = formatter.date(from: str) {
            return date
        }
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"
        if let date = formatter.date(from: str) {
            return date
        }
        
        return Date()
    }
    
    private func parseDefenderLevel(_ str: String) -> LogEntry.LogLevel {
        switch str.lowercased() {
        case "fatal", "critical": return .critical
        case "error", "err": return .error
        case "warning", "warn": return .warning
        case "debug", "dbg": return .debug
        case "trace", "verbose": return .trace
        default: return .info
        }
    }
    
    private func startMonitoring(path: String) {
        stopMonitoring(path: path)
        
        let fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        let monitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: DispatchQueue.main
        )
        
        monitor.setEventHandler { [weak self] in
            self?.reloadFile(at: path)
        }
        
        monitor.setCancelHandler {
            close(fileDescriptor)
        }
        
        monitor.resume()
        fileMonitors[path] = monitor
    }
    
    private func stopMonitoring(path: String) {
        fileMonitors[path]?.cancel()
        fileMonitors[path] = nil
    }
    
    private func reloadFile(at path: String) {
        loadAndAnalyzeFile(at: path)
    }
    
    func stopAllMonitoring() {
        for (path, _) in fileMonitors {
            stopMonitoring(path: path)
        }
    }
    
    deinit {
        stopAllMonitoring()
    }
}