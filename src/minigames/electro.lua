-- Mini-game 2: Woordplaatje (Electro)

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "electro",
    title = "Woordplaatje",
    background = "electro",
    helpVo = "wplsphp1",
  })
end
