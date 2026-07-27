#!/usr/bin/env bash
# Fast install of the GrokTerm CLI from the *releases* repo (binaries only).
#
# Source is private. Binaries live in daniel-farina/grokterm-releases.
#
#   export GITHUB_TOKEN=ghp_...   # required while releases repo is private
#   curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
#     https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
#
# Env:
#   GROKTERM_VERSION   pin a release tag (default: latest)
#   GROKTERM_INSTALL   install dir (default: ~/.local/bin)
#   GROKTERM_REPO      owner/repo (default: daniel-farina/grokterm-releases)
#   GITHUB_TOKEN / GH_TOKEN  required for private releases repo
set -euo pipefail

REPO="${GROKTERM_REPO:-daniel-farina/grokterm-releases}"
INSTALL_DIR="${GROKTERM_INSTALL:-$HOME/.local/bin}"
VERSION="${GROKTERM_VERSION:-latest}"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
  arm64|aarch64) ARCH="aarch64" ;;
  x86_64|amd64)  ARCH="x86_64" ;;
  *)
    echo "error: unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

case "$OS" in
  darwin) TARGET="${ARCH}-apple-darwin" ;;
  linux)  TARGET="${ARCH}-unknown-linux-gnu" ;;
  *)
    echo "error: unsupported OS: $OS" >&2
    exit 1
    ;;
esac

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: need '$1' on PATH" >&2
    exit 1
  }
}
need curl
need tar
need mktemp
need python3

TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
auth_header=()
if [[ -n "$TOKEN" ]]; then
  auth_header=(-H "Authorization: Bearer ${TOKEN}")
else
  echo "warning: GITHUB_TOKEN/GH_TOKEN unset — private releases require a token" >&2
fi

api="https://api.github.com/repos/${REPO}/releases"
if [[ "$VERSION" == "latest" ]]; then
  release_json="$(curl -fsSL "${auth_header[@]}" \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: GrokTerm-install" \
    "${api}/latest")"
else
  # Accept v0.1.4 or 0.1.4
  tag="$VERSION"
  [[ "$tag" == v* ]] || tag="v${tag}"
  release_json="$(curl -fsSL "${auth_header[@]}" \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: GrokTerm-install" \
    "${api}/tags/${tag}")"
fi

# Prefer a prebuilt CLI tarball: grokterm-<ver>-<target>.tar.gz
# For private repos, use the API asset URL (needs Accept: application/octet-stream).
read -r asset_id asset_name asset_url < <(printf '%s' "$release_json" | python3 -c "
import json,sys
data=json.load(sys.stdin)
assets=data.get('assets') or []
target='${TARGET}'
chosen=None
for a in assets:
    n=a.get('name','')
    if n.endswith(target + '.tar.gz') and n.startswith('grokterm-'):
        chosen=a; break
if not chosen:
    for a in assets:
        n=a.get('name','')
        if 'grokterm' in n and n.endswith('.tar.gz') and target.split('-')[0] in n:
            chosen=a; break
if not chosen:
    sys.exit(1)
print(chosen.get('id',''), chosen.get('name',''), chosen.get('url') or chosen.get('browser_download_url',''))
" 2>/dev/null || true)

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

if [[ -z "${asset_id:-}" && -z "${asset_url:-}" ]]; then
  echo "error: no prebuilt CLI tarball for ${TARGET} in ${REPO} releases" >&2
  echo "       (source is private — binaries only from grokterm-releases)" >&2
  exit 1
fi

echo "==> Downloading GrokTerm CLI (${TARGET}) from ${REPO}…"
# API asset endpoint works for private repos with a token.
if [[ -n "${asset_id:-}" && "$asset_id" != "None" ]]; then
  curl -fsSL "${auth_header[@]}" \
    -H "Accept: application/octet-stream" \
    -H "User-Agent: GrokTerm-install" \
    -L \
    -o "$tmpdir/grokterm.tgz" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}"
else
  curl -fsSL "${auth_header[@]}" -L -o "$tmpdir/grokterm.tgz" "$asset_url"
fi

tar -xzf "$tmpdir/grokterm.tgz" -C "$tmpdir"
bin="$(find "$tmpdir" -type f -name grokterm | head -1)"
if [[ -z "$bin" ]]; then
  echo "error: archive did not contain grokterm binary" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
install -m 755 "$bin" "$INSTALL_DIR/grokterm"

echo "==> Installed: $INSTALL_DIR/grokterm"
"$INSTALL_DIR/grokterm" --version 2>/dev/null || true

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "Add to PATH (zsh):"
    echo "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    ;;
esac

echo ""
echo "GrokTerm — created by Daniel Farina · https://x.com/daniel_farinax"
echo "Binaries: https://github.com/${REPO}/releases"
echo "Run:  grokterm"
echo "      grokterm --voice"
echo "      grokterm --grok"
