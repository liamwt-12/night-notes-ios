import SwiftUI
import AuthenticationServices
import UserNotifications

// ─────────────────────────────────────────
// MARK: - Progress Dots
// ─────────────────────────────────────────

struct OnboardingDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(i == current ? 0.6 : 0.18))
                    .frame(width: i == current ? 6 : 4, height: i == current ? 6 : 4)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Back Button
// ─────────────────────────────────────────

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(NNColour.textPrimary.opacity(0.35))
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var step: OnboardingStep = .hero
    @State private var selectedType: DreamerType? = nil

    var body: some View {
        ZStack {
            AuroraView()
            switch step {
            case .hero:
                HeroScreen(onContinue: { step = .dreamerType })
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .dreamerType:
                DreamerTypeScreen(selectedType: $selectedType, onContinue: { step = .notificationPicker }, onBack: { step = .hero })
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .notificationPicker:
                NotificationPickerScreen(onContinue: { step = .transition }, onBack: { step = .dreamerType })
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .transition:
                TransitionScreen(onContinue: { step = .signIn }, onBack: { step = .notificationPicker })
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .signIn:
                SignInScreen(selectedType: selectedType)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: step)
    }
}

// ─────────────────────────────────────────
// MARK: - Hero Screen
// ─────────────────────────────────────────

struct HeroScreen: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("night notes")
                    .font(NNFont.ui(11))
                    .tracking(6)
                    .foregroundColor(NNColour.textPrimary.opacity(0.5))
                Spacer()
            }

            Spacer().frame(height: 20)

            OnboardingDots(current: 0, total: 4)
                .frame(maxWidth: .infinity)

            Spacer()

            HStack {
                Spacer()
                GlowOrb(colour: NNColour.orbRose, size: 18)
                Spacer()
            }
            .padding(.bottom, 48)

            VStack(alignment: .leading, spacing: 16) {
                Text("The other half of your life.")
                    .font(NNFont.display(44))
                    .foregroundColor(NNColour.textPrimary)
                    .lineLimit(2)

                Text("Every night your mind tells you something.\nMost mornings you\u{2019}ve already forgotten it.")
                    .font(NNFont.body(14))
                    .foregroundColor(NNColour.textPrimary.opacity(0.7))
                    .lineSpacing(4)
            }

            Spacer().frame(height: 52)

            Button(action: onContinue) {
                Text("Get started")
                    .font(NNFont.ui(11))
                    .tracking(4)
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

// ─────────────────────────────────────────
// MARK: - Dreamer Type Screen
// ─────────────────────────────────────────

struct DreamerTypeScreen: View {
    @Binding var selectedType: DreamerType?
    let onContinue: () -> Void
    let onBack: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                OnboardingBackButton(action: onBack)
                Spacer()
            }

            Spacer().frame(height: 16)

            OnboardingDots(current: 1, total: 4)
                .frame(maxWidth: .infinity)

            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                Text("How do your\ndreams arrive?")
                    .font(NNFont.display(44))
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
                    .font(NNFont.ui(11))
                    .tracking(4)
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.extendedLabel)
                        .font(.custom("PlayfairDisplay-Italic", size: 18))
                        .foregroundColor(isSelected ? NNColour.textPrimary : NNColour.textPrimary.opacity(0.5))
                        .kerning(0.3)

                    Text(type.subtitle)
                        .font(NNFont.ui(12, weight: .ultraLight))
                        .foregroundColor(NNColour.textPrimary.opacity(0.45))
                }

                Spacer()
            }
            .padding(.vertical, 14)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Notification Time Picker
// ─────────────────────────────────────────

struct NotificationPickerScreen: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @State private var appeared = false
    @State private var wakeTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var permissionDenied = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton(action: onBack)
                Spacer()
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 16)

            OnboardingDots(current: 2, total: 4)

            Spacer()

            Text("When do you want to remember?")
                .font(NNFont.display(44))
                .foregroundColor(NNColour.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)

            Text("We\u{2019}ll remind you before the night disappears.")
                .font(NNFont.body(14))
                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, 36)

            // Time picker in frosted glass card
            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(20)
                .padding(.horizontal, 40)
                .padding(.bottom, 36)

            Button(action: { scheduleAndContinue() }) {
                Text("Set my reminder")
                    .font(NNFont.ui(11))
                    .tracking(4)
                    .foregroundColor(NNColour.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(NNColour.glassLight)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 28)

            Text("You can change this in Settings")
                .font(NNFont.ui(10))
                .foregroundColor(NNColour.textPrimary.opacity(0.4))
                .padding(.top, 12)

            if permissionDenied {
                Text("Enable in Settings \u{2192} Notifications")
                    .font(NNFont.ui(10))
                    .foregroundColor(NNColour.orbAmber.opacity(0.8))
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            Spacer()

            // Skip option
            Button(action: onContinue) {
                Text("Skip")
                    .font(NNFont.ui(11))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 28)
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
    }

    private func scheduleAndContinue() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeTime)
        let hour = components.hour ?? 8
        let minute = components.minute ?? 0
        reminderHour = hour
        reminderMinute = minute

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UserDefaults.standard.set(true, forKey: "morningReminderEnabled")
                    scheduleNotification(hour: hour, minute: minute)
                    onContinue()
                } else {
                    permissionDenied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        onContinue()
                    }
                }
            }
        }
    }

    private func scheduleNotification(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["nn.morning.reminder"])

        let titles = [
            "What happened last night?",
            "Your mind was busy while you slept.",
            "Dreams fade in minutes.",
            "Something was there. What was it?",
            "Catch it before it disappears.",
            "Last night is still with you.",
            "The other half of your day."
        ]

        // Schedule 7 notifications, one for each day of the week
        for dayOffset in 0..<7 {
            let content = UNMutableNotificationContent()
            content.title = titles[dayOffset]
            content.body = "Open Night Notes before it fades."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = dayOffset + 1 // 1=Sunday, 7=Saturday

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "nn.morning.reminder.\(dayOffset)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Transition Screen
// ─────────────────────────────────────────

struct TransitionScreen: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OnboardingBackButton(action: onBack)
                Spacer()
            }
            .padding(.horizontal, 36)

            Spacer().frame(height: 16)

            OnboardingDots(current: 3, total: 4)

            Spacer()
            GlowOrb(colour: NNColour.orbRose, size: 22)
            Spacer().frame(height: 48)

            Text("What you write here belongs to you.")
                .font(NNFont.display(34))
                .foregroundColor(NNColour.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 16)

            Text("No ads. No data sold. Just a private space\nto catch what your sleep is trying to say.")
                .font(NNFont.body(14))
                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            Button(action: onContinue) {
                Text("I\u{2019}m ready")
                    .font(NNFont.ui(11))
                    .tracking(4)
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

// ─────────────────────────────────────────
// MARK: - Sign In Screen
// ─────────────────────────────────────────

struct SignInScreen: View {
    let selectedType: DreamerType?
    @EnvironmentObject var auth: AuthManager
    @State private var appeared = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("One last step.")
                .font(NNFont.display(44))
                .foregroundColor(NNColour.textPrimary)

            Spacer().frame(height: 12)

            Text("Your journal is private and encrypted.\nSign in with Apple to get started.")
                .font(NNFont.body(14))
                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                .lineSpacing(4)

            Spacer()

            VStack(spacing: 14) {
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                } else {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authResult):
                            guard let appleId = authResult.credential as? ASAuthorizationAppleIDCredential else { return }
                            isSigningIn = true
                            errorMessage = nil
                            Task {
                                await self.auth.signInWithApple(credential: appleId)
                                if let type = selectedType { await self.auth.saveDreamerType(type) }
                            }
                        case .failure:
                            errorMessage = "Something went wrong. Please try again."
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(14)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(NNFont.ui(12))
                        .foregroundColor(NNColour.orbRose.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.opacity)
                        .animation(.easeIn(duration: 0.3), value: errorMessage)
                }

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
