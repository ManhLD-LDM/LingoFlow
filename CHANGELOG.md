# Changelog

All notable changes to the LingoFlow project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-08-30

### 🚀 Added
- **Multi-Engine OCR Strategy (`OcrEngineMode`)**:
  - `Auto Fallback`: Intelligent cloud-first recognition with seamless local/offline fallback.
  - `Cloud Only`: OCR.space Asian Cloud Engine 2 for complex Kanji/CJK typography.
  - `Offline Only`: Zero-network latency recognition with no API quotas.
- **Game Profiles & Custom Terminology Glossary System (`GameProfile`)**:
  - Create and manage isolated profiles for different Games, Visual Novels, and Manga titles.
  - Custom game vocabulary mapping (e.g. `宝具` ➔ `Noble Phantasm (Bảo Khí)`, `HP` ➔ `Máu`).
  - TextProcessor algorithm with longest-match precedence to preserve character and skill names.
  - Dedicated `ProfilesScreen` for profile switching, adding terms, and JSON import/export.
- **Onboarding Setup Wizard (`OnboardingWizardDialog`)**:
  - Interactive 3-step setup guide for first-time users (Language selection ➔ OCR Strategy ➔ Hotkeys guide).
- **Live Subtitle Preview Box**:
  - Real-time simulation of subtitles directly within the Appearance settings tab.
- **Native Audio Speech Synthesis (TTS)**:
  - System speech playback in `TtsService` and interactive pronunciation in `DictionaryPopup`.
- **Automated CI/CD Pipeline (`.github/workflows/flutter_ci.yml`)**:
  - Automated static analysis (`flutter analyze`), full test suite execution with coverage, and multi-platform native releases for Windows (`.exe`) and Android (`.apk`).
- **Comprehensive Unit & Widget Test Suite**:
  - 28 unit and widget tests covering TextProcessor, ExportService, BmpEncoder, TranslationRepository, Domain Entities, GameProfile, and TtsService (100% pass rate).

### ⚡ Enhanced & Refactored
- **Settings Screen Redesign**: Refactored monolithic scroll view into a 4-tab TabBarView (Translation Engine, OCR, Subtitle Appearance, Performance & Hotkeys).
- **Home Screen UX**: Added quick Clipboard Paste action in the Live Translation Tester and an interactive Global Hotkeys reference modal (F1 / Help).
- **Persistent State**: Full `SharedPreferences` persistence for all app settings, FloatingLens geometry (`lensX`, `lensY`, `lensWidth`, `lensHeight`), OCR API key, and OCR strategy mode.
- **High-DPI Awareness**: Integrated `devicePixelRatio` scaling in screen capture and OCR coordinates to prevent misalignments on 125%/150%/200%/4K displays.
- **Memory Optimization**: Implemented bounded LRU cache eviction (max 200 entries) in `TranslationRepositoryImpl`.

### 🔒 Security & Bug Fixes
- **API Key Hardcode Elimination**: Moved OCR.space and DeepL API keys to `.env` (git-ignored) with `.env.example` public template.
- **Safe DotEnv Loading**: Added graceful fallback hierarchy preventing startup crashes when `.env` is absent in fresh clones or CI environments.
- **Structured Error Logging**: Eliminated silent `catch (_) {}` across all datasources and native services with leveled `AppLogger`.
