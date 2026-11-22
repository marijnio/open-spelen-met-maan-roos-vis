-- Mini-game 3: Draai maar om (Draaiom)

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "draaiom",
    title = "Draai maar om",
    background = "draaiom",
    helpVo = "drasphp1",
  })
end
