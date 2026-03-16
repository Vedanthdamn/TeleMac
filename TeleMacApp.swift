import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var teleprompterWindowController: TeleprompterWindowController?
    var viewModel: TeleprompterViewModel?

    private var keyEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupKeyboardShortcuts()
    }

    func applicationWillTerminate(_ notification: Notification) {
        teardownKeyboardShortcuts()
    }

    func setupKeyboardShortcuts() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let vm = self.viewModel else { return event }

            switch event.keyCode {
            case 49: // Space bar
                Task { @MainActor in vm.togglePause() }
                return nil

            case 123: // Left arrow — decrease speed
                Task { @MainActor in
                    vm.scrollSpeed = max(10, vm.scrollSpeed - 5)
                }
                return nil

            case 124: // Right arrow — increase speed
                Task { @MainActor in
                    vm.scrollSpeed = min(120, vm.scrollSpeed + 5)
                }
                return nil

            case 15: // R key
                Task { @MainActor in vm.resetScroll() }
                return nil

            case 53: // Escape
                Task { @MainActor in
                    self.teleprompterWindowController?.hide()
                    vm.stopScrolling()
                }
                return nil

            default:
                return event
            }
        }
    }

    func teardownKeyboardShortcuts() {
        if let monitor = keyEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyEventMonitor = nil
        }
    }
}

@main
struct TeleMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "settings") {
            ContentView(isPromptingActive: .constant(false))
                .onAppear {
                    // No-op: viewModel is wired from ContentView.startTeleprompter()
                }
        }
    }
}
