local terminal = "ghostty --gtk-single-instance=true"
local startup_terminal = terminal .. " --quit-after-last-window-closed=false --initial-window=false"

hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')

hl.on("hyprland.start", function()
  hl.exec_cmd(startup_terminal)
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("kwalletd6")
  hl.exec_cmd("/usr/lib/pam_kwallet_init")
  hl.exec_cmd("easyeffects --gapplication-service")
  hl.exec_cmd("hyprpaper & waybar & swaync & swayosd-server & hypridle")
end)
