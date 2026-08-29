-- Migrated from hyprland.conf (Hyprland 0.56.0, commit d8dc50309c551cfa44fee70744397311b8b7c5fc)
-- Maintains the exact settings that were active in hyprland.conf.
-- Refer to the wiki for more information: https://wiki.hypr.land/Configuring/

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
require("monitors")

---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "kitty"
local fileManager = "nautilus"
local personalBrowser = 'helium-browser --profile-directory="Default" --new-window'
local workBrowser = 'helium-browser --profile-directory="Profile 1" --new-window'

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function()
	-- hl.exec_cmd("uwsm-app -- hyprdynamicmonitors run")
	hl.exec_cmd("noctalia")
	hl.exec_cmd("uwsm-app -- /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("uwsm-app -- kanata --cfg ~/.config/kanata/kanata.kbd --no-wait")
	hl.exec_cmd("uwsm-app -- nextcloud --background")

	-- Launch Work first. Once its window maps, focus it, preselect a right-side
	-- split, then launch Personal. This keeps Work left and Personal right.
	-- Workspace placement remains handled by hl.window_rule below.
	local workWindowSubscription
	workWindowSubscription = hl.on("window.open", function(window)
		if window.class ~= "helium" then
			return
		end

		workWindowSubscription:remove()
		hl.dispatch(hl.dsp.focus({ window = window }))
		hl.dispatch(hl.dsp.layout("preselect r"))
		hl.exec_cmd("uwsm-app -- " .. personalBrowser)
	end)
	hl.exec_cmd("uwsm-app -- " .. workBrowser)

	hl.exec_cmd("uwsm-app -- kitty")
	hl.exec_cmd("uwsm-app -- thunderbird")
	hl.exec_cmd("uwsm-app -- obsidian")
	hl.exec_cmd("uwsm-app -- discord")
	hl.exec_cmd("uwsm-app -- slack")
	hl.exec_cmd("uwsm-app -- ferdium")
	hl.exec_cmd("uwsm-app -- spotify")
	hl.exec_cmd("uwsm-app -- signal-desktop")

	-- Slow app launch fix -- set systemd vars
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Force all apps to use Wayland
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Allow better support for screen sharing (Google Meet, Discord, etc)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Force NVIDIA as the primary driver for all backends
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")

-- NVIDIA Hardware Acceleration fix
hl.env("NVD_BACKEND", "direct")

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})

-- Don't show update on first launch
hl.config({
	ecosystem = {
		no_update_news = true,
	},
})

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,

		border_size = 1,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		-- Set to true to enable resizing windows by clicking and dragging on borders and gaps
		resize_on_border = false,

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,

		layout = "dwindle",
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,

		-- Change transparency of focused and unfocused windows
		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = false,
	},
})

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/ for more
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
	master = {
		new_status = "master",
	},
})

----------------
----  MISC  ----
----------------

hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
		allow_session_lock_restore = true, -- If true, Hyprland will try to restore your last session on startup.
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		kb_layout = "pt",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 0,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = false,
		},
	},
})

-- gestures { workspace_swipe = true } -- was commented out in original hyprland.conf; left disabled

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "noctalia msg "

-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more.
-- Numbered headings and literal descriptions are parsed by Keybind Cheatsheet.

-- 1. Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Open file manager" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(personalBrowser), { description = "Open Personal browser" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(workBrowser), { description = "Open Work browser" })

-- 2. Noctalia Shell
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"), { description = "Open app launcher" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"), { description = "Open control center" })
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(ipc .. "panel-toggle session"), { description = "Open session menu" })
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"), { description = "Open Noctalia settings" })
hl.bind("ALT + TAB", hl.dsp.exec_cmd(ipc .. "window-switcher"), { description = "Open window switcher" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(ipc .. "session lock"), { description = "Lock session" })
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd(ipc .. "panel-toggle kenn/keybind-cheatsheet:cheatsheet"), {
	description = "Show keybind cheatsheet",
})

-- 3. Window Management
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Toggle pseudo tiling" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window with mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })

-- 4. Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output"), { description = "Capture current display" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region"), { description = "Capture selected region" })
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m window"), { description = "Capture active window" })

-- 5. Workspaces
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), {
		description = "Switch to workspace " .. i,
	})
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), {
		description = "Move window to workspace " .. i,
	})
end
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), {
	description = "Move window to scratchpad",
})
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })

-- 6. Audio and Brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), {
	locked = true,
	repeating = true,
	description = "Raise volume",
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), {
	locked = true,
	repeating = true,
	description = "Lower volume",
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), {
	locked = true,
	repeating = true,
	description = "Mute audio",
})
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(ipc .. "mic-mute"), {
	locked = true,
	repeating = true,
	description = "Mute microphone",
})
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), {
	locked = true,
	repeating = true,
	description = "Raise brightness",
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), {
	locked = true,
	repeating = true,
	description = "Lower brightness",
})

-- 7. Media
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(ipc .. "media next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "media play-pause"), { locked = true, description = "Play or pause media" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(ipc .. "media play-pause"), { locked = true, description = "Play or pause media" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(ipc .. "media previous"), { locked = true, description = "Previous track" })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

-- Keep numbered workspaces visible in Noctalia even while empty.
for i = 1, 10 do
	hl.workspace_rule({
		workspace = tostring(i),
		persistent = true,
	})
end

-- Workspace rules to assign apps to specific workspaces.
-- This is the ONLY workspace-assignment mechanism for these apps — do not
-- reintroduce `hyprctl dispatch exec [workspace N] app` in the autostart
-- block above; it races Hyprland's startup IPC/workspace-token state and
-- silently fails for most apps (see 2026-07-26 investigation).
hl.window_rule({ match = { class = "helium" }, workspace = "1" })
hl.window_rule({ match = { class = "kitty" }, workspace = "2" })
hl.window_rule({ match = { class = "org.mozilla.Thunderbird" }, workspace = "3" })
hl.window_rule({ match = { class = "obsidian" }, workspace = "4" })
hl.window_rule({ match = { class = "discord" }, workspace = "5" })
hl.window_rule({ match = { class = "Slack" }, workspace = "6" })
hl.window_rule({ match = { class = "ferdium" }, workspace = "7" })
hl.window_rule({ match = { class = "spotify" }, workspace = "8" })
hl.window_rule({ match = { class = "signal" }, workspace = "9" })

-- Noctalia settings window
hl.window_rule({
	match = { class = "dev.noctalia.Noctalia" },
	float = true,
	size = { 1080, 920 },
})

-- Noctalia surfaces: use Noctalia animations and Hyprland blur
hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

-- Example windowrule
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })

-- For Noctalia Color templates
require("noctalia").apply_theme()
