#!/bin/bash

curl https://api.github.com/orgs/rapid7/repos?per_page=100 > out.json
for i in `grep git_url out.json | cut -f 2-10 -d ":" | sed s/[,\"]//g |
  sed s#git://github.com/#github-r7:# `; do git clone --depth=1 $i; done


