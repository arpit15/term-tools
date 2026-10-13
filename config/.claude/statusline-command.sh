#!/usr/bin/env bash
# Claude Code status line — mirrors p10k left: dir + git, right: model + context
input=$(cat)

# --- directory ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
home="$HOME"
display_dir="${cwd/#$home/~}"

# --- git branch (skip optional lock to avoid contention) ---
git_branch=""
if git_dir=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --git-dir 2>/dev/null); then
  git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# --- model (short form) ---
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')

# --- context remaining ---
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# --- assemble ---
# Left segment: dir [branch]
left=$(printf '\033[34m%s\033[0m' "$display_dir")
if [ -n "$git_branch" ]; then
  left="$left $(printf '\033[33m(%s)\033[0m' "$git_branch")"
fi

# Right segment: model | ctx
right=""
if [ -n "$model" ]; then
  right=$(printf '\033[36m%s\033[0m' "$model")
fi
if [ -n "$remaining" ]; then
  ctx_color='\033[32m'
  remaining_int=$(printf '%.0f' "$remaining")
  if [ "$remaining_int" -lt 20 ]; then
    ctx_color='\033[31m'
  elif [ "$remaining_int" -lt 40 ]; then
    ctx_color='\033[33m'
  fi
  ctx_str=$(printf "${ctx_color}ctx:%s%%\033[0m" "$remaining_int")
  if [ -n "$right" ]; then
    right="$right $(printf '\033[90m|\033[0m') $ctx_str"
  else
    right="$ctx_str"
  fi
fi

# --- rate limits (5h / weekly) ---
fmt_limit() {
  # $1 label, $2 used_percentage, $3 resets_at (epoch s), $4 date format
  [ -z "$2" ] && return
  local pct reset="" out
  pct=$(printf '%.0f' "$2" 2>/dev/null) || return
  if [ -n "$3" ]; then
    reset=$(date -r "${3%.*}" "+$4" 2>/dev/null)
  fi
  out="$1: ${pct}%"
  [ -n "$reset" ] && out="$out (resets $reset)"
  local color='\033[32m'
  if [ "$pct" -ge 80 ]; then color='\033[31m'; elif [ "$pct" -ge 50 ]; then color='\033[33m'; fi
  printf "${color}%s\033[0m" "$out"
}
IFS='|' read -r five_pct five_reset week_pct week_reset < <(
  echo "$input" | jq -r '[.rate_limits.five_hour.used_percentage // "", .rate_limits.five_hour.resets_at // "", .rate_limits.seven_day.used_percentage // "", .rate_limits.seven_day.resets_at // ""] | map(tostring) | join("|")' 2>/dev/null
)
limits=""
five_str=$(fmt_limit "5h" "$five_pct" "$five_reset" "%H:%M")
week_str=$(fmt_limit "wk" "$week_pct" "$week_reset" "%a %H:%M")
if [ -n "$five_str" ] && [ -n "$week_str" ]; then
  limits="$five_str $(printf '\033[90m·\033[0m') $week_str"
else
  limits="$five_str$week_str"
fi
if [ -n "$limits" ]; then
  if [ -n "$right" ]; then
    right="$right $(printf '\033[90m|\033[0m') $limits"
  else
    right="$limits"
  fi
fi

if [ -n "$right" ]; then
  printf "%b  %b" "$left" "$right"
else
  printf "%b" "$left"
fi
