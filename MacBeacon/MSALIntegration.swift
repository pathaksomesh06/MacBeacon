import SwiftUI
import Foundation

// MARK: - MSAL Integration for Enterprise SSO
// This module provides Microsoft Authentication Library integration for enterprise single sign-on

// MARK: - MSAL Configuration
struct MSALConfiguration {
    let clientId: String
    let authority: String
    let redirectUri: String
    let scopes: [String]
    
    // Default configuration for enterprise environments
    static let enterprise = MSALConfiguration(
        clientId: "YOUR_ENTERPRISE_CLIENT_ID", // TODO: Replace with actual client ID
        authority: "https://login.microsoftonline.com/common",
        redirectUri: "msauth.com.mavericklabs.MacBeacon://auth",
        scopes: [
            "User.Read",
            "User.ReadBasic.All",
            "Directory.Read.All",
            "Device.Read.All",
            "SecurityEvents.Read.All"
        ]
    )
}

// MARK: - MSAL Authentication Manager
class MSALAuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: MSALUser?
    @Published var authenticationState: AuthenticationState = .notAuthenticated
    @Published var errorMessage: String?
    
    private var configuration: MSALConfiguration
    
    init(configuration: MSALConfiguration = .enterprise) {
        self.configuration = configuration
        loadStoredCredentials()
    }
    
    // MARK: - Authentication States
    enum AuthenticationState {
        case notAuthenticated
        case authenticating
        case authenticated
        case failed(String)
    }
    
    // MARK: - MSAL User Model
    struct MSALUser: Codable, Identifiable {
        let id: String
        let displayName: String
        let email: String
        let tenantId: String
        let jobTitle: String?
        let department: String?
        let manager: String?
        let lastSignIn: Date
        
        var isEnterpriseUser: Bool {
            return !tenantId.isEmpty && email.contains("@")
        }
        
        var userType: String {
            return isEnterpriseUser ? "Enterprise User" : "Personal Account"
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with Microsoft account
    func signIn() async {
        await MainActor.run {
            authenticationState = .authenticating
            errorMessage = nil
        }
        
        // Simulate MSAL authentication flow
        // In production, this would use actual MSAL SDK calls
        do {
            try await simulateMSALSignIn()
            
            await MainActor.run {
                authenticationState = .authenticated
                isAuthenticated = true
            }
            
            // Fetch user profile and enterprise data
            await fetchUserProfile()
            await fetchEnterpriseData()
            
        } catch {
            await MainActor.run {
                authenticationState = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Sign out from Microsoft account
    func signOut() async {
        await MainActor.run {
            authenticationState = .notAuthenticated
            isAuthenticated = false
            currentUser = nil
            errorMessage = nil
        }
        
        // Clear stored credentials
        clearStoredCredentials()
        
        // Simulate MSAL sign out
        // In production, this would use actual MSAL SDK calls
        try? await simulateMSALSignOut()
    }
    
    /// Refresh authentication token
    func refreshToken() async {
        guard isAuthenticated else { return }
        
        await MainActor.run {
            authenticationState = .authenticating
        }
        
        // Simulate token refresh
        // In production, this would use actual MSAL SDK calls
        try? await simulateTokenRefresh()
        
        await MainActor.run {
            authenticationState = .authenticated
        }
    }
    
    // MARK: - Enterprise Data Fetching
    
    /// Fetch user profile information
    private func fetchUserProfile() async {
        // Simulate API call to Microsoft Graph
        // In production, this would use actual Microsoft Graph API calls
        
        let simulatedUser = MSALUser(
            id: UUID().uuidString,
            displayName: "John Enterprise",
            email: "john.enterprise@company.com",
            tenantId: "company-tenant-id",
            jobTitle: "Security Engineer",
            department: "Information Security",
            manager: "Sarah Security",
            lastSignIn: Date()
        )
        
        await MainActor.run {
            currentUser = simulatedUser
        }
        
        // Store user credentials
        storeUserCredentials(simulatedUser)
    }
    
    /// Fetch enterprise-specific data
    private func fetchEnterpriseData() async {
        // Simulate fetching enterprise policies, compliance data, etc.
        // In production, this would integrate with enterprise systems
        
        // This would typically include:
        // - Company security policies
        // - Compliance requirements
        // - User permissions and roles
        // - Device compliance status
        // - Security group memberships
        
        print("🔐 Fetching enterprise data for user: \(currentUser?.email ?? "Unknown")")
    }
    
    // MARK: - Credential Management
    
    private func storeUserCredentials(_ user: MSALUser) {
        // In production, this would securely store MSAL tokens
        // For now, we'll store basic user info in UserDefaults
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "MSALUser")
        }
    }
    
    private func loadStoredCredentials() {
        // Load previously stored user credentials
        if let data = UserDefaults.standard.data(forKey: "MSALUser"),
           let user = try? JSONDecoder().decode(MSALUser.self, from: data) {
            currentUser = user
            isAuthenticated = true
            authenticationState = .authenticated
        }
    }
    
    private func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: "MSALUser")
    }
    
    // MARK: - MSAL Simulation Methods
    // These methods simulate MSAL behavior for development purposes
    // In production, they would be replaced with actual MSAL SDK calls
    
    private func simulateMSALSignIn() async throws {
        // Simulate network delay and authentication process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Simulate potential authentication failure (10% chance)
        if Int.random(in: 1...10) == 1 {
            throw MSALError.authenticationFailed("Simulated authentication failure")
        }
    }
    
    private func simulateMSALSignOut() async throws {
        // Simulate sign out process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    private func simulateTokenRefresh() async throws {
        // Simulate token refresh process
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - MSAL Errors
enum MSALError: LocalizedError {
    case authenticationFailed(String)
    case networkError(String)
    case configurationError(String)
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .userCancelled:
            return "Authentication was cancelled by user"
        }
    }
}

// MARK: - MSAL Authentication View
struct MSALAuthenticationView: View {
    @ObservedObject var authManager: MSALAuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "building.2.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Enterprise Authentication")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Sign in with your company account to access enterprise security features")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Authentication Status
            switch authManager.authenticationState {
            case .notAuthenticated:
                signInButton
            case .authenticating:
                authenticatingView
            case .authenticated:
                authenticatedView
            case .failed(let error):
                errorView(error)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Text("This app uses Microsoft Authentication Library (MSAL)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Your credentials are managed securely by Microsoft")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
        .background(Color(red: 0.04, green: 0.05, blue: 0.15))
    }
    
    // MARK: - View Components
    
    private var signInButton: some View {
        Button(action: {
            Task {
                await authManager.signIn()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "microsoft.logo")
                    .font(.title2)
                Text("Sign in with Microsoft")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var authenticatingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Authenticating...")
                .font(.headline)
            
            Text("Please wait while we verify your credentials")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Successfully Authenticated!")
                .font(.headline)
            
            if let user = authManager.currentUser {
                VStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(user.email)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(user.jobTitle ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Authentication Failed")
                .font(.headline)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        await authManager.signIn()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - MSAL User Profile View
struct MSALUserProfileView: View {
    @ObservedObject var authManager: MSALAuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            // User Avatar and Basic Info
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                if let user = authManager.currentUser {
                    VStack(spacing: 8) {
                        Text(user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text(user.userType)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(user.isEnterpriseUser ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                            )
                            .foregroundColor(user.isEnterpriseUser ? .green : .blue)
                    }
                }
            }
            
            // User Details
            if let user = authManager.currentUser {
                VStack(spacing: 12) {
                    MSALDetailRow(title: "Job Title", value: user.jobTitle ?? "Not specified")
                    MSALDetailRow(title: "Department", value: user.department ?? "Not specified")
                    MSALDetailRow(title: "Manager", value: user.manager ?? "Not specified")
                    MSALDetailRow(title: "Last Sign In", value: formatDate(user.lastSignIn))
                    MSALDetailRow(title: "Tenant ID", value: user.tenantId)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.08, green: 0.10, blue: 0.24))
                )
            }
            
            // Sign Out Button
            Button(action: {
                Task {
                    await authManager.signOut()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.04, green: 0.05, blue: 0.15))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Component
struct MSALDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    MSALAuthenticationView(authManager: MSALAuthenticationManager())
}
