import SwiftUI
import UniformTypeIdentifiers

struct ComplianceReportingPanel: View {
    @ObservedObject var complianceEngine: PolicyComplianceEngine
    @StateObject private var reportHistory = ReportHistory()
    @State private var selectedExportFormat: ExportFormat = .pdf
    @State private var showingExportOptions = false
    @State private var exportInProgress = false
    @State private var exportSuccess = false
    @State private var exportError: String?
    @State private var exportedFileURL: URL?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.chart")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Compliance Reporting")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Generate and export compliance reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingExportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Quick Export Buttons
            HStack(spacing: 12) {
                QuickExportButton(
                    title: "Compliance Report",
                    subtitle: "Full policy analysis",
                    icon: "doc.text.magnifyingglass",
                    action: { exportComplianceReport() }
                )
                
                QuickExportButton(
                    title: "Security Posture",
                    subtitle: "Current status summary",
                    icon: "shield.checkered",
                    action: { exportSecurityPosture() }
                )
            }
            
            // Export Status
            if exportInProgress {
                ExportProgressView()
            } else if exportSuccess {
                ExportSuccessView(fileURL: exportedFileURL)
            } else if let error = exportError {
                ExportErrorView(error: error)
            }
            
            // Recent Reports
            RecentReportsSection(reportHistory: reportHistory)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsSheet(
                selectedFormat: $selectedExportFormat,
                onExport: { format in
                    selectedExportFormat = format
                    showingExportOptions = false
                    exportComplianceReport()
                }
            )
        }
    }
    
    private func exportComplianceReport() {
        exportInProgress = true
        exportError = nil
        exportSuccess = false
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [selectedExportFormat.contentType]
        savePanel.nameFieldStringValue = "ComplianceReport.\(selectedExportFormat.rawValue.lowercased())"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let success = complianceEngine.exportComplianceReport(to: url, format: selectedExportFormat)
                    
                    DispatchQueue.main.async {
                        exportInProgress = false
                        if success {
                            exportedFileURL = url
                            exportSuccess = true
                            reportHistory.addReport(title: "Compliance Report", format: selectedExportFormat, url: url)
                        } else {
                            exportError = "Failed to export compliance report."
                        }
                    }
                }
            } else {
                exportInProgress = false
            }
        }
    }
    
    private func exportSecurityPosture() {
        exportInProgress = true
        exportError = nil
        exportSuccess = false
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [selectedExportFormat.contentType]
        savePanel.nameFieldStringValue = "SecurityPostureSummary.\(selectedExportFormat.rawValue.lowercased())"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let success = complianceEngine.exportSecurityPostureSummary(to: url, format: selectedExportFormat)
                    
                    DispatchQueue.main.async {
                        exportInProgress = false
                        if success {
                            exportedFileURL = url
                            exportSuccess = true
                            reportHistory.addReport(title: "Security Posture Summary", format: selectedExportFormat, url: url)
                        } else {
                            exportError = "Failed to export security posture summary."
                        }
                    }
                }
            } else {
                exportInProgress = false
            }
        }
    }
}

// MARK: - Quick Export Button
struct QuickExportButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Export Progress View
struct ExportProgressView: View {
    @State private var progressValue: Double = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                
                Text("\(Int(progressValue * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Generating report...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                progressValue = 1.0
            }
        }
    }
}

// MARK: - Export Success View
struct ExportSuccessView: View {
    let fileURL: URL?
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Export successful!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let url = fileURL {
                    Text("Saved to: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Export Error View
struct ExportErrorView: View {
    let error: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Recent Reports Section
struct RecentReportsSection: View {
    @ObservedObject var reportHistory: ReportHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Reports")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if reportHistory.reports.isEmpty {
                Text("No reports generated yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(reportHistory.reports) { report in
                        RecentReportRow(
                            title: report.title,
                            date: report.dateString,
                            format: report.format.rawValue,
                            status: "Generated"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Report History Management
class ReportHistory: ObservableObject {
    @Published var reports: [Report] = []
    
    func addReport(title: String, format: ExportFormat, url: URL) {
        let newReport = Report(title: title, format: format, url: url)
        reports.insert(newReport, at: 0)
    }
}

struct Report: Identifiable {
    let id = UUID()
    let title: String
    let date: Date = Date()
    let format: ExportFormat
    let url: URL
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Recent Report Row
struct RecentReportRow: View {
    let title: String
    let date: String
    let format: String
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(format)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(status)
                .font(.caption2)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Export Options Sheet
struct ExportOptionsSheet: View {
    @Binding var selectedFormat: ExportFormat
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Format Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Export Format")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        FormatOptionCard(
                            format: format,
                            isSelected: selectedFormat == format,
                            onTap: { selectedFormat = format }
                        )
                    }
                }
            }
            
            // Export Button
            Button(action: {
                onExport(selectedFormat)
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Report")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export Options")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Format Option Card
struct FormatOptionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: formatIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(format.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(formatDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formatIcon: String {
        switch format {
        case .pdf: return "doc.text"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        case .html: return "globe"
        }
    }
    
    private var formatDescription: String {
        switch format {
        case .pdf: return "Professional document format"
        case .csv: return "Spreadsheet compatible"
        case .json: return "Machine readable data"
        case .html: return "Web browser format"
        }
    }
}

#Preview {
    ComplianceReportingPanel(complianceEngine: PolicyComplianceEngine())
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
}
