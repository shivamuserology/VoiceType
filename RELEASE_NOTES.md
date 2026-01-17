# VoiceType 1.1.1: Context & Control 🧠
This update transforms VoiceType from a dictation tool into a context-aware writing assistant. It now "sees" where you are writing to give you perfectly tailored results.

## 🌟 What's New

### 🧠 Smart Context Awareness
VoiceType now understands your environment:
*   **Window Context**: It detects the active window title and URL (e.g., "Slack: #engineering", "Xcode: GeminiService.swift") to adapt its tone and technical level.
*   **Ghost Context**: It intelligently reads the text field name and description even if the text itself isn't selectable, preventing the "blind rewrite" problem.
*   **Safe Placeholders**: Create your own custom prompts in Settings using placeholders like `{windowContext}`, `{platformName}`, and `{userProfession}`.

### ⌨️ Keyboard Power
*   **Fn + Shift (Release)**: You can now trigger the **AI Rewrite** instantly from your keyboard.
    *   **Tap Fn**: Standard transcription.
    *   **Hold Fn + Tap Shift**: Transcription + Immediate AI Rewrite.

### 🛡️ Professional Onboarding
*   **Mandatory Setup**: We've streamlined the setup flow to ensure your microphone and accessibility permissions are perfect from the start.
*   **Subtle Status**: Moved system status indicators to a sleek, non-intrusive header.

## 🛠 Fixes
*   **Google Docs Support**: Completely rewrote the text injection engine to fix the "over-deletion" bug in Google Docs and web browsers. We now use a robust **Undo-Replace** strategy that works perfectly even on slow connections.
*   **Context Guard**: Fixed an edge case where the AI would sometimes read the transcribed text as "existing context," leading to redundancy.

## How to Install
1.  Download `VoiceType-1.1.1.dmg`
2.  Drag to Applications
3.  Open and grant the new Accessibility permissions if prompted.
