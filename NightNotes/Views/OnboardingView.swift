import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            VeilBackground()
            VStack {
                Spacer()
                Text("Night Notes").font(Theme.logoLargeFont).foregroundColor(Theme.textPrimary)
                Text("See what came through").font(Theme.bodySerifFont).foregroundColor(Theme.textSecondary).padding(.top, 12)
                Spacer()
                
                SignInWithAppleButton(onRequest: { $0.requestedScopes = [.email] },
                    onCompletion: { result in
                        if case .success(let auth) = result,
                           let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                            Task { await authManager.signInWithApple(credential: cred) }
                        }
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(32)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
            }
        }
    }
}
