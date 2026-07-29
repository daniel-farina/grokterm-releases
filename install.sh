#!/usr/bin/env bash
# Fast install of the GrokTerm CLI from the public releases repo (binaries only).
#
#   curl -fsSL https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
#
# Env:
#   GROKTERM_VERSION   pin a release tag (default: latest), e.g. v0.1.16
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

# Exact triple only — never fall back to another OS (e.g. apple-darwin on Linux).
choose_out="$(printf '%s' "$release_json" | TARGET="$TARGET" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
assets = data.get("assets") or []
target = os.environ["TARGET"]
suffix = "-" + target + ".tar.gz"
available = []
chosen = None
for a in assets:
    n = a.get("name") or ""
    if n.endswith(".tar.gz") and n.startswith("grokterm-"):
        available.append(n)
    if n.endswith(suffix) and n.startswith("grokterm-"):
        chosen = a
        break
if not chosen:
    print("error: no asset ending with " + suffix, file=sys.stderr)
    print("available grokterm tarballs:", file=sys.stderr)
    for n in available or ["(none)"]:
        print("  " + n, file=sys.stderr)
    print("See https://github.com/daniel-farina/grokterm-releases/releases", file=sys.stderr)
    sys.exit(1)
print(
    chosen.get("id", ""),
    chosen.get("name", ""),
    chosen.get("browser_download_url") or chosen.get("url", ""),
)
')" || {
  echo "error: failed to select CLI asset for ${TARGET}" >&2
  exit 1
}

read -r asset_id asset_name asset_url <<<"$choose_out"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

echo "==> Downloading ${asset_name} (${TARGET}) from ${REPO}…"
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
  echo "error: no download URL for ${asset_name}" >&2
  exit 1
fi

tar -xzf "$tmpdir/grokterm.tgz" -C "$tmpdir"
bin="$(find "$tmpdir" -type f -name grokterm | head -1)"
if [[ -z "$bin" ]]; then
  echo "error: archive did not contain grokterm binary" >&2
  exit 1
fi

# Sanity: refuse wrong OS binary formats.
if command -v file >/dev/null 2>&1; then
  ft="$(file -b "$bin" || true)"
  case "$OS" in
    linux)
      if echo "$ft" | grep -qiE 'Mach-O|Darwin'; then
        echo "error: downloaded a macOS binary on Linux (${ft})" >&2
        echo "  asset was: ${asset_name}" >&2
        exit 1
      fi
      ;;
    darwin)
      if echo "$ft" | grep -qiE 'ELF|Linux'; then
        echo "error: downloaded a Linux binary on macOS (${ft})" >&2
        exit 1
      fi
      ;;
  esac
fi

mkdir -p "$INSTALL_DIR"
install -m 755 "$bin" "$INSTALL_DIR/grokterm"

echo "==> Installed: $INSTALL_DIR/grokterm"
if ! "$INSTALL_DIR/grokterm" --version; then
  echo "error: installed binary failed to run (wrong arch/OS?)" >&2
  file "$INSTALL_DIR/grokterm" 2>/dev/null || true
  exit 1
fi

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
