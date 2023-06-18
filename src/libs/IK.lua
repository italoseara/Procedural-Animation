local module = {
    _version = "Lua-Inverse-Kinematics v2023.0.1",
    _description = "A simple Inverse Kinematics library for LÖVE",
    _url = "https://github.com/italoseara/Lua-Inverse-Kinematics",
    _license = [[
        MIT License

        Copyright (c) 2023 Italo Seara

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

local Vector = require "libs.vector"

local Segment = {}
Segment.__index = Segment

function Segment.new(length, circ)
    local self = setmetatable({}, Segment)
    self.a = Vector(0, 0)
    self.b = Vector(0, 0)
    self.length = length
    self.angle = 0

    if circ ~= nil then
        self.radius = circ / 2
    end
    return self
end

function Segment:update()
    local d = Vector.fromPolar(self.angle, self.length)
    self.b.x = self.a.x + d.x
    self.b.y = self.a.y + d.y
end

function Segment:follow(target)
    local target = Vector(target.x, target.y)
    local dir = target - self.a
    self.angle = dir:heading()

    dir:setMag(self.length)
    dir = dir * -1

    self.a = target + dir
end

function Segment:getMediumPoint()
    return Vector((self.a.x + self.b.x) / 2, (self.a.y + self.b.y) / 2)
end

function Segment:draw(debug)
    love.graphics.line(self.a.x, self.a.y, self.b.x, self.b.y)

    if self.radius ~= nil then
        local pos = self:getMediumPoint()
        love.graphics.circle('line', pos.x, pos.y, self.radius)
    end

    if debug then
        love.graphics.circle("fill", self.a.x, self.a.y, 5)
        love.graphics.circle("fill", self.b.x, self.b.y, 5)
    end
end

local IK = {}
IK.__index = IK

function IK.new()
    local self = setmetatable({}, IK)
    self.segments = {}
    self.fixedPoint = nil
    self.target = nil
    self.debug = false
    return self
end

function IK:setFixedPoint(x, y)
    self.fixedPoint = Vector(x, y)
end

function IK:addSegment(length, circ)
    table.insert(self.segments, Segment.new(length, circ))
end

function IK:setTarget(x, y)
    self.target = Vector(x, y)
end

function IK:update()
    if not self.target then return end

    local last = self.segments[#self.segments]
    last:follow(self.target)

    for i = #self.segments - 1, 1, -1 do
        local segment = self.segments[i]
        local nextSegment = self.segments[i + 1]
        segment:follow(nextSegment.a)
    end

    if self.fixedPoint then
        local first = self.segments[1]
        first.a = self.fixedPoint

        for i = 2, #self.segments do
            local segment = self.segments[i]
            local prevSegment = self.segments[i - 1]
            segment.a = prevSegment.b
        end
    end

    for _, segment in ipairs(self.segments) do
        segment:update()
    end
end

function IK:draw()
    for _, segment in ipairs(self.segments) do
        segment:draw(self.debug)
    end

    if self.debug then
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", self.target.x, self.target.y, 5)
    end
end

return setmetatable({
    new = IK.new,
}, {
    __call = function(_) return IK.new() end
})
