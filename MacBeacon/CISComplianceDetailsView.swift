import SwiftUI

struct CISComplianceDetailsView: View {
    @ObservedObject var cisService: CISComplianceService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Operating System", "System Settings", "Password Policy", "Access Control", "Security"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title)
                            .foregroundColor(cisService.getComplianceColor())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CIS Level 1 Compliance")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(cisService.getComplianceSummary())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Run Audit") {
                            cisService.runCISAudit()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(cisService.isLoading)
                    }
                    
                    // Compliance Status Bar
                    if let result = cisService.complianceResult {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Compliance Status:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text(cisService.getComplianceStatus())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(cisService.getComplianceColor())
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(cisService.getComplianceColor())
                                        .frame(width: geometry.size.width * (result.compliancePercentage / 100), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            HStack {
                                Text("\(Int(result.compliancePercentage))% Compliant")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(result.compliant)/\(result.totalRules) Rules")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                .padding()
                
                Divider()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .background(selectedCategory == category ? Color.accentColor : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Findings List
                if cisService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Running CIS Level 1 audit...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result = cisService.complianceResult {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFindings(result.findings)) { finding in
                                CISFindingRow(finding: finding)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.blue.opacity(0.5))
                        
                        Text("No CIS audit data available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Run a CIS Level 1 audit to view compliance details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Run CIS Audit") {
                            cisService.runCISAudit()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("CIS Compliance Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func filteredFindings(_ findings: [CISFinding]) -> [CISFinding] {
        if selectedCategory == "All" {
            return findings
        }
        return findings.filter { $0.category == selectedCategory }
    }
}

struct CISFindingRow: View {
    let finding: CISFinding
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(finding.ruleName.replacingOccurrences(of: "audit_", with: "").replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(finding.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status Badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
                
                Text(finding.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var statusIcon: String {
        if finding.exempt {
            return "minus.circle.fill"
        } else if finding.compliant {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if finding.exempt {
            return .orange
        } else if finding.compliant {
            return .green
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if finding.exempt {
            return "EXEMPT"
        } else if finding.compliant {
            return "COMPLIANT"
        } else {
            return "NON-COMPLIANT"
        }
    }
}

#Preview {
    CISComplianceDetailsView(cisService: CISComplianceService())
}
