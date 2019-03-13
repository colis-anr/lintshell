#!/usr/bin/env bash

plugins=`lintshell list | cut -f1 -d' '`

echo '# List of lintshell analyzers' > docs/analyzers.md

for p in $plugins; do
    mangle=`echo $p | sed s,/,-,g`
    lintshell show $p > docs/$mangle.md
    short=`lintshell show $p | grep Summary | cut -d':' -f2`
    echo "- [$p]($mangle.md) $short" >> docs/analyzers.md
done
