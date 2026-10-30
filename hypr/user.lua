-- --- hypr/user.lua --------------------------------------------------------
-- Your Hyprland overrides, in Ryoku's `hl` Lua API. Loaded LAST, so anything
-- here wins over Ryoku's defaults and over Ryoku Settings. Updates never touch
-- it. Reach for it only for raw config the GUI does not expose.
--
-- --- who owns what --------------------------------------------------------
--   Ryoku defaults   the base modules           replaced by updates   don't edit
--   Ryoku Settings   settings.lua, rebinds.lua  the GUI writes these  edit in-app
--   you              this file (edit it here); whole-file forks in user_edits  yours
--
-- --- take over a whole module ---------------------------------------------
-- Copy it into the overlay at the same path and edit there, e.g.
--   ~/.config/ryoku/user_edits/hypr/modules/binds.lua
-- You then own that file: `ryoku doctor` warns when an update changes the
-- original, and `ryoku reset hypr/modules/binds.lua` hands it back.
--
-- --- examples -------------------------------------------------------------
-- hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("kitty"))
-- hl.window_rule({ name = "float-mpv", match = { class = "mpv" }, float = true })
-- hl.config({ general = { border_size = 3 } })

-- iris (Shima) panels: Super+Esc = Control Center (quick settings), Super+N = left panel.
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("qs -c shell ipc call iris controlCenter toggle"), { dont_inhibit = true })
hl.bind("SUPER + N",      hl.dsp.exec_cmd("qs -c shell ipc call iris focus toggle"))

-- Sleep the laptop.
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("ryoku-shell suspend"))

-- Lock screen -> desktop transition overlay (driven by the r1999-2 qylock theme).
hl.on("hyprland.start", function()
    -- ~/Scripts/BootUp.sh restarts it fresh and waits until it answers.
    hl.exec_cmd("$HOME/Scripts/BootUp.sh")
end)

-- Lock with the rising curtain; falls back to a plain lock if the overlay is down.
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -p $HOME/.config/custom-desktop/unlock-reveal ipc call reveal lockIn || ryoku-shell lock"))

-- Brightness keys: also ask the iris top-bar Island to show the level (Ryoku's
-- shipped binds only feed its own bottom OSD, which is hidden under iris).
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("sleep 0.15; qs -c shell ipc call brightness refresh; qs -c shell ipc call osd brightness"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sleep 0.15; qs -c shell ipc call brightness refresh; qs -c shell ipc call osd brightness"), { locked = true, repeating = true })

-- Files (Nautilus): tile like other apps instead of Ryoku's floating window,
-- which always sat above tiled windows. File pickers ("Open File" etc.) still float.
hl.window_rule({
    name  = "tile-nautilus",
    match = { class = "org.gnome.Nautilus" },
    tile  = true,
})
