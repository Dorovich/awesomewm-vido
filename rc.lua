-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
   naughty.notify({ preset = naughty.config.presets.critical,
                    title = "Oops, there were errors during startup!",
                    text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
   local in_error = false
   awesome.connect_signal("debug::error", function (err)
                             -- Make sure we don't go into an endless error loop
                             if in_error then return end
                             in_error = true

                             naughty.notify({ preset = naughty.config.presets.critical,
                                              title = "Oops, an error happened!",
                                              text = tostring(err) })
                             in_error = false
   end)
end
-- }}}

-- Check the hostname
local function getHostname()
    local f = io.popen("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()
    hostname = string.gsub(hostname, "\n$", "")
    return hostname
end
local hostname = getHostname()

if hostname == "Ness-net" then is_laptop = true
elseif hostname == "raspinet" then is_raspi = true
else
   is_laptop = false
   is_raspi = false
end

function do_if(boolean, result)
   if boolean then return result
   else return nil end
end

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = os.getenv("TERMINAL") or "st"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Script manager
if not is_raspi then
   scriptmanager = "scriptctl"
end

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
   awful.layout.suit.max,
   awful.layout.suit.tile,
   awful.layout.suit.floating,
   -- awful.layout.suit.tile.left,
   -- awful.layout.suit.tile.bottom,
   -- awful.layout.suit.tile.top,
   -- awful.layout.suit.fair,
   -- awful.layout.suit.fair.horizontal,
   -- awful.layout.suit.spiral,
   -- awful.layout.suit.spiral.dwindle,
   -- awful.layout.suit.max.fullscreen,
   -- awful.layout.suit.magnifier,
   -- awful.layout.suit.corner.nw,
   -- awful.layout.suit.corner.ne,
   -- awful.layout.suit.corner.sw,
   -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

local menu_awesome = { "awesome", myawesomemenu, beautiful.awesome_icon }
local menu_terminal = { "open terminal", terminal }

if has_fdo then
   mymainmenu = freedesktop.menu.build({
         before = { menu_awesome },
         after =  { menu_terminal }
   })
else
   mymainmenu = awful.menu({
         items = {
            menu_awesome,
            { "Debian", debian.menu.Debian_menu.Debian },
            menu_terminal,
         }
   })
end


mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
   awful.button({ }, 1, function(t) t:view_only() end),
   awful.button({ modkey }, 1, function(t)
         if client.focus then
            client.focus:move_to_tag(t)
         end
   end),
   awful.button({ }, 3, awful.tag.viewtoggle),
   awful.button({ modkey }, 3, function(t)
         if client.focus then
            client.focus:toggle_tag(t)
         end
   end),
   awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
   awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
   awful.button({ }, 1, function (c)
         -- if c == client.focus then
         --    c.minimized = true
         -- else
         if c ~= client.focus then
            c:emit_signal(
               "request::activate",
               "tasklist",
               {raise = true}
            )
         end
   end),
   awful.button({ }, 3, function()
         awful.menu.client_list({ theme = { width = 250 } })
   end),
   awful.button({ }, 4, function ()
         awful.client.focus.byidx(1)
   end),
   awful.button({ }, 5, function ()
         awful.client.focus.byidx(-1)
end))

local function set_wallpaper(s)
   -- Wallpaper
   if beautiful.wallpaper then
      local wallpaper = beautiful.wallpaper
      -- If wallpaper is a function, call it with the screen
      if type(wallpaper) == "function" then
         wallpaper = wallpaper(s)
      end
      gears.wallpaper.maximized(wallpaper, s, true)
   end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local sep = {
   space = wibox.widget {
      widget = wibox.widget.separator,
      orientation = "vertical",
      forced_width = dpi(8),
      color = beautiful.bg_normal,
   },
   line = wibox.widget {
      widget = wibox.widget.separator,
      orientation = "vertical",
      forced_width = dpi(10),
      color = "#ffffff",
   }
}

awful.screen.connect_for_each_screen(function(s)
      -- Wallpaper
      set_wallpaper(s)

      -- Each screen has its own tag table.
      awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

      -- Create a promptbox for each screen
      s.mypromptbox = awful.widget.prompt()
      -- Create an imagebox widget which will contain an icon indicating which layout we're using.
      -- We need one layoutbox per screen.
      s.mylayoutbox = awful.widget.layoutbox(s)
      s.mylayoutbox:buttons(gears.table.join(
                               awful.button({ }, 1, function () awful.layout.inc( 1) end),
                               awful.button({ }, 3, function () awful.layout.inc(-1) end),
                               awful.button({ }, 4, function () awful.layout.inc( 1) end),
                               awful.button({ }, 5, function () awful.layout.inc(-1) end)))
      -- Create a taglist widget
      s.mytaglist = awful.widget.taglist {
         screen  = s,
         filter  = awful.widget.taglist.filter.all,
         buttons = taglist_buttons
      }

      -- Create a tasklist widget
      s.mytasklist = awful.widget.tasklist {
         screen  = s,
         filter  = awful.widget.tasklist.filter.currenttags,
         buttons = tasklist_buttons
      }

      -- Create the wibox
      s.mywibox = awful.wibar({
            position = "top",
            screen = s,
            height = dpi(20),
            -- border_width = dpi(2),
      })

      -- Add widgets to the wibox
      s.mywibox:setup {
         layout = wibox.layout.align.horizontal,
         { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            sep.space,
            s.mytaglist,
            sep.space,
            s.mypromptbox,
         },
         s.mytasklist, -- Middle widget
         { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
         },
      }
end)
-- }}}

require("keys")

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = {},
     properties = { border_width = beautiful.border_width,
                    border_color = beautiful.border_normal,
                    focus = awful.client.focus.filter,
                    maximized = false,
                    maximized_vertical = false,
                    maximized_horizontal = false,
                    raise = true,
                    keys = clientkeys,
                    buttons = clientbuttons,
                    screen = awful.screen.preferred,
                    placement = awful.placement.no_overlap+awful.placement.no_offscreen+awful.placement.centered,
     }
   },

   -- Floating clients.
   { rule_any = {
        instance = {
           "DTA",  -- Firefox addon DownThemAll.
           "copyq",  -- Includes session name in class.
           "pinentry",
        },
        class = {
           "Arandr",
           "Blueman-manager",
           "Gpick",
           "Kruler",
           "MessageWin",  -- kalarm.
           "Sxiv",
           "mpv",
           "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
           "Wpa_gui",
           "veromix",
           "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
           "Event Tester",  -- xev.
        },
        role = {
           "AlarmWindow",  -- Thunderbird's calendar.
           "ConfigManager",  -- Thunderbird's about:config.
           "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
   }, properties = { floating = true }},

   -- Add titlebars to normal clients and dialogs
   { rule_any = {type = { "normal", "dialog" }
                }, properties = { titlebars_enabled = false }
   },

   -- Set Firefox to always map on the tag named "2" on screen 1.
   -- { rule = { class = "Firefox" },
   --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
                         -- Set the windows at the slave,
                         -- i.e. put it at the end of others instead of setting it master.
                         -- if not awesome.startup then awful.client.setslave(c) end

                         if awesome.startup
                            and not c.size_hints.user_position
                            and not c.size_hints.program_position then
                            -- Prevent clients from being unreachable after screen count changes.
                            awful.placement.no_offscreen(c)
                         end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
                         -- buttons for the titlebar
                         local buttons = gears.table.join(
                            awful.button({ }, 1, function()
                                  c:emit_signal("request::activate", "titlebar", {raise = true})
                                  awful.mouse.client.move(c)
                            end),
                            awful.button({ }, 3, function()
                                  c:emit_signal("request::activate", "titlebar", {raise = true})
                                  awful.mouse.client.resize(c)
                            end)
                         )

                         awful.titlebar(c) : setup {
                            { -- Left
                               awful.titlebar.widget.iconwidget(c),
                               buttons = buttons,
                               layout  = wibox.layout.fixed.horizontal
                            },
                            { -- Middle
                               { -- Title
                                  align  = "center",
                                  widget = awful.titlebar.widget.titlewidget(c)
                               },
                               buttons = buttons,
                               layout  = wibox.layout.flex.horizontal
                            },
                            { -- Right
                               awful.titlebar.widget.floatingbutton (c),
                               awful.titlebar.widget.maximizedbutton(c),
                               awful.titlebar.widget.stickybutton   (c),
                               awful.titlebar.widget.ontopbutton    (c),
                               awful.titlebar.widget.closebutton    (c),
                               layout = wibox.layout.fixed.horizontal()
                            },
                            layout = wibox.layout.align.horizontal
                                                   }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
                         c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- No borders on tiled clients on max layout
local function update_border_visibility(c)
   if c.floating or awful.layout.get(awful.screen.focused()).name ~= "max" then
      c.border_width = beautiful.border_width
   else
      c.border_width = 0
   end
end

local function update_border_visibility_ontag(t)
   if t.layout.name == "max" then
      for _, c in ipairs(t:clients()) do
         update_border_visibility(c)
      end
   else 
      for _, c in ipairs(t:clients()) do
         c.border_width = beautiful.border_width
      end
   end
end

client.connect_signal("manage", function(c) update_border_visibility(c) end)
client.connect_signal("property::floating", function(c) update_border_visibility(c) end)
tag.connect_signal("property::selected", function (t) update_border_visibility_ontag(t) end)
tag.connect_signal("property::layout", function(t) update_border_visibility_ontag(t) end)
-- }}}

-- Garbage collection
gears.timer {
   timeout = 30,
   autostart = true,
   callback = function() collectgarbage() end
}
