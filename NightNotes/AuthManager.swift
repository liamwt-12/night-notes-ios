import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading       = false
    @Published var user: UserProfile?
    @Published var error: String?

    // ─────────────────────────────────────────
    // MARK: - Session Check
    // ─────────────────────────────────────────

    func checkSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            await fetchProfile(userId: session.user.id)
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    // ─────────────────────────────────────────
    // MARK: - Apple Sign In
    // ─────────────────────────────────────────

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let tokenData   = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8)
        else { return }

        isLoading = true
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: tokenString)
            )
            await fetchOrCreateProfile(userId: session.user.id, email: session.user.email)
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // ─────────────────────────────────────────
    // MARK: - Profile
    // ─────────────────────────────────────────

    func fetchProfile(userId: UUID) async {
        do {
            let data = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .data
            let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: data)
            user = profile
        } catch {
            print("❌ fetchProfile error: \(error)")
            // Profile missing — create a minimal one so the app can function
            let newProfile = NewProfile(
                id: userId,
                email: nil,
                subscriptionActive: false,
                freeInterpretationsUsed: 0
            )
            do {
                try await supabase
                    .from("profiles")
                    .upsert(newProfile)
                    .execute()
                await fetchProfile(userId: userId)
            } catch {
                print("❌ Profile upsert error: \(error)")
            }
        }
    }

    private func fetchOrCreateProfile(userId: UUID, email: String?) async {
        do {
            let data = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .data
            let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: data)
            user = profile
        } catch {
            print("❌ fetchOrCreateProfile error: \(error)")
            // Profile doesn't exist — create it
            let newProfile = NewProfile(
                id: userId,
                email: email,
                subscriptionActive: false,
                freeInterpretationsUsed: 0
            )
            do {
                try await supabase
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                await fetchProfile(userId: userId)
            } catch {
                print("❌ Profile create error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Dreamer Type
    // ─────────────────────────────────────────

    func saveDreamerType(_ type: DreamerType) async {
        guard let userId = user?.id else { return }
        do {
            try await supabase
                .from("profiles")
                .update(["dreamer_type": type.rawValue])
                .eq("id", value: userId.uuidString)
                .execute()
            await fetchProfile(userId: userId)
        } catch {
            print("❌ Dreamer type save error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Increment interpretations used
    // ─────────────────────────────────────────

    func incrementInterpretationsUsed() async {
        guard let userId = user?.id,
              let current = user?.freeInterpretationsUsed
        else { return }
        do {
            try await supabase
                .from("profiles")
                .update(["free_interpretations_used": current + 1])
                .eq("id", value: userId.uuidString)
                .execute()
            user?.freeInterpretationsUsed = current + 1
        } catch {
            print("❌ Increment error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Sign Out
    // ─────────────────────────────────────────

    func signOut() async {
        try? await supabase.auth.signOut()
        isAuthenticated = false
        user = nil
    }
}

// ─────────────────────────────────────────
// MARK: - Helper struct for profile creation
// ─────────────────────────────────────────

private struct NewProfile: Codable {
    let id: UUID
    let email: String?
    let subscriptionActive: Bool
    let freeInterpretationsUsed: Int

    enum CodingKeys: String, CodingKey {
        case id, email,
             subscriptionActive        = "subscription_active",
             freeInterpretationsUsed   = "free_interpretations_used"
    }
}
