-- Clickable & hoverable rectangular hotzones with sprite swap, audio feedback, and F1 debug view.

local Assets = require("src.core.assets")
local Cursor = require("src.core.cursor")

local HotzoneManager = {}
HotzoneManager.__index = HotzoneManager

function HotzoneManager.new(audioQueue)
  local self = setmetatable({}, HotzoneManager)
  self.audioQueue = audioQueue
  self.zones = {}
  self.hoveredId = nil
  self.handCursor = Cursor.getSystem("hand")
  self.arrowCursor = Cursor.getSystem("arrow")
  return self
end

function HotzoneManager:clear()
  self.zones = {}
  self.hoveredId = nil
  Cursor.set(self.arrowCursor)
end

function HotzoneManager:add(zone)
  assert(zone.id, "Hotzone requires an id")
  if zone.enabled == nil then
    zone.enabled = true
  end
  if zone.clickSfx == nil then
    zone.clickSfx = "klik"
  end
  table.insert(self.zones, zone)
  return zone
end

function HotzoneManager:findAt(vx, vy)
  -- Search in reverse order so later (topmost) zones take priority
  for i = #self.zones, 1, -1 do
    local z = self.zones[i]
    if z.enabled and vx >= z.x and vx <= (z.x + z.w) and vy >= z.y and vy <= (z.y + z.h) then
      return z
    end
  end
  return nil
end

function HotzoneManager:getById(id)
  for _, z in ipairs(self.zones) do
    if z.id == id then
      return z
    end
  end
  return nil
end

function HotzoneManager:_resolveImage(spec)
  if type(spec) == "table" then
    return Assets.getImage(spec[1], spec[2])
  end
  return spec
end

function HotzoneManager:syncHover(vx, vy)
  local hit = self:findAt(vx, vy)
  self.hoveredId = hit and hit.id or nil
  if hit then
    Cursor.set(self.handCursor)
    if hit.onHoverEnter then
      hit.onHoverEnter(hit)
    end
  else
    Cursor.set(self.arrowCursor)
  end
end

function HotzoneManager:update(vx, vy, suppressHoverAudio)
  local hit = self:findAt(vx, vy)
  local nextId = hit and hit.id or nil

  if nextId ~= self.hoveredId then
    if self.hoveredId then
      local prev = self:getById(self.hoveredId)
      if prev and prev.onHoverLeave then
        prev.onHoverLeave(prev)
      end
    end

    self.hoveredId = nextId

    if hit then
      Cursor.set(self.handCursor)
      if self.audioQueue and not suppressHoverAudio then
        if hit.hoverSfx then
          self.audioQueue:playSfx(hit.hoverSfx)
        end
        if hit.hoverVo then
          self.audioQueue:clearAndPlay(hit.hoverVo[1] or "jantje", hit.hoverVo[2] or hit.hoverVo)
        end
      end
      if hit.onHoverEnter then
        hit.onHoverEnter(hit)
      end
    else
      Cursor.set(self.arrowCursor)
    end
  end
end

function HotzoneManager:mousepressed(vx, vy, button)
  if button ~= 1 then
    return false
  end
  local hit = self:findAt(vx, vy)
  if not hit then
    return false
  end
  if self.audioQueue and hit.clickSfx and hit.clickSfx ~= false then
    self.audioQueue:playSfx(hit.clickSfx)
  end
  if hit.onClick then
    hit.onClick(hit)
  end
  return true
end

function HotzoneManager:draw(debugMode)
  love.graphics.setColor(1, 1, 1, 1)
  for _, z in ipairs(self.zones) do
    if z.enabled then
      local isHovered = (z.id == self.hoveredId)
      local imgSpec = (isHovered and z.hoverImage) or z.normalImage
      local img = self:_resolveImage(imgSpec)
      if img then
        love.graphics.draw(img, z.x, z.y)
      end
    end
  end

  if debugMode then
    for _, z in ipairs(self.zones) do
      local isHovered = (z.id == self.hoveredId)
      if not z.enabled then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.25)
      elseif isHovered then
        love.graphics.setColor(0.2, 1.0, 0.3, 0.35)
      else
        love.graphics.setColor(1.0, 0.8, 0.1, 0.25)
      end
      love.graphics.rectangle("fill", z.x, z.y, z.w, z.h)

      love.graphics.setColor(isHovered and 0.2 or 1.0, 1.0, isHovered and 0.3 or 0.1, 0.95)
      love.graphics.rectangle("line", z.x + 0.5, z.y + 0.5, z.w - 1, z.h - 1)

      local text = string.format("%s (%d,%d %dx%d)", z.label or z.id, z.x, z.y, z.w, z.h)
      love.graphics.setColor(0, 0, 0, 0.75)
      love.graphics.rectangle("fill", z.x + 2, z.y + 2, math.min(z.w - 4, #text * 6.5 + 6), 14)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(text, z.x + 4, z.y + 3, 0, 0.8, 0.8)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end

return HotzoneManager
