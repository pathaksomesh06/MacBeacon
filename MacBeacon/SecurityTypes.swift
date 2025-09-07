import Foundation
import SwiftUI

// MARK: - Security Event Types
struct SecurityEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let severity: EventSeverity
    let timestamp: Date
    let description: String
    
    enum EventType {
        case process
        case file
        case network
        case system
        
        var icon: String {
            switch self {
            case .process: return "terminal"
            case .file: return "doc.text"
            case .network: return "network"
            case .system: return "gearshape.fill"
            }
        }
    }
    
    enum EventSeverity {
        case low
        case medium
        case high
        case critical
        
        var name: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
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

// MARK: - Network Connection Types
struct NetworkConnection: Identifiable {
    let id = UUID()
    let source: String
    let destination: String
    let port: Int
    let networkProtocol: String
    let timestamp: Date
    let status: Status
    
    enum Status {
        case allowed, blocked, monitoring
        
        var name: String {
            switch self {
            case .allowed: return "Allowed"
            case .blocked: return "Blocked"
            case .monitoring: return "Monitoring"
            }
        }
        
        var color: Color {
            switch self {
            case .allowed: return .green
            case .blocked: return .red
            case .monitoring: return .orange
            }
        }
    }
}

// MARK: - Security Alert Types
struct SecurityAlert: Identifiable {
    let id: UUID
    let title: String
    let severity: AlertSeverity
    let timestamp: Date
    let description: String
    
    enum AlertSeverity {
        case low
        case medium
        case high
        case critical
        
        var name: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
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

// MARK: - Timeline Entry Types
struct TimelineEntry {
    let timestamp: Date
    let events: Int
    let criticalCount: Int
    let errorCount: Int
}

// MARK: - Critical Alert Types
struct CriticalAlert: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let timestamp: Date
    let severity: Severity
    
    enum Severity {
        case critical, high, medium
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            }
        }
    }
}
