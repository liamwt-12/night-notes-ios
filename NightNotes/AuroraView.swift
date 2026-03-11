import SwiftUI

// ─────────────────────────────────────────
// MARK: - Aurora Background
// ─────────────────────────────────────────
// Stacked radial gradient ellipses with .screen blend mode.
// This matches the CSS radial-gradient additive compositing
// far better than Canvas, which clips gradients differently.

struct AuroraView: View {
    var hueShift: Double = 0
    var scaleBoost: Double = 1.0

    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            auroraLayer(t: t)
        }
        .hueRotation(.degrees(hueShift))
        .scaleEffect(scaleBoost)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func auroraLayer(t: Double) -> some View {
        ZStack {
            // Base — deep void
            NNColour.void
                .ignoresSafeArea()

            // Blob 1 — rose, slow drift
            AuroraBlob(
                colour: NNColour.auroraRose,
                opacity: 0.72,
                radiusX: 0.70,
                radiusY: 0.60,
                offsetX: 0.06 * sin(t * 0.11),
                offsetY: 0.05 * cos(t * 0.11),
                anchorX: 0.28,
                anchorY: 0.22
            )
            .blendMode(.screen)

            // Blob 2 — indigo, medium drift
            AuroraBlob(
                colour: NNColour.auroraIndigo,
                opacity: 0.65,
                radiusX: 0.65,
                radiusY: 0.55,
                offsetX: 0.05 * cos(t * 0.17),
                offsetY: 0.06 * sin(t * 0.17),
                anchorX: 0.74,
                anchorY: 0.26
            )
            .blendMode(.screen)

            // Blob 3 — ember, faster pulse
            AuroraBlob(
                colour: NNColour.auroraEmber,
                opacity: 0.30,
                radiusX: 0.50,
                radiusY: 0.42,
                offsetX: 0.04 * sin(t * 0.23 + 1.2),
                offsetY: 0.04 * cos(t * 0.23),
                anchorX: 0.85,
                anchorY: 0.10
            )
            .blendMode(.screen)

            // Grain overlay
            GrainOverlay()
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Aurora Blob
// ─────────────────────────────────────────

struct AuroraBlob: View {
    let colour: Color
    let opacity: Double
    let radiusX: Double   // fraction of screen width
    let radiusY: Double   // fraction of screen height
    let offsetX: Double   // animated offset, fraction of width
    let offsetY: Double   // animated offset, fraction of height
    let anchorX: Double   // base position, fraction of width
    let anchorY: Double   // base position, fraction of height

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w * (anchorX + offsetX)
            let cy = h * (anchorY + offsetY)
            let rx = w * radiusX
            let ry = h * radiusY

            EllipticalGradient(
                gradient: Gradient(stops: [
                    .init(color: colour.opacity(opacity), location: 0),
                    .init(color: colour.opacity(opacity * 0.5), location: 0.4),
                    .init(color: colour.opacity(0), location: 1),
                ]),
                center: UnitPoint(
                    x: cx / w,
                    y: cy / h
                ),
                startRadiusFraction: 0,
                endRadiusFraction: 1
            )
            .frame(width: rx, height: ry)
            .position(x: cx, y: cy)
        }
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────
// MARK: - Glow Orb
// ─────────────────────────────────────────
// Pure stacked .shadow() on a clear Circle.
// ZERO fill, ZERO hard edge — just luminescence.

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

    // Generate once, cache statically
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
