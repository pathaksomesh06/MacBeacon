import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcome: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                // Title
                VStack(spacing: 10) {
                    Text("MDELogReader")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Microsoft Defender for Endpoint Log Analysis")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Features
                VStack(spacing: 20) {
                    FeatureRow(icon: "bolt.fill", text: "Real-time threat monitoring")
                    FeatureRow(icon: "magnifyingglass", text: "Advanced search & filtering")
                    FeatureRow(icon: "exclamationmark.shield.fill", text: "Security event analysis")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Get Started button
                Button(action: {
                    #if !DEBUG
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    #endif
                    showWelcome = false
                }) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(radius: 10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(text)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}