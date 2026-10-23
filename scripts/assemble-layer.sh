#!/usr/bin/env bash
# Builds layer.tar: the files added on top of Windows Server Core LTSC 2022, laid out relative to C:\.
#   C:\MinGit                                                   portable Git for Windows (core.longpaths = true)
#   C:\Program Files\WindowsPowerShell\Modules\Pester\<ver>     Pester (AllUsers module path)
#   C:\Program Files\WindowsPowerShell\Modules\PSScriptAnalyzer\<ver>
# Every download is checked against versions.env before it is used. No Windows machine is needed: crane append turns
# the tar into a Windows layer when the base image is a Windows image.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$here/versions.env"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
root="$work/root"
mkdir -p "$root/MinGit" "$root/Program Files/WindowsPowerShell/Modules"

curl -fsSL -o "$work/mingit.zip" "$MINGIT_URL"
echo "$MINGIT_SHA256  $work/mingit.zip" | sha256sum -c -
python3 -I -m zipfile -e "$work/mingit.zip" "$root/MinGit"
printf '[core]\n\tlongpaths = true\n' >> "$root/MinGit/etc/gitconfig"

module() {  # name version expected-sha512-base64
    local name="$1" version="$2" expected="$3" pkg="$work/$1.nupkg" dest
    curl -fsSL -o "$pkg" "https://www.powershellgallery.com/api/v2/package/$name/$version"
    local actual
    actual="$(openssl dgst -sha512 -binary "$pkg" | base64 -w0)"
    if [ "$actual" != "$expected" ]; then echo "$name $version: SHA-512 mismatch ($actual)" >&2; exit 1; fi
    dest="$root/Program Files/WindowsPowerShell/Modules/$name/$version"
    mkdir -p "$dest"
    python3 -I -m zipfile -e "$pkg" "$dest"
    # NuGet packaging files are not part of the module.
    rm -rf "$dest/_rels" "$dest/package" "$dest/[Content_Types].xml" "$dest/$name.nuspec"
}
module Pester "$PESTER_VERSION" "$PESTER_SHA512_B64"
module PSScriptAnalyzer "$PSSA_VERSION" "$PSSA_SHA512_B64"

tar -C "$root" --owner=0 --group=0 --numeric-owner -cf "${1:-$here/layer.tar}" .
echo "layer: $(du -h "${1:-$here/layer.tar}" | cut -f1)"
