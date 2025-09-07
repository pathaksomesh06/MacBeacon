import Foundation
import SwiftUI
import OSLog

class LogFileService: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var errorCount = 0
    @Published var warningCount = 0
    @Published var criticalCount = 0
    @Published var totalCount = 0
    @Published var isMonitoring = false
    @Published var hasNewErrors = false
    
    private var monitors: [String: DispatchSourceFileSystemObject] = [:]
    private let logQueue = DispatchQueue(label: "log.processing", qos: .background)
    
    // Log source paths
    private let logSources = [
        "system": "/var/log/system.log",
        "security": "/var/log/security.log",
        "install": "/var/log/install.log",
        "wifi": "/var/log/wifi.log"
    ]
    
    private let userLogPaths = [
        "~/Library/Logs",
        "~/Library/Application Support/CrashReporter",
        "~/Library/Logs/DiagnosticReports"
    ]
    
    init() {
        startMultiSourceMonitoring()
    }
    
    private func startMultiSourceMonitoring() {
        // 1. Load system logs
        loadSystemLogs()
        
        // 2. Load application logs
        loadApplicationLogs()
        
        // 3. Start unified logging
        startUnifiedLogging()
        
        // 4. Monitor file changes
        startFileMonitoring()
        
        updateCounts()
    }
    
    private func loadSystemLogs() {
        for (source, path) in logSources {
            if FileManager.default.fileExists(atPath: path) {
                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                    let lines = content.components(separatedBy: .newlines).suffix(100) // Last 100 lines
                    for line in lines {
                        if let entry = parseSystemLogLine(line, source: source) {
                            entries.append(entry)
                        }
                    }
                }
            }
        }
    }
    
    private func loadApplicationLogs() {
        let fm = FileManager.default
        let homeDir = fm.homeDirectoryForCurrentUser.path
        
        for relativePath in userLogPaths {
            let fullPath = relativePath.replacingOccurrences(of: "~", with: homeDir)
            
            guard fm.fileExists(atPath: fullPath) else { continue }
            
            do {
                let files = try fm.contentsOfDirectory(atPath: fullPath)
                for file in files.prefix(10) { // Limit to recent files
                    let filePath = "\(fullPath)/\(file)"
                    if let content = try? String(contentsOfFile: filePath, encoding: .utf8) {
                        let lines = content.components(separatedBy: .newlines).suffix(50)
                        for line in lines {
                            if let entry = parseApplicationLogLine(line, source: file) {
                                entries.append(entry)
                            }
                        }
                    }
                }
            } catch {
                continue
            }
        }
    }
    
    private func startUnifiedLogging() {
        logQueue.async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
            process.arguments = ["show", "--last", "1h", "--predicate", "category == 'security' OR subsystem == 'com.apple.securityd'"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self?.processUnifiedLogOutput(output)
                    }
                }
            } catch {
                print("Failed to execute log command: \(error)")
            }
        }
    }
    
    private func processUnifiedLogOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines.suffix(100) {
            if let entry = parseUnifiedLogLine(line) {
                entries.insert(entry, at: 0)
            }
        }
        updateCounts()
    }
    
    private func parseSystemLogLine(_ line: String, source: String) -> LogEntry? {
        // System log format: Jan 15 10:30:45 hostname process[pid]: message
        let pattern = #"^(\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2})\s+\w+\s+([^[]+)\[(\d+)\]:\s*(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let timestampStr = String(line[Range(match.range(at: 1), in: line)!])
        let process = String(line[Range(match.range(at: 2), in: line)!])
        let message = String(line[Range(match.range(at: 4), in: line)!])
        
        return LogEntry(
            timestamp: parseSystemTimestamp(timestampStr),
            level: inferLogLevel(from: message),
            component: "\(source):\(process)",
            message: message,
            fullText: line
        )
    }
    
    private func parseApplicationLogLine(_ line: String, source: String) -> LogEntry? {
        // Various application log formats
        if line.isEmpty { return nil }
        
        let level = inferLogLevel(from: line)
        let timestamp = Date() // Use current time if parsing fails
        
        return LogEntry(
            timestamp: timestamp,
            level: level,
            component: source,
            message: line.trimmingCharacters(in: .whitespacesAndNewlines),
            fullText: line
        )
    }
    
    private func parseUnifiedLogLine(_ line: String) -> LogEntry? {
        // Unified log format: 2025-01-15 10:30:45.123456-0800  0x12345  Default     0x0      123    0    process: (subsystem) message
        let pattern = #"^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+[+-]\d{4})\s+\w+\s+(\w+)\s+\w+\s+\d+\s+\d+\s+([^:]+):\s*\(([^)]+)\)\s*(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let timestampStr = String(line[Range(match.range(at: 1), in: line)!])
        let levelStr = String(line[Range(match.range(at: 2), in: line)!])
        let process = String(line[Range(match.range(at: 3), in: line)!])
        let subsystem = String(line[Range(match.range(at: 4), in: line)!])
        let message = String(line[Range(match.range(at: 5), in: line)!])
        
        return LogEntry(
            timestamp: parseUnifiedTimestamp(timestampStr),
            level: mapUnifiedLogLevel(levelStr),
            component: "\(process):\(subsystem)",
            message: message,
            fullText: line
        )
    }
    
    private func inferLogLevel(from message: String) -> LogEntry.LogLevel {
        let lowercased = message.lowercased()
        
        if lowercased.contains("error") || lowercased.contains("failed") || lowercased.contains("denied") {
            return .error
        }
        if lowercased.contains("warning") || lowercased.contains("warn") {
            return .warning
        }
        if lowercased.contains("critical") || lowercased.contains("fatal") || lowercased.contains("panic") {
            return .critical
        }
        if lowercased.contains("debug") {
            return .debug
        }
        
        return .info
    }
    
    private func parseSystemTimestamp(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: str) {
            // Add current year
            let calendar = Calendar.current
            let year = calendar.component(.year, from: Date())
            return calendar.date(bySetting: .year, value: year, of: date) ?? Date()
        }
        
        return Date()
    }
    
    private func parseUnifiedTimestamp(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSz"
        return formatter.date(from: str) ?? Date()
    }
    
    private func mapUnifiedLogLevel(_ level: String) -> LogEntry.LogLevel {
        switch level.lowercased() {
        case "error", "fault": return .error
        case "info", "default": return .info
        case "debug": return .debug
        default: return .info
        }
    }
    
    private func startFileMonitoring() {
        for (source, path) in logSources {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            
            let fileDescriptor = open(path, O_EVTONLY)
            guard fileDescriptor >= 0 else { continue }
            
            let source_obj = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: .write,
                queue: logQueue
            )
            
            source_obj.setEventHandler { [weak self] in
                self?.reloadLogSource(path: path, source: source)
            }
            
            source_obj.setCancelHandler {
                close(fileDescriptor)
            }
            
            source_obj.resume()
            monitors[source] = source_obj
        }
        
        isMonitoring = true
    }
    
    private func reloadLogSource(path: String, source: String) {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        
        let lines = content.components(separatedBy: .newlines).suffix(10) // Last 10 new lines
        
        DispatchQueue.main.async { [weak self] in
            for line in lines {
                if let entry = self?.parseSystemLogLine(line, source: source) {
                    self?.entries.insert(entry, at: 0)
                }
            }
            self?.updateCounts()
        }
    }
    
    private func updateCounts() {
        totalCount = entries.count
        errorCount = entries.filter { $0.level == .error }.count
        warningCount = entries.filter { $0.level == .warning }.count
        criticalCount = entries.filter { $0.level == .critical }.count
        
        // Sort entries by timestamp (newest first)
        entries.sort { $0.timestamp > $1.timestamp }
        
        // Limit to 1000 entries for performance
        if entries.count > 1000 {
            entries = Array(entries.prefix(1000))
        }
    }
    
    func log(_ message: String, level: LogEntry.LogLevel = .info, component: String = "Application") {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            component: component,
            message: message,
            fullText: "[\(level.rawValue.uppercased())] [\(component)] \(message)"
        )
        
        entries.insert(entry, at: 0)
        updateCounts()
    }
    
    func loadLogFile(from path: String, enableMonitoring: Bool = true) {
        // Legacy compatibility
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            let lines = content.components(separatedBy: .newlines)
            for line in lines.suffix(100) {
                if let entry = parseApplicationLogLine(line, source: "custom") {
                    entries.append(entry)
                }
            }
            updateCounts()
        }
    }
    
    func setAutoRefresh(_ enabled: Bool) {
        if enabled {
            startMultiSourceMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    func detectPatterns() -> [(pattern: String, count: Int)] {
        var patterns: [String: Int] = [:]
        
        for entry in entries {
            let key = "\(entry.component): \(entry.level.rawValue)"
            patterns[key, default: 0] += 1
        }
        
        return patterns.sorted { $0.1 > $1.1 }.prefix(5).map { ($0.0, $0.1) }
    }
    
    private func stopMonitoring() {
        for (_, monitor) in monitors {
            monitor.cancel()
        }
        monitors.removeAll()
        isMonitoring = false
    }
    
    deinit {
        stopMonitoring()
    }
}
