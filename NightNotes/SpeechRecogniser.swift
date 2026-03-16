import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecogniser: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""

    private let recogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func startRecording(onPermissionDenied: @escaping (Bool) -> Void) {
        // Check speech permission
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.requestMicAndStart(onPermissionDenied: onPermissionDenied)
                default:
                    onPermissionDenied(true)
                }
            }
        }
    }

    private func requestMicAndStart(onPermissionDenied: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.beginRecording()
                } else {
                    onPermissionDenied(true)
                }
            }
        }
    }

    private func beginRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest, let recogniser, recogniser.isAvailable else { return }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = recogniser.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.cleanupAudio()
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine start error: \(error)")
            cleanupAudio()
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        cleanupAudio()
    }

    private func cleanupAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
