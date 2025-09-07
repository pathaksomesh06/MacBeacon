import SwiftUI

struct ThreatEventsPanel: View {
    @ObservedObject var logService: LogFileService
    @ObservedObject var threatAnalyzer: ThreatAnalyzer
    @Binding var selectedThreat: ThreatEvent?
    @State private var searchText = ""
    
    var filteredEvents: [ThreatEvent] {
        if searchText.isEmpty {
            return threatAnalyzer.threatEvents
        }
        return threatAnalyzer.threatEvents.filter {
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.component.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Security Events (\(threatAnalyzer.threatEvents.count))")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    StatBadge(
                        icon: "exclamationmark.triangle.fill",
                        count: threatAnalyzer.activeThreats,
                        color: .orange,
                        label: "Active"
                    )
                    StatBadge(
                        icon: "shield.slash.fill",
                        count: threatAnalyzer.blockedThreats,
                        color: .red,
                        label: "Blocked"
                    )
                    StatBadge(
                        icon: "magnifyingglass",
                        count: threatAnalyzer.scanEvents,
                        color: .blue,
                        label: "Scans"
                    )
                }
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search events...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Events List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEvents) { event in
                        ThreatEventRow(
                            event: event,
                            isSelected: selectedThreat?.id == event.id
                        )
                        .onTapGesture {
                            selectedThreat = event
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ThreatEventRow: View {
    let event: ThreatEvent
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.type.icon)
                .font(.title2)
                .foregroundColor(event.type.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.type.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                    
                    Spacer()
                    
                    Text(event.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.component)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    // Severity Badge
                    Text(event.severity.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.severity.color.opacity(0.2))
                        .foregroundColor(event.severity.color)
                        .cornerRadius(4)
                    
                    // Status Badge
                    Text(event.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(event.status.color.opacity(0.2))
                        .foregroundColor(event.status.color)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if event.count > 1 {
                        Label("\(event.count)", systemImage: "doc.on.doc.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}