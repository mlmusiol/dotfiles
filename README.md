# Installation

1. Install [chezmoi](https://www.chezmoi.io/install/)
2. Run `chezmoi init https://github.com/mlmusiol/dotfiles.git --apply`
   chezmoi will run the installation script automatically on Windows / MacOS

# Updating dotfiles

If changes were made, go to chezmoi root with `chezmoi cd`
edit files with `chezmoi edit  <target-file>`
apply with `chezmoi apply <target-file>`
commit & push.

# Syncing dotfiles

Run `chezmoi update`

# CI

GitHub Actions runs full installer tests on macOS and Windows (`.github/workflows/installer-full.yml`).
