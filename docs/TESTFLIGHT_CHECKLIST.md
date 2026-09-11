# First TestFlight Checklist

## Local gates

- [x] iPhone Debug build succeeds.
- [x] watchOS Debug and Release builds succeed.
- [x] Unsigned iPhone Release archive succeeds.
- [x] Watch transport contract tests pass.
- [x] Paired iPhone and Apple Watch simulators launch both apps.
- [x] WatchConnectivity reports paired, installed, and reachable.
- [x] Public-source scan contains no private deployment data.
- [x] Signed Release archive succeeds with distribution profiles.

## Apple Developer gates

- [x] Register main app, notification service, share extension, watch app, and complication extension identifiers.
- [x] Register iPhone and watch app groups.
- [x] Enable Associated Domains, Communication Notifications, Push Notifications, and required keychain sharing.
- [x] Create or refresh distribution provisioning profiles.
- [x] Confirm App Store Connect app uses bundle ID `app.syn.messenger`.
- [x] Add privacy policy, support, marketing, and copyright metadata.
- [ ] Complete privacy nutrition labels and export-compliance answers.
- [ ] Add TestFlight description, test notes, contact, screenshots, and review credentials if required.

## Public web gates

- [x] Serve `synmessenger.com` with a valid matching TLS certificate.
- [x] Publish website pages and `logo.svg`.
- [x] Publish `.well-known/apple-app-site-association` as JSON without redirects.
- [x] Verify OAuth callback association for `app.syn.messenger`.

## Device acceptance

- [ ] Sign in to a generic Matrix account on physical iPhone.
- [ ] Confirm paired watch receives room snapshots without separate authentication.
- [ ] Send an online watch reply and confirm Matrix delivery.
- [ ] Queue an offline watch reply, reconnect phone, and confirm delivery.
- [ ] Confirm inline, circular, corner, and rectangular complications render and update.
- [ ] Confirm watch displays no Matrix tokens or encryption keys.

## Upload gate

- [ ] Obtain Dakota's explicit approval immediately before archive upload.
- [x] Upload build 1 to TestFlight.
- [x] Wait for processing, resolve validation issues, then invite Dakota.
