import SwiftUI

// ─────────────────────────────────────────
// MARK: - Aurora Background
// ─────────────────────────────────────────
// Three animated radial blobs composited via Metal (.drawingGroup()).
// Do NOT use Canvas on this view in WKWebView contexts — native only.

struct AuroraView: View {
    var hueShift: Double = 0
    var scaleBoost: Double = 1.0

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            AuroraCanvas(time: t, hueShift: hueShift, scaleBoost: scaleBoost)
        }
        .drawingGroup() // Metal-accelerated composite
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────
// MARK: - Aurora Canvas
// ─────────────────────────────────────────

struct AuroraCanvas: View {
    let time: Double
    var hueShift: Double = 0
    var scaleBoost: Double = 1.0

    var body: some View {
        Canvas { ctx, size in
            // Blob 1 — rose, slow 0.11 speed
            drawBlob(
                ctx: ctx, size: size,
                cx: 0.28 + 0.06 * sin(time * 0.11),
                cy: 0.18 + 0.05 * cos(time * 0.11),
                rx: size.width  * 0.72,
                ry: size.height * 0.58,
                colour: NNColour.auroraRose,
                opacity: 0.58
            )

            // Blob 2 — indigo, medium 0.17 speed
            drawBlob(
                ctx: ctx, size: size,
                cx: 0.76 + 0.05 * cos(time * 0.17),
                cy: 0.24 + 0.06 * sin(time * 0.17),
                rx: size.width  * 0.62,
                ry: size.height * 0.52,
                colour: NNColour.auroraIndigo,
                opacity: 0.48
            )

            // Blob 3 — ember, fast pulse 0.23 speed
            drawBlob(
                ctx: ctx, size: size,
                cx: 0.88 + 0.04 * sin(time * 0.23),
                cy: 0.08 + 0.04 * cos(time * 0.23),
                rx: size.width  * 0.55,
                ry: size.height * 0.44,
                colour: NNColour.auroraEmber,
                opacity: 0.20
            )
        }
        .hueRotation(.degrees(hueShift))
        .scaleEffect(scaleBoost)
        .background(NNColour.void)
    }

    private func drawBlob(
        ctx: GraphicsContext,
        size: CGSize,
        cx: Double, cy: Double,
        rx: Double, ry: Double,
        colour: Color,
        opacity: Double
    ) {
        let centre = CGPoint(x: size.width * cx, y: size.height * cy)
        let rect   = CGRect(
            x: centre.x - rx / 2, y: centre.y - ry / 2,
            width: rx, height: ry
        )

        // Radial gradient ellipse
        var gc = ctx
        gc.opacity = opacity
        let gradient = Gradient(colors: [colour, colour.opacity(0)])
        gc.drawLayer { innerCtx in
            let path = Path(ellipseIn: rect)
            innerCtx.fill(
                path,
                with: .radialGradient(
                    gradient,
                    center: centre,
                    startRadius: 0,
                    endRadius: max(rx, ry) / 2
                )
            )
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Glow Orb
// ─────────────────────────────────────────
// Pure stacked .shadow() on a clear Circle — ZERO fill, ZERO hard edge.

struct GlowOrb: View {
    var colour: Color = NNColour.orbRose
    var size: CGFloat = 14
    var animate: Bool = true

    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: size, height: size)
            .shadow(color: colour.opacity(0.68), radius: 5)
            .shadow(color: colour.opacity(0.42), radius: 14)
            .shadow(color: colour.opacity(0.20), radius: 34)
            .shadow(color: colour.opacity(0.09), radius: 68)
            .shadow(color: colour.opacity(0.04), radius: 120)
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
                    image: Image(uiImage: grainImage()),
                    scale: 0.5
                )
            )
            .opacity(0.038)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }

    private func grainImage() -> UIImage {
        let size = CGSize(width: 128, height: 128)
        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()!
        for _ in 0..<8000 {
            let x = CGFloat.random(in: 0..<size.width)
            let y = CGFloat.random(in: 0..<size.height)
            let alpha = CGFloat.random(in: 0.1...0.6)
            ctx.setFillColor(UIColor(white: 1, alpha: alpha).cgColor)
            ctx.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}

// ─────────────────────────────────────────
// MARK: - Hairline separator
// ─────────────────────────────────────────

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(NNColour.hairline)
            .frame(height: 1)
    }
}
