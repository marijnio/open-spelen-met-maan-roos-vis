-- Mini-game 4: Kleurplaat

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "klplaat",
    title = "Kleurplaat",
    background = "klplaat",
    helpVo = "klpsphp1",
  })
end
