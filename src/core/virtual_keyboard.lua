-- Built-in Windows 3.1 style QWERTY on-screen keyboard for touch-friendly name entry.

local HotzoneManager = require("src.core.hotzone")

local VirtualKeyboard = {}
VirtualKeyboard.__index = VirtualKeyboard

local PANEL_X = 20
local PANEL_Y = 206
local PANEL_W = 600
local PANEL_H = 262

local KEY_W = 52
local KEY_H = 52
local KEY_GAP_X = 6
local KEY_GAP_Y = 8

local ROW1_Y = PANEL_Y + 15 -- 221
local ROW2_Y = ROW1_Y + KEY_H + KEY_GAP_Y -- 281
local ROW3_Y = ROW2_Y + KEY_H + KEY_GAP_Y -- 341
local ROW4_Y = ROW3_Y + KEY_H + KEY_GAP_Y -- 401

local ROW1_KEYS = { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" }
local ROW2_KEYS = { "a", "s", "d", "f", "g", "h", "j", "k", "l" }
local ROW3_KEYS = { "z", "x", "c", "v", "b", "n", "m" }

local PRESSED_DURATION = 0.10

local function drawKeyButton(x, y, w, h, isHovered, isPressed, isActive)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)

  if isPressed then
    love.graphics.setColor(0.66, 0.66, 0.66, 1)
  elseif isActive then
    love.graphics.setColor(0.90, 0.90, 0.78, 1)
  elseif isHovered then
    love.graphics.setColor(0.84, 0.84, 0.84, 1)
  else
    love.graphics.setColor(0.76, 0.76, 0.76, 1)
  end
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)

  local sunken = isPressed or isActive
  local topLeft = sunken and 0.45 or 1.0
  local bottomRight = sunken and 1.0 or 0.45

  love.graphics.setColor(topLeft, topLeft, topLeft, 1)
  love.graphics.line(x + 1, y + 1, x + w - 2, y + 1)
  love.graphics.line(x + 1, y + 1, x + 1, y + h - 2)

  love.graphics.setColor(bottomRight, bottomRight, bottomRight, 1)
  love.graphics.line(x + 1, y + h - 2, x + w - 1, y + h - 2)
  love.graphics.line(x + w - 2, y + 1, x + w - 2, y + h - 1)
end

local function drawShiftIcon(x, y, w, h, active)
  local cx = x + math.floor(w * 0.5)
  local cy = y + math.floor(h * 0.5)
  if active then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.polygon("fill", cx, cy - 11, cx - 10, cy + 1, cx + 10, cy + 1)
    love.graphics.rectangle("fill", cx - 4, cy + 1, 8, 9)
  else
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(
      cx, cy - 10,
      cx - 10, cy + 1,
      cx - 4, cy + 1,
      cx - 4, cy + 10,
      cx + 4, cy + 10,
      cx + 4, cy + 1,
      cx + 10, cy + 1,
      cx, cy - 10
    )
    love.graphics.setLineWidth(1)
  end
end

local function drawBackspaceIcon(x, y, w, h)
  local cx = x + math.floor(w * 0.5)
  local cy = y + math.floor(h * 0.5)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.polygon("fill", cx - 12, cy, cx - 3, cy - 7, cx - 3, cy + 7)
  love.graphics.rectangle("fill", cx - 3, cy - 2, 15, 4)
end

function VirtualKeyboard.new(app, callbacks)
  callbacks = callbacks or {}
  local self = setmetatable({}, VirtualKeyboard)
  self.app = app
  self.onChar = callbacks.onChar
  self.onBackspace = callbacks.onBackspace
  self.hotzones = HotzoneManager.new(app.audio)
  self.shift = true
  self.pressedId = nil
  self.pressedTimer = 0
  self.keyFont = love.graphics.newFont(20)
  self.labelFont = love.graphics.newFont(16)
  self.keys = {}
  self:_buildKeys()
  return self
end

function VirtualKeyboard:_registerKey(spec)
  table.insert(self.keys, spec)
  self.hotzones:add({
    id = spec.id,
    label = spec.label or spec.lower or spec.char or spec.id,
    x = spec.x,
    y = spec.y,
    w = spec.w,
    h = spec.h,
    onClick = function()
      self.pressedId = spec.id
      self.pressedTimer = PRESSED_DURATION
      if spec.kind == "shift" then
        self.shift = not self.shift
      elseif spec.kind == "backspace" then
        if self.onBackspace then
          self.onBackspace()
        end
      elseif spec.kind == "letter" then
        local ch = self.shift and spec.upper or spec.lower
        if self.onChar then
          self.onChar(ch)
        end
      elseif spec.kind == "char" then
        if self.onChar then
          self.onChar(spec.char)
        end
      end
    end,
  })
end

function VirtualKeyboard:_buildKeys()
  self.keys = {}
  self.hotzones:clear()

  -- Row 1: 10 letters (total width 574px -> startX = 33)
  local row1StartX = 33
  for i, ch in ipairs(ROW1_KEYS) do
    self:_registerKey({
      id = "vk_" .. ch,
      kind = "letter",
      lower = ch,
      upper = string.upper(ch),
      x = row1StartX + (i - 1) * (KEY_W + KEY_GAP_X),
      y = ROW1_Y,
      w = KEY_W,
      h = KEY_H,
    })
  end

  -- Row 2: 9 letters (total width 516px -> startX = 62)
  local row2StartX = 62
  for i, ch in ipairs(ROW2_KEYS) do
    self:_registerKey({
      id = "vk_" .. ch,
      kind = "letter",
      lower = ch,
      upper = string.upper(ch),
      x = row2StartX + (i - 1) * (KEY_W + KEY_GAP_X),
      y = ROW2_Y,
      w = KEY_W,
      h = KEY_H,
    })
  end

  -- Row 3: Shift (81px) + 7 letters + Backspace (81px), flush 33..607
  self:_registerKey({
    id = "vk_shift",
    kind = "shift",
    label = "Shift",
    x = 33,
    y = ROW3_Y,
    w = 81,
    h = KEY_H,
  })

  local row3StartX = 120
  for i, ch in ipairs(ROW3_KEYS) do
    self:_registerKey({
      id = "vk_" .. ch,
      kind = "letter",
      lower = ch,
      upper = string.upper(ch),
      x = row3StartX + (i - 1) * (KEY_W + KEY_GAP_X),
      y = ROW3_Y,
      w = KEY_W,
      h = KEY_H,
    })
  end

  self:_registerKey({
    id = "vk_backspace",
    kind = "backspace",
    label = "Wis",
    x = 526,
    y = ROW3_Y,
    w = 81,
    h = KEY_H,
  })

  -- Row 4: '-' + Spatie + '\'' aligned under z..m (120..520)
  self:_registerKey({
    id = "vk_hyphen",
    kind = "char",
    char = "-",
    label = "-",
    x = 120,
    y = ROW4_Y,
    w = KEY_W,
    h = KEY_H,
  })

  self:_registerKey({
    id = "vk_space",
    kind = "char",
    char = " ",
    label = "Spatie",
    x = 178,
    y = ROW4_Y,
    w = 284,
    h = KEY_H,
  })

  self:_registerKey({
    id = "vk_apostrophe",
    kind = "char",
    char = "'",
    label = "'",
    x = 468,
    y = ROW4_Y,
    w = KEY_W,
    h = KEY_H,
  })
end

function VirtualKeyboard:setShift(enabled)
  self.shift = not not enabled
end

function VirtualKeyboard:reset(shiftOn)
  self.shift = (shiftOn ~= false)
  self.pressedId = nil
  self.pressedTimer = 0
end

function VirtualKeyboard:update(dt, vx, vy)
  if self.pressedTimer > 0 then
    self.pressedTimer = self.pressedTimer - dt
    if self.pressedTimer <= 0 then
      self.pressedTimer = 0
      self.pressedId = nil
    end
  end
  self.hotzones:update(vx, vy, self.app.isTouchMode)
end

function VirtualKeyboard:draw()
  -- Outer 1px black border + pale yellow panel matching highsy1/highsy2
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", PANEL_X + 0.5, PANEL_Y + 0.5, PANEL_W - 1, PANEL_H - 1)
  love.graphics.setColor(1.0, 1.0, 0.60, 1)
  love.graphics.rectangle("fill", PANEL_X + 1, PANEL_Y + 1, PANEL_W - 2, PANEL_H - 2)

  local hovered = not self.app.isTouchMode and self.hotzones.hoveredId or nil

  for _, key in ipairs(self.keys) do
    local isHovered = (hovered == key.id)
    local isPressed = (self.pressedId == key.id)
    local isActive = (key.kind == "shift") and self.shift
    drawKeyButton(key.x, key.y, key.w, key.h, isHovered, isPressed, isActive)

    if key.kind == "shift" then
      drawShiftIcon(key.x, key.y, key.w, key.h, self.shift)
    elseif key.kind == "backspace" then
      drawBackspaceIcon(key.x, key.y, key.w, key.h)
    elseif key.kind == "letter" then
      local text = self.shift and key.upper or key.lower
      love.graphics.setFont(self.keyFont)
      love.graphics.setColor(0, 0, 0, 1)
      local textY = key.y + math.floor((key.h - self.keyFont:getHeight()) * 0.5)
      love.graphics.printf(text, key.x, textY, key.w, "center")
    elseif key.id == "vk_space" then
      love.graphics.setFont(self.labelFont)
      love.graphics.setColor(0, 0, 0, 1)
      local textY = key.y + math.floor((key.h - self.labelFont:getHeight()) * 0.5)
      love.graphics.printf(key.label, key.x, textY, key.w, "center")
    else
      love.graphics.setFont(self.keyFont)
      love.graphics.setColor(0, 0, 0, 1)
      local textY = key.y + math.floor((key.h - self.keyFont:getHeight()) * 0.5)
      love.graphics.printf(key.char, key.x, textY, key.w, "center")
    end
  end

  self.hotzones:draw(self.app.debugHotzones)
  love.graphics.setColor(1, 1, 1, 1)
end

function VirtualKeyboard:mousepressed(vx, vy, button)
  return self.hotzones:mousepressed(vx, vy, button)
end

return VirtualKeyboard
