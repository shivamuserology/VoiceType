import AppKit
import ApplicationServices

/// Helper to inspect Accessibility focus state
class FocusManager {
    static let shared = FocusManager()
    
    private init() {}
    
    /// Check if the currently focused element in the frontmost app is a text input
    /// Returns: true if the user is likely editing text, false if just viewing/browsing
    func isCurrentFocusEditable() -> Bool {
        // 1. Get frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        
        // 2. Create AX Element for the app
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        // 3. Get the focused element
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        guard result == .success, let element = focusedElement else {
            // Cannot determine focus -> assume not editable
            return false
        }
        
        let axElement = element as! AXUIElement
        return isElementEditable(axElement)
    }
    
    /// Get detailed context about the current focus
    /// - Returns: Tuple of (WindowContext, TextFieldValue)
    func getFocusedElementContext() -> (appAndDocumentContext: String, nearbyTextContent: String) {
        // 1. Get frontmost app
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return ("Unknown", "") }
        
        // 2. Create AX Element for the app
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        // 3. Get Window Context (Aggregated from multiple attributes)
        var windowContextParts: [String] = []
        var focusedWindow: AnyObject?
        
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success {
            let windowElement = focusedWindow as! AXUIElement
            
            // A. Title
            var title: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title) == .success, let str = title as? String {
                windowContextParts.append("Title: \(str)")
            }
            
            // B. Document/File/URL
            var document: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, "AXDocument" as CFString, &document) == .success, let str = document as? String {
                // Documents can be long file paths, just take the basename if it looks like one
                windowContextParts.append("Document: \(str)")
            } else if AXUIElementCopyAttributeValue(windowElement, "AXFilename" as CFString, &document) == .success, let str = document as? String {
                windowContextParts.append("File: \(str)")
            }
            
            // C. Browser URL (Special check for browsers)
            // Note: This is hit or miss without deeper tree walking, but worth a quick probe
            var url: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, "AXURL" as CFString, &url) == .success, let str = url as? String {
                windowContextParts.append("URL: \(str)")
            }
            
            // D. Description
            var desc: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXDescriptionAttribute as CFString, &desc) == .success, let str = desc as? String, !str.isEmpty {
                windowContextParts.append("Description: \(str)")
            }
        }
        
        let windowContext = windowContextParts.isEmpty ? (frontApp.localizedName ?? "Unknown") : windowContextParts.joined(separator: " | ")
        
        // 4. Get Text Content (from Focused UI Element)
        var textContent = ""
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        
        if result == .success, let element = focusedElement {
            let axElement = element as! AXUIElement
            
            // Try Value Attribute (standard for text fields)
            var value: AnyObject?
            if AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &value) == .success {
                if let str = value as? String {
                    // Limit to last 500 chars to avoid overwhelming context
                    textContent = String(str.suffix(500))
                }
            }
            
            // Fallback: Selected Text (if partial selection)
            if textContent.isEmpty {
                var selected: AnyObject?
                if AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selected) == .success {
                     if let str = selected as? String {
                         textContent = String(str.suffix(500))
                     }
                }
            }
        }
        
        return (windowContext, textContent)
    }
    
    /// Determine if an AXElement is considered editable
    private func isElementEditable(_ element: AXUIElement) -> Bool {
        // A. Check Role
        var role: AnyObject?
        let _ = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        
        if let roleStr = role as? String {
            // Common text editing roles
            if roleStr == kAXTextAreaRole || roleStr == kAXTextFieldRole {
                return true
            }
            // Web areas require deeper checking (some might be contentEditable)
            // But usually "Browsing" implies the WebArea itself has focus, not an input inside it.
            // If the user clicks a specific input in a web page, the focus SHOULD be that input (with a text role or content properties).
        }
        
        // B. Check Value Attribute (some editors don't report Role correctly but have a value)
        var value: AnyObject?
        let valResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        // If we can get a String value and set it, it's definitely editable.
        // But "isAttributeSettable" is the real test.
        var isSettable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &isSettable)
        
        if settableResult == .success && isSettable.boolValue {
            return true
        }
        
        return false
    }
}
