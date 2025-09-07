import SwiftUI

struct FileListSidebar: View {
    @ObservedObject var logService: EnhancedLogService
    @State private var expandedSections = Set<String>()
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                    Text("Defender Logs")
                    Spacer()
                    Text("\(logService.logFiles.count) files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            ForEach(logService.logFiles) { file in
                FileRowView(
                    file: file,
                    isSelected: logService.currentFile?.id == file.id,
                    action: { logService.selectLogFile(file) }
                )
            }
            
            if logService.isAnalyzing {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section("Analysis Summary") {
                if let currentFile = logService.currentFile {
                    StatRow(icon: "doc", label: "Entries", value: "\(currentFile.entryCount)", color: .blue)
                    StatRow(icon: "exclamationmark.octagon", label: "Critical", value: "\(currentFile.criticalCount)", color: .purple)
                    StatRow(icon: "exclamationmark.circle", label: "Errors", value: "\(currentFile.errorCount)", color: .red)
                    StatRow(icon: "exclamationmark.triangle", label: "Warnings", value: "\(currentFile.warningCount)", color: .orange)
                }
            }
            
            Section("Event Types") {
                ForEach(DefenderEvent.EventType.allCases, id: \.self) { type in
                    let count = logService.events.filter { $0.type == type }.count
                    if count > 0 {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                                .frame(width: 20)
                            Text(type.rawValue)
                                .font(.caption)
                            Spacer()
                            Text("\(count)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
}

struct FileRowView: View {
    let file: EnhancedLogService.LogFile
    let isSelected: Bool
    let action: () -> Void
    
    var sizeString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: file.size)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(file.modifiedDate, format: .dateTime.hour().minute())
                            .font(.caption2)
                        Text("•")
                            .font(.caption2)
                        Text(sizeString)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if file.criticalCount > 0 || file.errorCount > 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(file.criticalCount > 0 ? .purple : .orange)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var statusIcon: String {
        if file.criticalCount > 0 { return "exclamationmark.octagon.fill" }
        if file.errorCount > 0 { return "exclamationmark.circle.fill" }
        if file.warningCount > 0 { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }
    
    var statusColor: Color {
        if file.criticalCount > 0 { return .purple }
        if file.errorCount > 0 { return .red }
        if file.warningCount > 0 { return .orange }
        return .green
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}