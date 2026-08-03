#!/usr/bin/env bash
#
# Install TPM (Tmux Plugin Manager, https://github.com/tmux-plugins/tpm)
# and the plugins declared in config/.tmux.conf.
#
set -euo pipefail

TPM_DIR="${TPM_DIR:-$HOME/.tmux/plugins/tpm}"

# Location of this repo's tmux config, used to seed ~/.tmux.conf if missing.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_TMUX_CONF="$SCRIPT_DIR/../config/.tmux.conf"
USER_TMUX_CONF="$HOME/.tmux.conf"

main() {
	for cmd in git tmux; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo "tmux-plugins: '$cmd' is required but not installed." >&2
			exit 1
		fi
	done

	# Ensure ~/.tmux.conf exists so TPM has plugin declarations to read.
	if [ ! -f "$USER_TMUX_CONF" ]; then
		if [ -f "$REPO_TMUX_CONF" ]; then
			echo "tmux-plugins: linking $USER_TMUX_CONF -> $REPO_TMUX_CONF"
			ln -s "$(cd "$(dirname "$REPO_TMUX_CONF")" && pwd)/$(basename "$REPO_TMUX_CONF")" "$USER_TMUX_CONF"
		else
			echo "tmux-plugins: no ~/.tmux.conf found and repo config missing." >&2
			echo "tmux-plugins: create ~/.tmux.conf with your @plugin declarations first." >&2
			exit 1
		fi
	fi

	# Install / update TPM itself.
	if [ -d "$TPM_DIR/.git" ]; then
		echo "tmux-plugins: updating TPM at $TPM_DIR ..."
		git -C "$TPM_DIR" pull --ff-only || \
			echo "tmux-plugins: could not fast-forward TPM; continuing." >&2
	else
		echo "tmux-plugins: cloning TPM into $TPM_DIR ..."
		git clone --depth=1 https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
	fi

	# Install the plugins listed in the config, non-interactively.
	# TPM's helper scripts read the plugin list from the tmux config directly,
	# so this works without an attached tmux session.
	echo "tmux-plugins: installing plugins declared in $USER_TMUX_CONF ..."
	"$TPM_DIR/bin/install_plugins"

	echo "tmux-plugins: updating plugins to latest ..."
	"$TPM_DIR/bin/update_plugins" all || true

	echo "tmux-plugins: done."
	echo "tmux-plugins: reload inside tmux with: prefix + r  (or: tmux source-file ~/.tmux.conf)"
}

main "$@"
