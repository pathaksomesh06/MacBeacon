import SwiftUI

struct ThreatDetailsPanel: View {
    @Binding var selectedThreat: ThreatEvent?
    @ObservedObject var logService: LogFileService
    @Binding var filterType: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Threat Analysis")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedThreat != nil {
                    Button("Export") {
                        exportThreatDetails()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Investigate") {
                        investigateThreat()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Divider()
            
            if let threat = selectedThreat {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Threat Overview Card
                        ThreatOverviewCard(threat: threat)
                        
                        // Timeline
                        TimelineCard(threat: threat)
                        
                        // Technical Details
                        TechnicalDetailsCard(threat: threat)
                        
                        // Recommendations
                        RecommendationsCard(threat: threat)
                    }
                    .padding()
                }
            } else {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("Select a security event to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Microsoft Defender for Endpoint")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    func exportThreatDetails() {
        guard let threat = selectedThreat else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "threat_\(threat.timestamp.timeIntervalSince1970).txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let content = generateThreatReport(threat)
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    func investigateThreat() {
        // Trigger deeper investigation
        guard let threat = selectedThreat else { return }
        // This would integrate with additional security tools
        print("Investigating threat: \(threat.description)")
    }
    
    func generateThreatReport(_ threat: ThreatEvent) -> String {
        """
        THREAT ANALYSIS REPORT
        ======================
        
        Event Type: \(threat.type.rawValue)
        Timestamp: \(threat.timestamp.formatted())
        Severity: \(threat.severity.rawValue)
        Status: \(threat.status.rawValue)
        Component: \(threat.component)
        
        Description:
        \(threat.description)
        
        Related Log Entries: \(threat.count)
        Duration: \(threat.duration?.formatted() ?? "N/A")
        
        Raw Logs:
        \(threat.relatedLogs.map { $0.fullText }.joined(separator: "\n"))
        """
    }
}

struct ThreatOverviewCard: View {
    let threat: ThreatEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Overview", systemImage: "info.circle.fill")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Event Type:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Label(threat.type.rawValue, systemImage: threat.type.icon)
                            .foregroundColor(threat.type.color)
                    }
                    
                    HStack {
                        Text("Severity:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(threat.severity.rawValue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(threat.severity.color.opacity(0.2))
                            .foregroundColor(threat.severity.color)
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(threat.status.rawValue)
                            .fontWeight(.semibold)
                            .foregroundColor(threat.status.color)
                    }
                    
                    Divider()
                    
                    Text(threat.description)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(8)
            }
        }
    }
}

struct TimelineCard: View {
    let threat: ThreatEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Timeline", systemImage: "clock.fill")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text("First Detected:")
                        Spacer()
                        Text(threat.timestamp.formatted(date: .abbreviated, time: .standard))
                            .font(.system(.caption, design: .monospaced))
                    }
                    
                    if let duration = threat.duration {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text("Duration:")
                            Spacer()
                            Text(formatDuration(duration))
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(.green)
                        Text("Events Count:")
                        Spacer()
                        Text("\(threat.count)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .padding(8)
            }
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }
}

struct TechnicalDetailsCard: View {
    let threat: ThreatEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Technical Details", systemImage: "cpu.fill")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Component:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(threat.component)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    if threat.relatedLogs.contains(where: { $0.message.contains("PID") }) {
                        HStack {
                            Text("Process Info:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(extractProcessInfo(from: threat))
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    
                    if let filePath = extractFilePath(from: threat) {
                        HStack(alignment: .top) {
                            Text("File Path:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(filePath)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(8)
            }
        }
    }
    
    func extractProcessInfo(from threat: ThreatEvent) -> String {
        // Extract process information from logs
        for log in threat.relatedLogs {
            if log.message.contains("PID") {
                return log.message
            }
        }
        return "N/A"
    }
    
    func extractFilePath(from threat: ThreatEvent) -> String? {
        // Extract file paths from logs
        for log in threat.relatedLogs {
            if log.message.contains("/") || log.message.contains("\\") {
                // Simple extraction - in production would use regex
                return nil // Return extracted path
            }
        }
        return nil
    }
}

struct RecommendationsCard: View {
    let threat: ThreatEvent
    
    var recommendations: [String] {
        var recs: [String] = []
        
        switch threat.severity {
        case .critical:
            recs.append("Immediate action required - isolate affected systems")
            recs.append("Run full system scan")
            recs.append("Review security policies")
        case .high:
            recs.append("Investigate threat source")
            recs.append("Update security definitions")
        case .medium:
            recs.append("Monitor for recurring patterns")
            recs.append("Schedule regular scans")
        default:
            recs.append("Continue monitoring")
        }
        
        if threat.status == .active {
            recs.append("Consider manual intervention")
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                            Text(rec)
                                .font(.callout)
                        }
                    }
                }
                .padding(8)
            }
        }
    }
}