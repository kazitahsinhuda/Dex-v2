# Dexter

A native Android AI companion built with Kotlin and Jetpack Compose.

## First-build features
- Dark chat interface
- Gemini-powered conversation
- Companion, Teaching, and Sparring modes
- Speech-to-text input
- Spoken replies only after voice input
- Clear HTTP/API error messages

## Build
GitHub Actions builds a debug APK on every push to `main`.

Add a repository Actions secret named `Api` containing your Gemini API key. Never commit the key into source code.
