import SwiftUI
import Combine

/// Recording state machine
enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case rewriting
    case error(String)
    
    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.recording, .recording): return true
        case (.transcribing, .transcribing): return true
        case (.rewriting, .rewriting): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Central app state - observable by all views
@MainActor
class AppState: ObservableObject {
    // MARK: - Published State
    
    @Published var recordingState: RecordingState = .idle
    @Published var audioLevel: Float = 0
    @Published var lastTranscription: String?
    @Published var showOnboarding = false
    @Published var widgetVisible = true
    @Published var isInitialized = false
    
    // MARK: - Services
    
    let permissionsManager = PermissionsManager()
    let hotkeyMonitor = HotkeyMonitor()
    let audioRecorder = AudioRecorder()
    let speechRecognizer = SpeechRecognizer()
    let textInjector = TextInjector()
    let geminiService = GeminiService()
    let transcriptionHistory = TranscriptionHistory()
    
    // MARK: - Rewrite State
    
    private var rewriteTask: Task<Void, Never>?
    private var originalTranscription: String?
    
    // MARK: - Private
    
    private var recordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        // Start preloading model immediately
        startModelPreload()
    }
    
    private func setupBindings() {
        // Sync audio level from recorder to state
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
        
        // Setup hotkey callbacks
        hotkeyMonitor.onFnKeyDown = { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }
        
        hotkeyMonitor.onFnKeyUp = { [weak self] in
            Task { @MainActor in
                // Only stop if we're actually recording (not if user just tapped Fn)
                if self?.recordingState == .recording {
                    self?.stopRecording()
                }
            }
        }
    }
    
    /// Start preloading the WhisperKit model in the background
    func startModelPreload() {
        Task {
            print("[AppState] Starting model preload...")
            await speechRecognizer.initialize(model: .base)
        }
    }
    
    /// Initialize services (call after permissions granted)
    func initializeServices() async {
        guard !isInitialized else { return }
        
        print("[AppState] Initializing services...")
        
        // Wait for model to finish loading if still in progress
        if !speechRecognizer.isReady && !speechRecognizer.isInitializing {
            await speechRecognizer.initialize(model: .base)
        }
        
        // Start hotkey monitoring
        hotkeyMonitor.startMonitoring()
        print("[AppState] Hotkey monitoring started")
        
        isInitialized = true
    }
    
    // MARK: - Recording Control
    
    /// Start recording from microphone
    func startRecording() {
        guard recordingState == .idle else {
            print("[AppState] Cannot start recording - not idle")
            return
        }
        
        // Check permissions
        guard permissionsManager.microphoneStatus == .granted else {
            recordingState = .error("Microphone access required")
            return
        }
        
        // Check if model is ready
        // Check if model is ready
        guard speechRecognizer.isReady else {
            if speechRecognizer.isInitializing {
                recordingState = .error("Model still loading... \(speechRecognizer.initializationProgress)")
            } else if let error = speechRecognizer.initializationError {
                recordingState = .error("Model error. Check app window.")
                // Automatically open onboarding/app window if there's an error
                DispatchQueue.main.async {
                    self.showOnboarding = true
                    // Activate app to bring window to front
                    NSApp.activate(ignoringOtherApps: true)
                    // NotificationCenter default used in AppDelegate to show window
                    NotificationCenter.default.post(name: NSNotification.Name("ShowOnboarding"), object: nil)
                }
            } else {
                recordingState = .error("Initializing model...")
                Task {
                    await speechRecognizer.initialize()
                }
            }
            return
        }
        
        // Start recording asynchronously
        Task {
            do {
                // Optimistically update UI to feel responsive
                recordingState = .recording
                print("[AppState] Starting recording engine (async)...")
                
                recordingURL = try await audioRecorder.startRecording()
                print("[AppState] Recording engine started successfully")
            } catch {
                print("[AppState] Failed to start recording: \(error)")
                recordingState = .error("Failed to start")
            }
        }
    }
    
    /// Stop recording and begin transcription
    func stopRecording() {
        guard recordingState == .recording else { return }
        
        guard let url = audioRecorder.stopRecording() else {
            print("[AppState] No recording URL")
            recordingState = .idle
            return
        }
        
        print("[AppState] Recording stopped, starting transcription...")
        recordingState = .transcribing
        
        Task {
            await transcribeAndInject(audioURL: url)
        }
    }
    
    /// Cancel recording without transcribing
    func cancelRecording() {
        guard recordingState == .recording else { return }
        
        if let url = audioRecorder.stopRecording() {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingState = .idle
        print("[AppState] Recording cancelled")
    }
    
    /// Stop recording and begin transcription with AI rewrite
    func stopRecordingWithRewrite() {
        guard recordingState == .recording else { return }
        
        guard let url = audioRecorder.stopRecording() else {
            print("[AppState] No recording URL")
            recordingState = .idle
            return
        }
        
        print("[AppState] Recording stopped, starting transcription with rewrite...")
        recordingState = .transcribing
        
        rewriteTask = Task {
            await transcribeRewriteAndInject(audioURL: url)
        }
    }
    
    /// Cancel rewriting (keeps raw transcription)
    func cancelRewriting() {
        guard recordingState == .rewriting else { return }
        
        rewriteTask?.cancel()
        rewriteTask = nil
        recordingState = .idle
        print("[AppState] Rewriting cancelled, keeping raw transcription")
    }
    
    /// Dismiss error state
    func dismissError() {
        if case .error = recordingState {
            recordingState = .idle
        }
    }
    
    // MARK: - Transcription
    
    private func transcribeAndInject(audioURL: URL) async {
        do {
            // Transcribe
            let text = try await speechRecognizer.transcribe(audioURL: audioURL)
            
            // Store transcription
            lastTranscription = text
            
            // Inject text at cursor
            textInjector.injectText(text)
            
            // Save to history
            transcriptionHistory.addTranscription(text)
            
            // Return to idle
            recordingState = .idle
            
            print("[AppState] Transcription complete and injected: \(text.prefix(50))...")
            
        } catch {
            print("[AppState] Transcription failed: \(error)")
            recordingState = .error("Transcription failed")
        }
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    /// Transcribe, paste raw text, then rewrite with Gemini and replace
    private func transcribeRewriteAndInject(audioURL: URL) async {
        do {
            // Step 1: Transcribe
            let rawText = try await speechRecognizer.transcribe(audioURL: audioURL)
            
            guard !Task.isCancelled else { return }
            
            // Store original transcription
            originalTranscription = rawText
            lastTranscription = rawText
            
            // Step 2: Paste raw transcription immediately
            textInjector.injectText(rawText)
            print("[AppState] Raw transcription injected: \(rawText.prefix(50))...")
            
            // Step 3: Switch to rewriting state
            recordingState = .rewriting
            
            guard !Task.isCancelled else {
                recordingState = .idle
                return
            }
            
            // Step 4: Get custom prompt from settings
            let customPrompt = UserDefaults.standard.string(forKey: "aiRewritePrompt")
            
            // Step 5: Call Gemini to rewrite
            let rewrittenText = try await geminiService.rewriteText(rawText, systemPrompt: customPrompt)
            
            guard !Task.isCancelled else {
                recordingState = .idle
                return
            }
            
            // Step 6: Select all and replace with rewritten text
            textInjector.selectAllAndReplace(with: rewrittenText)
            
            // Save to history with both raw and rewritten
            transcriptionHistory.addTranscriptionWithRewrite(raw: rawText, rewritten: rewrittenText)
            
            lastTranscription = rewrittenText
            recordingState = .idle
            
            print("[AppState] Rewrite complete and injected: \(rewrittenText.prefix(50))...")
            
        } catch is CancellationError {
            print("[AppState] Rewrite was cancelled")
            recordingState = .idle
        } catch let geminiError as GeminiService.GeminiError {
            print("[AppState] Rewrite failed: \(geminiError)")
            
            // Special handling for no API key error
            if case .noAPIKey = geminiError {
                recordingState = .error("API key required for AI rewrite")
                // Open settings to AI Rewrite tab with error state
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenAIRewriteSettings"), object: nil)
                }
            } else {
                recordingState = .error(geminiError.localizedDescription ?? "Rewrite failed")
            }
            
            // Auto-dismiss error after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                if case .error = self?.recordingState {
                    self?.recordingState = .idle
                }
            }
        } catch {
            print("[AppState] Rewrite failed: \(error)")
            recordingState = .error("Rewrite failed")
            // Auto-dismiss error after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                if case .error = self?.recordingState {
                    self?.recordingState = .idle
                }
            }
        }
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: audioURL)
        rewriteTask = nil
    }
    
    // MARK: - Clipboard
    
    /// Copy last transcription to clipboard
    func copyLastTranscription() {
        guard let text = lastTranscription else { return }
        textInjector.copyToClipboard(text)
        print("[AppState] Copied to clipboard: \(text.prefix(50))...")
    }
    
    // MARK: - Cleanup
    
    func shutdown() {
        hotkeyMonitor.stopMonitoring()
        if recordingState == .recording {
            _ = audioRecorder.stopRecording()
        }
    }
}
