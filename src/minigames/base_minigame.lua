-- Shared base class for all 6 mini-games (background, standard chrome buttons, Jantje feedback).

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local BaseMinigame = {}
BaseMinigame.__index = BaseMinigame

local GOOD_FEEDBACK = {
  "fdbgd1a", "fdbgd1b", "fdbgd1c",
  "fdbgd2a", "fdbgd2b", "fdbgd2c",
  "fdbgd3a", "fdbgd3b",
  "fdbgd4a", "fdbgd4b",
}

local BAD_FEEDBACK = {
  "fdbft1a", "fdbft1b", "fdbft1c",
  "fdbft2a", "fdbft2b", "fdbft2c",
}

function BaseMinigame.new(app, config)
  local self = setmetatable({}, BaseMinigame)
  self.app = app
  self.config = config
  self.hotzones = HotzoneManager.new(app.audio)
  return self
end

function BaseMinigame:_buildChromeHotzones()
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
      self.app.audio:stop()
      self.app.scenes:switch("hub")
    end,
  })

  self.hotzones:add({
    id = "help",
    label = "Help",
    x = 80,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "help" },
    hoverImage = { "ui", "hel2" },
    onClick = function()
      if self.config.helpVo then
        self.app.audio:clearAndPlay("jantje", self.config.helpVo)
      end
    end,
  })
end

function BaseMinigame:enter(params)
  self:_buildChromeHotzones()
  if self.config.helpVo then
    self.app.audio:clearAndPlay("jantje", self.config.helpVo)
  end
  if self.config.onEnter then
    self.config.onEnter(self, params)
  end
end

function BaseMinigame:exit()
  if self.config.onExit then
    self.config.onExit(self)
  end
  self.hotzones:clear()
end

function BaseMinigame:reset()
  self:_buildChromeHotzones()
  if self.config.onReset then
    self.config.onReset(self)
  end
end

function BaseMinigame:playFeedback(isCorrect)
  local pool = isCorrect and GOOD_FEEDBACK or BAD_FEEDBACK
  local pick = pool[love.math.random(1, #pool)]
  self.app.audio:clearAndPlay("jantje", pick)
end

function BaseMinigame:update(dt)
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)
  if self.config.onUpdate then
    self.config.onUpdate(self, dt, vx, vy)
  end
end

function BaseMinigame:draw()
  if self.config.background then
    local bg = Assets.getImage("screens", self.config.background)
    if bg then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(bg, 0, 0)
    end
  end

  if self.config.onDraw then
    self.config.onDraw(self)
  end

  self.hotzones:draw(self.app.debugHotzones)

  if self.app.debugHotzones then
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 8, 8, 300, 22)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("[%s] %s (F1 debug | Esc terug)", self.config.id, self.config.title), 14, 13)
  end
end

function BaseMinigame:mousepressed(vx, vy, button)
  if self.hotzones:mousepressed(vx, vy, button) then
    return true
  end
  if self.config.onMousePressed then
    return self.config.onMousePressed(self, vx, vy, button)
  end
  return false
end

return BaseMinigame
