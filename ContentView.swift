import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject var viewModel = TeleprompterViewModel()
    @StateObject var voiceDetector = VoiceDetector()
    @State var windowController: TeleprompterWindowController?

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

                Button(action: { viewModel.resetScroll() }) {
                    Text("Reset")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .systemGray).opacity(0.3))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

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
                    .fill(windowController != nil && viewModel.isScrolling ? Color.green : Color.secondary)
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

    private var statusText: String {
        if windowController == nil {
            return "Teleprompter inactive"
        } else if viewModel.isScrolling {
            return voiceDetector.isSpeaking ? "Scrolling — voice detected" : "Scrolling"
        } else if viewModel.isPaused {
            return "Paused"
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
    }

    func stopTeleprompter() {
        windowController?.hide()
        voiceDetector.stopMonitoring()
        viewModel.stopScrolling()
    }
}
