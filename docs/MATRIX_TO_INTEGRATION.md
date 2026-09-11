# Matrix.to integration

SYN Messenger is ready for inclusion in the Matrix.to client directory.

## Identity

- Name: SYN Messenger
- Website: https://synmessenger.com
- Author: SYN Messenger
- Description: Secure private messaging on the Matrix network.
- Icon: `Website/public/logo.svg`

## Apple application

- Platform: iOS
- App Store ID: `6809166852`
- Bundle ID: `app.syn.messenger`
- Associated application ID: `S6BUVDCKVJ.app.syn.messenger`
- Associated domain entitlement: `applinks:matrix.to`

SYN parses Matrix user, room, room-alias, and event permalinks. Matrix.to must include the associated application ID in its Apple App Site Association file before iOS can route Matrix.to Universal Links directly to SYN.

## Source repositories

- iOS and watchOS: https://github.com/dakotasnapshot/syn-messenger-ios
- Android: https://github.com/dakotasnapshot/syn-messenger-android
- Desktop: https://github.com/dakotasnapshot/syn-messenger-desktop

SYN Messenger is based on Element X and preserves upstream attribution and licensing. SYN is not affiliated with or endorsed by Element or the Matrix.org Foundation.
