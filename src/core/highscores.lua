-- Persistent Top-5 high score table across all 6 mini-games (stored in highscores.lua).

local loadChunk = loadstring or load

local HighScores = {}

HighScores.MAX_ENTRIES = 5
HighScores.FILENAME = "highscores.lua"

HighScores.GAMES = {
  { id = "memory",     title = "Onthouden maar!" },
  { id = "draaiom",    title = "Draai maar om!" },
  { id = "electro",    title = "Woordje plaatje" },
  { id = "invullen",   title = "Invullen" },
  { id = "klplaat",    title = "Kleurplaat" },
  { id = "turbowoord", title = "Luister maar" },
}

HighScores.data = {}

local function sanitizeName(name)
  if type(name) ~= "string" then
    return "-"
  end
  local cleaned = name:gsub("[\r\n]", " "):match("^%s*(.-)%s*$")
  if not cleaned or cleaned == "" then
    return "-"
  end
  return cleaned
end

local function escapeLuaString(s)
  return s:gsub("\\", "\\\\"):gsub('"', '\\"')
end

local function parseSavedTable(src)
  local env = {}
  local chunk
  if setfenv then
    chunk = loadChunk(src, HighScores.FILENAME)
    if chunk then
      setfenv(chunk, env)
    end
  else
    chunk = load(src, HighScores.FILENAME, "t", env)
  end
  if not chunk then
    return nil
  end
  local ok, parsed = pcall(chunk)
  if ok and type(parsed) == "table" then
    return parsed
  end
  return nil
end

function HighScores.reset()
  HighScores.data = {}
  for _, game in ipairs(HighScores.GAMES) do
    local list = {}
    for i = 1, HighScores.MAX_ENTRIES do
      list[i] = { name = "-", score = 0 }
    end
    HighScores.data[game.id] = list
  end
end

function HighScores.serialize()
  local lines = { "return {" }
  for _, game in ipairs(HighScores.GAMES) do
    table.insert(lines, string.format('  ["%s"] = {', game.id))
    local entries = HighScores.data[game.id] or {}
    for i = 1, HighScores.MAX_ENTRIES do
      local e = entries[i] or { name = "-", score = 0 }
      table.insert(
        lines,
        string.format('    { name = "%s", score = %d },', escapeLuaString(sanitizeName(e.name)), math.max(0, math.floor(tonumber(e.score) or 0)))
      )
    end
    table.insert(lines, "  },")
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

function HighScores.load()
  HighScores.reset()
  if not (love and love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(HighScores.FILENAME)) then
    return
  end
  local src = love.filesystem.read(HighScores.FILENAME)
  if not src then
    return
  end
  local parsed = parseSavedTable(src)
  if not parsed then
    return
  end
  for _, game in ipairs(HighScores.GAMES) do
    local savedList = parsed[game.id]
    if type(savedList) == "table" then
      local dest = HighScores.data[game.id]
      for i = 1, HighScores.MAX_ENTRIES do
        local row = savedList[i]
        if type(row) == "table" then
          local scoreVal = math.max(0, math.floor(tonumber(row.score) or 0))
          dest[i] = {
            name = sanitizeName(row.name),
            score = scoreVal,
          }
        end
      end
    end
  end
end

function HighScores.save()
  if not (love and love.filesystem and love.filesystem.write) then
    return false
  end
  return love.filesystem.write(HighScores.FILENAME, HighScores.serialize())
end

function HighScores.getEntries(gameId)
  return HighScores.data[gameId]
end

function HighScores.qualifies(gameId, score)
  local entries = HighScores.data[gameId]
  if not entries or type(score) ~= "number" then
    return false
  end
  local finalScore = math.floor(score)
  return finalScore > 0 and finalScore > entries[HighScores.MAX_ENTRIES].score
end

function HighScores.insert(gameId, name, score)
  local entries = HighScores.data[gameId]
  if not entries or type(score) ~= "number" then
    return nil
  end
  local finalScore = math.floor(score)
  if finalScore <= 0 then
    return nil
  end
  local cleanName = sanitizeName(name)
  for i = 1, HighScores.MAX_ENTRIES do
    if finalScore >= entries[i].score then
      table.insert(entries, i, { name = cleanName, score = finalScore })
      while #entries > HighScores.MAX_ENTRIES do
        table.remove(entries)
      end
      HighScores.save()
      return i
    end
  end
  return nil
end

HighScores.reset()

return HighScores
