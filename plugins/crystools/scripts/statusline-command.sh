#!/usr/bin/env bash
# Claude Code status line — powerline style + atomic palette + Nerd Font

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
api_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_rem=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
cur_in=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
cur_out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
output_style=$(echo "$input" | jq -r '.output_style.name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
exceeds_200k=$(echo "$input" | jq -r '.exceeds_200k_tokens // empty')

# Git status (dirty/clean)
git_dirty=""
if [ -n "$cwd" ]; then
  git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  if [ -n "$git_status" ]; then
    git_dirty="△"
  else
    git_dirty="󰄬"
  fi
fi

# Git ahead/behind
git_ab=""
if [ -n "$branch" ]; then
  ab=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
  if [ -n "$ab" ]; then
    ahead=$(echo "$ab" | cut -f1)
    behind=$(echo "$ab" | cut -f2)
    [ "$ahead" -gt 0 ] 2>/dev/null && git_ab+="↑${ahead}"
    [ "$behind" -gt 0 ] 2>/dev/null && git_ab+=" ↓${behind}"
  fi
fi

# Current time
cur_time=$(date +%H:%M)

# Icons: nerd | emoji | none (via STATUSLINE_ICONS env var)
case "${STATUSLINE_ICONS:-emoji}" in
  nerd)
    PL=''   PLR=''
    ICO_DIR='󰝰'  ICO_GIT='󰘬'  ICO_MODEL='󱙺'  ICO_CTX='󰾆'
    ICO_COST='$'  ICO_TIME='󱑎'  ICO_API='󰒍'  ICO_CACHE='󰑓'
    ;;
  emoji)
    PL='▶'  PLR='◀'
    ICO_DIR='📁'  ICO_GIT='⎇'  ICO_MODEL='🤖'  ICO_CTX='🪟'
    ICO_COST='💲'  ICO_TIME='🕐'  ICO_API='⚡'  ICO_CACHE='🔄'
    ;;
  *)
    PL='|'  PLR='|'
    ICO_DIR=''  ICO_GIT=''  ICO_MODEL=''  ICO_CTX=''
    ICO_COST=''  ICO_TIME=''  ICO_API=''  ICO_CACHE=''
    ;;
esac

# Background + foreground color helpers
# Usage: seg "bg_r;bg_g;bg_b" "fg_r;fg_g;fg_b" "text"
# Tracks prev_bg for arrow transitions
prev_bg=""
output=""

seg() {
  local bg="$1" fg="$2" text="$3"
  local fg_code="\033[38;2;${fg}m"
  local reset='\033[0m'

  output+="${fg_code} ${text} ${reset}"
}

close_seg() {
  :
}

# Spinner (cycles by current second)
spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
spin_idx=$(( $(date +%s) % ${#spinner[@]} ))
spin_ico=${spinner[$spin_idx]}

# Directory: project name always visible; deep paths show project/…/current
short_dir=$(echo "$cwd" | awk -F'/' '{
  proj=""; pi=0
  for(i=1;i<=NF;i++) if($i=="projects"){proj=$(i+1); pi=i+1; break}
  if(proj=="") {print $NF; next}
  depth=NF-pi
  if(depth==0) print proj
  else if(depth==1) print proj"/"$NF
  else print proj"/…/"$NF
}')

# --- Line 1: context + dir + git + emoji ---

# Context usage (progress bar)
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  if [ "$used_int" -ge 75 ]; then
    bar_fill="255;50;80"
    [ "${STATUSLINE_ICONS:-emoji}" = "nerd" ] && ICO_CTX='󰓅'
  elif [ "$used_int" -ge 50 ]; then
    bar_fill="255;200;0"
    [ "${STATUSLINE_ICONS:-emoji}" = "nerd" ] && ICO_CTX='󰾅'
  else
    bar_fill="0;200;255"
    [ "${STATUSLINE_ICONS:-emoji}" = "nerd" ] && ICO_CTX='󰾆'
  fi
  bar_empty="60;60;80"
  bar_w=10
  filled=$((used_int * bar_w / 100))
  pct_text="${used_int}%"
  fill_str="" empty_str=""
  for ((i=0; i<filled; i++)); do fill_str+="▓"; done
  remaining=$((bar_w - filled - ${#pct_text}))
  [ "$remaining" -lt 0 ] && remaining=0
  for ((i=0; i<remaining; i++)); do empty_str+="-"; done
  seg_text="\033[38;2;${bar_fill}m${fill_str}${pct_text}\033[38;2;${bar_empty}m${empty_str}"
  ctx_sep=" "
  [ "${STATUSLINE_ICONS:-emoji}" != "nerd" ] && ctx_sep=""
  seg "" "${bar_fill}" "${ICO_CTX}${ctx_sep}[${seg_text}\033[38;2;${bar_fill}m]"
fi

# Directory (neon orange)
if [ -n "$ICO_DIR" ]; then
  seg "" "220;190;130" "${ICO_DIR} ${short_dir}"
elif [ "${STATUSLINE_ICONS:-emoji}" = "none" ]; then
  seg "" "220;190;130" "/${short_dir}"
else
  seg "" "220;190;130" "${short_dir}"
fi

# Git branch + status + diff
if [ -n "$branch" ]; then
  git_text="${ICO_GIT} ${branch} ${git_dirty}"
  [ -n "$git_ab" ] && git_text+=" ${git_ab}"
  if [ -n "$lines_add" ] || [ -n "$lines_rem" ]; then
    add=${lines_add:-0}
    rem=${lines_rem:-0}
    git_text+="  \033[38;2;0;255;140m+${add} \033[38;2;255;60;90m-${rem}"
  fi
  seg "" "190;170;220" "$git_text"
fi

# Session + API duration
if [ -n "$duration_ms" ]; then
  total_sec=$((duration_ms / 1000))
  hrs=$((total_sec / 3600))
  mins=$(( (total_sec % 3600) / 60 ))
  secs=$((total_sec % 60))
  time_text="$(printf "${ICO_TIME} %02d:%02d:%02d" $hrs $mins $secs)"
  if [ -n "$api_ms" ]; then
    api_sec=$((api_ms / 1000))
    api_hrs=$((api_sec / 3600))
    api_min=$(( (api_sec % 3600) / 60 ))
    api_s=$((api_sec % 60))
    time_text+="$(printf " (%02d:%02d:%02d)" $api_hrs $api_min $api_s)"
  fi
  seg "" "160;210;200" "$time_text"
fi

close_seg

# --- Line 2: rate + model + cost + cache + emoji ---
prev_bg=""
output+="\n"

# Rate limit 5h (progress bar)
if [ -n "$rate_5h" ]; then
  rate_int=${rate_5h%.*}
  if [ "$rate_int" -ge 75 ]; then
    rbar_fill="255;0;120"
  elif [ "$rate_int" -ge 50 ]; then
    rbar_fill="255;160;0"
  else
    rbar_fill="0;255;180"
  fi
  rbar_empty="60;60;80"
  rbar_w=10
  rfilled=$((rate_int * rbar_w / 100))
  rpct_text="${rate_int}%"
  rfill_str="" rempty_str=""
  for ((i=0; i<rfilled; i++)); do rfill_str+="▓"; done
  rremaining=$((rbar_w - rfilled - ${#rpct_text}))
  [ "$rremaining" -lt 0 ] && rremaining=0
  for ((i=0; i<rremaining; i++)); do rempty_str+="-"; done
  rseg_text="\033[38;2;${rbar_fill}m${rfill_str}${rpct_text}\033[38;2;${rbar_empty}m${rempty_str}"
  rate_ico=""
  case "${STATUSLINE_ICONS:-emoji}" in
    nerd) rate_ico='󰔟 ' ;;
    emoji) rate_ico='⏳' ;;
  esac
  rate_reset_text=""
  if [ -n "$rate_resets" ]; then
    now=$(date +%s)
    remaining=$((rate_resets - now))
    if [ "$remaining" -gt 0 ]; then
      rh=$((remaining / 3600))
      rm=$(( (remaining % 3600) / 60 ))
      rate_reset_text="$(printf " (%02d:%02d)" $rh $rm)"
    fi
  fi
  seg "" "${rbar_fill}" "${rate_ico}[${rseg_text}\033[38;2;${rbar_fill}m]${rate_reset_text}"
fi

# Model + context size
if [ -n "$model" ]; then
  short_model=$(echo "$model" | sed 's/ (.*//') # "Opus 4.6 (1M context)" → "Opus 4.6"
  ctx_label=""
  if [ -n "$ctx_size" ]; then
    ctx_k=$((ctx_size / 1000))
    if [ "$ctx_k" -ge 1000 ]; then
      ctx_label=" $(echo "$ctx_k" | awk '{printf "%.0fM", $1/1000}')"
    else
      ctx_label=" ${ctx_k}K"
    fi
  fi
  if [ -n "$ICO_MODEL" ]; then
    seg "" "210;170;190" "${ICO_MODEL} ${short_model}${ctx_label}"
  else
    seg "" "210;170;190" "${short_model}${ctx_label}"
  fi
fi

# Cost
if [ -n "$cost_usd" ]; then
  cost_fmt=$(printf '%.2f' "$cost_usd")
  cost_prefix="${ICO_COST}"
  [ -z "$cost_prefix" ] && cost_prefix='$'
  seg "" "170;210;170" "${cost_prefix} ${cost_fmt}"
fi

# Cache
if [ -n "$cache_create" ] || [ -n "$cache_read" ]; then
  cc_k=$((${cache_create:-0} / 1000))
  cr_k=$((${cache_read:-0} / 1000))
  seg "" "180;190;210" "${ICO_CACHE} TK Cached w/r: ${cc_k}/${cr_k}"
fi

# Spinner
seg "" "0;200;255" "${spin_ico}"

close_seg

printf "%b\n" "$output"
