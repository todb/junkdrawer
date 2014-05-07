#!/bin/bash
# A one-liner (hah!) for checking all listening services for static
# links against openssl. This does briefly run under sudo (to get
# accurate PID information). Tested on Debian-derived linuces.
#
# Example:
# $ ./cardio.sh
# [sudo] password for todb:
# /opt/google/talkplugin/GoogleTalkPlugin: 1.0.1e 11 Feb 2013
# /usr/lib/postgresql/9.1/bin/postgres: 1.0.0
# /usr/lib/vmware/bin/vmware-hostd:
# /usr/sbin/cupsd:
#
# Notice that GoogleTalkPlugin in 1.0.1e (not 1.0.1g or later)
# and postgres is unaffected by the Heartbleed vuln:
#
# http://heartbleed.com/

CHECKLISTENINGPROGS=$(CHECKLISTENINGPIDS=$(sudo netstat -nlp \
  | grep "LISTEN " | sed -e 's/.* \([0-9]\+\)\/.*/\1/');
  for i in $CHECKLISTENINGPIDS;
  do ps --no-headers -p $i -o command;
  done | sed -e 's/^[^\/]*//' | \
  sed -e 's/ .*//' | sort -u) ;
  for a in $CHECKLISTENINGPROGS;
  do echo -n $a; echo -n ": " ;
  echo $(strings $a | grep -i 'openssl[ _-][0-9]' | \
  sed -e 's/.*openssl[ _-]\([^ ]\)/\1/i') ;
  done;
  unset CHECKLISTENINGPROGS;
  unset CHECKLISTENINGPIDS
