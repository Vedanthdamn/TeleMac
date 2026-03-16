import SwiftUI

struct TeleprompterView: View {
    @ObservedObject var viewModel: TeleprompterViewModel

    var body: some View {
        TeleprompterOverlayView(viewModel: viewModel)
            .frame(width: 340, height: 80)
            .ignoresSafeArea()
    }
}

struct TeleprompterOverlayView: View {
    @ObservedObject var viewModel: TeleprompterViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.88))

            GeometryReader { geometry in
                Text(viewModel.scriptText.isEmpty ? " " : viewModel.scriptText)
                    .font(.system(size: viewModel.fontSize, design: .monospaced))
                    .foregroundColor(viewModel.textColor)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: geometry.size.width - 16, alignment: .leading)
                    .padding(.horizontal, 8)
                    .offset(y: -viewModel.scrollOffset + 24)
            }
            .clipped()
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.15),
                        .init(color: .black, location: 0.85),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            if viewModel.isPaused {
                Text("⏸")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
                    .padding(.trailing, 6)
            }
        }
        .frame(width: 340, height: 80)
        .onHover { hovering in
            viewModel.isPaused = hovering
        }
    }
}
