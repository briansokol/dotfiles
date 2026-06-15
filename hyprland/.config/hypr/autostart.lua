local terminal = "ghostty --gtk-single-instance=true"
local startup_terminal = terminal .. " --quit-after-last-window-closed=false --initial-window=false"

hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')

hl.on("hyprland.start", function()
  hl.exec_cmd(startup_terminal)
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  -- ksecretd is launched by pam_kwallet5 at SDDM login but waits for its session
  -- environment before it can claim org.freedesktop.secrets on the user bus.
  -- pam_kwallet_init delivers that env over the PAM socket. It does NOT start a
  -- second daemon (starting kwalletd6 here is what previously fought over the
  -- one-shot socket). Plasma runs this via plasma-kwallet-pam.service; Hyprland
  -- does not, so trigger it manually. SSH uses ssh-agent.
  hl.exec_cmd("/usr/lib/pam_kwallet_init")
  hl.exec_cmd("easyeffects --gapplication-service")
  hl.exec_cmd("hyprpaper & waybar & swaync & swayosd-server & hypridle")
end)
