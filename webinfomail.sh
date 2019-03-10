#!/bin/bash
declare -r SENDMAIL='/usr/sbin/sendmail'
declare -r FROMMAIL="source@mail.com"
declare -r DESTINATOR="destination@mail.com"

mSubject="NGINX Access - $(date +%F)"

(printf "%s\n" \
        "From: $FROMMAIL" \
        "To: $DESTINATOR" \
        "Subject: $mSubject" \
        "`./webinfo.sh --bandwidth`";) | $SENDMAIL "$DESTINATOR"
