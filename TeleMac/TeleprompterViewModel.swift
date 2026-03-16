import Foundation
import SwiftUI
import Combine

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

    private var displayTimer: Timer?

    func startScrolling() {
        guard displayTimer == nil else { return }
        isScrolling = true
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.advanceScroll()
            }
        }
    }

    func stopScrolling() {
        displayTimer?.invalidate()
        displayTimer = nil
        isScrolling = false
    }

    func resetScroll() {
        scrollOffset = 0
        stopScrolling()
        isPaused = false
    }

    func advanceScroll() {
        // Hard stop — if paused, stop timer completely
        guard !isPaused else {
            stopScrolling()
            return
        }
        scrollOffset += CGFloat(scrollSpeed * 0.05)
    }

    func voiceDetected() {
        // If manually frozen, ignore voice completely
        guard isVoiceControlEnabled && !isPaused else { return }
        startScrolling()
    }

    func silenceDetected() {
        guard isVoiceControlEnabled && !isPaused else { return }
        stopScrolling()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            // Freeze everything immediately
            stopScrolling()
        }
        // Don't auto-resume — wait for voice when unpaused
    }
}
