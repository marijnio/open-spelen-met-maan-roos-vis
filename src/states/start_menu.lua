-- Start menu / title screen (ts.png): Stop (with confirmation popup), Moet je mij zien (About), and Start (Hub).

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local StartMenuState = {}
StartMenuState.__index = StartMenuState

local DIALOG_W = 304
local DIALOG_H = 160
local DIALOG_X = math.floor((640 - DIALOG_W) / 2) -- 168
local DIALOG_Y = math.floor((480 - DIALOG_H) / 2) -- 160

local BTN_W = 72
local BTN_H = 52
local BTN_Y = DIALOG_Y + DIALOG_H - 14 - BTN_H -- 254
local BTN_LEFT_X = DIALOG_X + 14 -- 182
local BTN_RIGHT_X = DIALOG_X + DIALOG_W - 14 - BTN_W -- 386

local function drawWinButton(x, y, w, h, iconKey, isHovered)
  -- Outer 1px black border
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)

  -- Button face background (standard Windows 3.1 grey)
  love.graphics.setColor(0.75, 0.75, 0.75, 1)
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)

  -- 3D Bevel
  -- Top and left highlight (white)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.line(x + 1, y + 1, x + w - 2, y + 1)
  love.graphics.line(x + 1, y + 1, x + 1, y + h - 2)

  -- Bottom and right shadow (dark gray)
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.line(x + 1, y + h - 2, x + w - 1, y + h - 2)
  love.graphics.line(x + w - 2, y + 1, x + w - 2, y + h - 1)

  -- Icon centered on button face
  local icon = Assets.getImage("ui", iconKey)
  if icon then
    local iw, ih = icon:getDimensions()
    local ix = x + math.floor((w - iw) * 0.5)
    local iy = y + math.floor((h - ih) * 0.5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(icon, ix, iy)
  end
end

function StartMenuState.new(app)
  local self = setmetatable({}, StartMenuState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.popupHotzones = HotzoneManager.new(app.audio)
  self.showQuitPopup = false
  self.isExiting = false
  self.exitTimer = 0
  return self
end

function StartMenuState:_buildMainHotzones()
  self.hotzones:clear()

  -- Bottom-left: Stop button -> Quit confirmation popup
  -- No hoverVo here: voice sample plays when the confirmation menu actually opens
  self.hotzones:add({
    id = "stop",
    label = "Stoppen",
    x = 12,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "stop" },
    hoverImage = { "ui", "sto2" },
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

  -- Left button: Cancel (Red X - knopan) -> close dialog
  self.popupHotzones:add({
    id = "quit_no",
    label = "Nee",
    x = BTN_LEFT_X,
    y = BTN_Y,
    w = BTN_W,
    h = BTN_H,
    onClick = function()
      self:closeQuitPopup()
    end,
  })

  -- Right button: Confirm quit (Green OK - knopok) -> show aftitel and exit
  self.popupHotzones:add({
    id = "quit_yes",
    label = "Ja",
    x = BTN_RIGHT_X,
    y = BTN_Y,
    w = BTN_W,
    h = BTN_H,
    onClick = function()
      self:confirmQuit()
    end,
  })

  -- Voiceover sample starts playing when you actually open the menu:
  self.app.audio:clearAndPlay("jantje", "stop")
end

function StartMenuState:closeQuitPopup()
  self.showQuitPopup = false
  self.popupHotzones:clear()
  self.app.audio:stop()
end

function StartMenuState:confirmQuit()
  self.showQuitPopup = false
  self.popupHotzones:clear()
  self.hotzones:clear()
  self.isExiting = true
  self.exitTimer = 0
  self.app.audio:stopMusic()
  self.app.audio:clearAndPlay("jantje", "stopbeve")
end

function StartMenuState:enter()
  self.isExiting = false
  self.exitTimer = 0
  self.showQuitPopup = false
  self:_buildMainHotzones()
end

function StartMenuState:exit()
  self.showQuitPopup = false
  self.isExiting = false
  self.hotzones:clear()
  self.popupHotzones:clear()
  self.app.audio:stopMusic()
end

function StartMenuState:update(dt)
  if self.isExiting then
    self.exitTimer = self.exitTimer + dt
    if self.exitTimer >= 2.6 or not self.app.audio:isPlaying() then
      love.event.quit()
    end
    return
  end

  local vx, vy = self.app:getVirtualPointer()
  if self.showQuitPopup then
    self.popupHotzones:update(vx, vy, self.app.isTouchMode)
  else
    self.hotzones:update(vx, vy, self.app.isTouchMode)
  end
end

function StartMenuState:_drawQuitPopup()
  -- Window frame border: 3px light blue / cyan
  love.graphics.setColor(0.65, 0.79, 0.94, 1)
  for b = 0, 2 do
    love.graphics.rectangle("line", DIALOG_X + b + 0.5, DIALOG_Y + b + 0.5, DIALOG_W - 1 - 2 * b, DIALOG_H - 1 - 2 * b)
  end

  -- Red title bar
  love.graphics.setColor(0.92, 0.05, 0.05, 1)
  love.graphics.rectangle("fill", DIALOG_X + 3, DIALOG_Y + 3, DIALOG_W - 6, 22)

  -- White centered title bar text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Stoppen!", DIALOG_X + 3, DIALOG_Y + 7, DIALOG_W - 6, "center")

  -- Light yellow client area background
  love.graphics.setColor(1.0, 1.0, 0.60, 1)
  love.graphics.rectangle("fill", DIALOG_X + 3, DIALOG_Y + 25, DIALOG_W - 6, DIALOG_H - 28)

  -- Left-aligned prompt text
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf(
    "Wil je 'Spelen met maan roos vis'\necht verlaten?",
    DIALOG_X + 18,
    DIALOG_Y + 36,
    DIALOG_W - 36,
    "left"
  )

  -- Left button: Cancel (Red X)
  drawWinButton(BTN_LEFT_X, BTN_Y, BTN_W, BTN_H, "knopan", self.popupHotzones.hoveredId == "quit_no")

  -- Right button: OK (Green OK)
  drawWinButton(BTN_RIGHT_X, BTN_Y, BTN_W, BTN_H, "knopok", self.popupHotzones.hoveredId == "quit_yes")

  self.popupHotzones:draw(self.app.debugHotzones)
  love.graphics.setColor(1, 1, 1, 1)
end

function StartMenuState:draw()
  if self.isExiting then
    local aftitel = Assets.getImage("screens", "aftitel")
    if aftitel then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(aftitel, 0, 0)
    else
      love.graphics.clear(0, 0, 0, 1)
    end
    return
  end

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
  if self.isExiting then
    love.event.quit()
    return
  end

  if self.showQuitPopup then
    self.popupHotzones:mousepressed(vx, vy, button)
  else
    self.hotzones:mousepressed(vx, vy, button)
  end
end

function StartMenuState:keypressed(key)
  if self.isExiting then
    love.event.quit()
    return
  end

  if key == "escape" then
    if self.showQuitPopup then
      self:closeQuitPopup()
    else
      self:openQuitPopup()
    end
  elseif key == "return" or key == "space" then
    if self.showQuitPopup then
      self:confirmQuit()
    end
  end
end

return StartMenuState
