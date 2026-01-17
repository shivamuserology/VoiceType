import AppKit
import Combine

/// Monitors global keyboard events for Fn key press/release
class HotkeyMonitor: ObservableObject {
    @Published var isFnKeyPressed = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isMonitoring = false
    
    /// Callback when Fn key is pressed down
    var onFnKeyDown: (() -> Void)?
    
    /// Callback when Fn key is released (Bool indicates if Shift was also pressed)
    var onFnKeyUp: ((Bool) -> Void)?
    
    /// Start monitoring for global Fn key events
    /// Requires Accessibility permission to work system-wide
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Global monitor for when app is not focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        
        // Local monitor for when app windows are focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        
        isMonitoring = true
        print("[HotkeyMonitor] Started monitoring for Fn key")
    }
    
    /// Stop monitoring for keyboard events
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isMonitoring = false
        print("[HotkeyMonitor] Stopped monitoring")
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Check if Fn key is in the modifier flags
        // Note: .function flag is set when Fn key is held
        let fnPressed = event.modifierFlags.contains(.function)
        
        // Only trigger callbacks on state change
        if fnPressed && !isFnKeyPressed {
            // Fn key just pressed
            DispatchQueue.main.async { [weak self] in
                self?.isFnKeyPressed = true
                self?.onFnKeyDown?()
            }
        } else if !fnPressed && isFnKeyPressed {
            // Fn key just released
            let shiftPressed = event.modifierFlags.contains(.shift)
            
            DispatchQueue.main.async { [weak self] in
                self?.isFnKeyPressed = false
                self?.onFnKeyUp?(shiftPressed)
            }
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
