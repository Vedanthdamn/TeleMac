import AppKit
import SwiftUI
import Combine

class TeleprompterWindowController: NSObject {
    private var panel: NSPanel
    private var hostingView: NSHostingView<TeleprompterView>?
    let viewModel: TeleprompterViewModel

    init(viewModel: TeleprompterViewModel) {
        self.viewModel = viewModel

        panel = NSPanel(
            contentRect: .zero,
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

        super.init()

        let teleprompterView = TeleprompterView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: teleprompterView)
        hosting.frame = CGRect(x: 0, y: 0, width: 340, height: 80)
        panel.contentView = hosting
        self.hostingView = hosting

        positionAtNotch()
    }

    func positionAtNotch() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 80
        let x = (screenFrame.width / 2) - (panelWidth / 2)
        let y = screenFrame.height - panelHeight
        panel.setFrame(CGRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
    }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    @MainActor
    func updateScript(_ text: String) {
        viewModel.scriptText = text
    }
}
