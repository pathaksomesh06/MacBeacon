import SwiftUI

struct LocalModeBanner: View {
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .medium))
                    
                    // Message
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Running in Local Mode")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("No data is being sent to external services. All security monitoring is performed locally on this device.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isDismissed = true
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Dismiss this message")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 25)
            .padding(.top, 8)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

#Preview {
    VStack {
        LocalModeBanner()
        Spacer()
    }
    .frame(width: 800, height: 200)
}
