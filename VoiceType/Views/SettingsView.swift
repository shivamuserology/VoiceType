import SwiftUI

/// Main Settings view with Professional SaaS UI (Wispr Flow style)
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: Int
    var showAPIKeyError: Bool = false
    
    init(appState: AppState, initialTab: Int = 0, showAPIKeyError: Bool = false) {
        self.appState = appState
        self._selectedTab = State(initialValue: initialTab)
        self.showAPIKeyError = showAPIKeyError
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Sidebar
            VStack(spacing: 0) {
                // App Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("VoiceType")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 24)
                
                // Navigation Items
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 4) {
                        Group {
                            SidebarItem(title: "General", icon: "gearshape", isSelected: selectedTab == 0) { selectedTab = 0 }
                            SidebarItem(title: "Transcription", icon: "text.bubble", isSelected: selectedTab == 1) { selectedTab = 1 }
                            SidebarItem(title: "AI Rewrite", icon: "sparkles", isSelected: selectedTab == 2, showBadge: showAPIKeyError) { selectedTab = 2 }
                            SidebarItem(title: "History", icon: "clock", isSelected: selectedTab == 3) { selectedTab = 3 }
                        }
                        
                        Divider()
                            .background(Color.primary.opacity(0.1))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        
                        SidebarItem(title: "About", icon: "info.circle", isSelected: selectedTab == 4) { selectedTab = 4 }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .frame(width: 240)
            .background(Color(NSColor.windowBackgroundColor)) // Sidebar matches window
            .overlay(
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 1),
                alignment: .trailing
            )
            
            // MARK: - Content Area
            ZStack {
                // Main Background
                Color(NSColor.controlBackgroundColor) // Slightly distinct from sidebar
                    .opacity(0.5)
                    .ignoresSafeArea()
                
                if selectedTab == 3 {
                    // History View (Full layout, custom scrolling)
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(title: pageTitle, subtitle: "Manage your past recordings")
                        HistoryView(history: appState.transcriptionHistory)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    // Other views (Standard scrolled document)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            HeaderView(
                                title: pageTitle,
                                subtitle: pageSubtitle
                            )
                            
                            VStack(spacing: 24) {
                                switch selectedTab {
                                case 0: GeneralSettingsView(appState: appState)
                                case 1: TranscriptionSettingsView()
                                case 2: AIRewriteSettingsView(showAPIKeyError: showAPIKeyError)
                                case 4: AboutView()
                                default: GeneralSettingsView(appState: appState)
                                }
                            }
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 650)
    }
    
    private var pageTitle: String {
        switch selectedTab {
        case 0: return "General"
        case 1: return "Transcription"
        case 2: return "AI Rewrite"
        case 3: return "History"
        case 4: return "About"
        default: return "Settings"
        }
    }
    
    private var pageSubtitle: String {
        switch selectedTab {
        case 0: return "Configure startup behavior and app preferences."
        case 1: return "Manage speech recognition models and output."
        case 2: return "Supercharge your dictation with Google Gemini."
        case 3: return "View and manage your past transcriptions."
        case 4: return "Version information and credits."
        default: return ""
        }
    }
}

// MARK: - Header Component
struct HeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var showBadge: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : (isHovered ? .primary : .secondary))
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : (isHovered ? .primary : .primary.opacity(0.8)))
                
                Spacer()
                
                if showBadge {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(isSelected ? .white : .red)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Custom Section Components

struct SettingsSection<Content: View>: View {
    let title: String?
    let content: Content
    
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let t = title {
                Text(t.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .padding(.leading, 4)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .background(Color(NSColor.textBackgroundColor)) // Pure white in light mode
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(14)
        .overlay(
            Divider().padding(.leading, 14), alignment: .bottom
        )
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showWidgetOnStartup") private var showWidgetOnStartup = true
    @AppStorage("playSoundOnComplete") private var playSoundOnComplete = true
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection("Startup") {
                SettingsRow {
                    ToggleRow(title: "Launch at Login", 
                              subtitle: "Automatically start VoiceType when you log in", 
                              isOn: $launchAtLogin)
                }
                SettingsRow {
                    ToggleRow(title: "Show Floating Widget", 
                              subtitle: "Display the recording widget on startup", 
                              isOn: $showWidgetOnStartup)
                }
            }
            
            SettingsSection("Behavior") {
                SettingsRow {
                    ToggleRow(title: "Completion Sound", 
                              subtitle: "Play a subtle sound when transcription finishes", 
                              isOn: $playSoundOnComplete)
                }
            }
            
            SettingsSection("Application") {
                SettingsRow {
                    HStack {
                        Text("Version")
                            .font(.system(size: 13))
                        Spacer()
                        Text("1.1.0")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                    }
                }
                SettingsRow {
                    HStack {
                        Text("Check for Updates")
                            .font(.system(size: 13))
                        Spacer()
                        Button("Check Now") { }
                        .font(.system(size: 12))
                    }
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
    }
}

// MARK: - Transcription Settings
struct TranscriptionSettingsView: View {
    @AppStorage("selectedModel") private var selectedModel = "distil-large-v3"
    @AppStorage("insertAtCursor") private var insertAtCursor = true
    
    var body: some View {
        VStack(spacing: 24) {
            SettingsSection("Model Configuration") {
                SettingsRow {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Whisper Model")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Picker("", selection: $selectedModel) {
                                Text("Distil Large v3 (Best)").tag("distil-large-v3")
                                Text("Base (Faster)").tag("base")
                                Text("Tiny (Fastest)").tag("tiny")
                            }
                            .frame(width: 160)
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text("Large model provides best accuracy but uses ~1GB RAM.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            SettingsSection("Output Handling") {
                SettingsRow {
                    ToggleRow(title: "Past at Cursor", 
                              subtitle: "Directly insert transcribed text where you are typing", 
                              isOn: $insertAtCursor)
                }
            }
        }
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
        VStack(spacing: 24) {
            // Feature Highlight Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Rewrite Engine")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Enhance your speech using Google Gemini")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $aiRewriteEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
            .padding(16)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            
            // API Key Section
            SettingsSection("Configuration") {
                SettingsRow {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Gemini API Key")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            if hasAPIKey {
                                Label("Connected", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Missing Key", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            if showAPIKey {
                                TextField("Ex: AIzaSy...", text: $apiKeyInput)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            } else {
                                SecureField("Ex: AIzaSy...", text: $apiKeyInput)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(8)
                                    .background(Color.primary.opacity(0.03))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: { showAPIKey.toggle() }) {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                if GeminiService.saveAPIKey(apiKeyInput) { hasAPIKey = true }
                            }) {
                                Text("Save")
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(apiKeyInput.isEmpty)
                            .opacity(apiKeyInput.isEmpty ? 0.6 : 1)
                        }
                        
                        Link("Get a free API Key →", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // System Prompt Editor
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("SYSTEM PROMPT")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    Spacer()
                    Button("Reset Default") {
                        displayedPrompt = GeminiService.defaultSystemPrompt
                        customPrompt = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    TextEditor(text: $displayedPrompt)
                        .font(.system(size: 13, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .frame(minHeight: 200)
                        .background(Color(NSColor.textBackgroundColor))
                }
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .onChange(of: displayedPrompt) { oldValue, newValue in
                    if newValue != GeminiService.defaultSystemPrompt {
                        customPrompt = newValue
                    } else {
                        customPrompt = ""
                    }
                }
                
                Text("Variables: {userProfession}, {platformName}, {windowContext}, {textFieldValue}")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .onAppear {
            hasAPIKey = GeminiService.hasAPIKey()
            if hasAPIKey { apiKeyInput = "••••••••••••••••" }
            displayedPrompt = customPrompt.isEmpty ? GeminiService.defaultSystemPrompt : customPrompt
        }
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer().frame(height: 10)
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 10)
                
                VStack(spacing: 4) {
                    Text("VoiceType")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Voice to Text, Perfected.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/shivam1610sethi/VoiceType")!) {
                    Text("Visit Website")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 140, height: 36)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Text("Version 1.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

