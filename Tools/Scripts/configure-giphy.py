"""Bundle Giphy client configuration without committing the deployment key."""

import os
from pathlib import Path
import plistlib
import shlex


def configured_key():
    key = os.environ.get("GIPHY_API_KEY", "").strip()
    if not key:
        config = Path(os.environ.get("SYNDICATE_RELEASE_ENV", "~/.config/syndicate/release.env")).expanduser()
        if config.is_file():
            for line in config.read_text().splitlines():
                parts = shlex.split(line, comments=True)
                if parts and parts[0] == "export":
                    parts.pop(0)
                if len(parts) == 1 and parts[0].startswith("GIPHY_API_KEY="):
                    key = parts[0].split("=", 1)[1].strip()
    return key


def main():
    key = configured_key()
    if not key and os.environ.get("CONFIGURATION") == "Release":
        raise SystemExit("error: GIPHY_API_KEY missing; refusing a release with GIFs disabled.")
    destination = Path(os.environ["TARGET_BUILD_DIR"]) / os.environ["UNLOCALIZED_RESOURCES_FOLDER_PATH"] / "SyndicateServices.plist"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(plistlib.dumps({"GiphyAPIKey": key} if key else {}, fmt=plistlib.FMT_BINARY))
    print("Giphy configured." if key else "warning: Giphy unavailable in this development build.")


if __name__ == "__main__":
    main()
