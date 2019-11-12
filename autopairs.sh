#!/usr/bin/env bash

# Show where the matching open paren is when inserting a closing one. Disabling
# as it hijacks the `)`, `]` and `}` characters to enable blinking.
bind "set blink-matching-paren off"

function __autopair() {
  local typed_char="$1"
  local opening_char="$2"
  local closing_char="$3"
  local cursor_char="${READLINE_LINE:READLINE_POINT:1}"
  local num_of_char

  local s
  s="${READLINE_LINE::READLINE_POINT}"

  if [[ "$opening_char" == "$closing_char" ]]; then
    num_of_char="${READLINE_LINE//[^$typed_char]/}"
    num_of_char="${#num_of_char}"

    if [[ "$cursor_char" == "$closing_char" ]]; then
      :
    elif [[ "$((num_of_char % 2))" -eq 0 ]]; then
      s+="$typed_char$typed_char"
    else
      s+="$typed_char"
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

__pairs=(
  "''"
  # '""'
  '()'
  '[]'
  '{}'
)

for pair in "${__pairs[@]}"; do
  bind -x "\"${pair:0:1}\": __autopair \\${pair:0:1} \\${pair:0:1} \\${pair:1:1}"
  bind -x "\"${pair:1:1}\": __autopair \\${pair:1:1} \\${pair:0:1} \\${pair:1:1}"
done
bind -x "\"\\\"\": __autopair \\\" \\\" \\\""

unset pair
unset __pairs
