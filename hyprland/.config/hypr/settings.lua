hl.monitor({
  output = "eDP-1",
  mode = "2560x1600@60.00",
  position = "0x0",
  scale = 1.25,
  bitdepth = 10,
  cm = "hdredid",
  vrr = 1,
})

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("HYPRCURSOR_THEME", "catppuccin-mocha-mauve-cursors")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("GSK_RENDERER", "gl")

-- SSH via persistent ssh-agent (passphrase entered once per boot, cached in agent).
-- Set here, not in ~/.config/environment.d, because start-hyprland does not import
-- environment.d into launched apps (only KDE/systemd-user sessions do).
hl.env("SSH_AUTH_SOCK", "/run/user/1000/ssh-agent.socket")
hl.env("SSH_ASKPASS", "/usr/bin/ksshaskpass")
hl.env("SSH_ASKPASS_REQUIRE", "prefer")

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
      inactive_border = "rgba(595959aa)",
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 10,
    rounding_power = 2,
    active_opacity = 1.0,
    inactive_opacity = 0.94,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  master = {
    new_status = "master",
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = false,
  },
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0.2,
    touchpad = {
      natural_scroll = true,
    },
  },
})

for _, curve in ipairs({
  { name = "easeOutQuint", points = { { 0.23, 1 }, { 0.32, 1 } } },
  { name = "easeInOutCubic", points = { { 0.65, 0.05 }, { 0.36, 1 } } },
  { name = "linear", points = { { 0, 0 }, { 1, 1 } } },
  { name = "almostLinear", points = { { 0.5, 0.5 }, { 0.75, 1 } } },
  { name = "quick", points = { { 0.15, 0 }, { 0.1, 1 } } },
}) do
  hl.curve(curve.name, {
    type = "bezier",
    points = curve.points,
  })
end

for _, animation in ipairs({
  { leaf = "global", enabled = true, speed = 10, bezier = "default" },
  { leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" },
  { leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" },
  { leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" },
  { leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" },
  { leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" },
  { leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" },
  { leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" },
  { leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" },
  { leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" },
  { leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" },
  { leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" },
  { leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" },
  { leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
  { leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" },
  { leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" },
  { leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" },
}) do
  hl.animation(animation)
end

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
