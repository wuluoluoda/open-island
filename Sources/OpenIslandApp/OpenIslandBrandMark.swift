import SwiftUI

struct OpenIslandBrandMark: View {
    enum Style {
        case duotone
        case template
    }

    let size: CGFloat
    var tint: Color = .mint
    var isAnimating: Bool = false
    var style: Style = .duotone

    var body: some View {
        GeometryReader { proxy in
            let length = min(proxy.size.width, proxy.size.height)
            let originX = (proxy.size.width - length) / 2
            let originY = (proxy.size.height - length) / 2
            let rect = CGRect(x: originX, y: originY, width: length, height: length)
            let glowOpacity = isAnimating ? 0.7 : 0.42

            ZStack {
                if style == .duotone {
                    Circle()
                        .fill(tint.opacity(isAnimating ? 0.9 : 0.7))
                        .frame(width: length * 0.15, height: length * 0.15)
                        .position(x: rect.midX, y: rect.minY + length * 0.84)
                        .shadow(color: tint.opacity(glowOpacity), radius: length * 0.12)
                }

                FoldPane(points: [
                    CGPoint(x: 0.10, y: 0.62),
                    CGPoint(x: 0.45, y: 0.41),
                    CGPoint(x: 0.54, y: 0.57),
                    CGPoint(x: 0.17, y: 0.81),
                ])
                .fill(fillGradient(baseOpacity: 0.62))
                .overlay(FoldPane(points: [
                    CGPoint(x: 0.10, y: 0.62),
                    CGPoint(x: 0.45, y: 0.41),
                    CGPoint(x: 0.54, y: 0.57),
                    CGPoint(x: 0.17, y: 0.81),
                ]).stroke(edgeColor, lineWidth: max(1, length * 0.055)))

                FoldPane(points: [
                    CGPoint(x: 0.42, y: 0.16),
                    CGPoint(x: 0.70, y: 0.34),
                    CGPoint(x: 0.70, y: 0.82),
                    CGPoint(x: 0.42, y: 0.64),
                ])
                .fill(fillGradient(baseOpacity: 0.76))
                .overlay(FoldPane(points: [
                    CGPoint(x: 0.42, y: 0.16),
                    CGPoint(x: 0.70, y: 0.34),
                    CGPoint(x: 0.70, y: 0.82),
                    CGPoint(x: 0.42, y: 0.64),
                ]).stroke(edgeColor, lineWidth: max(1, length * 0.06)))

                FoldPane(points: [
                    CGPoint(x: 0.28, y: 0.36),
                    CGPoint(x: 0.55, y: 0.53),
                    CGPoint(x: 0.48, y: 0.68),
                    CGPoint(x: 0.28, y: 0.55),
                ])
                .fill(fillGradient(baseOpacity: 0.7))
                .overlay(FoldPane(points: [
                    CGPoint(x: 0.28, y: 0.36),
                    CGPoint(x: 0.55, y: 0.53),
                    CGPoint(x: 0.48, y: 0.68),
                    CGPoint(x: 0.28, y: 0.55),
                ]).stroke(edgeColor, lineWidth: max(1, length * 0.05)))

                FoldPane(points: [
                    CGPoint(x: 0.67, y: 0.49),
                    CGPoint(x: 0.89, y: 0.38),
                    CGPoint(x: 0.89, y: 0.64),
                    CGPoint(x: 0.67, y: 0.80),
                ])
                .fill(fillGradient(baseOpacity: 0.58))
                .overlay(FoldPane(points: [
                    CGPoint(x: 0.67, y: 0.49),
                    CGPoint(x: 0.89, y: 0.38),
                    CGPoint(x: 0.89, y: 0.64),
                    CGPoint(x: 0.67, y: 0.80),
                ]).stroke(edgeColor, lineWidth: max(1, length * 0.05)))
            }
            .shadow(color: edgeColor.opacity(glowOpacity), radius: length * 0.11)
        }
        .frame(width: size, height: size)
        .drawingGroup(opaque: false, colorMode: .extendedLinear)
    }

    private var edgeColor: Color {
        switch style {
        case .duotone:
            return tint.opacity(isAnimating ? 1.0 : 0.86)
        case .template:
            return Color.primary
        }
    }

    private func fillGradient(baseOpacity: Double) -> LinearGradient {
        switch style {
        case .duotone:
            return LinearGradient(
                colors: [
                    tint.opacity(baseOpacity * (isAnimating ? 1.1 : 0.86)),
                    Color(red: 0.16, green: 0.18, blue: 0.25).opacity(baseOpacity * 0.72),
                    tint.opacity(baseOpacity * 0.35),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .template:
            return LinearGradient(
                colors: [
                    Color.primary.opacity(0.96),
                    Color.primary.opacity(0.62),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct FoldPane: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }

        path.move(to: point(first, in: rect))
        for point in points.dropFirst() {
            path.addLine(to: self.point(point, in: rect))
        }
        path.closeSubpath()
        return path
    }

    private func point(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + point.x * rect.width,
            y: rect.minY + point.y * rect.height
        )
    }
}
