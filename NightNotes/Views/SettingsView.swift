import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var purchase: PurchaseManager
    @State private var showDreamerTypePicker = false
    @State private var morningReminderEnabled = UserDefaults.standard.bool(forKey: "morningReminderEnabled")
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    var body: some View {
        ZStack {
            AuroraView()
            VStack(alignment: .leading, spacing: 0) {
                Text("Account")
                    .font(NNFont.display(56))
                    .foregroundColor(NNColour.textPrimary)
                    .padding(.bottom, 8)

                Text(auth.user?.email ?? "dreamer")
                    .font(NNFont.ui(11))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    .padding(.bottom, 40)

                settingsSection("Subscription") {
                    if purchase.isSubscribed {
                        HStack {
                            GlowOrb(colour: NNColour.orbAmber, size: 7, animate: false)
                            Text("Active")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    } else {
                        HStack {
                            let used = auth.user?.freeInterpretationsUsed ?? 0
                            let remaining = max(0, 7 - used)
                            Text("\(remaining) free dream\(remaining == 1 ? "" : "s") remaining")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                }

                Hairline()

                settingsSection("Dream type") {
                    Button(action: { showDreamerTypePicker = true }) {
                        HStack {
                            Text(auth.user?.dreamerType?.extendedLabel ?? "Not set")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                            Spacer()
                            Text("Change")
                                .font(NNFont.ui(10))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(0.4))
                        }
                        .padding(.vertical, 14)
                    }
                }

                Hairline()

                settingsSection("Reminders") {
                    Button(action: { toggleMorningReminder() }) {
                        HStack {
                            Text("Morning prompt")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textPrimary.opacity(0.7))
                            Spacer()
                            Text(morningReminderEnabled ? "On" : "Off")
                                .font(NNFont.ui(10))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(morningReminderEnabled ? 0.7 : 0.4))
                        }
                        .padding(.vertical, 14)
                    }
                }

                Hairline()
                Spacer()

                Button(action: {
                    Task { await auth.signOut() }
                }) {
                    Text("SIGN OUT")
                        .font(NNFont.ui(11))
                        .tracking(3)
                        .foregroundColor(NNColour.textPrimary.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(NNColour.glassLight)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(NNColour.glassBorder, lineWidth: 1))
                        .cornerRadius(12)
                }
                .padding(.bottom, 16)

                Text("night notes · by useful for humans")
                    .font(NNFont.ui(9))
                    .tracking(2)
                    .foregroundColor(NNColour.textPrimary.opacity(0.25))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 26)
            .padding(.top, 56)
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showDreamerTypePicker) { DreamerTypePickerSheet() }
        .onAppear { Task { await purchase.updateSubscriptionStatus() } }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(NNFont.ui(9))
                .tracking(4)
                .foregroundColor(NNColour.textPrimary.opacity(0.35))
                .padding(.top, 20)
                .padding(.bottom, 4)
            content()
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Morning Reminder
    // ─────────────────────────────────────────

    private func toggleMorningReminder() {
        let newValue = !morningReminderEnabled
        if newValue {
            scheduleMorningReminder()
        } else {
            morningReminderEnabled = false
            UserDefaults.standard.set(false, forKey: "morningReminderEnabled")
            cancelMorningReminder()
        }
    }

    private func scheduleMorningReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    morningReminderEnabled = false
                    UserDefaults.standard.set(false, forKey: "morningReminderEnabled")
                    return
                }
                morningReminderEnabled = true
                UserDefaults.standard.set(true, forKey: "morningReminderEnabled")

                // Use stored reminder time from onboarding
                let titles = [
                    "What happened last night?",
                    "Your mind was busy while you slept.",
                    "Dreams fade in minutes.",
                    "Something was there. What was it?",
                    "Catch it before it disappears.",
                    "Last night is still with you.",
                    "The other half of your day."
                ]

                // Remove old notifications
                center.removePendingNotificationRequests(withIdentifiers:
                    (0..<7).map { "nn.morning.reminder.\($0)" } + ["morningReminder"]
                )

                for dayOffset in 0..<7 {
                    let content = UNMutableNotificationContent()
                    content.title = titles[dayOffset]
                    content.body = "Open Night Notes before it fades."
                    content.sound = .default

                    var dateComponents = DateComponents()
                    dateComponents.hour = reminderHour
                    dateComponents.minute = reminderMinute
                    dateComponents.weekday = dayOffset + 1

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
    }

    private func cancelMorningReminder() {
        let ids = (0..<7).map { "nn.morning.reminder.\($0)" } + ["morningReminder"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

struct DreamerTypePickerSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var selected: DreamerType?

    var body: some View {
        ZStack {
            AuroraView()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Dream type")
                        .font(NNFont.display(32))
                        .foregroundColor(NNColour.textPrimary)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(NNFont.ui(12))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                }
                .padding(.bottom, 32)

                ForEach(DreamerType.allCases, id: \.self) { type in
                    DreamerTypeRow(
                        type: type,
                        isSelected: (selected ?? auth.user?.dreamerType) == type,
                        onTap: {
                            selected = type
                            Task { await auth.saveDreamerType(type); dismiss() }
                        }
                    )
                }
                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 52)
        }
        .onAppear { selected = auth.user?.dreamerType }
    }
}
