import Foundation

// MARK: - Configuration Manager
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    private let plistName = "MacBeaconConfig"
    private var configData: [String: Any] = [:]
    
    // Published properties for UI updates
    @Published var azureLogAnalyticsEnabled: Bool = false
    @Published var azureWorkspaceId: String = ""
    @Published var azurePrimaryKey: String = ""
    @Published var azureLogTypeName: String = "MacBeaconLogs"
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Loading
    private func loadConfiguration() {
        // Try to load from common Intune deployment locations
        if loadFromIntuneLocations() {
            return
        }
        
        // Fallback: Try to load from the app bundle Resources directory (for development)
        if let bundlePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
           let bundleData = NSDictionary(contentsOfFile: bundlePath) as? [String: Any] {
            configData = bundleData
            updatePublishedProperties()
            print("📋 [ConfigurationManager] Loaded configuration from bundle: \(bundlePath)")
            return
        }
        
        // Try to load from the app bundle's main directory
        if let bundleURL = Bundle.main.url(forResource: plistName, withExtension: "plist"),
           let bundleData = NSDictionary(contentsOf: bundleURL) as? [String: Any] {
            configData = bundleData
            updatePublishedProperties()
            print("📋 [ConfigurationManager] Loaded configuration from bundle main directory: \(bundleURL.path)")
            return
        }
        
        // Then try to load from Application Support (for MDM deployment)
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let configURL = appSupportURL.appendingPathComponent("MacBeacon").appendingPathComponent("\(plistName).plist")
        
        if FileManager.default.fileExists(atPath: configURL.path),
           let fileData = NSDictionary(contentsOfFile: configURL.path) as? [String: Any] {
            configData = fileData
            updatePublishedProperties()
            print("📋 [ConfigurationManager] Loaded configuration from Application Support: \(configURL.path)")
            return
        }
        
        // Finally try to load from /Library/Application Support (system-wide for MDM)
        let systemAppSupportURL = URL(fileURLWithPath: "/Library/Application Support/MacBeacon")
        let systemConfigURL = systemAppSupportURL.appendingPathComponent("\(plistName).plist")
        
        if FileManager.default.fileExists(atPath: systemConfigURL.path),
           let systemData = NSDictionary(contentsOfFile: systemConfigURL.path) as? [String: Any] {
            configData = systemData
            updatePublishedProperties()
            print("📋 [ConfigurationManager] Loaded configuration from system Application Support: \(systemConfigURL.path)")
            return
        }
        
        print("⚠️ [ConfigurationManager] No configuration file found. Using default values.")
        loadDefaultConfiguration()
    }
    
    // MARK: - Intune Deployment Locations
    private func loadFromIntuneLocations() -> Bool {
        // Common locations where Intune might deploy configuration files
        let bundleId = "com.mavericklabs.MacBeacon"
        let intuneLocations = [
            // Standard MacBeaconConfig files
            "/Library/Managed Preferences/MacBeaconConfig.plist",
            "/Library/Preferences/MacBeaconConfig.plist", 
            "/var/db/ConfigurationProfiles/MacBeaconConfig.plist",
            "/Library/Application Support/MacBeacon/MacBeaconConfig.plist",
            "/Users/Shared/MacBeaconConfig.plist",
            "/tmp/MacBeaconConfig.plist",
            // Also check for mobileconfig and XML files
            "/Library/Managed Preferences/MacBeaconConfig.mobileconfig",
            "/Library/Preferences/MacBeaconConfig.mobileconfig",
            "/var/db/ConfigurationProfiles/MacBeaconConfig.mobileconfig",
            "/Library/Application Support/MacBeacon/MacBeaconConfig.mobileconfig",
            "/Users/Shared/MacBeaconConfig.mobileconfig",
            "/tmp/MacBeaconConfig.mobileconfig",
            "/Library/Managed Preferences/MacBeaconConfig.xml",
            "/Library/Preferences/MacBeaconConfig.xml",
            "/var/db/ConfigurationProfiles/MacBeaconConfig.xml",
            "/Library/Application Support/MacBeacon/MacBeaconConfig.xml",
            "/Users/Shared/MacBeaconConfig.xml",
            "/tmp/MacBeaconConfig.xml",
            // Bundle identifier-based files (Intune default behavior)
            "/Library/Managed Preferences/\(bundleId).plist",
            "/Library/Preferences/\(bundleId).plist",
            "/var/db/ConfigurationProfiles/\(bundleId).plist",
            "/Library/Application Support/MacBeacon/\(bundleId).plist",
            "/Users/Shared/\(bundleId).plist",
            "/tmp/\(bundleId).plist",
            "/Library/Managed Preferences/\(bundleId).mobileconfig",
            "/Library/Preferences/\(bundleId).mobileconfig",
            "/var/db/ConfigurationProfiles/\(bundleId).mobileconfig",
            "/Library/Application Support/MacBeacon/\(bundleId).mobileconfig",
            "/Users/Shared/\(bundleId).mobileconfig",
            "/tmp/\(bundleId).mobileconfig",
            "/Library/Managed Preferences/\(bundleId).xml",
            "/Library/Preferences/\(bundleId).xml",
            "/var/db/ConfigurationProfiles/\(bundleId).xml",
            "/Library/Application Support/MacBeacon/\(bundleId).xml",
            "/Users/Shared/\(bundleId).xml",
            "/tmp/\(bundleId).xml"
        ]
        
        for location in intuneLocations {
            if FileManager.default.fileExists(atPath: location) {
                if let configData = loadConfigurationFromFile(at: location) {
                    self.configData = configData
                    updatePublishedProperties()
                    print("✅ [ConfigurationManager] Loaded configuration from Intune location: \(location)")
                    return true
                }
            }
        }
        
        print("ℹ️ [ConfigurationManager] No configuration found in common Intune deployment locations")
        return false
    }
    
    // MARK: - Configuration File Loading
    private func loadConfigurationFromFile(at path: String) -> [String: Any]? {
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        switch fileExtension {
        case "plist":
            return loadPlistFile(at: path)
        case "mobileconfig":
            return loadMobileConfigFile(at: path)
        case "xml":
            return loadXMLFile(at: path)
        default:
            // Try as plist first, then XML
            if let plistData = loadPlistFile(at: path) {
                return plistData
            }
            return loadXMLFile(at: path)
        }
    }
    
    private func loadPlistFile(at path: String) -> [String: Any]? {
        return NSDictionary(contentsOfFile: path) as? [String: Any]
    }
    
    private func loadMobileConfigFile(at path: String) -> [String: Any]? {
        // Mobileconfig files are plist files with PayloadContent structure
        guard let plistData = NSDictionary(contentsOfFile: path) as? [String: Any],
              let payloadContent = plistData["PayloadContent"] as? [[String: Any]],
              let firstPayload = payloadContent.first else {
            return nil
        }
        
        // Handle different payload types
        let payloadType = firstPayload["PayloadType"] as? String
        
        switch payloadType {
        case "com.apple.ManagedClient.preferences":
            return loadManagedClientPreferences(from: firstPayload)
        case "com.apple.applicationaccess":
            return loadApplicationAccess(from: firstPayload)
        default:
            // Fallback to generic extraction
            return loadGenericPayload(from: firstPayload)
        }
    }
    
    private func loadManagedClientPreferences(from payload: [String: Any]) -> [String: Any]? {
        guard let payloadContent = payload["PayloadContent"] as? [String: Any],
              let bundleId = payloadContent.keys.first,
              let bundleConfig = payloadContent[bundleId] as? [String: Any],
              let forced = bundleConfig["Forced"] as? [[String: Any]],
              let firstForced = forced.first,
              let mcxSettings = firstForced["mcx_preference_settings"] as? [String: Any] else {
            return nil
        }
        
        return mcxSettings
    }
    
    private func loadApplicationAccess(from payload: [String: Any]) -> [String: Any]? {
        var configData: [String: Any] = [:]
        
        // Copy all keys except PayloadContent structure
        for (key, value) in payload {
            if key.hasPrefix("Payload") == false && key != "CFBundleIdentifier" {
                configData[key] = value
            }
        }
        
        return configData.isEmpty ? nil : configData
    }
    
    private func loadGenericPayload(from payload: [String: Any]) -> [String: Any]? {
        var configData: [String: Any] = [:]
        
        // Copy all keys except PayloadContent structure
        for (key, value) in payload {
            if key.hasPrefix("Payload") == false && key != "CFBundleIdentifier" {
                configData[key] = value
            }
        }
        
        return configData.isEmpty ? nil : configData
    }
    
    private func loadXMLFile(at path: String) -> [String: Any]? {
        // Simple XML parsing for our custom XML format
        guard let data = FileManager.default.contents(atPath: path),
              let xmlString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Basic XML parsing - extract values between tags
        var configData: [String: Any] = [:]
        
        // Parse bundleIdentifier
        if let bundleId = extractValue(from: xmlString, tag: "bundleIdentifier") {
            configData["bundleIdentifier"] = bundleId
        }
        
        // Parse azureLogAnalytics section
        var azureConfig: [String: Any] = [:]
        if let enabled = extractValue(from: xmlString, tag: "enabled", within: "azureLogAnalytics") {
            azureConfig["enabled"] = enabled.lowercased() == "true"
        }
        if let workspaceId = extractValue(from: xmlString, tag: "workspaceId", within: "azureLogAnalytics") {
            azureConfig["workspaceId"] = workspaceId
        }
        if let primaryKey = extractValue(from: xmlString, tag: "primaryKey", within: "azureLogAnalytics") {
            azureConfig["primaryKey"] = primaryKey
        }
        if let logType = extractValue(from: xmlString, tag: "logType", within: "azureLogAnalytics") {
            azureConfig["logType"] = logType
        }
        
        if !azureConfig.isEmpty {
            configData["azureLogAnalytics"] = azureConfig
        }
        
        // Parse logging section
        var loggingConfig: [String: Any] = [:]
        if let level = extractValue(from: xmlString, tag: "level", within: "logging") {
            loggingConfig["level"] = level
        }
        if let enableConsoleLogging = extractValue(from: xmlString, tag: "enableConsoleLogging", within: "logging") {
            loggingConfig["enableConsoleLogging"] = enableConsoleLogging.lowercased() == "true"
        }
        
        if !loggingConfig.isEmpty {
            configData["logging"] = loggingConfig
        }
        
        // Parse refresh section
        var refreshConfig: [String: Any] = [:]
        if let autoRefresh = extractValue(from: xmlString, tag: "autoRefresh", within: "refresh") {
            refreshConfig["autoRefresh"] = autoRefresh.lowercased() == "true"
        }
        if let interval = extractValue(from: xmlString, tag: "interval", within: "refresh") {
            refreshConfig["interval"] = Double(interval) ?? 30.0
        }
        
        if !refreshConfig.isEmpty {
            configData["refresh"] = refreshConfig
        }
        
        return configData.isEmpty ? nil : configData
    }
    
    private func extractValue(from xmlString: String, tag: String, within parentTag: String? = nil) -> String? {
        let searchString: String
        if let parent = parentTag {
            // Find the parent tag first
            guard let parentStart = xmlString.range(of: "<\(parent)>"),
                  let parentEnd = xmlString.range(of: "</\(parent)>", range: parentStart.upperBound..<xmlString.endIndex) else {
                return nil
            }
            searchString = String(xmlString[parentStart.lowerBound..<parentEnd.upperBound])
        } else {
            searchString = xmlString
        }
        
        // Extract value between tags
        guard let start = searchString.range(of: "<\(tag)>"),
              let end = searchString.range(of: "</\(tag)>", range: start.upperBound..<searchString.endIndex) else {
            return nil
        }
        
        return String(searchString[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Update Published Properties
    private func updatePublishedProperties() {
        azureLogAnalyticsEnabled = getBool(for: "azureLogAnalytics.enabled", defaultValue: false)
        azureWorkspaceId = getString(for: "azureLogAnalytics.workspaceId", defaultValue: "")
        azurePrimaryKey = getString(for: "azureLogAnalytics.primaryKey", defaultValue: "")
        azureLogTypeName = getString(for: "azureLogAnalytics.logTypeName", defaultValue: "")
    }
    
    private func loadDefaultConfiguration() {
        // Default configuration when no plist is found - NO hardcoded Azure LA details
        configData = [
            "azureLogAnalytics": [
                "enabled": false,
                "workspaceId": "",
                "primaryKey": "",
                "logTypeName": ""
            ],
            "logging": [
                "level": "Info",
                "enableConsoleLogging": true
            ],
            "refresh": [
                "autoRefresh": true,
                "interval": 30.0
            ],
            "weeklyReporting": [
                "enabled": false,
                "intervalDays": 7,
                "sendInstallationData": true
            ]
        ]
        
        updatePublishedProperties()
        print("📋 [ConfigurationManager] Loaded default configuration (no Azure LA details)")
    }
    
    // MARK: - Configuration Access
    func getValue<T>(for keyPath: String, as type: T.Type, defaultValue: T) -> T {
        let keys = keyPath.components(separatedBy: ".")
        var current: Any = configData
        
        for key in keys {
            if let dictionary = current as? [String: Any],
               let value = dictionary[key] {
                current = value
            } else {
                print("⚠️ [ConfigurationManager] Key path '\(keyPath)' not found, using default value: \(defaultValue)")
                return defaultValue
            }
        }
        
        if let typedValue = current as? T {
            return typedValue
        } else {
            print("⚠️ [ConfigurationManager] Value for '\(keyPath)' is not of type \(T.self), using default: \(defaultValue)")
            return defaultValue
        }
    }
    
    func getString(for keyPath: String, defaultValue: String = "") -> String {
        return getValue(for: keyPath, as: String.self, defaultValue: defaultValue)
    }
    
    func getBool(for keyPath: String, defaultValue: Bool = false) -> Bool {
        return getValue(for: keyPath, as: Bool.self, defaultValue: defaultValue)
    }
    
    func getDouble(for keyPath: String, defaultValue: Double = 0.0) -> Double {
        return getValue(for: keyPath, as: Double.self, defaultValue: defaultValue)
    }
    
    func getInt(for keyPath: String, defaultValue: Int = 0) -> Int {
        return getValue(for: keyPath, as: Int.self, defaultValue: defaultValue)
    }
    
    // MARK: - Azure Log Analytics Configuration
    // These are now @Published properties defined at the top of the class
    
    // MARK: - Weekly Reporting Configuration
    var weeklyReportingEnabled: Bool {
        return getBool(for: "azureLogAnalytics.weeklyReporting.enabled", defaultValue: false)
    }
    
    var weeklyReportingIntervalDays: Int {
        return getInt(for: "azureLogAnalytics.weeklyReporting.intervalDays", defaultValue: 7)
    }
    
    var sendInstallationData: Bool {
        return getBool(for: "azureLogAnalytics.weeklyReporting.sendInstallationData", defaultValue: true)
    }
    
    // MARK: - Logging Configuration
    var logLevel: String {
        return getString(for: "logging.level", defaultValue: "Info")
    }
    
    var enableConsoleLogging: Bool {
        return getBool(for: "logging.enableConsoleLogging", defaultValue: true)
    }
    
    // MARK: - Refresh Configuration
    var autoRefresh: Bool {
        return getBool(for: "refresh.autoRefresh", defaultValue: true)
    }
    
    var refreshInterval: Double {
        return getDouble(for: "refresh.interval", defaultValue: 30.0)
    }
    
    // MARK: - Configuration Validation
    func validateAzureConfiguration() -> Bool {
        if azureLogAnalyticsEnabled {
            if azureWorkspaceId.isEmpty {
                print("❌ [ConfigurationManager] Azure Log Analytics enabled but workspace ID is empty")
                return false
            }
            if azurePrimaryKey.isEmpty {
                print("❌ [ConfigurationManager] Azure Log Analytics enabled but primary key is empty")
                return false
            }
            print("✅ [ConfigurationManager] Azure Log Analytics configuration is valid")
            return true
        } else {
            print("ℹ️ [ConfigurationManager] Azure Log Analytics is disabled")
            return true
        }
    }
    
    // MARK: - Debug Information
    func printConfiguration() {
        print("📋 [ConfigurationManager] Current configuration:")
        print("   Azure Log Analytics:")
        print("     Enabled: \(azureLogAnalyticsEnabled)")
        print("     Workspace ID: \(azureWorkspaceId.isEmpty ? "Not set" : "\(azureWorkspaceId.prefix(8))...")")
        print("     Primary Key: \(azurePrimaryKey.isEmpty ? "Not set" : "\(azurePrimaryKey.prefix(8))...")")
        print("     Log Type: \(azureLogTypeName)")
        print("   Weekly Reporting:")
        print("     Enabled: \(weeklyReportingEnabled)")
        print("     Interval: \(weeklyReportingIntervalDays) days")
        print("     Send Installation Data: \(sendInstallationData)")
        print("   Logging:")
        print("     Level: \(logLevel)")
        print("     Console Logging: \(enableConsoleLogging)")
        print("   Refresh:")
        print("     Auto Refresh: \(autoRefresh)")
        print("     Interval: \(refreshInterval) seconds")
        
        // Show configuration source
        print("   Configuration Source: Local file or default values")
    }
}
