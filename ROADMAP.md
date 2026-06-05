# Roadmap

This is a preview roadmap, not a promise.

This document covers the upstream direction and the extensions implemented in this fork.

## Implemented In This Fork

- LLM provider protocol with OpenAI and Claude backends
- Online transcription model selection (`whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`)
- Configurable hotkeys for all built-in workflows
- Custom workflows (up to 5) with voice and selection modes
- Selection service for reading marked text from other apps
- Custom workflows in menu bar popover and settings editor

See [docs/superpowers/specs/2026-06-04-blitztext-improvements-design.md](docs/superpowers/specs/2026-06-04-blitztext-improvements-design.md).

## Current Scope (Upstream Base)

- macOS menubar app
- local recording and hotkeys
- direct OpenAI API calls with a user-provided API key
- transcription, rewriting, calmer-message, and emoji workflows
- no hosted backend
- no other platforms
- no packaged public release

## Next Useful Work

- Make first-run setup clearer.
- Improve credential setup, validation, and recovery UX.
- Add a small automated test layer around prompt construction and text quality filters.
- Add provider boundaries so OpenAI and future local transcription can be swapped more cleanly.
- Prototype local transcription with WhisperKit or whisper.cpp.
- Reduce the Accessibility blast radius, ideally by moving synthetic paste into a smaller helper with narrower responsibilities.
- Add stronger supply-chain checks around downloaded local speech models.
- Add signed and notarized release builds when the project is ready for non-developer users.

## Fork-Specific Ideas (Not Implemented Yet)

- More than five custom workflows
- Local rewriting without cloud APIs
- Export/import custom workflow presets
- Screenshot assets for fork showcase in `docs/screenshots/`

## Not In Scope Yet

- Production support.
- Accounts, sync, teams, or hosted infrastructure.
- Claims that the app is offline or privacy-complete.
- App Store distribution.
