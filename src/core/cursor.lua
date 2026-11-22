-- Safe mouse cursor helper that acts as a no-op on touch-only platforms (e.g., Android).

local Cursor = {}
local systemCache = {}

--- Returns whether the current platform supports custom or system mouse cursors.
function Cursor.isSupported()
  return love ~= nil
    and love.mouse ~= nil
    and love.mouse.isCursorSupported ~= nil
    and love.mouse.isCursorSupported() == true
end

--- Safely retrieves and caches a system cursor, returning nil if unsupported.
function Cursor.getSystem(kind)
  if not Cursor.isSupported() then
    return nil
  end
  if systemCache[kind] ~= nil then
    return systemCache[kind] or nil
  end
  local ok, cur = pcall(love.mouse.getSystemCursor, kind)
  if ok and cur then
    systemCache[kind] = cur
    return cur
  end
  systemCache[kind] = false
  return nil
end

--- Safely creates a cursor from ImageData, returning nil if unsupported.
function Cursor.newFromImageData(data, hotx, hoty)
  if not Cursor.isSupported() or not data then
    return nil
  end
  local ok, cur = pcall(love.mouse.newCursor, data, hotx, hoty)
  if ok and cur then
    return cur
  end
  return nil
end

--- Safely sets the active mouse cursor, ignoring nil or unsupported platforms.
function Cursor.set(cursor)
  if not Cursor.isSupported() or cursor == nil then
    return
  end
  love.mouse.setCursor(cursor)
end

return Cursor
