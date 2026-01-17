# VoiceType 1.1.1: Perfected by context aware AI ✨
This update transforms VoiceType from a dictation tool into a context-aware writing assistant. It now "sees" where you are writing to give you perfectly tailored results.

## 🌟 What's New

### 🧠 Perfected by context aware AI
VoiceType now understands your environment:
*   **App and Document context**: It automatically detects the active app, document title, and technical level (e.g., "Slack: #engineering", "Xcode: GeminiService.m") to adapt its tone instantly.
*   **Smart Fallbacks**: It can even read context from text fields that normally block accessibility tools, ensuring a perfect rewrite every time.
*   **Safe Placeholders**: Create your own custom prompts in Settings using placeholders like `{app_and_document_context}`, `{nearby_text_context}`, `{platformName}`, and `{userProfession}`.

### 🎯 Refined Widget Experience
*   **Helpful Tooltips**: Hover over the widget buttons during recording to see their actions: "Cancel", "End", or "End & Re-Write".
*   Cleaner, more intuitive button labels throughout the app.

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
