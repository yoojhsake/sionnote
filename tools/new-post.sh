#!/bin/bash
# 사용법: ./tools/new-post.sh "제목" m365-readiness [영문-파일이름]
title="$1"; cat="${2:-practice}"; slug="$3"; d=$(date +%F)
[ -z "$slug" ] && slug=$(echo "$title" | sed 's/[^A-Za-z0-9]\+/-/g; s/^-//; s/-$//' | tr 'A-Z' 'a-z')
[ -z "$slug" ] && slug="post-$(date +%H%M)"
f="_posts/$d-$slug.md"
sed "s|^title: .*|title: \"$title\"|; s|^categories: \[[^]]*\]|categories: [$cat]|" tools/post-template.md > "$f"
echo "만들었습니다: $f"
