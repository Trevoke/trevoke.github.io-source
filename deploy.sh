#!/bin/bash
set -euo pipefail

# Refuse to run alongside a live `hugo server` -- it writes drafts/future
# content and a livereload script straight into public/ on disk, and this
# script has no diff review step, so that contamination would go live as-is.
if pgrep -f "hugo server" > /dev/null; then
  echo -e "\033[0;31mA 'hugo server' process is running -- kill it before deploying.\033[0m"
  pgrep -fa "hugo server"
  exit 1
fi

# public/ must be its own checkout of the pages repo. If it isn't (submodule
# never initialized), every git command below silently runs in the source
# repo instead and nothing reaches the live site.
if [ "$(git -C public rev-parse --show-toplevel 2>/dev/null)" != "$(cd public && pwd -P)" ]; then
  echo -e "\033[0;31mpublic/ is not a git checkout of the pages repo -- initialize the submodule first.\033[0m"
  exit 1
fi
if [ "$(git -C public symbolic-ref --short HEAD 2>/dev/null)" != "master" ]; then
  echo -e "\033[0;31mpublic/ is not on branch master -- run: git -C public checkout master && git -C public pull\033[0m"
  exit 1
fi

HUGO="${HUGO:-hugo}"
if ! command -v "$HUGO" > /dev/null; then
  echo -e "\033[0;31m'$HUGO' not found -- put hugo on PATH or set HUGO=/path/to/hugo.\033[0m"
  exit 1
fi

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Build the project.
"$HUGO" -t hugo-tufte

# Go To Public folder
cd public
# Add generated changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git diff --cached --quiet || git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

# add source changes to git
git add -A

git diff --cached --quiet || git commit -m "update generated site submodule"

git push origin master
