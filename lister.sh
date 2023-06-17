#! /usr/bin/env bash

if [[ "$1" == -g ]]; then
    cond="> $2"
elif [[ "$1" == -l ]]; then
    cond="< $2"
else
    echo "Requires either -g Integer -l Integer" 1>&2
    exit 1
fi

# incomprehensible hack from https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

while read -r file; do
    rating=$("$dir"/xattr_rater.sh get "$file")
    err="$?"
    if [ "$err" -gt 0 ]; then
        echo "Error $err rating for $file" 1>&2
    fi

    if awk "BEGIN {if ($rating $cond) exit 0; else exit 1;}"; then
        echo "$file"
    fi
done
