#!/usr/bin/env bash
# JoOS live-environment customization (runs inside the archiso chroot).

set -e

echo "==> JoOS customize_airootfs begins"

# ---- Locale (default pt_BR, keep en_US around) -----------------------------
sed -i 's/^#\(en_US\.UTF-8\)/\1/; s/^#\(pt_BR\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf

# ---- Timezone --------------------------------------------------------------
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# ---- Hostname ---------------------------------------------------------------
echo "joos-live" > /etc/hostname

# ---- Pre-render the default theme into /etc/skel ----------------------------
# joos-theme reads $XDG_CONFIG_HOME; point it at the skeleton so every new
# user (live session included) boots with the "kingdom" look already applied.
# Must run BEFORE the user is created so `useradd -m` copies themed dotfiles.
export XDG_CONFIG_HOME=/etc/skel/.config
export HOME=/etc/skel
/usr/local/bin/joos-theme set kingdom >/dev/null 2>&1 || true
unset XDG_CONFIG_HOME HOME

# ---- Create the live desktop user -------------------------------------------
# Hyprland refuses to run as root, so the live session runs as a real user.
# Password is locked in the live environment; sudo is NOPASSWD (live only).
if ! id -u joos >/dev/null 2>&1; then
  useradd -m -G wheel,input,video,audio -s /bin/zsh joos
  passwd -dl joos
  echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-joos-live
  chmod 440 /etc/sudoers.d/10-joos-live
fi
mkdir -p /home/joos
chown joos:joos /home/joos

# Give the desktop user access to the JoOS scripts.
chmod 755 /usr/local/bin/joos-*
chmod 755 /usr/local/bin/startjoos

echo "==> JoOS customize_airootfs done"