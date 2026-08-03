#!/usr/bin/env bash
#
# Install ble.sh (https://github.com/akinomyoga/ble.sh)
# a full-featured line editor / autosuggestion engine for bash.
#
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BLESH_SRC="${BLESH_SRC:-${TMPDIR:-/tmp}/ble.sh}"
BLESH_SOURCE_LINE='[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh'

main() {
	for cmd in git make; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo "ble.sh: '$cmd' is required but not installed." >&2
			exit 1
		fi
	done

	if [ -d "$BLESH_SRC/.git" ]; then
		echo "ble.sh: updating existing source at $BLESH_SRC ..."
		git -C "$BLESH_SRC" pull --ff-only
		git -C "$BLESH_SRC" submodule update --init --recursive
	else
		echo "ble.sh: cloning source into $BLESH_SRC ..."
		rm -rf "$BLESH_SRC"
		git clone --recursive --depth 1 --shallow-submodules \
			https://github.com/akinomyoga/ble.sh.git "$BLESH_SRC"
	fi

	echo "ble.sh: building and installing to $PREFIX ..."
	make -C "$BLESH_SRC" install PREFIX="$PREFIX"

	# Wire ble.sh into ~/.bashrc if not already present.
	if [ -f "$HOME/.bashrc" ] && grep -q 'blesh/ble.sh' "$HOME/.bashrc" 2>/dev/null; then
		echo "ble.sh: ~/.bashrc already sources ble.sh; leaving it as-is."
	else
		echo "ble.sh: adding source line to ~/.bashrc"
		{
			echo ''
			echo '# Load ble.sh (https://github.com/akinomyoga/ble.sh)'
			echo "$BLESH_SOURCE_LINE"
		} >> "$HOME/.bashrc"
	fi

	echo "ble.sh: done. Restart bash or run: source ~/.bashrc"
}

main "$@"
