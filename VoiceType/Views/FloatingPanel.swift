import AppKit
import SwiftUI

/// Custom NSPanel that floats above all windows without stealing focus
/// Used for the floating dictation widget
class FloatingPanel: NSPanel {
    
    private var hostingView: NSHostingView<AnyView>?
    
    /// Initialize the floating panel with SwiftUI content
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 30),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        configure()
        
        // Wrap content in AnyView and create hosting view
        let wrappedContent = AnyView(
            content
                .frame(minWidth: 80, maxWidth: 400, minHeight: 22, maxHeight: 30)
                .fixedSize()
        )
        
        let hosting = NSHostingView(rootView: wrappedContent)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a container view to avoid constraint issues
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 30))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = .clear
        containerView.addSubview(hosting)
        
        // Pin hosting view to container
        NSLayoutConstraint.activate([
            hosting.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            hosting.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        self.contentView = containerView
        self.hostingView = hosting
        
        positionAtBottomCenter()
    }
    
    private func configure() {
        // Window behavior - float above everything
        self.level = .floating
        self.isFloatingPanel = true
        
        // Don't hide when app loses focus
        self.hidesOnDeactivate = false
        
        // Animation behavior
        self.animationBehavior = .utilityWindow
        
        // Appear on all spaces/desktops and fullscreen apps
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]
        
        // Transparent background for custom shape
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Don't show in window menu
        self.isExcludedFromWindowsMenu = true
    }
    
    /// Position the panel at the bottom center of the main screen
    func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = 300
        
        let x = screenFrame.midX - (windowWidth / 2)
        let y = screenFrame.minY + 20 // 20px from bottom (was 50)
        
        self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: 30), display: true)
    }
    
    // MARK: - Prevent Focus Stealing
    
    /// Never become the key window
    override var canBecomeKey: Bool { false }
    
    /// Never become the main window
    override var canBecomeMain: Bool { false }
    
    // MARK: - Show/Hide
    
    /// Show the panel without activating the app
    func showPanel() {
        self.orderFrontRegardless()
    }
    
    /// Hide the panel
    func hidePanel() {
        self.orderOut(nil)
    }
}
