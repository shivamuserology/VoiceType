
import SwiftUI

/// Main Settings view with Sidebar navigation (Wispr Flow style)
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
        HSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App Header
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text("VoiceType")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                
                // Navigation Items
                ScrollView {
                    VStack(spacing: 4) {
                        SidebarItem(title: "General", icon: "gear", isSelected: selectedTab == 0) { selectedTab = 0 }
                        SidebarItem(title: "Transcription", icon: "text.bubble", isSelected: selectedTab == 1) { selectedTab = 1 }
                        SidebarItem(title: "AI Rewrite", icon: "sparkles", isSelected: selectedTab == 2, showBadge: showAPIKeyError) { selectedTab = 2 }
                        SidebarItem(title: "History", icon: "clock.arrow.circlepath", isSelected: selectedTab == 3) { selectedTab = 3 }
                        
                        Divider().padding(.vertical, 8)
                        
                        SidebarItem(title: "About", icon: "info.circle", isSelected: selectedTab == 4) { selectedTab = 4 }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(minWidth: 200, maxWidth: 220)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content Area
            VStack(spacing: 0) {
                switch selectedTab {
                case 0: GeneralSettingsView(appState: appState)
                case 1: TranscriptionSettingsView()
                case 2: AIRewriteSettingsView(showAPIKeyError: showAPIKeyError)
                case 3: HistoryView(history: appState.transcriptionHistory)
                case 4: AboutView()
                default: GeneralSettingsView(appState: appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            // Apply a subtle transition when switching tabs to make it feel less "abrupt" but still fast
            .animation(.easeInOut(duration: 0.1), value: selectedTab)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var showBadge: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                
                Spacer()
                
                if showBadge {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Keep existing subviews
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
                Toggle("Play sound on completion", isOn: $playSoundOnComplete)
            } header: {
                Text("Startup & Behavior")
            }
            
            Section {
                Button("Check for Updates...") {
                    // Placeholder
                }
            } header: {
                Text("Updates")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Transcription Settings
struct TranscriptionSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "distil-large-v3"
    @AppStorage("useSmallModel") private var useSmallModel = false
    @AppStorage("insertAtCursor") private var insertAtCursor = true
    
    var body: some View {
        Form {
            Section {
                Picker("Whisper Model", selection: $selectedModel) {
                    Text("Distil Large v3 (Best Quality)").tag("distil-large-v3")
                    Text("Base (Faster)").tag("base")
                    Text("Tiny (Fastest)").tag("tiny")
                }
                
                Text("Distil Large v3 provides the best accuracy but requires more memory (1GB+).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("AI Model")
            }
            
            Section {
                Toggle("Insert text at cursor position", isOn: $insertAtCursor)
            } header: {
                Text("Output")
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
            displayedPrompt = customPrompt.isEmpty ? GeminiService.defaultSystemPrompt : customPrompt
        }
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                Text("VoiceType")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.2")
                    .foregroundColor(.secondary)
            }
            
            Text("A minimal, powerful dictation app for macOS.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)
            
            Link("Visit Website", destination: URL(string: "https://github.com/shivam1610sethi/VoiceType")!)
            
            Spacer()
            
            Text("Created by Shivam Sethi")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
