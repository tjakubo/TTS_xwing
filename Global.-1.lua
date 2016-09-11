-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of: Flolania, Hera Vertigo
-- ~~~~~~

-- TESTING: If final position of moved token doesnt make its owner ship it moved with,
--  move it on its base

-- TO_DO: dont lock ship after completeing if it;s not level
-- TO_DO: Dials:o n drop among dials, return to origin (maybe)
-- TO_DO onload (dials done, anything else?)

-- TESTING: Small ship getting tokens has trouble checking who would be closest to the token
-- kinda done (see 1st todo), to be tested

-- TO_DO: Intercept deleted dial
-- TO_DO: weirdness when playing with saving/deletin dials multiple times (testing?)


-- Should the code execute print functions or skip them?
-- This should be set to false on every release
print_debug = false

TTS_print = print
function print(arg)
    if print_debug == true then
        TTS_print(arg)
    end
end

-- Patch for clearing buttons since TTS broke obj.clearButtons()
function ClearButtonsPatch(obj)
    local buttons = obj.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do
            obj.removeButton(but.index)
        end
    end
end


--------
-- MEASUREMENT RELATED FUNCTIONS

-- 40mm = 1.445igu
-- (s1 length / small base size)

-- 1mm = 0.036125igu
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

-- Distance between two positions
function Dist_Pos(pos1, pos2)
    return math.sqrt( math.pow(pos1[1]-pos2[1], 2) + math.pow(pos1[3]-pos2[3], 2) )
end

-- Distance between two objects
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

-- Inverse each element of a vector
function Vect_Inverse(vector)
    local out = {}
    local k = 1
    while vector[k] ~= nil do
        out[k] = -1*vector[k]
        k = k+1
    end
    return out
end

-- Multiply each element of a vector by a factor
function Vect_Scale(vector, factor)
    local out = {}
    local k = 1
    while vector[k] ~= nil do
        out[k] = vector[k]*factor
        k = k+1
    end
    return out
end

-- Length (euclidean norm) of a vector
function Vect_Length(vector)
    return math.sqrt(vector[1]*vector[1] + vector[3]*vector[3])
end

-- Offset self vector by first and third element of vec2 (second el ignored)
-- Useful for TTS positioning offsets
function Vect_Offset(self, vec2)
    return {self[1]+vec2[1], self[2], self[3]+vec2[3]}
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

-- Check if object matches some of predefined X-Wing types
-- TO_DO: Change lock script to use more unique variable than 'set'
function XW_ObjMatchType(obj, type)
    if type == 'any' then
        return true
    elseif type == 'ship' then
        if obj.tag == 'Figurine' then return true end
    elseif type == 'token' then
        if (obj.tag == 'Chip' or obj.getVar('set') ~= nil) and obj.getName() ~= 'Shield' then return true end
    elseif type == 'lock' then
        if obj.getVar('set') ~= nil then return true end
    elseif type == 'dial' then
        if obj.tag == 'Card' and obj.getDescription() ~= '' then return true end
    end
    return false
end

-- Get objects within distance of some position + optional X-Wing type filter
function XW_ClosestToPosWithinDist(centralPos, maxDist, type)
    local closest = nil
    local minDist = maxDist+1
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, type) == true then
            local dist = Dist_Pos(centralPos, obj.getPosition())
            if dist < maxDist and dist < minDist then
                minDist = dist
                closest = obj
            end
        end
    end
    return {obj=closest, dist=minDist}
end

-- Get an object closest to some position + optional X-Wing type filter
function XW_ClosestWithinDist(centralObj, maxDist, type)
    local closest = nil
    local minDist = maxDist+1
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, type) == true and obj ~= centralObj then
            local dist = Dist_Pos(centralObj.getPosition(), obj.getPosition())
            if dist < maxDist and dist < minDist then
                minDist = dist
                closest = obj
            end
        end
    end
    return {obj=closest, dist=minDist}
end

-- Get objects within distance of some other object + optional X-Wing type filter
function XW_ObjWithinDist(position, maxDist, type)
    local ships = {}
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, type) == true then
            if Dist_Pos(position, obj.getPosition()) < maxDist then
                table.insert(ships, obj)
            end
        end
    end
    return ships
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

-- Dud function for info buttons and not yet written sections where Lua complains about no code
function dummy() return end

-- END MISC FUNCTIONS
--------

--------
-- COMMAND HANDLING MODULE
-- Sanitizes input (more like throws away anything not explicitly allowed)
-- Allows other modules to add available commands and passes their execution where they belong

XW_cmd = {}

-- Table of valid commands: their patterns and general types
XW_cmd.ValidCommands = {}
XW_cmd.AddCommand = function(cmdRegex, type)
    -- When adding avaialble commands, assert beggining and end of string automatically
    if cmdRegex:sub(1,1) ~= '^' then cmdRegex = '^' .. cmdRegex end
    if cmdRegex:sub(-1,-1) ~= '$' then cmdRegex = cmdRegex .. '$' end
    table.insert(XW_cmd.ValidCommands, {cmdRegex, type})
end

-- Process provided command on a provided object
XW_cmd.Process = function(obj, cmd)
    -- Trim whitespaces
    cmd = cmd:match( "^%s*(.-)%s*$" )
    local type = nil
    -- Resolve command type
    for k,pat in pairs(XW_cmd.ValidCommands) do
        if cmd:match(pat[1]) ~= nil then
            type = pat[2]
            break
        end
    end
    if type == nil then return end
    -- If it matched something, do it
    if type == 'move' then
        MoveModule.PerformMove(cmd, obj)
    elseif type == 'actionMove' then
        MoveModule.PerformMove(cmd, obj, true)
    elseif type == 'historyHandle' then
        if cmd == 'q' or cmd == 'undo' then
            MoveModule.UndoMove(obj)
        elseif cmd == 'z' or cmd == 'redo' then
            MoveModule.RedoMove(obj)
        elseif cmd == 'keep' then
            MoveModule.SaveStateToHistory(obj, false)
        end
    elseif type == 'dialHandle' then
        if cmd == 'sd' then
            DialModule.SaveNearby(obj)
        elseif cmd == 'rd' then
            DialModule.RemoveSet(obj)
        end
    elseif type == 'action' then
        if cmd == 'r' then cmd = 'ruler' end
        DialModule.PerformAction(obj, cmd)
    end
    obj.setDescription('')
end

--------
-- MOVEMENT DATA MODULE
-- Defines moves, parts of moves, their variants and decoding of move codes into actual move data
-- This is not aware of any ship positions (ship objects yes for their size) and doesn't move anything
-- Used for feeding data about a move to a higher level movement module

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
MoveData.straight.length = {str_mm[1], str_mm[2], str_mm[3], str_mm[4], str_mm[5]}
XW_cmd.AddCommand('[sk][12345]', 'move')

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
XW_cmd.AddCommand('b[rle][123][s]?', 'move')

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
XW_cmd.AddCommand('t[rle][123]', 'move')
XW_cmd.AddCommand('t[rle][123][st]', 'move')

-- Barrel roll RIGHT (member function to modify to left)
-- Large ships are hard to handle exceptions so their rolls are defined separately as 5 speeds higher
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
XW_cmd.AddCommand('x[rle]', 'actionMove')
XW_cmd.AddCommand('x[rle][fb]', 'actionMove')
XW_cmd.AddCommand('c[srle]', 'actionMove')
XW_cmd.AddCommand('c[rle][fb]', 'actionMove')


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

-- Decode a move command into table with type, direction, speed etc info
MoveData.DecodeInfo = function (move_code, ship)
    local info = {type='invalid', speed=nil, dir=nil, extra=nil, size=nil, note=nil, collNote=nil, code=move_code}

    if DB_isLargeBase(ship) == true then info.size = 'large'
    else info.size = 'small' end

    -- Straights, regular stuff
    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info.type = 'straight'
        info.speed = tonumber(move_code:sub(2,2))
        if move_code:sub(1,1) == 'k' then
            info.extra = 'koiogran'
            info.note = 'koiogran turned ' .. info.speed
            info.collNote = 'tried to koiogran turn ' .. info.speed
        else
            info.note = 'flew straight ' .. info.speed
            info.collNote = 'tried to fly straight ' .. info.speed
        end
        if info.speed > 5 then info.type = 'invalid' end
        -- Banks, regular stuff
    elseif move_code:sub(1,1) == 'b' then
        info.type = 'bank'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 's' then
            info.extra = 'segnor'
            info.note = 'segnor looped ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to segnor loop ' .. info.dir .. ' ' .. info.speed
        else
            info.note = 'banked ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to bank ' .. info.dir .. ' ' .. info.speed
        end
        if info.speed > 3 then info.type = 'invalid' end
        -- Turns, regular stuff
    elseif move_code:sub(1,1) == 't' then
        info.type = 'turn'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        if move_code:sub(-1,-1) == 't' then
            info.extra = 'talon'
            info.note = 'talon rolled ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to talon roll ' .. info.dir .. ' ' .. info.speed
        elseif move_code:sub(-1,-1) == 's' then
            info.extra = 'segnor'
            info.note = 'segnor looped (turn template) ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to segnor loop (turn template) ' .. info.dir .. ' ' .. info.speed
        else
            info.note = 'turned ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to turn ' .. info.dir .. ' ' .. info.speed
        end
        if info.speed > 3 then info.type = 'invalid' end
        -- Barrel rolls, spaghetti
    elseif move_code:sub(1,1) == 'x' or move_code:sub(1,1) == 'c' then
        info.type = 'roll'
        info.dir = 'right'
        info.speed = 1
        if info.size == 'large' then info.speed = info.speed+5 end
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        info.note = 'barrel rolled'
        -- (fucking decloak) is treated as a roll before, now just return straight 2 data
        if move_code:sub(2,2) == 's' then
            info.speed = 2
            info.extra = 'straight'
            info.note = 'decloaked forward'
            if info.size == 'large' then return MoveData.DecodeInfo('s2', ship) end
        elseif move_code:sub(1,1) == 'c' then
            info.note = 'decloaked'
            info.speed = 2
            if info.size == 'large' then return MoveData.DecodeInfo(move_code:gsub('c', 'x'), ship) end
        end

        if move_code:sub(-1,-1) == 'f' then
            info.extra = 'forward'
            info.note = info.note .. ' forward ' .. info.dir
        elseif move_code:sub(-1,-1) == 'b' then
            info.extra = 'backward'
            info.note = info.note .. ' backward ' .. info.dir
        else
            info.note = info.note .. ' ' .. info.dir
        end

        -- Assert trying to roll at weird speeds (speeds determine which entry will be taken)
        -- Cannot be done in a sane way like other stuff since this "speed" is not in the move code
        if  (info.size == 'small' and info.speed > 2) or (info.size == 'large' and info.speed ~= 6) then info.type = 'invalid' end

    end
    return info
end

-- Decode a "move" from the standard X-Wing notation into a valid movement data
-- Provide a 'ship' object reference to determine if it is large based
-- Returns a valid path the ship has to traverse to perform a move (if it was at origin)
-- Standard format {xOffset, yOffset, zOffset, rotOffset}
MoveData.DecodeFull = function(move_code, ship)
    local data = {}
    -- get the info about the move
    local info = MoveData.DecodeInfo(move_code, ship)
    if info.type == 'invalid' then
        dummy()
        --TO_DO: exception handling?
        -- This should really never happen since command regex should prevent
        --  borked commands from getting through
        return {0, 0, 0, 0}
    end
    -- copy relevant offest
    data = Lua_ShallowCopy(MoveData[info.type][info.speed])
    -- apply modifiers
    if info.dir == 'left' then data = MoveData.LeftVariant(data) end
    if info.extra == 'koiogran' or info.extra == 'segnor' then
        data = MoveData.TurnAroundVariant(data)
    elseif info.extra == 'talon' then
        data = MoveData.TurnInwardVariant(data)
    end

    -- handle rolls and decloak
    if info.type == 'roll' then
        -- treat decloak straight as a straight move
        if info.extra == 'straight' then return MoveData.DecodeFull('s' .. info.speed, ship) end

        -- aply yank foward/backward for rolls
        if info.extra == 'forward' then
            data = Vect_Sum(data, MoveData.roll[info.size .. 'BaseWiggle'].max)
        elseif info.extra == 'backward' then
            data = Vect_Sum(data, MoveData.roll[info.size .. 'BaseWiggle'].min)
        end
    end

    -- apply ship base offset
    data = MoveData.BaseOffset(data, info)

    return MoveData.ConvertDataToIGU(data)
end

-- Max part value for partial moves
-- Part equal to this is a full move
-- Value is largely irrelevant since part can be a fraction (any kind of number really)
PartMax = 1000

-- Get an offset of a ship if it would do A PART of the move
MoveData.DecodePartial = function(move_code, ship, part)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)

    -- handle part out of (0, PartMax) bounds
    if part >= PartMax then return MoveData.DecodeFull(move_code, ship)
    elseif part < 0 then return {0, 0, 0, 0} end
    if info.type == 'invalid' then
        dummy()
        --TO_DO: exception handling?
        -- This should really never happen since command regex should prevent
        --  borked commands from getting through
        return {0, 0, 0, 0}
    end

    -- PARTIAL STRAIGHT
    -- Simply get a proportional part of a full straight move (oof)
    if info.type == 'straight' then
        data = MoveData.DecodeFull(move_code, ship)
        if part < PartMax then data[4] = 0 end
        data[3] = data[3]*(part/PartMax)

        -- PARTIAL BANK/TURN
        -- angle changes linearly throughout whole move
        -- move IS separated in 3 sections:
        -- - before center of the ship moves onto the template
        -- - when ship center moves over the template
        -- - when ship moves off the template and slides it between guides again
    elseif info.type == 'bank' or info.type == 'turn' then

        -- calculate length of the base offsets and real move
        local initOffLen = Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        local moveLen = MoveData[info.type].length[info.speed]
        local finalOffLen = Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
        local totalLen = initOffLen + moveLen + finalOffLen

        -- check where (at which part value) transitions initOffset-move and move-finalOffset happen
        local initPartCutoff = (initOffLen/totalLen)*PartMax
        local movePartCutoff = ((initOffLen+moveLen)/totalLen)*PartMax

        -- if part is in the initial base offset region
        if part <= initPartCutoff then
            -- proportiaonal angle change
            -- proportional part of the init offset since it is straight
            local offset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetInit'])[3]*(part/initPartCutoff)
            local angle = MoveData[info.type][info.speed][4]*(part/PartMax)
            data = {0, 0, offset, angle}
            if info.dir == 'left' then data=MoveData.LeftVariant(data) end
        elseif part > movePartCutoff then
            -- similiar idea as above
            -- get the final position and slide the ship BACK
            --  a proportional part of the final offset (since it is a straight)
            data = MoveData.DecodeFull(move_code, ship)
            data[4] = MoveData[info.type][info.speed][4]*(part/PartMax)
            if info.dir == 'left' then data[4] = -1*data[4] end

            -- scale the part value so it's 0 for full move and PartMax for move just before final offset
            part = (part-PartMax)*(-1/(PartMax-movePartCutoff))

            local xInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[1]*part
            local zInset = MoveData.ConvertDataToIGU(MoveData[info.type][info.size .. 'BaseOffsetFinal'])[3]*part
            if info.dir == 'left' then xInset = xInset * -1 end
            data[1] = data[1] - xInset
            data[3] = data[3] - zInset
        else
            -- simply slide the ship over a part of a circle
            local angle = MoveData[info.type][info.speed][4]*(part/PartMax)
            if info.dir == 'left' then angle = -1*angle end
            data = Lua_ShallowCopy(MoveData[info.type][info.size .. 'BaseOffsetInit'])
            -- scale part so it's 0 at the start of the template and PartMax at its end
            part = (part-(initPartCutoff))*(PartMax/(movePartCutoff-initPartCutoff))
            -- argument at the end of a move is 1/4 of a circle for turn and 1/8 for a bank
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

        -- PARTIAL ROLL/DECLOAK
        -- kinda special since it;s not partial "sideways" but partial as in fwd/backwd wiggle room
    elseif info.type == 'roll' then

        if info.extra == 'straight' then return MoveData.DecodePartial('s' .. info.speed, ship, part) end

        -- scale the part so it's PartMax at max forward and -1*PartMax at max backward
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


--------
-- MAIN MOVEMENT MODULE
-- Lets us move ships around and handles what comes with moving

MoveModule = {}

-- Simply get the final position for a 'ship' if it did a move (standard move code)
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetFinalPos = function(move, ship)
    local finalPos = MoveData.DecodeFull(move, ship)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- Simply get the final position for a 'ship' if it did a part of a move (standard move code)
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetPartialPos = function(move, ship, part)
    local finalPos = MoveData.DecodePartial(move, ship, part)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end


-- HISTORY HANDLING:
-- Lets us undo, redo and save positions a ship was seen at

MoveModule.moveHistory = {}
XW_cmd.AddCommand('[qz]', 'historyHandle')
XW_cmd.AddCommand('undo', 'historyHandle')
XW_cmd.AddCommand('redo', 'historyHandle')
XW_cmd.AddCommand('keep', 'historyHandle')

-- Return history of a ship
-- History table: {ship=shipRef, actKey=keyOfHistoryEntryShipWasLastSeenAt (._.), history=entryList}
-- Entry list: {entry1, entry2, entry3, ...}
-- Entry: {pos=position, rot=rotation, move=moveThatGotShipHere}
MoveModule.GetHistory = function(ship)
    for k,hist in pairs(MoveModule.moveHistory) do
        if hist.ship == ship then
            return hist
        end
    end
    table.insert(MoveModule.moveHistory, {ship=ship, actKey=0, history={}})
    return MoveModule.GetHistory(ship)
end

-- Erase all history "forward" from the current state
-- Happens when you undo and then do a move - all positions you undid are lost
MoveModule.ErasePastCurrent = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local k=1
    while histData.history[histData.actKey + k] ~= nil do
        histData.history[histData.actKey + k] = nil
    end
end

-- Print history, just for debug
MoveModule.PrintHistory = function(ship)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey == 0 then
        print(ship.getName() .. ': NO HISTORY')
    else
        print(ship.getName() .. '\'s HISTORY:')
        local k=1
        while histData.history[k] ~= nil do
            local entry = histData.history[k]
            if k == histData.actKey then
                print(' >> ' .. entry.move)
            else
                print(' -- ' .. entry.move)
            end
            k = k+1
        end
        print(' -- -- -- -- ')
    end
end

-- How much position can be offset to be considered 'same'
undoPosCutoff = Convert_mm_igu(1)
-- How much rotation can be offset to be considered 'same'
undoRotCutoffDeg = 1

-- Save <some> ship position to the history
-- Can be quiet when not explicitly called by the user
MoveModule.AddHistoryEntry = function(ship, entry, andBeQuiet)
    local histData = MoveModule.GetHistory(ship)
    -- Don't add an entry if it's current position/rotation
    if histData.actKey > 0 then
        local currEntry = histData.history[histData.actKey]
        if Dist_Pos(ship.getPosition(), currEntry.pos) < undoPosCutoff
        and math.abs(ship.getRotation()[2] - currEntry.rot[2]) < undoRotCutoffDeg then
            if andBeQuiet ~= true then MoveModule.Announce(ship, {type='historyHandle', note='already has current position saved'}, 'all') end
            return
        end
    end
    histData.history[histData.actKey+1] = entry
    histData.actKey = histData.actKey+1
    MoveModule.ErasePastCurrent(ship)
    if andBeQuiet ~= true then MoveModule.Announce(ship, {type='historyHandle', note='stored current position'}, 'all') end
end

-- Save curent ship position to the history
-- Can be quiet when not explicitly called by the user
MoveModule.SaveStateToHistory = function(ship, beQuiet)
    local entry = {pos=ship.getPosition(), rot=ship.getRotation(), move='position save'}
    MoveModule.AddHistoryEntry(ship, entry, beQuiet)
end

-- Move a ship to a previous state from the history
MoveModule.UndoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
    -- No history
    if histData.actKey == 0 then
        announceInfo.note = 'has no more moves to undo'
        return
    else
    -- There is history
        local currEntry = histData.history[histData.actKey]
        local rotDiff = math.abs(ship.getRotation()[2] - currEntry.rot[2])
        if rotDiff > 180 then rotDiff = 360 - rotDiff end
        if Dist_Pos(ship.getPosition(), currEntry.pos) > undoPosCutoff
        or rotDiff > undoRotCutoffDeg then
        -- Current posiion/rotation not matching last entry
            -- Queue tokens for movement, but disable position saving
            MoveModule.QueueShipTokensMove(ship, 'none')
            ship.setPosition(currEntry.pos)
            ship.setRotation(currEntry.rot)
            ship.lock()
            announceInfo.note = 'moved to the last saved position'
        else
        -- Current posiion/rotation is matching last entry
            if histData.actKey > 1 then
                -- Move to previuso saved position
                local undidMove = currEntry.move
                histData.actKey = histData.actKey - 1
                currEntry = histData.history[histData.actKey]
                -- Queue tokens for movement, but disable position saving
                MoveModule.QueueShipTokensMove(ship, 'none')
                ship.setPosition(currEntry.pos)
                ship.setRotation(currEntry.rot)
                ship.lock()
                announceInfo.note = 'performed an undo of (' .. undidMove .. ')'
            else
                -- There is no data to go back to
                announceInfo.note = 'has no more moves to undo'
            end
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
end

-- Move a ship to next state from the history
MoveModule.RedoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
    -- No history
    if histData.actKey == 0 then
        announceInfo.note = 'has no more moves to redo'
        return
    else
    -- There is history
        if histData.history[histData.actKey+1] == nil then
            -- No more moves forward
            announceInfo.note = 'has no more moves to redo'
        else
            -- Move forward
            histData.actKey = histData.actKey+1
            local currEntry = histData.history[histData.actKey]
            -- Queue tokens for movement, but disable position saving
            MoveModule.QueueShipTokensMove(ship, 'none')
            ship.setPosition(currEntry.pos)
            ship.setRotation(currEntry.rot)
            ship.lock()
            announceInfo.note = 'performed an redo of (' .. currEntry.move .. ')'
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
end



-- This tidbit lets us wait till ships lands WITHOUT checking for this condition
--  on everything all the time

-- Queue containing stuff to watch

-- Ships waiting to be level (resting)
-- entry: {ship=shipRef, lastMove=lastMoveCode}
-- if last move code is nil, do not save to history
-- elements pop from here as coroutines start
MoveModule.restWaitQueue = {}

-- Tokens waiting to be moved with ships
-- entry: {token=tokenRef, ship=shipWaitingFor}
-- elements wait here until ships are ready
MoveModule.tokenWaitQueue = {}

-- This completes when a ship is resting at a table level
-- Ships token moving, saving positons for undo, locking model
-- also yanks it down if TTS decides it should just hang out resting midair
-- TESTING: Final token position (that is not determined beforehand) can be on other ship for example
--  move these tokens on the base instead, would be useful to have nice token-handling functions for it
function restWaitCoroutine()
    if MoveModule.restWaitQueue[1] == nil then
        dummy()
        print('coroutine table empty') --TO_DO: Exception handling?
        -- Should now happen since I try to keep 1 entry added = 1 coroutine started ratio
        --  but who knows, it's kinda harmless anyways
        return 0
    end

    local waitData = MoveModule.restWaitQueue[#MoveModule.restWaitQueue]
    local actShip = waitData.ship
    local yank = false
    table.remove(MoveModule.restWaitQueue, #MoveModule.restWaitQueue)
    repeat
        if actShip.getPosition()[2] > 1.5 and actShip.resting == true then
            actShip.setPositionSmooth({actShip.getPosition()['x'], actShip.getPosition()['y']-0.1, actShip.getPosition()['z']})
        end
        coroutine.yield(0)
    -- YIELD until ship is resting, not held and close to the table
    until actShip.resting == true and actShip.held_by_color == nil and actShip.getPosition()[2] < 1.5
    local newTokenTable = {}
    for k,tokenInfo in pairs(MoveModule.tokenWaitQueue) do
        -- Move and pop waiting tokens
        if tokenInfo.ship == actShip then
            local offset = Vect_RotateDeg(tokenInfo.offset, actShip.getRotation()[2])
            local dest = Vect_Sum(offset, actShip.getPosition())
            local destData = MoveModule.GetTokenOwner(dest)
            if destData.owner ~= actShip or destData.margin < Convert_mm_igu(20) then
                local destLen
                if DB_isLargeBase(actShip) == true then
                    destLen = Convert_mm_igu(mm_largeBase/4)
                else
                    destLen = Convert_mm_igu(mm_smallBase/4)
                end
                offset = Vect_Scale(offset, (destLen/Vect_Length(offset)))
                dest = Vect_Sum(offset, actShip.getPosition())
            end
            dest[2] = dest[2] + 1.5
            tokenInfo.token.setPositionSmooth(dest)
        else
        -- Index back tokens that are not waiting for this ship
            table.insert(newTokenTable, tokenInfo)
        end

    end
    MoveModule.tokenWaitQueue = newTokenTable
    actShip.lock()
    -- Save this position if last move code was provided
    if waitData.lastMove ~= nil then MoveModule.AddHistoryEntry(actShip, {pos=actShip.getPosition(), rot=actShip.getRotation(), move=waitData.lastMove}, true) end
    return 1
end

-- Check if provided ship in a provided position/rotation would collide with anything from the provided table
MoveModule.CheckCollisions = function(ship, shipPosRot, colShipTable)
    local info = {coll=nil, minMargin=0, numCheck=0}
    local shipInfo = {pos=shipPosRot.pos, rot=shipPosRot.rot, ship=ship}
    local certShipReach = nil -- distance at which other ships MUST bump it
    local maxShipReach = nil  -- distance at which other ships CAN bump it
    if DB_isLargeBase(ship) == true then
        certShipReach = Convert_mm_igu(mm_largeBase/2)
        maxShipReach = Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
    else
        certShipReach = Convert_mm_igu(mm_smallBase/2)
        maxShipReach = Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
    end

    for k, collShip in pairs(colShipTable) do
        local certBumpDist = nil -- distance at which these two particular ships ships MUST bump
        local maxBumpDist = nil  -- distance at which these two particular ships ships CAN bump
        if DB_isLargeBase(collShip) == true then
            certBumpDist = certShipReach + Convert_mm_igu(mm_largeBase/2)
            maxBumpDist = maxShipReach + Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
        else
            certBumpDist = certShipReach + Convert_mm_igu(mm_smallBase/2)
            maxBumpDist = maxShipReach + Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
        end
        local dist = Dist_Pos(shipPosRot.pos, collShip.getPosition())
        if dist < maxBumpDist then
            if dist < certBumpDist then
                info.coll = collShip
                if certBumpDist - dist > info.minMargin then
                    info.minMargin = certBumpDist - dist
                end
            elseif collide(shipInfo, {pos=collShip.getPosition(), rot=collShip.getRotation(), ship=collShip}) == true then
                info.coll = collShip
                info.numCheck = info.numCheck + 1
                break
            end
            if info.coll ~= nil then
            end
        end
    end
    return info
end

-- Perform move designated by move_code on a ship
-- For some moves (like barrel rolls) collisons are automatically ignored, rest considers them normally
-- Includes token handling so nothing obscurs the final position
-- Starts the wait coroutine that handles stuff done when ship settles down
MoveModule.PerformMove = function(move_code, ship, ignoreCollisions)

    local finPos = nil
    local info = MoveData.DecodeInfo(move_code, ship)

    if ignoreCollisions ~= true then
        -- LET THE SPAGHETTI FLOW!
        -- Check move length so we can relate how far some part of a move will take us
        local moveLength = MoveData[info.type].length[info.speed]
        moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
        moveLength = Convert_mm_igu(moveLength)

        -- Check how close ships have to be so bump is unavoidable and how far so bump is possible at all
        local isShipLargeBase = DB_isLargeBase(ship)
        local certShipReach = nil
        local maxShipReach = nil
        if isShipLargeBase == true then
            certShipReach = Convert_mm_igu(mm_largeBase/2)
            maxShipReach = Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
        else
            certShipReach = Convert_mm_igu(mm_smallBase/2)
            maxShipReach = Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
        end

        -- Get list of ships that can possibly collide (all in *some* distance from middle of move)
        local ships = XW_ObjWithinDist(MoveModule.GetPartialPos(move_code, ship, PartMax/2).pos, moveLength+(2*maxShipReach), 'ship')
        for k, collShip in pairs(ships) do if collShip == ship then table.remove(ships, k) end end

        -- Let's try collisions at the end of a move
        local finalInfo = MoveModule.CheckCollisions(ship, MoveModule.GetFinalPos(move_code, ship), ships)

        -- (if there will be collisions) we will start with maximum part of a move (ending position)
        local actPart = PartMax
        if finalInfo.coll ~= nil then
            -- There was a collision!
            local checkNum = 0 -- this is just to see how efficient stuff is
            local collision = false

            -- First, we will check collisions every 1/100th of a move
            -- BUT WITH A CATCH
            local partDelta = -1*(PartMax/100)
            repeat
                local nPos = MoveModule.GetPartialPos(move_code, ship, actPart)
                local collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                local distToSkip = nil
                if collInfo.coll ~= nil then
                    collision = true
                    distToSkip = collInfo.minMargin
                    -- If there is a distance we can travel that assures collison will not end
                    if distToSkip > 0 then
                        -- Calculate how big part it is and skip away!
                        -- This saves A LOT of iterations, for real
                        partDelta = -1*((distToSkip * PartMax)/moveLength)
                        if partDelta > -10 then partDelta = -10 end
                        -- Else we're back at 1/100th of a move back
                    else partDelta = -10 end
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
                if collision == true then info.collidedShip = collInfo.coll end
            until collision == false or actPart < 0

            -- Right now, we're out of any collisions or at part 0 (no move)
            -- Go 1/1000th of a move forward until we have a collision, then skip to last free 1/1000th
            partDelta = (1/1000)*PartMax
            local collInfo
            repeat
                local nPos = MoveModule.GetPartialPos(move_code, ship, actPart)
                collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                if collInfo.coll ~= nil then collision = true
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
            until (collision == true and collInfo.coll == info.collidedShip) or actPart > PartMax
            actPart = actPart - partDelta
            info.collidedShip = collInfo.coll -- This is what we hit
        end

        -- We get the final position as a calculated part or as a full move if ignoring collisions
        finPos = MoveModule.GetPartialPos(move_code, ship, actPart)
    else
        finPos = MoveModule.GetFinalPos(move_code, ship)
    end
    -- Movement part finished!

    -- TOKEN HANDLING:
    -- How far ships reach (circle) for nearby tokens distance considerations and checking for obstructions
    -- This is because token next to a large ship is MUCH FARTHER from it than token near a small ship
    local isShipLargeBase = DB_isLargeBase(ship)
    local maxShipReach = nil
    if isShipLargeBase == true then
        maxShipReach = Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
    else
        maxShipReach = Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
    end

    -- This part was recently collapsed into a function
    -- TO_DO: Actually wrap this stuff around in functions nicely, like
    --  getTokenOwner
    --  getShipTokens
    -- and stuff since token movement is kinda hacky now
    -- PARTIALLY DONE
    MoveModule.QueueShipTokensMove(ship)

    -- Check which tokens could obstruct final position
    -- TO_DO: Collapse this into a function maybe?
    --  can wait until there would be a use for this outside here
    local obstrTokens = XW_ObjWithinDist(finPos.pos, maxShipReach+Convert_mm_igu(20), 'token')
    for k, token in pairs(obstrTokens) do
        local owner = XW_ClosestWithinDist(token, Convert_mm_igu(80), 'ship').obj
        -- If there is someone else close to one of these, move it on his base
        if owner ~= nil and owner ~= ship then
            local dir = Vect_Sum(owner.getPosition(), Vect_Scale(token.getPosition(), -1))
            local dist = Vect_Length(dir)
            local intendedDist = nil
            if DB_isLargeBase(owner) then
                intendedDist = Convert_mm_igu(mm_largeBase/4)
            else
                intendedDist = Convert_mm_igu(mm_smallBase/4)
            end
            dir = Vect_Scale(dir, (dist-intendedDist)/dist)
            local dest = Vect_Sum(token.getPosition(), dir)
            dest[2] = 2
            token.setPositionSmooth(dest)
        -- If tokens appears to be stray, just yank it out of the way
        else
            local dir = Vect_Sum(token.getPosition(), Vect_Scale(finPos.pos, -1))
            local dist = Vect_Length(dir)
            dir = Vect_Scale(dir, ((maxShipReach+Convert_mm_igu(20))/dist))
            local dest = Vect_Sum(finPos.pos, dir)
            dest[2] = 2
            token.setPositionSmooth(dest)
        end
    end

    -- Lift it a bit, save current and move
    finPos.pos[2] = finPos.pos[2] + 1
    MoveModule.SaveStateToHistory(ship, true)
    ship.setPosition(finPos.pos)
    ship.setRotation(finPos.rot)
    ship.setDescription('')
    -- Notification
    info.type = 'move'
    MoveModule.Announce(ship, info, 'all')
    -- Get the ship in a queue to do stuff once resting
    table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove=move_code})
    startLuaCoroutine(Global, 'restWaitCoroutine')
end

-- Check which ship has it's base closest to position (large ships have large bases!), thats the owner
--  also check how far it is to the owner-changing position (out margin of safety)
-- Kinda tested: margin > 20mm = visually safe
MoveModule.GetTokenOwner = function(tokenPos)
    local out = {owner=nil, dist=0, margin=-1}
    local nearShips = XW_ObjWithinDist(tokenPos, Convert_mm_igu(120), 'ship')
    if nearShips[1] == nil then return out end
    local baseDist = {}
    for k,ship in pairs(nearShips) do
        local realDist = Dist_Pos(tokenPos, ship.getPosition())
        if DB_isLargeBase(ship) == true then realDist = realDist-Convert_mm_igu(20) end
        table.insert(baseDist, {ship=ship, dist=realDist})
    end
    local nearest = baseDist[1]
    for k,data in pairs(baseDist) do
        if data.dist < nearest.dist then nearest = data end
    end
    local nextNearest = {dist=999}
    for k,data in pairs(baseDist) do
        if data.ship ~= nearest.ship and (data.dist < nextNearest.dist) then
            nextNearest = data
        end
    end
    return {owner=nearest.ship, dist=nearest.dist, margin=(nextNearest.dist-nearest.dist)/2}
end
-- Get tokens that should belong to this ship, cram them into token waiting for movement table
--  AND FIRE THE SHIP WAITING COROUTINE!
-- This should be only called immediately before changing position of a ship
MoveModule.QueueShipTokensMove = function(ship, queueShipMove)
    -- This is because token next to a large ship is MUCH FARTHER from it than token near a small ship
    local isShipLargeBase = DB_isLargeBase(ship)
    local maxShipReach = nil
    if isShipLargeBase == true then
        maxShipReach = Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
    else
        maxShipReach = Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
    end

    -- Check for nearby tokens
    local selfTokens = XW_ObjWithinDist(ship.getPosition(), maxShipReach+Convert_mm_igu(50), 'token')
    -- Exclude currently used cloak tokens
    local tokensExcl = {}
    for k, token in pairs(selfTokens) do
        if token.getName() == 'Cloak' then
            local active = true
            local buttons = token.getButtons()
            if buttons ~= nil then
                for k2, but in pairs(buttons) do
                    if but.label == 'Decloak' then active = false break end
                end
            end
            if active == false then table.insert(tokensExcl, token) end
        else
            table.insert(tokensExcl, token)
        end
    end
    selfTokens = tokensExcl
    -- Check which ones have our ship nearest, put them in a queue to be moved after ship rests
    for k, token in pairs(selfTokens) do
        local owner = XW_ClosestWithinDist(token, Convert_mm_igu(80), 'ship').obj
        if owner == ship then
            local infoTable = {}
            infoTable.token = token
            infoTable.ship = ship
            local offset = Vect_Sum(token.getPosition(), Vect_Scale(ship.getPosition(), -1))
            infoTable.offset = Vect_RotateDeg(offset, -1*ship.getRotation()[2])
            table.insert(MoveModule.tokenWaitQueue, infoTable)
        end
    end

    if queueShipMove ~= nil then
         table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove=queueShipMove})
         startLuaCoroutine(Global, 'restWaitCoroutine')
     elseif queueShipMove == 'none' then
          table.insert(MoveModule.restWaitQueue, {ship=ship})
          startLuaCoroutine(Global, 'restWaitCoroutine')
     end
end

-- COLOR CONFIGURATION FOR ANNOUNCEMENTS
MoveModule.AnnounceColor = {}
MoveModule.AnnounceColor.moveClear = {0.1, 1, 0.1}     -- Green
MoveModule.AnnounceColor.moveCollision = {1, 0.5, 0.1} -- Orange
MoveModule.AnnounceColor.action = {0.2, 0.2, 1}        -- Blue
MoveModule.AnnounceColor.historyHandle = {0.1, 1, 1}   -- Cyan
MoveModule.AnnounceColor.error = {1, 0.1, 0.1}         -- Red
MoveModule.AnnounceColor.info = {0.6, 0.1, 0.6}        -- Purple

-- Notify color or all players of some event
-- Info: {ship=shipRef, info=announceInfo, target=targetStr}
-- announceInfo: {type=typeOfEvent, note=notificationString}
MoveModule.Announce = function(ship, info, target)
    local annString = ''
    local annColor = {1, 1, 1}
    if info.type == 'move' then
        if info.collidedShip == nil then
            annString = ship.getName() .. ' ' .. info.note .. ' (' .. info.code .. ')'
            annColor = MoveModule.AnnounceColor.moveClear
        else
            annString = ship.getName() .. ' ' .. info.collNote .. ' (' .. info.code .. ') but is now touching ' .. info.collidedShip.getName()
            annColor = MoveModule.AnnounceColor.moveCollision
        end
    elseif info.type == 'historyHandle' then
        annString = ship.getName() .. ' ' .. info.note
        annColor = MoveModule.AnnounceColor.historyHandle
    elseif info.type == 'action' then
        annString = ship.getName() .. ' ' .. info.note
        annColor = MoveModule.AnnounceColor.action
    elseif info.type:find('error') ~= nil then
        annString = ship.getName() .. ' ' .. info.note
        annColor = MoveModule.AnnounceColor.error
    elseif info.type:find('info') ~= nil then
        annString = ship.getName() .. ' ' .. info.note
        annColor = MoveModule.AnnounceColor.info
    end

    if target == 'all' then
        printToAll(annString, annColor)
    else
        printToColor(target, annString, annColor)
    end
end
-- END MAIN MOVEMENT MODULE
--------

--------
-- AUTO DIALS MODULE
-- Manages sets of dials and performing automated actions (including ruler, locks etc)

-- This script must be on every dial that is assigned through this module
dialLuaScript = [[
function setShip(shipTable)
    assignedShip = shipTable[1]
end

function onPickedUp()
    if assignedShip ~= nil then Global.call('DialPickedUp', {dial=self, ship=assignedShip}) end
end

function onDropped()
    if assignedShip ~= nil then Global.call('DialDropped', {dial=self, ship=assignedShip}) end
end
]]

-- This is called evey time a dialling is picked up
-- Make this a new active dial or ignore if it already is
function DialPickedUp(dialTable)
    if dialTable.ship == nil then return end
    local actSet = DialModule.GetSet(dialTable.ship)
    if actSet.activeDial ~= nil then
        if actSet.activeDial.dial ~= dialTable.dial then
            DialModule.MakeNewActive(dialTable.ship, dialTable.dial)
        end
    else
        DialModule.MakeNewActive(dialTable.ship, dialTable.dial)
    end
end

-- This is called evey time a dialling is dropped
-- Spawn first buttos if this is an active dial or return if it's not
function DialDropped(dialTable)
    if dialTable.ship == nil then return end
    local actSet = DialModule.GetSet(dialTable.ship)
    if actSet.activeDial ~= nil and actSet.activeDial.dial == dialTable.dial then
        if dialTable.dial.getButtons() == nil then DialModule.SpawnFirstActiveButtons(dialTable) end
    else
        DialModule.RestoreDial(dialTable.dial)
    end
end

DialModule = {}

-- set: {ship=shipRef, activeDial=actDialInfo, dialSet=dialData}
-- dialData: {dial1Info, dial2Info, dial3Info ...}
-- dialInfo (and actDialInfo): {dial=dialRef, originPos=origin}
DialModule.ActiveSets = {}
XW_cmd.AddCommand('r', 'action')
XW_cmd.AddCommand('rd', 'dialHandle')
XW_cmd.AddCommand('sd', 'dialHandle')

-- Assign a set of dials to a ship
-- Fit for calling from outside, removes a set if it already exists for a ship
-- set_ship table: {set=dialTable, ship=shipRef}
-- dialTable: {dial1, dial2, dial3, ...}
function DialAPI_AssignSet(set_ship)
    local actSet = DialModule.GetSet(set_ship.ship)
    if actSet ~= nil then
        DialModule.RemoveSet(set_ship.ship)
    end
    local validSet = {}
    for k,dial in pairs(set_ship.set) do
        -- If there already is a dial of same description in those that are added now
        if validSet[dial.getDescription()] ~= nil then
            MoveModule.Announce(set_ship.ship, {type='error_DialModule', note='tried to assign few of same dials'}, 'all')
        else
        -- If dial description is (so far) unique
            validSet[dial.getDescription()] = {dial=dial, originPos=dial.getPosition()}
        end
        if dial.getVar('assignedShip') == nil then
            dial.call('setShip', {set_ship.ship})
        end
    end
    DialModule.AddSet(set_ship.ship, validSet)
end

-- Print active sets in play, just for debug
DialModule.PrintSets = function()
    for k, set in pairs(DialModule.ActiveSets) do
        print('SET: ' .. set.ship.getName())
        if set.activeDial ~= nil then
            print(' - actDial: ' .. set.activeDial.dial.getDescription())
        else
            print(' - actDial: nil')
        end
        local allDialsStr = ''
        for k, dialInfo in pairs(set.dialSet) do
            allDialsStr = allDialsStr .. ' ' .. k .. ':' .. dialInfo.dial.getDescription()
        end
        if allDialStr ~= '' then
            print(' - allDials: ' .. allDialsStr)
        else
            print(' - allDials: nil')
        end
    end
end

-- Remove a set from ship (whole set, all assigned)
-- If there is an active dial, restore it, flips all unassigned as an indicatior
DialModule.RemoveSet = function(ship)
    for k, set in pairs(DialModule.ActiveSets) do
        local hadDials = false
        if set.ship == ship then
            hadDials = true
            ship.setVar('DialModule_hasDials', false) -- Just informative
            if set.activeDial ~= nil then
                DialModule.RestoreActive(set.ship)
            end
            for k,dialData in pairs(set.dialSet) do
                dialData.dial.flip()
                dialData.dial.call('setShip', {nil})
                dialData.dial.setName('')
            end
            table.remove(DialModule.ActiveSets, k)
            MoveModule.Announce(ship, {type='info_DialModule', note='had all dials unassigned'}, 'all')
            break
        end
        if hadDials == false then MoveModule.Announce(ship, {type='info_DialModule', note='had no assigned dials'}, 'all') end
    end
end

-- Return a set belonging to a ship or nil if there is none
DialModule.GetSet = function(ship)
    for k, set in pairs(DialModule.ActiveSets) do
        if set.ship == ship then
            return set
        end
    end
    return nil
end

-- Add some dials to a ship set
-- This does not unassign existing dials in a set so needs to be called carefully
DialModule.AddSet = function(ship, set)
    local actSet = DialModule.GetSet(ship)
    if actSet ~= nil then
        for k, newDialData in pairs(set) do
            table.insert(actSet.dialSet, newDialData)
        end
    else
        table.insert(DialModule.ActiveSets, {ship=ship, activeDial=nil, dialSet=set})
        ship.setVar('DialModule_hasDials', true)
    end
end

-- Distance (circle from ship) at wchich dials can be to be registered
saveNearbyCircleDist = Convert_mm_igu(160)

-- Save nearby dials
-- If dials are already assigned to this ship, they are ignored
-- If one of dials is assigned to other ship, unassign and proceed
DialModule.SaveNearby = function(ship)
    local nearbyDialsAll = XW_ObjWithinDist(ship.getPosition(), saveNearbyCircleDist, 'dial')
    local nearbyDials = {}
    -- Nothing nearby
    if nearbyDialsAll[1] == nil then
        MoveModule.Announce(ship, {type='info_DialModule', note=('has no valid dials nearby')}, 'all')
        return
    end
    -- There is stuff nearby
    for k,dial in pairs(nearbyDialsAll) do
        -- If a dial is already assigned, unassign if it belongs to another ship
        -- Ingore if it's this ship
        if DialModule.isAssigned(dial) == true then
            if dial.getVar('assignedShip') ~= ship then
                local prevOwner = dial.getVar('assignedShip').getName()
                MoveModule.Announce(ship, {type='info_DialModule', note=('assigned a dial that previously was assigned to ' .. prevOwner)}, 'all')
                DialModule.UnassignDial(dial)
                table.insert(nearbyDials, dial)
            end
        else
            table.insert(nearbyDials, dial)
        end
    end
    -- If there are no filtered (not this ship already) dials
    if nearbyDials[1] == nil then
        MoveModule.Announce(ship, {type='info_DialModule', note=('already has all nearby dials assigned to him')}, 'all')
        return
    end
    local dialSet = {}
    local actSet = DialModule.GetSet(ship)
    -- Break if this ship already has a dial of same description as we're trying to save
    if actSet ~= nil then
        for k,dial in pairs(nearbyDials) do
            if actSet.dialSet[dial.getDescription()] ~= nil and actSet.dialSet[dial.getDescription()] ~= dial then
                MoveModule.Announce(ship, {type='error_DialModule', note='tried to assign a second dial of same move (' .. dial.getDescription() .. ')'}, 'all')
                return
            end
        end
    end
    -- Then we start adding
    local dialCount = 0
    for k, dial in pairs(nearbyDials) do
        local dialOK = nil
        -- Make sure the dial has correct script set up
        if dial.getLuaScript() ~= dialLuaScript then
            -- If not, clone it, apply script and delete the original
            local cloneDialPos = dial.getPosition()
            dial.setPosition({0, -1, 0})
            dialOK = dial.clone({position=cloneDialPos})
            dial.destruct()
            dialOK.setLuaScript(dialLuaScript)
            dialOK.setPosition(cloneDialPos)
        else
            dialOK = dial
        end
        -- Add to set, break if there are 2 dials of same description
        if dialSet[dialOK.getDescription()] == nil then
            dialSet[dialOK.getDescription()] = {dial=dialOK, originPos=dialOK.getPosition()}
        else
            MoveModule.Announce(ship, {type='error_DialModule', note='tried to assign few dials with same move (' .. dialOK.getDescription() .. ')'}, 'all')
            return
        end
        dialCount = dialCount + 1
    end
    -- If everything is OK, set each dial and pass the set to be added
    for k,dialInfo in pairs(dialSet) do
        dialInfo.dial.setName(ship.getName())
        dialInfo.dial.setVar('assignedShip', ship)
    end
    DialModule.AddSet(ship, dialSet)
    MoveModule.Announce(ship, {type='info_dialModule', note='had ' .. dialCount .. ' dials assigned (' .. DialModule.DialCount(ship) .. ' total now)' }, 'all')
end

-- Unassign this dial from any sets it is found in
-- Could check what ship set this is first, but it's more reliable this way
-- TO_DO table.remove is unsafe when iterating if we expect to remove more than one object
--  we're not really expecting it here, but it's supposed to be foolproof...
DialModule.UnassignDial = function(dial)
    for k,set in pairs(DialModule.ActiveSets) do
        for k2,dialInfo in pairs(set.dialSet) do
            if dialInfo.dial == dial then
                dialInfo.dial.setVar('assignedShip', nil)
                dialInfo.dial.clearButtons()
                ClearButtonsPatch(dialInfo.dial)
                table.remove(set.dialSet, k2)
            end
        end
        local empty = true
        for k2,dialInfo in pairs(set.dialSet) do empty = false break end
        if empty == true then DialModule.RemoveSet(set.ship) end
    end
    dial.setName('')
end

-- Count dials assigne to some ship
DialModule.DialCount = function(ship)
    local count = 0
    local actSet = DialModule.GetSet(ship)
    if actSet ~= nil then
        for k,dialInfo in pairs(actSet.dialSet) do count = count + 1 end
    end
    return count
end

-- Is this dial assigned to anyone?
DialModule.isAssigned = function(dial)
    if dial.getVar('assignedShip') ~= nil then return true
    else return false end
end

-- Handle destroyed objects that may be of DialModule interest
DialModule.ObjDestroyedHandle = function(obj)
    -- Remove dial set of destroyed ship
    if obj.tag == 'Figurine' then
        if DialModule.GetSet(obj) ~= nil then
            DialModule.RemoveSet(obj)
        end
    end
    -- Remove ruler with ship it is on and remove ruler from list if it is manually deleted
    for k,info in pairs(DialModule.SpawnedRulers) do
        if info.ship == obj or info.ruler == obj then
            info.ruler.destruct()
            table.remove(DialModule.SpawnedRulers, k)
        end
    end
end

-- Table with bags from which we can draw stuff
DialModule.TokenSources = {}

-- Update token sources on each load
-- Restore sets if data is loaded
DialModule.onLoad = function(saveTable)
    for k, obj in pairs(getAllObjects()) do
        if obj.tag == 'Infinite' then
            if obj.getName() == 'Focus' then DialModule.TokenSources['focus'] = obj
            elseif obj.getName() == 'Evade' then DialModule.TokenSources['evade'] = obj
            elseif obj.getName() == 'Stress' then DialModule.TokenSources['stress'] = obj
            elseif obj.getName() == 'Target Locks' then DialModule.TokenSources['targetLock'] = obj
            elseif obj.getName():find('Templates') ~= nil then
                if obj.getName():find('Straight') ~= nil then
                    DialModule.TokenSources['s' .. obj.getName():sub(1,1)] = obj
                elseif obj.getName():find('Turn') ~= nil then
                    DialModule.TokenSources['t' .. obj.getName():sub(1,1)] = obj
                elseif obj.getName():find('Bank') ~= nil then
                    DialModule.TokenSources['b' .. obj.getName():sub(1,1)] = obj
                end
            end

        end
    end
    -- Restore dial sets
    DialModule.RestoreSaveData(saveTable)
end

-- Restore active sets from provided table (already decoded)
-- Table should come from DialModule.GetSaveData
DialModule.RestoreSaveData = function(saveTable)
    if saveTable[1] == 'empty' then return end
    for k,set in pairs(DialModule.ActiveSets) do
        DialModule.RemoveSet(set.ship)
    end
    for k,set in pairs(saveTable) do
        if getObjectFromGUID(set.ship) == nil then
            dummy()
            -- TO_DO: I guess this means that it's lost an we continue?
        else
            DialModule.ActiveSets[k] = {ship=getObjectFromGUID(set.ship), dialSet={}}
            for k2,dialInfo in pairs(set.dialSet) do
                if getObjectFromGUID(dialInfo.dial) == nil then
                    dummy()
                    -- TO_DO: This is more severe than whole ship missing, but
                    -- can't think of anything else than to skip it
                else
                    DialModule.ActiveSets[k].dialSet[k2] = {dial=getObjectFromGUID(dialInfo.dial), originPos=dialInfo.originPos}
                    getObjectFromGUID(dialInfo.dial).call('setShip', {getObjectFromGUID(set.ship)})
                end
            end
            getObjectFromGUID(set.ship).setVar('DialModule_hasDials', false)
            if set.activeDialGUID ~= nil then
                local actDial = getObjectFromGUID(set.activeDialGUID)
                DialModule.RestoreDial(actDial)
            end
        end
    end

end

-- Dumbest TTS issue ever workaround
DialModule.PosSerialize = function(pos)
    return {pos[1], pos[2], pos[3]}
end

-- Retrieve all sets data with serialize-able guids instead of objects references
DialModule.GetSaveData = function()
    local saveTable = {}
    for k,set in pairs(DialModule.ActiveSets) do
        saveTable[k] = {ship=set.ship.getGUID(), dialSet={}}
        if set.activeDial ~= nil then saveTable[k].activeDialGUID = set.activeDial.dial.getGUID() end
        for k2,dialInfo in pairs(set.dialSet) do
            --table.insert(saveTable[k].dialSet, {dial=dialInfo.dial.getGUID(), originPos=dialInfo.originPos})
            saveTable[k].dialSet[k2] = {dial=dialInfo.dial.getGUID(), originPos=DialModule.PosSerialize(dialInfo.originPos)}
        end
    end
    if saveTable[1] == nil then return {'empty'}
    else return saveTable end
end

-- Return table to be saved
DialModule.onSave = function()
    return DialModule.GetSaveData()
end

-- Perform an automated action
-- Can be called externally for stuff like range ruler spawning
DialModule.PerformAction = function(ship, type, extra)
    local tokenActions = 'focus evade stress targetLock'
    announceInfo = {type='action'}
    -- Ruler spawning
    if type == 'ruler' then
        local rulerExisted = false
        for k,info in pairs(DialModule.SpawnedRulers) do
            if info.ship == ship then
                -- Ruler existed
                info.ruler.destruct()
                table.remove(DialModule.SpawnedRulers, k)
                rulerExisted = true
                return
            end
        end
        if rulerExisted == false then
            -- New ruler to be spawned
            local obj_parameters = {}
            obj_parameters.type = 'Custom_Model'
            obj_parameters.position = ship.getPosition()
            obj_parameters.rotation = { 0, ship.getRotation()[2], 0 }
            local newRuler = spawnObject(obj_parameters)
            local custom = {}
            if DB_isLargeBase(ship) == true then
                custom.mesh = 'https://paste.ee/r/AZlb4'
                custom.collider = 'https://paste.ee/r/BUHIZ'
                scale = {0.623, 0.623, 0.623}
            else
                custom.mesh = 'https://paste.ee/r/VVoNs'
                custom.collider = 'https://paste.ee/r/oCwKG'
                scale = {0.629, 0.629, 0.629}
            end
            newRuler.setCustomObject(custom)
            newRuler.lock()
            newRuler.setScale(scale)
            local button = {['click_function'] = 'Ruler_SelfDestruct', ['label'] = 'DEL', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 900, ['height'] = 900, ['font_size'] = 250}
            newRuler.createButton(button)
            table.insert(DialModule.SpawnedRulers, {ruler=newRuler, ship=ship})
            announceInfo.note = 'spawned a ruler'
        end
    elseif tokenActions:find(type) ~= nil then
        -- Token spawning!
        local baseSize
        -- Get the position next to the ship base
        if DB_isLargeBase(ship) == true then baseSize = Convert_mm_igu(mm_largeBase/2)
        else baseSize = Convert_mm_igu(mm_smallBase/2) end
        local dest = {baseSize+Convert_mm_igu(10), 1.5, 0}
        -- Offset forward/backward between tokens
        if type == 'stress' then dest[3] = dest[3] - (Convert_mm_igu(40)/math.sqrt(3))
        elseif type == 'focus' then dest[3] = dest[3] + (Convert_mm_igu(40)/math.sqrt(3))
        elseif type == 'targetLock' then
            dest[3] = dest[3] + (Convert_mm_igu(40)/math.sqrt(3))
            dest[1] = dest[1]*-1
        end
        -- If this position has other ship than ours here closest, halve it (it's on base instead then)
        local tempDest = Vect_Sum(Vect_RotateDeg(dest, ship.getRotation()[2]+180), ship.getPosition())
        local destData = MoveModule.GetTokenOwner(tempDest)
        if destData.owner ~= ship or destData.margin < Convert_mm_igu(20) then
            dest[1] = (baseSize/2)*(dest[1]/math.abs(dest[1]))
        end
        dest = Vect_RotateDeg(dest, ship.getRotation()[2]+180)
        dest = Vect_Sum(dest, ship.getPosition())

        if type == 'targetLock' then
            local newToken = DialModule.TokenSources[type].takeObject({position=dest, callback='Dial_SetLocks', callback_owner=Global})
            table.insert(DialModule.LocksToBeSet, {lock=newToken, name=ship.getName(), color=extra})
            announceInfo.note = 'acquired a target lock'
        else
            DialModule.TokenSources[type].takeObject({position=dest})
            if type == 'evade' then
                announceInfo.note = 'takes an evade token'
            else
                announceInfo.note = 'takes a ' .. type .. ' token'
            end
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
end

-- Table for locks to be set and callback to call setting of them
-- It's easiest this way if we want target lock tokens to still retain functionality
--  when manually handled too
DialModule.LocksToBeSet = {}
function Dial_SetLocks()
    for k,info in pairs(DialModule.LocksToBeSet) do
        info.lock.call('manualSet', {info.color, info.name})
    end
end

-- Keep spawned rulers here so you can delete them with same button as for spawn
-- Entry: {ship=shipRef, ruler=rulerObjRef}
DialModule.SpawnedRulers = {}
-- Click function for ruler button
function Ruler_SelfDestruct(obj)
    for k, info in pairs(DialModule.SpawnedRulers) do
        if info.ruler == obj then table.remove(DialModule.SpawnedRulers, k) end
    end
    obj.destruct()
end


-- DIAL BUTTON CLICK FUNCTIONS (self-explanatory)
function DialClick_Delete(dial)
    dial.clearButtons()
    ClearButtonsPatch(dial)
    DialModule.RestoreActive(dial.getVar('assignedShip'))
end
function DialClick_Flip(dial)
    dial.flip()
    dial.clearButtons()
    ClearButtonsPatch(dial)
    DialModule.SpawnMainActiveButtons({dial=dial, ship=dial.getVar('assignedShip')})
end
function DialClick_Move(dial)
    local actShip = dial.getVar('assignedShip')
    XW_cmd.Process(actShip, dial.getDescription())
    DialModule.SwitchMainButton(dial, 'undo')
end
function DialClick_Focus(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'focus')
end
function DialClick_Evade(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'evade')
end
function DialClick_Stress(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'stress')
end
function DialClick_TargetLock(dial, playerColor)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'targetLock', playerColor)
end
function DialClick_Template(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'spawnTemplate')
end
function DialClick_Undo(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'q')
    DialModule.SwitchMainButton(dial, 'move')
end
function DialClick_BoostS(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 's1')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_BoostR(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'br1')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_BoostL(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'be1')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollR(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xr')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollRF(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xrf')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollRB(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xrb')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollL(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xe')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollLF(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xef')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_RollLB(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xeb')
    DialModule.SwitchMainButton(dial, 'none')
end
function DialClick_Ruler(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler')
end
function DialClick_ToggleExpanded(dial)
    local befMove = false
    for k,but in pairs(dial.getButtons()) do
        if but.label == 'Move' then befMove = true end
    end
    if DialModule.GetButtonsState(dial) ~= 2 then
        DialModule.SetButtonsState(dial, 2)
    else
        if befMove == true then DialModule.SetButtonsState(dial, 0)
        else DialModule.SetButtonsState(dial, 1) end
    end
end

-- Dial buttons definitions (centralized so it;s easier to adjust)
DialModule.Buttons = {}
DialModule.Buttons.deleteFacedown = {label='Delete', click_function='DialClick_Delete', height = 400, width=1000, position={0, -0.5, 2}, rotation={180, 180, 0}, font_size=300}
DialModule.Buttons.deleteFaceup = {label='Delete', click_function='DialClick_Delete', height = 400, width=1000, position={0, 0.5, 2}, font_size=300}
DialModule.Buttons.flip = {label='Flip', click_function='DialClick_Flip', height = 400, width=600, position={0, -0.5, 0.2}, rotation={180, 180, 0}, font_size=300}
DialModule.Buttons.move = {label='Move', click_function='DialClick_Move', height = 500, width=750, position={-0.32, 0.5, 1}, font_size=300}
DialModule.Buttons.undoMove = {label='Undo', click_function='DialClick_Undo', height = 500, width=750, position={-0.32, 0.5, 1}, font_size=300}
DialModule.Buttons.focus = {label = 'F', click_function='DialClick_Focus', height=500, width=200, position={0.9, 0.5, -1}, font_size=250}
DialModule.Buttons.stress = {label = 'S', click_function='DialClick_Stress', height=500, width=200, position={0.9, 0.5, 0}, font_size=250}
DialModule.Buttons.evade = {label = 'E', click_function='DialClick_Evade', height=500, width=200, position={0.9, 0.5, 1}, font_size=250}
DialModule.Buttons.toggleExpanded = {label = 'A', click_function='DialClick_ToggleExpanded', height=500, width=200, position={-0.9, 0.5, 0}, font_size=250}
DialModule.Buttons.undo = {label = 'Q', click_function='DialClick_Undo', height=500, width=200, position={-0.9, 0.5, -1}, font_size=250}
DialModule.Buttons.nameButton = function(ship)
    local shortName = DialModule.GetShortName(ship)
    local nameWidth = 900
    local len = string.len(shortName)
    if len*150 > nameWidth then nameWidth = len*150 end
    return {label=shortName, click_function='dummy', height=300, width=nameWidth, position={0, -0.5, -1}, rotation={180, 180, 0}, font_size=250}
end
DialModule.Buttons.boostS = {label='B', click_function='DialClick_BoostS', height=500, width=365, position={0, 0.5, -2.2}, font_size=250}
DialModule.Buttons.boostR = {label='Br', click_function='DialClick_BoostR', height=500, width=365, position={0.75, 0.5, -2.2}, font_size=250}
DialModule.Buttons.boostL = {label='Bl', click_function='DialClick_BoostL', height=500, width=365, position={-0.75, 0.5, -2.2}, font_size=250}
DialModule.Buttons.rollR = {label='X', click_function='DialClick_RollR', height=500, width=365, position={1.5, 0.5, 0}, font_size=250}
DialModule.Buttons.rollRF = {label='Xf', click_function='DialClick_RollRF', height=500, width=365, position={1.5, 0.5, -1}, font_size=250}
DialModule.Buttons.rollRB = {label='Xb', click_function='DialClick_RollRB', height=500, width=365, position={1.5, 0.5, 1}, font_size=250}
DialModule.Buttons.rollL = {label='X', click_function='DialClick_RollL', height=500, width=365, position={-1.5, 0.5, 0}, font_size=250}
DialModule.Buttons.rollLF = {label='Xf', click_function='DialClick_RollLF', height=500, width=365, position={-1.5, 0.5, -1}, font_size=250}
DialModule.Buttons.rollLB = {label='Xb', click_function='DialClick_RollLB', height=500, width=365, position={-1.5, 0.5, 1}, font_size=250}
DialModule.Buttons.ruler = {label='R', click_function='DialClick_Ruler', height=500, width=365, position={-1.5, 0.5, 2}, font_size=250}
DialModule.Buttons.targetLock = {label='TL', click_function='DialClick_TargetLock', height=500, width=365, position={1.5, 0.5, 2}, font_size=250}

-- Get short name of a ship for dial indication "button"
DialModule.GetShortName = function(ship)
    local shipNameWords = {}
    local numWords = 0
    for word in ship.getName():gmatch('%w+') do table.insert(shipNameWords, word) numWords = numWords+1 end
    for k,w in pairs(shipNameWords) do if w == 'LGS' then table.remove(shipNameWords, k) numWords = numWords-1 end end
    local shipShortName = shipNameWords[1]
    if shipShortName:sub(1,1) == '\'' or shipShortName:sub(1,1) == '\"' then shipShortName = shipShortName:sub(2, -1) end
    if shipNameWords[numWords]:len() == 1 then shipShortName = shipShortName .. ' ' .. shipNameWords[numWords]:sub(1,1) end
    return shipShortName
end

-- Spawn first buttons on a dial (flip, indication, delete)
DialModule.SpawnFirstActiveButtons = function(dialTable)
    dialTable.dial.clearButtons()
    ClearButtonsPatch(dialTable.dial)
    dialTable.dial.createButton(DialModule.Buttons.deleteFacedown)
    dialTable.dial.createButton(DialModule.Buttons.flip)
    dialTable.dial.createButton(DialModule.Buttons.nameButton(dialTable.ship))
end

-- Spawn main buttons on a dial (move, actions, undo) when it is flipped over
DialModule.SpawnMainActiveButtons = function (dialTable)
    dialTable.dial.clearButtons()
    ClearButtonsPatch(dialTable.dial)
    dialTable.dial.createButton(DialModule.Buttons.deleteFaceup)
    dialTable.dial.createButton(DialModule.Buttons.move)
    dialTable.dial.createButton(DialModule.Buttons.toggleExpanded)
end

-- Check what buttons state the dial is in
-- -1: no buttons, generally should not occur
-- 0: just basic buttons
-- 1: above plus FSEQ buttons
-- 2: above plus boost, rolls, ruler and lock
DialModule.GetButtonsState = function(dial)
    local state = 0
    local buttons = dial.getButtons()
    if buttons == nil then return -1 end
    for k,but in pairs(buttons) do
        if but.label == 'F' then if state == 0 then state = 1 end end
        if but.label == 'B' then state = 2 end
    end
    return state
end

-- Adjust button set between states like explained over GetButtonsState function
DialModule.SetButtonsState = function(dial, newState)
    local standardActionsMatch = 'F S E Q'           -- labels for buttons of STANDARD set
    local extActionsMatch = 'Br B Bl Xf X Xb TL R'  -- labels for buttons of EXTENDED set

    local currentState = DialModule.GetButtonsState(dial)
    if newState > currentState then
        if currentState == 0 then -- BASIC -> STANDARD
            dial.createButton(DialModule.Buttons.focus)
            dial.createButton(DialModule.Buttons.stress)
            dial.createButton(DialModule.Buttons.evade)
            dial.createButton(DialModule.Buttons.undo)
        end
        if newState == 2 then -- STANDARD -> EXTENDED
            dial.createButton(DialModule.Buttons.boostS)
            dial.createButton(DialModule.Buttons.boostR)
            dial.createButton(DialModule.Buttons.boostL)
            dial.createButton(DialModule.Buttons.rollR)
            dial.createButton(DialModule.Buttons.rollRF)
            dial.createButton(DialModule.Buttons.rollRB)
            dial.createButton(DialModule.Buttons.rollL)
            dial.createButton(DialModule.Buttons.rollLF)
            dial.createButton(DialModule.Buttons.rollLB)
            dial.createButton(DialModule.Buttons.ruler)
            dial.createButton(DialModule.Buttons.targetLock)
        end
        -- if REMOVING buttons
    elseif newState < currentState then
        local buttons = dial.getButtons()
        if currentState == 2 then -- remove EXTENDED set ones
            for k,but in pairs(buttons) do
                if extActionsMatch:find(but.label) ~= nil then dial.removeButton(but.index) end
            end
        end
        if newState == 0 then -- remove STANDARD set ones
            for k,but in pairs(buttons) do
                if standardActionsMatch:find(but.label) ~= nil then dial.removeButton(but.index) end
            end
        end
    end
end

-- Change the main button between "Move", "Undo" and no button states
DialModule.SwitchMainButton = function(dial, type)
    local buttons = dial.getButtons()
    for k,but in pairs(buttons) do
        if type=='none' then
            if but.label == 'Undo' then
                dial.removeButton(but.index)
            end
        elseif type == 'undo' then
            if but.label == 'Move' then
                dial.removeButton(but.index)
                dial.createButton(DialModule.Buttons.undoMove)
                if DialModule.GetButtonsState(dial) == 0 then
                    DialModule.SetButtonsState(dial, 1)
                end
            end
        elseif type == 'move' then
            if but.label == 'Undo' then
                dial.removeButton(but.index)
                dial.createButton(DialModule.Buttons.move)
                if DialModule.GetButtonsState(dial) == 1 then
                    DialModule.SetButtonsState(dial, 0)
                end
            end
        end
    end
end

-- Make said dial a new active one
-- If there is one, return it to origin
DialModule.MakeNewActive = function(ship, dial)
    local actSet = DialModule.GetSet(ship)
    if actSet.dialSet[dial.getDescription()].dial == dial then
        if actSet.activeDial ~= nil then
            DialModule.RestoreActive(ship)
        end
        actSet.activeDial = actSet.dialSet[dial.getDescription()]
    end
end

-- Restore active dial for this ship set to origin
DialModule.RestoreActive = function(ship)
    local actSet = DialModule.GetSet(ship)
    if actSet.ship == ship and actSet.activeDial ~= nil then
        actSet.activeDial.dial.clearButtons()
        ClearButtonsPatch(actSet.activeDial.dial)
        actSet.activeDial.dial.setPosition(actSet.activeDial.originPos)
        actSet.activeDial.dial.setRotation(Dial_FaceupRot(actSet.activeDial.dial))
        actSet.activeDial = nil
    end
end

-- Resore said dial to origin
DialModule.RestoreDial = function(dial)
    for k, set in pairs(DialModule.ActiveSets) do
        if set.dialSet[dial.getDescription()].dial == dial then
            if set.activeDial ~= nil and set.activeDial.dial == dial then
                DialModule.RestoreActive(set.ship)
            else
                dial.clearButtons()
                ClearButtonsPatch(dial)
                dial.setPosition(set.dialSet[dial.getDescription()].originPos)
                dial.setRotation(Dial_FaceupRot(dial))
            end
        end
    end
end

-- Get "correct" faceup rotation of a dial based on which half of tabe it is in
function Dial_FaceupRot(dial)
    local z_half = nil
    if(dial.getPosition()[3] < 0) then z_half = -1 else z_half = 1 end
    if z_half > 0 then
        return {x=0, y=0, z=0}
    else
        return {x=0, y=180, z=0}
    end
end

-- END AUTO DIALS MODULE
--------


--------
-- DIRECT TTS EVENT HANDLING
-- Watch for changed descriptions, handle destroyed objects, saving et cetera

-- ~~~~~~
-- CONFIGURATION:

-- How many frames pass between updating watched objects (ships) list
-- It's so we don't go through massive list of all objects on table each frame (why would we?)
updateFrameInterval = 120
-- ~~~~~~

frameCounter = 0
watchedObj = {}

-- This is called each frame
function update()
    -- If there are no watched objects or frame counter passes threshhold
    if watchedObj[1] == nil or frameCounter > updateFrameInterval then
        watchedObj = {}
        -- Reset the list and add every figurine on the table
        for k,obj in pairs(getAllObjects()) do
            if obj ~= nil and obj.tag == 'Figurine' then
                table.insert(watchedObj, obj)
            end
        end
        frameCounter = 0
    end

    -- If description is not blank, try processing it
    for k, obj in pairs(watchedObj) do
        if obj ~= nil and obj.getDescription() ~= '' then XW_cmd.Process(obj, obj.getDescription()) end
    end

    frameCounter = frameCounter + 1
end

-- When something is destroyed, it is called as an argument here (with 1 more frame to live)
function onObjectDestroyed(dying_object)
    for k, obj in pairs(watchedObj) do if dying_object == obj then table.remove(watchedObj, k) end end
    -- Handle killing rulers and unassignment of dial sets
    DialModule.ObjDestroyedHandle(dying_object)
end

-- When table is loaded up, this is called
-- save_state contains everything separate modules saved before to restore table state
-- TO_DO: I swear I wanted to save/load something else too
function onLoad(save_state)
    if save_state ~= '' and save_state ~= nil then
        local savedData = JSON.decode(save_state)
        DialModule.onLoad(savedData['DialModule'])
    end
end

function onSave()
    local tableToSave = {}
    tableToSave['DialModule'] = {}
    tableToSave['DialModule'] = DialModule.onSave()
    return JSON.encode_pretty(tableToSave)
end

-- END DIRECT TTS EVENT HANDLING
--------


--------
-- COLLISION CHECKING MODULE
-- Generally checking if two rotated rectangles overlap

-- ~~~~~~
-- CONFIGURATION:

-- How many milimeters should we widen the base from each side
-- With this at zero, sometimes ships overlap after a move
addidionalCollisionMargin_mm = 0.4
-- ~~~~~~

-- General idea here: http://www.gamedev.net/page/resources/_/technical/game-programming/2d-rotated-rectangle-collision-r2604
-- Originally written by Flolania and Hera Verigo, slightly refitted here

-- Return corners of ship base in a {xPos, zPos} table format
-- shipInfo: {ship=shipObjectReference, pos=shipPosition, rot=shipRotation}
function getCorners(shipInfo)
    local corners = {}
    local spos = shipInfo.pos
    local srot = shipInfo.rot[2]
    local size = nil
    if DB_isLargeBase(shipInfo.ship) == true then
        size = Convert_mm_igu((mm_largeBase/2) + addidionalCollisionMargin_mm)
    else
        size = Convert_mm_igu((mm_smallBase/2) + addidionalCollisionMargin_mm)
    end
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

-- Return axes perpendicular to sides of two rectangles
function getAxis(c1,c2)
    local axis = {}
    axis[1] = {c1[2][1]-c1[1][1],c1[2][2]-c1[1][2]}
    axis[2] = {c1[4][1]-c1[1][1],c1[4][2]-c1[1][2]}
    axis[3] = {c2[2][1]-c2[1][1],c2[2][2]-c2[1][2]}
    axis[4] = {c2[4][1]-c2[1][1],c2[4][2]-c2[1][2]}
    return axis
end

-- Dot product of vectors ({xPos, yPos} format, not TTS one!)
function dot2d(p,o)
    return p[1] * o[1] + p[2] * o[2]
end

-- Check if any part of two rectangles overlap
-- Rectangles as in ship bases of a proper size
-- shipInfo: {ship=shipObjectReference, pos=shipPosition, rot=shipRotation}
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

-- END COLLISION CHECKING MODULE
--------


--------
-- SHIP DATABASE MODULE
-- Lets us check type and base size of a ship easily

-- Return ship type like it's written on the back of a dial
-- Return 'Unknown' is ship is not in the database
function DB_getShipType(shipRef)
    if shipRef.getVar('DB_shipType') ~= nil then return shipRef.getVar('DB_shipType') end
    local mesh = shipRef.getCustomObject()['mesh']
    for k,typeTable in pairs(shipTypeDatabase) do
        for k2,model in pairs(typeTable) do
            if model == mesh then
                shipRef.setVar('DB_shipType', typeTable[1])
                return typeTable[1]
            end
        end
    end
    return 'Unknown'
end

-- Return true if large base, false if small
-- First checks database, then LGS in name, warns and treat as small if both fail
function DB_isLargeBase(shipRef)
    if shipRef.getVar('DB_isLargeBase') ~= nil then
        return shipRef.getVar('DB_isLargeBase')
    end
    local shipType = DB_getShipType(shipRef)
    for k,typeTable in pairs(shipTypeDatabase) do
        if typeTable[1] == shipType then
            shipRef.setVar('DB_isLargeBase', typeTable[2])
            return typeTable[2]
        end
    end
    if shipRef.getName():find('LGS') ~= nil then return true
    else
        if shipRef.getVar('DB_missingModelWarned') ~= true then
            printToAll(shipRef.getName() .. '\'s model not recognized - use LGS in name if large base and contact author about the issue', {1, 0.1, 0.1})
            shipRef.setVar('DB_missingModelWarned', true)
        end
        return false
    end
end

-- Same as above with table argument to allow call from outside Global
function DB_getShipTypeCallable(table)
    return DB_getShipType(table[1])
end

-- Get the ship size as in 'large' or 'small'
-- 'Unknown' should be never returned (unless parent function DB_isLargeBase breaks)
function DB_getBaseSize(shipRef)
    local isLargeBase = DB_isLargeBase(shipRef)
    if isLargeBase == true then return 'large'
    elseif isLargeBase == false then return 'small'
    else return 'Unknown' end
end

-- Type <=> Model (mesh) database
-- Entry: { <type name>, <is large base?>, <model1>, <model2>, ..., <modelN>}
shipTypeDatabase = {
    xWing = {'X-Wing', false, 'https://paste.ee/r/54FLC', 'https://paste.ee/r/eAdkb', 'https://paste.ee/r/hxWah', 'https://paste.ee/r/ZxcTT', 'https://paste.ee/r/FfWNK'},
    yWingReb = {'Y-Wing Rebel', false, 'https://paste.ee/r/MV6qP'},
    yt1300 = {'YT-1300', true, 'https://paste.ee/r/kkPoB', 'http://pastebin.com/VdHhgdFr'},
    yt2400 = {'YT-2400', true, 'https://paste.ee/r/Ff0vZ'},
    aWing = {'A-Wing', false, 'https://paste.ee/r/tIdib', 'https://paste.ee/r/mow3U', 'https://paste.ee/r/ntg8n'},
    bWing = {'B-Wing', false, 'https://paste.ee/r/8CtXr'},
    hwk290Reb = {'HWK-290 Rebel', false, 'https://paste.ee/r/MySkn'},
    vcx100 = {'VCX-100', true, 'https://paste.ee/r/VmV6q'},
    attShuttle = {'Attack Shuttle', false, 'https://paste.ee/r/jrwRJ'},
    t70xWing = {'T-70 X-Wing', false, 'https://paste.ee/r/NH1KI'},
    eWing = {'E-Wing', false, 'https://paste.ee/r/A57A8'},
    kWing = {'K-Wing', false, 'https://paste.ee/r/2Airh'},
    z95hhReb = {'Z-95 Headhunter Rebel', false, 'https://paste.ee/r/d91Hu'},

    fs31Scum = {'Firespray-31 Scum', true, 'https://paste.ee/r/3INxK'},
    z95hhScum = {'Z-95 Headhunter Scum', false, 'https://paste.ee/r/OZrhd'},
    yWingScum = {'Y-Wing Scum', false, 'https://paste.ee/r/1T0ii'},
    hwk290Scum = {'HWK-290 Scum', false, 'https://paste.ee/r/tqTsw'},
    m3aScyk = {'M3-A Interceptor', false, 'https://paste.ee/r/mUFjk'},
    starViper = {'StarViper', false, 'https://paste.ee/r/jpEbC'},
    aggressor = {'Aggressor', true, 'https://paste.ee/r/0UFlm'},
    yv666 = {'YV-666', true, 'https://paste.ee/r/lLZ8W'},
    kihraxz = {'Kihraxz Fighter', false, 'https://paste.ee/r/E8ZT0'},
    jm5k = {'JumpMaster 5000', true, 'https://paste.ee/r/1af5C'},
    g1a = {'G-1A StarFighter', false, 'https://paste.ee/r/aLVFD'},

    tieFighter = {'TIE Fighter', false, 'https://paste.ee/r/Yz0kt'},
    tieCeptor= {'TIE Interceptor', false, 'https://paste.ee/r/cedkZ', 'https://paste.ee/r/JxWNX'},
    spaceCow = {'Lambda-Class Shuttle', true, 'https://paste.ee/r/4uxZO'},
    fs31Imp = {'Firespray-31 Imperial', true, 'https://paste.ee/r/p3iYR'},
    tieBomber = {'TIE Bomber', false, 'https://paste.ee/r/5A0YG'},
    tiePhantom = {'TIE Phantom', false, 'https://paste.ee/r/JN16g'},
    vtDecimator = {'VT-49 Decimator', true, 'https://paste.ee/r/MJOFI'},
    tieAdv = {'TIE Advanced', false, 'https://paste.ee/r/NeptF'},
    tiePunisher = {'TIE Punisher', false, 'https://paste.ee/r/aVGkQ'},
    tieDefender = {'TIE Defender', false, 'https://paste.ee/r/0QVhZ'},
    tieFoFighter = {'TIE/fo Fighter', false, 'http://pastebin.com/jt2AzA8t'},
    tieAdvProt = {'TIE Adv. Prototype', false, 'https://paste.ee/r/l7cuZ'}
}
-- END SHIP DATABASE MODULE
--------