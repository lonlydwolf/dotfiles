#!/bin/sh

MEDIA_CONTROL=/opt/homebrew/bin/media-control

case "${BUTTON:-left}" in
  right) "$MEDIA_CONTROL" next-track ;;
  other) "$MEDIA_CONTROL" previous-track ;;
  *) "$MEDIA_CONTROL" toggle-play-pause ;;
esac
