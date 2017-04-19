#!/bin/bash
low-add-backend() {
  for name in "${@:2}"; do
    awk -v name="$name" '
    {
      if ($0 == "backend " name ) {
        exists=1;
        exit 1;
      }
    }
    END {
      if (exists == 1) print "Backend " name " already exists." > "/dev/stderr";
      else {
        print "backend " name "\n  server " name " " name "-web:80 check resolvers docker resolve-prefer ipv4\n";
        exit 0;
      }
    }
    ' "$1" > "$1.bak"
    cp "$1.bak" "$1"
  done
}

low-remove-backend() {
  for name in "${@:2}"; do
    sed -e "/^backend $name$/d" -e "/^  server $name $name-web:80 check resolvers docker resolve-prefer ipv4/,+1d" "$1" > "$1.bak"
    cp "$1.bak" "$1"
  done
}

low-list-backend() {
  grep -o '^backend .*' "$1" | cut -d ' ' -f 2 | sort
}

low-list-projects() {
  find "$1" -maxdepth 3 -type d -name '.git' -exec dirname {} \; | xargs basename -a | sort
}

low-reset-backends() {
  sed '/#####/q' "$1" > "$1.bak"
  cp "$1.bak" "$1"
  echo "" >> "$1"
  low-add-backend "$1" $(low-list-projects "$2")
}

check_env() {
  if [ -z "$PROJECTS_DIR" ]; then
    echo "PROJECTS_DIR is not defined." > /dev/stderr
    return 1
  fi
  if [ -z "$CONFIG_FILE" ]; then
    echo "CONFIG_FILE is not defined." > /dev/stderr
    return 1
  fi
  echo "Everything looks ok."
  return 0
}

add-backend() {
  check_env > /dev/null
  low-add-backend "$CONFIG_FILE" "$@"
}

remove-backend() {
  check_env > /dev/null
  low-remove-backend "$CONFIG_FILE" "$@"
}

list-backend() {
  check_env > /dev/null
  low-list-backend "$CONFIG_FILE" | column -x
}

list-projects() {
  check_env > /dev/null
  low-list-projects "$PROJECTS_DIR" | column -x
}

reset-backends() {
  check_env > /dev/null
  low-reset-backends "$CONFIG_FILE" "$PROJECTS_DIR"
}

_backend() {
  local cur opts
  COMPREPLY=()
  opts=""
  cur="${COMP_WORDS[COMP_CWORD]}"
  backends=$(low-list-backend "$CONFIG_FILE")
  if [ "$1" == add-backend ]; then
    if [ -z "$backends" ]; then
      opts="$(low-list-projects "$PROJECTS_DIR")"
    else
      opts=$(grep -vxf <(echo "$backends") <(low-list-projects "$PROJECTS_DIR") | sort -u)
    fi
  elif [[ "$1" == remove-backend ]]; then
    opts="$backends"
  fi
  COMPREPLY=( $(compgen -W "$opts" -- "${cur}") )
  return 0
}

complete -F _backend add-backend remove-backend
