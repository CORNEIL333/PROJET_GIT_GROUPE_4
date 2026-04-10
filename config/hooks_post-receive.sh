#!/bin/bash
# Post-receive hook – Notifier après un push
# Copier dans : /home/git/repos/MON_DEPOT.git/hooks/post-receive
while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref "$refname")
    echo "🔔 Nouveau push sur la branche : $branch"
    echo "   Commit : $newrev"
done
