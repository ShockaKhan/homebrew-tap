# homebrew-tap

[![tests](https://github.com/ShockaKhan/homebrew-tap/actions/workflows/tests.yml/badge.svg)](https://github.com/ShockaKhan/homebrew-tap/actions/workflows/tests.yml)
[![autobump](https://github.com/ShockaKhan/homebrew-tap/actions/workflows/autobump.yml/badge.svg)](https://github.com/ShockaKhan/homebrew-tap/actions/workflows/autobump.yml)

Linux desktop apps for [Homebrew](https://brew.sh), installed from the vendors' official packages without root. Built for immutable distros such as Bluefin and Bazzite.

```sh
brew tap shockakhan/tap
brew install --cask shockakhan/tap/<name>
```

| Cask | App | Run | Arch |
| --- | --- | --- | --- |
| `chatgpt-linux` | ChatGPT | `chatgpt` | x86_64, arm64 |
| `claude-desktop-linux` | Claude (beta) | `claude-desktop` | x86_64, arm64 |
| `thorium-reader-linux` | Thorium Reader | `thorium-reader` | x86_64, arm64 |
| `paseo-linux` | Paseo | `paseo-desktop`, `paseo` | x86_64 |
| `omp-desktop` | OMP Desktop (needs `brew install can1357/tap/omp`) | `omp-desktop /path` | x86_64 |
| `opencodex` | OpenCodex desktop | `opencodex-desktop` | x86_64 |
| `opencodex-cli` | OpenCodex CLI and proxy | `ocx`, `opencodex` | x86_64, arm64 |
| `emacs-pgtk-linux` | Desktop entries for the Emacs formula | | x86_64, arm64 |

| Formula | App | Arch |
| --- | --- | --- |
| `emacs` | GNU Emacs: Wayland (PGTK), native compilation, tree-sitter. Prebuilt bottles. Optional daemon: `brew services start shockakhan/tap/emacs` | x86_64, arm64 |

Update with `brew update && brew upgrade`. Uninstalling keeps your app data; `brew uninstall --zap` removes what each cask lists.

## How it works

Casks extract the vendor's `.deb`, AppImage or tarball into the Caskroom. Maintainer scripts never run, nothing is written outside `$HOME` and the Homebrew prefix, and `.desktop` entries are rewritten to point at Homebrew's `bin`.

- **`tests`**: on every PR and push. Style and `readall` for the whole tap, `brew audit` and an install, verify and uninstall run for each changed cask (both architectures where supported). GUI apps are also launched under Xvfb and must open a window.
- **`autobump`**: daily. Finds outdated casks with `brew livecheck`, rewrites version and checksums from the real downloads with `brew bump-cask-pr`, runs the same install check, and commits to `main`. If the check fails it opens a PR instead and never touches `main`.
- **Emacs** is bumped by hand: change `Formula/emacs.rb` in a PR, let `validate-emacs` build and test the bottles, then run **Publish tested Emacs bottles**.

Local check before a PR:

```sh
brew style Casks Formula && brew audit --cask --strict shockakhan/tap/<name>
python3 .github/ci/check_cask.py <name>   # installs, verifies, uninstalls
```
