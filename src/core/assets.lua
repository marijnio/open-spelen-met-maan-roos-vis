-- Runtime local asset loader resolving manifest.lua from SMRV_ASSETS_DIR,
-- local_config.lua, project-local assets/, or LÖVE save directory.

local loadChunk = loadstring or load

local Assets = {
  manifest = nil,
  ready = false,
  root = nil,
  mode = nil, -- "love" or "fs"
  checkedPaths = {},
  loadError = nil,
  images = {},
  imageData = {},
  audio = {},
  warned = {},
  filterMode = "nearest",
}

local function normalizePath(p)
  if type(p) ~= "string" then
    return nil
  end
  local trimmed = p:match("^%s*(.-)%s*$")
  if trimmed == "" then
    return nil
  end
  if trimmed:sub(1, 1) == "~" then
    local home = os.getenv("HOME")
    if home and home ~= "" then
      trimmed = home .. trimmed:sub(2)
    end
  end
  trimmed = trimmed:gsub("/+$", "")
  return trimmed
end

local function isExternalPath(p)
  return p:sub(1, 1) == "/" or p:match("^[A-Za-z]:") ~= nil or p:find("..", 1, true) ~= nil
end

local function readText(mode, fullPath)
  if mode == "love" then
    if not love.filesystem.getInfo(fullPath) then
      return nil
    end
    local contents = love.filesystem.read(fullPath)
    return contents
  end

  local f = io.open(fullPath, "rb")
  if not f then
    return nil
  end
  local contents = f:read("*a")
  f:close()
  return contents
end

local function loadManifestAt(candidate)
  local manifestPath = candidate.path .. "/manifest.lua"
  local content = readText(candidate.mode, manifestPath)
  if not content then
    return nil, "manifest.lua niet gevonden"
  end

  local chunk, syntaxErr = loadChunk(content, "@" .. manifestPath)
  if not chunk then
    return nil, "manifest parse fout: " .. tostring(syntaxErr)
  end

  local ok, parsed = pcall(chunk)
  if not ok or type(parsed) ~= "table" or type(parsed.images) ~= "table" or type(parsed.audio) ~= "table" then
    return nil, "ongeldig manifest formaat"
  end

  return parsed, nil
end

local function addCandidate(list, sourceLabel, rawPath, forcedMode)
  local p = normalizePath(rawPath)
  if not p then
    return
  end
  local mode = forcedMode or (isExternalPath(p) and "fs" or "love")
  table.insert(list, { label = sourceLabel, path = p, mode = mode })
end

function Assets.init()
  Assets.manifest = nil
  Assets.ready = false
  Assets.root = nil
  Assets.mode = nil
  Assets.checkedPaths = {}
  Assets.loadError = nil
  Assets.images = {}
  Assets.imageData = {}
  Assets.audio = {}
  Assets.warned = {}

  local candidates = {}

  local envDir = os.getenv("SMRV_ASSETS_DIR")
  addCandidate(candidates, "SMRV_ASSETS_DIR", envDir, "fs")

  package.loaded["local_config"] = nil
  local hasCfg, cfg = pcall(require, "local_config")
  if hasCfg and type(cfg) == "table" and cfg.assets_dir then
    addCandidate(candidates, "local_config.lua", cfg.assets_dir, nil)
  end

  addCandidate(candidates, "project assets/", "assets", "love")

  if love.filesystem and love.filesystem.getSaveDirectory then
    local saveAssets = love.filesystem.getSaveDirectory() .. "/assets"
    addCandidate(candidates, "LÖVE save dir", saveAssets, "fs")
  end

  for _, c in ipairs(candidates) do
    local parsed, err = loadManifestAt(c)
    table.insert(Assets.checkedPaths, {
      label = c.label,
      path = c.path .. "/manifest.lua",
      mode = c.mode,
      err = err,
    })
    if parsed then
      Assets.manifest = parsed
      Assets.root = c.path
      Assets.mode = c.mode
      Assets.ready = true
      return true
    end
  end

  Assets.loadError = "Geen lokale assets/manifest.lua gevonden."
  return false
end

function Assets.isReady()
  return Assets.ready
end

function Assets.getRoot()
  return Assets.root
end

function Assets.getCheckedPaths()
  return Assets.checkedPaths
end

function Assets.getLoadError()
  return Assets.loadError
end

function Assets.setFilterMode(mode)
  Assets.filterMode = mode
  for _, img in pairs(Assets.images) do
    img:setFilter(mode, mode)
  end
end

function Assets:_warnOnce(key, message)
  if not self.warned[key] then
    self.warned[key] = true
    print(message)
  end
end

function Assets:_resolveSourceInput(relPath)
  local cleanRel = relPath:gsub("^/+", "")
  local fullPath = self.root .. "/" .. cleanRel

  if self.mode == "love" then
    if not love.filesystem.getInfo(fullPath) then
      return nil, fullPath
    end
    return fullPath, fullPath
  end

  local f = io.open(fullPath, "rb")
  if not f then
    return nil, fullPath
  end
  local bytes = f:read("*a")
  f:close()
  local fileData = love.filesystem.newFileData(bytes, cleanRel)
  return fileData, fullPath
end

function Assets.getImage(category, name)
  if not Assets.ready or not Assets.manifest then
    return nil
  end
  local catTable = Assets.manifest.images and Assets.manifest.images[category]
  if not catTable then
    return nil
  end
  local relPath = catTable[name]
  if not relPath then
    return nil
  end

  local cacheKey = category .. ":" .. name
  if Assets.images[cacheKey] then
    return Assets.images[cacheKey]
  end

  local input, fullPath = Assets:_resolveSourceInput(relPath)
  if not input then
    Assets:_warnOnce("img:" .. cacheKey, string.format("[Assets] Ontbrekende afbeelding (%s.%s): %s", category, name, fullPath))
    return nil
  end

  local ok, img = pcall(love.graphics.newImage, input)
  if not ok or not img then
    Assets:_warnOnce("img:" .. cacheKey, string.format("[Assets] Kon afbeelding niet laden (%s.%s): %s", category, name, tostring(img)))
    return nil
  end

  img:setFilter(Assets.filterMode, Assets.filterMode)
  Assets.images[cacheKey] = img
  return img
end

function Assets.getImageData(category, name)
  if not Assets.ready or not Assets.manifest then
    return nil
  end
  local catTable = Assets.manifest.images and Assets.manifest.images[category]
  if not catTable then
    return nil
  end
  local relPath = catTable[name]
  if not relPath then
    return nil
  end

  local cacheKey = category .. ":" .. name
  if Assets.imageData[cacheKey] then
    return Assets.imageData[cacheKey]
  end

  local input, fullPath = Assets:_resolveSourceInput(relPath)
  if not input then
    Assets:_warnOnce("imgd:" .. cacheKey, string.format("[Assets] Ontbrekende afbeelding (%s.%s): %s", category, name, fullPath))
    return nil
  end

  local ok, data = pcall(love.image.newImageData, input)
  if not ok or not data then
    Assets:_warnOnce("imgd:" .. cacheKey, string.format("[Assets] Kon ImageData niet laden (%s.%s): %s", category, name, tostring(data)))
    return nil
  end

  Assets.imageData[cacheKey] = data
  return data
end

function Assets.getAudio(category, name, sourceType)
  if not Assets.ready or not Assets.manifest then
    return nil
  end
  local catTable = Assets.manifest.audio and Assets.manifest.audio[category]
  if not catTable then
    return nil
  end
  local relPath = catTable[name]
  if not relPath then
    return nil
  end

  local kind = sourceType or ((category == "sfx" or category == "words") and "static" or "stream")
  local cacheKey = category .. ":" .. name .. ":" .. kind
  if Assets.audio[cacheKey] then
    return Assets.audio[cacheKey]
  end

  local input, fullPath = Assets:_resolveSourceInput(relPath)
  if not input then
    Assets:_warnOnce("aud:" .. cacheKey, string.format("[Assets] Ontbrekende audio (%s.%s): %s", category, name, fullPath))
    return nil
  end

  local ok, src = pcall(love.audio.newSource, input, kind)
  if not ok or not src then
    Assets:_warnOnce("aud:" .. cacheKey, string.format("[Assets] Kon audio niet laden (%s.%s): %s", category, name, tostring(src)))
    return nil
  end

  Assets.audio[cacheKey] = src
  return src
end

function Assets.listKeys(kind, category)
  if not Assets.ready or not Assets.manifest then
    return {}
  end
  local group = Assets.manifest[kind] and Assets.manifest[kind][category]
  if not group then
    return {}
  end
  local keys = {}
  for k in pairs(group) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

return Assets
