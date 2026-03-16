import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject var viewModel = TeleprompterViewModel()
    @StateObject var voiceDetector = VoiceDetector()
    @State var windowController: TeleprompterWindowController?
    @State private var globalMonitor: Any?
    @State private var localMonitor: Any?

    init(isPromptingActive: Binding<Bool> = .constant(false)) {
        _viewModel = StateObject(wrappedValue: TeleprompterViewModel())
        _voiceDetector = StateObject(wrappedValue: VoiceDetector())
        _windowController = State(initialValue: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("TeleMac")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.bottom, 4)

            // Section 1 — Script Editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Script")
                    .font(.headline)

                ZStack(alignment: .topLeading) {
                    if viewModel.scriptText.isEmpty {
                        Text("Paste or type your script here...")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.scriptText)
                        .font(.system(size: 14, design: .monospaced))
                        .frame(height: 180)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(6)
            }

            // Section 2 — Controls
            HStack(spacing: 10) {
                Button(action: startTeleprompter) {
                    Text("Start Teleprompter")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: stopTeleprompter) {
                    Text("Stop")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .systemGray).opacity(0.3))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.scrollOffset = 0
                    viewModel.stopScrolling()
                    viewModel.isPaused = false
                    viewModel.scriptText = ""
                    windowController?.hide()
                    windowController = nil
                    removeKeyboardShortcuts()
                }) {
                    Text("Reset")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .systemGray).opacity(0.3))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Manual freeze button
                Button(action: { viewModel.isPaused.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        Text(viewModel.isPaused ? "Resume" : "Freeze")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(viewModel.isPaused ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Keyboard hints
            Text("💡 Space = freeze/resume  |  ↑ scroll back  |  ↓ scroll forward")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, -8)

            // Section 3 — Settings
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Speed: \(Int(viewModel.scrollSpeed)) pt/s")
                            .font(.subheadline)
                        Slider(value: $viewModel.scrollSpeed, in: 10...120, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font Size: \(Int(viewModel.fontSize))pt")
                            .font(.subheadline)
                        Slider(value: $viewModel.fontSize, in: 14...42, step: 1)
                    }

                    Toggle("Voice-Activated Scroll", isOn: $viewModel.isVoiceControlEnabled)
                        .font(.subheadline)
                }
                .padding(4)
            } label: {
                Text("Settings")
                    .font(.headline)
            }

            // Section 4 — Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 580)
    }

    private var statusColor: Color {
        if viewModel.isPaused { return .orange }
        if viewModel.isScrolling { return .green }
        return .secondary
    }

    private var statusText: String {
        if windowController == nil {
            return "Teleprompter inactive"
        } else if viewModel.isPaused {
            return "⏸ Frozen — press Space to resume"
        } else if viewModel.isScrolling {
            return voiceDetector.isSpeaking ? "Scrolling — voice detected" : "Scrolling"
        } else {
            return "Teleprompter active — waiting for voice"
        }
    }

    func startTeleprompter() {
        if windowController == nil {
            windowController = TeleprompterWindowController(viewModel: viewModel)
        }
        (NSApp.delegate as? AppDelegate)?.viewModel = viewModel
        (NSApp.delegate as? AppDelegate)?.teleprompterWindowController = windowController
        windowController?.updateScript(viewModel.scriptText)
        windowController?.show()
        voiceDetector.onVoiceDetected = { viewModel.voiceDetected() }
        voiceDetector.onSilenceDetected = { viewModel.silenceDetected() }
        voiceDetector.requestPermissionAndStart()
        setupKeyboardShortcuts()
    }

    func stopTeleprompter() {
        windowController?.hide()
        voiceDetector.stopMonitoring()
        viewModel.stopScrolling()
        removeKeyboardShortcuts()
    }

    func setupKeyboardShortcuts() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space — freeze/unfreeze
                DispatchQueue.main.async { self.viewModel.isPaused.toggle() }
                return nil
            case 126: // Up arrow — scroll back
                DispatchQueue.main.async {
                    self.viewModel.scrollOffset = max(0, self.viewModel.scrollOffset - 20)
                }
                return nil
            case 125: // Down arrow — scroll forward
                DispatchQueue.main.async {
                    self.viewModel.scrollOffset += 20
                }
                return nil
            default:
                return event
            }
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49: // Space
                DispatchQueue.main.async { self.viewModel.isPaused.toggle() }
            case 126: // Up arrow
                DispatchQueue.main.async {
                    self.viewModel.scrollOffset = max(0, self.viewModel.scrollOffset - 20)
                }
            case 125: // Down arrow
                DispatchQueue.main.async {
                    self.viewModel.scrollOffset += 20
                }
            default:
                break
            }
        }
    }

    func removeKeyboardShortcuts() {
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
            globalMonitor = nil
        }
    }
}
