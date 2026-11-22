-- "Moet je mij zien" info screen (about.png) with Terug button back to Start Menu.

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local AboutState = {}
AboutState.__index = AboutState

function AboutState.new(app)
  local self = setmetatable({}, AboutState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  return self
end

function AboutState:_goBack()
  self.app.audio:stop()
  self.app.scenes:switch("start_menu")
end

function AboutState:enter()
  self.hotzones:clear()

  self.hotzones:add({
    id = "terug",
    label = "Terug",
    x = 12,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "terug" },
    hoverImage = { "ui", "teru2" },
    onClick = function()
      self:_goBack()
    end,
  })
end

function AboutState:exit()
  self.hotzones:clear()
end

function AboutState:update(_dt)
  local vx, vy = self.app.viewport:screenToVirtual(love.mouse.getPosition())
  self.hotzones:update(vx, vy)
end

function AboutState:draw()
  local bg = Assets.getImage("screens", "about")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  self.hotzones:draw(self.app.debugHotzones)
end

function AboutState:mousepressed(vx, vy, button)
  self.hotzones:mousepressed(vx, vy, button)
end

function AboutState:keypressed(key)
  if key == "escape" then
    self:_goBack()
  end
end

return AboutState
