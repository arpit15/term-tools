#!/usr/bin/env bash
#
# Install oh-my-bash (https://github.com/ohmybash/oh-my-bash)
# but only when bash is the user's active login shell.
#
set -euo pipefail

OSH_DIR="${OSH:-$HOME/.oh-my-bash}"
OSH_THEME="${OSH_THEME:-powerline-multiline}"

is_bash_active_shell() {
	# Prefer the user's configured login shell (from the passwd database),
	# falling back to $SHELL if getent/dscl are unavailable.
	local login_shell=""

	if command -v getent >/dev/null 2>&1; then
		login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
	elif command -v dscl >/dev/null 2>&1; then
		# macOS
		login_shell="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}')"
	fi

	if [ -z "$login_shell" ]; then
		login_shell="${SHELL:-}"
	fi

	case "$(basename "$login_shell")" in
		bash) return 0 ;;
		*) return 1 ;;
	esac
}

# Set OSH_THEME="<theme>" in ~/.bashrc, replacing any existing assignment.
set_theme() {
	local bashrc="$HOME/.bashrc"
	[ -f "$bashrc" ] || return 0

	if grep -qE '^[[:space:]]*OSH_THEME=' "$bashrc" 2>/dev/null; then
		# Portable in-place edit (works on both GNU and BSD/macOS sed).
		local tmp
		tmp="$(mktemp)"
		sed -E "s|^[[:space:]]*OSH_THEME=.*|OSH_THEME=\"$OSH_THEME\"|" "$bashrc" >"$tmp"
		cat "$tmp" >"$bashrc"
		rm -f "$tmp"
	else
		printf '\nOSH_THEME="%s"\n' "$OSH_THEME" >>"$bashrc"
	fi
	echo "oh-my-bash: theme set to '$OSH_THEME'."
}

main() {
	if ! is_bash_active_shell; then
		echo "oh-my-bash: active login shell is not bash; skipping install." >&2
		exit 0
	fi

	if ! command -v git >/dev/null 2>&1; then
		echo "oh-my-bash: git is required but not installed." >&2
		exit 1
	fi

	if [ -d "$OSH_DIR" ]; then
		echo "oh-my-bash: already installed at $OSH_DIR; updating..."
		git -C "$OSH_DIR" pull --ff-only || \
			echo "oh-my-bash: could not fast-forward update; leaving existing install untouched." >&2
		set_theme
		exit 0
	fi

	echo "oh-my-bash: cloning into $OSH_DIR ..."
	git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "$OSH_DIR"

	if [ ! -f "$HOME/.bashrc" ] || ! grep -q 'oh-my-bash' "$HOME/.bashrc" 2>/dev/null; then
		if [ -f "$OSH_DIR/templates/bashrc.osh-template" ]; then
			echo "oh-my-bash: installing default ~/.bashrc from template."
			[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.omb-backup.$(date +%s)"
			cp "$OSH_DIR/templates/bashrc.osh-template" "$HOME/.bashrc"
		fi
	fi

	set_theme

	echo "oh-my-bash: done. Restart bash or run: source ~/.bashrc"
}

main "$@"
