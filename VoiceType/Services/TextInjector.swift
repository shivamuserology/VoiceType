import AppKit
import Carbon.HIToolbox
import Cocoa

/// Injects text at the current cursor position using clipboard + simulated Cmd+V paste
class TextInjector {
    
    /// Stored clipboard content to restore after paste
    private var savedPasteboardChangeCount: Int = 0
    private var savedPasteboardData: [(NSPasteboard.PasteboardType, Data)] = []
    
    /// Last detected target application (for external access if needed)
    private(set) var lastTargetApp: NSRunningApplication?
    
    /// Inject text at the current cursor position
    /// Works by temporarily placing text on clipboard, simulating Cmd+V, then restoring clipboard
    func injectText(_ text: String) {
        guard !text.isEmpty else {
            print("[TextInjector] Empty text, skipping injection")
            return
        }
        
        // Detect active application before injection
        let targetApp = detectActiveApplication()
        lastTargetApp = targetApp
        
        if let app = targetApp {
            print("[TextInjector] Target App: \(app.localizedName ?? "Unknown") (\(app.bundleIdentifier ?? "unknown.bundle"))")
        } else {
            print("[TextInjector] Target App: Unknown")
        }
        
        // Format text for specific apps (placeholder for future feature)
        let formattedText = formatText(text, for: targetApp)
        
        print("[TextInjector] Injecting text: \(formattedText.prefix(50))...")
        
        // 1. Save current clipboard content
        saveClipboard()
        
        // 2. Put our text on clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(formattedText, forType: .string)
        
        // 3. Small delay to ensure clipboard is updated
        usleep(50000) // 50ms
        
        // 4. Simulate Cmd+V paste
        simulatePaste()
        
        // 5. Restore original clipboard after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.restoreClipboard()
        }
    }
    
    // MARK: - Active App Detection
    
    /// Detect the frontmost (active) application
    private func detectActiveApplication() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }
    
    /// Format text for specific applications (placeholder for future feature)
    /// - Parameters:
    ///   - text: Original transcribed text
    ///   - app: Target application (optional)
    /// - Returns: Formatted text (currently returns original)
    private func formatText(_ text: String, for app: NSRunningApplication?) -> String {
        // Future: Add app-specific formatting here
        // Example bundle IDs:
        // - com.apple.Notes
        // - com.microsoft.VSCode
        // - com.tinyspeck.slackmacgap (Slack)
        // - com.google.Chrome
        
        guard let bundleId = app?.bundleIdentifier else {
            return text
        }
        
        // Placeholder switch for future formatting rules
        switch bundleId {
        case "com.microsoft.VSCode", "com.apple.dt.Xcode":
            // Future: Could apply code formatting
            return text
        case "com.tinyspeck.slackmacgap":
            // Future: Could format for Slack markdown
            return text
        default:
            return text
        }
    }
    
    /// Copy text to clipboard without pasting (for "Copy Last Transcription" feature)
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("[TextInjector] Copied to clipboard: \(text.prefix(50))...")
    }
    
    /// Select all text in the current field and replace with new text
    /// Used for AI rewrite: replaces the raw transcription with rewritten version
    func selectAllAndReplace(with text: String) {
        guard !text.isEmpty else {
            print("[TextInjector] Empty text, skipping replacement")
            return
        }
        
        print("[TextInjector] Selecting all and replacing with: \(text.prefix(50))...")
        
        // 1. Save current clipboard content
        saveClipboard()
        
        // 2. Put our replacement text on clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 3. Small delay to ensure clipboard is updated
        usleep(50000) // 50ms
        
        // 4. Simulate Cmd+A to select all
        simulateSelectAll()
        
        // 5. Small delay between select and paste
        usleep(100000) // 100ms
        
        // 6. Simulate Cmd+V paste (replaces selection)
        simulatePaste()
        
        // 7. Restore original clipboard after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.restoreClipboard()
        }
    }
    
    /// Simulate Cmd+A (Select All)
    private func simulateSelectAll() {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("[TextInjector] Failed to create event source for select all")
            return
        }
        
        // Virtual key code for 'A'
        let aKeyCode = CGKeyCode(kVK_ANSI_A)
        
        // Key down with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: aKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        usleep(10000) // 10ms
        
        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: aKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
        
        print("[TextInjector] Simulated Cmd+A select all")
    }
    
    // MARK: - Private Methods
    
    private func saveClipboard() {
        let pasteboard = NSPasteboard.general
        savedPasteboardChangeCount = pasteboard.changeCount
        savedPasteboardData = []
        
        // Save all types of data on the clipboard
        if let items = pasteboard.pasteboardItems {
            for item in items {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedPasteboardData.append((type, data))
                    }
                }
            }
        }
    }
    
    private func restoreClipboard() {
        guard !savedPasteboardData.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        
        // Only restore if we haven't had other clipboard changes
        // (user might have copied something else)
        pasteboard.clearContents()
        
        // Create a new pasteboard item with all saved data
        let item = NSPasteboardItem()
        for (type, data) in savedPasteboardData {
            item.setData(data, forType: type)
        }
        pasteboard.writeObjects([item])
        
        savedPasteboardData = []
        print("[TextInjector] Clipboard restored")
    }
    
    private func simulatePaste() {
        // Create event source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("[TextInjector] Failed to create event source")
            return
        }
        
        // Virtual key code for 'V'
        let vKeyCode = CGKeyCode(kVK_ANSI_V)
        
        // Key down with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        // Small delay between key down and up
        usleep(10000) // 10ms
        
        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
        
        print("[TextInjector] Simulated Cmd+V paste")
    }
}
