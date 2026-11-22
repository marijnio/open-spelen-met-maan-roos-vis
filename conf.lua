function love.conf(t)
  t.identity = "spelen-met-maan-roos-vis"

  local major, minor = 11, 5
  if love.getVersion then
    major, minor = love.getVersion()
  end
  if major == 12 and minor == 0 then
    t.version = "12.0"
  else
    t.version = "11.5"
  end

  local osName = love._os
  if not osName and love.system and love.system.getOS then
    osName = love.system.getOS()
  end
  local isMobile = (osName == "Android" or osName == "iOS")

  t.externalstorage = true

  t.window.title = "Spelen met Maan Roos Vis"
  t.window.icon = "logo.png"
  t.window.width = 1280
  t.window.height = 960
  t.window.minwidth = 640
  t.window.minheight = 480
  t.window.resizable = not isMobile
  t.window.fullscreen = isMobile
  t.window.fullscreentype = "desktop"
  if major >= 12 then
    t.highdpi = true
  else
    t.window.highdpi = true
  end
  t.window.vsync = 1

  t.modules.joystick = false
  t.modules.physics = false
  t.modules.touch = true
  t.modules.video = false
end