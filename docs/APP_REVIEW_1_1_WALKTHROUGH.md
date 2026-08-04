# Kislap 1.1 App Review Walkthrough

This document is the reviewer path for Kislap 1.1. Replace bracketed slots only in App Store Connect; keep credentials out of source control.

## Review access

- Telegram-compatible account: `[REVIEW_TELEGRAM_PHONE]`
- Telegram verification: `[SMS_OR_OTHER_METHOD]`
- Kislap learning account: `[REVIEW_KISLAP_EMAIL]`
- Kislap OTP delivery: `[EMAIL_OTP]`
- Review region: Philippines

## First-minute path

1. Launch Kislap and finish the communication-account sign-in with the supplied review phone.
2. The app opens on **Learn**, not on a chat list.
3. Observe the three Kislap-owned entry points: **Learn**, **Teach** and **Connect**.
4. Tap **Connect learning profile** and sign in with the supplied Kislap review email and email OTP.
5. In **Learn**, choose English, Programming or Singing.
6. Tap **Use My Approximate Area**. The interface explains that exact position is not displayed and visibility is time-limited.
7. Open a real nearby learning profile to inspect avatar, learning skills, teaching skills, activity and approximate distance.
8. Use **Connect** to send or review a learning request.
9. Open the profile safety menu to verify **Report** and **Block**.
10. Open **Chats**, **Calls** or a group only after the learning flow to verify the communication capabilities.

## What is unique to Kislap

- Kislap-owned account and learning profile
- Learn, Teach and Connect as the default product hierarchy
- Skill matching for English, programming, singing and additional skills
- Nearby discovery using approximate ranges and user-controlled visibility
- Learning requests, profile safety, report and block workflows
- Separate Dating opt-in that is off by default
- Messaging, groups and calls used as communication capabilities for ongoing learning relationships

## 4.3(a) review context

Kislap is one learning and skill-exchange product and is not a multi-brand or white-label submission. It uses open-source communication components, while the Kislap account, learning profile, skill matching, Nearby privacy model, learning connections, moderation workflows and product navigation are Kislap-specific.

The default authenticated destination is the Kislap learning home. The reviewer can reach the product's primary learning workflows without first navigating through a general chat interface.

## Review Notes draft

Kislap 1.1 is a learning and skill-exchange app. After communication-account sign-in, the app opens directly to the Kislap Learn home, where the reviewer will see Learn, Teach and Connect.

Reviewer path:
1. Sign in with `[REVIEW_TELEGRAM_PHONE]`; verification arrives by `[SMS_OR_OTHER_METHOD]`.
2. Tap Connect learning profile.
3. Sign in with `[REVIEW_KISLAP_EMAIL]`; the OTP arrives by email.
4. Choose a skill, enable approximate-area visibility, open a learning profile, and inspect Connect, Report and Block.
5. Chats, groups, voice calls and video calls remain available as communication capabilities for learning relationships.

Kislap-specific functionality includes a separate learning account and profile, skill matching, privacy-preserving Nearby discovery, learning requests, time-limited visibility, and Kislap moderation. Dating is a separate mutual opt-in and is off by default.

Open-source communication components are disclosed in the app's acknowledgements and source notices. The submitted app, metadata and screenshots all represent the same single Kislap product.

## Evidence to capture before submission

- [ ] 45–60 second screen recording of steps 1–9
- [ ] Real-device screenshot showing Learn as the default destination
- [ ] Real-device screenshot showing a signed-in learning profile
- [ ] Real-device screenshot showing one real nearby result
- [ ] Real-device screenshot showing Report and Block
- [ ] OTP delivery timestamp for the review account
- [x] Support and privacy URLs returned HTTP 200 on 2026-07-31; support includes account-deletion instructions
