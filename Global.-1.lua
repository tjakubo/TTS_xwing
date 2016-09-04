
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

function Dist_Pos(pos1, pos2)
    return math.sqrt( math.pow(pos1[1]-pos2[1], 2) + math.pow(pos1[3]-pos2[3], 2) )
end

function Dist_Obj(obj1, obj2)
    local pos1 = obj1.getPosition()
    local pos2 = obj2.getPosition()
    return Dist_Pos(pos1, pos2)
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

function Vect_Length(vector)
    return math.sqrt(vector[1]*vector[1] + vector[3]*vector[3])
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

function XW_ObjMatchType(obj, type)
    if type == 'ship' then
        if obj.tag == 'Figurine' then return true end
    elseif type == 'token' then
        if (token.tag == 'Chip' or token.getVar('XW_lockSet') ~= nil) then return true end
    elseif type == 'lock' then
        if token.getVar('XW_lockSet') ~= nil then return true end
    end
    return false
end

function XW_ObjWithinDist(position, maxDistance, type, excludeObj)
    local ships = {}
    --print(position[1] .. position[2] .. position[3])
    for k,obj in pairs(getAllObjects()) do
        if obj ~= excludeObj and XW_ObjMatchType(obj, type) == true then
            if Dist_Pos(position, obj.getPosition()) < maxDistance then
                table.insert(ships, obj)
            end
        end
    end
    return ships
end

function XW_RemoveDuplicateObj(objTable)
    local guidTable = {}
    for k,obj in pairs(objTable) do
        guidTable[obj.getGUID()] = obj
    end
    local uniqueObjTable = {}
    for k,obj in pairs(guidTable) do
        table.insert(uniqueObjTable, obj)
    end
    return uniqueObjTable
end

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
--[[MoveData.straight.baseOffset = function(size, part)
    local baseSize = mm_smallBase
    if size == 'large' then baseSize = mm_largeBase end
    local offsetInit = {0, 0, baseSize/2, 0}
    local offsetFinal = {0, 0, baseSize/2, 0}
    if part == 'init' then return offsetInit
    elseif part == 'final' then return offsetFinal
    else return Vect_Sum()
end]]--
MoveData.straight.smallBaseOffsetInit = {0, 0, mm_smallBase/2, 0}
MoveData.straight.smallBaseOffsetFinal = {0, 0, mm_smallBase/2, 0}
MoveData.straight.smallBaseOffset = Vect_Sum(MoveData.straight.smallBaseOffsetInit, MoveData.straight.smallBaseOffsetFinal)
MoveData.straight.largeBaseOffsetInit = {0, 0, mm_largeBase/2, 0}
MoveData.straight.largeBaseOffsetFinal = {0, 0, mm_largeBase/2, 0}
MoveData.straight.largeBaseOffset = Vect_Sum(MoveData.straight.largeBaseOffsetInit, MoveData.straight.largeBaseOffsetFinal)
MoveData.straight.length = {str_mm[1], str_mm[2], str_mm[3], str_mm[4], str_mm[5]}

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
MoveData.bank.length = {2*math.pi*bankRad_mm[1]/8, 2*math.pi*bankRad_mm[2]/8, 2*math.pi*bankRad_mm[3]/8}

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
MoveData.turn.length = {2*math.pi*turnRad_mm[1]/4, 2*math.pi*turnRad_mm[2]/4, 2*math.pi*turnRad_mm[3]/4}

MoveData.roll = {}
MoveData.roll[1] = {str_mm[1], 0, 0, 0}
MoveData.roll[2] = {str_mm[2], 0, 0, 0}
MoveData.roll[6] = {str_mm[1]/2, 0, 0, 0}
MoveData.roll.smallBaseWiggle = {min={0, 0, -1*mm_smallBase/2, 0}, max={0, 0, mm_smallBase/2, 0}}
MoveData.roll.largeBaseWiggle = {min={0, 0, -1*mm_largeBase/2, 0}, max={0, 0, mm_largeBase/2, 0}}
MoveData.roll.smallBaseOffsetInit = {mm_smallBase/2, 0, 0, 0}
MoveData.roll.smallBaseOffsetFinal = {mm_smallBase/2, 0, 0, 0}
MoveData.roll.smallBaseOffset = Vect_Sum(MoveData.roll.smallBaseOffsetInit, MoveData.roll.smallBaseOffsetFinal)
MoveData.roll.largeBaseOffsetInit = {mm_largeBase/2, 0, 0, 0}
MoveData.roll.largeBaseOffsetFinal = {mm_largeBase/2, 0, 0, 0}
MoveData.roll.largeBaseOffset = Vect_Sum(MoveData.roll.largeBaseOffsetInit, MoveData.roll.largeBaseOffsetFinal)



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
    local info = {type='invalid', speed=nil, dir=nil, extra=nil, size=nil}

    if ship.getName():find('LGS') ~= nil then info.size = 'large'
    else info.size = 'small' end

    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info.type = 'straight'
        info.speed = tonumber(move_code:sub(2,2))
        if move_code:sub(1,1) == 'k' then
            info.extra = 'koiogran'
        end
        if info.speed > 5 then info.type = 'invalid' end
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
        if info.speed > 3 then info.type = 'invalid' end
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
        if info.speed > 3 then info.type = 'invalid' end
    elseif move_code:sub(1,1) == 'x' or move_code:sub(1,1) == 'c' then
        info.type = 'roll'
        --if move_code:sub(1,1) == 'c' then info.type = 'decloak' end
        info.dir = 'right'
        info.speed = 1
        if info.size == 'large' then info.speed = info.speed+5 end
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 'f' then
            info.extra = 'forward'
        elseif move_code:sub(-1,-1) == 'b' then
            info.extra = 'backward'
        end

        if move_code:sub(2,2) == 's' then info.speed = 2 info.extra = 'straight' end

        if info.speed > 2 or (info.size == 'large' and info.speed > 1) then info.type = 'invalid' end

    end
    -- check database
    -- else

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
    if info.type == 'invalid' then print('Wrong move') return {0, 0, 0, 0} end
    data = Lua_ShallowCopy(MoveData[info.type][info.speed])
    if info.dir == 'left' then data = MoveData.LeftVariant(data) end
    if info.extra == 'koiogran' or info.extra == 'segnor' then
        data = MoveData.TurnAroundVariant(data)
    elseif info.extra == 'talon' then
        data = MoveData.TurnInwardVariant(data)
    end
    if info.type == 'roll' then

        if info.extra == 'straight' then return MoveData.DecodeFull('s' .. info.speed, ship) end

        if info.extra == 'forward' then
            data = Vect_Sum(data, MoveData.roll[info.size .. 'BaseWiggle'].max)
        elseif info.extra == 'backward' then
            data = Vect_Sum(data, MoveData.roll[info.size .. 'BaseWiggle'].min)
        end
    end
    data = MoveData.BaseOffset(data, info)

    return MoveData.ConvertDataToIGU(data)
end


-- Get a position of a ship if it would do A PART of the move

PartMax = 1000

MoveData.DecodePartial = function(move_code, ship, part)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)

    if part >= PartMax then return MoveData.DecodeFull(move_code, ship)
    elseif part < 0 then return {0, 0, 0, 0} end
    if info.type == 'invalid' then print('Wrong move partial') return {0, 0, 0, 0} end

    if info.type == 'straight' then
        data = MoveData.DecodeFull(move_code, ship)
        if part < PartMax then data[4] = 0 end
        data[3] = data[3]*(part/PartMax)
    elseif info.type == 'bank' or info.type == 'turn' then

        local initOffLen = Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        local moveLen = MoveData[info.type].length[info.speed]
        local finalOffLen = Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
        local totalLen = initOffLen + moveLen + finalOffLen

        local initPartCutoff = (initOffLen/totalLen)*PartMax
        local movePartCutoff = ((initOffLen+moveLen)/totalLen)*PartMax

        if part <= initPartCutoff then
            local offset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetInit'])[3]*(part/initPartCutoff)
            local angle = MoveData[info.type][info.speed][4]*(part/PartMax)
            --if info.dir == 'left' then angle = -1*angle end
            data = {0, 0, offset, angle}
            if info.dir == 'left' then data=MoveData.LeftVariant(data) end
        elseif part > movePartCutoff then
            data = MoveData.DecodeFull(move_code, ship)
            data[4] = MoveData[info.type][info.speed][4]*(part/PartMax)
            if info.dir == 'left' then data[4] = -1*data[4] end

            part = (part-PartMax)*(-1/(PartMax-movePartCutoff))

            local xInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[1]*part
            local zInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[3]*part
            if info.dir == 'left' then xInset = xInset * -1 end
            data[1] = data[1] - xInset
            data[3] = data[3] - zInset
        else
            local angle = MoveData[info.type][info.speed][4]*(part/PartMax)
            if info.dir == 'left' then angle = -1*angle end
            data = Lua_ShallowCopy(MoveData[info.type][info.size .. 'BaseOffsetInit'])
            part = (part-(initPartCutoff))*(PartMax/(movePartCutoff-initPartCutoff))
            local fullArg = nil
            if info.type == 'bank' then fullArg = math.pi/4
            elseif info.type == 'turn' then fullArg = math.pi/2 end
            local arg = (fullArg*part)/PartMax
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

    elseif info.type == 'roll' then

        if info.extra == 'straight' then return MoveData.DecodePartial('s' .. info.speed, ship, part) end

        part = (part-(PartMax/2))*2
        local move_code_adj = move_code
        if move_code:sub(-1, -1) == 'f' or move_code:sub(-1, -1) == 'b' then
            move_code_adj = move_code:sub(1, 2)
        end
        data = MoveData.DecodeFull(move_code_adj, ship)
        local partOffset = {0, 0, 0, 0}
        if part > 0 then
            partOffset = Lua_ShallowCopy(MoveData.roll[info.size .. 'BaseWiggle'].max)
            partOffset[3] = partOffset[3]*(part/PartMax)
        elseif part < 0 then
            partOffset = Lua_ShallowCopy(MoveData.roll[info.size .. 'BaseWiggle'].min)
            partOffset[3] = partOffset[3]*(part/PartMax)*-1
        end
        partOffset = MoveData.ConvertDataToIGU(partOffset)
        data = Vect_Sum(data, partOffset)
        --data = MoveData.ConvertDataToIGU(data)
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

--MoveModule.restWaitQuota = {}

MoveModule.PerformMove = function(move_code, ship)
    --[[local initCheckSectNum = 4 + MoveData.DecodeInfo(move_code, ship).speed
    local k=initCheckSectNum
    local initCheckPos = {}
    local initCheckPart = {}
    while k >= 0 do
        table.insert(initCheckPos, MoveData.GetPartialPos(move_code, ship, (k/initCheckSectNum)*PartMax))

        k = k-1
    end

    actPart = MaxPart

    while actPart > 0 do
        MoveModule.getPartialPos(move_code, ship, actPart)

    end   ]]--
    local info = MoveData.DecodeInfo(move_code, ship)
    local moveLength = Convert_mm_igu(MoveData[info.type].length[info.speed])
    moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
    moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
    local ships = XW_ObjWithinDist(MoveModule.GetPartialPos(move_code, ship, PartMax/2).pos, 10, 'ship', ship)
    local actPart = PartMax
    local okPart = PartMax
    local checkNum = 0
    local maxMargin = Convert_mm_igu(mm_smallBase)*0.95
    while actPart > 0 do
        local minDist = 9999
        print(actPart)
        local nPos = MoveModule.GetPartialPos(move_code, ship, actPart)
        local collision = false
        for k,colShip in pairs(ships) do
            checkNum = checkNum + 1
            if collide(nPos, {pos=colShip.getPosition(), rot=colShip.getRotation()}) == true then
                collision = true
                local dist = Dist_Pos(nPos.pos, colShip.getPosition())
                print('col: ' .. colShip.getName() .. ' : ' .. dist)
                if dist < minDist then minDist = dist end
                break
            end

        end
        if collision == true then
            if minDist < maxMargin then
                print('DTS: ' .. maxMargin-minDist)
                local pBef = nPos.pos
                actPart=actPart-(((maxMargin-minDist)*PartMax)/moveLength)
                local pAft = MoveModule.GetPartialPos(move_code, ship, actPart).pos
                print('SKIP: ' .. Dist_Pos(pBef, pAft))
            else
                actPart = actPart - 1
            end
        else print('OK') break end
    end
    local finPos = MoveModule.GetPartialPos(move_code, ship, actPart)
    ship.setPosition(finPos.pos)
    ship.setRotation(finPos.rot)
    ship.setDescription('')
    print('CN: ' .. checkNum)

end


-- END MAIN MOVEMENT MODULE
--------

iter = 0
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
                MoveModule.PerformMove(obj.getDescription(), obj)
                --[[local finalPos = MoveModule.GetFinalPos(obj.getDescription(), obj)
                obj.setPosition(finalPos.pos)
                obj.setRotation(finalPos.rot)
                obj.setDescription('')]]--
                --[[sobj = obj
                spos = sobj.getPosition()
                srot = sobj.getRotation()
                colship = nil
                fin = false
                fin2 = false]]--
            end
        end
    else
        --[[if colship == nil then
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
                iter = PartMax sobj = nil fin2 = true
            end
        end
]]--
        --[[iter = iter+2
        print(iter)
        sobj.setPosition(spos)
        sobj.setRotation(srot)
        local finPos = MoveModule.GetPartialPos(sobj.getDescription(), sobj, iter)
        sobj.setPosition(finPos.pos)
        sobj.setRotation(finPos.rot)
        if iter > PartMax then iter = 0 sobj.setDescription('') sobj = nil end--]]
    end
end

function getCorners(shipInfo)
    local corners = {}
    local spos = shipInfo.pos
    local srot = shipInfo.rot[2]
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

function collide(shipInfo1, shipInfo2)
    local c2 = getCorners(shipInfo1)
    local c1 = getCorners(shipInfo2)
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