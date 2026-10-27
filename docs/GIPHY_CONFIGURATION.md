# Giphy build configuration

GIF attachment picker uses `GiphyConfiguration.apiKey`, loaded from app-bundled `SyndicateServices.plist`. `Tools/Scripts/configure-giphy.py` writes this resource during the main target's post-build phase, before code signing.

Set `GIPHY_API_KEY` in the build environment, or place it in `~/.config/syndicate/release.env`. Override the configuration file path with `SYNDICATE_RELEASE_ENV`. The parser reads assignments without executing shell code. Keep deployment values outside source control; never print keys in build logs. Like other client SDK configuration, the bundled value is accessible to app users, not a server-side secret.

Release builds fail if the key is absent. Development builds may omit it, which hides the GIF attachment item. Do not substitute a permanently enabled menu with an unconfigured SDK. Generated `Components/Secrets` is not the source for Giphy configuration.

Release acceptance: verify trending and search, select a GIF and reach the existing attachment preview, then verify the archived and exported app contain a nonempty configuration. Keep Giphy attribution and rating filtering. Publish only synthetic conversation screenshots.
