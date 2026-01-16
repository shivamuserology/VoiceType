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
                    onStop: appState.stopRecording
                )
                
            case .transcribing:
                TranscribingPillView()
                
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
                    HStack(spacing: 3) {
                        Text("Click or hold")
                            .foregroundColor(.white.opacity(0.8))
                        Text("fn")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Text("to dictate")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.system(size: 10, weight: .medium)) // Scale down from 12
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
    
    var body: some View {
        HStack(spacing: 10) {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .frame(width: 20, height: 20)
            .background(Circle().fill(Color.white.opacity(0.2)))
            
            // Audio waveform visualization
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 3, height: waveHeight(for: index))
                }
            }
            .frame(width: 40, height: 18)
            
            // Stop/Finish button
            Button(action: onStop) {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 28)
        .padding(.horizontal, 10)
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

// MARK: - Error State

struct ErrorPillView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 6) { // Spacing 10->6
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10)) // Scale defaults->10
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.system(size: 10, weight: .medium)) // Scale 12->10
                .foregroundColor(.white)
                .lineLimit(1)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold)) // Scale 10->8
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 22) // Scale 44->22
        .padding(.horizontal, 8) // Padding 14->8
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        IdlePillView(onTap: {})
        RecordingPillView(audioLevel: 0.5, onCancel: {}, onStop: {})
        TranscribingPillView()
        ErrorPillView(message: "Microphone access denied", onDismiss: {})
    }
    .padding(50)
    .background(Color.gray.opacity(0.3))
}
