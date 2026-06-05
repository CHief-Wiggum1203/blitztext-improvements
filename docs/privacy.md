# Privacy Notes

Blitztext macOS Preview does not include a hosted backend.

This fork adds an optional **Anthropic (Claude)** rewriting backend alongside OpenAI. Transcription in online mode still uses OpenAI only.

## Online Workflows

When you use online workflows, your Mac sends data directly to the configured providers:

**OpenAI** (always for online transcription; also for rewriting when OpenAI is selected):

- audio recordings for transcription
- transcribed or typed text for rewriting
- custom terms and prompt context if you configured them

**Anthropic** (only when Claude is selected as the AI provider):

- transcribed, selected, or typed text for rewriting
- system prompts including custom workflow prompts
- no audio is sent to Anthropic

When **Sicherer Lokaler Modus** is enabled and a WhisperKit/CoreML model is installed, transcription runs on your Mac and does not send audio to OpenAI. Rewriting workflows (including custom workflows) still require an online AI provider and are paused while secure local mode is active.

You are responsible for your API accounts, usage, costs, and data handling at each provider.

## Local Data

The app stores:

- your OpenAI API key in the user's macOS Keychain
- your Anthropic API key in the user's macOS Keychain (if configured)
- workflow settings, hotkey bindings, and custom workflows in local app support storage
- optional WhisperKit/CoreML model folders in local app support storage
- temporary audio files while a transcription is being processed; the app attempts to delete each recording when the workflow ends or is cancelled

Custom workflows store their names, system prompts, modes, and hotkeys as plain JSON in local app support storage. Do not put secrets into those fields.

Workflow output may also be placed on your clipboard so it can be pasted into another app. Auto-paste marks the clipboard entry as concealed for compatible clipboard managers, but the generated text intentionally remains on the clipboard as a fallback if automatic paste is blocked. Clipboard managers, macOS, or other apps may still observe clipboard contents while they are present.

Selection-mode workflows read the currently selected text by simulating Cmd+C. That text is then sent to the configured AI provider according to your workflow prompt.

The app uses the system TLS trust store for OpenAI, Anthropic, and Hugging Face requests. It does not currently pin certificates. A user-installed or managed root certificate can therefore affect HTTPS trust decisions on that Mac.

## Offline Scope

Only transcription can run locally. Any workflow that rewrites, improves, or transforms text still uses OpenAI or Anthropic, depending on your settings.

## Sensitive Content

Do not use this preview with confidential, regulated, or highly sensitive content unless you have reviewed the code, your provider settings, and your legal/privacy requirements.
