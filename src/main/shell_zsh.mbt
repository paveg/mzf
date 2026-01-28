///|
/// Zsh shell integration script for mzf
/// Provides key bindings (Ctrl-R, Ctrl-T, Alt-C) and completion
pub fn get_zsh_script() -> String {
  let script =
    #|# mzf zsh integration
    #|# Usage: source <(mzf --zsh)
    #|
    #|# Ensure mzf is available
    #|if ! command -v mzf &> /dev/null; then
    #|  echo "mzf: command not found" >&2
    #|  return 1
    #|fi
    #|
    #|# Key binding widgets
    #|# -------------------
    #|
    #|# Ctrl-T: File selection widget
    #|mzf-file-widget() {
    #|  local cmd="${MZF_CTRL_T_COMMAND:-find . -type f 2>/dev/null | head -50000}"
    #|  local output
    #|  output=$(eval "$cmd" | mzf --height=40% -m $MZF_CTRL_T_OPTS)
    #|  if [[ -n "$output" ]]; then
    #|    # Escape and join multiple selections
    #|    output=$(echo "$output" | while IFS= read -r line; do print -rn -- "${(q)line} "; done)
    #|    output="${output% }"  # Remove trailing space
    #|    LBUFFER="${LBUFFER}${output}"
    #|  fi
    #|  zle reset-prompt
    #|}
    #|zle -N mzf-file-widget
    #|
    #|# Ctrl-R: History search widget
    #|mzf-history-widget() {
    #|  local output
    #|  output=$(
    #|    fc -lnr 1 2>/dev/null |
    #|    sed 's/^[[:space:]]*//' |
    #|    awk '!x[$0]++' |
    #|    mzf --height=40% --reverse --query="$LBUFFER" \
    #|        --prompt="history> " $MZF_CTRL_R_OPTS
    #|  )
    #|  if [[ -n "$output" ]]; then
    #|    LBUFFER="$output"
    #|    RBUFFER=""
    #|  fi
    #|  zle reset-prompt
    #|}
    #|zle -N mzf-history-widget
    #|
    #|# Alt-C: cd widget
    #|mzf-cd-widget() {
    #|  local cmd="${MZF_ALT_C_COMMAND:-find . -type d 2>/dev/null | head -50000}"
    #|  local dir
    #|  dir=$(eval "$cmd" | mzf --height=40% +m --prompt="cd> " $MZF_ALT_C_OPTS)
    #|  if [[ -n "$dir" ]]; then
    #|    cd "$dir" || return
    #|    LBUFFER=""
    #|    RBUFFER=""
    #|    zle accept-line
    #|    return
    #|  fi
    #|  zle reset-prompt
    #|}
    #|zle -N mzf-cd-widget
    #|
    #|# Bind keys
    #|bindkey '^T' mzf-file-widget
    #|bindkey '^R' mzf-history-widget
    #|bindkey '\ec' mzf-cd-widget
    #|
    #|# Completion
    #|# ----------
    #|
    #|# Completion trigger (default: **)
    #|MZF_COMPLETION_TRIGGER="${MZF_COMPLETION_TRIGGER:-**}"
    #|
    #|# mzf completion widget
    #|mzf-completion-widget() {
    #|  local tokens=(${(z)LBUFFER})
    #|  local trigger="$MZF_COMPLETION_TRIGGER"
    #|
    #|  # Check if last token ends with trigger
    #|  if [[ ${#tokens} -gt 0 ]]; then
    #|    local last="${tokens[-1]}"
    #|    if [[ "$last" == *"$trigger" ]]; then
    #|      local prefix="${last%$trigger}"
    #|      local cmd="${tokens[1]}"
    #|      local result
    #|
    #|      # Directory-only completion for cd, pushd, rmdir
    #|      if [[ "$cmd" == "cd" || "$cmd" == "pushd" || "$cmd" == "rmdir" ]]; then
    #|        result=$(__mzf_dir_completion "$prefix")
    #|      else
    #|        result=$(__mzf_path_completion "$prefix")
    #|      fi
    #|
    #|      if [[ -n "$result" ]]; then
    #|        # Replace last token with selected result
    #|        tokens[-1]="${(q)result}"
    #|        LBUFFER="${tokens[*]}"
    #|      fi
    #|      zle reset-prompt
    #|      return
    #|    fi
    #|  fi
    #|
    #|  # Fall back to default completion
    #|  zle expand-or-complete
    #|}
    #|zle -N mzf-completion-widget
    #|
    #|# Path completion helper (files and directories)
    #|__mzf_path_completion() {
    #|  local prefix="$1"
    #|  local base_dir="${prefix%/*}"
    #|
    #|  if [[ -z "$base_dir" || "$base_dir" == "$prefix" ]]; then
    #|    base_dir="."
    #|  fi
    #|
    #|  find "$base_dir" -maxdepth 5 2>/dev/null | \
    #|    mzf --height=40% -m --prompt="path> " $MZF_COMPLETION_OPTS | \
    #|    head -1
    #|}
    #|
    #|# Directory-only completion helper
    #|__mzf_dir_completion() {
    #|  local prefix="$1"
    #|  local base_dir="${prefix%/*}"
    #|
    #|  if [[ -z "$base_dir" || "$base_dir" == "$prefix" ]]; then
    #|    base_dir="."
    #|  fi
    #|
    #|  find "$base_dir" -maxdepth 5 -type d 2>/dev/null | \
    #|    mzf --height=40% +m --prompt="dir> " $MZF_COMPLETION_OPTS
    #|}
    #|
    #|# Bind Tab to mzf completion
    #|bindkey '^I' mzf-completion-widget
  script
}
