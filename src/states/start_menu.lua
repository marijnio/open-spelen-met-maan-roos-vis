-- Start menu / title screen (ts.png): Stop (with confirmation popup), Moet je mij zien (About), and Start (Hub).

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local StartMenuState = {}
StartMenuState.__index = StartMenuState

local DIALOG_X = 130
local DIALOG_Y = 165
local DIALOG_W = 380
local DIALOG_H = 150

function StartMenuState.new(app)
  local self = setmetatable({}, StartMenuState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.popupHotzones = HotzoneManager.new(app.audio)
  self.showQuitPopup = false
  return self
end

function StartMenuState:_buildMainHotzones()
  self.hotzones:clear()

  -- Bottom-left: Stop button -> Quit confirmation popup
  self.hotzones:add({
    id = "stop",
    label = "Stoppen",
    x = 12,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "stop" },
    hoverImage = { "ui", "sto2" },
    hoverVo = { "jantje", "stop" },
    onClick = function()
      self:openQuitPopup()
    end,
  })

  -- Bottom-center: "Moet je mij zien" -> About screen
  self.hotzones:add({
    id = "about",
    label = "Moet je mij zien",
    x = 290,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "moetje" },
    hoverImage = { "ui", "moetj2" },
    onClick = function()
      self.app.audio:stop()
      self.app.scenes:switch("about")
    end,
  })

  -- Bottom-right: Traffic light (Start) -> Main Hub
  self.hotzones:add({
    id = "start",
    label = "Start",
    x = 568,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "start" },
    hoverImage = { "ui", "star2" },
    onClick = function()
      self.app.audio:stop()
      self.app.scenes:switch("hub")
    end,
  })
end

function StartMenuState:openQuitPopup()
  self.showQuitPopup = true
  self.popupHotzones:clear()

  self.popupHotzones:add({
    id = "quit_yes",
    label = "Ja",
    x = 225,
    y = 235,
    w = 60,
    h = 60,
    normalImage = { "ui", "okee" },
    hoverImage = { "ui", "oke2" },
    onClick = function()
      love.event.quit()
    end,
  })

  self.popupHotzones:add({
    id = "quit_no",
    label = "Nee",
    x = 355,
    y = 235,
    w = 60,
    h = 60,
    normalImage = { "ui", "terug" },
    hoverImage = { "ui", "teru2" },
    onClick = function()
      self:closeQuitPopup()
    end,
  })

  self.app.audio:clearAndPlay("jantje", "stopbeve")
end

function StartMenuState:closeQuitPopup()
  self.showQuitPopup = false
  self.popupHotzones:clear()
  self.app.audio:stop()
end

function StartMenuState:enter()
  self.showQuitPopup = false
  self:_buildMainHotzones()
end

function StartMenuState:exit()
  self.showQuitPopup = false
  self.hotzones:clear()
  self.popupHotzones:clear()
end

function StartMenuState:update(_dt)
  local vx, vy = self.app.viewport:screenToVirtual(love.mouse.getPosition())
  if self.showQuitPopup then
    self.popupHotzones:update(vx, vy)
  else
    self.hotzones:update(vx, vy)
  end
end

function StartMenuState:_drawQuitPopup()
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle("fill", 0, 0, 640, 480)

  -- Panel background & border
  love.graphics.setColor(0.97, 0.95, 0.88, 1)
  love.graphics.rectangle("fill", DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H, 8, 8)
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", DIALOG_X, DIALOG_Y, DIALOG_W, DIALOG_H, 8, 8)
  love.graphics.setLineWidth(1)

  -- Prompt text
  love.graphics.setColor(0.12, 0.12, 0.12, 1)
  love.graphics.printf(
    "Wil je 'Spelen met maan roos vis' echt verlaten?",
    DIALOG_X + 16,
    DIALOG_Y + 22,
    DIALOG_W - 32,
    "center"
  )

  -- Ja / Nee modal buttons
  self.popupHotzones:draw(self.app.debugHotzones)

  love.graphics.setColor(0.15, 0.15, 0.15, 1)
  love.graphics.printf("Ja", 225, 297, 60, "center")
  love.graphics.printf("Nee", 355, 297, 60, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

function StartMenuState:draw()
  local bg = Assets.getImage("screens", "ts")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  self.hotzones:draw(self.app.debugHotzones)

  if self.showQuitPopup then
    self:_drawQuitPopup()
  end
end

function StartMenuState:mousepressed(vx, vy, button)
  if self.showQuitPopup then
    self.popupHotzones:mousepressed(vx, vy, button)
  else
    self.hotzones:mousepressed(vx, vy, button)
  end
end

function StartMenuState:keypressed(key)
  if key == "escape" then
    if self.showQuitPopup then
      self:closeQuitPopup()
    else
      self:openQuitPopup()
    end
  end
end

return StartMenuState
