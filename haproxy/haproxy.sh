#!/bin/bash
_add-backend() {
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
    ' < "$1" >> "$1"
  done
}

_remove-backend() {
  for name in "${@:2}"; do
    sed -e "/^backend $name$/d" -e "/^  server $name $name-web:80 check resolvers docker resolve-prefer ipv4$/N; /^  server $name $name-web:80 check resolvers docker resolve-prefer ipv4/d" "$1" > "$1.bak"
    cp "$1.bak" "$1"
  done
}

_list-backends() {
  grep -o '^backend .*' "$1" | cut -d ' ' -f 2 | sort
}

_list-projects() {
  sort -u <(find "$1" -maxdepth 3 -type d -name '.git' -exec dirname {} \; | xargs basename -a)\
     <(docker ps --format "{{.Names}}" --filter "name=web" | sed 's/-web.*//')
}

_reset-backends() {
  sed '/#####/q' "$1" > "$1.bak"
  cp "$1.bak" "$1"
  echo "" >> "$1"
  _add-backend "$1" $(_list-projects "$2")
}

_update-backends() {
  _add-backend "$1" $(_list-projects "$2") 2>/dev/null
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
  _add-backend "$CONFIG_FILE" "$@"
}

list-backends() {
  check_env > /dev/null
  _list-backends "$CONFIG_FILE" | column -x
}

list-projects() {
  check_env > /dev/null
  _list-projects "$PROJECTS_DIR" | column -x
}

remove-backend() {
  check_env > /dev/null
  _remove-backend "$CONFIG_FILE" "$@"
}

reset-backends() {
  check_env > /dev/null
  _reset-backends "$CONFIG_FILE" "$PROJECTS_DIR"
}

update-backends() {
  check_env > /dev/null
  _update-backends "$CONFIG_FILE" "$PROJECTS_DIR"
}

_backend() {
  local cur opts
  COMPREPLY=()
  opts=""
  cur="${COMP_WORDS[COMP_CWORD]}"
  backends=$(_list-backends "$CONFIG_FILE")
  if [ "$1" == add-backend ]; then
    if [ -z "$backends" ]; then
      opts="$(_list-projects "$PROJECTS_DIR")"
    else
      opts=$(grep -vxf <(echo "$backends") <(_list-projects "$PROJECTS_DIR") | sort -u)
    fi
  elif [[ "$1" == remove-backend ]]; then
    opts="$backends"
  fi
  COMPREPLY=( $(compgen -W "$opts" -- "${cur}") )
  return 0
}

complete -F _backend add-backend remove-backend
