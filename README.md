# GrokTerm Releases

**Binaries only.** Application source is not published in this repository.

| Asset | Notes |
|-------|--------|
| `GrokTerm-*-macos-arm64.dmg` / `GrokTerm.dmg` | Notarized macOS app (Apple Silicon) |
| `grokterm-*-aarch64-apple-darwin.tar.gz` | macOS CLI (Apple Silicon) |
| `grokterm-*-x86_64-apple-darwin.tar.gz` | macOS CLI (Intel) |
| `grokterm-*-x86_64-unknown-linux-gnu.tar.gz` | Linux CLI x86_64 |
| `grokterm-*-aarch64-unknown-linux-gnu.tar.gz` | Linux CLI arm64 |
| `grokterm-*-x86_64-pc-windows-msvc.zip` | **Windows CLI** (`grokterm.exe`) |
| `grokterm-app-*-x86_64-pc-windows-msvc.zip` | **Windows GUI** (`GrokTerm-App.exe`) |

## Install CLI with curl (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
```

Installs to `~/.local/bin`. Optional env:

| Variable | Default | Meaning |
|----------|---------|---------|
| `GROKTERM_VERSION` | `latest` | e.g. `v0.1.24` |
| `GROKTERM_INSTALL` | `~/.local/bin` | install directory |

## Install Windows

1. Open the [latest release](https://github.com/daniel-farina/grokterm-releases/releases/latest)
2. **GUI:** download `grokterm-app-*-x86_64-pc-windows-msvc.zip` → unzip → run `GrokTerm-App.exe`
3. **CLI:** download `grokterm-*-x86_64-pc-windows-msvc.zip` → put `grokterm.exe` on your `PATH`

## Install macOS app

1. Download `GrokTerm.dmg` (or versioned `GrokTerm-*-macos-arm64.dmg`)
2. Drag **GrokTerm** to **Applications**

Landing page: [https://grokterm.pages.dev](https://grokterm.pages.dev)

Created by [Daniel Farina](https://x.com/daniel_farinax) · MIT on published binaries.
