# homebrew-kaikai

Private Homebrew tap for the [kaikai](https://github.com/lnds/kaikai)
language.

## Install

```sh
brew tap lnds/kaikai git@github.com:lnds/homebrew-kaikai.git
brew install lnds/kaikai/kaikai
```

The tap is private. `brew tap` clones it via SSH using your local key;
`brew install` downloads the release tarball from `lnds/kaikai` using
your authenticated `gh` session (or `HOMEBREW_GITHUB_API_TOKEN`).

## Verify

```sh
echo 'fn main() : Unit / Console = print("hola brew")' > /tmp/h.kai
kai run /tmp/h.kai
```

## Update

When `kaikai` cuts a new version, update `Formula/kaikai.rb`:
- bump `version`
- replace `sha256` with the new tarball checksum (see the release page on
  `lnds/kaikai`)
- commit + push to this repo
- run `brew upgrade kaikai`

## Layout

The release tarball already follows brew's expected layout:

```
kaikai-v<version>-<os>-<arch>/
  bin/kai
  libexec/kaikai/kaic2
  share/kaikai/
    VERSION
    stdlib/...
    include/runtime.h
  README.md
  LICENSE
```

`bin/kai` does its own layout detection — when installed under brew it
resolves `share/kaikai/stdlib/` from the script's own location.
