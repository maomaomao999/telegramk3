# Kislap 1.2 Development Plan

Status: release candidate delivered to App Store Connect
Base: rejected App Store build `1.1 (100003)`
Development branch: `kislap/1.2`
Primary objective: materially differentiate the executable and App Store metadata through real Kislap-owned architecture and features.

## Product boundary

- Telegram account, chats, groups, media, voice calls and video calls remain available as the communication foundation.
- Kislap owns the default App Shell, privacy controls, batch-forward workflow and Nearby experience.
- Learning and skill exchange remain the primary Nearby use case; Dating remains separate, mutual opt-in and off by default.
- Changes must be functional and testable. Symbol-only renaming, binary padding and misleading metadata are excluded.

## P0 — Executable differentiation

### 0. Isolated release line and evidence

- [x] Create `kislap/1.2` from the frozen 1.1 release state.
- [x] Record the accepted 1.2 requirements and validation gates.
- [ ] Capture a pre-change module/resource/binary baseline.
- [x] Maintain a per-feature build record; real-device verification remains a release gate.

### 1. Kislap App Shell

- [x] Add a Kislap-owned Home controller as the default post-login destination.
- [x] Move Telegram Chats and Calls behind communication actions instead of using a Telegram screen as the product shell.
- [x] Expose Batch Forward, Peek Mode, Stealth Mode and Nearby as first-class Kislap actions.
- [x] Add English and Simplified Chinese copy and theme-aware layouts.

Acceptance:

- A normal authenticated launch opens Kislap Home.
- The first viewport is structurally distinct from the Telegram chat list.
- Telegram chats, groups and calls remain reachable within one action.

### 2. Peek Mode (private preview)

- [x] Persist an explicit Peek Mode preference.
- [x] Suppress automatic interactive read advancement while Peek Mode is enabled.
- [x] Keep the upstream manual Mark as Read path available.
- [x] Display a persistent in-product state indicator and explanatory copy.
- [ ] Verify private chats, groups, channels, threads and secret chats separately.

Acceptance:

- Opening a chat while Peek Mode is enabled does not automatically advance the interactive read index.
- Disabling Peek Mode restores the upstream behavior without restarting the app.
- The UI never claims to reverse a read state already recorded by the network.

### 3. Stealth Mode

- [x] Persist an explicit Stealth Mode preference.
- [x] Suppress typing, sticker-selection, voice-recording and instant-video activity broadcasts while enabled.
- [x] Add session duration presets and a clear off state.
- [ ] Add notification-preview, media-preload and link-preview controls in later increments.

Acceptance:

- Text entry and recording continue locally while peer activity broadcasts remain absent.
- Disabling Stealth Mode restores upstream activity behavior immediately.

### 4. Batch Forward

- [x] Add a Kislap Batch Forward entry and onboarding path.
- [x] Support multiple selected messages and multiple destinations through the existing restricted-content-aware forwarding engine.
- [x] Add a review screen with destination count, message count, forwarding options and restricted-content warnings.
- [x] Add queue progress, cancel-pending and per-destination results.
- [x] Preserve upstream forwarding restrictions and rate limits.

### 5. Nearby

- [x] Move Nearby under the Kislap App Shell while preserving its independent account and API.
- [x] Retain approximate distance, time-limited visibility, Report and Block.
- [x] Keep Dating separate, adult-only, mutual opt-in and off by default.

## P1 — Metadata and review package

- [ ] Remove Telegram-first screenshots, captions, keywords and navigation references.
- [ ] Prepare screenshots for Home, Batch Forward, Peek, Stealth, Nearby and Safety.
- [ ] Update Review Notes with a first-minute Kislap-owned path.
- [x] Disclose the open-source communication foundation accurately.
- [x] Record source/license compliance for the exact submitted build.

## Release gates

- [x] Full Bazel release build succeeds.
- [x] Main app and all extensions pass signing/profile validation.
- [ ] Peek and Stealth behavior pass two-account real-device verification.
- [ ] Batch Forward passes private chat, group, channel and protected-content tests.
- [ ] Nearby, Connect, Report, Block and account deletion regressions pass.
- [ ] Voice/video/background/lock-screen calling regressions pass.
- [ ] TestFlight smoke test passes before App Review submission.

## Implementation record

### 2026-08-02 — App Shell and privacy modes

- Added `KislapHomeController` as the default authenticated root tab.
- Added persisted Peek and Stealth preferences plus a Kislap Privacy Center.
- Added one-hour, eight-hour and until-disabled Stealth sessions with automatic expiry.
- Peek gates automatic interactive read advancement in `AccountContext.applyMaxReadIndex`.
- Stealth gates typing, sticker selection, voice recording and instant-video activity broadcasts in `ChatController`.
- Batch Forward has a first-class Home entry and uses the existing multi-message, multi-destination, restricted-content-aware forwarding engine.
- Added a Kislap-owned pre-send review screen with message count, destination count/names, sender/caption options, comment state and restriction disclosure.
- Validation: `//submodules/TelegramUI:TelegramUI` compiled successfully for `ios_sim_arm64` with Xcode 26.2; output includes `bazel-bin/submodules/TelegramUI/libTelegramUI.a`.
- Full app packaging remains a release gate because the simulator app target still requires extension provisioning configuration.

### 2026-08-03 — Batch Forward delivery tracking

- Added a Kislap-owned progress screen with queued, sending, sent, failed and cancelled states for every destination.
- Added aggregate progress and final sent/failed/cancelled counts.
- Added cancel-pending behavior backed by deletion of message IDs that are still pending, including IDs returned after cancellation was requested.
- Replaced the previous single-disposable batch status tracking with independent status subscriptions for every destination.
- Validation: `//submodules/TelegramUI:TelegramUI` compiled successfully for `ios_sim_arm64` with Xcode 26.2 after the cancellation-race correction; output includes `bazel-bin/submodules/TelegramUI/libTelegramUI.a`.

### 2026-08-03 — Store and review draft

- Added paste-ready English and Simplified Chinese 1.2 metadata centered on the implemented Home, Batch, Peek, Stealth and Nearby workflows.
- Added a step-by-step reviewer path with typed credential slots and explicit real-account fixtures.
- Added an iPhone/iPad screenshot shot list that excludes fictional profiles and requires final-build capture.
- Validation: subtitle, promotional text and keyword drafts fit their intended field budgets; placeholder scan confirms review credentials remain outside source control.

### 2026-08-03 — App Store delivery candidate

- Archived and exported Kislap `1.2 (100005)` with bundle identifier `ph.kislap.app`.
- Verified strict code signing for the main app and all six extensions.
- Exported `build-artifacts/Kislap-1.2-100005/Telegram.ipa` with SHA-256 `ba15b9405d51f25c80b33431e346a9755605fb9d38be255a74eaa61ec7e8176a`.
- Transporter confirmed successful delivery and reported the build available for internal testing.
- Real-device regression, final screenshots, TestFlight smoke testing and App Review submission remain open release gates.
