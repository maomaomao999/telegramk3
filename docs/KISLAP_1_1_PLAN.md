# Kislap 1.1 Development Plan

Status: active development  
Base: submitted App Store build `1.0 (100002)`  
Development branch: `kislap/1.1`  
Frozen reference: `kislap/1.0-submitted-100002`

## Product boundary

- Learning and skill exchange remains the primary experience (about 70%).
- Dating remains a separate, mutual opt-in experience (about 30%).
- Telegram messaging, groups and calls stay intact.
- Production APIs must remain backward compatible with Kislap 1.0 while it is in review.
- Production Nearby displays real users only. Review/demo profiles must remain visibly labelled and excluded from Dating.

## P0 — Profile and trust foundation

### 0. App Review 4.3(a) differentiation

- [x] Preserve build `1.0 (100002)` and request clarification/reconsideration in App Store Connect.
- [x] Confirm this App Store Connect account currently lists only Kislap.
- [x] Make Kislap Nearby Learning the default post-login destination instead of Telegram Chats.
- [x] Add a clearly branded learning home hierarchy: Learn, Teach, Connect.
- [x] Ensure the first review session exposes profile, skill matching, Nearby and safety without relying on Telegram navigation.
- [x] Replace the Telegram chat placeholder on the iPad learning landing state with Kislap learning guidance.
- [x] Replace remaining Telegram-first App Store screenshots and review copy with Kislap learning workflows.
- [x] Prepare an annotated App Review walkthrough and 4.3(a)-specific Review Notes.
- [ ] Record the 45–60 second real-device review walkthrough for the next submission.

Acceptance:

- A normal authenticated launch opens the Kislap learning experience.
- The first minute presents at least three Kislap-owned actions and does not resemble a renamed Telegram chat list.
- Telegram messages, groups and calls remain available as connected communication capabilities.
- Review Notes identify the exact path to Kislap account, profile, Nearby, Connect, Report and Block.
- Store screenshots and metadata describe one learning/skill-exchange product rather than a general Telegram client.

### 1. Learning partner profile sheet

- [x] Add a Telegram-themed profile sheet opened from each Nearby card.
- [x] Show avatar, verification, activity, approximate area, biography and learning/teaching roles.
- [x] Keep Connect and Safety actions reachable inside the sheet.
- [x] Add English and Simplified Chinese copy.
- [x] Build the unsigned/no-extensions App Store target with the full Bazel dependency graph.
- [ ] Verify light, dark, large text, iPhone and iPad layouts.

Acceptance:

- Selecting the chevron on a Nearby card opens the sheet without triggering Connect.
- Exact coordinates and addresses never appear.
- Demo/review profiles remain explicitly labelled.
- Connect, Report and Block retain their 1.0 server behavior.

### 2. Profile photo capture and management

- [x] Add Camera and Photo Library entry points to the owner's Learning Profile.
- [x] Add permission copy and denied-permission recovery.
- [x] Crop to a square, normalize orientation, resize and compress before upload.
- [x] Strip EXIF/GPS metadata on device; retain the server-side Sharp metadata scrub.
- [ ] Add upload progress, retry, cancel, delete and Make Main states.
- [ ] Enable the production upload feature flag only after private OSS validation.

Acceptance:

- Images are private in OSS and read through short-lived signed URLs.
- File type, decoded dimensions and size limits are enforced on both client and server.
- Deleting a main image selects a deterministic replacement.
- A failed upload never leaves a profile pointing at a missing object.

### 3. Nearby filters and privacy

- [ ] Add distance, skill, availability, language and online-status filters.
- [ ] Keep one-hour visibility and approximate distance buckets.
- [ ] Add empty, loading, offline, retry and permission states.
- [ ] Persist only non-sensitive filter preferences on device.

Acceptance:

- Filters are reflected in API queries and reset predictably.
- Results never expose raw latitude/longitude.
- Blocking removes the profile immediately and from subsequent API results.

### 4. Moderation loop

- [ ] Expand report reasons and add optional context.
- [ ] Confirm photo reports enter the existing moderation queue.
- [ ] Add appeal status visibility and support routing.
- [ ] Record moderation SLA evidence without exposing internal tokens.

## P1 — Learning engagement

- [ ] Study invitations with topic, goal and suggested time.
- [ ] Learning-first icebreakers and quick greetings.
- [ ] Favorites, recent partners and connection history.
- [ ] Session reminders using local notifications.
- [ ] Clearly labelled Kislap Guide onboarding; no unlabelled synthetic nearby users.

## P1 — Optional Dating (about 30%)

- [ ] Keep Dating off by default and outside the primary Nearby learning flow.
- [ ] Require mutual Dating opt-in before Dating requests are available.
- [ ] Preserve learning/report/block behavior when Dating is disabled.
- [ ] Review copy and screenshots so education remains the dominant store positioning.

## Deferred beyond 1.1

- Paid memberships and teacher settlement.
- Course booking and marketplace payouts.
- Public classroom voice rooms and recording.
- Filipino localization.

## Release gates

- [ ] 1.0 review feedback, if any, is fixed only on the frozen release line and then forward-merged.
- [ ] Backend schema/API changes are additive and compatible with 1.0.
- [ ] Swift build, backend lint/typecheck/tests and production preflight pass.
- [ ] Real-device Nearby, photo, Connect, Report, Block and account deletion regression passes.
- [ ] App Privacy, permission strings, screenshots and Review Notes are updated for photo collection.
- [ ] TestFlight 1.1 smoke test passes before App Store submission.
