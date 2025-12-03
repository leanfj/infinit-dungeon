#!/bin/sh
printf '\033c\033]0;%s\a' InfinitDungeon
base_path="$(dirname "$(realpath "$0")")"
"$base_path/InfinitDungeon.x86_64" "$@"
