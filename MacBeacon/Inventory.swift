import Foundation

struct DeviceInventory: Codable {
    let computerName: String
    let deviceSerialNumber: String
    let managedDeviceID: String
    let applications: [ApplicationInfo]

    enum CodingKeys: String, CodingKey {
        case computerName = "ComputerName"
        case deviceSerialNumber = "DeviceSerialNumber"
        case managedDeviceID = "ManagedDeviceID"
        case applications = "Applications"
    }
}

struct ApplicationInfo: Codable, Hashable {
    let appName: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case appName = "AppName"
        case appVersion = "AppVersion"
    }
}
