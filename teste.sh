#!/bin/sh
printf '\033c\033]0;%s\a' memoria
base_path="$(dirname "$(realpath "$0")")"
"$base_path/teste.x86_64" "$@"
