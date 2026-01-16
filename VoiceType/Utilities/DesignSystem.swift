import SwiftUI

/// Centralized Design System for VoiceType
enum DesignSystem {
    enum Color {
        // Core Colors
        static let accent = SwiftUI.Color.accentColor // This will use the asset we just updated
        static let background = SwiftUI.Color(nsColor: .windowBackgroundColor)
        static let secondaryBackground = SwiftUI.Color(nsColor: .controlBackgroundColor)
        
        // Semantic Colors
        static let recording = SwiftUI.Color.red
        static let rewriting = SwiftUI.Color.orange // Match accent for rewriting
        static let transcribing = SwiftUI.Color.purple
        static let text = SwiftUI.Color.primary
        static let secondaryText = SwiftUI.Color.secondary
        
        // Widget Colors (High Contrast)
        static let widgetBackground = SwiftUI.Color.black
        static let widgetForeground = SwiftUI.Color.white
    }
    
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let widgetHeight: CGFloat = 44
        static let widgetSmallHeight: CGFloat = 22
    }
    
    enum Icon {
        static let recording = "waveform"
        static let stop = "stop.fill"
        static let rewrite = "sparkles"
        static let settings = "gearshape.fill"
        static let history = "clock.arrow.circlepath"
    }
}
