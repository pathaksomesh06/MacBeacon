import SwiftUI

struct ComplianceDetailsModal: View {
    let framework: String
    let status: ComplianceStatus
    @Binding var isPresented: Bool
    
    // Mock data for demonstration - in real app this would come from compliance service
    private var complianceDetails: FrameworkComplianceDetails {
        switch framework {
        case "ISO 27001":
            return FrameworkComplianceDetails(
                framework: .iso27001,
                status: .nonCompliant,
                overallScore: 67.0,
                failingRequirements: [
                    FrameworkComplianceDetails.FailingRequirement(
                        requirement: "Endpoint Security Monitoring",
                        currentStatus: "Partially Implemented",
                        requiredStatus: "Fully Operational",
                        impact: "Leaves endpoints vulnerable to undetected attacks.",
                        evidence: "Basic monitoring is active, but AI-powered threat detection is missing.",
                        remediationSteps: [
                            "Implement machine learning-based threat detection.",
                            "Configure behavioral analysis rules.",
                            "Set up automated response mechanisms for common threats.",
                            "Train security team on new tools and alert triage."
                        ],
                        estimatedTimeToFix: "4-6 weeks",
                        priority: .high
                    ),
                    FrameworkComplianceDetails.FailingRequirement(
                        requirement: "Data Classification System",
                        currentStatus: "Not Implemented",
                        requiredStatus: "Fully Operational",
                        impact: "Risk of sensitive data exposure and regulatory fines.",
                        evidence: "No data classification system is currently in place.",
                        remediationSteps: [
                            "Implement a data classification framework (e.g., Confidential, Internal, Public).",
                            "Configure automated data discovery and classification tools.",
                            "Set up access controls based on data classification levels.",
                            "Train staff on data handling procedures and policies."
                        ],
                        estimatedTimeToFix: "8-12 weeks",
                        priority: .critical
                    )
                ],
                recommendations: [
                    FrameworkComplianceDetails.ComplianceRecommendation(
                        title: "Implement AI-Powered Threat Detection",
                        description: "Deploy machine learning-based security monitoring to detect advanced threats",
                        priority: .high,
                        estimatedEffort: "Medium",
                        resources: ["Security Engineer", "ML Specialist", "Security Tools"],
                        timeline: "4-6 weeks"
                    ),
                    FrameworkComplianceDetails.ComplianceRecommendation(
                        title: "Establish Data Classification Framework",
                        description: "Create comprehensive data classification system for sensitive information",
                        priority: .critical,
                        estimatedEffort: "High",
                        resources: ["Data Protection Officer", "Legal Team", "IT Security"],
                        timeline: "8-12 weeks"
                    )
                ],
                lastAssessment: Date(),
                nextReviewDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                assessor: "Security Team"
            )
        case "GDPR":
            return FrameworkComplianceDetails(
                framework: .gdpr,
                status: .compliant,
                overallScore: 95.0,
                failingRequirements: [],
                recommendations: [
                    FrameworkComplianceDetails.ComplianceRecommendation(
                        title: "Regular Privacy Impact Assessments",
                        description: "Conduct quarterly privacy impact assessments for new data processing activities",
                        priority: .medium,
                        estimatedEffort: "Low",
                        resources: ["Privacy Officer", "Legal Team"],
                        timeline: "Ongoing"
                    )
                ],
                lastAssessment: Date(),
                nextReviewDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                assessor: "Privacy Officer"
            )
        case "NIST":
            return FrameworkComplianceDetails(
                framework: .nist,
                status: .compliant,
                overallScore: 92.0,
                failingRequirements: [],
                recommendations: [
                    FrameworkComplianceDetails.ComplianceRecommendation(
                        title: "Enhanced Incident Response",
                        description: "Implement advanced incident response automation and playbooks",
                        priority: .medium,
                        estimatedEffort: "Medium",
                        resources: ["Incident Response Team", "Security Tools"],
                        timeline: "6-8 weeks"
                    )
                ],
                lastAssessment: Date(),
                nextReviewDate: Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date(),
                assessor: "Security Team"
            )
        default:
            return FrameworkComplianceDetails(
                framework: .custom,
                status: .pendingReview,
                overallScore: 0.0,
                failingRequirements: [],
                recommendations: [],
                lastAssessment: Date(),
                nextReviewDate: Date(),
                assessor: "TBD"
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: complianceDetails.framework.icon)
                                .foregroundColor(complianceDetails.framework.status.color)
                                .font(.title)
                            
                            VStack(alignment: .leading) {
                                Text(framework)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(complianceDetails.framework.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(Int(complianceDetails.overallScore))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(complianceDetails.framework.status.color)
                                
                                Text("Compliance Score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Status Badge
                        HStack {
                            Text(complianceDetails.framework.status.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(complianceDetails.framework.status.color)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("Last Updated: \(formatDate(complianceDetails.lastAssessment))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Failing Requirements Section
                    if !complianceDetails.failingRequirements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Failing Requirements")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            ForEach(complianceDetails.failingRequirements) { requirement in
                                FailingRequirementCard(requirement: requirement)
                            }
                        }
                    }
                    
                    // Recommendations Section
                    if !complianceDetails.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(complianceDetails.recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }
                        }
                    }
                    
                    // Assessment Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assessment Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Assessor", value: complianceDetails.assessor)
                            InfoRow(label: "Last Assessment", value: formatDate(complianceDetails.lastAssessment))
                            InfoRow(label: "Next Review", value: formatDate(complianceDetails.nextReviewDate))
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Compliance Details")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Failing Requirement Card
struct FailingRequirementCard: View {
    let requirement: FrameworkComplianceDetails.FailingRequirement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(requirement.requirement)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                PriorityBadge(priority: requirement.priority)
            }
            
            // Status Section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Current Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(requirement.currentStatus)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                HStack {
                    Text("Required Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text(requirement.requiredStatus)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Impact and Evidence
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Impact:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(requirement.impact)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("Evidence:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(requirement.evidence)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            // Remediation Steps
            VStack(alignment: .leading, spacing: 8) {
                Text("Remediation Steps:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ForEach(requirement.remediationSteps, id: \.self) { step in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.blue)
                        Text(step)
                            .font(.caption)
                    }
                }
            }
            
            Divider()
            
            // Timeline
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Estimated Time to Fix:")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(requirement.estimatedTimeToFix)
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(requirement.priority.color, lineWidth: 1)
        )
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: FrameworkComplianceDetails.ComplianceRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: recommendation.priority)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Timeline: \(recommendation.timeline)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.green)
                    Text("Effort: \(recommendation.estimatedEffort)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Resources
            VStack(alignment: .leading, spacing: 8) {
                Text("Required Resources:")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                ForEach(recommendation.resources, id: \.self) { resource in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.green)
                        Text(resource)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(recommendation.priority.color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: PolicyRequirement.RequirementPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color)
            .cornerRadius(4)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Framework Extensions
extension ComplianceFramework {
    var icon: String {
        switch self {
        case .iso27001: return "shield.checkered"
        case .gdpr: return "hand.raised.fill"
        case .nist: return "building.2.fill"
        default: return "shield"
        }
    }
    
    var status: ComplianceStatus {
        switch self {
        case .iso27001: return .nonCompliant
        case .gdpr: return .compliant
        case .nist: return .compliant
        default: return .pendingReview
        }
    }
}

#Preview {
    ComplianceDetailsModal(
        framework: "ISO 27001",
        status: .nonCompliant,
        isPresented: .constant(true)
    )
}
