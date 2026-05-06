#!/usr/bin/env bash
# crystools — subagent tracker hook
# Events:
#   PreToolUse / PostToolUse (matcher: Agent) → record start/end of each subagent
#   SessionStart                              → sweep orphan JSONL files (>24h)
#   SessionEnd                                → delete this session's JSONL

set -euo pipefail

input=$(cat)

# Require jq; silent no-op if missing (don't break the user's session)
command -v jq &>/dev/null || exit 0

session_id=$(echo "$input" | jq -r '.session_id // empty')
event=$(echo "$input" | jq -r '.hook_event_name // empty')
tool_name=$(echo "$input" | jq -r '.tool_name // empty')

[ -z "$session_id" ] && exit 0

# Tool-scoped events only matter for Agent; lifecycle events bypass this check
case "$event" in
  PreToolUse|PostToolUse)
    [ "$tool_name" = "Agent" ] || exit 0
    ;;
esac

# State dir: prefer project .tmp, fallback to ~/.claude/tmp
cwd=$(echo "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  state_dir="$cwd/.tmp"
else
  state_dir="$HOME/.claude/tmp"
fi
mkdir -p "$state_dir" 2>/dev/null || exit 0
state_file="$state_dir/agents-${session_id}.jsonl"

now_ms=$(date +%s%3N)
tool_use_id=$(echo "$input" | jq -r '.tool_use_id // empty')

case "$event" in
  PreToolUse)
    agent=$(echo "$input" | jq -r '.tool_input.subagent_type // "general-purpose"')
    desc=$(echo "$input" | jq -r '.tool_input.description // ""')
    jq -nc \
      --arg e "start" \
      --argjson ts "$now_ms" \
      --arg id "$tool_use_id" \
      --arg agent "$agent" \
      --arg desc "$desc" \
      '{event:$e, ts:$ts, id:$id, agent:$agent, desc:$desc}' \
      >> "$state_file"
    ;;
  PostToolUse)
    # Extract activity metrics from tool_response
    metrics=$(echo "$input" | jq -c '{
      tokens: ([.tool_response.totalTokens,
               .tool_response.usage.total_tokens,
               (.tool_response.usage.input_tokens + .tool_response.usage.output_tokens),
               0] | map(select(. != null)) | .[0] // 0),
      msgs:   ((.tool_response.usage.iterations // []) | length),
      tools:  (.tool_response.totalToolUseCount // 0),
      status: (.tool_response.status // "completed")
    }' 2>/dev/null || echo '{"tokens":0,"msgs":0,"tools":0,"status":"unknown"}')
    jq -nc \
      --arg e "end" \
      --argjson ts "$now_ms" \
      --arg id "$tool_use_id" \
      --argjson m "$metrics" \
      '{event:$e, ts:$ts, id:$id} + $m' \
      >> "$state_file"
    ;;
  SessionEnd)
    # Drop this session's file
    rm -f "$state_file"
    ;;
  SessionStart)
    # Sweep orphan files older than 24h, keep current session's file
    find "$state_dir" -maxdepth 1 -name 'agents-*.jsonl' \
      -mtime +0 \
      -not -name "agents-${session_id}.jsonl" \
      -delete 2>/dev/null || true
    ;;
esac

exit 0
