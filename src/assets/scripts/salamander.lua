local Class = require 'libs.classic'
local Vector = require 'libs.vector'

local Salamander = Class:extend()

function Salamander:new(x, y)
    self.pos = Vector(x, y)
    self.vel = Vector(0, 0)
    self.acc = Vector(0, 0)

    self.max_speed = 100

    self.desired = Vector(0, 0)
    self.steer = Vector(0, 0)

    -- The body is a list of body parts, each representing a node
    -- that will act like a string, to make a "snake" effect
    self.body = {
        { pos = Vector(x, y), radius = 7, dist = 0 },
        { pos = Vector(x, y), radius = 5, dist = 12, foot = true },
        { pos = Vector(x, y), radius = 6, dist = 11 },
        { pos = Vector(x, y), radius = 7, dist = 14 },
        { pos = Vector(x, y), radius = 7, dist = 15 },
        { pos = Vector(x, y), radius = 7, dist = 15 },
        { pos = Vector(x, y), radius = 5, dist = 15, foot = true },
        { pos = Vector(x, y), radius = 4, dist = 15 },
        { pos = Vector(x, y), radius = 3, dist = 15 },
        { pos = Vector(x, y), radius = 3, dist = 15 },
        { pos = Vector(x, y), radius = 3, dist = 15 },
        { pos = Vector(x, y), radius = 2, dist = 15 },
        { pos = Vector(x, y), radius = 2, dist = 15 },
        { pos = Vector(x, y), radius = 1, dist = 15 },
    }

    self.feet = {}

    for i = 1, #self.body do
        if self.body[i].foot then
            table.insert(self.feet, {
                node = self.body[i],
                front_node = self.body[i + 1],

                leg_length = 20,
                leg_angle = 25,

                left = Vector(0, 0),
                right = Vector(0, 0),
                left_desired = Vector(0, 0),
                right_desired = Vector(0, 0),

                step = true,
                last_step = 0
            })
        end
    end
end

function Salamander:seek(target)
    -- if the target is too close, don't seek
    if self.pos:dist(target) < 20 then
        return
    end

    self.desired = target - self.pos
    self.desired = self.desired:normalized() * self.max_speed

    self.steer = self.desired - self.vel

    self:applyForce(self.steer)
end

function Salamander:applyForce(force)
    self.acc = self.acc + force
end

function Salamander:calculateFeet(dt)
    for i = 1, #self.feet do
        local foot = self.feet[i]
        local dir = (foot.node.pos - foot.front_node.pos):normalized()

        local left = Vector(0, 0)
        local right = Vector(0, 0)

        left.x = foot.node.pos.x + math.cos(math.rad(foot.leg_angle)) * foot.leg_length
        left.y = foot.node.pos.y + math.sin(math.rad(foot.leg_angle)) * foot.leg_length

        right.x = foot.node.pos.x + math.cos(math.rad(-foot.leg_angle)) * foot.leg_length
        right.y = foot.node.pos.y + math.sin(math.rad(-foot.leg_angle)) * foot.leg_length

        left = foot.node.pos + (left - foot.node.pos):rotated(dir:angleTo())
        right = foot.node.pos + (right - foot.node.pos):rotated(dir:angleTo())

        -- Make the foot stationary unless (distance to step pos > leg length) then move to step pos
        if foot.step then
            local dist = foot.left:dist(foot.node.pos)

            if dist > foot.leg_length and foot.last_step < love.timer.getTime() - 0.1 then
                foot.left_desired = left

                foot.step = false
                foot.last_step = love.timer.getTime()
            end
        else
            local dist = foot.right:dist(foot.node.pos)

            if dist > foot.leg_length and foot.last_step < love.timer.getTime() - 0.1 then
                foot.right_desired = right

                foot.step = true
                foot.last_step = love.timer.getTime()
            end
        end

        -- Lerp the feet to the desired position
        foot.left = foot.left + (foot.left_desired - foot.left) * 25 * dt
        foot.right = foot.right + (foot.right_desired - foot.right) * 25 * dt
    end
end

function Salamander:updateBody(dt)
    self.body[1].pos = self.pos

    for i = 2, #self.body do
        local dist = self.body[i].pos:dist(self.body[i - 1].pos)

        if dist > self.body[i].dist then
            local dir = (self.body[i - 1].pos - self.body[i].pos):normalized()
            self.body[i].pos = self.body[i].pos + dir * (dist - self.body[i].dist)
        end
    end

    self:calculateFeet(dt)
end

function Salamander:update(dt)
    -- Increase the salamander's speed if the player is holding the mouse button
    if love.mouse.isDown(1) then
        self.max_speed = 500
    else
        self.max_speed = 100
    end

    -- Update body
    self:updateBody(dt)

    -- Apply acceleration to velocity
    self.vel = self.vel + self.acc * dt

    -- Apply velocity to position
    self.pos = self.pos + self.vel * dt

    -- Reset acceleration
    self.acc = Vector(0, 0)
end

function Salamander:draw()
    -- Draw body
    for i = 1, #self.body do
        if self.body[i].foot then
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle('fill', self.body[i].pos.x, self.body[i].pos.y, self.body[i].radius)
            love.graphics.setColor(0, 0, 0)
        end

        love.graphics.circle('line', self.body[i].pos.x, self.body[i].pos.y, self.body[i].radius)
    end

    -- Connect the points of the body
    for i = 1, #self.body - 1 do
        love.graphics.line(self.body[i].pos.x, self.body[i].pos.y, self.body[i + 1].pos.x, self.body[i + 1].pos.y)
    end

    -- Draw feet
    love.graphics.setColor(1, 0, 0)
    for i = 1, #self.feet do
        local foot = self.feet[i]

        love.graphics.line(foot.node.pos.x, foot.node.pos.y, foot.left.x, foot.left.y)
        love.graphics.line(foot.node.pos.x, foot.node.pos.y, foot.right.x, foot.right.y)

        love.graphics.circle('fill', foot.left.x, foot.left.y, 4)
        love.graphics.circle('fill', foot.right.x, foot.right.y, 4)
    end
    love.graphics.setColor(0, 0, 0)

    -- Desired
    love.graphics.setColor(1, 0, 0)
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.desired.x / 5, self.pos.y + self.desired.y / 5)

    -- Steer
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.steer.x / 5, self.pos.y + self.steer.y / 5)

    -- Velocity
    love.graphics.setColor(0, 0, 1)
    love.graphics.line(self.pos.x, self.pos.y, self.pos.x + self.vel.x / 5, self.pos.y + self.vel.y / 5)

    love.graphics.setColor(0, 0, 0)
end

return Salamander
