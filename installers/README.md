# Installers

Idempotent shell scripts for setting up terminal tooling. Each script is safe to
re-run — it updates an existing install rather than failing or duplicating work,
and honors environment-variable overrides for its install paths.

Run any of them directly:

```sh
./installers/install-oh-my-bash.sh
./installers/install-ble-sh.sh
./installers/install-tmux-plugins.sh
```

## `install-oh-my-bash.sh`

Installs [oh-my-bash](https://github.com/ohmybash/oh-my-bash) — **only when bash
is your active login shell**. The shell is resolved from the passwd database
(`getent` on Linux, `dscl` on macOS), falling back to `$SHELL`. If bash is not
your login shell the script exits successfully without changing anything.

What it does:

- Clones oh-my-bash, or fast-forward-updates an existing install.
- Installs a default `~/.bashrc` from the oh-my-bash template if none references
  it (backing up any existing file first).
- Sets the theme to `powerline-multiline` in `~/.bashrc`, replacing any existing
  `OSH_THEME=` assignment.

| Variable    | Default             | Purpose                     |
| ----------- | ------------------- | --------------------------- |
| `OSH`       | `~/.oh-my-bash`     | Install directory           |
| `OSH_THEME` | `powerline-multiline` | Theme written to `~/.bashrc` |

Requires: `git`.

## `install-ble-sh.sh`

Installs [ble.sh](https://github.com/akinomyoga/ble.sh) — a full-featured line
editor and autosuggestion engine for bash.

What it does:

- Clones ble.sh with submodules (or updates an existing checkout).
- Builds and installs via `make install PREFIX=~/.local`.
- Appends an interactive-shell-guarded source line to `~/.bashrc` if not already
  present:
  ```sh
  [[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh
  ```

| Variable     | Default                  | Purpose               |
| ------------ | ------------------------ | --------------------- |
| `PREFIX`     | `~/.local`               | Install prefix        |
| `BLESH_SRC`  | `$TMPDIR/ble.sh`         | Source checkout path  |

Requires: `git`, `make`.

> **Using both oh-my-bash and ble.sh?** ble.sh should be sourced *before*
> oh-my-bash in `~/.bashrc` for them to cooperate. Run `install-oh-my-bash.sh`
> first, then `install-ble-sh.sh`.

## `install-tmux-plugins.sh`

Installs [TPM](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager) and the
plugins declared in [`../config/.tmux.conf`](../config/.tmux.conf) — currently
`tmux-resurrect` and `tmux-continuum`.

What it does:

- Ensures `~/.tmux.conf` exists, symlinking this repo's `config/.tmux.conf` if it
  is missing.
- Clones TPM into `~/.tmux/plugins/tpm` (or updates it) — matching the
  `run '~/.tmux/plugins/tpm/tpm'` line in the config.
- Runs TPM's `install_plugins` and `update_plugins all` non-interactively — no
  attached tmux session required.

Plugins added later under the `# more plugins will go here` line are picked up
automatically on the next run.

| Variable  | Default                 | Purpose            |
| --------- | ----------------------- | ------------------ |
| `TPM_DIR` | `~/.tmux/plugins/tpm`   | TPM install path   |

Requires: `git`, `tmux`.

> The config sets `@continuum-restore 'on'`, so `tmux-continuum` auto-restores
> your last saved session when the tmux server next starts.

After installing, reload inside tmux with `prefix + r` (prefix is remapped to
`C-a`), or `tmux source-file ~/.tmux.conf`.
