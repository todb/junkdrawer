#!/bin/bash

# This script assumes that the repo you're publishing to is "upstream" (not
# "origin") and that you either have a keyless PGP key to sign commits, and
# commit signing is configured, or that you don't care to sign commits at all.

# 

echo [*] $(date) : Generating API docs...
git checkout upstream/master &&
  git fetch upstream &&
  git checkout upstream/master &&
  bundle install && rake yard &&
  git branch -D gh-pages

sleep 3
echo [*] $(date): Publishing...
git checkout -b gh-pages --track upstream/gh-pages &&
  rm -rf api/ &&
  mv doc/ api/ &&
  git add --all api/ &&
  git commit -m "Update API docs" &&
  git push upstream

sleep 3
echo [*] Checking the generated timestamp in a minute...
sleep 60 &&
  FINISH_TIME=$(curl -L https://rapid7.github.io/metasploit-framework/api | grep Generated | sed 's/.*on //' | sed 's/ by.*//')
  echo [*] $FINISH_TIME : Apparently completed

