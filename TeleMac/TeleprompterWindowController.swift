import AppKit
import SwiftUI
import Combine

class TeleprompterWindowController: NSObject {
    private var panel: NSPanel
    private var hostingView: NSHostingView<TeleprompterView>?
    let viewModel: TeleprompterViewModel

    private let panelWidth: CGFloat = 300
    private let panelHeight: CGFloat = 90

    init(viewModel: TeleprompterViewModel) {
        self.viewModel = viewModel

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 90),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.level = .screenSaver
        panel.sharingType = .none
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = false
        panel.hasShadow = false

        super.init()

        let teleprompterView = TeleprompterView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: teleprompterView)
        hosting.frame = CGRect(x: 0, y: 0, width: 300, height: 90)
        panel.contentView = hosting
        self.hostingView = hosting

        positionAtNotch()
    }

    func positionAtNotch() {
        guard let screen = NSScreen.main else { return }
        let screenWidth = screen.frame.width
        let screenHeight = screen.frame.height

        let x = (screenWidth / 2) - (panelWidth / 2)
        let y = screenHeight - panelHeight

        panel.setFrame(
            NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            display: true
        )
    }

    func show() {
        positionAtNotch()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    @MainActor
    func updateScript(_ text: String) {
        viewModel.scriptText = text
        viewModel.resetScroll()
    }
}
