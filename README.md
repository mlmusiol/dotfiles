# Installation

1. Install [chezmoi](https://www.chezmoi.io/install/)
2. Run `chezmoi init https://github.com/mlmusiol/dotfiles.git --apply`
   chezmoi will run the installation script automatically on Windows / MacOS

# Updating dotfiles

If changes were made, go to chezmoi root with `chezmoi cd`
add them with `chezmoi add <...>` and
commit & push.

# Syncing dotfiles

Run `chezmoi update`
