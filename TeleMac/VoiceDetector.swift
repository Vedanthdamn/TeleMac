import AVFoundation
import AppKit
import Combine

final class VoiceDetector: NSObject, ObservableObject {
    @Published var isSpeaking: Bool = false

    var onVoiceDetected: (() -> Void)?
    var onSilenceDetected: (() -> Void)?

    private var audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private let voiceThreshold: Float = 0.015

    func requestPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            startMonitoring()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startMonitoring()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Microphone Access Required"
                alert.informativeText = "Please enable microphone access in System Settings → Privacy & Security → Microphone"
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Cancel")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                }
            }
        @unknown default:
            break
        }
    }

    func startMonitoring() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = self.computeRMS(buffer: buffer)
            DispatchQueue.main.async {
                if rms > self.voiceThreshold {
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = nil
                    if !self.isSpeaking {
                        self.isSpeaking = true
                        self.onVoiceDetected?()
                    }
                } else if self.isSpeaking && self.silenceTimer == nil {
                    self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                        self.isSpeaking = false
                        self.onSilenceDetected?()
                        self.silenceTimer = nil
                    }
                }
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed: \(error)")
        }
    }

    func stopMonitoring() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        silenceTimer?.invalidate()
        silenceTimer = nil
        isSpeaking = false
    }

    private func computeRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        return sqrt(sum / Float(frameLength))
    }
}
