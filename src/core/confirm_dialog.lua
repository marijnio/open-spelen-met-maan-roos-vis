-- Reusable Windows 3.1 style Confirmation Dialog (Stop / Quit prompt)

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

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

function ConfirmDialog.new(app, opts)
  opts = opts or {}
  local self = setmetatable({}, ConfirmDialog)
  self.app = app
  self.defaultTitle = opts.title or "Stoppen!"
  self.defaultPrompt = opts.prompt or "Weet je zeker dat je wilt stoppen?"
  self.title = self.defaultTitle
  self.prompt = self.defaultPrompt
  self.hotzones = HotzoneManager.new(app.audio)
  self.visible = false
  self.onConfirm = nil
  self.onCancel = nil
  self.font = love.graphics.newFont(14)
  self.titleFont = love.graphics.newFont(14)
  return self
end

function ConfirmDialog:open(onConfirm, onCancel, prompt, title)
  self.visible = true
  self.onConfirm = onConfirm
  self.onCancel = onCancel
  self.prompt = prompt or self.defaultPrompt
  self.title = title or self.defaultTitle

  self.hotzones:clear()
  self.hotzones:add({
    id = "quit_no",
    label = "Nee",
    x = BTN_LEFT_X,
    y = BTN_Y,
    w = BTN_W,
    h = BTN_H,
    onClick = function()
      self:close()
      if self.onCancel then
        self.onCancel()
      end
    end,
  })

  self.hotzones:add({
    id = "quit_yes",
    label = "Ja",
    x = BTN_RIGHT_X,
    y = BTN_Y,
    w = BTN_W,
    h = BTN_H,
    onClick = function()
      local cb = self.onConfirm
      self:close()
      if cb then
        cb()
      end
    end,
  })

  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function ConfirmDialog:close()
  self.visible = false
  self.hotzones:clear()
end

function ConfirmDialog:isOpen()
  return self.visible
end

function ConfirmDialog:update(_dt)
  if not self.visible then return end
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)
end

function ConfirmDialog:draw()
  if not self.visible then return end

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
  love.graphics.setFont(self.titleFont)
  love.graphics.printf(self.title, DIALOG_X + 3, DIALOG_Y + 7, DIALOG_W - 6, "center")

  -- Light yellow client area background
  love.graphics.setColor(1.0, 1.0, 0.60, 1)
  love.graphics.rectangle("fill", DIALOG_X + 3, DIALOG_Y + 25, DIALOG_W - 6, DIALOG_H - 28)

  -- Left-aligned prompt text
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setFont(self.font)
  love.graphics.printf(
    self.prompt,
    DIALOG_X + 18,
    DIALOG_Y + 36,
    DIALOG_W - 36,
    "left"
  )

  -- Left button: Cancel (Red X)
  drawWinButton(BTN_LEFT_X, BTN_Y, BTN_W, BTN_H, "knopan", self.hotzones.hoveredId == "quit_no")

  -- Right button: OK (Green OK)
  drawWinButton(BTN_RIGHT_X, BTN_Y, BTN_W, BTN_H, "knopok", self.hotzones.hoveredId == "quit_yes")

  self.hotzones:draw(self.app.debugHotzones)
  love.graphics.setColor(1, 1, 1, 1)
end

function ConfirmDialog:mousepressed(vx, vy, button)
  if not self.visible then return false end
  self.hotzones:mousepressed(vx, vy, button)
  return true
end

function ConfirmDialog:keypressed(key)
  if not self.visible then return false end
  if key == "escape" then
    self:close()
    if self.onCancel then
      self.onCancel()
    end
    return true
  elseif key == "return" or key == "space" then
    local cb = self.onConfirm
    self:close()
    if cb then
      cb()
    end
    return true
  end
  return true
end

return ConfirmDialog
