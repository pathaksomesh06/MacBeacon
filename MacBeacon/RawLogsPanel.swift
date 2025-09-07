import SwiftUI

struct RawLogsPanel: View {
    @ObservedObject var logService: LogFileService
    @State private var searchText = ""
    
    var displayedLogs: [LogEntry] {
        var logs = logService.entries
        
        if !searchText.isEmpty {
            logs = logs.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.component.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return logs
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Raw Logs")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(displayedLogs.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Filter logs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Logs List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(displayedLogs) { log in
                        RawLogRow(log: log)
                        Divider()
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct RawLogRow: View {
    let log: LogEntry
    @State private var isExpanded = false
    
    var threadId: String {
        // Extract thread/PID from log if available
        if let range = log.fullText.range(of: #"\[(\d+)\]"#, options: .regularExpression) {
            return String(log.fullText[range])
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // Expand button
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Level indicator
                Circle()
                    .fill(log.level.color)
                    .frame(width: 6, height: 6)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(log.timestamp, style: .time)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text(log.component)
                            .font(.system(size: 11))
                            .foregroundColor(.blue)
                        
                        if !threadId.isEmpty {
                            Text("Thread \(threadId)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    
                    Text(log.message)
                        .font(.system(size: 12, design: .monospaced))
                        .lineLimit(isExpanded ? nil : 2)
                        .textSelection(.enabled)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                        .padding(.leading, 30)
                    
                    Text("Full Log:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 30)
                    
                    Text(log.fullText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .padding(.leading, 30)
                        .padding(.trailing, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}