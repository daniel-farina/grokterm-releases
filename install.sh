#!/usr/bin/env bash
# Fast install of the GrokTerm CLI from the public releases repo (binaries only).
#
#   curl -fsSL https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
#
# Env:
#   GROKTERM_VERSION   pin a release tag (default: latest), e.g. v0.1.5
#   GROKTERM_INSTALL   install dir (default: ~/.local/bin)
#   GROKTERM_REPO      owner/repo (default: daniel-farina/grokterm-releases)
#   GITHUB_TOKEN / GH_TOKEN  optional (higher rate limits)
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

# Portable curl wrapper: empty-array "${arr[@]}" fails under `set -u` on
# bash 3.2 (macOS /bin/bash) and some bash 4/5 configs.
gh_curl() {
  if [[ -n "$TOKEN" ]]; then
    curl -fsSL -H "Authorization: Bearer ${TOKEN}" "$@"
  else
    curl -fsSL "$@"
  fi
}

api="https://api.github.com/repos/${REPO}/releases"
if [[ "$VERSION" == "latest" ]]; then
  release_json="$(gh_curl \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: GrokTerm-install" \
    "${api}/latest")"
else
  tag="$VERSION"
  [[ "$tag" == v* ]] || tag="v${tag}"
  release_json="$(gh_curl \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: GrokTerm-install" \
    "${api}/tags/${tag}")"
fi

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
print(chosen.get('id',''), chosen.get('name',''), chosen.get('browser_download_url') or chosen.get('url',''))
" 2>/dev/null || true)

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

if [[ -z "${asset_url:-}" && -z "${asset_id:-}" ]]; then
  echo "error: no prebuilt CLI tarball for ${TARGET} in ${REPO} releases" >&2
  exit 1
fi

echo "==> Downloading GrokTerm CLI (${TARGET}) from ${REPO}…"
# Prefer public browser download URL; fall back to API asset endpoint.
if [[ -n "${asset_url:-}" && "$asset_url" == https://github.com/* ]]; then
  gh_curl -L -o "$tmpdir/grokterm.tgz" "$asset_url"
elif [[ -n "${asset_id:-}" && "$asset_id" != "None" ]]; then
  gh_curl \
    -H "Accept: application/octet-stream" \
    -H "User-Agent: GrokTerm-install" \
    -L \
    -o "$tmpdir/grokterm.tgz" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}"
else
  gh_curl -L -o "$tmpdir/grokterm.tgz" "$asset_url"
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
echo "Releases: https://github.com/${REPO}/releases"
echo "Run:  grokterm"
echo "      grokterm --voice"
echo "      grokterm --grok"

