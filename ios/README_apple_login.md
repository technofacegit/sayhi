# Apple Login Setup (iOS)

This document explains how to enable and verify **Sign in with Apple** for this app.

## 1) Apple Developer prerequisites

- Active Apple Developer account.
- App Identifier (Bundle ID) for this app exists in Apple Developer Portal.

## 2) Enable capability in Apple Developer Portal

1. Go to **Certificates, Identifiers & Profiles**.
2. Open the app's **Identifier** (Bundle ID must match this project).
3. Enable **Sign In with Apple** for that identifier.
4. Save changes.

## 3) Enable capability in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select `Runner` target.
3. Open **Signing & Capabilities** tab.
4. Click **+ Capability**.
5. Add **Sign In with Apple**.

## 4) Verify Signing values

- **Team** is correct.
- **Bundle Identifier** matches Apple Developer Portal App ID.
- Provisioning profile is valid and up to date.

If profiles are stale, re-resolve signing and rebuild.

## 5) Build and test

- Prefer testing on a real iPhone with iCloud logged in.
- Tap **Continue with Apple** on login screen.
- Ensure Apple auth sheet appears.
- After success, app should navigate to Home.

## 6) Expected behavior notes

- `email` and `fullName` are often provided only on the first authorization.
- Do not rely on these fields being present on every login.

## 7) Security recommendation (production)

- Verify Apple `identityToken` on backend before creating a session.
- Do not trust client-only authentication flow in production.

