# App Store Submission

## Candidate

- Version: `0.1.0`
- Build: `14`
- Bundle ID: `app.syn.messenger`
- App Store Connect app ID: `6809166852`
- Release: manually release after approval
- Primary category: Social Networking

Build 14 is valid and App Store eligible. It is selected on the `0.1.0` App Store version.

## Published metadata

- Name: SYN Messenger
- Subtitle: Matrix chat on phone & watch
- Marketing URL: https://synmessenger.com/
- Support URL: https://synmessenger.com/support.html
- Privacy policy: https://synmessenger.com/privacy.html
- Copyright: 2026 SYN Messenger
- Keywords: matrix,messenger,chat,encryption,watch,secure,private,federated,messaging

The App Store description and promotional text are populated in App Store Connect.

## Public web verification

- Homepage, privacy policy, support, terms, and logo return HTTP 200 over valid TLS.
- `/.well-known/apple-app-site-association` returns HTTP 200 as `application/json` without a redirect.
- The association file includes the app identifier `S6BUVDCKVJ.app.syn.messenger` and the Matrix OAuth callback path.

## Privacy questionnaire source of truth

The bundled privacy manifest declares no tracking and identifies these data types for app functionality or analytics:

- Linked: email address, precise location, user ID, device ID, and other diagnostic data.
- Not linked: contacts, photos or videos, audio data, product interaction, crash data, and performance data.

Confirm the App Store Connect privacy questionnaire matches the current manifest before submission.

## Remaining submission gates

- Complete the App Store age-rating questionnaire. Messaging/chat and user-generated content apply.
- Complete and publish the App Privacy nutrition labels.
- Add App Review contact information and a working generic Matrix review account. Do not commit review credentials.
- Capture and upload App Store screenshots using synthetic Matrix rooms, users, and messages only.
- Confirm content-rights declaration and free worldwide availability.
- Confirm the support alias receives a test message.
- Run the final privacy scan and signed archive validation if the candidate changes after Build 14.
- Obtain Dakota's explicit approval immediately before submitting for App Review.
