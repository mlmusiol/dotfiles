# Installation

## (1) Prerequisites

* Git
* chezmoi
* GitHub CLI (`gh`) *(for private repo)*

## (2) Authenticate (private repo only)

```bash
gh auth login
```

## (3) Apply dotfiles

```bash
chezmoi init https://github.com/mlmusiol/dotfiles.git --apply
```

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
