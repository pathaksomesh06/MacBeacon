import SwiftUI

struct EnhancedMainView: View {
    @StateObject private var logService = LogFileService()
    @StateObject private var threatAnalyzer = ThreatAnalyzer()
    @State private var selectedThreat: ThreatEvent?
    @State private var showRawLogs = true
    @State private var autoRefresh = true
    @State private var filterType = "All Events"
    
    var body: some View {
        HSplitView {
            // Left Panel - Threat Events
            ThreatEventsPanel(
                logService: logService,
                threatAnalyzer: threatAnalyzer,
                selectedThreat: $selectedThreat
            )
            .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
            
            // Center Panel - Threat Details
            ThreatDetailsPanel(
                selectedThreat: $selectedThreat,
                logService: logService,
                filterType: $filterType
            )
            .frame(minWidth: 500, idealWidth: 700)
            
            // Right Panel - Raw Logs
            if showRawLogs {
                RawLogsPanel(
                    logService: logService
                )
                .frame(minWidth: 350, idealWidth: 450, maxWidth: 500)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: loadDefenderLogs) {
                    Label("Load Logs", systemImage: "arrow.clockwise")
                }
                
                Toggle(isOn: $showRawLogs) {
                    Image(systemName: "sidebar.right")
                }
                .toggleStyle(.button)
            }
            
            ToolbarItemGroup(placement: .automatic) {
                Picker("Filter", selection: $filterType) {
                    Text("All Events").tag("All Events")
                    Text("Threats").tag("Threats")
                    Text("Scans").tag("Scans")
                    Text("Updates").tag("Updates")
                    Text("Network").tag("Network")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 400)
                
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .toggleStyle(.switch)
            }
        }
        .onAppear {
            loadDefenderLogs()
            threatAnalyzer.analyze(logs: logService.entries)
        }
    }
    
    func loadDefenderLogs() {
        let path = "/Library/Logs/Microsoft/mdatp/microsoft_defender_core.log"
        logService.loadLogFile(from: path)
        threatAnalyzer.analyze(logs: logService.entries)
    }
}
