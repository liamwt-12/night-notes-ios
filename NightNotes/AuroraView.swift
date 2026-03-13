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

                // Blob 1 — Rose, upper left, large (5s breathing cycle)
                RadialBlob(
                    color: Color(red: 0.647, green: 0.216, blue: 0.529),
                    centerX: 0.22 + 0.06 * sin(t * 0.11),
                    centerY: 0.28 + 0.05 * cos(t * 0.11),
                    radiusX: w * 1.0 + 15 * CGFloat(sin(t * .pi * 2 / 5.0)),
                    radiusY: h * 0.70 + 15 * CGFloat(cos(t * .pi * 2 / 5.5)),
                    opacity: 0.95
                )

                // Blob 2 — Indigo, upper right, large (4.5s cycle)
                RadialBlob(
                    color: Color(red: 0.333, green: 0.188, blue: 0.765),
                    centerX: 0.78 + 0.05 * cos(t * 0.17),
                    centerY: 0.22 + 0.06 * sin(t * 0.17),
                    radiusX: w * 0.95 + 15 * CGFloat(sin(t * .pi * 2 / 4.5)),
                    radiusY: h * 0.68 + 15 * CGFloat(cos(t * .pi * 2 / 5.0)),
                    opacity: 0.90
                )

                // Blob 3 — Rose lower, fills bottom half (5.5s cycle)
                RadialBlob(
                    color: Color(red: 0.500, green: 0.150, blue: 0.420),
                    centerX: 0.35 + 0.04 * sin(t * 0.09),
                    centerY: 0.72 + 0.04 * cos(t * 0.09),
                    radiusX: w * 0.90 + 15 * CGFloat(sin(t * .pi * 2 / 5.5)),
                    radiusY: h * 0.55 + 15 * CGFloat(cos(t * .pi * 2 / 4.8)),
                    opacity: 0.70
                )

                // Blob 4 — Indigo lower right (6s cycle)
                RadialBlob(
                    color: Color(red: 0.250, green: 0.140, blue: 0.600),
                    centerX: 0.80 + 0.04 * cos(t * 0.13),
                    centerY: 0.68 + 0.04 * sin(t * 0.13),
                    radiusX: w * 0.80 + 15 * CGFloat(sin(t * .pi * 2 / 6.0)),
                    radiusY: h * 0.50 + 15 * CGFloat(cos(t * .pi * 2 / 5.2)),
                    opacity: 0.65
                )

                // Blob 5 — Ember, top right accent (4s cycle)
                RadialBlob(
                    color: Color(red: 0.843, green: 0.314, blue: 0.188),
                    centerX: 0.88 + 0.04 * sin(t * 0.23),
                    centerY: 0.08 + 0.04 * cos(t * 0.23),
                    radiusX: w * 0.55 + 15 * CGFloat(sin(t * .pi * 2 / 4.0)),
                    radiusY: h * 0.38 + 15 * CGFloat(cos(t * .pi * 2 / 4.3)),
                    opacity: 0.45
                )
            }
            .frame(width: w, height: h)
            .drawingGroup()
            .overlay(GrainOverlay())
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
            let r = max(radiusX, radiusY) * 0.65

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
                    ? .easeInOut(duration: 4.5).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
            .onAppear { if animate { pulse = true } }
    }
}

// ─────────────────────────────────────────
// MARK: - Grain Overlay
// ─────────────────────────────────────────

struct GrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(
                ImagePaint(
                    image: Image(uiImage: Self.grainImage),
                    scale: 0.5
                )
            )
            .opacity(0.045)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }

    private static let grainImage: UIImage = {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()!
        for _ in 0..<18000 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let alpha = CGFloat.random(in: 0.08...0.55)
            ctx.setFillColor(UIColor(white: 1, alpha: alpha).cgColor)
            ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }()
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
