import SwiftUI

// ─────────────────────────────────────────
// MARK: - Aurora Background
// ─────────────────────────────────────────

struct AuroraView: View {
    var hueShift: Double = 0
    var scaleBoost: Double = 1.0

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            AuroraCanvas(time: Float(t))
        }
        .hueRotation(.degrees(hueShift))
        .scaleEffect(scaleBoost)
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────
// MARK: - Aurora Canvas
// ─────────────────────────────────────────

// ─────────────────────────────────────────
// MARK: - Time-of-day Palette
// ─────────────────────────────────────────

struct AuroraPalette {
    let primary: Color
    let primaryOpacity: Double
    let secondary: Color
    let secondaryOpacity: Double

    static func current() -> AuroraPalette {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:
            // Morning — rose/amber warmth
            return AuroraPalette(
                primary: Color(red: 180/255, green: 80/255, blue: 120/255),
                primaryOpacity: 0.55,
                secondary: Color(red: 140/255, green: 60/255, blue: 160/255),
                secondaryOpacity: 0.35
            )
        case 10..<17:
            // Daytime — neutral violet/rose (original)
            return AuroraPalette(
                primary: Color(red: 123/255, green: 63/255, blue: 196/255),
                primaryOpacity: 0.50,
                secondary: Color(red: 196/255, green: 94/255, blue: 171/255),
                secondaryOpacity: 0.40
            )
        case 17..<22:
            // Evening — deeper violet, warm dusk
            return AuroraPalette(
                primary: Color(red: 100/255, green: 40/255, blue: 160/255),
                primaryOpacity: 0.55,
                secondary: Color(red: 160/255, green: 60/255, blue: 100/255),
                secondaryOpacity: 0.45
            )
        default:
            // Night (22-4) — deep ink
            return AuroraPalette(
                primary: Color(red: 60/255, green: 20/255, blue: 120/255),
                primaryOpacity: 0.60,
                secondary: Color(red: 80/255, green: 30/255, blue: 100/255),
                secondaryOpacity: 0.35
            )
        }
    }
}

struct AuroraCanvas: View {
    let time: Float
    private let palette = AuroraPalette.current()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t = Double(time)

            ZStack {
                NNColour.void

                // Blob 1 — Primary, upper left (8s breathing cycle)
                RadialBlob(
                    color: palette.primary,
                    centerX: 0.22 + 0.06 * sin(t * 0.096),
                    centerY: 0.28 + 0.05 * cos(t * 0.096),
                    radiusX: w * 1.0 + 15 * CGFloat(sin(t * .pi * 2 / 8.0)),
                    radiusY: h * 0.70 + 15 * CGFloat(cos(t * .pi * 2 / 8.5)),
                    opacity: palette.primaryOpacity * 1.7
                )

                // Blob 2 — Secondary, upper right (9s cycle)
                RadialBlob(
                    color: palette.secondary,
                    centerX: 0.78 + 0.05 * cos(t * 0.148),
                    centerY: 0.22 + 0.06 * sin(t * 0.148),
                    radiusX: w * 0.95 + 15 * CGFloat(sin(t * .pi * 2 / 9.0)),
                    radiusY: h * 0.68 + 15 * CGFloat(cos(t * .pi * 2 / 8.0)),
                    opacity: palette.secondaryOpacity * 2.25
                )

                // Blob 3 — Primary lower (8.5s cycle)
                RadialBlob(
                    color: palette.primary,
                    centerX: 0.35 + 0.04 * sin(t * 0.078),
                    centerY: 0.72 + 0.04 * cos(t * 0.078),
                    radiusX: w * 0.90 + 15 * CGFloat(sin(t * .pi * 2 / 8.5)),
                    radiusY: h * 0.55 + 15 * CGFloat(cos(t * .pi * 2 / 9.0)),
                    opacity: palette.primaryOpacity * 1.27
                )

                // Blob 4 — Secondary lower right (9.5s cycle)
                RadialBlob(
                    color: palette.secondary,
                    centerX: 0.80 + 0.04 * cos(t * 0.113),
                    centerY: 0.68 + 0.04 * sin(t * 0.113),
                    radiusX: w * 0.80 + 15 * CGFloat(sin(t * .pi * 2 / 9.5)),
                    radiusY: h * 0.50 + 15 * CGFloat(cos(t * .pi * 2 / 8.0)),
                    opacity: palette.secondaryOpacity * 1.625
                )

                // Blob 5 — Ember accent, top right (8s cycle)
                RadialBlob(
                    color: Color(red: 0.843, green: 0.314, blue: 0.188),
                    centerX: 0.88 + 0.04 * sin(t * 0.200),
                    centerY: 0.08 + 0.04 * cos(t * 0.200),
                    radiusX: w * 0.55 + 15 * CGFloat(sin(t * .pi * 2 / 8.0)),
                    radiusY: h * 0.38 + 15 * CGFloat(cos(t * .pi * 2 / 8.5)),
                    opacity: 0.45
                )
            }
            .frame(width: w, height: h)
            .drawingGroup()
            // Additional bloom layers
            .overlay(
                ZStack {
                    // Rose/pink tight bloom — bottom-left, 28s drift
                    Circle()
                        .fill(Color(red: 0.85, green: 0.35, blue: 0.55))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                        .opacity(0.22)
                        .position(
                            x: w * 0.18 + 30 * CGFloat(sin(t * .pi * 2 / 28)),
                            y: h * 0.78 + 20 * CGFloat(cos(t * .pi * 2 / 28))
                        )
                    // Deep violet diffuse bloom — centred high, 20s breathe
                    Circle()
                        .fill(Color(red: 0.25, green: 0.10, blue: 0.45))
                        .frame(width: 500, height: 500)
                        .blur(radius: 100)
                        .opacity(0.13 + 0.05 * sin(t * .pi * 2 / 20))
                        .position(x: w * 0.5, y: h * 0.35)
                }
                .allowsHitTesting(false)
            )
            // Film grain
            .overlay(FilmGrainCanvas())
            // Vignette
            .overlay(VignetteOverlay())
        }
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────
// MARK: - Radial Blob
// ─────────────────────────────────────────

struct RadialBlob: View {
    let color: Color
    let centerX: Double
    let centerY: Double
    let radiusX: CGFloat
    let radiusY: CGFloat
    let opacity: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w * centerX
            let cy = h * centerY
            let r = max(radiusX, radiusY) * 0.75

            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(opacity),        location: 0.00),
                    .init(color: color.opacity(opacity * 0.55), location: 0.40),
                    .init(color: color.opacity(opacity * 0.10), location: 0.75),
                    .init(color: color.opacity(0),              location: 1.00),
                ]),
                center: UnitPoint(x: cx / w, y: cy / h),
                startRadius: 0,
                endRadius: r
            )
            .blendMode(.plusLighter)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Glow Orb
// ─────────────────────────────────────────

struct GlowOrb: View {
    var colour: Color = NNColour.orbRose
    var size: CGFloat = 14
    var animate: Bool = true

    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: size, height: size)
            .shadow(color: colour.opacity(0.70), radius: 5)
            .shadow(color: colour.opacity(0.45), radius: 14)
            .shadow(color: colour.opacity(0.22), radius: 34)
            .shadow(color: colour.opacity(0.10), radius: 68)
            .shadow(color: colour.opacity(0.05), radius: 120)
            .scaleEffect(pulse ? 1.14 : 1.0)
            .animation(
                animate
                    ? .easeInOut(duration: 5.4).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
            .onAppear { if animate { pulse = true } }
    }
}

// ─────────────────────────────────────────
// MARK: - Film Grain (Canvas)
// ─────────────────────────────────────────

struct FilmGrainCanvas: View {
    private struct GrainPoint {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
    }

    @State private var points: [GrainPoint] = []

    var body: some View {
        Canvas { context, size in
            for p in points {
                let rect = CGRect(
                    x: p.x * size.width - p.radius,
                    y: p.y * size.height - p.radius,
                    width: p.radius * 2,
                    height: p.radius * 2
                )
                context.opacity = p.opacity
                context.fill(Circle().path(in: rect), with: .color(.white))
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            points = (0..<800).map { _ in
                GrainPoint(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    radius: CGFloat.random(in: 0.6...1.0),
                    opacity: Double.random(in: 0.03...0.06)
                )
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Vignette
// ─────────────────────────────────────────

struct VignetteOverlay: View {
    var body: some View {
        Rectangle()
            .fill(RadialGradient(
                gradient: Gradient(colors: [.clear, Color.black.opacity(0.45)]),
                center: .center,
                startRadius: 80,
                endRadius: 420
            ))
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// ─────────────────────────────────────────
// MARK: - Hairline
// ─────────────────────────────────────────

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(NNColour.hairline)
            .frame(height: 1)
    }
}
