import SwiftUI

/// Settings/Preferences window view
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Binding var selectedTab: Int
    var showAPIKeyError: Bool = false
    
    init(appState: AppState, selectedTab: Binding<Int> = .constant(0), showAPIKeyError: Bool = false) {
        self.appState = appState
        self._selectedTab = selectedTab
        self.showAPIKeyError = showAPIKeyError
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            TranscriptionSettingsView()
                .tabItem {
                    Label("Transcription", systemImage: "text.bubble")
                }
                .tag(1)
            
            AIRewriteSettingsView(showAPIKeyError: showAPIKeyError)
                .tabItem {
                    Label("AI Rewrite", systemImage: "sparkles")
                }
                .tag(2)
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 520, height: 450)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showWidgetOnStartup") private var showWidgetOnStartup = true
    @AppStorage("playSoundOnComplete") private var playSoundOnComplete = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch VoiceType at login", isOn: $launchAtLogin)
                Toggle("Show floating widget on startup", isOn: $showWidgetOnStartup)
                Toggle("Play sound when transcription completes", isOn: $playSoundOnComplete)
            } header: {
                Text("Startup & Behavior")
            }
            
            Section {
                HStack {
                    Text("Hotkey")
                    Spacer()
                    Text("Hold Fn key")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                }
            } header: {
                Text("Keyboard Shortcut")
            }
            
            Section {
                PermissionStatusRow(
                    title: "Microphone",
                    granted: appState.permissionsManager.microphoneStatus == .granted,
                    onFix: { appState.permissionsManager.openMicrophoneSettings() }
                )
                
                PermissionStatusRow(
                    title: "Accessibility",
                    granted: appState.permissionsManager.accessibilityStatus == .granted,
                    onFix: { appState.permissionsManager.openAccessibilitySettings() }
                )
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct PermissionStatusRow: View {
    let title: String
    let granted: Bool
    let onFix: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if granted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Fix", action: onFix)
            }
        }
    }
}

// MARK: - Transcription Settings

struct TranscriptionSettingsView: View {
    @AppStorage("whisperModel") private var whisperModel = "base.en"
    @AppStorage("autoCapitalize") private var autoCapitalize = true
    @AppStorage("autoPunctuation") private var autoPunctuation = true
    
    var body: some View {
        Form {
            Section {
                Picker("Model", selection: $whisperModel) {
                    Text("Tiny (fastest)").tag("tiny.en")
                    Text("Base (balanced)").tag("base.en")
                    Text("Small (better accuracy)").tag("small.en")
                    Text("Medium (best accuracy)").tag("medium.en")
                }
                .pickerStyle(.menu)
                
                Text("Larger models are more accurate but slower. Base is recommended for most users.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Whisper Model")
            }
            
            Section {
                Toggle("Auto-capitalize sentences", isOn: $autoCapitalize)
                Toggle("Auto-punctuate", isOn: $autoPunctuation)
            } header: {
                Text("Text Formatting")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - AI Rewrite Settings

struct AIRewriteSettingsView: View {
    @AppStorage("aiRewriteEnabled") private var aiRewriteEnabled = true
    @AppStorage("aiRewritePrompt") private var customPrompt = ""
    @State private var apiKeyInput: String = ""
    @State private var hasAPIKey: Bool = false
    @State private var showAPIKey: Bool = false
    @State private var displayedPrompt: String = ""
    
    var showAPIKeyError: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable AI Rewrite (wand button)", isOn: $aiRewriteEnabled)
                
                Text("When enabled, the wand button appears during recording to paste and rewrite your transcription with AI.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Feature")
            }
            
            Section {
                HStack {
                    if showAPIKey {
                        TextField("Gemini API Key", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Gemini API Key", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button("Save") {
                        if GeminiService.saveAPIKey(apiKeyInput) {
                            hasAPIKey = true
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)
                }
                
                HStack {
                    Text("Status:")
                    if hasAPIKey {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key Saved")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(showAPIKeyError ? "API Key Required!" : "No API Key")
                                .foregroundColor(showAPIKeyError ? .red : .orange)
                                .fontWeight(showAPIKeyError ? .semibold : .regular)
                        }
                    }
                }
                
                Text("Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                HStack {
                    Text("Gemini API Key")
                    if showAPIKeyError && !hasAPIKey {
                        Text("⚠️ Required")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                TextEditor(text: $displayedPrompt)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onChange(of: displayedPrompt) { oldValue, newValue in
                        // Only save to customPrompt if it differs from default
                        if newValue != GeminiService.defaultSystemPrompt {
                            customPrompt = newValue
                        } else {
                            customPrompt = ""
                        }
                    }
                
                Button("Reset to Default") {
                    displayedPrompt = GeminiService.defaultSystemPrompt
                    customPrompt = ""
                }
            } header: {
                Text("System Prompt")
            } footer: {
                Text("Customize how AI rewrites your transcriptions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            hasAPIKey = GeminiService.hasAPIKey()
            if hasAPIKey {
                apiKeyInput = "••••••••••••••••"
            }
            // Show the custom prompt if set, otherwise show default
            displayedPrompt = customPrompt.isEmpty ? GeminiService.defaultSystemPrompt : customPrompt
        }
    }
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "waveform")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("VoiceType")
                    .font(.title2.bold())
                Text("Version 1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Text("Voice-to-text dictation for macOS")
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 60)
            
            VStack(spacing: 8) {
                Text("Powered by WhisperKit")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("100% on-device • Private • No data leaves your Mac")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

// Note: Preview disabled due to MainActor isolation requirements
// Use the app directly to test SettingsView

