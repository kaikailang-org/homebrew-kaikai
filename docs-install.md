# Installing kaikai

Three paths, in order of how much you want to invest.

## 1. From source (development)

```sh
git clone git@github.com:lnds/kaikai.git
cd kaikai
make
./bin/kai run examples/effects/hello.kai
```

`bin/kai` runs against the dev checkout: it detects `stage0/` and
`stdlib/` next to itself and uses those.

## 2. From a release tarball

Per-release tarballs are attached to GitHub Releases at
[lnds/kaikai/releases](https://github.com/lnds/kaikai/releases). They
contain a pre-compiled `kaic2` for one platform plus the stdlib and
runtime header.

Layout inside the tarball:

```
kaikai-v<version>-<os>-<arch>/
  bin/kai
  libexec/kaikai/kaic2
  share/kaikai/
    VERSION
    stdlib/
    include/runtime.h
  README.md
  LICENSE
```

Drop it anywhere that's on your `PATH`:

```sh
tar xzf kaikai-v0.40.0-darwin-arm64.tar.gz
sudo mv kaikai-v0.40.0-darwin-arm64 /opt/kaikai
sudo ln -s /opt/kaikai/bin/kai /usr/local/bin/kai
```

`bin/kai` detects the installed layout via its own location: when
`bin/kai` lives next to `libexec/kaikai/kaic2` and `share/kaikai/stdlib`,
it switches to "installed" mode automatically.

Override the stdlib root with `KAI_STDLIB=/path/to/stdlib` if you want
an installed binary to run against an experimental stdlib copy.

## 3. Via Homebrew (private tap)

The tap repo is private; `brew tap` uses SSH and `brew install` uses
your authenticated `gh`/`HOMEBREW_GITHUB_API_TOKEN` to fetch the
private release tarball.

```sh
brew tap lnds/kaikai git@github.com:lnds/homebrew-kaikai.git
brew install lnds/kaikai/kaikai
```

Smoke test:

```sh
echo 'fn main() : Unit / Console = print("hola brew")' > /tmp/h.kai
kai run /tmp/h.kai
```

Upgrade to a new version:

```sh
brew update
brew upgrade kaikai
```

## Environment variables

| Var               | Effect                                                |
|-------------------|-------------------------------------------------------|
| `KAI_NO_STDLIB=1` | Skip auto-loading stdlib preludes                     |
| `KAI_STDLIB`      | Override the stdlib root directory                    |
| `KAI_RUNTIME_INC` | Override the runtime header include dir               |

## Cutting a release (maintainer)

1. `cz bump --yes` — bumps VERSION, writes CHANGELOG, tags `v$version`.
2. `git push origin main && git push origin v<version>` — push branch
   and tag separately so the `release` workflow fires.
3. The workflow builds platform-specific tarballs and attaches them
   to the GitHub Release page.
4. Update `lnds/homebrew-kaikai/Formula/kaikai.rb`:
   - bump `version`
   - replace `sha256` with the new tarball checksum
   - commit + push
5. Anyone tapped runs `brew upgrade kaikai`.
