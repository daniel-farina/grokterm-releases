# GrokTerm Releases

**Binaries only.** Application source is not published in this repository.

| Asset | Notes |
|-------|--------|
| `GrokTerm-*-macos-arm64.dmg` | Notarized macOS app (Apple Silicon) |
| `GrokTerm.dmg` | Same DMG, stable name for links |
| `grokterm-*-aarch64-apple-darwin.tar.gz` | CLI tarball used by `install.sh` |

## Install CLI with curl

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
```

Installs to `~/.local/bin`. Optional env:

| Variable | Default | Meaning |
|----------|---------|---------|
| `GROKTERM_VERSION` | `latest` | e.g. `v0.1.5` |
| `GROKTERM_INSTALL` | `~/.local/bin` | install directory |

```bash
# Pin version
export GROKTERM_VERSION=v0.1.5
curl -fsSL https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash

# PATH (zsh)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
grokterm --version
```

## Install macOS app

1. Open the latest [Release](https://github.com/daniel-farina/grokterm-releases/releases)
2. Download `GrokTerm-*-macos-arm64.dmg` or `GrokTerm.dmg`
3. Drag **GrokTerm** to **Applications**

Created by [Daniel Farina](https://x.com/daniel_farinax) · MIT on published binaries.
