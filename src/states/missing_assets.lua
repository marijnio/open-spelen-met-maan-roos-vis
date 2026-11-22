-- Friendly fallback screen shown when local converted assets cannot be located.

local Assets = require("src.core.assets")

local MissingAssetsState = {}
MissingAssetsState.__index = MissingAssetsState

function MissingAssetsState.new(app)
  local self = setmetatable({}, MissingAssetsState)
  self.app = app
  self.statusMessage = nil
  return self
end

function MissingAssetsState:enter()
  self.statusMessage = nil
end

function MissingAssetsState:retry()
  if Assets.init() then
    self.app.scenes:switch("intro")
  else
    self.statusMessage = "Nog steeds geen lokale assets gevonden. Controleer de paden hieronder."
  end
end

function MissingAssetsState:draw()
  love.graphics.clear(0.11, 0.13, 0.18, 1)

  love.graphics.setColor(0.98, 0.85, 0.35, 1)
  love.graphics.print("Spelen met Maan Roos Vis - Lokale assets ontbreken", 28, 24, 0, 1.35, 1.35)

  love.graphics.setColor(0.92, 0.94, 0.96, 1)
  love.graphics.printf(
    "Deze open-source engine bevat geen auteursrechtelijk beschermde bestanden.\n" ..
    "Converteer eerst je eigen kopie van de cd-rom (SYS/) naar LÖVE-bestanden:",
    28,
    62,
    584,
    "left"
  )

  love.graphics.setColor(0.18, 0.22, 0.29, 1)
  love.graphics.rectangle("fill", 28, 108, 584, 52, 6, 6)
  love.graphics.setColor(0.55, 0.95, 0.65, 1)
  love.graphics.print("python3 tools/convert_assets.py --source /pad/naar/SYS --output assets", 38, 118)
  love.graphics.setColor(0.75, 0.85, 0.98, 1)
  love.graphics.print("Of start met:  SMRV_ASSETS_DIR=/pad/naar/assets love .   (of local_config.lua)", 38, 138)

  love.graphics.setColor(0.95, 0.78, 0.45, 1)
  love.graphics.print("Gecontroleerde locaties:", 28, 178)

  local y = 200
  local checked = Assets.getCheckedPaths()
  for i = 1, math.min(#checked, 6) do
    local entry = checked[i]
    love.graphics.setColor(0.85, 0.88, 0.92, 1)
    love.graphics.print(string.format("[%s] %s", entry.label, entry.path), 32, y)
    love.graphics.setColor(0.95, 0.48, 0.48, 1)
    love.graphics.print("  -> " .. tostring(entry.err or "niet gevonden"), 32, y + 15)
    y = y + 36
  end

  if self.statusMessage then
    love.graphics.setColor(1, 0.55, 0.35, 1)
    love.graphics.print(self.statusMessage, 28, 418)
  end

  love.graphics.setColor(0.75, 0.9, 1, 1)
  love.graphics.print("[R] Opnieuw proberen     [Esc] Afsluiten", 28, 446)
  love.graphics.setColor(1, 1, 1, 1)
end

function MissingAssetsState:keypressed(key)
  if key == "r" then
    self:retry()
  elseif key == "escape" then
    love.event.quit()
  end
end

return MissingAssetsState
