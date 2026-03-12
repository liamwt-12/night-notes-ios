import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var step: OnboardingStep = .hero
    @State private var selectedType: DreamerType? = nil

    var body: some View {
        ZStack {
            AuroraView()
            switch step {
            case .hero:
                HeroScreen(onContinue: { step = .dreamerType }).transition(.opacity)
            case .dreamerType:
                DreamerTypeScreen(selectedType: $selectedType, onContinue: { step = .transition }).transition(.opacity)
            case .transition:
                TransitionScreen(onContinue: { step = .signIn }).transition(.opacity)
            case .signIn:
                SignInScreen(selectedType: selectedType).transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: step)
    }
}

struct HeroScreen: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("night notes")
                .font(NNFont.ui(11))
                .tracking(6)
                .foregroundColor(NNColour.textPrimary.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack {
                Spacer()
                GlowOrb(colour: NNColour.orbRose, size: 18)
                Spacer()
            }
            .padding(.bottom, 48)

            VStack(alignment: .leading, spacing: 16) {
                Text("Dreams fade quickly.")
                    .font(NNFont.display(54))
                    .foregroundColor(NNColour.textPrimary)
                    .lineLimit(2)

                Text("Write them down before they disappear.")
                    .font(.custom("PlayfairDisplay-Italic", size: 18))
                    .foregroundColor(NNColour.textPrimary.opacity(0.6))
                    .lineSpacing(4)
            }

            Spacer().frame(height: 52)

            Button(action: onContinue) {
                Text("Get started")
                    .font(NNFont.ui(15))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(NNColour.glassLight)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 64)
        .padding(.bottom, 52)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear { withAnimation(.easeOut(duration: 0.8).delay(0.2)) { appeared = true } }
    }
}

struct DreamerTypeScreen: View {
    @Binding var selectedType: DreamerType?
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("night notes")
                .font(NNFont.ui(11))
                .tracking(6)
                .foregroundColor(NNColour.textPrimary.opacity(0.5))

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                Text("How do you\ndream?")
                    .font(NNFont.display(52))
                    .foregroundColor(NNColour.textPrimary)
                    .lineSpacing(-2)

                Hairline().padding(.vertical, 8)

                ForEach(DreamerType.allCases, id: \.self) { type in
                    DreamerTypeRow(type: type, isSelected: selectedType == type, onTap: { selectedType = type })
                }

                Hairline().padding(.top, 8)
            }

            Spacer().frame(height: 40)

            Button(action: { if selectedType != nil { onContinue() } }) {
                Text("Continue")
                    .font(NNFont.ui(15))
                    .tracking(2)
                    .foregroundColor(selectedType != nil ? NNColour.textPrimary : NNColour.textPrimary.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(NNColour.glassLight)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                    .cornerRadius(14)
            }
            .disabled(selectedType == nil)
        }
        .padding(.horizontal, 28)
        .padding(.top, 64)
        .padding(.bottom, 52)
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }
}

struct DreamerTypeRow: View {
    let type: DreamerType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                        .shadow(color: NNColour.orbRose.opacity(isSelected ? 0.9 : 0), radius: 4)
                        .shadow(color: NNColour.orbRose.opacity(isSelected ? 0.5 : 0), radius: 12)
                    Circle()
                        .fill(isSelected ? NNColour.orbRose.opacity(0.8) : NNColour.textPrimary.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
                .frame(width: 20)

                Text(type.extendedLabel)
                    .font(.custom("PlayfairDisplay-Italic", size: 19))
                    .foregroundColor(isSelected ? NNColour.textPrimary : NNColour.textPrimary.opacity(0.5))

                Spacer()
            }
            .padding(.vertical, 14)
        }
    }
}

struct TransitionScreen: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            GlowOrb(colour: NNColour.orbRose, size: 22)
            Spacer().frame(height: 48)

            Text("A quiet place\nfor your dreams.")
                .font(NNFont.display(34))
                .foregroundColor(NNColour.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 16)

            Text("No judgement. Just a place to look.")
                .font(.custom("PlayfairDisplay-Italic", size: 16))
                .foregroundColor(NNColour.textPrimary.opacity(0.55))
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onContinue) {
                Text("I'm ready")
                    .font(NNFont.ui(15))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(NNColour.glassLight)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 52)
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { appeared = true } }
    }
}

struct SignInScreen: View {
    let selectedType: DreamerType?
    @EnvironmentObject var auth: AuthManager
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Sign in to continue")
                .font(NNFont.display(44))
                .foregroundColor(NNColour.textPrimary)

            Spacer().frame(height: 12)

            Text("Your dreams are saved privately\nacross all your devices.")
                .font(.custom("PlayfairDisplay-Italic", size: 16))
                .foregroundColor(NNColour.textPrimary.opacity(0.55))
                .lineSpacing(4)

            Spacer()

            VStack(spacing: 14) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.email]
                } onCompletion: { result in
                    switch result {
                    case .success(let auth):
                        guard let appleId = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                        Task {
                            await self.auth.signInWithApple(credential: appleId)
                            if let type = selectedType { await self.auth.saveDreamerType(type) }
                        }
                    case .failure(let error):
                        print("Apple Sign In error: \(error)")
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .cornerRadius(14)

                Text("Your dreams are private. Always.")
                    .font(NNFont.ui(10))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 80)
        .padding(.bottom, 52)
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }
}
