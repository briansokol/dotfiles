local terminal = "ghostty --gtk-single-instance=true"
local file_manager = "dolphin"
local menu = "rofi -show drun"
local windows = "rofi -show window"
local main_mod = "SUPER"
local super_shift = "SUPER + SHIFT"

hl.bind(main_mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + A", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + Q", hl.dsp.window.kill())
hl.bind(main_mod .. " + W", hl.dsp.window.close())
hl.bind(main_mod .. " + C", hl.dsp.window.kill())
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(main_mod .. " + M", hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(main_mod .. " + E", hl.dsp.exec_cmd(file_manager))
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(main_mod .. " + TAB", hl.dsp.exec_cmd(windows))
hl.bind(main_mod .. " + P", hl.dsp.window.pseudo())
hl.bind(main_mod .. " + R", hl.dsp.layout("togglesplit"))

hl.bind(main_mod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(main_mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(main_mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(main_mod .. " + L", hl.dsp.focus({ direction = "r" }))

for index, key in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
  local workspace = tostring(index)
  if index == 10 then
    workspace = "10"
  end

  hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
  hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })

hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")

hl.bind(
  "XF86MonBrightnessUp",
  hl.dsp.exec_cmd("~/.local/bin/brightness-control up"),
  {
    locked = true,
    repeating = true,
    description = "Logarithmic brightness up",
  }
)
hl.bind(
  "XF86MonBrightnessDown",
  hl.dsp.exec_cmd("~/.local/bin/brightness-control down"),
  {
    locked = true,
    repeating = true,
    description = "Logarithmic brightness down",
  }
)

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl previous"), { locked = true })

hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("CTRL + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"))

hl.bind(super_shift .. " + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(main_mod .. " + SHIFT + V", hl.dsp.exec_cmd("~/.config/rofi/scripts/clipboard.sh"))
hl.bind(main_mod .. " + PERIOD", hl.dsp.exec_cmd("rofimoji --selector rofi --action copy"))

hl.bind(main_mod .. " + S", hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace magic"))
hl.bind(super_shift .. " + S", hl.dsp.exec_cmd("hyprctl dispatch movetoworkspacesilent special:magic"))
