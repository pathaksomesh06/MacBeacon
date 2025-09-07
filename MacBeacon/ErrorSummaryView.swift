import SwiftUI

struct ErrorSummaryView: View {
    @ObservedObject var logService: LogFileService
    
    var criticalAndErrorsByComponent: [(component: String, count: Int, isCritical: Bool)] {
        let criticals = logService.entries.filter { $0.level == .critical }
        let errors = logService.entries.filter { $0.level == .error }
        
        let criticalGrouped = Dictionary(grouping: criticals) { $0.component }
        let errorGrouped = Dictionary(grouping: errors) { $0.component }
        
        var result: [(String, Int, Bool)] = []
        
        // Add criticals first
        for (component, entries) in criticalGrouped {
            result.append((component, entries.count, true))
        }
        
        // Add errors
        for (component, entries) in errorGrouped {
            if !criticalGrouped.keys.contains(component) {
                result.append((component, entries.count, false))
            }
        }
        
        return result
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { ($0.0, $0.1, $0.2) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Events")
                .font(.headline)
            
            if criticalAndErrorsByComponent.isEmpty {
                Text("No security events found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(criticalAndErrorsByComponent, id: \.component) { item in
                    HStack {
                        if item.isCritical {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        Text(item.component)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(item.isCritical ? .purple : .red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.isCritical ? Color.purple.opacity(0.15) : Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
    }
}