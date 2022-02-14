#!/usr/bin/env bash

# Show where the matching open paren is when inserting a closing one. Disabling
# as it hijacks the `)`, `]` and `}` characters to enable blinking.
bind "set blink-matching-paren off"

function __autopair() {
  local typed_char="$1"
  local opening_char="$2"
  local closing_char="$3"
  local cursor_char="${READLINE_LINE:READLINE_POINT:1}"
  local previous_char="${READLINE_LINE:READLINE_POINT-1:1}"
  local num_of_char

  local s
  s="${READLINE_LINE::READLINE_POINT}"

  num_of_char="${READLINE_LINE//\\${typed_char}}"
  num_of_char="${num_of_char//[^${typed_char}]/}"

  if [[ "$previous_char"  == "\\" ]]; then
    s+="$typed_char"
  elif [[ "$opening_char" == "$closing_char" ]]; then
    if [[ "$(( ${#num_of_char} % 2 ))" -eq 1 ]]; then
      s+="$typed_char"
    elif [[ "$cursor_char" == "$closing_char" ]]; then
      :
    elif [[ "$(( ${#num_of_char} % 2 ))" -eq 0 ]]; then
      s+="$typed_char$typed_char"
    fi
  elif [[ "$typed_char" == "$opening_char" ]]; then
    s+="$opening_char$closing_char"
  elif [[ "$cursor_char" == "$closing_char" ]]; then
    :
  else
    s+="$typed_char"
  fi

  s+="${READLINE_LINE:READLINE_POINT}"

  READLINE_LINE="$s"

  ((READLINE_POINT++))
}

function __autopair_remove() {
  local previous_char="${READLINE_LINE:READLINE_POINT-1:1}"
  local cursor_char="${READLINE_LINE:READLINE_POINT:1}"

  if [[ "${#READLINE_LINE}" -eq 0 || "$READLINE_POINT" -eq 0 ]]; then
    return
  fi

  local s
  s="${READLINE_LINE::READLINE_POINT-1}"

  local autopair_operated=false
  local pair

  # ()[]{}
  for pair in "${__pairs[@]:2}"; do
    if [[ "$previous_char" == "${pair:0:1}" ]] \
      && [[ "$cursor_char" == "${pair:1:1}" ]]; then

      s+="${READLINE_LINE:READLINE_POINT+1}"
      autopair_operated=true
    fi
  done

  # ""''
  for pair in "${__pairs[@]:0:2}"; do
    if [[ "$previous_char" == "${pair:0:1}" ]] \
      && [[ "$cursor_char" == "${pair:1:1}" ]]; then

      num_of_char="${READLINE_LINE//[^${pair:0:1}]/}"
      num_of_char="${#num_of_char}"

      if [[ "$((num_of_char % 2))" -eq 1 ]]; then
        break
      fi

      s+="${READLINE_LINE:READLINE_POINT+1}"
      autopair_operated=true
    fi
  done

  if [[ "$autopair_operated" == 'false' ]]; then
    s+="${READLINE_LINE:READLINE_POINT}"
  fi

  READLINE_LINE="$s"

  ((READLINE_POINT--))
}

__pairs=(
  "''"
  '""'
  '()'
  '[]'
  '{}'
)

for pair in "${__pairs[@]}"; do
  bind -x "\"${pair:0:1}\": __autopair \\${pair:0:1} \\${pair:0:1} \\${pair:1:1}"
  bind -x "\"${pair:1:1}\": __autopair \\${pair:1:1} \\${pair:0:1} \\${pair:1:1}"
done

# `"` needs to be done separately
bind -x "\"\\\"\": __autopair \\\" \\\" \\\""

bind -x '"\C-h": __autopair_remove'

if [[ -v BASH_AUTOPAIR_BACKSPACE ]]; then
  # https://lists.gnu.org/archive/html/bug-bash/2019-11/msg00129.html
  bind 'set bind-tty-special-chars off'
  bind -x '"\C-?": __autopair_remove'
fi

unset pair
