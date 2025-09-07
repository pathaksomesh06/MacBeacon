import SwiftUI

struct EventsListView: View {
    @ObservedObject var logService: EnhancedLogService
    @State private var selectedEventType: DefenderEvent.EventType?
    @State private var showOnlyErrors = false
    
    var filteredEvents: [DefenderEvent] {
        var events = logService.events
        
        if let eventType = selectedEventType {
            events = events.filter { $0.type == eventType }
        }
        
        if showOnlyErrors {
            events = events.filter { $0.errorCount > 0 || $0.status == .failed }
        }
        
        return events
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                Menu {
                    Button("All Types") {
                        selectedEventType = nil
                    }
                    Divider()
                    ForEach(DefenderEvent.EventType.allCases, id: \.self) { type in
                        Button(action: { selectedEventType = type }) {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedEventType?.icon ?? "line.3.horizontal.decrease.circle")
                        Text(selectedEventType?.rawValue ?? "All Events")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Toggle(isOn: $showOnlyErrors) {
                    Label("Errors Only", systemImage: "exclamationmark.circle")
                }
                .toggleStyle(.button)
                
                Spacer()
                
                Text("\(filteredEvents.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Events list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEvents) { event in
                        EventCardView(event: event, isSelected: logService.selectedEvent?.id == event.id) {
                            logService.selectedEvent = event
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct EventCardView: View {
    let event: DefenderEvent
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: event.type.icon)
                        .foregroundColor(event.type.color)
                    
                    Text(event.type.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
                    StatusBadge(status: event.status)
                    
                    Text(event.startTime, format: .dateTime.hour().minute().second())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Component and Thread
                HStack {
                    if let firstEntry = event.details.first {
                        Label(firstEntry.component, systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("Thread \(event.threadId)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if event.duration != nil {
                        Label(event.durationString, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats bar
                HStack(spacing: 16) {
                    if event.errorCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("\(event.errorCount) errors")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    if event.warningCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            Text("\(event.warningCount) warnings")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("\(event.details.count) log entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // Preview message
                if let lastMessage = event.details.last?.message {
                    Text(lastMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusBadge: View {
    let status: DefenderEvent.EventStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    var statusText: String {
        switch status {
        case .completed: return "COMPLETED"
        case .inProgress: return "IN PROGRESS"
        case .failed: return "FAILED"
        case .warning: return "WARNING"
        }
    }
}