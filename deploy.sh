#!/bin/bash

# Refuse to run alongside a live `hugo server` -- it writes drafts/future
# content and a livereload script straight into public/ on disk, and this
# script has no diff review step, so that contamination would go live as-is.
if pgrep -f "hugo server" > /dev/null; then
  echo -e "\033[0;31mA 'hugo server' process is running -- kill it before deploying.\033[0m"
  pgrep -fa "hugo server"
  exit 1
fi

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Build the project.
hugo -t hugo-tufte

# Go To Public folder
cd public
# Add generated changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..

# add source changes to git
git add -A

git commit -am "update generated site submodule"

git push origin master
