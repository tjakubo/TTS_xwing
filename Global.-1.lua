
--------
-- MEASUREMENT RELATED FUNCTIONS

-- 40mm = 1.445igu
-- (s1 length / small base size)

-- 1mm = 0.36125igu
mm_igu_ratio = 0.036125

-- Milimeter dimensions of ship bases
mm_smallBase = 40
mm_largeBase = 80

-- Convert argument from MILIMETERS to IN-GAME UNITS
function Convert_mm_igu(milimeters)
    return milimeters*mm_igu_ratio
end

-- Convert argument from MILIMETERS to IN-GAME UNITS
function Convert_igu_mm(in_game_units)
    return in_game_units/mm_igu_ratio
end

-- END MEASUREMENT RELATED FUNCTIONS
--------

--------
-- VECTOR RELATED FUNCTIONS

-- Sum of two vectors (of any size)
function Vect_Sum(vec1, vec2)
    local out = {}
    local k = 1
    while vec1[k] ~= nil and vec2[k] ~= nil do
        out[k] = vec1[k]+vec2[k]
        k = k+1
    end
    return out
end

function Vect_Inverse(vector)
    local out = {}
    local k = 1
    while vector[k] ~= nil do
        out[k] = -1*vector[k]
        k = k+1
    end
    return out
end

-- Offset self vector by first and third element of vec2 (second el ignored)
-- Useful for TTS positioning offsets
function Vect_Offset(self, vec2)
    return {self[1]+vec2[1], self[2], self[3]+vec2[3]}
end

-- Euclidean norm of a 3D vector, second element is ignored
function Vect_Norm(vector)
    return math.sqrt((vector[1]*vector[1])+(vector[3]*vector[3]))
end

-- Rotation of a 3D vector over its second element axis, arg in degrees
function Vect_RotateDeg(vector, degRotation)
    local radRotation = math.rad(degRotation)
    return Vect_RotateRad(vector, radRotation)
end

-- Rotation of a 3D vector over its second element axis, arg in radians
function Vect_RotateRad(vector, radRotation)
    local newX = math.cos(radRotation) * vector[1] + math.sin(radRotation) * vector[3]
    local newZ = math.sin(radRotation) * vector[1] * -1 + math.cos(radRotation) * vector[3]
    return {newX, vector[2], newZ}
end

-- END VECTOR RELATED FUNCTIONS
--------

--------
-- MISC FUNCTIONS

-- Simple shallow copy to cope with Lua reference handling
function Lua_ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end

-- END MISC FUNCTIONS
--------


--------
-- MAIN MOVEMENT MODULE

-- ~~~~~~
-- CONFIGURATION:

-- How many milimeters forward with straight move {speed 1, speed 2, etc}
str_mm = {40, 80, 120, 160, 200}

-- How big (radius) is the bank template circle {speed 1, speed 2, speed 3}
bankRad_mm = {80, 130, 180}

-- How big (radius) is the turn template circle {speed 1, speed 2, speed 3}
turnRad_mm = {35, 62.5, 90}
-- ~~~~~~


-- Table telling us how moves final position is determined
-- Format: {xOffset, yOffset, zOffset, rotOffset}
-- Axis' offsets are in milimeters, rotation offset is in degrees
-- Includes all member functions to process the data
MoveData = {}

-- Straights
-- Path is some distance (see CONFIGURATION) in one direction, no rotation
-- Base offset is base length in that direction
MoveData.straight = {}
MoveData.straight[1] = {0, 0, str_mm[1], 0}
MoveData.straight[2] = {0, 0, str_mm[2], 0}
MoveData.straight[3] = {0, 0, str_mm[3], 0}
MoveData.straight[4] = {0, 0, str_mm[4], 0}
MoveData.straight[5] = {0, 0, str_mm[5], 0}
MoveData.straight.smallBaseOffsetInit = {0, 0, mm_smallBase/2, 0}
MoveData.straight.smallBaseOffsetFinal = {0, 0, mm_smallBase/2, 0}
MoveData.straight.smallBaseOffset = Vect_Sum(MoveData.straight.smallBaseOffsetInit, MoveData.straight.smallBaseOffsetFinal)
MoveData.straight.largeBaseOffsetInit = {0, 0, mm_largeBase/2, 0}
MoveData.straight.largeBaseOffsetFinal = {0, 0, mm_largeBase/2, 0}
MoveData.straight.largeBaseOffset = Vect_Sum(MoveData.straight.largeBaseOffsetInit, MoveData.straight.largeBaseOffsetFinal)

-- Banks RIGHT (member function to modify to left)
-- Path traversed is eighth part (1/8 or 45deg) of a circle of specified radius (see CONFIGURATION)
-- Base offset is half base forward initially and half base 45deg in the bank direction at the end
-- Rotation is 45deg in the bank direction
MoveData.bank = {}
MoveData.bank[1] = {bankRad_mm[1]-(bankRad_mm[1]/math.sqrt(2)), 0, bankRad_mm[1]/math.sqrt(2), 45}
MoveData.bank[2] = {bankRad_mm[2]-(bankRad_mm[2]/math.sqrt(2)), 0, bankRad_mm[2]/math.sqrt(2), 45}
MoveData.bank[3] = {bankRad_mm[3]-(bankRad_mm[3]/math.sqrt(2)), 0, bankRad_mm[3]/math.sqrt(2), 45}
MoveData.bank.smallBaseOffsetInit = {0, 0, mm_smallBase/2, 0}
MoveData.bank.smallBaseOffsetFinal = {(mm_smallBase/2)/math.sqrt(2), 0, (mm_smallBase/2)/math.sqrt(2), 0}
MoveData.bank.smallBaseOffset = Vect_Sum(MoveData.bank.smallBaseOffsetInit, MoveData.bank.smallBaseOffsetFinal)
MoveData.bank.largeBaseOffsetInit = {0, 0, mm_largeBase/2, 0}
MoveData.bank.largeBaseOffsetFinal = {(mm_largeBase/2)/math.sqrt(2), 0, (mm_largeBase/2)/math.sqrt(2), 0}
MoveData.bank.largeBaseOffset = Vect_Sum(MoveData.bank.largeBaseOffsetInit, MoveData.bank.largeBaseOffsetFinal)

-- Turns RIGHT (member function to modify to left)
-- Path traversed is fourth part (1/4 or 90deg) of a circle of specified radius (see CONFIGURATION)
-- Base offset is half base forward initially and half 90deg in the turn direction at the end
-- Rotation is 90deg in the turn direction
MoveData.turn = {}
MoveData.turn[1] = {turnRad_mm[1], 0, turnRad_mm[1], 90}
MoveData.turn[2] = {turnRad_mm[2], 0, turnRad_mm[2], 90}
MoveData.turn[3] = {turnRad_mm[3], 0, turnRad_mm[3], 90}
MoveData.turn.smallBaseOffsetInit = {0, 0, mm_smallBase/2, 0}
MoveData.turn.smallBaseOffsetFinal = {mm_smallBase/2, 0, 0, 0}
MoveData.turn.smallBaseOffset = Vect_Sum(MoveData.turn.smallBaseOffsetInit, MoveData.turn.smallBaseOffsetFinal)
MoveData.turn.largeBaseOffsetInit = {0, 0, mm_largeBase/2, 0}
MoveData.turn.largeBaseOffsetFinal = {mm_largeBase/2, 0, 0, 0}
MoveData.turn.largeBaseOffset = Vect_Sum(MoveData.turn.largeBaseOffsetInit, MoveData.turn.largeBaseOffsetFinal)

-- Convert an entry from milimeters to in-game units
MoveData.ConvertDataToIGU = function(entry)
    return {Convert_mm_igu(entry[1]), Convert_mm_igu(entry[2]), Convert_mm_igu(entry[3]), entry[4]}
end

-- Change an entry to a left-heading version
MoveData.LeftVariant = function(entry)
    return {-1*entry[1], entry[2], entry[3], -1*entry[4]}
end

-- Change an entry to be k-turn like (+180deg rot at the end)
MoveData.TurnAroundVariant = function(entry)
    return {entry[1], entry[2], entry[3], entry[4]+180}
end

-- Change an entry to be talon-roll like (+90deg INWARD rot at the end)
MoveData.TurnInwardVariant = function(entry)
    local dir = 0
    if entry[1] > 0 then dir = 90
    elseif entry[1] < 0 then dir = -90 end
    return {entry[1], entry[2], entry[3], entry[4]+dir}
end

-- Apply base offset to an entry
-- Needs to be done as a member cause both base size and direction affects it
-- 'info' tells about type and direction, 'is_large' tells if the ship base is large
MoveData.BaseOffset = function(entry, info)
    local offset = {}
    if info.size == 'large' then
        offset = MoveData[info.type].largeBaseOffset
    else
        offset = MoveData[info.type].smallBaseOffset
    end
    if info.dir == 'left' then offset = MoveData.LeftVariant(offset) end
    return {entry[1]+offset[1], entry[2]+offset[2], entry[3]+offset[3], entry[4]+offset[4]}
end

MoveData.DecodeInfo = function (move_code, ship)
    local info = {type=nil, speed=nil, dir=nil, extra=nil, size=nil}

    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info.type = 'straight'
        info.speed = tonumber(move_code:sub(2,2))
        if move_code:sub(1,1) == 'k' then
            info.extra = 'koiogran'
        end
    elseif move_code:sub(1,1) == 'b' then
        info.type = 'bank'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 's' then
            info.extra = 'segnor'
        end
    elseif move_code:sub(1,1) == 't' then
        info.type = 'turn'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 't' then
            info.extra = 'talon'
        elseif move_code:sub(-1,-1) == 's' then
            info.extra = 'segnor'
        end
    end
    -- check database
    -- else
    if ship.getName():find('LGS') ~= nil then info.size = 'large'
    else info.size = 'small' end
    return info
end

-- Decode a "move" from the standard X-Wing notation into a valid movement data
-- Provide a 'ship' object reference to determine if it is large based
--- TO_DO: actually check if base is large (include database and failsafe LGS in name handling)
--- TO_DO: barrel rolls, decloaks and all this shit
-- Returns a valid path the ship has to traverse to perform a move (if it was at origin)
-- Standard format {xOffset, yOffset, zOffset, rotOffset}
MoveData.DecodeFull = function(move_code, ship)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)

    data = Lua_ShallowCopy(MoveData[info.type][info.speed])
    if info.dir == 'left' then data = MoveData.LeftVariant(data) end
    if info.extra == 'koiogran' or info.extra == 'segnor' then
        data = MoveData.TurnAroundVariant(data)
    elseif info.extra == 'talon' then
        data = MoveData.TurnInwardVariant(data)
    end
    data = MoveData.BaseOffset(data, info)

    return MoveData.ConvertDataToIGU(data)
end

MoveData.DecodePartial = function(move_code, ship, part)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)

    if part >= 1000 then return MoveData.DecodeFull(move_code, ship)
    elseif part < 0 then return {0, 0, 0, 0} end

    if info.type == 'straight' then
        data = MoveData.DecodeFull(move_code, ship)
        if part < 1000 then data[4] = 0 end
        data[3] = data[3]*(part/1000)
    else
        if part <= 100 then
            local offset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetInit'])[3]*(part/100)
            local angle = MoveData[info.type][info.speed][4]*(part/1000)
            if info.dir == 'left' then angle = -1*angle end
            data = {0, 0, offset, angle}
        elseif part > 900 then
            data = MoveData.DecodeFull(move_code, ship)
            data[4] = MoveData[info.type][info.speed][4]*(part/1000)
            if info.dir == 'left' then data[4] = -1*data[4] end

            part = (part-1000)*(-1/100)

            local xInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[1]*part
            local zInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[3]*part
            if info.dir == 'left' then xInset = xInset * -1 end
            data[1] = data[1] - xInset
            data[3] = data[3] - zInset
        else
            local angle = MoveData[info.type][info.speed][4]*(part/1000)
            if info.dir == 'left' then angle = -1*angle end
            data = Lua_ShallowCopy(MoveData[info.type][info.size .. 'BaseOffsetInit'])
            part = (part-100)*(10/8)
            local fullArg = nil
            if info.type == 'bank' then fullArg = math.pi/4
            elseif info.type == 'turn' then fullArg = math.pi/2 end
            local arg = (fullArg*part)/1000
            local radius = {}
            if info.type == 'bank' then radius = bankRad_mm[info.speed]
            elseif info.type == 'turn' then radius = turnRad_mm[info.speed] end
            local yoff = math.sin(arg)*radius
            local xoff = (-1*math.cos(arg)+1)*radius
            if info.dir == 'left' then xoff = xoff * -1 end

            data[1] = data[1] + xoff
            data[3] = data[3] + yoff
            data[4] = angle
            data = MoveData.ConvertDataToIGU(data)
        end

    end

    return data
end

-- Table containing all the high-level functions used to move stuff around
MoveModule = {}

-- Simply get the final position for a 'ship' if it did a 'move' (standard move code)
-- Format:  out.pos for position, out.rot for rotation
-- Position and rotation are ready to feed TTS functions
MoveModule.GetFinalPos = function(move, ship)
    local finalPos = MoveData.DecodeFull(move, ship)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

MoveModule.GetPartialPos = function(move, ship, part)
    local finalPos = MoveData.DecodePartial(move, ship, part)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

MoveModule.restWaitQuota = {}


-- END MAIN MOVEMENT MODULE
--------

iter = 1000
spos = {}
srot = {}
sobj = nil
colship = nil
fin = false
fin2 = false
-- Sample update to test functionalities
function update()
    if sobj == nil then
        for k,obj in pairs(getAllObjects()) do
            if obj.tag == 'Figurine' and obj.getDescription() ~= '' then
                --[[local finalPos = MoveModule.GetFinalPos(obj.getDescription(), obj)
                obj.setPosition(finalPos.pos)
                obj.setRotation(finalPos.rot)
                obj.setDescription('')]]--
                sobj = obj
                spos = sobj.getPosition()
                srot = sobj.getRotation()
                colship = nil
                fin = false
                fin2 = false
            end
        end
    else
        if colship == nil then
            for k,obj in pairs(getAllObjects()) do
                if obj.getName() == 'TEST' then colship = obj end
            end
        end
        while fin ~= true do
            sobj.setPosition(spos)
            sobj.setRotation(srot)
            local finPos = MoveModule.GetPartialPos(sobj.getDescription(), sobj, iter)
            sobj.setPosition(finPos.pos)
            sobj.setRotation(finPos.rot)
            if collide({sobj, colship}) then iter = iter -10
            else
                fin = true
            end
        end
        while fin2 ~= true do
            iter = iter+1
            sobj.setPosition(spos)
            sobj.setRotation(srot)
            local finPos = MoveModule.GetPartialPos(sobj.getDescription(), sobj, iter)
            sobj.setPosition(finPos.pos)
            sobj.setRotation(finPos.rot)
            if collide({sobj, colship}) then
                sobj.setPosition(spos)
                sobj.setRotation(srot)
                iter = iter - 1 sobj.setDescription('')
                local finPos = MoveModule.GetPartialPos(sobj.getDescription(), sobj, iter)
                sobj.setPosition(finPos.pos)
                sobj.setRotation(finPos.rot)
                iter = 1000 sobj = nil fin2 = true
            end
        end

    end
end

function getCorners(ship)
    local corners = {}
    local spos = ship.getPosition()
    local srot = ship.getRotation()[2]
    local size = 0.7225
    --if isBigShip(guid) == true then
    --    size = size * 2
    --end
    local world_coords = {}
    world_coords[1] = {spos[1] - size, spos[3] + size}
    world_coords[2] = {spos[1] + size, spos[3] + size}
    world_coords[3] = {spos[1] + size, spos[3] - size}
    world_coords[4] = {spos[1] - size, spos[3] - size}
    for r, corr in ipairs(world_coords) do
        local xcoord = spos[1] + ((corr[1] - spos[1]) * math.sin(math.rad(srot))) - ((corr[2] - spos[3]) * math.cos(math.rad(srot)))
        local ycoord = spos[3] + ((corr[1] - spos[1]) * math.cos(math.rad(srot))) + ((corr[2] - spos[3]) * math.sin(math.rad(srot)))
        corners[r] = {xcoord,ycoord}
    end
    return corners
end

function getAxis(c1,c2)
    local axis = {}
    axis[1] = {c1[2][1]-c1[1][1],c1[2][2]-c1[1][2]}
    axis[2] = {c1[4][1]-c1[1][1],c1[4][2]-c1[1][2]}
    axis[3] = {c2[2][1]-c2[1][1],c2[2][2]-c2[1][2]}
    axis[4] = {c2[4][1]-c2[1][1],c2[4][2]-c2[1][2]}
    return axis
end

function dot2d(p,o)
    return p[1] * o[1] + p[2] * o[2]
end

function collide(tab)
    local c2 = getCorners(tab[2])
    local c1 = getCorners(tab[1])
    local axis = getAxis(c1,c2)
    local scalars = {}
    for i1 = 1, #axis do
        for i2, set in pairs({c1,c2}) do
            scalars[i2] = {}
            for i3, point in pairs(set) do
                table.insert(scalars[i2],dot2d(point,axis[i1]))
            end
        end
        local s1max = math.max(unpack(scalars[1]))
        local s1min = math.min(unpack(scalars[1]))
        local s2max = math.max(unpack(scalars[2]))
        local s2min = math.min(unpack(scalars[2]))
        if s2min > s1max or s2max < s1min then
            return false
        end
    end
    return true
end
