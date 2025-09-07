import SwiftUI

struct SidebarView: View {
    @ObservedObject var logService: LogFileService
    @State private var currentFileName = "No file loaded"
    
    var body: some View {
        List {
            Section("File") {
                HStack {
                    Image(systemName: "doc.text")
                    Text(currentFileName)
                        .lineLimit(1)
                }
                
                if logService.isMonitoring {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        Text("Live monitoring")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section("Security Overview") {
                Label("Total: \(logService.totalCount)", systemImage: "list.bullet")
                Label("Critical: \(logService.criticalCount)", systemImage: "exclamationmark.octagon.fill")
                    .foregroundColor(.purple)
                Label("Errors: \(logService.errorCount)", systemImage: "exclamationmark.circle")
                    .foregroundColor(.red)
                Label("Warnings: \(logService.warningCount)", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }
            
            if logService.totalCount > 0 {
                Section("Threat Analysis") {
                    VStack(alignment: .leading) {
                        Text("Critical Rate: \(criticalPercentage)%")
                            .font(.caption)
                            .foregroundColor(criticalPercentage > 0 ? .purple : .secondary)
                        Text("Error Rate: \(errorPercentage)%")
                            .font(.caption)
                            .foregroundColor(errorPercentage > 5 ? .red : .secondary)
                        Text("Warning Rate: \(warningPercentage)%")
                            .font(.caption)
                            .foregroundColor(warningPercentage > 10 ? .orange : .secondary)
                    }
                }
                
                if logService.criticalCount > 0 || logService.errorCount > 0 {
                    Section("Security Events") {
                        ErrorSummaryView(logService: logService)
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
        .onReceive(NotificationCenter.default.publisher(for: .fileLoaded)) { notification in
            if let path = notification.userInfo?["path"] as? String {
                currentFileName = URL(fileURLWithPath: path).lastPathComponent
            }
        }
    }
    
    var criticalPercentage: Int {
        guard logService.totalCount > 0 else { return 0 }
        return (logService.criticalCount * 100) / logService.totalCount
    }
    
    var errorPercentage: Int {
        guard logService.totalCount > 0 else { return 0 }
        return (logService.errorCount * 100) / logService.totalCount
    }
    
    var warningPercentage: Int {
        guard logService.totalCount > 0 else { return 0 }
        return (logService.warningCount * 100) / logService.totalCount
    }
}

extension Notification.Name {
    static let fileLoaded = Notification.Name("fileLoaded")
}