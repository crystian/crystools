# Claude Code status line — powerline style + atomic palette + Nerd Font

if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
    "jq not found - install it: https://jqlang.github.io/jq/download/"
    exit 0
}

$input = $Input | Out-String

$cwd = $input | jq -r '.workspace.current_dir // .cwd // ""'
$model = $input | jq -r '.model.display_name // ""'
$cost_usd = $input | jq -r '.cost.total_cost_usd // empty'
$duration_ms = $input | jq -r '.cost.total_duration_ms // empty'
$api_ms = $input | jq -r '.cost.total_api_duration_ms // empty'
$lines_add = $input | jq -r '.cost.total_lines_added // empty'
$lines_rem = $input | jq -r '.cost.total_lines_removed // empty'
$used_pct = $input | jq -r '.context_window.used_percentage // empty'
$ctx_size = $input | jq -r '.context_window.context_window_size // empty'
$cache_create = $input | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty'
$cache_read = $input | jq -r '.context_window.current_usage.cache_read_input_tokens // empty'
$rate_5h = $input | jq -r '.rate_limits.five_hour.used_percentage // empty'
$rate_resets = $input | jq -r '.rate_limits.five_hour.resets_at // empty'

# Git info
$branch = ""
$git_dirty = ""
$git_ab = ""
if ($cwd -and (Test-Path $cwd)) {
    try {
        $branch = git -C $cwd --no-optional-locks rev-parse --abbrev-ref HEAD 2>$null
        if ($branch) {
            $gs = git -C $cwd --no-optional-locks status --porcelain 2>$null | Select-Object -First 1
            $git_dirty = if ($gs) { [char]0x25B3 } else { [char]0xF0116 }

            $ab = git -C $cwd --no-optional-locks rev-list --left-right --count "HEAD...@{upstream}" 2>$null
            if ($ab) {
                $parts = $ab -split '\s+'
                $ahead = [int]$parts[0]
                $behind = [int]$parts[1]
                if ($ahead -gt 0) { $git_ab += [char]0x2191 + "$ahead" }
                if ($behind -gt 0) { $git_ab += " " + [char]0x2193 + "$behind" }
            }
        }
    } catch {}
}

# Icons
$iconMode = if ($env:CRYSTOOLS_SL_ICONS) { $env:CRYSTOOLS_SL_ICONS } else { "emoji" }
switch ($iconMode) {
    "nerd" {
        $ICO_DIR = [char]0xF0DD0; $ICO_GIT = [char]0xF062C; $ICO_MODEL = [char]0xF167A; $ICO_CTX = [char]0xF0F86
        $ICO_COST = '$'; $ICO_TIME = [char]0xF1058; $ICO_CACHE = [char]0xF0453
    }
    "emoji" {
        $ICO_DIR = [char]0x1F4C1; $ICO_GIT = [char]0x2387; $ICO_MODEL = [char]0x1F916; $ICO_CTX = [char]0x1FA9F
        $ICO_COST = [char]0x1F4B2; $ICO_TIME = [char]0x1F550; $ICO_CACHE = [char]0x1F504
    }
    default {
        $ICO_DIR = ''; $ICO_GIT = ''; $ICO_MODEL = ''; $ICO_CTX = ''
        $ICO_COST = ''; $ICO_TIME = ''; $ICO_CACHE = ''
    }
}

# Color helper
function Seg($fg, $text) {
    $r, $g, $b = $fg -split ';'
    return "$([char]27)[38;2;${r};${g};${b}m ${text} $([char]27)[0m"
}

# Spinner
$spinners = @([char]0x280B, [char]0x2819, [char]0x2839, [char]0x2838, [char]0x283C, [char]0x2834, [char]0x2826, [char]0x2827, [char]0x2807, [char]0x280F)
$spin_idx = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() % $spinners.Count)
$spin_ico = $spinners[$spin_idx]

# Short directory
$short_dir = if ($cwd) {
    $parts = $cwd -replace '\\', '/' -split '/'
    $projIdx = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i] -eq 'projects') { $projIdx = $i + 1; break }
    }
    if ($projIdx -ge 0 -and $projIdx -lt $parts.Count) {
        $proj = $parts[$projIdx]
        $depth = $parts.Count - 1 - $projIdx
        if ($depth -eq 0) { $proj }
        elseif ($depth -eq 1) { "$proj/$($parts[-1])" }
        else { "$proj/.../$($parts[-1])" }
    } else { $parts[-1] }
} else { "" }

# --- Line 1 ---
$line1 = ""

# Context usage
if ($used_pct) {
    $used_int = [math]::Floor([double]$used_pct)
    if ($used_int -ge 75) { $bar_fill = "255;50;80" }
    elseif ($used_int -ge 50) { $bar_fill = "255;200;0" }
    else { $bar_fill = "0;200;255" }
    $bar_empty = "60;60;80"
    $bar_w = 10
    $filled = [math]::Floor($used_int * $bar_w / 100)
    $pct_text = "${used_int}%"
    $fill_str = [string]::new([char]0x2593, $filled)
    $rem = $bar_w - $filled - $pct_text.Length
    if ($rem -lt 0) { $rem = 0 }
    $empty_str = [string]::new('-', $rem)
    $r1, $g1, $b1 = $bar_fill -split ';'
    $r2, $g2, $b2 = $bar_empty -split ';'
    $seg_text = "$([char]27)[38;2;${r1};${g1};${b1}m${fill_str}${pct_text}$([char]27)[38;2;${r2};${g2};${b2}m${empty_str}"
    $ctx_sep = if ($iconMode -eq "nerd") { " " } else { "" }
    $line1 += Seg $bar_fill "${ICO_CTX}${ctx_sep}[${seg_text}$([char]27)[38;2;${r1};${g1};${b1}m]"
}

# Directory
if ($ICO_DIR) {
    $line1 += Seg "220;190;130" "${ICO_DIR} ${short_dir}"
} elseif ($iconMode -eq "none") {
    $line1 += Seg "220;190;130" "/${short_dir}"
} else {
    $line1 += Seg "220;190;130" "${short_dir}"
}

# Git
if ($branch) {
    $git_text = "${ICO_GIT} ${branch} ${git_dirty}"
    if ($git_ab) { $git_text += " ${git_ab}" }
    if ($lines_add -or $lines_rem) {
        $add = if ($lines_add) { $lines_add } else { "0" }
        $rem_val = if ($lines_rem) { $lines_rem } else { "0" }
        $git_text += "  $([char]27)[38;2;0;255;140m+${add} $([char]27)[38;2;255;60;90m-${rem_val}"
    }
    $line1 += Seg "190;170;220" $git_text
}

# Duration
if ($duration_ms) {
    $total_sec = [math]::Floor([double]$duration_ms / 1000)
    $hrs = [math]::Floor($total_sec / 3600)
    $mins = [math]::Floor(($total_sec % 3600) / 60)
    $secs = $total_sec % 60
    $time_text = "${ICO_TIME} {0:D2}:{1:D2}:{2:D2}" -f $hrs, $mins, $secs
    if ($api_ms) {
        $api_sec = [math]::Floor([double]$api_ms / 1000)
        $api_hrs = [math]::Floor($api_sec / 3600)
        $api_min = [math]::Floor(($api_sec % 3600) / 60)
        $api_s = $api_sec % 60
        $time_text += " ({0:D2}:{1:D2}:{2:D2})" -f $api_hrs, $api_min, $api_s
    }
    $line1 += Seg "160;210;200" $time_text
}

# --- Line 2 ---
$line2 = ""

# Rate limit
if ($rate_5h) {
    $rate_int = [math]::Floor([double]$rate_5h)
    if ($rate_int -ge 75) { $rbar_fill = "255;0;120" }
    elseif ($rate_int -ge 50) { $rbar_fill = "255;160;0" }
    else { $rbar_fill = "0;255;180" }
    $rbar_empty = "60;60;80"
    $rbar_w = 10
    $rfilled = [math]::Floor($rate_int * $rbar_w / 100)
    $rpct_text = "${rate_int}%"
    $rfill_str = [string]::new([char]0x2593, $rfilled)
    $rrem = $rbar_w - $rfilled - $rpct_text.Length
    if ($rrem -lt 0) { $rrem = 0 }
    $rempty_str = [string]::new('-', $rrem)
    $r1, $g1, $b1 = $rbar_fill -split ';'
    $r2, $g2, $b2 = $rbar_empty -split ';'
    $rseg_text = "$([char]27)[38;2;${r1};${g1};${b1}m${rfill_str}${rpct_text}$([char]27)[38;2;${r2};${g2};${b2}m${rempty_str}"
    $rate_ico = switch ($iconMode) { "nerd" { [char]0xF0517 + ' ' } "emoji" { [char]0x231B } default { '' } }
    $rate_reset_text = ""
    if ($rate_resets) {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $remaining = [int]$rate_resets - $now
        if ($remaining -gt 0) {
            $rh = [math]::Floor($remaining / 3600)
            $rm = [math]::Floor(($remaining % 3600) / 60)
            $rate_reset_text = " ({0:D2}:{1:D2})" -f $rh, $rm
        }
    }
    $line2 += Seg $rbar_fill "${rate_ico}[${rseg_text}$([char]27)[38;2;${r1};${g1};${b1}m]${rate_reset_text}"
}

# Model
if ($model) {
    $short_model = $model -replace ' \(.*', ''
    $ctx_label = ""
    if ($ctx_size) {
        $ctx_k = [math]::Floor([double]$ctx_size / 1000)
        if ($ctx_k -ge 1000) {
            $ctx_label = " {0:N0}M" -f ($ctx_k / 1000)
        } else {
            $ctx_label = " ${ctx_k}K"
        }
    }
    if ($ICO_MODEL) {
        $line2 += Seg "210;170;190" "${ICO_MODEL} ${short_model}${ctx_label}"
    } else {
        $line2 += Seg "210;170;190" "${short_model}${ctx_label}"
    }
}

# Cost
if ($cost_usd) {
    $cost_fmt = "{0:F2}" -f [double]$cost_usd
    $cost_prefix = if ($ICO_COST) { $ICO_COST } else { '$' }
    $line2 += Seg "170;210;170" "${cost_prefix} ${cost_fmt}"
}

# Cache
if ($cache_create -or $cache_read) {
    $cc_k = [math]::Floor([double]$(if ($cache_create) { $cache_create } else { 0 }) / 1000)
    $cr_k = [math]::Floor([double]$(if ($cache_read) { $cache_read } else { 0 }) / 1000)
    $line2 += Seg "180;190;210" "${ICO_CACHE} TK Cached w/r: ${cc_k}/${cr_k}"
}

# Spinner
$line2 += Seg "0;200;255" $spin_ico

"${line1}`n${line2}"
