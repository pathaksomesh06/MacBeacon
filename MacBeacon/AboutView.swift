import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Mac Beacon")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0 (1)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Microsoft Defender for Endpoint log analysis tool")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("© 2025 Maverick Labs")
                Text("Built for Security Administrators")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}