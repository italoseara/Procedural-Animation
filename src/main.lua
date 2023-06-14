local Salamander = require 'assets.scripts.salamander'
local Vector = require 'libs.vector'

local salamander, target

function love.load()
    love.graphics.setBackgroundColor(0.9, 0.9, 0.9)

    salamander = Salamander(100, 100)
    target = Vector(love.mouse.getPosition())
end

function love.update(dt)
    target = Vector(love.mouse.getPosition())

    salamander:seek(target)
    salamander:update(dt)
end

function love.draw()
    salamander:draw()
end
