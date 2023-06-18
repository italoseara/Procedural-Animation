local Class = require 'libs.classic'
local Vector = require 'libs.vector'
local IK = require 'libs.IK'

local Salamander = Class:extend()

function Salamander:new(x, y)
    self.pos = Vector(x, y)
    self.vel = Vector(0, 0)
    self.acc = Vector(0, 0)

    self.max_speed = 100

    self.desired = Vector(0, 0)
    self.steer = Vector(0, 0)

    self.body = IK()
    self.body:addSegment(15, 5)
    self.body:addSegment(15, 5)
    self.body:addSegment(15, 5)
    self.body:addSegment(20, 8)
    self.body:addSegment(20, 8)
    self.body:addSegment(20, 10)
    self.body:addSegment(20, 10)
    self.body:addSegment(20, 10)
    self.body:addSegment(15, 15)
    self.body:addSegment(18, 18)
    self.body:addSegment(20, 20)
    self.body:addSegment(20, 20)
    self.body:addSegment(18, 18)
    self.body:addSegment(16, 16)
    self.body:addSegment(12, 12)
    self.body:addSegment(20, 20)

    self.feet = {}
    self:addFeet(1, 10, 30, 1)
    self:addFeet(6, 10, 30, 0)
end

function Salamander:addFeet(index, angle, length, firstStep)
    local foot = {
        body = #self.body.segments - index,
        angle = angle,
        length = length,

        step = firstStep,
        lastStep = 0,

        desired = {
            left = Vector(0, 0),
            right = Vector(0, 0),
        },
        current = {
            left = Vector(0, 0),
            right = Vector(0, 0),
        },

        legs = {
            left = IK(),
            right = IK(),
        },
    }

    local point = self.body.segments[foot.body]:getMediumPoint()

    foot.legs.left:addSegment(foot.length / 2, 0, 180, 0)
    foot.legs.left:addSegment(foot.length / 2)
    foot.legs.left:setTarget(foot.current.left.x, foot.current.left.y)
    foot.legs.left:setFixedPoint(point.x, point.y)

    foot.legs.right:addSegment(foot.length / 2, 0, 180, 0)
    foot.legs.right:addSegment(foot.length / 2)
    foot.legs.right:setTarget(foot.current.right.x, foot.current.right.y)
    foot.legs.right:setFixedPoint(point.x, point.y)

    table.insert(self.feet, foot)
end

function Salamander:seek(target)
    -- if the target is too close, don't seek
    if self.pos:dist(target) < 20 then
        return
    end

    self.desired = target - self.pos
    self.desired = self.desired:normalized() * self.max_speed

    self.steer = self.desired - self.vel
    self.acc = self.acc + self.steer
end

function Salamander:move(dt)
    -- Increase the salamander's speed if the player is holding the mouse button
    if love.mouse.isDown(1) then
        self.max_speed = 500
    else
        self.max_speed = 100
    end

    -- Apply acceleration to velocity
    self.vel = self.vel + self.acc * dt

    -- Apply velocity to position
    self.pos = self.pos + self.vel * dt

    -- Reset acceleration
    self.acc = Vector(0, 0)
end

function Salamander:updateFeet(dt)
    for i, foot in ipairs(self.feet) do
        local body = self.body.segments[foot.body]
        local angle = body.angle + math.rad(foot.angle)
        local pos = body:getMediumPoint()

        -- Calculate the desired position of the feet
        local left = Vector(0, 0)
        local right = Vector(0, 0)

        right.x = pos.x + math.cos(angle) * foot.length
        right.y = pos.y + math.sin(angle) * foot.length

        left.x = pos.x + math.cos(angle - 2 * math.rad(foot.angle)) * foot.length
        left.y = pos.y + math.sin(angle - 2 * math.rad(foot.angle)) * foot.length

        local speed = (1 / self.vel:len()) * 30

        -- If the foot is not in the desired position, move it
        if foot.lastStep < love.timer.getTime() - speed then
            if foot.step == 1 then
                local distance = foot.desired.right:dist(right)

                if distance > foot.length / 2 then
                    foot.desired.right = right
                    foot.step = 0
                    foot.lastStep = love.timer.getTime()
                end
            else
                local distance = foot.desired.left:dist(left)

                if distance > foot.length / 2 then
                    foot.desired.left = left
                    foot.step = 1
                    foot.lastStep = love.timer.getTime()
                end
            end
        end

        -- Update the current position of the feet using a lerp
        local lerpSpeed = self.vel:len() * dt / 5

        foot.current.right.x = foot.current.right.x + (foot.desired.right.x - foot.current.right.x) * lerpSpeed
        foot.current.right.y = foot.current.right.y + (foot.desired.right.y - foot.current.right.y) * lerpSpeed

        foot.current.left.x = foot.current.left.x + (foot.desired.left.x - foot.current.left.x) * lerpSpeed
        foot.current.left.y = foot.current.left.y + (foot.desired.left.y - foot.current.left.y) * lerpSpeed

        -- pull the body slightly toward the moving leg using a lerp
        if foot.step == 1 then
            local right = Vector(0, 0)
            right.x = pos.x + math.cos(angle + math.rad(90)) * foot.length / 10
            right.y = pos.y + math.sin(angle + math.rad(90)) * foot.length / 10

            body:pullTo(right.x, right.y, lerpSpeed)
        else
            local left = Vector(0, 0)
            left.x = pos.x + math.cos(angle - math.rad(90)) * foot.length / 10
            left.y = pos.y + math.sin(angle - math.rad(90)) * foot.length / 10

            body:pullTo(left.x, left.y, lerpSpeed)
        end

        -- Update the IK legs
        foot.legs.left:setTarget(foot.current.left.x, foot.current.left.y)
        foot.legs.left:setFixedPoint(pos.x, pos.y)
        foot.legs.left:update()

        foot.legs.right:setTarget(foot.current.right.x, foot.current.right.y)
        foot.legs.right:setFixedPoint(pos.x, pos.y)
        foot.legs.right:update()
    end
end

function Salamander:updateBody(dt)
    self.body:setTarget(self.pos.x, self.pos.y)
    self.body:update()
end

function Salamander:update(dt)
    self:updateBody(dt)
    self:updateFeet(dt)
    self:move(dt)
end

function Salamander:draw()
    -- Draw feet
    for i, foot in ipairs(self.feet) do
        local body = self.body.segments[foot.body]
        local pos = body:getMediumPoint()

        love.graphics.setColor(1, 0, 0)
        love.graphics.circle('fill', pos.x, pos.y, body.radius)

        foot.legs.left:draw()
        foot.legs.right:draw()

        local leftHand = foot.legs.left.segments[2].b
        local rightHand = foot.legs.right.segments[2].b

        love.graphics.circle('fill', leftHand.x, leftHand.y, 5)
        love.graphics.circle('fill', rightHand.x, rightHand.y, 5)
    end

    -- Draw body
    love.graphics.setColor(0, 0, 0)
    self.body:draw()

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
