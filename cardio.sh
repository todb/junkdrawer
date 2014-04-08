#!/bin/bash

CHECKLISTENINGPROGS=$(CHECKLISTENINGPIDS=$(sudo netstat -nlp | grep "LISTEN " | sed -e 's/.* \([0-9]\+\)\/.*/\1/'); for i in $CHECKLISTENINGPIDS; do ps --no-headers -p $i -o command; done | sed -e 's/^[^\/]*//' | sed -e 's/ .*//' | sort -u) ; for a in $CHECKLISTENINGPROGS; do echo -n $a; echo -n ": " ; echo $(strings $a | grep -i 'openssl[ _-][0-9]' | sed -e 's/.*openssl[ _-]\([^ ]\)/\1/i') ; done; unset CHECKLISTENINGPROGS; unset CHECKLISTENINGPIDS
