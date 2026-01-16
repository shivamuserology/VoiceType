import AppKit
import SwiftUI
import Combine

/// Main application delegate - coordinates all app components
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var appState: AppState!
    private var floatingPanel: FloatingPanel?
    private var menuBarController: MenuBarController!
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - App Lifecycle
    
    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await self.setupApplication()
        }
    }
    
    private func setupApplication() async {
        print("[AppDelegate] Application launched")
        
        // Make this a menu bar app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize state
        appState = AppState()
        
        // Setup menu bar
        setupMenuBar()
        
        // Check permissions and show onboarding if needed
        appState.permissionsManager.checkAllPermissions()
        
        if appState.permissionsManager.allPermissionsGranted {
            initializeApp()
        } else {
            showOnboarding()
        }
        
        // Listen for requests to show onboarding (e.g. from error states)
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowOnboarding"), object: nil, queue: .main) { [weak self] _ in
            self?.showOnboarding()
        }
        
        // Listen for requests to open AI Rewrite settings (e.g. when API key missing)
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenAIRewriteSettings"), object: nil, queue: .main) { [weak self] _ in
            self?.showSettings(tab: 2, showAPIKeyError: true)
        }
    }
    
    nonisolated func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            print("[AppDelegate] Application terminating")
            appState?.shutdown()
        }
    }
    
    nonisolated func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Task { @MainActor in
            // Show settings when clicking dock icon (if visible) with no windows open
            if !flag {
                self.showSettings()
            }
        }
        return true
    }
    
    // MARK: - Setup
    
    private func setupMenuBar() {
        menuBarController = MenuBarController()
        menuBarController.setup(appState: appState)
        
        menuBarController.onCopyLastTranscription = { [weak self] in
            self?.appState.copyLastTranscription()
        }
        
        menuBarController.onOpenSettings = { [weak self] in
            self?.showSettings()
        }
        
        menuBarController.onToggleWidget = { [weak self] visible in
            self?.setWidgetVisible(visible)
        }
    }
    
    private func initializeApp() {
        print("[AppDelegate] Initializing app...")
        
        // Initialize services (WhisperKit, hotkey monitoring)
        Task {
            await appState.initializeServices()
        }
        
        // Show floating widget
        showFloatingWidget()
        
        // Observe recording state for menu bar icon
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.menuBarController.updateIcon(isRecording: state == .recording)
            }
            .store(in: &cancellables)
        
        // Observe transcription changes for menu refresh
        appState.$lastTranscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.menuBarController.refreshMenu()
            }
            .store(in: &cancellables)
        
        print("[AppDelegate] App initialized")
    }
    
    // MARK: - Windows
    
    private func showOnboarding() {
        print("[AppDelegate] Showing onboarding")
        
        let view = OnboardingView(
            permissionsManager: appState.permissionsManager,
            speechRecognizer: appState.speechRecognizer,
            onComplete: { [weak self] in
                self?.completeOnboarding()
            }
        )
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to VoiceType"
        window.contentView = NSHostingView(rootView: view)
        
        // Position at bottom center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.origin.x + (screenFrame.width - windowFrame.width) / 2
            let y = screenFrame.origin.y + 80 // 80pt from bottom
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
        
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        onboardingWindow = window
        
        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func completeOnboarding() {
        print("[AppDelegate] Onboarding complete")
        onboardingWindow?.close()
        onboardingWindow = nil
        initializeApp()
    }
    
    private func showFloatingWidget() {
        print("[AppDelegate] Showing floating widget")
        
        let widgetView = FloatingWidgetView(appState: appState)
        
        floatingPanel = FloatingPanel(content: widgetView)
        floatingPanel?.showPanel()
        appState.widgetVisible = true
        
        // Note: We don't need to observe state changes here
        // SwiftUI's @ObservedObject in FloatingWidgetView handles updates automatically
    }
    
    private func setWidgetVisible(_ visible: Bool) {
        if visible {
            floatingPanel?.showPanel()
        } else {
            floatingPanel?.hidePanel()
        }
        appState.widgetVisible = visible
    }
    
    private func showSettings(tab: Int = 0, showAPIKeyError: Bool = false) {
        print("[AppDelegate] Showing settings (tab: \(tab), showAPIKeyError: \(showAPIKeyError))")
        
        // Always recreate window if we need to show a specific tab or error
        if settingsWindow != nil && (tab != 0 || showAPIKeyError) {
            settingsWindow?.close()
            settingsWindow = nil
        }
        
        if settingsWindow == nil {
            let view = SettingsView(
                appState: appState, 
                initialTab: tab,
                showAPIKeyError: showAPIKeyError
            )
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 720),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "VoiceType Settings"
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
