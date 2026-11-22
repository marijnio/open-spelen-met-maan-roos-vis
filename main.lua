-- Entry point for Spelen met Maan Roos Vis (LÖVE 11.5).

local Assets = require("src.core.assets")
local AudioQueue = require("src.core.audio_queue")
local HighScores = require("src.core.highscores")
local SceneManager = require("src.core.scene_manager")
local Viewport = require("src.core.viewport")

local MissingAssetsState = require("src.states.missing_assets")
local IntroState = require("src.states.intro")
local StartMenuState = require("src.states.start_menu")
local AboutState = require("src.states.about")
local HubState = require("src.states.hub")
local HighScoreState = require("src.states.highscore")

local MemoryGame = require("src.minigames.memory")
local ElectroGame = require("src.minigames.electro")
local DraaiomGame = require("src.minigames.draaiom")
local KlplaatGame = require("src.minigames.klplaat")
local InvullenGame = require("src.minigames.invullen")
local TurbowoordGame = require("src.minigames.turbowoord")

local App = {
  debugHotzones = false,
  hasGreetedInHub = false,
}

function love.load()
  Assets.setFilterMode("nearest")
  Assets.init()
  HighScores.load()

  App.viewport = Viewport.new("nearest")
  App.audio = AudioQueue.new()
  App.scenes = SceneManager.new(App)

  App.scenes:register("missing_assets", MissingAssetsState.new)
  App.scenes:register("intro", IntroState.new)
  App.scenes:register("start_menu", StartMenuState.new)
  App.scenes:register("about", AboutState.new)
  App.scenes:register("hub", HubState.new)
  App.scenes:register("highscore", HighScoreState.new)
  App.scenes:register("memory", MemoryGame)
  App.scenes:register("electro", ElectroGame)
  App.scenes:register("draaiom", DraaiomGame)
  App.scenes:register("klplaat", KlplaatGame)
  App.scenes:register("invullen", InvullenGame)
  App.scenes:register("turbowoord", TurbowoordGame)

  if Assets.isReady() then
    App.scenes:switch("intro")
  else
    App.scenes:switch("missing_assets")
  end
end

function love.resize(w, h)
  App.viewport:resize(w, h)
end

function love.update(dt)
  App.audio:update(dt)
  App.scenes:update(dt)
end

function love.draw()
  App.viewport:beginDraw()
  App.scenes:draw()
  App.viewport:endDraw()
end

function love.mousepressed(x, y, button)
  local vx, vy, inside = App.viewport:screenToVirtual(x, y)
  if inside then
    App.scenes:mousepressed(vx, vy, button)
  end
end

function love.mousereleased(x, y, button)
  local vx, vy = App.viewport:screenToVirtual(x, y)
  App.scenes:mousereleased(vx, vy, button)
end

function love.mousemoved(x, y, dx, dy)
  local vx, vy = App.viewport:screenToVirtual(x, y)
  local s = App.viewport.scale
  App.scenes:mousemoved(vx, vy, dx / s, dy / s)
end

function love.keypressed(key)
  if key == "f1" then
    App.debugHotzones = not App.debugHotzones
    return
  elseif key == "f2" then
    local mode = App.viewport:toggleFilter()
    Assets.setFilterMode(mode)
    return
  elseif key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen())
    return
  elseif key == "escape" then
    if App.scenes.current and App.scenes.current.handlesEscape then
      App.scenes:keypressed(key)
      return
    end
    local cur = App.scenes.currentName
    if cur == "intro" or cur == "start_menu" or cur == "missing_assets" then
      App.scenes:keypressed(key)
    elseif cur == "about" or cur == "hub" then
      App.audio:stop()
      App.scenes:switch("start_menu")
    else
      App.audio:stop()
      App.scenes:switch("hub")
    end
    return
  end

  App.scenes:keypressed(key)
end

function love.textinput(text)
  App.scenes:textinput(text)
end
