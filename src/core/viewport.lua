-- Virtual 640x480 (4:3) canvas with centered aspect-ratio scaling and coordinate mapping.

local Viewport = {}
Viewport.__index = Viewport

Viewport.VIRTUAL_W = 640
Viewport.VIRTUAL_H = 480

local function getSafeArea(winW, winH)
  if love and love.window and love.window.getSafeArea then
    local ok, sx, sy, sw, sh = pcall(love.window.getSafeArea)
    if ok and type(sx) == "number" and type(sy) == "number"
      and type(sw) == "number" and type(sh) == "number"
      and sw > 0 and sh > 0
    then
      sx = math.max(0, math.min(winW, sx))
      sy = math.max(0, math.min(winH, sy))
      sw = math.max(1, math.min(winW - sx, sw))
      sh = math.max(1, math.min(winH - sy, sh))
      return sx, sy, sw, sh
    end
  end
  return 0, 0, winW, winH
end

function Viewport.new(filterMode)
  local self = setmetatable({}, Viewport)
  self.filterMode = filterMode or "nearest"
  self.canvas = love.graphics.newCanvas(self.VIRTUAL_W, self.VIRTUAL_H)
  self.canvas:setFilter(self.filterMode, self.filterMode)
  self.scale = 1
  self.offsetX = 0
  self.offsetY = 0
  self.winW = self.VIRTUAL_W
  self.winH = self.VIRTUAL_H
  self.safeX = 0
  self.safeY = 0
  self.safeW = self.VIRTUAL_W
  self.safeH = self.VIRTUAL_H
  self:resize(love.graphics.getDimensions())
  return self
end

function Viewport:setFilter(mode)
  self.filterMode = mode
  self.canvas:setFilter(mode, mode)
end

function Viewport:toggleFilter()
  local nextMode = (self.filterMode == "nearest") and "linear" or "nearest"
  self:setFilter(nextMode)
  return nextMode
end

function Viewport:resize(w, h)
  self.winW = math.max(1, w)
  self.winH = math.max(1, h)
  local safeX, safeY, safeW, safeH = getSafeArea(self.winW, self.winH)
  self.safeX = safeX
  self.safeY = safeY
  self.safeW = safeW
  self.safeH = safeH

  local sx = safeW / self.VIRTUAL_W
  local sy = safeH / self.VIRTUAL_H
  self.scale = math.min(sx, sy)
  local drawW = self.VIRTUAL_W * self.scale
  local drawH = self.VIRTUAL_H * self.scale
  local centeredX = (self.winW - drawW) * 0.5
  local centeredY = (self.winH - drawH) * 0.5
  local minX = safeX
  local maxX = math.max(minX, safeX + safeW - drawW)
  local minY = safeY
  local maxY = math.max(minY, safeY + safeH - drawH)
  self.offsetX = math.floor(math.max(minX, math.min(maxX, centeredX)))
  self.offsetY = math.floor(math.max(minY, math.min(maxY, centeredY)))
end

function Viewport:syncDimensions()
  local w, h = love.graphics.getDimensions()
  local safeX, safeY, safeW, safeH = getSafeArea(math.max(1, w), math.max(1, h))
  if w ~= self.winW or h ~= self.winH
    or safeX ~= self.safeX or safeY ~= self.safeY
    or safeW ~= self.safeW or safeH ~= self.safeH
  then
    self:resize(w, h)
  end
end

function Viewport:beginDraw()
  self:syncDimensions()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
end

function Viewport:endDraw()
  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

function Viewport:screenToVirtual(sx, sy)
  local vx = (sx - self.offsetX) / self.scale
  local vy = (sy - self.offsetY) / self.scale
  local inside = vx >= 0 and vx <= self.VIRTUAL_W and vy >= 0 and vy <= self.VIRTUAL_H
  return vx, vy, inside
end

return Viewport
