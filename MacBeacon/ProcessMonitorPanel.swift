import SwiftUI

struct ProcessMonitorPanel: View {
    @ObservedObject var endpointMonitor: EndpointSecurityMonitor
    @State private var selectedProcess: ProcessEvent?
    @State private var filterType = "All"
    
    var filteredProcesses: [ProcessEvent] {
        switch filterType {
        case "High Risk": return endpointMonitor.processEvents.filter { $0.riskLevel == .high }
        case "Medium Risk": return endpointMonitor.processEvents.filter { $0.riskLevel == .medium }
        case "Executions": return endpointMonitor.processEvents.filter { $0.eventType == .execution }
        default: return Array(endpointMonitor.processEvents.prefix(50))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PROCESS MONITOR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Filter picker
                Picker("Filter", selection: $filterType) {
                    Text("All").tag("All")
                    Text("High Risk").tag("High Risk")
                    Text("Medium Risk").tag("Medium Risk")
                    Text("Executions").tag("Executions")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 280)
            }
            .padding()
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Process list
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredProcesses) { process in
                        ProcessEventRow(
                            process: process,
                            isSelected: selectedProcess?.id == process.id
                        )
                        .onTapGesture {
                            selectedProcess = process
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Process details
            if let selected = selectedProcess {
                ProcessDetailsView(process: selected)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
        )
    }
}

struct ProcessEventRow: View {
    let process: ProcessEvent
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Risk indicator
            Image(systemName: "circle.fill")
                .foregroundColor(process.riskLevel.color)
                .font(.system(size: 8))
                .padding(.trailing, 4)

            // Process info
            VStack(alignment: .leading, spacing: 2) {
                Text(processName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                
                Text(process.executable)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(process.timestamp, style: .time)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
        )
    }
    
    private var processName: String {
        URL(fileURLWithPath: process.executable).lastPathComponent
    }
}

struct ProcessDetailsView: View {
    let process: ProcessEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Process Details")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Kill Process") {
                    // Implement process termination
                }
                .font(.system(size: 9))
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.2))
                .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(label: "PID", value: "\(process.pid)")
                DetailRow(label: "PPID", value: "\(process.ppid)")
                DetailRow(label: "Executable", value: process.executable)
                DetailRow(label: "Risk Level", value: process.riskLevel.rawValue)
                
                if !process.arguments.isEmpty {
                    Text("Arguments:")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text(process.arguments.joined(separator: " "))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(process.riskLevel.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.bottom)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct StatItem: View {
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
