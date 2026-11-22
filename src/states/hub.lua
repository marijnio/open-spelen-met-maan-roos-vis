-- Main Hub state (KEUZE.BMP): launches the 6 mini-games, leaderboard, help, or back to start menu.

local Assets = require("src.core.assets")
local HotzoneManager = require("src.core.hotzone")

local HubState = {}
HubState.__index = HubState

local MINIGAME_ZONES = {
  { id = "memory",     label = "Onthouden maar",  x = 126, y = 43,  w = 133, h = 80,  head = "h6", hoverVo = { "jantje", "onthmaar" } },
  { id = "electro",    label = "Woordje plaatje", x = 151, y = 124, w = 71,  h = 106, head = "h7", hoverVo = { "jantje", "wrdpltje" } },
  { id = "draaiom",    label = "Draai maar om",   x = 350, y = 84,  w = 112, h = 72,  head = "h3", hoverVo = { "jantje", "drmaarom" } },
  { id = "klplaat",    label = "Kleurplaat",      x = 405, y = 157, w = 111, h = 79,  head = "h2", hoverVo = { "jantje", "klplaat"  } },
  { id = "invullen",   label = "Invullen",        x = 362, y = 249, w = 117, h = 74,  head = "h4", hoverVo = { "jantje", "invullen" } },
  { id = "turbowoord", label = "Luister maar",    x = 297, y = 155, w = 105, h = 77,  head = "h5", hoverVo = { "jantje", "luismaar" } },
}

function HubState.new(app)
  local self = setmetatable({}, HubState)
  self.app = app
  self.hotzones = HotzoneManager.new(app.audio)
  self.headSprite = "h1"
  return self
end

function HubState:enter()
  self.headSprite = "h1"
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
      onHoverEnter = function()
        self.headSprite = cfg.head
      end,
      onHoverLeave = function()
        self.headSprite = "h1"
      end,
      onClick = function()
        self.app.audio:stop()
        self.app.scenes:switch(cfg.id)
      end,
    })
  end

  self.hotzones:add({
    id = "highscore",
    label = "Score",
    x = 535,
    y = 252,
    w = 84,
    h = 159,
    hoverVo = { "jantje", "top5" },
    onHoverEnter = function()
      self.headSprite = "h1"
    end,
    onClick = function()
      self.app.audio:stop()
      self.app.scenes:switch("highscore", { returnTo = "hub" })
    end,
  })

  self.hotzones:add({
    id = "terug",
    label = "Terug",
    x = 8,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "terug" },
    hoverImage = { "ui", "teru2" },
    onClick = function()
      self.app.audio:stop()
      self.app.scenes:switch("start_menu")
    end,
  })

  self.hotzones:add({
    id = "help",
    label = "Help",
    x = 72,
    y = 416,
    w = 60,
    h = 60,
    normalImage = { "ui", "help" },
    hoverImage = { "ui", "hel2" },
    hoverVo = { "jantje", "spgdhelp" },
    onClick = function()
      self.app.audio:clearAndPlay("jantje", "openhelp")
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

  local headImg = Assets.getImage("ui", self.headSprite)
  if headImg then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(headImg, 460, 250)
  end

  self.hotzones:draw(self.app.debugHotzones)
end

function HubState:mousepressed(vx, vy, button)
  self.hotzones:mousepressed(vx, vy, button)
end

return HubState
