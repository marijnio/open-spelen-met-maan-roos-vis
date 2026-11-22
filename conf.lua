function love.conf(t)
  t.identity = "spelen-met-maan-roos-vis"
  t.version = "11.5"
  t.externalstorage = true

  t.window.title = "Spelen met Maan Roos Vis"
  t.window.icon = "logo.png"
  t.window.width = 1280
  t.window.height = 960
  t.window.minwidth = 640
  t.window.minheight = 480
  t.window.resizable = true
  t.window.highdpi = true
  t.window.vsync = 1

  t.modules.joystick = false
  t.modules.physics = false
  t.modules.touch = true
  t.modules.video = false
end
