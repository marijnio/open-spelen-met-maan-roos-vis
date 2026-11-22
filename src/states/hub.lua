-- Main Hub state (KEUZE.BMP): launches the 6 mini-games, help, or exit.

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local HubState = {}
HubState.__index = HubState

local MINIGAME_ZONES = {
  { id = "memory",     label = "Onthoud maar",  x = 40,  y = 65,  w = 175, h = 140, hoverVo = { "jantje", "onthmaar" } },
  { id = "electro",    label = "Woordplaatje",  x = 232, y = 65,  w = 175, h = 140, hoverVo = { "jantje", "wrdpltje" } },
  { id = "draaiom",    label = "Draai maar om", x = 425, y = 65,  w = 175, h = 140, hoverVo = { "jantje", "drmaarom" } },
  { id = "klplaat",    label = "Kleurplaat",    x = 40,  y = 225, w = 175, h = 140, hoverVo = { "jantje", "klplaat"  } },
  { id = "invullen",   label = "Invullen",      x = 232, y = 225, w = 175, h = 140, hoverVo = { "jantje", "invullen" } },
  { id = "turbowoord", label = "Luister maar",  x = 425, y = 225, w = 175, h = 140, hoverVo = { "jantje", "luismaar" } },
}

function HubState.new(app)
  local self = setmetatable({}, HubState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  return self
end

function HubState:enter()
  self.hotzones:clear()

  for _, cfg in ipairs(MINIGAME_ZONES) do
    self.hotzones:add({
      id = cfg.id,
      label = cfg.label,
      x = cfg.x,
      y = cfg.y,
      w = cfg.w,
      h = cfg.h,
      hoverVo = cfg.hoverVo,
      onClick = function()
        self.app.audio:stop()
        self.app.scenes:switch(cfg.id)
      end,
    })
  end

  self.hotzones:add({
    id = "help",
    label = "Help",
    x = 12,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "help" },
    hoverImage = { "ui", "hel2" },
    hoverVo = { "jantje", "spgdhelp" },
    onClick = function()
      self.app.audio:clearAndPlay("jantje", "openhelp")
    end,
  })

  self.hotzones:add({
    id = "stop",
    label = "Stoppen",
    x = 568,
    y = 408,
    w = 60,
    h = 60,
    normalImage = { "ui", "stop" },
    hoverImage = { "ui", "sto2" },
    hoverVo = { "jantje", "stop" },
    onClick = function()
      love.event.quit()
    end,
  })
end

function HubState:exit()
  self.hotzones:clear()
end

function HubState:update(_dt)
  local vx, vy = self.app.viewport:screenToVirtual(love.mouse.getPosition())
  self.hotzones:update(vx, vy)
end

function HubState:draw()
  local bg = Assets.getImage("screens", "keuze")
  if bg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bg, 0, 0)
  end

  self.hotzones:draw(self.app.debugHotzones)
end

function HubState:mousepressed(vx, vy, button)
  self.hotzones:mousepressed(vx, vy, button)
end

return HubState
