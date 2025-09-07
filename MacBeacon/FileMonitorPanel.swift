import SwiftUI

struct FileMonitorPanel: View {
    @ObservedObject var endpointMonitor: EndpointSecurityMonitor
    @State private var selectedFile: FileEvent?
    @State private var filterType = "All"
    
    var filteredFiles: [FileEvent] {
        switch filterType {
        case "Creates": return endpointMonitor.fileEvents.filter { $0.operation == .create }
        case "Writes": return endpointMonitor.fileEvents.filter { $0.operation == .write }
        case "Reads": return endpointMonitor.fileEvents.filter { $0.operation == .read }
        default: return Array(endpointMonitor.fileEvents.prefix(50))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FILE SYSTEM MONITOR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Picker("Filter", selection: $filterType) {
                    Text("All").tag("All")
                    Text("Creates").tag("Creates")
                    Text("Writes").tag("Writes")
                    Text("Reads").tag("Reads")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 240)
            }
            .padding()
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // File list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredFiles) { file in
                        FileEventRow(
                            file: file,
                            isSelected: selectedFile?.id == file.id
                        )
                        .onTapGesture {
                            selectedFile = file
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
    }
}

struct FileEventRow: View {
    let file: FileEvent
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Operation icon
            Image(systemName: operationIcon)
                .foregroundColor(operationColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(fileName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(file.timestamp, style: .time)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
        )
    }
    
    private var fileName: String {
        URL(fileURLWithPath: file.filePath).lastPathComponent
    }
    
    private var filePath: String {
        let url = URL(fileURLWithPath: file.filePath)
        return url.deletingLastPathComponent().path
    }
    
    private var operationIcon: String {
        switch file.operation {
        case .create: return "doc.badge.plus"
        case .write: return "pencil"
        case .read: return "eye"
        case .delete: return "trash"
        }
    }
    
    private var operationColor: Color {
        switch file.operation {
        case .create: return .green
        case .write: return .orange
        case .read: return .blue
        case .delete: return .red
        }
    }
}

struct FileStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
