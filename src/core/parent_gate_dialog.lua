-- Reusable Windows 3.1 style Parent Gate Dialog with a built-in numeric keypad.

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local ParentGateDialog = {}
ParentGateDialog.__index = ParentGateDialog

local DIALOG_W = 360
local DIALOG_H = 314
local DIALOG_X = math.floor((640 - DIALOG_W) / 2) -- 140
local DIALOG_Y = math.floor((480 - DIALOG_H) / 2) -- 83

local ROW_Y = DIALOG_Y + 76 -- 159
local ROW_H = 34
local INPUT_X = DIALOG_X + 160 -- 300
local INPUT_Y = ROW_Y
local INPUT_W = 84
local INPUT_H = ROW_H

local BACK_X = INPUT_X + INPUT_W + 8 -- 392
local BACK_Y = ROW_Y
local BACK_W = 48
local BACK_H = ROW_H

local KEY_W = 56
local KEY_H = 42
local KEY_GAP = 8
local KEY_START_X = DIALOG_X + 24 -- 164
local KEY_ROWS = {
  { y = DIALOG_Y + 134, digits = { "1", "2", "3", "4", "5" } },
  { y = DIALOG_Y + 184, digits = { "6", "7", "8", "9", "0" } },
}

local BTN_W = 72
local BTN_H = 52
local BTN_Y = DIALOG_Y + 242 -- 325
local BTN_LEFT_X = DIALOG_X + 24 -- 164
local BTN_RIGHT_X = DIALOG_X + DIALOG_W - 24 - BTN_W -- 404

local function drawBeveledButton(x, y, w, h, isHovered)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)

  if isHovered then
    love.graphics.setColor(0.83, 0.83, 0.83, 1)
  else
    love.graphics.setColor(0.75, 0.75, 0.75, 1)
  end
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)

  -- 3D Bevel: white top/left highlight, dark grey bottom/right shadow
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.line(x + 1, y + 1, x + w - 2, y + 1)
  love.graphics.line(x + 1, y + 1, x + 1, y + h - 2)

  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.line(x + 1, y + h - 2, x + w - 1, y + h - 2)
  love.graphics.line(x + w - 2, y + 1, x + w - 2, y + h - 1)
end

local function drawIconButton(x, y, w, h, iconKey, isHovered)
  drawBeveledButton(x, y, w, h, isHovered)
  local icon = Assets.getImage("ui", iconKey)
  if icon then
    local iw, ih = icon:getDimensions()
    local ix = x + math.floor((w - iw) * 0.5)
    local iy = y + math.floor((h - ih) * 0.5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(icon, ix, iy)
  end
end

local function drawSunkenBox(x, y, w, h)
  -- Outer sunken bevel (dark top/left, white bottom/right)
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.line(x, y, x + w - 1, y)
  love.graphics.line(x, y, x, y + h - 1)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.line(x + 1, y + h - 1, x + w - 1, y + h - 1)
  love.graphics.line(x + w - 1, y + 1, x + w - 1, y + h - 1)

  -- Inner 1px black border and white background
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", x + 1.5, y + 1.5, w - 3, h - 3)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
end

local function drawBackspaceArrow(x, y, w, h)
  local cx = x + math.floor(w * 0.5)
  local cy = y + math.floor(h * 0.5)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.polygon("fill", cx - 10, cy, cx - 2, cy - 6, cx - 2, cy + 6)
  love.graphics.rectangle("fill", cx - 2, cy - 2, 12, 4)
end

function ParentGateDialog.new(app, opts)
  opts = opts or {}
  local self = setmetatable({}, ParentGateDialog)
  self.app = app
  self.defaultTitle = opts.title or "Oudercontrole"
  self.defaultPrompt = opts.prompt or "Los de som op om te bevestigen:"
  self.title = self.defaultTitle
  self.prompt = self.defaultPrompt
  self.hotzones = HotzoneManager.new(app.audio)
  self.visible = false
  self.onConfirm = nil
  self.onCancel = nil
  self.factorA = 3
  self.factorB = 4
  self.expectedAnswer = 12
  self.answer = ""
  self.errorMessage = nil
  self.wrongAttempts = 0
  self.blinkTimer = 0
  self.titleFont = love.graphics.newFont(14)
  self.promptFont = love.graphics.newFont(14)
  self.mathFont = love.graphics.newFont(22)
  self.keyFont = love.graphics.newFont(18)
  self.errorFont = love.graphics.newFont(13)
  return self
end

function ParentGateDialog:_playSfx(name)
  if self.app and self.app.audio and self.app.audio.playSfx then
    self.app.audio:playSfx(name)
  end
end

function ParentGateDialog:_generateQuestion()
  local prevA, prevB = self.factorA, self.factorB
  local a, b = prevA, prevB
  for _ = 1, 6 do
    a = love.math.random(3, 9)
    b = love.math.random(3, 9)
    if a ~= prevA or b ~= prevB then
      break
    end
  end
  self.factorA = a
  self.factorB = b
  self.expectedAnswer = a * b
end

function ParentGateDialog:_appendDigit(digit)
  if #self.answer >= 3 then
    return
  end
  self.answer = self.answer .. digit
  self.errorMessage = nil
  self.blinkTimer = 0
end

function ParentGateDialog:_backspace()
  if #self.answer > 0 then
    self.answer = self.answer:sub(1, #self.answer - 1)
    self.errorMessage = nil
    self.blinkTimer = 0
  end
end

function ParentGateDialog:_tryConfirm()
  if self.answer == "" then
    self.errorMessage = "Vul eerst het antwoord in."
    self:_playSfx("fout")
    return false
  end

  if tonumber(self.answer) == self.expectedAnswer then
    self:_playSfx("klik")
    local cb = self.onConfirm
    self:close()
    if cb then
      cb()
    end
    return true
  end

  self:_playSfx("fout")
  self.answer = ""
  self.wrongAttempts = self.wrongAttempts + 1
  self.errorMessage = "Fout antwoord, probeer opnieuw."
  self.blinkTimer = 0
  if self.wrongAttempts >= 3 then
    self.wrongAttempts = 0
    self:_generateQuestion()
  end
  return false
end

function ParentGateDialog:open(onConfirm, onCancel, prompt, title)
  self.visible = true
  self.onConfirm = onConfirm
  self.onCancel = onCancel
  self.prompt = prompt or self.defaultPrompt
  self.title = title or self.defaultTitle
  self.answer = ""
  self.errorMessage = nil
  self.wrongAttempts = 0
  self.blinkTimer = 0
  self:_generateQuestion()

  self.hotzones:clear()

  for _, row in ipairs(KEY_ROWS) do
    for idx, digit in ipairs(row.digits) do
      local kx = KEY_START_X + (idx - 1) * (KEY_W + KEY_GAP)
      self.hotzones:add({
        id = "gate_digit_" .. digit,
        label = digit,
        x = kx,
        y = row.y,
        w = KEY_W,
        h = KEY_H,
        onClick = function()
          self:_appendDigit(digit)
        end,
      })
    end
  end

  self.hotzones:add({
    id = "gate_backspace",
    label = "Wis",
    x = BACK_X,
    y = BACK_Y,
    w = BACK_W,
    h = BACK_H,
    onClick = function()
      self:_backspace()
    end,
  })

  self.hotzones:add({
    id = "gate_cancel",
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
    id = "gate_ok",
    label = "Ja",
    x = BTN_RIGHT_X,
    y = BTN_Y,
    w = BTN_W,
    h = BTN_H,
    clickSfx = false,
    onClick = function()
      self:_tryConfirm()
    end,
  })

  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:syncHover(vx, vy)
end

function ParentGateDialog:close()
  self.visible = false
  self.errorMessage = nil
  self.hotzones:clear()
end

function ParentGateDialog:isOpen()
  return self.visible
end

function ParentGateDialog:update(dt)
  if not self.visible then
    return
  end
  self.blinkTimer = self.blinkTimer + dt
  local vx, vy = self.app:getVirtualPointer()
  self.hotzones:update(vx, vy, self.app.isTouchMode)
end

function ParentGateDialog:draw()
  if not self.visible then
    return
  end

  -- Window frame border: 3px light blue / cyan
  love.graphics.setColor(0.65, 0.79, 0.94, 1)
  for b = 0, 2 do
    love.graphics.rectangle("line", DIALOG_X + b + 0.5, DIALOG_Y + b + 0.5, DIALOG_W - 1 - 2 * b, DIALOG_H - 1 - 2 * b)
  end

  -- Red title bar
  love.graphics.setColor(0.92, 0.05, 0.05, 1)
  love.graphics.rectangle("fill", DIALOG_X + 3, DIALOG_Y + 3, DIALOG_W - 6, 24)

  -- White centered title bar text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(self.titleFont)
  love.graphics.printf(self.title, DIALOG_X + 3, DIALOG_Y + 7, DIALOG_W - 6, "center")

  -- Light yellow client area background
  love.graphics.setColor(1.0, 1.0, 0.60, 1)
  love.graphics.rectangle("fill", DIALOG_X + 3, DIALOG_Y + 27, DIALOG_W - 6, DIALOG_H - 30)

  -- Prompt text
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setFont(self.promptFont)
  love.graphics.printf(self.prompt, DIALOG_X + 18, DIALOG_Y + 34, DIALOG_W - 36, "center")

  -- Equation + sunken answer input + backspace button
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setFont(self.mathFont)
  local equation = string.format("%d x %d =", self.factorA, self.factorB)
  love.graphics.printf(equation, DIALOG_X + 16, ROW_Y + 4, 136, "right")

  drawSunkenBox(INPUT_X, INPUT_Y, INPUT_W, INPUT_H)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setFont(self.mathFont)
  love.graphics.print(self.answer, INPUT_X + 8, INPUT_Y + 4)

  if math.floor(self.blinkTimer * 2) % 2 == 0 then
    local caretX = INPUT_X + 8 + self.mathFont:getWidth(self.answer) + 1
    love.graphics.setLineWidth(1.5)
    love.graphics.line(caretX, INPUT_Y + 6, caretX, INPUT_Y + INPUT_H - 6)
    love.graphics.setLineWidth(1)
  end

  local hovered = not self.app.isTouchMode and self.hotzones.hoveredId or nil
  drawBeveledButton(BACK_X, BACK_Y, BACK_W, BACK_H, hovered == "gate_backspace")
  drawBackspaceArrow(BACK_X, BACK_Y, BACK_W, BACK_H)

  -- Error feedback line
  if self.errorMessage then
    love.graphics.setColor(0.8, 0.05, 0.05, 1)
    love.graphics.setFont(self.errorFont)
    love.graphics.printf(self.errorMessage, DIALOG_X + 18, DIALOG_Y + 114, DIALOG_W - 36, "center")
  end

  -- Built-in 10-digit numeric keypad
  love.graphics.setFont(self.keyFont)
  for _, row in ipairs(KEY_ROWS) do
    for idx, digit in ipairs(row.digits) do
      local kx = KEY_START_X + (idx - 1) * (KEY_W + KEY_GAP)
      drawBeveledButton(kx, row.y, KEY_W, KEY_H, hovered == ("gate_digit_" .. digit))
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.printf(digit, kx, row.y + 10, KEY_W, "center")
    end
  end

  -- Bottom Cancel / Confirm buttons
  drawIconButton(BTN_LEFT_X, BTN_Y, BTN_W, BTN_H, "knopan", hovered == "gate_cancel")
  drawIconButton(BTN_RIGHT_X, BTN_Y, BTN_W, BTN_H, "knopok", hovered == "gate_ok")

  self.hotzones:draw(self.app.debugHotzones)
  love.graphics.setColor(1, 1, 1, 1)
end

function ParentGateDialog:mousepressed(vx, vy, button)
  if not self.visible then
    return false
  end
  self.hotzones:mousepressed(vx, vy, button)
  return true
end

function ParentGateDialog:keypressed(key)
  if not self.visible then
    return false
  end
  if key == "escape" then
    self:close()
    if self.onCancel then
      self.onCancel()
    end
    return true
  elseif key == "return" or key == "kpenter" then
    self:_tryConfirm()
    return true
  elseif key == "backspace" or key == "delete" then
    self:_backspace()
    self:_playSfx("klik")
    return true
  else
    local digit = key:match("^kp(%d)$") or key:match("^(%d)$")
    if digit then
      self:_appendDigit(digit)
      self:_playSfx("klik")
      return true
    end
  end
  return true
end

return ParentGateDialog
