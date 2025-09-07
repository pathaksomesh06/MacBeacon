import Foundation
import SwiftUI

struct PSSOStatus {
    let isConnected: Bool
    let deviceConfigured: Bool
    let userConfigured: Bool
    let tokensPresent: Bool
    let lastLoginDate: Date?
    let accountDisplayName: String?
    let userEmail: String?
    let tokenExpiration: Date?
    
    var statusColor: Color {
        return isConnected ? .green : .red
    }
    
    var statusText: String {
        return isConnected ? "🟢 Connected" : "🔴 Disconnected"
    }
    
    var subtitle: String {
        if isConnected {
            return userEmail ?? accountDisplayName ?? "Company Portal Active"
        } else {
            return "Sign in required"
        }
    }
}

class PSSOStatusChecker: ObservableObject {
    @Published var currentStatus: PSSOStatus = PSSOStatus(
        isConnected: false,
        deviceConfigured: false,
        userConfigured: false,
        tokensPresent: false,
        lastLoginDate: nil,
        accountDisplayName: nil,
        userEmail: nil,
        tokenExpiration: nil
    )
    
    @Published var isLoading = false
    @Published var lastChecked: Date = Date()
    
    func checkPSSOStatus() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let status = self.executePSSOCommand()
            
            DispatchQueue.main.async {
                self.currentStatus = status
                self.lastChecked = Date()
                self.isLoading = false
            }
        }
    }
    
    private func executePSSOCommand() -> PSSOStatus {
        let task = Process()
        task.launchPath = "/usr/bin/app-sso"
        task.arguments = ["platform", "-s"]
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let outputString = String(data: outputData, encoding: .utf8) ?? ""
            
            return parsePSSOOutput(outputString)
        } catch {
            print("Error executing app-sso command: \(error)")
            return PSSOStatus(
                isConnected: false,
                deviceConfigured: false,
                userConfigured: false,
                tokensPresent: false,
                lastLoginDate: nil,
                accountDisplayName: nil,
                userEmail: nil,
                tokenExpiration: nil
            )
        }
    }
    
    private func parsePSSOOutput(_ output: String) -> PSSOStatus {
        var deviceConfigured = false
        var userConfigured = false
        var tokensPresent = false
        var accountDisplayName: String?
        var userEmail: String?
        var lastLoginDate: Date?
        var tokenExpiration: Date?
        
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for device configuration
            if trimmedLine.contains("\"registrationCompleted\" : true") {
                deviceConfigured = true
            }
            
            // Check for user configuration
            if trimmedLine.contains("\"state\" : \"POUserStateNormal (0)\"") {
                userConfigured = true
            }
            
            // Extract account display name
            if trimmedLine.contains("\"accountDisplayName\"") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    accountDisplayName = components[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Extract user email
            if trimmedLine.contains("\"loginUserName\"") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    userEmail = components[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "")
                }
            }
            
            // Check for SSO tokens
            if trimmedLine.contains("SSO Tokens:") {
                tokensPresent = true
            }
            
            // Extract last login date
            if trimmedLine.contains("Received:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    let dateString = components[1].trimmingCharacters(in: .whitespaces)
                    lastLoginDate = parseDate(dateString)
                }
            }
            
            // Extract token expiration
            if trimmedLine.contains("Expiration:") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count > 1 {
                    let dateString = components[1].components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? ""
                    tokenExpiration = parseDate(dateString)
                }
            }
        }
        
        // Determine overall connection status
        let isConnected = deviceConfigured && userConfigured && tokensPresent
        
        return PSSOStatus(
            isConnected: isConnected,
            deviceConfigured: deviceConfigured,
            userConfigured: userConfigured,
            tokensPresent: tokensPresent,
            lastLoginDate: lastLoginDate,
            accountDisplayName: accountDisplayName,
            userEmail: userEmail,
            tokenExpiration: tokenExpiration
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try alternative format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: dateString)
    }
}

#Preview {
    VStack {
        Text("PSSO Status Checker")
            .font(.headline)
        
        Text(PSSOStatusChecker().currentStatus.statusText)
            .foregroundColor(PSSOStatusChecker().currentStatus.statusColor)
    }
}
