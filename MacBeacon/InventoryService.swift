import Foundation

class InventoryService: ObservableObject {
    @Published var inventory: DeviceInventory?
    @Published var isRunning = false
    
    func fetchInventory() async {
        await MainActor.run {
            self.isRunning = true
        }
        
        guard let scriptPath = Bundle.main.path(forResource: "app_inventory", ofType: "sh") else {
            print("Error: app_inventory.sh not found in bundle.")
            await MainActor.run { self.isRunning = false }
            return
        }
        
        do {
            let output = try await runScript(at: scriptPath)
            let inventoryData = try JSONDecoder().decode(DeviceInventory.self, from: output)
            
            await MainActor.run {
                self.inventory = inventoryData
                self.isRunning = false
            }
        } catch {
            print("Error fetching or decoding inventory: \(error)")
            await MainActor.run {
                self.isRunning = false
            }
        }
    }
    
    private func runScript(at path: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/bash")
                process.arguments = [path]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
