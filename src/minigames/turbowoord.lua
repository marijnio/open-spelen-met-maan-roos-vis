-- Mini-game 6: Luister maar / Turbowoord

local BaseMinigame = require("src.minigames.base_minigame")

return function(app)
  return BaseMinigame.new(app, {
    id = "turbowoord",
    title = "Luister maar",
    background = "turbow",
    helpVo = "luisphp1",
  })
end
