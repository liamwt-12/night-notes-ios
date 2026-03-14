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

struct AuroraCanvas: View {
    let time: Float

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t = Double(time)

            ZStack {
                NNColour.void

                // Blob 1 — Rose, upper left (8s breathing cycle)
                RadialBlob(
                    color: Color(red: 0.647, green: 0.216, blue: 0.529),
                    centerX: 0.22 + 0.06 * sin(t * 0.096),
                    centerY: 0.28 + 0.05 * cos(t * 0.096),
                    radiusX: w * 1.0 + 15 * CGFloat(sin(t * .pi * 2 / 8.0)),
                    radiusY: h * 0.70 + 15 * CGFloat(cos(t * .pi * 2 / 8.5)),
                    opacity: 0.95
                )

                // Blob 2 — Indigo, upper right (9s cycle)
                RadialBlob(
                    color: Color(red: 0.333, green: 0.188, blue: 0.765),
                    centerX: 0.78 + 0.05 * cos(t * 0.148),
                    centerY: 0.22 + 0.06 * sin(t * 0.148),
                    radiusX: w * 0.95 + 15 * CGFloat(sin(t * .pi * 2 / 9.0)),
                    radiusY: h * 0.68 + 15 * CGFloat(cos(t * .pi * 2 / 8.0)),
                    opacity: 0.90
                )

                // Blob 3 — Rose lower (8.5s cycle)
                RadialBlob(
                    color: Color(red: 0.500, green: 0.150, blue: 0.420),
                    centerX: 0.35 + 0.04 * sin(t * 0.078),
                    centerY: 0.72 + 0.04 * cos(t * 0.078),
                    radiusX: w * 0.90 + 15 * CGFloat(sin(t * .pi * 2 / 8.5)),
                    radiusY: h * 0.55 + 15 * CGFloat(cos(t * .pi * 2 / 9.0)),
                    opacity: 0.70
                )

                // Blob 4 — Indigo lower right (9.5s cycle)
                RadialBlob(
                    color: Color(red: 0.250, green: 0.140, blue: 0.600),
                    centerX: 0.80 + 0.04 * cos(t * 0.113),
                    centerY: 0.68 + 0.04 * sin(t * 0.113),
                    radiusX: w * 0.80 + 15 * CGFloat(sin(t * .pi * 2 / 9.5)),
                    radiusY: h * 0.50 + 15 * CGFloat(cos(t * .pi * 2 / 8.0)),
                    opacity: 0.65
                )

                // Blob 5 — Ember, top right accent (8s cycle)
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
                        .frame(width: 120, height: 120)
                        .blur(radius: 80)
                        .opacity(0.15)
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
        .blendMode(.overlay)
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            points = (0..<800).map { _ in
                GrainPoint(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    radius: CGFloat.random(in: 0.6...1.0),
                    opacity: Double.random(in: 0.018...0.035)
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
        ZStack {
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 180)
                .frame(maxHeight: .infinity, alignment: .top)
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                .frame(height: 180)
                .frame(maxHeight: .infinity, alignment: .bottom)
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 180)
                .frame(maxWidth: .infinity, alignment: .leading)
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: 180)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .opacity(0.25)
        .allowsHitTesting(false)
        .ignoresSafeArea()
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
