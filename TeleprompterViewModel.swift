import Foundation
import SwiftUI
import Combine
import CoreVideo

@MainActor
final class TeleprompterViewModel: ObservableObject {
    @Published var scriptText: String = ""
    @Published var scrollOffset: CGFloat = 0
    @Published var isScrolling: Bool = false
    @Published var scrollSpeed: Double = 40.0
    @Published var isPaused: Bool = false
    @Published var isVoiceControlEnabled: Bool = true
    @Published var fontSize: CGFloat = 22
    @Published var textColor: Color = .white

    private var displayLink: CVDisplayLink?
    private var lastHostTime: UInt64 = 0

    func startScrolling() {
        guard !isScrolling else { return }
        isScrolling = true
        lastHostTime = 0

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let link else { return }

        let callback: CVDisplayLinkOutputCallback = { _, inNow, _, _, _, userInfo in
            let vm = Unmanaged<TeleprompterViewModel>.fromOpaque(userInfo!).takeUnretainedValue()
            let currentHostTime = inNow.pointee.hostTime

            DispatchQueue.main.async {
                let last = vm.lastHostTime
                guard last != 0 else {
                    vm.lastHostTime = currentHostTime
                    return
                }
                let elapsedNanos = currentHostTime - last
                let dt = Double(elapsedNanos) / 1_000_000_000.0
                vm.lastHostTime = currentHostTime
                vm.advanceScroll(dt: dt)
            }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(link, callback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(link)
        self.displayLink = link
    }

    func stopScrolling() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
        lastHostTime = 0
        isScrolling = false
    }

    func resetScroll() {
        scrollOffset = 0
        stopScrolling()
    }

    func advanceScroll(dt: Double = 0.016) {
        guard !isPaused else { return }
        scrollOffset += scrollSpeed * dt
    }

    func voiceDetected() {
        guard isVoiceControlEnabled && !isPaused else { return }
        startScrolling()
    }

    func silenceDetected() {
        guard isVoiceControlEnabled else { return }
        stopScrolling()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopScrolling()
        } else {
            startScrolling()
        }
    }

    deinit {
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
    }
}
