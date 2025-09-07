import SwiftUI

struct DetailView: View {
    @State private var selectedLog: LogEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let log = selectedLog {
                // Header
                HStack {
                    Text("Security Event Details")
                        .font(.headline)
                    Spacer()
                    if log.level == .critical {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.purple)
                    }
                }
                
                // Timestamp
                Group {
                    Text("Timestamp")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(log.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.system(.body, design: .monospaced))
                }
                
                // Severity Level
                Group {
                    Text("Severity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Circle()
                            .fill(log.level.color)
                            .frame(width: 10, height: 10)
                        Text(log.level.rawValue)
                            .foregroundColor(log.level.color)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(log.level == .critical ? .bold : .regular)
                    }
                }
                
                // Component
                Group {
                    Text("Component")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(log.component)
                        .font(.system(.body, design: .monospaced))
                }
                
                // Message
                Group {
                    Text("Event Message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(log.message)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
                
                Divider()
                
                // Full Raw Log
                Group {
                    Text("Raw Log Entry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(log.fullText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // Actions
                HStack {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(log.fullText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Export") {
                        exportLog()
                    }
                    .buttonStyle(.bordered)
                    
                    if log.level == .critical || log.level == .error {
                        Button("Search Similar") {
                            searchSimilar()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Spacer()
            } else {
                Text("Event Details")
                    .font(.headline)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                    .padding()
                
                Text("Select a log entry to view details")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: .logSelected)) { notification in
            if let log = notification.userInfo?["log"] as? LogEntry {
                selectedLog = log
            }
        }
    }
    
    func exportLog() {
        guard let log = selectedLog else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "defender_event_\(log.timestamp.timeIntervalSince1970).txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let content = """
            Microsoft Defender Event Export
            ================================
            Timestamp: \(log.timestamp.formatted())
            Severity: \(log.level.rawValue)
            Component: \(log.component)
            
            Message:
            \(log.message)
            
            Raw Log:
            \(log.fullText)
            """
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    func searchSimilar() {
        // This would trigger a search for similar log entries
        // For now, just copy the message pattern to clipboard
        if let log = selectedLog {
            let searchPattern = String(log.message.prefix(50))
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(searchPattern, forType: .string)
        }
    }
}