# Kislap 1.2 App Review Walkthrough

Use this with the exact build submitted for review. Credentials stay in App Store Connect Review Information and do not enter source control.

## Review access slots

- Communication account: `[REVIEW_PHONE]`
- Verification method: `[SMS]`
- Kislap learning account: `[REVIEW_EMAIL]`
- Kislap OTP method: `[EMAIL]`
- Review region: Philippines

## First-minute path

1. Launch Kislap and sign in with the supplied communication account.
2. Confirm that the first authenticated destination is **Kislap Home**, not a chat list.
3. On Home, observe four Kislap tools: **Batch Forward**, **Peek Mode**, **Stealth Mode** and **Nearby Learning**.
4. Open **Peek Mode** and enable it. Open a prepared unread test conversation, then return and use the existing manual Mark as Read action.
5. Open **Stealth Mode**, choose a one-hour session, enter text or begin a recording, and observe the persistent active-state indicator.
6. Open **Batch Forward**, choose **Open Messages**, enter the prepared review chat, select multiple messages and choose multiple destinations.
7. Inspect the Kislap pre-send review, send the batch, then observe live progress and the sent/failed/cancelled result for each destination.
8. Return to Home and open **Nearby Learning**. Sign in with the supplied Kislap review email and email OTP if prompted.
9. Enable approximate-area visibility, open a real learning profile, and inspect Connect, Report and Block.
10. Return to Home and open **Messages** or **Calls** to verify the retained communication foundation.

## Reviewer test fixtures

- One unread direct conversation for Peek verification
- One consenting direct-chat recipient for typing/recording signal verification
- Two writable destinations for Batch Forward
- One destination with a known restriction only if the reviewer needs a failure-state example
- One real Kislap learning profile with a non-sensitive test photo and skills
- One real nearby learning profile; no fictional or undisclosed seeded users

## Kislap-specific functionality

- A Kislap-owned authenticated Home and navigation hierarchy
- Batch Forward review, independent destination status tracking and cancellation of pending items
- Peek Mode gating of automatic interactive read advancement
- Timed Stealth sessions for activity-signal control
- Nearby learning discovery using approximate distance and expiring visibility
- Kislap learning profiles, Connect, Report and Block
- Separate Dating opt-in that is off by default

## Review Notes draft

Kislap 1.2 is a learning and intentional-communication product. After sign-in, the app opens on Kislap Home, where the reviewer can access Batch Forward, Peek Mode, Stealth Mode and Nearby Learning before entering general chats or calls.

Suggested path:
1. Sign in with `[REVIEW_PHONE]`; verification arrives by `[SMS]`.
2. Enable Peek Mode and open the prepared unread test conversation. Peek pauses automatic read advancement from this client; manual Mark as Read remains available.
3. Start a one-hour Stealth session. This client pauses typing, sticker-selection, voice-recording and instant-video activity signals while local input and recording continue.
4. Open Batch Forward, select multiple prepared messages and destinations, review the batch, send it, and inspect per-destination progress and results. The existing content restrictions, destination permissions, paid-message checks and rate limits still apply.
5. Open Nearby Learning, sign in with `[REVIEW_EMAIL]`, enable approximate-area visibility, open a real profile, and inspect Connect, Report and Block.
6. Messages, groups, voice calls and video calls remain available from the Communication section.

Kislap uses open-source communication components, disclosed in the in-app acknowledgements and source notices. The Kislap Home, batch workflow, privacy modes, learning account, learning profiles, Nearby privacy model, connections and moderation flows are Kislap-specific.

## Evidence required before submission

- [ ] Screenshot: Kislap Home as the first authenticated screen
- [ ] Screenshot: Batch Forward review with real test destinations
- [ ] Screenshot: Batch progress/results screen
- [ ] Screenshot: Peek and timed Stealth controls
- [ ] Screenshot: Nearby Learning privacy state
- [ ] Screenshot: real learning profile with Connect, Report and Block
- [ ] Video: 60–90 second first-minute reviewer path
- [ ] Test log: two-account Peek and Stealth verification
- [ ] Test log: Batch private chat, group, protected-content and cancel-pending cases
- [ ] Test log: voice/video/background/lock-screen call regression
- [ ] OTP delivery timestamps for both review accounts
