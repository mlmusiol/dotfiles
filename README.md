![!CI](https://github.com/mlmusiol/dotfiles/actions/workflows/installer-full.yml/badge.svg)
# Installation

1. Install the dotfiles manager [chezmoi](https://www.chezmoi.io/install/)
2. Run:
   ```bash
   chezmoi init https://github.com/mlmusiol/dotfiles.git --apply
   ```
    `chezmoi` will run the installation script automatically on Windows / MacOS

# Updating dotfiles

If changes need to be done:
- edit files safely with `chezmoi edit <target-file>`
- apply edited file with `chezmoi apply <target-file>` (or all files with `chezmoi apply`)
- commit & push.

# Syncing dotfiles

Run `chezmoi update` to pull changes and apply from remote

# CI

GitHub Actions runs full installer tests on macOS and Windows (`.github/workflows/installer-full.yml`).
