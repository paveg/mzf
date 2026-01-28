///|
/// Bash shell integration script for mzf
/// Provides key bindings (Ctrl-R, Ctrl-T, Alt-C) and completion
pub fn get_bash_script() -> String {
  let script =
    #|# mzf bash integration
    #|# Usage: eval "$(mzf --bash)"
    #|
    #|# Ensure mzf is available
    #|if ! command -v mzf &> /dev/null; then
    #|  echo "mzf: command not found" >&2
    #|  return 1
    #|fi
    #|
    #|# Key bindings
    #|# -------------
    #|
    #|# Ctrl-T: File selection widget
    #|__mzf_select__() {
    #|  local cmd="${MZF_CTRL_T_COMMAND:-find . -type f 2>/dev/null | head -50000}"
    #|  local output
    #|  output=$(eval "$cmd" | mzf --height=40% -m $MZF_CTRL_T_OPTS)
    #|  if [[ -n "$output" ]]; then
    #|    # Escape spaces and special characters for shell
    #|    output=$(echo "$output" | while IFS= read -r line; do printf '%q ' "$line"; done)
    #|    output="${output% }"  # Remove trailing space
    #|    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}$output${READLINE_LINE:READLINE_POINT}"
    #|    READLINE_POINT=$((READLINE_POINT + ${#output}))
    #|  fi
    #|}
    #|
    #|# Ctrl-R: History search widget
    #|__mzf_history__() {
    #|  local output
    #|  output=$(
    #|    fc -lnr 1 2>/dev/null |
    #|    sed 's/^[[:space:]]*//' |
    #|    awk '!x[$0]++' |
    #|    mzf --height=40% --reverse --query="$READLINE_LINE" \
    #|        --prompt="history> " $MZF_CTRL_R_OPTS
    #|  )
    #|  if [[ -n "$output" ]]; then
    #|    READLINE_LINE="$output"
    #|    READLINE_POINT=${#READLINE_LINE}
    #|  fi
    #|}
    #|
    #|# Alt-C: cd widget
    #|__mzf_cd__() {
    #|  local cmd="${MZF_ALT_C_COMMAND:-find . -type d 2>/dev/null | head -50000}"
    #|  local dir
    #|  dir=$(eval "$cmd" | mzf --height=40% +m --prompt="cd> " $MZF_ALT_C_OPTS)
    #|  if [[ -n "$dir" ]]; then
    #|    cd "$dir" || return
    #|    READLINE_LINE=""
    #|    READLINE_POINT=0
    #|  fi
    #|}
    #|
    #|# Bind keys (only in interactive shells)
    #|if [[ $- == *i* ]]; then
    #|  bind -x '"\C-t": __mzf_select__'
    #|  bind -x '"\C-r": __mzf_history__'
    #|  bind -x '"\ec": __mzf_cd__'
    #|fi
    #|
    #|# Completion
    #|# ----------
    #|
    #|# Completion trigger (default: **)
    #|MZF_COMPLETION_TRIGGER="${MZF_COMPLETION_TRIGGER:-**}"
    #|
    #|# Generic mzf completion function
    #|_mzf_complete() {
    #|  local cur="${COMP_WORDS[COMP_CWORD]}"
    #|  local trigger="$MZF_COMPLETION_TRIGGER"
    #|  local trigger_len=${#trigger}
    #|
    #|  # Check if current word ends with trigger
    #|  if [[ ${#cur} -ge $trigger_len && "${cur: -$trigger_len}" == "$trigger" ]]; then
    #|    local prefix="${cur:0:-$trigger_len}"
    #|    local cmd="${COMP_WORDS[0]}"
    #|    local result
    #|
    #|    # Directory-only completion for cd, pushd, rmdir
    #|    if [[ "$cmd" == "cd" || "$cmd" == "pushd" || "$cmd" == "rmdir" ]]; then
    #|      result=$(_mzf_dir_completion "$prefix")
    #|    else
    #|      result=$(_mzf_path_completion "$prefix")
    #|    fi
    #|
    #|    if [[ -n "$result" ]]; then
    #|      # Replace the trigger with selected result
    #|      COMPREPLY=("$result")
    #|    fi
    #|  fi
    #|}
    #|
    #|# Path completion (files and directories)
    #|_mzf_path_completion() {
    #|  local prefix="$1"
    #|  local base_dir="${prefix%/*}"
    #|
    #|  if [[ -z "$base_dir" || "$base_dir" == "$prefix" ]]; then
    #|    base_dir="."
    #|  fi
    #|
    #|  find "$base_dir" -maxdepth 5 2>/dev/null | \
    #|    mzf --height=40% -m --prompt="path> " $MZF_COMPLETION_OPTS | \
    #|    while IFS= read -r line; do printf '%q ' "$line"; done
    #|}
    #|
    #|# Directory-only completion
    #|_mzf_dir_completion() {
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
    #|# Register completion for common commands
    #|if [[ $- == *i* ]]; then
    #|  complete -F _mzf_complete -o default -o bashdefault cd
    #|  complete -F _mzf_complete -o default -o bashdefault pushd
    #|  complete -F _mzf_complete -o default -o bashdefault rmdir
    #|  complete -F _mzf_complete -o default -o bashdefault cat
    #|  complete -F _mzf_complete -o default -o bashdefault less
    #|  complete -F _mzf_complete -o default -o bashdefault vim
    #|  complete -F _mzf_complete -o default -o bashdefault nvim
    #|  complete -F _mzf_complete -o default -o bashdefault code
    #|fi
  script
}
