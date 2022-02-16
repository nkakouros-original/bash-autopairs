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
  local next_char="${READLINE_LINE:READLINE_POINT+1:1}"

  local s="${READLINE_LINE::READLINE_POINT}"

  # escaped character
  if [[ "$previous_char" == "\\" ]]; then
    s+="$typed_char"

  # ''""``
  elif [[ "$opening_char" == "$closing_char" ]]; then
    local num_of_char="${READLINE_LINE//\\$typed_char/}"
    num_of_char="${num_of_char//[^$typed_char]/}"
    num_of_char="${#num_of_char}"

    if [[ "$((num_of_char % 2))" -eq 1 ]]; then
      s+="$typed_char"
    else
      s+="$typed_char$typed_char"
    fi

  # [{(
  elif [[ "$typed_char" == "$opening_char" ]]; then
    # TODO check right part string for balance
    s+="$opening_char$closing_char"

  # [ | ]{ | }( | ) and pressing ]})
  elif [[ "$typed_char" == "$closing_char" && "$cursor_char" == " " &&
    "$next_char" == "$closing_char" ]]; then
    s+=' '
    ((READLINE_POINT++))

  # ]}): cursor is already on closing char
  elif [[ "$cursor_char" == "$closing_char" ]]; then
    # TODO check left and right string parts for balance
    :
  # ]})
  else
    s+="$typed_char"
  fi

  s+="${READLINE_LINE:READLINE_POINT}"

  READLINE_LINE="$s"

  ((READLINE_POINT++))
}

function __autopair_space() {
  local magic_space_enabled_on_space="$1"
  local cursor_char="${READLINE_LINE:READLINE_POINT:1}"
  local previous_char="${READLINE_LINE:READLINE_POINT-1:1}"
  local next_char="${READLINE_LINE:READLINE_POINT+1:1}"
  local num_of_char

  local s="${READLINE_LINE::READLINE_POINT}"

  # The user pressed space, so we want to print at least one space no matter
  # what. If magic-space is enabled on the space bar, send a magic space. If
  # not, send a regular space.
  if [[ "$magic_space_enabled_on_space" -eq 1 ]]; then
    # https://unix.stackexchange.com/questions/213799#answer-213821
    bind '"\e[0n": magic-space' && printf '\e[5n'
  else
    s+=' '
    ((READLINE_POINT++))
  fi

  for pair in "${__pairs[@]:3}"; do
    local opening_char="${pair:0:1}"
    local closing_char="${pair:1:1}"

    if [[ "$previous_char" == "$opening_char" && "$cursor_char" == "$closing_char" ]]; then
      s+=" "
      break
    fi
  done

  s+="${READLINE_LINE:READLINE_POINT}"

  READLINE_LINE="$s"
}

function __autopair_remove() {
  # empty line or backspace at the start of line
  if [[ "${#READLINE_LINE}" -eq 0 || "$READLINE_POINT" -eq 0 ]]; then
    return
  fi

  local s="${READLINE_LINE::READLINE_POINT-1}"
  local previous_char="${READLINE_LINE:READLINE_POINT-1:1}"
  local cursor_char="${READLINE_LINE:READLINE_POINT:1}"
  local pair
  local offset=0
  local loop_index=0
  local num_of_char

  for pair in "${__pairs[@]}"; do
    local minus_2_char="${READLINE_LINE:READLINE_POINT-2:1}"
    local next_char="${READLINE_LINE:READLINE_POINT+1:1}"

    # ()[]{}: delete first space in double space  (e.g. {A|B}, delete space "A")
    if [[ "$previous_char" == ' ' ]] \
      && [[ "$cursor_char" == ' ' ]] \
      && [[ "$minus_2_char" == "${pair:0:1}" ]] \
      && [[ "$next_char" == "${pair:1:1}" ]]; then
      offset=1
      break

    # all pairs: delete the opening
    elif [[ "$previous_char" == "${pair:0:1}" ]] \
      && [[ "$cursor_char" == "${pair:1:1}" ]]; then

      # ''""``: delete results in balanced pairs on line
      if [[ "$loop_index" -lt 3 ]]; then
        num_of_char="${READLINE_LINE//[^${pair:0:1}]/}"
        num_of_char="${#num_of_char}"

        if [[ "$((num_of_char % 2))" -eq 1 ]]; then
          break
        fi
      fi

      # all pairs: delete whole pair
      offset=1
      break
    fi

    ((index++))
  done

  s+="${READLINE_LINE:READLINE_POINT+$offset}"

  READLINE_LINE="$s"

  ((READLINE_POINT--))
}

__pairs=(
  "''"
  '""'
  '``'
  '()'
  '[]'
  '{}'
)

for pair in "${__pairs[@]:1:3}"; do
  bind -x "\"${pair:0:1}\": __autopair \\${pair:0:1} \\${pair:0:1} \\${pair:1:1}"
done
for pair in "${__pairs[@]:3}"; do
  bind -x "\"${pair:0:1}\": __autopair \\${pair:0:1} \\${pair:0:1} \\${pair:1:1}"
  bind -x "\"${pair:1:1}\": __autopair \\${pair:1:1} \\${pair:0:1} \\${pair:1:1}"
done
bind -x "\"\\\"\": __autopair \\\" \\\" \\\"" # `"` needs to be done separately
unset pair

bind -x '"\C-h": __autopair_remove'

if [[ "$(bind -q magic-space)" =~ 'invoked via " "' ]]; then
  bind -x "\" \": __autopair_space 1"
else
  bind -x "\" \": __autopair_space 0"
fi

if [[ -v BASH_AUTOPAIR_BACKSPACE ]]; then
  # https://lists.gnu.org/archive/html/bug-bash/2019-11/msg00129.html
  bind 'set bind-tty-special-chars off'
  bind -x '"\C-?": __autopair_remove'
fi
