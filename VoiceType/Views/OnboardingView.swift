import SwiftUI

/// Onboarding step enum
enum OnboardingStep {
    case personalization
    case permissions
}

/// Onboarding view for first-time setup - Sleek Black & White Design
struct OnboardingView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var speechRecognizer: SpeechRecognizer
    var onComplete: () -> Void
    
    // Step management
    @State private var currentStep: OnboardingStep = .personalization
    
    // User data (persisted)
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userProfession") private var userProfession: String = ""
    @State private var customProfession: String = ""
    
    // Profession options
    private let professionOptions = [
        "Developer",
        "Designer",
        "Product Manager",
        "Writer",
        "Content Creator",
        "Marketing Manager",
        "Data Analyst",
        "Project Manager",
        "Sales Representative",
        "Consultant",
        "Researcher",
        "Teacher/Educator",
        "Journalist",
        "Copywriter",
        "Video Editor",
        "Podcaster",
        "UX/UI Designer",
        "Business Analyst",
        "Accountant",
        "Lawyer",
        "Other"
    ]
    
    var canContinue: Bool {
        permissionsManager.allPermissionsGranted && speechRecognizer.isReady
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Always visible
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("VoiceType")
                        .font(.system(size: 24, weight: .semibold))
                        .tracking(-0.3)
                    
                    Text(currentStep == .personalization ? "Let's get to know you" : "Voice to text, anywhere")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 24)
            
            // Content based on step
            if currentStep == .personalization {
                personalizationStep
            } else {
                permissionsStep
            }
        }
        .frame(width: 420, height: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Start model download immediately
            Task {
                await speechRecognizer.initialize()
            }
            permissionsManager.checkAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionsManager.checkAllPermissions()
        }
    }
    
    // MARK: - Step 1: Personalization
    
    private var personalizationStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Profession dropdown
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Profession")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(professionOptions, id: \.self) { option in
                            Button(option) {
                                userProfession = option
                            }
                        }
                    } label: {
                        HStack {
                            Text(userProfession.isEmpty ? "Select your profession" : userProfession)
                                .font(.system(size: 15))
                                .foregroundColor(userProfession.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Show custom text field if "Other" is selected
                    if userProfession == "Other" {
                        TextField("Enter your profession", text: $customProfession)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Text("Helps personalize your experience")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Bottom buttons
            VStack(spacing: 10) {
                Button(action: { currentStep = .permissions }) {
                    Text("Continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: { currentStep = .permissions }) {
                    Text("Skip")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
    }
    
    // MARK: - Step 2: Permissions
    
    private var permissionsStep: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Setup Steps
                    VStack(spacing: 8) {
                        // Microphone Permission
                        CompactPermissionRow(
                            icon: "mic",
                            title: "Microphone",
                            isGranted: permissionsManager.microphoneStatus == .granted,
                            buttonLabel: "Enable",
                            action: {
                                Task {
                                    await permissionsManager.requestMicrophonePermission()
                                }
                            }
                        )
                        
                        // Accessibility Permission
                        CompactPermissionRow(
                            icon: "accessibility",
                            title: "Accessibility",
                            isGranted: permissionsManager.accessibilityStatus == .granted,
                            buttonLabel: "Settings",
                            action: {
                                permissionsManager.openAccessibilitySettings()
                            }
                        )
                    }
                    
                    // Help text for accessibility (only when needed)
                    if permissionsManager.accessibilityStatus != .granted {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To enable Accessibility:")
                                .font(.system(size: 11, weight: .medium))
                            Text("Click Settings → Click + → Select VoiceType.app → Toggle ON")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxHeight: .infinity)
            
            // Bottom Area
            VStack(spacing: 16) {
                // Model Installation Status
                ModelStatusView(recognizer: speechRecognizer)
                
                // Bottom Buttons
                VStack(spacing: 8) {
                    Button(action: onComplete) {
                        HStack(spacing: 6) {
                            Text("Get Started")
                                .font(.system(size: 14, weight: .medium))
                            
                            if canContinue {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .foregroundColor(canContinue ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(canContinue ? Color.black : Color.black.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canContinue)
                    
                    if !canContinue {
                        Button(action: onComplete) {
                            Text("Skip for now")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
    }
}

// MARK: - Compact Permission Row

struct CompactPermissionRow: View {
    let icon: String
    let title: String
    let isGranted: Bool
    let buttonLabel: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 18)
            
            // Title
            Text(title)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            // Status/Action
            if isGranted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(5)
                    .background(
                        Circle()
                            .stroke(Color.green, lineWidth: 1.5)
                    )
            } else {
                Button(action: action) {
                    Text(buttonLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Model Status View

struct ModelStatusView: View {
    @ObservedObject var recognizer: SpeechRecognizer
    
    var body: some View {
        VStack(spacing: 8) {
            if recognizer.isReady {
                // Completed State
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("AI Model Ready (100%)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            } else if let error = recognizer.initializationError {
                // Error State
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("Installation Failed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        Task {
                            await recognizer.initialize()
                        }
                    }) {
                        Text("Retry Installation")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            } else {
                // Loading State
                VStack(spacing: 6) {
                    HStack {
                        Text("Installing AI Model...")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    }
                    
                    ProgressView() // Indeterminate
                        .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                        .opacity(0.5)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
