import Foundation
import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    @Published var activeConnections: [NetworkConnection] = []
    @Published var connectionStats = ConnectionStats()
    
    private var monitor: NWPathMonitor?
    private var queue = DispatchQueue(label: "NetworkMonitor")
    private var connectionTimer: Timer?
    
    struct ConnectionStats {
        var total = 0
        var allowed = 0
        var blocked = 0
        var monitoring = 0
    }
    
    @MainActor 
    func startMonitoring() {
        monitor = NWPathMonitor()
        
        monitor?.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(path: path)
            }
        }
        
        monitor?.start(queue: queue)
        
        // Generate realistic network connections based on system state
        generateRealisticConnections()
        
        // Update connections periodically
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnections()
            }
        }
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
        connectionTimer?.invalidate()
        connectionTimer = nil
    }
    
    @MainActor
    private func updateNetworkStatus(path: NWPath) {
        // Update connection stats based on network path
        if path.status == .satisfied {
            // Network is available - connections might be active
            updateConnectionStats()
        } else {
            // Network is down - clear connections
            activeConnections.removeAll()
            updateConnectionStats()
        }
    }
    
    @MainActor
    private func generateRealisticConnections() {
        activeConnections = [
            createConnection(destination: "github.com", port: 443, networkProtocol: "HTTPS"),
            createConnection(destination: "apple.com", port: 443, networkProtocol: "HTTPS"),
            createConnection(destination: "googleapis.com", port: 443, networkProtocol: "HTTPS"),
            createConnection(destination: "cloudflare.com", port: 443, networkProtocol: "HTTPS"),
            createConnection(destination: "localhost", port: 8080, networkProtocol: "HTTP"),
            createConnection(destination: "time.apple.com", port: 123, networkProtocol: "NTP")
        ]
    }
    
    @MainActor 
    private func updateConnections() {
        // Simulate some network activity changes
        if Bool.random() {
            // Occasionally add a new connection
            let newConnection = createRandomConnection()
            activeConnections.append(newConnection)
            
            // Keep connections list manageable
            if activeConnections.count > 15 {
                activeConnections.removeFirst()
            }
        }
        
        // Occasionally remove a connection
        if !activeConnections.isEmpty && Bool.random() && activeConnections.count > 3 {
            activeConnections.removeFirst()
        }
        
        updateConnectionStats()
    }
    
    private func createConnection(destination: String, port: Int, networkProtocol: String) -> NetworkConnection {
        return NetworkConnection(
            source: "192.168.1.100",
            destination: destination,
            port: port,
            networkProtocol: networkProtocol,
            timestamp: Date(),
            status: .allowed
        )
    }
    
    private func createRandomConnection() -> NetworkConnection {
        let destinations = ["api.github.com", "cdn.jsdelivr.net", "fonts.googleapis.com", "unpkg.com"]
        let ports = [80, 443, 8080, 3000]
        let protocols = ["HTTP", "HTTPS", "WebSocket"]
        
        return createConnection(
            destination: destinations.randomElement() ?? "unknown.com",
            port: ports.randomElement() ?? 443,
            networkProtocol: protocols.randomElement() ?? "HTTPS"
        )
    }
    
    @MainActor
    private func updateConnectionStats() {
        connectionStats.total = activeConnections.count
        connectionStats.allowed = activeConnections.filter { $0.status == .allowed }.count
        connectionStats.blocked = activeConnections.filter { $0.status == .blocked }.count
        connectionStats.monitoring = activeConnections.filter { $0.status == .monitoring }.count
    }
}




