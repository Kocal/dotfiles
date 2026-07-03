#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' | LC_ALL=C awk '{printf "%.4f", $1}')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | LC_ALL=C awk '{printf "%.2f", $1}')

# git branch (skip optional locks)
branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)

# Session elapsed time from transcript file birth/creation time
elapsed_part=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  birth=$(stat -f %B "$transcript" 2>/dev/null)
  if [ -z "$birth" ] || [ "$birth" = "0" ]; then
    birth=$(stat -f %m "$transcript" 2>/dev/null)
  fi
  if [ -n "$birth" ]; then
    now=$(date +%s)
    elapsed=$(( now - birth ))
    h=$(( elapsed / 3600 ))
    m=$(( (elapsed % 3600) / 60 ))
    if [ "$h" -gt 0 ]; then
      elapsed_str="${h}h${m}m"
    else
      elapsed_str="${m}m"
    fi
    elapsed_part=" \033[0;36m⏱ ${elapsed_str}\033[0m"
  fi
fi

# Build status line
arrow="\033[1;32m➜\033[0m"
dir_part="\033[0;36m${dir}\033[0m"

if [ -n "$branch" ]; then
  git_part=" \033[1;34mgit:(\033[0;31m${branch}\033[1;34m)\033[0m"
else
  git_part=""
fi

if [ -n "$model" ]; then
  model_part=" \033[0;35m🤖 ${model}\033[0m"
else
  model_part=""
fi

if [ -n "$used" ]; then
  ctx_val=$(printf '%.0f' "$used")
  if [ "$ctx_val" -ge 80 ]; then
    ctx_color="\033[0;31m"
  elif [ "$ctx_val" -ge 50 ]; then
    ctx_color="\033[0;33m"
  else
    ctx_color="\033[0;32m"
  fi
  ctx_part=" ${ctx_color}🧠 ${ctx_val}%%\033[0m"
else
  ctx_part=""
fi

cost_part=" \033[0;33m💰 \$${cost}\033[0m"

if [ "${lines_added:-0}" -gt 0 ] || [ "${lines_removed:-0}" -gt 0 ]; then
  lines_part=" \033[0;32m+${lines_added}\033[0m\033[0;31m-${lines_removed}\033[0m"
else
  lines_part=""
fi

if [ -n "$rate_5h" ]; then
  if [ "$rate_5h" -ge 80 ]; then
    rate_color="\033[0;31m"
  elif [ "$rate_5h" -ge 50 ]; then
    rate_color="\033[0;33m"
  else
    rate_color="\033[0;32m"
  fi
  rate_part=" ${rate_color}⚡ ${rate_5h}%%\033[0m"
else
  rate_part=""
fi

printf "${arrow} ${dir_part}${git_part}${model_part}${ctx_part}${cost_part}${lines_part}${rate_part}${elapsed_part}"
