import AVFoundation
import Combine

/// Records audio from the microphone using AVAudioEngine
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    enum AudioRecorderError: Error, LocalizedError {
        case engineStartFailed
        case fileCreationFailed
        case noInputAvailable
        case formatConversionFailed
        
        var errorDescription: String? {
            switch self {
            case .engineStartFailed:
                return "Failed to start audio engine"
            case .fileCreationFailed:
                return "Failed to create audio file"
            case .noInputAvailable:
                return "No audio input available"
            case .formatConversionFailed:
                return "Audio format conversion failed"
            }
        }
    }
    
    /// Start recording audio from the default input device
    /// - Returns: URL of the temporary audio file being recorded
    func startRecording() async throws -> URL {
        // Run audio engine setup on background thread to prevent UI freeze
        return try await Task.detached(priority: .userInitiated) {
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            
            // Get the native format of the input node's output
            let nativeFormat = inputNode.outputFormat(forBus: 0)
            
            // Check if we have a valid format
            guard nativeFormat.sampleRate > 0 && nativeFormat.channelCount > 0 else {
                throw AudioRecorderError.noInputAvailable
            }
            
            print("[AudioRecorder] Native input format: \(nativeFormat.sampleRate) Hz, \(nativeFormat.channelCount) ch")
            
            // Create 16kHz mono format for WhisperKit output file
            guard let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 16000,
                channels: 1,
                interleaved: false
            ) else {
                throw AudioRecorderError.formatConversionFailed
            }
            
            // Create converter from native format to 16kHz mono
            guard let converter = AVAudioConverter(from: nativeFormat, to: outputFormat) else {
                throw AudioRecorderError.formatConversionFailed
            }
            
            // Create temp file for recording (16kHz mono for WhisperKit)
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "voicetype_\(UUID().uuidString).wav"
            let url = tempDir.appendingPathComponent(fileName)
            
            // Create audio file with 16kHz mono format
            guard let audioFile = try? AVAudioFile(forWriting: url, settings: outputFormat.settings) else {
                throw AudioRecorderError.fileCreationFailed
            }
            
            // Return to main actor to set properties and start engine
            return try await MainActor.run {
                self.audioFile = audioFile
                
                // Install tap using native format (must match input node's output)
                inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
                    guard let self = self else { return }
                    
                    // Calculate audio level for visualization
                    let level = self.calculateAudioLevel(buffer: buffer)
                    DispatchQueue.main.async {
                        self.audioLevel = level
                    }
                    
                    // Convert buffer to 16kHz mono
                    let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * 16000.0 / nativeFormat.sampleRate)
                    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else { return }
                    
                    var error: NSError?
                    var inputBufferConsumed = false
                    
                    converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
                        if inputBufferConsumed {
                            outStatus.pointee = .noDataNow
                            return nil
                        }
                        inputBufferConsumed = true
                        outStatus.pointee = .haveData
                        return buffer
                    }
                    
                    if error == nil && convertedBuffer.frameLength > 0 {
                        do {
                            try self.audioFile?.write(from: convertedBuffer)
                        } catch {
                            print("[AudioRecorder] Error writing converted audio: \(error)")
                        }
                    }
                }
                
                do {
                    try engine.start()
                } catch {
                    inputNode.removeTap(onBus: 0)
                    print("[AudioRecorder] Engine start error: \(error)")
                    throw AudioRecorderError.engineStartFailed
                }
                
                self.audioEngine = engine
                self.recordingURL = url
                self.isRecording = true
                
                print("[AudioRecorder] Started recording to: \(url.path)")
                return url
            }
        }.value
    }
    
    /// Stop recording and return the URL of the recorded audio file
    /// - Returns: URL of the recorded audio file, or nil if not recording
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        // Remove tap from input node
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // Stop engine
        audioEngine?.stop()
        
        audioEngine = nil
        audioFile = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.audioLevel = 0
        }
        
        print("[AudioRecorder] Stopped recording")
        return recordingURL
    }
    
    /// Calculate the average audio level from a buffer (0.0 to 1.0)
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return 0 }
        
        var sum: Float = 0
        for i in 0..<frames {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frames)
        // Normalize to roughly 0-1 range
        return min(average * 10, 1.0)
    }
    
    deinit {
        _ = stopRecording()
    }
}
