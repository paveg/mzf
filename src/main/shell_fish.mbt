///|
/// Fish shell integration script for mzf
/// Provides key bindings (Ctrl-R, Ctrl-T, Alt-C)
pub fn get_fish_script() -> String {
  let script =
    #|# mzf fish integration
    #|# Usage: mzf --fish | source
    #|
    #|# Ensure mzf is available
    #|if not command -v mzf &> /dev/null
    #|  echo "mzf: command not found" >&2
    #|  return 1
    #|end
    #|
    #|# Key binding functions
    #|# ---------------------
    #|
    #|# Ctrl-T: File selection
    #|function __mzf_select
    #|  set -l cmd (string length -q -- "$MZF_CTRL_T_COMMAND"; and echo "$MZF_CTRL_T_COMMAND"; or echo "find . -type f 2>/dev/null | head -50000")
    #|  set -l output (eval $cmd | mzf --height 20 -m $MZF_CTRL_T_OPTS)
    #|  if test -n "$output"
    #|    # Escape and join selections
    #|    set -l escaped
    #|    for line in $output
    #|      set -a escaped (string escape -- $line)
    #|    end
    #|    commandline -i -- (string join ' ' $escaped)
    #|  end
    #|  commandline -f repaint
    #|end
    #|
    #|# Ctrl-R: History search
    #|function __mzf_history
    #|  set -l output (
    #|    builtin history --show-time='' | \
    #|    awk '!x[$0]++' | \
    #|    mzf --height 20 --reverse --query=(commandline) \
    #|        --prompt="history> " $MZF_CTRL_R_OPTS
    #|  )
    #|  if test -n "$output"
    #|    commandline -r -- $output
    #|  end
    #|  commandline -f repaint
    #|end
    #|
    #|# Alt-C: cd widget
    #|function __mzf_cd
    #|  set -l cmd (string length -q -- "$MZF_ALT_C_COMMAND"; and echo "$MZF_ALT_C_COMMAND"; or echo "find . -type d 2>/dev/null | head -50000")
    #|  set -l dir (eval $cmd | mzf --height 20 --prompt="cd> " $MZF_ALT_C_OPTS)
    #|  if test -n "$dir"
    #|    cd "$dir"
    #|    commandline -r ''
    #|    commandline -f repaint
    #|  else
    #|    commandline -f repaint
    #|  end
    #|end
    #|
    #|# Bind keys
    #|# Default bindings (can be overridden by user)
    #|
    #|function mzf_key_bindings
    #|  # Clear existing bindings that we're about to set
    #|  bind --erase \ct
    #|  bind --erase \cr
    #|  bind --erase \ec
    #|
    #|  # Ctrl-T: file selection
    #|  bind \ct __mzf_select
    #|
    #|  # Ctrl-R: history search
    #|  bind \cr __mzf_history
    #|
    #|  # Alt-C: cd widget
    #|  bind \ec __mzf_cd
    #|
    #|  # Also bind for insert mode if using vi mode
    #|  if test "$fish_key_bindings" = fish_vi_key_bindings
    #|    bind -M insert \ct __mzf_select
    #|    bind -M insert \cr __mzf_history
    #|    bind -M insert \ec __mzf_cd
    #|  end
    #|end
    #|
    #|# Apply key bindings
    #|mzf_key_bindings
    #|
    #|# Completion
    #|# ----------
    #|
    #|# Completion trigger (default: **)
    #|set -q MZF_COMPLETION_TRIGGER; or set -g MZF_COMPLETION_TRIGGER '**'
    #|
    #|# Tab completion helper for mzf
    #|function __mzf_complete
    #|  set -l token (commandline -ct)
    #|  set -l trigger $MZF_COMPLETION_TRIGGER
    #|
    #|  # Check if token ends with trigger
    #|  if string match -q -- "*$trigger" "$token"
    #|    set -l prefix (string replace -r -- "$trigger\$" '' "$token")
    #|    set -l cmd (commandline -opc)[1]
    #|    set -l result
    #|
    #|    # Directory-only completion for cd, pushd, rmdir
    #|    if contains -- "$cmd" cd pushd rmdir
    #|      set result (__mzf_dir_completion "$prefix")
    #|    else
    #|      set result (__mzf_path_completion "$prefix")
    #|    end
    #|
    #|    if test -n "$result"
    #|      commandline -rt -- (string escape -- $result)
    #|    end
    #|    commandline -f repaint
    #|    return 0
    #|  end
    #|
    #|  return 1  # Fall through to default completion
    #|end
    #|
    #|# Path completion helper
    #|function __mzf_path_completion
    #|  set -l prefix $argv[1]
    #|  set -l base_dir (dirname -- "$prefix" 2>/dev/null; or echo ".")
    #|
    #|  if test -z "$base_dir" -o "$base_dir" = "$prefix"
    #|    set base_dir "."
    #|  end
    #|
    #|  find "$base_dir" -maxdepth 5 2>/dev/null | \
    #|    mzf --height 20 -m --prompt="path> " $MZF_COMPLETION_OPTS | \
    #|    head -1
    #|end
    #|
    #|# Directory-only completion helper
    #|function __mzf_dir_completion
    #|  set -l prefix $argv[1]
    #|  set -l base_dir (dirname -- "$prefix" 2>/dev/null; or echo ".")
    #|
    #|  if test -z "$base_dir" -o "$base_dir" = "$prefix"
    #|    set base_dir "."
    #|  end
    #|
    #|  find "$base_dir" -maxdepth 5 -type d 2>/dev/null | \
    #|    mzf --height 20 --prompt="dir> " $MZF_COMPLETION_OPTS
    #|end
  script
}
