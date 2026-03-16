import SwiftUI

// Custom shape with concave top corners matching notch curve
struct NotchShape: Shape {
    var cornerRadius: CGFloat = 20
    var notchCurve: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start from top-left, after the concave curve
        path.move(to: CGPoint(x: 0, y: notchCurve))

        // Concave curve top-left corner (curves inward)
        path.addQuadCurve(
            to: CGPoint(x: notchCurve, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        // Top edge
        path.addLine(to: CGPoint(x: rect.width - notchCurve, y: 0))

        // Concave curve top-right corner (curves inward)
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: notchCurve),
            control: CGPoint(x: rect.width, y: 0)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))

        // Rounded bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))

        // Rounded bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )

        path.closeSubpath()
        return path
    }
}

struct TeleprompterView: View {
    @ObservedObject var viewModel: TeleprompterViewModel

    var body: some View {
        ZStack {
            // Black background in notch shape
            NotchShape(cornerRadius: 20, notchCurve: 18)
                .fill(Color.black)

            VStack(spacing: 0) {
                // Top covers the notch — pure black, no text
                Color.clear
                    .frame(height: 37)

                // Text lives below the notch area
                ZStack {
                    GeometryReader { geo in
                        Text(viewModel.scriptText.isEmpty
                             ? "Your script appears here"
                             : viewModel.scriptText)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.92))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: geo.size.width - 16)
                            .padding(.horizontal, 8)
                            .offset(y: 4 - viewModel.scrollOffset)
                    }
                    .clipped()

                    // Green glow wave at bottom
                    VStack {
                        Spacer()
                        ZStack {
                            Ellipse()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 260, height: 20)
                                .blur(radius: 10)
                            Ellipse()
                                .fill(Color.green.opacity(0.4))
                                .frame(width: 140, height: 10)
                                .blur(radius: 5)
                        }
                        .padding(.bottom, 2)
                    }
                }
                .frame(height: 53)
            }

            // Frozen badge
            if viewModel.isPaused {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 7))
                            Text("FROZEN")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .padding(5)
                    }
                }
            }
        }
        .frame(width: 300, height: 90)
        .clipShape(NotchShape(cornerRadius: 20, notchCurve: 18))
        .onHover { hovering in
            viewModel.isPaused = hovering
        }
    }
}
