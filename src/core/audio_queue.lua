-- Sequential voice-over & phoneme playback queue plus non-blocking SFX channel.

local Assets = require("src.core.assets")

local AudioQueue = {}
AudioQueue.__index = AudioQueue

function AudioQueue.new()
  local self = setmetatable({}, AudioQueue)
  self.queue = {}
  self.current = nil
  self.defaultGap = 0.06
  self.gapTimer = 0
  self.pendingGap = 0
  self.voVolume = 1.0
  self.sfxVolume = 0.9
  return self
end

function AudioQueue:_startItem(item)
  local src = Assets.getAudio(item.category, item.name, item.sourceType)
  if not src then
    -- Gracefully skip missing clips (e.g., pending .BWV phonemes)
    return false
  end
  src:stop()
  src:setVolume(self.voVolume)
  src:play()
  self.current = src
  self.pendingGap = item.gap or self.defaultGap
  return true
end

function AudioQueue:_advanceQueue()
  while #self.queue > 0 do
    local nextItem = table.remove(self.queue, 1)
    if self:_startItem(nextItem) then
      return
    end
  end
end

function AudioQueue:enqueue(category, name, opts)
  opts = opts or {}
  table.insert(self.queue, {
    category = category,
    name = name,
    sourceType = opts.sourceType,
    gap = opts.gap,
  })
  if not self.current and self.gapTimer <= 0 then
    self:_advanceQueue()
  end
end

function AudioQueue:playSequence(items, opts)
  opts = opts or {}
  self:stop()
  for _, item in ipairs(items) do
    table.insert(self.queue, {
      category = item.category or item[1],
      name = item.name or item[2],
      sourceType = item.sourceType or opts.sourceType,
      gap = item.gap or opts.gap,
    })
  end
  self:_advanceQueue()
end

function AudioQueue:clearAndPlay(category, name, opts)
  self:stop()
  self:enqueue(category, name, opts)
end

function AudioQueue:stop()
  if self.current then
    self.current:stop()
    self.current = nil
  end
  self.queue = {}
  self.gapTimer = 0
  self.pendingGap = 0
end

function AudioQueue:isPlaying()
  return (self.current ~= nil and self.current:isPlaying()) or (#self.queue > 0) or (self.gapTimer > 0)
end

function AudioQueue:update(dt)
  if self.current then
    if not self.current:isPlaying() then
      self.current = nil
      if #self.queue > 0 then
        self.gapTimer = self.pendingGap
      end
    end
    return
  end

  if self.gapTimer > 0 then
    self.gapTimer = self.gapTimer - dt
    if self.gapTimer <= 0 then
      self.gapTimer = 0
      self:_advanceQueue()
    end
  end
end

function AudioQueue:playSfx(name)
  local template = Assets.getAudio("sfx", name, "static")
  if not template then
    return nil
  end
  local instance = template:clone()
  instance:setVolume(self.sfxVolume)
  instance:play()
  return instance
end

return AudioQueue
