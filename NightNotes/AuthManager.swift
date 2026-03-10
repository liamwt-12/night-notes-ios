import SwiftUI
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var user: UserProfile?
    @Published var error: String?
    
    private let supabase = SupabaseClient.shared
    
    init() { Task { await checkSession() } }
    
    func checkSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            await fetchProfile(userId: session.user.id)
            isAuthenticated = true
        } catch { isAuthenticated = false }
        isLoading = false
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let token = credential.identityToken,
              let tokenString = String(data: token, encoding: .utf8) else { return }
        isLoading = true
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: tokenString))
            await fetchProfile(userId: session.user.id)
            isAuthenticated = true
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
    
    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        user = nil
    }
    
    func fetchProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await supabase.database
                .from("profiles").select().eq("id", value: userId.uuidString).single().execute().value
            self.user = profile
        } catch { print("Profile error: \(error)") }
    }
    
    func refreshProfile() async {
        guard let id = user?.id else { return }
        await fetchProfile(userId: id)
    }
}
