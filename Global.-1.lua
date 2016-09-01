
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

-- Sum of two 3D vectors
function Vect_Sum(vec1, vec2)
    return {vec1[1]+vec2[1], vec1[2]+vec2[2], vec1[3]+vec2[3]}
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
MoveData.straight.smallBaseOffset = {0, 0, mm_smallBase, 0}
MoveData.straight.largeBaseOffset = {0, 0, mm_largeBase, 0}

-- Banks RIGHT (member function to modify to left)
-- Path traversed is eighth part (1/8 or 45deg) of a circle of specified radius (see CONFIGURATION)
-- Base offset is half base forward initially and half base 45deg in the bank direction at the end
-- Rotation is 45deg in the bank direction
MoveData.bank = {}
MoveData.bank[1] = {bankRad_mm[1]-(bankRad_mm[1]/math.sqrt(2)), 0, bankRad_mm[1]/math.sqrt(2), 45}
MoveData.bank[2] = {bankRad_mm[2]-(bankRad_mm[2]/math.sqrt(2)), 0, bankRad_mm[2]/math.sqrt(2), 45}
MoveData.bank[3] = {bankRad_mm[3]-(bankRad_mm[3]/math.sqrt(2)), 0, bankRad_mm[3]/math.sqrt(2), 45}
MoveData.bank.smallBaseOffset = {(mm_smallBase/2)/math.sqrt(2), 0, (mm_smallBase/2)+((mm_smallBase/2)/math.sqrt(2)), 0}
MoveData.bank.largeBaseOffset = {(mm_largeBase/2)/math.sqrt(2), 0, (mm_largeBase/2)+((mm_largeBase/2)/math.sqrt(2)), 0}

-- Turns RIGHT (member function to modify to left)
-- Path traversed is fourth part (1/4 or 90deg) of a circle of specified radius (see CONFIGURATION)
-- Base offset is half base forward initially and half 90deg in the turn direction at the end
-- Rotation is 90deg in the turn direction
MoveData.turn = {}
MoveData.turn[1] = {turnRad_mm[1], 0, turnRad_mm[1], 90}
MoveData.turn[2] = {turnRad_mm[2], 0, turnRad_mm[2], 90}
MoveData.turn[3] = {turnRad_mm[3], 0, turnRad_mm[3], 90}
MoveData.turn.smallBaseOffset = {mm_smallBase/2, 0, mm_smallBase/2, 0}
MoveData.turn.largeBaseOffset = {mm_largeBase/2, 0, mm_largeBase/2, 0}

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
MoveData.BaseOffset = function(entry, info, is_large)
    local offset = {}
    if is_large == true then
        offset = MoveData[info.type].largeBaseOffset
    else
        offset = MoveData[info.type].smallBaseOffset
    end
    if info.dir == 'left' then offset = MoveData.LeftVariant(offset) end
    return {entry[1]+offset[1], entry[2]+offset[2], entry[3]+offset[3], entry[4]+offset[4]}
end

-- Decode a "move" from the standard X-Wing notation into a valid movement data
-- Provide a 'ship' object reference to determine if it is large based
--- TO_DO: actually check if base is large (include database and failsafe LGS in name handling)
--- TO_DO: barrel rolls, decloaks and all this shit
-- Returns a valid path the ship has to traverse to perform a move (if it was at origin)
-- Standard format {xOffset, yOffset, zOffset, rotOffset}
MoveData.Decode = function(move_code, ship)
    local data = {}
    local info = {}

    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info = {type='straight', dir=nil}
        data = Lua_ShallowCopy(MoveData.straight[tonumber(move_code:sub(2,2))])
        if move_code:sub(1,1) == 'k' then
            data = MoveData.TurnAroundVariant(data)
        end
    elseif move_code:sub(1,1) == 'b' then
        info = {type='bank', dir='right'}
        data = Lua_ShallowCopy(MoveData.bank[tonumber(move_code:sub(3,3))])
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            data = MoveData.LeftVariant(data)
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 's' then
            data = MoveData.TurnAroundVariant(data)
        end
    elseif move_code:sub(1,1) == 't' then
        info = {type='turn', dir='right'}
        data = Lua_ShallowCopy(MoveData.turn[tonumber(move_code:sub(3,3))])
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            data = MoveData.LeftVariant(data)
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 't' then
            data = MoveData.TurnInwardVariant(data)
        end
    end
    if ship == nil then
        data = MoveData.BaseOffset(data, info, false)
    end
    return MoveData.ConvertDataToIGU(data)
end


-- Table containing all the high-level functions used to move stuff around
MoveModule = {}

-- Simply get the final position for a 'ship' if it did a 'move' (standard move code)
-- Format:  out.pos for position, out.rot for rotation
-- Position and rotation are ready to feed TTS functions
MoveModule.getFinalPos = function(ship, move)
    local finalPos = MoveData.Decode(move)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- END MAIN MOVEMENT MODULE
--------

-- Sample update to test functionalities
function update()
    for k,obj in pairs(getAllObjects()) do
        if obj.tag == 'Figurine' and obj.getDescription() ~= '' then
            local finalPos = MoveModule.getFinalPos(obj, obj.getDescription())
            obj.setPosition(finalPos.pos)
            obj.setRotation(finalPos.rot)
            obj.setDescription('')
        end
    end
end