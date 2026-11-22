-- Mini-game 1: Onthoud maar (Memory)

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "memory",
    title = "Onthoud maar",
    background = "memory",
    helpVo = "ontsphp1",
  })
end
