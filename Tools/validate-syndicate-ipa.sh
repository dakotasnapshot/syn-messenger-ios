#!/bin/sh
set -eu

ipa_path="${1:?usage: $0 path/to/Syndicate.ipa}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

unzip -q "$ipa_path" -d "$work_dir"
app_path="$work_dir/Payload/Syndicate.app"

test -d "$app_path" || {
    echo "error: IPA payload is not Syndicate.app" >&2
    find "$work_dir/Payload" -maxdepth 1 -type d -print >&2
    exit 1
}

plist="$app_path/Info.plist"
bundle_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$plist")"
display_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$plist")"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")"

test "$bundle_name" = "Syndicate"
test "$display_name" = "Syndicate"
test "$bundle_id" = "app.syn.messenger"

if find "$app_path" -maxdepth 2 \( -name 'ElementX.app' -o -name 'Element X.app' \) | grep -q .; then
    echo "error: legacy Element app bundle found in IPA" >&2
    exit 1
fi

echo "Validated Syndicate IPA: $ipa_path"
