import SwiftUI

struct TeleprompterView: View {
    @ObservedObject var viewModel: TeleprompterViewModel

    var body: some View {
        ZStack {
            Color.black

            VStack(spacing: 0) {
                Color.black
                    .frame(height: 37)

                ZStack {
                    GeometryReader { geo in
                        Text(viewModel.scriptText.isEmpty
                             ? "Your script appears here"
                             : viewModel.scriptText)
                            .font(.system(size: viewModel.fontSize, weight: .medium, design: .monospaced))
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
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onHover { hovering in
            viewModel.isPaused = hovering
        }
    }
}
