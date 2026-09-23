# JoOS — login shell bootstrap (runs once, at login on the live desktop user).
# Only reacts on the autologin tty (tty1); nested shells stay untouched.

if [[ $- == *l* ]] && [[ "$(tty)" == /dev/tty1 ]]; then
  if [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" ]]; then
    exec startjoos
  fi
fi