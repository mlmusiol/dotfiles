# Installation

## (1) Prerequisites

### Windows
* Git
* chezmoi
* GitHub CLI (`gh`) *(for private repo)*

### macOS
* Xcode Command Line Tools: `xcode-select --install`
* chezmoi: `brew install chezmoi` *(or see [chezmoi.io](https://www.chezmoi.io/install/))*
* GitHub CLI (`gh`) *(for private repo)*

## (2) Authenticate (private repo only)

```bash
gh auth login
```

## (3) Apply dotfiles

```bash
chezmoi init https://github.com/mlmusiol/dotfiles.git --apply
```

> Works on both **Windows** and **macOS**. The setup script automatically detects the OS and runs the appropriate installer (winget/scoop on Windows, Homebrew on macOS).

## (4) Update dotfiles

```bash
chezmoi update
```

## (5) Local changes

```bash
chezmoi add <file>
chezmoi cd
git add .
git commit -m "message"
git push
```
