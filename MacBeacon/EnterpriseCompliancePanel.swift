import SwiftUI

struct EnterpriseCompliancePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Compliance Benchmarks")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Industry-standard security framework assessments")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    // Refresh action
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Info action
                }) {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding([.horizontal, .top])
            
            // Frameworks List
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Benchmarks")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
                
                BenchmarkRow(name: "GDPR Compliance Benchmark", icon: "lock.shield")
                BenchmarkRow(name: "NIST Compliance Benchmark", icon: "lock.shield")
                BenchmarkRow(name: "CIS Compliance Benchmark", icon: "lock.shield")
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Last Updated Footer
            HStack {
                Spacer()
                Text("Last Assessed: Not Yet Run")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
        .frame(minHeight: 250)
    }
}

struct BenchmarkRow: View {
    let name: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(name)
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// Use the existing ComplianceStatus enum from EnterpriseCompliance.swift
