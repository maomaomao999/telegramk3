# Kislap iOS open-source release

## Release identity

- Product: Kislap: Learn & Connect
- App version: 1.2
- App Store build: 100005
- Bundle identifier: `ph.kislap.app`
- Release tag: `ios-v1.2-build-100005`
- Upstream base: Telegram iOS `release-12.8`
- Upstream repository: https://github.com/TelegramMessenger/Telegram-iOS

This tag is the source tree used for the submitted binary, including Kislap
changes and the exact Git references for each submodule. Clone with:

```sh
git clone --recursive --branch ios-v1.2-build-100005 \
  https://github.com/maomaomao999/telegramk3.git kislap-ios
```

If the repository was cloned without `--recursive`, run:

```sh
git submodule update --init --recursive
```

## Build configuration

Copy `build-system/kislap-appstore.template.json` and replace every placeholder
with your own Telegram API ID/hash, Apple Team ID and App Store numeric ID. Do
not commit the resulting `*.local.json` file or signing directory. Detailed
project generation and build steps are in `KISLAP_BUILD.md`.

## Licensing and attribution

Kislap is derived from Telegram's open-source iOS client. Telegram requires
third-party clients to use their own API ID and publish their corresponding
source to comply with the GNU GPL licenses:
https://core.telegram.org/api/obtaining_api_id

Upstream copyright notices and the individual license/copying files bundled
with Telegram and its dependencies are preserved in this repository. No claim
is made over third-party trademarks. Kislap is an unofficial client and is not
affiliated with or endorsed by Telegram.

## Excluded material

The public source intentionally excludes:

- Telegram API ID/hash values used by the production build
- Apple certificates, private keys, `.p12` files and provisioning profiles
- Kislap backend, OTP, moderation and object-storage credentials
- user accounts, sessions, logs and review OTPs

These values are deployment credentials, not source code required to build the
client with independently supplied credentials.
