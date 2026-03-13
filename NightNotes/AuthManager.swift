import Foundation
import AuthenticationServices
import Supabase

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading       = false
    @Published var user: UserProfile?
    @Published var error: String?

    init() {
        // ⚠️ Temporary: reset for testing fresh onboarding — remove after confirming
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    // ─────────────────────────────────────────
    // MARK: - Session Check
    // ─────────────────────────────────────────

    func checkSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            let success = await fetchProfile(userId: session.user.id)
            print("🔍 checkSession: fetchProfile returned \(success), user is now: \(String(describing: self.user?.id))")
            if success && user != nil {
                isAuthenticated = true
            } else {
                print("❌ checkSession: session valid but profile load failed — user stays nil")
                self.error = "Could not load profile — please sign out and try again"
                isAuthenticated = false
            }
        } catch {
            print("❌ checkSession error (no session): \(error)")
            isAuthenticated = false
        }
        isLoading = false
    }

    /// Attempt to recover auth.user from the existing session WITHOUT setting isLoading.
    /// This avoids tearing down the view hierarchy when called from inside MainTabView.
    func recoverUser() async -> Bool {
        do {
            let session = try await supabase.auth.session
            let success = await fetchProfile(userId: session.user.id)
            print("🔍 recoverUser: fetchProfile returned \(success), user is now: \(String(describing: self.user?.id))")
            return success && user != nil
        } catch {
            print("❌ recoverUser: no valid session — \(error)")
            return false
        }
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
            let success = await fetchOrCreateProfile(userId: session.user.id, email: session.user.email)
            if success && user != nil {
                isAuthenticated = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            } else {
                self.error = "Could not load profile — please sign out and try again"
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // ─────────────────────────────────────────
    // MARK: - Profile
    // ─────────────────────────────────────────

    @discardableResult
    func fetchProfile(userId: UUID, retried: Bool = false) async -> Bool {
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: response.data)
            user = profile
            return true
        } catch {
            print("❌ fetchProfile error: \(error)")

            // Don't retry more than once to avoid infinite recursion
            guard !retried else {
                print("❌ fetchProfile already retried — giving up")
                self.error = "Could not load profile — please sign out and try again"
                return false
            }

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


                return await fetchProfile(userId: userId, retried: true)
            } catch {
                print("❌ Profile upsert failed — full error object: \(error)")
                print("❌ Profile upsert failed — localizedDescription: \(error.localizedDescription)")
                self.error = "Could not load profile — please sign out and try again"
                return false
            }
        }
    }

    @discardableResult
    private func fetchOrCreateProfile(userId: UUID, email: String?) async -> Bool {
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            let profile = try JSONDecoder.supabase.decode(UserProfile.self, from: response.data)
            user = profile
            return true
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


                return await fetchProfile(userId: userId, retried: true)
            } catch {
                print("❌ Profile create failed — full error object: \(error)")
                print("❌ Profile create failed — localizedDescription: \(error.localizedDescription)")
                self.error = "Could not load profile — please sign out and try again"
                return false
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
        error = nil
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

// ─────────────────────────────────────────
// MARK: - Helper struct for profile creation
// ─────────────────────────────────────────
// CodingKeys verified: subscription_active and free_interpretations_used
// match the exact Supabase column names in the profiles table.

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
