# Kislap iOS build baseline

This repository starts from Telegram-iOS `release-12.8` at commit
`6e370e06d147b091b07903071cb1b8a22152492d`.

## Locked tools

- Xcode 26.2 (`17C52`)
- Bazel 8.4.2
- macOS 26

Xcode is installed at `/Applications/Xcode-26.2.0.app`. Select it globally once
because Bazel's local SDK discovery reads `xcode-select` before action-level
environment variables are applied:

```sh
sudo xcode-select --switch /Applications/Xcode-26.2.0.app/Contents/Developer
```

The project commands also export `DEVELOPER_DIR` so their selected toolchain is
explicit and reproducible.

Install the simulator runtime and Metal compiler once after installing Xcode:

```sh
export DEVELOPER_DIR=/Applications/Xcode-26.2.0.app/Contents/Developer
xcodebuild -downloadPlatform iOS
xcodebuild -downloadComponent MetalToolchain
```

## Local configuration

Copy `build-system/kislap-development.template.json` to
`build-system/kislap-development.local.json`, then replace the Telegram API ID,
Telegram API hash, and Apple Team ID. The local file is ignored by Git. Never
commit API hashes, certificates, provisioning profiles, or account passwords.

The Telegram API ID and API hash are created at `https://my.telegram.org/apps`.

## Generate the simulator project

Use the Bazel binary whose SHA-256 directory matches `versions.json`:

```sh
export DEVELOPER_DIR=/Applications/Xcode-26.2.0.app/Contents/Developer
export BAZEL_8_4_2="$HOME/Library/Caches/bazelisk/downloads/sha256/45e9388abf21d1107e146ea366ad080eb93cb6a5f3a4a3b048f78de0bc3faffa/bin/bazel"

python3 build-system/Make/Make.py \
  --bazel "$BAZEL_8_4_2" \
  --cacheDir="$HOME/telegram-bazel-cache" \
  generateProject \
  --configurationPath=build-system/kislap-development.local.json \
  --xcodeManagedCodesigning \
  --disableProvisioningProfiles \
  --disableExtensions
```

The generated `Telegram/Telegram.xcodeproj`, build inputs, and Bazel links are
local build artifacts and are ignored by Git.

## Brand boundary

The application display name and first-run learning tour use the Kislap brand.
The tour explicitly says that communication is built on the Telegram network.
Service-specific terms such as Telegram login codes, Telegram cloud behavior,
MTProto, and Telegram privacy controls must remain accurate; do not replace
every occurrence of “Telegram” mechanically.

The default iPhone/iPad icon is compiled from the validated 1024×1024 Kislap
learning-partner artwork. Telegram's alternate icon catalog is disabled for the
Kislap target so a user cannot switch the product back to Telegram artwork.

Telegram passkey login is attempted only by Telegram's official bundle IDs.
Kislap cannot claim the `telegram.org` associated-domain entitlement, so its
authorization flow proceeds directly to phone-number login. The splash-to-phone
transition also starts on the first valid layout instead of waiting for a
software-keyboard height, which keeps simulator and hardware-keyboard flows
from retaining the splash snapshot indefinitely.

## Current verification

- The official source and all pinned submodules are present.
- Xcode 26.2 generates the project and recognizes its Telegram, TelegramVoip,
  TgVoipWebrtc, and WebRTC targets.
- A complete Bazel simulator build succeeds, including TelegramCore,
  TelegramUI, TelegramVoip, tgcalls, WebRTC, BoringSSL, Opus, and libvpx.
- The resulting `ph.kislap.dev` version 12.8 arm64 app installs and launches on
  an iPhone 17 Pro simulator running iOS 26.3.1.
- The simulator build uses ad-hoc signing. Device and TestFlight builds still
  require a real Apple Team ID, certificates, entitlements, and provisioning.
- The temporary preflight configuration cannot authenticate with Telegram.
  Real Telegram API credentials are required before login and end-to-end call
  testing.
- A clean simulator install displays the Kislap learning tour and the
  `Start Learning` action while retaining the Telegram-network disclosure.
- A real Telegram account completes phone login with the ignored local API
  configuration, and a Saved Messages smoke-test message reaches the account.
- The Calls tab and new-call entry render after login. An end-to-end voice and
  video call still requires a consenting second account and has not been placed
  automatically.
- A native `Nearby` tab now renders after Telegram login. Location is off by
  default, discovery requires an explicit tap, the location manager requests
  kilometer-level accuracy, and the UI promises only distance ranges rather
  than exact coordinates.
- The native Nearby flow uses `http://127.0.0.1:3000` only for the `.dev`
  simulator. Physical devices and production builds use
  `https://api.kislap.org`. It uses a
  separate email-verified adult learning profile; Telegram credentials and
  MTProto session material are never sent to the Kislap backend.
- Refresh tokens are stored in the iOS Keychain, rotated by the server, and
  refreshed through a single-flight client path so concurrent requests cannot
  trigger token-reuse revocation. Disconnect revokes the server refresh token
  and does not sign the user out of Telegram.
- Nearby visibility is an explicit one-hour opt-in. The backend stores only a
  randomly fuzzed coordinate, evaluates expiry in UTC, returns coarse distance
  labels without meter distances or district data, and excludes stale, blocked,
  or suspended users. The native list supports English, programming, and
  singing filters, study-session requests, blocking, and reporting.
- Local end-to-end verification completed email OTP login, coarse location
  update, one-hour expiry, a real database-backed nearby card, a study request,
  and a cold restart that preserved both Telegram and Kislap sessions. No mock
  nearby people are rendered and Telegram's removed People Nearby flow is not
  used.
- The Nearby integration passes a full Bazel iOS Simulator build and was
  overwrite-installed on the logged-in iPhone 17 Pro simulator without losing
  the Telegram account session.

## Known local Xcode issue

The Bazel app bundle is valid and runnable, but the generated Xcode build can
currently finish its Bazel phase and then exit with code 65 while Xcode copies
read-only debug Swift module metadata from Bazel frameworks. Until the generated
copy phase is corrected, use the Bazel-produced app for simulator smoke tests.
This does not indicate a Telegram, MTProto, or tgcalls compilation failure.
