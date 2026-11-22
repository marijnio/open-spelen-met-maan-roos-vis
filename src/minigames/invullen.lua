-- Mini-game 5: Invullen

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "invullen",
    title = "Invullen",
    background = "invullen",
    helpVo = "invsphp1",
  })
end
