import Foundation
import SwiftUI
import PDFKit
import AppKit
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case json = "JSON"
    case html = "HTML"

    var contentType: UTType {
        switch self {
        case .pdf: return .pdf
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .html: return .html
        }
    }
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .csv: return "csv"
        case .json: return "json"
        case .html: return "html"
        }
    }
}

// MARK: - Compliance Models
struct CompliancePolicy: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: PolicyCategory
    let requirements: [PolicyRequirement]
    let framework: ComplianceFramework
    let lastUpdated: Date
    let status: ComplianceStatus
    
    enum PolicyCategory: String, CaseIterable, Codable {
        case accessControl = "Access Control"
        case dataProtection = "Data Protection"
        case networkSecurity = "Network Security"
        case endpointSecurity = "Endpoint Security"
        case auditLogging = "Audit Logging"
        case incidentResponse = "Incident Response"
    }
}

struct PolicyRequirement: Identifiable, Codable {
    let id = UUID()
    let description: String
    let type: RequirementType
    let status: ComplianceStatus
    let lastChecked: Date
    let notes: String?
    let failingReason: String?
    let remediationSteps: [String]
    let priority: RequirementPriority
    
    enum RequirementType: String, CaseIterable, Codable {
        case mandatory = "Mandatory"
        case recommended = "Recommended"
        case optional = "Optional"
    }
    
    enum RequirementPriority: String, CaseIterable, Codable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .blue
            }
        }
    }
}

enum ComplianceStatus: String, CaseIterable, Codable {
    case compliant = "Compliant"
    case nonCompliant = "Non-Compliant"
    case partiallyCompliant = "Partially Compliant"
    case notApplicable = "Not Applicable"
    case pendingReview = "Pending Review"
    
    var color: Color {
        switch self {
        case .compliant: return .green
        case .nonCompliant: return .red
        case .partiallyCompliant: return .orange
        case .notApplicable: return .gray
        case .pendingReview: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .compliant: return "checkmark.circle.fill"
        case .nonCompliant: return "xmark.circle.fill"
        case .partiallyCompliant: return "exclamationmark.triangle.fill"
        case .notApplicable: return "minus.circle.fill"
        case .pendingReview: return "clock.fill"
        }
    }
}

enum ComplianceFramework: String, CaseIterable, Codable {
    case iso27001 = "ISO 27001"
    case soc2 = "SOC 2"
    case pciDss = "PCI DSS"
    case hipaa = "HIPAA"
    case gdpr = "GDPR"
    case nist = "NIST"
    case custom = "Custom Enterprise"
    
    var description: String {
        switch self {
        case .iso27001: return "Information Security Management System standard"
        case .soc2: return "Service Organization Control 2 for security, availability, processing integrity, confidentiality, and privacy"
        case .pciDss: return "Payment Card Industry Data Security Standard"
        case .hipaa: return "Health Insurance Portability and Accountability Act"
        case .gdpr: return "General Data Protection Regulation"
        case .nist: return "National Institute of Standards and Technology Cybersecurity Framework"
        case .custom: return "Custom enterprise security framework"
        }
    }
    
    var keyRequirements: [String] {
        switch self {
        case .iso27001:
            return [
                "Information Security Policy",
                "Asset Management",
                "Access Control",
                "Cryptography",
                "Physical Security",
                "Operations Security",
                "Communications Security",
                "System Acquisition",
                "Supplier Relationships",
                "Incident Management",
                "Business Continuity",
                "Compliance"
            ]
        case .gdpr:
            return [
                "Data Protection by Design",
                "Data Minimization",
                "Consent Management",
                "Data Subject Rights",
                "Data Breach Notification",
                "Data Processing Records",
                "Data Protection Impact Assessment",
                "Cross-border Data Transfer"
            ]
        case .nist:
            return [
                "Identify",
                "Protect",
                "Detect",
                "Respond",
                "Recover"
            ]
        default:
            return ["Standard requirements apply"]
        }
    }
}

// MARK: - Framework Compliance Details
struct FrameworkComplianceDetails: Identifiable, Codable {
    let id = UUID()
    let framework: ComplianceFramework
    let status: ComplianceStatus
    let overallScore: Double
    let failingRequirements: [FailingRequirement]
    let recommendations: [ComplianceRecommendation]
    let lastAssessment: Date
    let nextReviewDate: Date
    let assessor: String
    
    struct FailingRequirement: Identifiable, Codable {
        let id = UUID()
        let requirement: String
        let currentStatus: String
        let requiredStatus: String
        let impact: String
        let evidence: String
        let remediationSteps: [String]
        let estimatedTimeToFix: String
        let priority: PolicyRequirement.RequirementPriority
    }
    
    struct ComplianceRecommendation: Identifiable, Codable {
        let id = UUID()
        let title: String
        let description: String
        let priority: PolicyRequirement.RequirementPriority
        let estimatedEffort: String
        let resources: [String]
        let timeline: String
    }
}

// MARK: - Export Models
struct ComplianceReport: Codable {
    let generatedAt: Date
    let organization: String
    let reportPeriod: String
    let summary: ComplianceSummary
    let policies: [CompliancePolicy]
    let recommendations: [String]
    let riskAssessment: RiskAssessment
}

struct ComplianceSummary: Codable {
    let totalPolicies: Int
    let compliantPolicies: Int
    let nonCompliantPolicies: Int
    let overallScore: Double
    let criticalIssues: Int
    let highRiskIssues: Int
    let mediumRiskIssues: Int
    let lowRiskIssues: Int
}

struct RiskAssessment: Codable {
    let overallRiskLevel: RiskLevel
    let riskFactors: [RiskFactor]
    let mitigationStrategies: [String]
    
    enum RiskLevel: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

struct RiskFactor: Codable {
    let description: String
    let impact: RiskAssessment.RiskLevel
    let probability: RiskAssessment.RiskLevel
    let mitigation: String
}

// MARK: - Mock Service
class MockComplianceService: ObservableObject {
    @Published var policies: [CompliancePolicy] = []
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        policies = [
            CompliancePolicy(
                name: "Endpoint Security Policy",
                category: .endpointSecurity,
                requirements: [
                    PolicyRequirement(
                        description: "All endpoints must have real-time monitoring enabled",
                        type: .mandatory,
                        status: .compliant,
                        lastChecked: Date(),
                        notes: "Successfully implemented with EndpointSecurity framework",
                        failingReason: nil,
                        remediationSteps: [],
                        priority: .high
                    ),
                    PolicyRequirement(
                        description: "File access logging must be comprehensive",
                        type: .mandatory,
                        status: .compliant,
                        lastChecked: Date(),
                        notes: "FileMonitorPanel actively logging all file events",
                        failingReason: nil,
                        remediationSteps: [],
                        priority: .high
                    ),
                    PolicyRequirement(
                        description: "Process monitoring must detect suspicious activity",
                        type: .mandatory,
                        status: .partiallyCompliant,
                        lastChecked: Date(),
                        notes: "Basic monitoring implemented, AI threat detection pending",
                        failingReason: "AI threat detection system not yet implemented",
                        remediationSteps: [
                            "Implement machine learning-based threat detection",
                            "Configure behavioral analysis rules",
                            "Set up automated response mechanisms"
                        ],
                        priority: .medium
                    )
                ],
                framework: .iso27001,
                lastUpdated: Date(),
                status: .partiallyCompliant
            ),
            CompliancePolicy(
                name: "Network Security Policy",
                category: .networkSecurity,
                requirements: [
                    PolicyRequirement(
                        description: "All network connections must be monitored",
                        type: .mandatory,
                        status: .compliant,
                        lastChecked: Date(),
                        notes: "NetworkMonitor actively tracking all connections",
                        failingReason: nil,
                        remediationSteps: [],
                        priority: .critical
                    ),
                    PolicyRequirement(
                        description: "Suspicious network activity must trigger alerts",
                        type: .mandatory,
                        status: .compliant,
                        lastChecked: Date(),
                        notes: "Real-time alerting implemented",
                        failingReason: nil,
                        remediationSteps: [],
                        priority: .critical
                    )
                ],
                framework: .nist,
                lastUpdated: Date(),
                status: .compliant
            ),
            CompliancePolicy(
                name: "Data Protection Policy",
                category: .dataProtection,
                requirements: [
                    PolicyRequirement(
                        description: "Sensitive data access must be logged",
                        type: .mandatory,
                        status: .nonCompliant,
                        lastChecked: Date(),
                        notes: "Data classification system not yet implemented",
                        failingReason: "Data classification and access logging system missing",
                        remediationSteps: [
                            "Implement data classification system",
                            "Configure access logging for sensitive data",
                            "Set up data loss prevention (DLP) tools",
                            "Train staff on data handling procedures"
                        ],
                        priority: .critical
                    ),
                    PolicyRequirement(
                        description: "Encryption at rest must be enabled",
                        type: .mandatory,
                        status: .pendingReview,
                        lastChecked: Date(),
                        notes: "Under review by security team",
                        failingReason: "Encryption implementation pending security review",
                        remediationSteps: [
                            "Complete security review of encryption approach",
                            "Implement disk encryption for all endpoints",
                            "Configure database encryption",
                            "Test encryption performance impact"
                        ],
                        priority: .high
                    )
                ],
                framework: .gdpr,
                lastUpdated: Date(),
                status: .nonCompliant
            )
        ]
    }
}

// MARK: - Policy Compliance Engine
class PolicyComplianceEngine: ObservableObject {
    @Published var policies: [CompliancePolicy] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date = Date()
    
    private let mockService = MockComplianceService()
    
    init() {
        loadComplianceData()
    }
    
    func loadComplianceData() {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.policies = self.mockService.policies
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    func refreshComplianceData() {
        loadComplianceData()
    }
    
    // MARK: - Dashboard Properties
    var overallComplianceScore: Int {
        guard !policies.isEmpty else { return 0 }
        
        let totalRequirements = policies.reduce(0) { sum, policy in
            sum + policy.requirements.count
        }
        let compliantRequirements = policies.reduce(0) { sum, policy in
            sum + policy.requirements.filter { $0.status == .compliant }.count
        }
        
        if totalRequirements == 0 { return 100 }
        
        // Calculate percentage and round to nearest whole number
        let percentage = Double(compliantRequirements) / Double(totalRequirements) * 100
        return Int(round(percentage))
    }
    
    var complianceStatus: String {
        let score = overallComplianceScore
        if score >= 90 { return "🟢 Excellent" }
        else if score >= 75 { return "🟡 Good" }
        else if score >= 60 { return "🟠 Fair" }
        else { return "🔴 Poor" }
    }
    
    var complianceSubtitle: String {
        let score = overallComplianceScore
        if score >= 90 { return "All policies compliant" }
        else if score >= 75 { return "Most policies compliant" }
        else if score >= 60 { return "Some policies need attention" }
        else { return "Multiple policies need attention" }
    }
    
    var frameworks: [ComplianceFramework] {
        // Extract unique frameworks from policies
        Array(Set(policies.map { $0.framework }))
    }
    
    // MARK: - Reporting & Exporting
    
    func exportComplianceReport(to url: URL, format: ExportFormat) -> Bool {
        let reportData = generateComplianceReportData(format: format)
        
        do {
            try reportData.write(to: url, options: .atomic)
            return true
        } catch {
            print("Error exporting compliance report: \(error.localizedDescription)")
            return false
        }
    }
    
    func exportSecurityPostureSummary(to url: URL, format: ExportFormat) -> Bool {
        let summaryData = generateSecurityPostureSummaryData(format: format)
        
        do {
            try summaryData.write(to: url, options: .atomic)
            return true
        } catch {
            print("Error exporting security posture summary: \(error.localizedDescription)")
            return false
        }
    }
    
    private func generateComplianceReportData(format: ExportFormat) -> Data {
        let report = generateComplianceReport()
        switch format {
        case .pdf:
            return generatePdfData(from: report)
        case .csv:
            return generateCSVString(report).data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return (try? encoder.encode(report)) ?? Data()
        case .html:
            return generateHTMLString(report).data(using: .utf8) ?? Data()
        }
    }

    private func generateSecurityPostureSummaryData(format: ExportFormat) -> Data {
        let report = generateSecurityPostureSummary()
        switch format {
        case .pdf:
            return generatePdfData(from: report)
        case .csv:
            return generateCSVString(report).data(using: .utf8) ?? Data()
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            return (try? encoder.encode(report)) ?? Data()
        case .html:
            return generateHTMLString(report).data(using: .utf8) ?? Data()
        }
    }
    
    private func generatePdfData(from report: ComplianceReport) -> Data {
        let attributedString = generateAttributedString(for: report)
        
        // UI operations must be performed on the main thread.
        // Using `sync` to ensure data is returned before the function exits.
        return DispatchQueue.main.sync {
            let printInfo = NSPrintInfo()
            let pageBounds = printInfo.imageablePageBounds
            
            let textView = NSTextView(frame: pageBounds)
            textView.textStorage?.setAttributedString(attributedString)
            
            return textView.dataWithPDF(inside: textView.bounds)
        }
    }
    
    private func generateComplianceReport() -> ComplianceReport {
        let summary = ComplianceSummary(
            totalPolicies: policies.count,
            compliantPolicies: policies.filter { $0.status == .compliant }.count,
            nonCompliantPolicies: policies.filter { $0.status == .nonCompliant }.count,
            overallScore: calculateOverallScore(),
            criticalIssues: countIssuesByRisk(.critical),
            highRiskIssues: countIssuesByRisk(.high),
            mediumRiskIssues: countIssuesByRisk(.medium),
            lowRiskIssues: countIssuesByRisk(.low)
        )
        
        let recommendations = generateRecommendations()
        let riskAssessment = generateRiskAssessment()
        
        return ComplianceReport(
            generatedAt: Date(),
            organization: "Enterprise Corp",
            reportPeriod: "Q4 2024",
            summary: summary,
            policies: policies,
            recommendations: recommendations,
            riskAssessment: riskAssessment
        )
    }
    
    private func generateSecurityPostureSummary() -> ComplianceReport {
        // Simplified version for security posture
        let summary = ComplianceSummary(
            totalPolicies: policies.count,
            compliantPolicies: policies.filter { $0.status == .compliant }.count,
            nonCompliantPolicies: policies.filter { $0.status == .nonCompliant }.count,
            overallScore: calculateOverallScore(),
            criticalIssues: countIssuesByRisk(.critical),
            highRiskIssues: countIssuesByRisk(.high),
            mediumRiskIssues: countIssuesByRisk(.medium),
            lowRiskIssues: countIssuesByRisk(.low)
        )
        
        return ComplianceReport(
            generatedAt: Date(),
            organization: "Enterprise Corp",
            reportPeriod: "Current Status",
            summary: summary,
            policies: policies,
            recommendations: ["Focus on data protection implementation", "Enhance process monitoring capabilities"],
            riskAssessment: generateRiskAssessment()
        )
    }
    
    private func calculateOverallScore() -> Double {
        let totalRequirements = policies.flatMap { $0.requirements }.count
        let compliantRequirements = policies.flatMap { $0.requirements }.filter { $0.status == .compliant }.count
        
        guard totalRequirements > 0 else { return 0.0 }
        return Double(compliantRequirements) / Double(totalRequirements) * 100.0
    }
    
    private func countIssuesByRisk(_ riskLevel: RiskAssessment.RiskLevel) -> Int {
        // Simplified risk counting based on compliance status
        switch riskLevel {
        case .critical:
            return policies.filter { $0.status == .nonCompliant }.count
        case .high:
            return policies.filter { $0.status == .partiallyCompliant }.count
        case .medium:
            return policies.filter { $0.status == .pendingReview }.count
        case .low:
            return policies.filter { $0.status == .notApplicable }.count
        }
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if policies.contains(where: { $0.status == .nonCompliant }) {
            recommendations.append("Address non-compliant policies immediately")
        }
        
        if policies.contains(where: { $0.status == .partiallyCompliant }) {
            recommendations.append("Complete partially compliant implementations")
        }
        
        if policies.contains(where: { $0.status == .pendingReview }) {
            recommendations.append("Complete pending policy reviews")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Maintain current compliance status")
        }
        
        return recommendations
    }
    
    private func generateRiskAssessment() -> RiskAssessment {
        let overallRiskLevel: RiskAssessment.RiskLevel
        
        if policies.contains(where: { $0.status == .nonCompliant }) {
            overallRiskLevel = .high
        } else if policies.contains(where: { $0.status == .partiallyCompliant }) {
            overallRiskLevel = .medium
        } else {
            overallRiskLevel = .low
        }
        
        let riskFactors = [
            RiskFactor(
                description: "Data protection policy non-compliance",
                impact: .high,
                probability: .medium,
                mitigation: "Implement data classification and access logging"
            ),
            RiskFactor(
                description: "Process monitoring limitations",
                impact: .medium,
                probability: .low,
                mitigation: "Enhance AI-powered threat detection"
            )
        ]
        
        let mitigationStrategies = [
            "Implement comprehensive data protection measures",
            "Enhance endpoint security monitoring",
            "Establish regular compliance reviews",
            "Provide security awareness training"
        ]
        
        return RiskAssessment(
            overallRiskLevel: overallRiskLevel,
            riskFactors: riskFactors,
            mitigationStrategies: mitigationStrategies
        )
    }

    private func generateCSVString(_ report: ComplianceReport) -> String {
        var csv = "Policy Name,Category,Status,Framework,Last Updated\n"
        
        for policy in report.policies {
            let row = "\(policy.name),\(policy.category.rawValue),\(policy.status.rawValue),\(policy.framework.rawValue),\(formatDate(policy.lastUpdated))\n"
            csv += row
        }
        
        return csv
    }
    
    private func generateHTMLString(_ report: ComplianceReport) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Compliance Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
                .summary { margin: 20px 0; }
                .policy { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
                .status-compliant { color: green; }
                .status-noncompliant { color: red; }
                .status-partial { color: orange; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Compliance Report</h1>
                <p><strong>Generated:</strong> \(formatDate(report.generatedAt))</p>
                <p><strong>Organization:</strong> \(report.organization)</p>
                <p><strong>Period:</strong> \(report.reportPeriod)</p>
            </div>
            
            <div class="summary">
                <h2>Summary</h2>
                <p>Overall Score: \(String(format: "%.1f", report.summary.overallScore))%</p>
                <p>Total Policies: \(report.summary.totalPolicies)</p>
                <p>Compliant: \(report.summary.compliantPolicies)</p>
                <p>Non-Compliant: \(report.summary.nonCompliantPolicies)</p>
            </div>
            
            <h2>Policies</h2>
        """
        
        for policy in report.policies {
            let statusClass = policy.status == .compliant ? "status-compliant" :
                             policy.status == .nonCompliant ? "status-noncompliant" : "status-partial"
            
            html += """
                <div class="policy">
                    <h3>\(policy.name)</h3>
                    <p><strong>Category:</strong> \(policy.category.rawValue)</p>
                    <p><strong>Status:</strong> <span class="\(statusClass)">\(policy.status.rawValue)</span></p>
                    <p><strong>Framework:</strong> \(policy.framework.rawValue)</p>
                    <p><strong>Last Updated:</strong> \(formatDate(policy.lastUpdated))</p>
                </div>
            """
        }
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func generateAttributedString(for report: ComplianceReport) -> NSAttributedString {
        let mutableString = NSMutableAttributedString()
        
        // Title
        let titleFont = NSFont.boldSystemFont(ofSize: 18)
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        let title = NSAttributedString(string: "Compliance Report\n\n", attributes: titleAttributes)
        mutableString.append(title)
        
        // Header information
        let headerFont = NSFont.systemFont(ofSize: 12)
        let headerAttributes = [NSAttributedString.Key.font: headerFont]
        let headerText = """
        Generated: \(formatDate(report.generatedAt))
        Organization: \(report.organization)
        Report Period: \(report.reportPeriod)
        
        
        """
        let header = NSAttributedString(string: headerText, attributes: headerAttributes)
        mutableString.append(header)
        
        // Summary section
        let summaryFont = NSFont.boldSystemFont(ofSize: 14)
        let summaryAttributes = [NSAttributedString.Key.font: summaryFont]
        let summaryTitle = NSAttributedString(string: "Summary\n", attributes: summaryAttributes)
        mutableString.append(summaryTitle)
        
        let summaryText = """
        Overall Score: \(String(format: "%.1f", report.summary.overallScore))%
        Total Policies: \(report.summary.totalPolicies)
        Compliant Policies: \(report.summary.compliantPolicies)
        Non-Compliant Policies: \(report.summary.nonCompliantPolicies)
        Critical Issues: \(report.summary.criticalIssues)
        High Risk Issues: \(report.summary.highRiskIssues)
        
        
        """
        let summary = NSAttributedString(string: summaryText, attributes: headerAttributes)
        mutableString.append(summary)
        
        // Policies section
        let policiesTitle = NSAttributedString(string: "Policy Details\n\n", attributes: summaryAttributes)
        mutableString.append(policiesTitle)
        
        for policy in report.policies {
            let policyTitle = NSAttributedString(string: "\(policy.name)\n", attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 12)])
            mutableString.append(policyTitle)
            
            let policyDetails = """
            Category: \(policy.category.rawValue)
            Status: \(policy.status.rawValue)
            Framework: \(policy.framework.rawValue)
            Last Updated: \(formatDate(policy.lastUpdated))
            
            Requirements:
            """
            let details = NSAttributedString(string: policyDetails, attributes: headerAttributes)
            mutableString.append(details)
            
            for requirement in policy.requirements {
                let reqText = "• \(requirement.description) - \(requirement.status.rawValue)\n"
                let req = NSAttributedString(string: reqText, attributes: headerAttributes)
                mutableString.append(req)
            }
            
            mutableString.append(NSAttributedString(string: "\n", attributes: headerAttributes))
        }
        
        // Recommendations section
        if !report.recommendations.isEmpty {
            let recommendationsTitle = NSAttributedString(string: "Recommendations\n\n", attributes: summaryAttributes)
            mutableString.append(recommendationsTitle)
            
            for recommendation in report.recommendations {
                let recText = "• \(recommendation)\n"
                let rec = NSAttributedString(string: recText, attributes: headerAttributes)
                mutableString.append(rec)
            }
        }
        
        return mutableString
    }
}
