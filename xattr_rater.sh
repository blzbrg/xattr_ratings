#! /usr/bin/env bash

mode="$1"
file="$2"

if [ ! -e "$file" ]; then
    exit 1
fi

if [ -z "$(getfattr --match 'rating' "$file")" ]; then
    current_rating="0"
else
    current_rating=$(getfattr --name 'user.rating' --only-values "$file")
fi

if [ "$mode" = "get" ]; then
    echo "$current_rating"
else
    if [ "$mode" = "increase" ]; then
        delta="+ 1"
    else
        delta="- 1"
    fi

    new_rating=$(echo "$current_rating" | awk '{print $1'"$delta"';}')
    setfattr -n 'user.rating' -v "$new_rating" "$file"
    echo "Changed $file from $current_rating to $new_rating"
fi
