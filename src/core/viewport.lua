-- Virtual 640x480 (4:3) canvas with centered aspect-ratio scaling and coordinate mapping.

local Viewport = {}
Viewport.__index = Viewport

Viewport.VIRTUAL_W = 640
Viewport.VIRTUAL_H = 480

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
  local sx = self.winW / self.VIRTUAL_W
  local sy = self.winH / self.VIRTUAL_H
  self.scale = math.min(sx, sy)
  local drawW = self.VIRTUAL_W * self.scale
  local drawH = self.VIRTUAL_H * self.scale
  self.offsetX = math.floor((self.winW - drawW) * 0.5)
  self.offsetY = math.floor((self.winH - drawH) * 0.5)
end

function Viewport:beginDraw()
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
