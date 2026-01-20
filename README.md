# VoiceType

A native macOS dictation app with a floating widget, Fn key activation, and **context-aware AI Rewrite** capabilities. Perfected by on-device WhisperKit and Google Gemini.

![VoiceType Demo](docs/demo.gif)

## Features

- 🎙️ **Voice-to-Text Anywhere** - Dictate in any app where you can type
- ✨ **Perfected by context aware AI** - Instantly fix grammar, formatting, and clarity with full app & document context
- ⌨️ **Fn Key Activation** - Press and hold Fn to start dictating; add Shift to auto-rewrite
- 🔒 **Privacy Focused** - Dictation is 100% on-device; Rewrite is opt-in via your own API Key
- 💨 **Floating Widget** - Always visible, non-intrusive pill with fluid animations and helpful tooltips
- 📋 **Clipboard Integration** - Copy your last transcription from the menu bar

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1, M2, M3, or later)
- ~500MB disk space for the Whisper model

## Installation

1. Download **VoiceType-1.1.1.dmg** from the [Releases](https://github.com/shivamuserology/VoiceType/releases) page
2. Open the DMG and drag VoiceType to your Applications folder
3. Launch VoiceType from Applications
4. Grant permissions:
   - **Microphone**: For dictation
   - **Accessibility**: For text injection
5. (Optional) Go to **Settings > General** and enter your **Gemini API Key** to enable AI Rewrite.

## Usage

### Basic Dictation
1. Click on any text field
2. Press and hold the **Fn** key
3. Speak clearly
4. Release the **Fn** key -> Text appears instantly

### Smart Rewrite
1. Dictate as usual (or click the widget microphone)
2. Instead of releasing to paste, click the **Blue Sparkles ✨** icon on the widget
3. Watch as your raw speech is transformed into polished text

### Hands-Free Mode
1. Click the floating widget to start recording
2. Speak your text
3. Click **End** (Red) to paste raw, or **End & Re-Write** (Blue) to polish
4. Hover over buttons to see helpful tooltips!

## Building from Source

### Prerequisites
- Xcode 15.0 or later
- macOS 14.0 or later

### Steps

```bash
# Clone the repository
git clone https://github.com/shivamuserology/VoiceType.git
cd VoiceType

# Open in Xcode
open VoiceType.xcodeproj

# Build and run (Cmd+R)
```

## Architecture

```
VoiceType/
├── App/
│   ├── VoiceTypeApp.swift      # SwiftUI app entry
│   └── AppState.swift          # Observable state machine
├── Services/
│   ├── GeminiService.swift     # Google Gemini API integration
│   ├── AudioRecorder.swift     # AVAudioEngine recording
│   ├── SpeechRecognizer.swift  # WhisperKit wrapper
│   └── TextInjector.swift      # Smart text replacement
├── Views/
│   ├── FloatingWidgetView.swift # The pill UI
│   ├── HistoryView.swift       # Past dictations
│   └── SettingsView.swift
└── Scripts/
    └── create-dmg.sh
```

## Privacy

VoiceType is designed with strong privacy principles:
- **Dictation**: Processed 100% locally using WhisperKit. Your voice never leaves your Mac during standard dictation.
- **AI Rewrite**: If you use the Rewrite feature, text is sent to Google's Gemini API using your personal API Key.
- **No Data Collection**: We (the developers) do not collect, store, or transmit any of your data.

## Acknowledgments

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - On-device speech recognition
- [Google Generative AI](https://github.com/google/generative-ai-swift) - Smart Rewriting
- [OpenAI Whisper](https://github.com/openai/whisper) - Underlying model

## License

MIT License - see [LICENSE](LICENSE) for details.
