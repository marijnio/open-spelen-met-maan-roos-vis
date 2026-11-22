-- Scene/State manager handling transitions and forwarding Love2D callbacks.

local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new(app)
  local self = setmetatable({}, SceneManager)
  self.app = app
  self.current = nil
  self.currentName = nil
  self.registry = {}
  return self
end

function SceneManager:register(name, factoryOrModule)
  self.registry[name] = factoryOrModule
end

function SceneManager:switch(target, params)
  local nextScene = target
  local nextName = nil

  if type(target) == "string" then
    nextName = target
    local entry = assert(self.registry[target], "Unknown scene: " .. tostring(target))
    nextScene = (type(entry) == "function") and entry(self.app) or entry
  end

  if self.current and self.current.exit then
    self.current:exit()
  end

  self.current = nextScene
  self.currentName = nextName

  if self.current and self.current.enter then
    self.current:enter(params)
  end
end

function SceneManager:update(dt)
  if self.current and self.current.update then
    self.current:update(dt)
  end
end

function SceneManager:draw()
  if self.current and self.current.draw then
    self.current:draw()
  end
end

function SceneManager:mousepressed(vx, vy, button)
  if self.current and self.current.mousepressed then
    self.current:mousepressed(vx, vy, button)
  end
end

function SceneManager:mousereleased(vx, vy, button)
  if self.current and self.current.mousereleased then
    self.current:mousereleased(vx, vy, button)
  end
end

function SceneManager:mousemoved(vx, vy, dx, dy)
  if self.current and self.current.mousemoved then
    self.current:mousemoved(vx, vy, dx, dy)
  end
end

function SceneManager:keypressed(key)
  if self.current and self.current.keypressed then
    self.current:keypressed(key)
  end
end

function SceneManager:textinput(text)
  if self.current and self.current.textinput then
    self.current:textinput(text)
  end
end

return SceneManager
