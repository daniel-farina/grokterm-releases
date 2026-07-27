# GrokTerm Releases

**Binaries only.** Application source is private and not open source.

| Asset | Notes |
|-------|--------|
| `GrokTerm-*-macos-arm64.dmg` | Notarized macOS app (Apple Silicon) |
| `GrokTerm.dmg` | Same DMG, stable name for links |
| `grokterm-*-aarch64-apple-darwin.tar.gz` | CLI tarball used by `install.sh` |

## Install CLI with curl

Private repo — you need a GitHub token with **Contents: Read** on this repo.

```bash
export GITHUB_TOKEN=ghp_your_token_here

curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
```

Installs to `~/.local/bin`. Optional env:

| Variable | Default | Meaning |
|----------|---------|---------|
| `GROKTERM_VERSION` | `latest` | e.g. `v0.1.4` |
| `GROKTERM_INSTALL` | `~/.local/bin` | install directory |
| `GITHUB_TOKEN` / `GH_TOKEN` | — | required for private downloads |

```bash
# Pin version
export GITHUB_TOKEN=ghp_...
export GROKTERM_VERSION=v0.1.4
curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash

# PATH (zsh)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
grokterm --version
```

## Install macOS app

1. Open the latest [Release](https://github.com/daniel-farina/grokterm-releases/releases)
2. Download `GrokTerm-*-macos-arm64.dmg` or `GrokTerm.dmg`
3. Drag **GrokTerm** to **Applications**

Created by [Daniel Farina](https://x.com/daniel_farinax) · MIT on published binaries.
