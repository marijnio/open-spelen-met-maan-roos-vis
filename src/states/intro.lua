-- Intro animation state: plays VIDEO frames on black background with ZWT music,
-- shows the Radarsoft logo in the bottom-right at the end, and waits for ZWT to finish (or click to skip).

local Assets = require("src.core.assets")

local IntroState = {}
IntroState.__index = IntroState

function IntroState.new(app)
  local self = setmetatable({}, IntroState)
  self.app = app
  self.frames = {}
  self.frameIndex = 1
  self.timer = 0
  self.frameDuration = 0.10 -- ~10 fps
  self.doneAnimating = false
  return self
end

function IntroState:enter()
  self.frames = Assets.listKeys("images", "video")
  self.frameIndex = 1
  self.timer = 0
  self.doneAnimating = (#self.frames == 0)
  self.app.audio:clearAndPlay("system", "zwt")
end

function IntroState:exit()
end

function IntroState:_goToStartMenu()
  self.app.audio:stop()
  self.app.scenes:switch("start_menu")
end

function IntroState:update(dt)
  if not self.doneAnimating and #self.frames > 0 then
    self.timer = self.timer + dt
    while self.timer >= self.frameDuration do
      self.timer = self.timer - self.frameDuration
      if self.frameIndex < #self.frames then
        self.frameIndex = self.frameIndex + 1
      else
        self.doneAnimating = true
        break
      end
    end
  elseif self.doneAnimating and not self.app.audio:isPlaying() then
    self:_goToStartMenu()
  end
end

function IntroState:draw()
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)

  if #self.frames > 0 then
    local key = self.frames[self.frameIndex]
    local frame = Assets.getImage("video", key)
    if frame then
      local fw, fh = frame:getDimensions()
      local x = math.floor((640 - fw) * 0.5)
      local y = math.floor((480 - fh) * 0.5)
      love.graphics.draw(frame, x, y)
    end
  end

  if self.doneAnimating then
    local rslogo = Assets.getImage("ui", "rslogo")
    if rslogo then
      local rw, rh = rslogo:getDimensions()
      love.graphics.draw(rslogo, 640 - rw - 16, 480 - rh - 16)
    end
  end

  if self.app.debugHotzones then
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 8, 8, 320, 22)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Intro frame %d/%d (click or key to skip)", self.frameIndex, #self.frames), 14, 13)
  end
end

function IntroState:mousepressed(_vx, _vy, button)
  if button == 1 then
    self.app.audio:playSfx("klik")
    self:_goToStartMenu()
  end
end

function IntroState:keypressed(key)
  if key == "space" or key == "return" or key == "escape" then
    self:_goToStartMenu()
  end
end

return IntroState
