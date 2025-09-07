import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let log = UTType(filenameExtension: "log", conformingTo: .plainText)!
}

struct MainView: View {
    @StateObject private var logService = LogFileService()
    @State private var fileAccessStatus = "No file loaded"
    @State private var selectedLogPath: String?
    @State private var autoRefresh = true
    @FocusState private var searchFieldFocused: Bool
    
    private let defenderLogPath = "/Library/Logs/Microsoft/mdatp/rotated"
    
    var body: some View {
        NavigationSplitView {
            SidebarView(logService: logService)
                .navigationSplitViewColumnWidth(250)
        } content: {
            LogListView(logService: logService, searchFieldFocused: $searchFieldFocused)
                .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: 900)
        } detail: {
            DetailView()
                .navigationSplitViewColumnWidth(250)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Load Latest Defender Log") {
                    loadLatestDefenderLog()
                }
                .keyboardShortcut("d", modifiers: [.command])
            }
            ToolbarItem(placement: .automatic) {
                Button("Browse...") {
                    openLogFile()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
            ToolbarItem(placement: .automatic) {
                Menu("Export") {
                    Button("Export All (CSV)") {
                        exportLogs(filtered: false)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    
                    Button("Export Critical & Errors (CSV)") {
                        exportCriticalAndErrors()
                    }
                    
                    Divider()
                    
                    Button("Export Security Report") {
                        exportSecurityReport()
                    }
                }
                .disabled(logService.entries.isEmpty)
            }
            ToolbarItem(placement: .automatic) {
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .keyboardShortcut("r", modifiers: [.command])
            }
            ToolbarItem(placement: .automatic) {
                Text(fileAccessStatus)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
        .onChange(of: autoRefresh) {
            logService.setAutoRefresh(autoRefresh)
        }
    }
    
    func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
                searchFieldFocused = true
                return nil
            }
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "l" {
                loadLatestDefenderLog()
                return nil
            }
            return event
        }
    }
    
    func loadLatestDefenderLog() {
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: defenderLogPath) else {
            fileAccessStatus = "⚠️ Defender log folder not found"
            return
        }
        
        do {
            let files = try fm.contentsOfDirectory(atPath: defenderLogPath)
            let logFiles = files.filter { $0.hasSuffix(".log") || $0.hasSuffix(".json") }
            
            guard !logFiles.isEmpty else {
                fileAccessStatus = "⚠️ No log files found"
                return
            }
            
            // Get the latest modified log file
            var latestFile: String?
            var latestDate = Date.distantPast
            
            for file in logFiles {
                let filePath = "\(defenderLogPath)/\(file)"
                if let attributes = try? fm.attributesOfItem(atPath: filePath),
                   let modDate = attributes[.modificationDate] as? Date,
                   modDate > latestDate {
                    latestDate = modDate
                    latestFile = file
                }
            }
            
            if let latest = latestFile {
                let fullPath = "\(defenderLogPath)/\(latest)"
                selectedLogPath = fullPath
                fileAccessStatus = "✅ Loaded: \(latest)"
                logService.loadLogFile(from: fullPath)
            }
        } catch {
            fileAccessStatus = "⚠️ Error reading folder"
        }
    }
    
    func openLogFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .log, .json]
        panel.directoryURL = URL(fileURLWithPath: defenderLogPath)
        
        if panel.runModal() == .OK, let path = panel.url?.path {
            selectedLogPath = path
            fileAccessStatus = "✅ File loaded"
            logService.loadLogFile(from: path)
        }
    }
    
    func exportLogs(filtered: Bool) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "defender_logs_\(Int(Date().timeIntervalSince1970)).csv"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            exportToCSV(logs: logService.entries, to: url)
        }
    }
    
    func exportCriticalAndErrors() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "defender_critical_\(Int(Date().timeIntervalSince1970)).csv"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let criticalLogs = logService.entries.filter { 
                $0.level == .error || $0.level == .critical 
            }
            exportToCSV(logs: criticalLogs, to: url)
        }
    }
    
    func exportToCSV(logs: [LogEntry], to url: URL) {
        var csv = "Timestamp,Level,Component,Message\n"
        
        for log in logs {
            let timestamp = ISO8601DateFormatter().string(from: log.timestamp)
            let row = "\"\(timestamp)\",\"\(log.level.rawValue)\",\"\(log.component)\",\"\(log.message.replacingOccurrences(of: "\"", with: "\"\""))\"\n"
            csv += row
        }
        
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportSecurityReport() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "defender_security_report_\(Int(Date().timeIntervalSince1970)).txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let threatPatterns = logService.detectPatterns()
            let criticalPercentage = logService.totalCount > 0 ? (logService.criticalCount * 100) / logService.totalCount : 0
            let errorPercentage = logService.totalCount > 0 ? (logService.errorCount * 100) / logService.totalCount : 0
            let warningPercentage = logService.totalCount > 0 ? (logService.warningCount * 100) / logService.totalCount : 0
            
            var report = """
            MICROSOFT DEFENDER FOR ENDPOINT - SECURITY LOG ANALYSIS REPORT
            ================================================================
            Generated: \(Date().formatted())
            Log File: \(selectedLogPath ?? "Unknown")
            
            ========== EXECUTIVE SUMMARY ==========
            Total Log Entries: \(logService.totalCount)
            Critical Issues: \(logService.criticalCount) (\(criticalPercentage)%)
            Errors: \(logService.errorCount) (\(errorPercentage)%)
            Warnings: \(logService.warningCount) (\(warningPercentage)%)
            Info/Debug: \(logService.totalCount - logService.criticalCount - logService.errorCount - logService.warningCount)
            
            ========== THREAT PATTERNS DETECTED ==========
            \(threatPatterns.isEmpty ? "No specific threat patterns identified" : threatPatterns.map { "- \($0.pattern): \($0.count) occurrences" }.joined(separator: "\n"))
            
            ========== CRITICAL SECURITY EVENTS ==========
            """
            
            let criticals = logService.entries.filter { $0.level == .critical }
            if criticals.isEmpty {
                report += "\nNo critical events found."
            } else {
                for log in criticals.prefix(50) {
                    report += "\n\(log.timestamp.formatted())\t[\(log.level.rawValue)]\t\(log.component)\t\(log.message)"
                }
            }
            
            report += "\n\n========== HIGH PRIORITY ERRORS ==========\n"
            let errors = logService.entries.filter { $0.level == .error }
            if errors.isEmpty {
                report += "No error events found."
            } else {
                for log in errors.prefix(50) {
                    report += "\n\(log.timestamp.formatted())\t[\(log.level.rawValue)]\t\(log.component)\t\(log.message)"
                }
            }
            
            try? report.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}