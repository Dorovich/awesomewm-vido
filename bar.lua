-- Libs
local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local color = require("colors")

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

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

-- IP address widget
local myipwidget = wibox.widget{
   {
      font = beautiful.font,
      widget = wibox.widget.textbox,
   },
   fg = color.magenta,
   widget = wibox.container.background,
}

local interface
if not is_raspi then
   interface = "enp3s0"
else
   interface = "wlan0"
end

local command = string.format("ip addr show %s | grep -oE '([[:digit:]]{1,3}.){3}[[:digit:]]{1,3}/' | cut -d'/' -f1", interface)

gears.timer {
   timeout = 10, -- seconds
   call_now  = true,
   autostart = true,
   callback = function()
      awful.spawn.easy_async_with_shell(string.format('bash -c "%s"', command),
                                        function(stdout, stderr, reason, exit_code)
                                           ip = string.gsub(stdout, "[\n\r]", "")
                                           if(ip ~= "") then
                                              myipwidget.widget.text = string.format(" %s", ip)
                                           else
                                              myipwidget.widget.text = string.format(" %s down", interface)
                                           end
      end)
   end
}

-- Separators
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
            height = dpi(22),
      })

      -- Add widgets to the wibox
      s.mywibox:setup {
         layout = wibox.layout.align.horizontal,
         { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            --mylauncher,
            sep.space,
            s.mylayoutbox, -- ponemos esto a la izquierda
            sep.space,
            s.mytaglist,
            sep.space,
            s.mypromptbox,
         },
         s.mytasklist, -- Middle widget
         { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            myipwidget,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            --s.mylayoutbox,
         },
      }
end)
