import Foundation
import CryptoKit

// MARK: - Azure Log Analytics Configuration
struct AzureLogAnalyticsConfig {
    // Configuration is now loaded from plist via ConfigurationManager
    static var workspaceId: String {
        return ConfigurationManager.shared.azureWorkspaceId
    }
    
    static var primaryKey: String {
        return ConfigurationManager.shared.azurePrimaryKey
    }
    
    static var logTypeName: String {
        return ConfigurationManager.shared.azureLogTypeName
    }
    
    static var isEnabled: Bool {
        return ConfigurationManager.shared.azureLogAnalyticsEnabled
    }
}

class AzureLogAnalytics {
    private let workspaceId: String
    private let primaryKey: String
    private let logTypeName: String
    
    private let session: URLSession
    
    init(workspaceId: String, primaryKey: String, logTypeName: String) {
        self.workspaceId = workspaceId
        self.primaryKey = primaryKey
        self.logTypeName = logTypeName
        self.session = URLSession.shared
    }
    
    // Convenience initializer using configuration
    convenience init() {
        self.init(
            workspaceId: AzureLogAnalyticsConfig.workspaceId,
            primaryKey: AzureLogAnalyticsConfig.primaryKey,
            logTypeName: AzureLogAnalyticsConfig.logTypeName
        )
    }
    
    /// Sends a dictionary of data to Azure Log Analytics.
    /// - Parameter logData: A dictionary representing the data to be sent.
    func send(logData: [String: Any]) {
        // Check if Azure Log Analytics is enabled
        guard AzureLogAnalyticsConfig.isEnabled else {
            print("📊 [AzureLogAnalytics] Azure Log Analytics is disabled in configuration")
            return
        }
        
        // Validate configuration
        guard !workspaceId.isEmpty && !primaryKey.isEmpty else {
            print("❌ [AzureLogAnalytics] Invalid configuration: workspaceId or primaryKey is empty")
            return
        }
        print("🔵 [AzureLogAnalytics] Starting to send data to workspace: \(workspaceId)")
        print("🔵 [AzureLogAnalytics] Log type: \(logTypeName)")
        print("🔵 [AzureLogAnalytics] Data to send: \(logData)")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: logData, options: [])
            print("🔵 [AzureLogAnalytics] JSON data length: \(jsonData.count) bytes")
            
            let dateString = rfc1123Date()
            let signature = try createSignature(dateString: dateString, contentLength: jsonData.count)
            
            let url = URL(string: "https://\(workspaceId).ods.opinsights.azure.com/api/logs?api-version=2016-04-01")!
            print("🔵 [AzureLogAnalytics] Sending to URL: \(url)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(logTypeName, forHTTPHeaderField: "Log-Type")
            request.setValue(dateString, forHTTPHeaderField: "x-ms-date")
            request.setValue("SharedKey \(workspaceId):\(signature)", forHTTPHeaderField: "Authorization")
            request.httpBody = jsonData
            
            print("🔵 [AzureLogAnalytics] Request headers:")
            print("   Content-Type: application/json")
            print("   Log-Type: \(logTypeName)")
            print("   x-ms-date: \(dateString)")
            print("   Authorization: SharedKey \(workspaceId):[SIGNATURE]")
            
            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ [AzureLogAnalytics] Error sending logs: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔵 [AzureLogAnalytics] Response status code: \(httpResponse.statusCode)")
                    if !(200...299).contains(httpResponse.statusCode) {
                        print("❌ [AzureLogAnalytics] Error: Received status code \(httpResponse.statusCode)")
                        if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                            print("❌ [AzureLogAnalytics] Response body: \(responseBody)")
                        }
                    } else {
                        print("✅ [AzureLogAnalytics] Logs sent successfully to Azure Log Analytics!")
                    }
                }
            }
            task.resume()
            
        } catch {
            print("❌ [AzureLogAnalytics] Error preparing log data: \(error)")
        }
    }
    
    /// Creates the HMAC-SHA256 signature for the Authorization header.
    private func createSignature(dateString: String, contentLength: Int) throws -> String {
        let stringToSign = "POST\n\(contentLength)\napplication/json\nx-ms-date:\(dateString)\n/api/logs"
        
        guard let keyData = Data(base64Encoded: primaryKey) else {
            throw NSError(domain: "AzureLogAnalytics", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid primary key"])
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: key)
        
        return Data(signature).base64EncodedString()
    }
    
    /// Returns the current date in RFC 1123 format.
    private func rfc1123Date() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date())
    }
}

// MARK: - Data Models

struct DeviceStatus {
    let deviceName: String
    let osVersion: String
    let timestamp: String
    
    // MDE Health
    let mdeHealth: MDEHealthStatus
    
    // Compliance Status
    let cisBenchmarkResult: String
    let gdprComplianceResult: String
    let nistBenchmarkResult: String
    
    // Inventory Data
    let inventory: DeviceInventory?
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "DeviceName": deviceName,
            "OSVersion": osVersion,
            "Timestamp": timestamp,
            "MDEHealthy": mdeHealth.isHealthy,
            "MDERealTimeProtection": mdeHealth.realTimeProtection,
            "MDEHealthScore": mdeHealth.healthScore,
            "CISBenchmarkResult": cisBenchmarkResult,
            "GDPRComplianceResult": gdprComplianceResult,
            "NISTBenchmarkResult": nistBenchmarkResult,
        ]
        
        // Add inventory data if it exists
        if let inventory = inventory {
            dict["InventoryComputerName"] = inventory.computerName
            dict["InventoryDeviceSerialNumber"] = inventory.deviceSerialNumber
            dict["InventoryManagedDeviceID"] = inventory.managedDeviceID
            // For Log Analytics, it's better to serialize the app list to a string
            // to avoid complex nested object issues.
            if let appsData = try? JSONEncoder().encode(inventory.applications),
               let appsString = String(data: appsData, encoding: .utf8) {
                dict["Applications"] = appsString
            }
        }
        
        return dict
    }
}

struct MDEHealthStatus {
    let isHealthy: Bool
    let realTimeProtection: Bool
    let healthScore: Int
}
