#! /usr/bin/env bash

mode="$1"
file="$2"

if [ ! -e "$file" ]; then
    echo "Nonexistant file $file" 1>&2
    exit 1
fi

if [ -z "$(getfattr --absolute-names --match 'rating' "$file")" ]; then
    current_rating="0"
else
    current_rating=$(getfattr --absolute-names --name 'user.rating' --only-values "$file")
fi

if [ "$mode" = "get" ]; then
    echo "$current_rating"
else
    if [ "$mode" = "increase" ]; then
        delta="+ 1"
    elif [ "$mode" = "decrease" ]; then
        delta="- 1"
    else
        echo "Unrecognized mode $mode" 1>&2
        exit 2
    fi

    new_rating=$(echo "$current_rating" | awk '{print $1'"$delta"';}')
    setfattr -n 'user.rating' -v "$new_rating" "$file"
    echo "Changed $file from $current_rating to $new_rating"
fi
