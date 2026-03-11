import SwiftUI

// ─────────────────────────────────────────
// MARK: - Settings View
// ─────────────────────────────────────────
// Screen 12: "You." — minimal, no boxes

struct SettingsView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var purchase: PurchaseManager

    @State private var showDreamerTypePicker = false

    var body: some View {
        ZStack {
            AuroraView()
            GrainOverlay()

            VStack(alignment: .leading, spacing: 0) {

                // Heading
                Text("You.")
                    .font(NNFont.display(56))
                    .foregroundColor(NNColour.textPrimary)
                    .padding(.bottom, 8)

                Text(auth.user?.email ?? "dreamer")
                    .font(NNFont.ui(11))
                    .tracking(2)
                    .foregroundColor(NNColour.textMuted)
                    .padding(.bottom, 40)

                // Subscription status
                settingsSection("Subscription") {
                    if purchase.isSubscribed {
                        HStack {
                            GlowOrb(colour: NNColour.orbAmber, size: 7, animate: false)
                            Text("Active")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    } else {
                        HStack {
                            let used  = auth.user?.freeInterpretationsUsed ?? 0
                            let total = 3
                            Text("\(total - min(used, total)) free reading\(total - min(used, total) == 1 ? "" : "s") remaining")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textSecondary)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                }

                Hairline()

                // Dreamer type
                settingsSection("Dreamer type") {
                    Button(action: { showDreamerTypePicker = true }) {
                        HStack {
                            Text(auth.user?.dreamerType?.label ?? "Not set")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textSecondary)
                            Spacer()
                            Text("Change")
                                .font(NNFont.ui(10))
                                .tracking(2)
                                .foregroundColor(NNColour.textMuted)
                        }
                        .padding(.vertical, 14)
                    }
                }

                Hairline()

                // Notifications placeholder
                settingsSection("Reminders") {
                    HStack {
                        Text("Morning prompt")
                            .font(.custom("PlayfairDisplay-Italic", size: 16))
                            .foregroundColor(NNColour.textSecondary)
                        Spacer()
                        Text("Off")
                            .font(NNFont.ui(10))
                            .tracking(2)
                            .foregroundColor(NNColour.textMuted)
                    }
                    .padding(.vertical, 14)
                }

                Hairline()

                Spacer()

                // Sign out
                Button(action: {
                    Task { await auth.signOut() }
                }) {
                    Text("Sign out")
                        .font(NNFont.ui(11))
                        .tracking(3)
                        .foregroundColor(NNColour.textMuted)
                }
                .padding(.bottom, 16)

                // Legal
                Text("night notes · by useful for humans")
                    .font(NNFont.ui(9))
                    .tracking(2)
                    .foregroundColor(NNColour.textMuted.opacity(0.5))
            }
            .padding(.horizontal, 26)
            .padding(.top, 56)
            .padding(.bottom, 44)
        }
        .sheet(isPresented: $showDreamerTypePicker) {
            DreamerTypePickerSheet()
        }
        .onAppear {
            Task { await purchase.updateSubscriptionStatus() }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(NNFont.ui(9))
                .tracking(4)
                .foregroundColor(NNColour.textMuted)
                .padding(.top, 20)
                .padding(.bottom, 4)
            content()
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Dreamer Type Picker Sheet
// ─────────────────────────────────────────

struct DreamerTypePickerSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var selected: DreamerType?

    var body: some View {
        ZStack {
            AuroraView()
            GrainOverlay()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Dreamer type")
                        .font(NNFont.display(32))
                        .foregroundColor(NNColour.textPrimary)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(NNFont.ui(12))
                        .tracking(2)
                        .foregroundColor(NNColour.textMuted)
                }
                .padding(.bottom, 32)

                ForEach(DreamerType.allCases, id: \.self) { type in
                    DreamerTypeRow(
                        type: type,
                        isSelected: (selected ?? auth.user?.dreamerType) == type,
                        onTap: {
                            selected = type
                            Task {
                                await auth.saveDreamerType(type)
                                dismiss()
                            }
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
