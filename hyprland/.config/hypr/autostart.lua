local terminal = "ghostty --gtk-single-instance=true"
local startup_terminal = terminal .. " --quit-after-last-window-closed=false --initial-window=false"

hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')
hl.exec_cmd('gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-mauve-cursors"')

hl.on("hyprland.start", function()
  -- xdg-desktop-portal.service has Requisite=graphical-session.target, which
  -- Hyprland never activates on its own. Without it the portal refuses to start,
  -- so any Qt app that registers with the portal (ksecretd, swaync) fails with
  -- "Could not activate remote peer 'org.freedesktop.portal.Desktop'".
  -- graphical-session.target itself has RefuseManualStart=yes, so we start our
  -- hyprland-session.target (BindsTo it), which pulls it up as a dependency.
  -- Import env into the user bus first so portal-activated services inherit it.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")
  hl.exec_cmd("systemctl --user start hyprland-session.target")
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
  hl.exec_cmd("hyprctl setcursor catppuccin-mocha-mauve-cursors 24")
  hl.exec_cmd("wl-paste --type text --watch cliphist store &")
  hl.exec_cmd("wl-paste --type image --watch cliphist store &")
  hl.exec_cmd("hyprpm reload -n")
  hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh init")
  hl.exec_cmd("waybar & swaync & swayosd-server & hypridle")
end)
