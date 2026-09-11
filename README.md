# SYN Messenger

SYN Messenger is an independent, open-source Matrix client for iPhone and Apple Watch. It is based on Element X iOS and uses the Matrix Rust SDK.

## Status

Early development. iPhone messaging uses the full Matrix client. The Apple Watch companion mirrors a reduced conversation list and sends replies through the authenticated iPhone without copying Matrix credentials or encryption keys to the watch.

## Build

1. Install XcodeGen, SwiftGen, Sourcery, SwiftLint, and SwiftFormat.
2. Run `swift run tools setup-project`.
3. Open `ElementX.xcodeproj` and build the `ElementX` scheme.

See [CONTRIBUTING.md](CONTRIBUTING.md) for upstream development requirements and [docs/SYN_WATCH_ARCHITECTURE.md](docs/SYN_WATCH_ARCHITECTURE.md) for companion design.

## Support and security

General support and private vulnerability reports: [support@synmessenger.com](mailto:support@synmessenger.com). Never include passwords, access tokens, recovery keys, or private message content.

## Independence and attribution

SYN Messenger is not affiliated with or endorsed by Element. Matrix is an open standard for interoperable communication.

This project is based on [Element X iOS](https://github.com/element-hq/element-x-ios). Original portions are copyright © 2025–2026 Element Creations Ltd and copyright © 2022–2025 New Vector Ltd. SYN Messenger modifications are copyright © 2026 SYN Messenger contributors.

## License

Distributed under GNU Affero General Public License v3 or later. See [LICENSE](LICENSE). `LICENSE-COMMERCIAL` describes Element's separate commercial option and does not grant SYN Messenger a commercial license.
