import SwiftUI

struct Theme {
    static let background = Color(hex: "F5F3F0")
    static let textPrimary = Color(hex: "38343A")
    static let textSecondary = Color(hex: "8A8488")
    static let textMuted = Color(hex: "A09AA4")
    static let cardBackground = Color.white.opacity(0.55)
    static let cardBorder = Color.white.opacity(0.6)
    static let buttonPrimary = Color(hex: "38343A")
    static let buttonText = Color(hex: "F5F3F0")
    static let veilPurple = Color(hex: "C8BED2").opacity(0.35)
    static let veilBlue = Color(hex: "BEC8D7").opacity(0.3)
    static let veilWarm = Color(hex: "D7CDC8").opacity(0.2)
    
    static let logoFont = Font.system(size: 13, weight: .light, design: .serif).italic()
    static let logoLargeFont = Font.system(size: 36, weight: .light, design: .serif).italic()
    static let headingFont = Font.system(size: 32, weight: .light, design: .serif).italic()
    static let bodySerifFont = Font.system(size: 18, weight: .regular, design: .serif)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 11, weight: .regular)
    static let buttonFont = Font.system(size: 16, weight: .regular, design: .serif).italic()
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

struct VeilBackground: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Theme.background
            Ellipse().fill(LinearGradient(colors: [Theme.veilPurple, .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 500, height: 400).blur(radius: 60)
                .offset(x: animate ? -50 : -80, y: animate ? -100 : -120)
                .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate)
            Ellipse().fill(LinearGradient(colors: [Theme.veilBlue, .clear], startPoint: .topTrailing, endPoint: .bottomLeading))
                .frame(width: 450, height: 350).blur(radius: 70)
                .offset(x: animate ? 100 : 80, y: animate ? 150 : 180)
                .animation(.easeInOut(duration: 28).repeatForever(autoreverses: true), value: animate)
        }
        .ignoresSafeArea()
        .onAppear { animate = true }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.buttonFont)
            .foregroundColor(Theme.buttonText)
            .padding(.horizontal, 56).padding(.vertical, 20)
            .background(Theme.buttonPrimary)
            .cornerRadius(32)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.background(RoundedRectangle(cornerRadius: 28).fill(Theme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.cardBorder, lineWidth: 1)))
    }
}

struct ModeToggle: View {
    @Binding var mode: InterpretationMode
    var body: some View {
        HStack(spacing: 28) {
            ModeOption(title: "Surface", isSelected: mode == .surface) { mode = .surface }
            ModeOption(title: "Beneath", isSelected: mode == .beneath) { mode = .beneath }
        }
    }
}

struct ModeOption: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title).font(Theme.captionFont).foregroundColor(isSelected ? Theme.textPrimary : Theme.textMuted)
                Rectangle().fill(Theme.textPrimary).frame(height: 1).opacity(isSelected ? 1 : 0)
            }
        }
    }
}

enum InterpretationMode: String, Codable { case surface, beneath }
