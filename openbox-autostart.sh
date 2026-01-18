polybar &
dunst &
feh --bg-fill ~/Pictures/wp.png
xset r rate 200 100
xset -dpms s off
(sleep 3s && /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1) &
systemctl --user import-environment DISPLAY
dbus-update-activation-environment --systemd DISPLAY
systemctl --user restart xdg-desktop-portal-gtk.service
audio_dx3
