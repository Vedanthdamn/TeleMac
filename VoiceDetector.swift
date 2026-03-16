import AVFoundation
import AppKit

final class VoiceDetector: NSObject, ObservableObject {
    @Published var isSpeaking: Bool = false

    var onVoiceDetected: (() -> Void)?
    var onSilenceDetected: (() -> Void)?

    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    private let voiceThreshold: Float = 0.015
    private var lastSpeakingState: Bool = false

    func requestPermissionAndStart() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.startMonitoring()
            }
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
                    if !self.lastSpeakingState {
                        self.lastSpeakingState = true
                        self.isSpeaking = true
                        self.onVoiceDetected?()
                    }
                } else if self.lastSpeakingState {
                    guard self.silenceTimer == nil else { return }
                    self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
                        guard let self else { return }
                        self.lastSpeakingState = false
                        self.isSpeaking = false
                        self.silenceTimer = nil
                        self.onSilenceDetected?()
                    }
                }
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("VoiceDetector: Failed to start audio engine: \(error)")
        }
    }

    func stopMonitoring() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        silenceTimer?.invalidate()
        silenceTimer = nil
        lastSpeakingState = false
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }

    func computeRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        return sqrt(sum / Float(frameLength))
    }
}
