# GrokTerm Releases

**Binaries only.** Application source is private and not open source.

| Asset | Notes |
|-------|--------|
| `GrokTerm-*-macos-arm64.dmg` | Notarized macOS app (Apple Silicon) |
| `GrokTerm.dmg` | Same DMG, stable name for links |
| `grokterm-*-aarch64-apple-darwin.tar.gz` | CLI tarball for `install.sh` |

## Install CLI

```bash
# Private repo — pass a GitHub token with `contents:read` on this repo:
export GITHUB_TOKEN=ghp_...   # or GH_TOKEN
curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/daniel-farina/grokterm-releases/main/install.sh | bash
```

Or download a DMG from [Releases](https://github.com/daniel-farina/grokterm-releases/releases).

Created by [Daniel Farina](https://x.com/daniel_farinax) · MIT license on binaries as published.
