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
