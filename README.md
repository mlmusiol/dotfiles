![!CI](https://github.com/mlmusiol/dotfiles/actions/workflows/installer-full.yml/badge.svg)
# Installation 

1. Install [chezmoi](https://www.chezmoi.io/install/)
2.  Run chezmoi init https://github.com/mlmusiol/dotfiles.git --apply

    chezmoi will run the installation script automatically on Windows / MacOS

# Updating dotfiles

## If you edited files inside the chezmoi source directory

```sh
chezmoi cd
```

Edit files there, then apply them to your system:

```sh
chezmoi apply
```

Commit and push afterwards.

---

## If you edited real system config files directly

Example:

- `~/.config/nvim`
- `~/.wezterm.lua`
- `~/.config/powershell/profile.ps1`

Sync the changes back into chezmoi:

```sh
chezmoi re-add
```

Then commit and push from:

```sh
chezmoi cd
```
# CI
GitHub Actions runs full installer tests on macOS and Windows (.github/workflows/installer-full.yml).
