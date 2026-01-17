import SwiftUI

/// The floating pill widget that shows dictation state
struct FloatingWidgetView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ZStack {
            switch appState.recordingState {
            case .idle:
                IdlePillView(onTap: appState.startRecording)
                
            case .recording:
                RecordingPillView(
                    audioLevel: appState.audioLevel,
                    onCancel: appState.cancelRecording,
                    onStop: appState.stopRecording,
                    onStopWithRewrite: appState.stopRecordingWithRewrite
                )
                
            case .transcribing:
                TranscribingPillView()
                
            case .rewriting:
                RewritingPillView(onCancel: appState.cancelRewriting)
                
            case .error(let message):
                ErrorPillView(message: message, onDismiss: appState.dismissError)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.recordingState)
    }
}

// MARK: - Idle State

struct IdlePillView: View {
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isHovered {
                    HStack(spacing: 4) {
                        Text("Click or hold")
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Keyboard key style for "fn"
                        Text("fn")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                        
                        Text("to dictate")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .font(.system(size: 10, weight: .medium))
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: isHovered ? 12 : 8))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: isHovered ? 150 : 36, height: isHovered ? 22 : 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Recording State

struct RecordingPillView: View {
    let audioLevel: Float
    let onCancel: () -> Void
    let onStop: () -> Void
    let onStopWithRewrite: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .frame(width: 17, height: 17)
            .background(Circle().fill(Color.white.opacity(0.2)))
            .help("Cancel")
            
            // Audio waveform visualization - wider with more bars
            HStack(spacing: 3) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2, height: waveHeight(for: index))
                }
            }
            .frame(width: 50, height: 18)
            
            // Stop/Finish button (paste transcription only)
            Button(action: onStop) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 17, height: 17)
                    
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: 7, height: 7)
                }
            }
            .buttonStyle(.plain)
            .help("End")
            
            // AI Rewrite button (sparkles icon - Gemini style)
            Button(action: onStopWithRewrite) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 17, height: 17)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .help("End & Re-Write")
        }
        .frame(height: 28)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 4
        let maxAddition: CGFloat = 10
        let normalizedLevel = CGFloat(min(audioLevel * 3, 1.0))
        
        // Create pseudo-random wave pattern
        let heights: [CGFloat] = [0.3, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.6]
        let wave = heights[index % heights.count]
        
        return baseHeight + (maxAddition * normalizedLevel * wave)
    }
}

// MARK: - Transcribing State

struct TranscribingPillView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) { // Spacing 6->4
            Text("Transcribing")
                .font(.system(size: 10, weight: .medium)) // Scale 13->10
                .foregroundColor(.white)
            
            HStack(spacing: 2) { // Spacing 4->2
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3) // Scale 5->3
                        .opacity(animating ? 1 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
        }
        .frame(height: 22) // Scale 44->22
        .padding(.horizontal, 10) // Padding 18->10
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Rewriting State (AI)

struct RewritingPillView: View {
    let onCancel: () -> Void
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 14, height: 14)
            .background(Circle().fill(Color.white.opacity(0.15)))
            
            // Sparkles icon (Gemini style)
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.blue)
            
            Text("Rewriting")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
            
            // Animated dots
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 3, height: 3)
                        .opacity(animating ? 1 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
        }
        .frame(height: 22)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Error State

struct ErrorPillView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 16, height: 16)
            .background(Circle().fill(Color.white.opacity(0.15)))
        }
        .frame(minWidth: 150, maxWidth: 350)
        .frame(height: 28)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        IdlePillView(onTap: {})
        RecordingPillView(audioLevel: 0.5, onCancel: {}, onStop: {}, onStopWithRewrite: {})
        TranscribingPillView()
        RewritingPillView(onCancel: {})
        ErrorPillView(message: "Microphone access denied", onDismiss: {})
    }
    .background(Color.gray.opacity(0.3))
}
