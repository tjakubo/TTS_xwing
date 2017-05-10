-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: http://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of: Flolania, Hera Vertigo
-- ~~~~~~

-- TO_DO: don't lock ship after completeing if it's not level
-- TO_DO: Dials: on drop among dials, return to origin (maybe)
-- TO_DO onload (dials done, anything else?)
-- TO_DO: Movement collision check resolution based on its legth (consistent between moves)

-- TO_DO Vect Invers -> Vect Negaticve

-- TESTING: Reverse movements

-- Should the code execute print functions or skip them?
-- This should be set to false on every release
print_debug = true

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

mm_baseSize = {}
mm_baseSize.small = 40
mm_baseSize.smallBase = 40
mm_baseSize.large = 80
mm_baseSize.largeBase = 80

-- Convert argument from MILIMETERS to IN-GAME UNITS
function Convert_mm_igu(milimeters)
    return milimeters*mm_igu_ratio
end

-- Convert argument from IN-GAME UNITS to MILIMETERS
function Convert_igu_mm(in_game_units)
    return in_game_units/mm_igu_ratio
end

-- Distance between two positions
function Dist_Pos(pos1, pos2)
    if type(pos1) ~= 'table' or type(pos2) ~= 'table' then
        print('Dist_Pos: arg not a table!')
    end
    return math.sqrt( math.pow(pos1[1]-pos2[1], 2) + math.pow(pos1[3]-pos2[3], 2) )
end

-- Distance between two objects
function Dist_Obj(obj1, obj2)
    if type(pos1) ~= 'userdata' or type(pos2) ~= 'userdata' then
        print('Dist_Obj: arg not an object!')
    end
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
    if type(vec1) ~= 'table' or type(vec2) ~= 'table' then
        print('Vect_Sum: arg not a table!')
    end
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
    if type(vector) ~= 'table' then
        print('Vect_Inverse: arg not a table!')
    end
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
    if type(vector) ~= 'table' or type(factor) ~= 'number' then
        print('Vect_Scale: arg not a table/numer pair!')
    end
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
    if type(vector) ~= 'table' then
        print('Vect_Length: arg not a table!')
    end
    return math.sqrt(vector[1]*vector[1] + vector[3]*vector[3])
end

-- Offset self vector by first and third element of vec2 (second el ignored)
-- Useful for TTS positioning offsets
function Vect_Offset(self, vec2)
    if type(self) ~= 'table' or type(vec2) ~= 'table' then
        print('Vect_Offset: arg not a table!')
    end
    return {self[1]+vec2[1], self[2], self[3]+vec2[3]}
end

-- Rotation of a 3D vector over its second element axis, arg in degrees
function Vect_RotateDeg(vector, degRotation)
    local radRotation = math.rad(degRotation)
    return Vect_RotateRad(vector, radRotation)
end

-- Rotation of a 3D vector over its second element axis, arg in radians
function Vect_RotateRad(vector, radRotation)
    if type(vector) ~= 'table' or type(radRotation) ~= 'number' then
        print('Vect_RotateRad: arg not a table/number pair!')
    end
    local newX = math.cos(radRotation) * vector[1] + math.sin(radRotation) * vector[3]
    local newZ = math.sin(radRotation) * vector[1] * -1 + math.cos(radRotation) * vector[3]
    return {newX, vector[2], newZ}
end

function Var_Clamp(var, min, max)
    if min ~= nil and var < min then
        return min
    elseif max ~= nil and var > max then
        return max
    else
        return var
    end
end

function math.sgn(arg)
    if arg < 0 then
        return -1
    elseif arg > 0 then
        return 1
    end
    return 0
end

function math.round(arg)
    frac = arg - math.floor(arg)
    if frac >= 0.5 then
        return math.ceil(arg)
    else
        return math.floor(arg)
    end
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

-- Get an object closest to some position + optional X-Wing type filter
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

-- Get an object closest to some other object + optional X-Wing type filter
function XW_ClosestWithinDist(centralPosObj, maxDist, objType)
    exclObj = nil
    centralPos = nil
    if (type(centralPosObj) ~= 'userdata' and type(centralPosObj) ~= 'table') or
    type(maxDist) ~= 'number' or type(objType) ~= 'string' then
        print('XW_ClosestWithinDist: arg of invalid type')
    end
    if type(centralPosObj) == 'table' then
        centralPos = centralPosObj
    elseif type(centralPosObj) == 'userdata' then
        centralPos = centralPosObj.getPosition()
        exclObj = centralPosObj
    end
    local closest = nil
    local minDist = maxDist+1
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, objType) == true and obj ~= centralObj then
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
function XW_ObjWithinDist(centralPosObj, maxDist, objType, exclList)
    local ships = {}
    exclObj = nil
    centralPos = nil
    if (type(centralPosObj) ~= 'userdata' and type(centralPosObj) ~= 'table') or type(maxDist) ~= 'number' or
    type(objType) ~= 'string' or (exclList ~= nil and type(exclList) ~= 'table') then
        print('XW_ObjWithinDist: arg of invalid type')
    end
    if type(centralPosObj) == 'table' then
        centralPos = centralPosObj
    elseif type(centralPosObj) == 'userdata' then
        centralPos = centralPosObj.getPosition()
        exclObj = centralPosObj
    end
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, objType) == true and obj ~= exclObj then
            local excluded = false
            if exclList ~= nil then
                for k, exclListObj in pairs(exclList) do
                    if obj == exclListObj then
                        excluded = true
                        break
                    end
                end
            end
            if (not excluded) and Dist_Pos(centralPos, obj.getPosition()) < maxDist then
                table.insert(ships, obj)
            end
        end
    end
    return ships
end

-- Get objects within specified rectangle + optional X-Wing type filter
-- Rectangle is aligned with the table (no rotation)
function XW_ObjWithinRect(center, x_size, z_size, ObjType)
    if type(center) ~= 'table' or type(x_size) ~= 'number' or
    type(z_size) ~= 'number' or type(ObjType) ~= 'string' then
        print('XW_ObjWithinRect: arg of invalid type')
    end

    local objects = {}
    local x_min = center[1] - (x_size/2)
    local x_max = center[1] + (x_size/2)
    local z_min = center[3] - (z_size/2)
    local z_max = center[3] + (z_size/2)
    for k,obj in pairs(getAllObjects()) do
        if XW_ObjMatchType(obj, ObjType) == true then
            local obj_x = obj.getPosition()[1]
            local obj_z = obj.getPosition()[3]
            if obj_x < x_max and obj_x > x_min and obj_z < z_max and obj_z > z_min then
                table.insert(objects, obj)
            end
        end
    end
    return objects
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
    -- When adding available commands, assert beggining and end of string automatically
    if cmdRegex:sub(1,1) ~= '^' then cmdRegex = '^' .. cmdRegex end
    if cmdRegex:sub(-1,-1) ~= '$' then cmdRegex = cmdRegex .. '$' end
    table.insert(XW_cmd.ValidCommands, {cmdRegex, type})
end

-- Check if command is registered as valid
-- If it is return its type identifier, if not return nil
XW_cmd.CheckCommand = function(cmd)
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
    return type
end

XW_cmd.AddCommand('diag', 'special')
-- Check for typical issues with a ship
-- 1. Check and unlock XW_cmd lock if it's on
-- 2. Clear buttons if there are any
-- 3. Search for nil refs on dials in his set
-- 4. Check if ship type is recognized OK
XW_cmd.Diagnose = function(ship)
    local issueFound = false
    if XW_ObjMatchType(ship, 'ship') ~= true then return end
    if XW_cmd.isReady(ship) ~= true then
        XW_cmd.SetReady(ship)
        printToAll(ship.getName() .. '\'s deadlock resolved!', {0.1, 0.1, 1})
        issueFound = true
    end
    if ship.getButtons() ~= nil then
        ship.clearButtons()
        ClearButtonsPatch(ship)
        printToAll(ship.getName() .. '\'s lingering buttons deleted!', {0.1, 0.1, 1})
        issueFound = true
    end
    local set = DialModule.GetSet(ship)
    local dialError = false
    DialModule.RestoreActive(ship)
    if set ~= nil and set.dialSet ~= nil then
        for k, dInfo in pairs(set.dialSet) do
            if dInfo.dial == nil then dialError = true end
        end
    end
    if dialError == true then
        printToAll(ship.getName() .. '\'s dial data corupted - delete model & dials, spawn and assign a new set to new model', {1, 0.1, 0.1})
        issueFound = true
    end
    local shipType = DB_getShipType(ship)
    if shipType == 'Unknown' then
        printToAll(ship.getName() .. '\'s ship type not reconized. If this model was taken from Squad Builder or Collection, notify author of the issue.', {1, 0.1, 0.1})
        issueFound = true
    end
    if issueFound ~= true then
        printToAll(ship.getName() .. ' looks OK', {0.1, 1, 0.1})
    end
end

-- Process provided command on a provided object
-- Return true if command has been executed/started
-- Return false if object cannot process commands right now or command was invalid
XW_cmd.Process = function(obj, cmd)

    -- Resolve command type
    local type = XW_cmd.CheckCommand(cmd)
    -- Return if object is not ready
    if type ~= 'special' and XW_cmd.isReady(obj) ~= true then return false end


    -- Return if invalid, lock object if valid
    if type == nil then
        return false
    elseif type == 'special' then
        if cmd == 'diag' then
            XW_cmd.Diagnose(obj)
        end
    else
        XW_cmd.SetBusy(obj)
    end

    -- If it matched something, do it:

    -- Moving involves waiting for object to rest which then does SetReady
    if type == 'demoMove' then
        MoveModule.DemoMove(cmd:sub(3, -1), obj)
    elseif type == 'move' then
        MoveModule.PerformMove(cmd, obj)
    elseif type == 'actionMove' then
        MoveModule.PerformMove(cmd, obj)
    elseif type == 'historyHandle' then
        if cmd == 'q' or cmd == 'undo' then
            MoveModule.UndoMove(obj)
        elseif cmd == 'z' or cmd == 'redo' then
            MoveModule.RedoMove(obj)

            -- These commands are finished immediately and SetReady right away
        elseif cmd == 'keep' then
            MoveModule.SaveStateToHistory(obj, false)
            XW_cmd.SetReady(obj)
        end
    elseif type == 'dialHandle' then
        if cmd == 'sd' then
            DialModule.SaveNearby(obj)
        elseif cmd == 'rd' then
            DialModule.RemoveSet(obj)
        elseif cmd == 'cd' then
            DialModule.SaveNearby(obj, true)
        end
        XW_cmd.SetReady(obj)
    elseif type == 'action' then
        if cmd == 'r' then cmd = 'ruler' end
        DialModule.PerformAction(obj, cmd)
        XW_cmd.SetReady(obj)
    end
    obj.setDescription('')
    return true
end

-- Is object not processing some commands right now?
XW_cmd.isReady = function(obj)
    if obj.getVar('XW_cmd_busy') == true then return false
    else return true end
end

-- Flag the object as processing commands to ignore any in the meantime
XW_cmd.SetBusy = function(obj)
    if XW_cmd.isReady(obj) ~= true then
        print('Nested process on ' .. obj.getName())
    end
    obj.setVar('XW_cmd_busy', true)
end

-- Flag the object as ready to process next command
XW_cmd.SetReady = function(obj)
    if XW_cmd.isReady(obj) == true then
        print('Double ready on ' .. obj.getName())
    end
    obj.setVar('XW_cmd_busy', false)
end
--------
-- MOVEMENT DATA MODULE
-- Defines moves, parts of moves, their variants and decoding of move codes into actual move data
-- This is not aware of any ship positions (ship objects yes for their size) and doesn't move anything
-- Used for feeding data about a move to a higher level movement module

MoveData = {}
MoveData.LUT = {}

MoveData.onLoad = function()
    for k,obj in pairs(getAllObjects()) do
        if obj.getName() == 'MoveLUT' then
            MoveData.LUT.Parse(obj)
        end
    end
end

MoveData.LUT.Parse = function(object)
    MoveData.LUT.Data = object.call('ParseLUT', {})
end

MoveData.LUT.ConstructData = function(moveInfo, part)
    if part == nil then part = MoveData.partMax end
    part = Var_Clamp(part, 0, MoveData.partMax)
    local LUTtable = MoveData.LUT.Data[moveInfo.size .. 'Base'][moveInfo.type][moveInfo.speed]
    local LUTindex = (part/MoveData.partMax)*LUTtable.dataNum
    if LUTindex < 1 then LUTindex = 1 end
    local aProp = LUTindex - math.floor(LUTindex)
    local bProp = 1 - aProp
    local outPos = Vect_Sum(Vect_Scale(LUTtable.posXZ[math.floor(LUTindex)], bProp), Vect_Scale(LUTtable.posXZ[math.ceil(LUTindex)], aProp))
    local outRot = (LUTtable.rotY[math.floor(LUTindex)] * bProp) + (LUTtable.rotY[math.ceil(LUTindex)] * aProp)

    local outData = {outPos[1], 0, outPos[2], outRot}
    return outData
end

MoveData.MoveLength = function(moveInfo)
    if moveInfo.noPartial == true then
        return nil
    elseif moveInfo.speed == 0 then
        return 0
    else
        return MoveData.LUT.Data[moveInfo.size .. 'Base'][moveInfo.type][moveInfo.speed].length
    end
end

MoveData.slideMatchTable = {'x[rle]', 'x[rle][fb]?', 'c[rle][fb]?', 't[rle][123]t'}
MoveData.IsSlideMove = function(moveInfoCode)
    local code = nil
    if type(moveInfoCode) == 'table' and type(moveInfoCode.code) == 'string' then
        code = moveInfoCode.code
    elseif type(moveInfoCode) == 'string' then
        code = moveInfoCode
    else
        print('MoveData.IsSlideMove: arg of invalid type')
        print(type(moveInfoCode))
    end
    local matched = false
    for k,pat in pairs(MoveData.slideMatchTable) do
        if code:match(pat) ~= nil then
            matched = true
            break
        end
    end
    return matched
end

MoveData.SlideLength = function(moveInfo)
    if type(moveInfo) ~= 'table' and type(moveInfo.size) ~= 'string' then
        print('MoveData.SlideLength: arg of invalid type')
    end
    if not moveInfo.slideMove then
        return nil
    else
        baseSize = mm_baseSize[moveInfo.size]
        if moveInfo.type == 'roll' then
            return baseSize
        elseif moveInfo.type == 'turn' and moveInfo.extra == 'talon' then
            return baseSize/2
        end
    end
    return nil
end

MoveData.SlideMoveOrigin = function(moveInfo)
    --[[
    local info = {
    type='invalid',
    speed=nil,         -- speed, +5 for large ship barrel roll
    dir=nil,           -- 'left', 'right' or nil
    extra=nil,         -- 'koiogran', 'segnor', 'talon', 'reverse' (moves)
    -- 'straight', 'forward', 'backward' (decloaks/rolls)
    -- nil if not applicable
    noPartial=false,
    size=nil,          -- base size, 'large' or 'small'
    note=nil,          -- how movement nore looks, ex. (...) 'banked xxx' (...)
    collNote=nil,      -- how collision note looks, ex. (...) 'tried to do xxx' (...)
        code=move_code     -- explicit move code recieved
    ]]--
    local code = moveInfo.code
    local baseSize = mm_baseSize[moveInfo.size]
    local data = nil
    if moveInfo.type == 'roll' then
        local ang = -90
        if moveInfo.dir == 'right' then ang = 90 end
        if moveInfo.size == 'small' then
            data = MoveData.LUT.ConstructData({type='straight', speed=moveInfo.speed, size=moveInfo.size, code='s'..moveInfo.speed})
        else
            data = {0, 0, baseSize + 20, 0}
        end
        data = MoveData.RotateEntry(data, ang)
        data[4] = data[4] - ang
        data[3] = data[3] - MoveData.SlideLength(moveInfo)/2
    elseif moveInfo.type == 'turn' and moveInfo.extra == 'talon' then
        data = MoveData.LUT.ConstructData(moveInfo)
        data[3] = data[3] + MoveData.SlideLength(moveInfo)/2
        if moveInfo.dir == 'left' then
            data = MoveData.LeftVariant(data)
        end
        data = MoveData.TurnInwardVariant(data)
        --print('MoveData.SLideMoveOrigin TT data: ' .. data)
    end
    if data == nil then
        print('MoveData.SLideMoveOrigin return nil')
        --print('MoveData.SLideMoveOrigin info: ' .. moveInfo.type .. ' : ' .. moveInfo.extra)
    end
    return data
end

MoveData.SlidePartOffset = function(moveInfo, part)
    if moveInfo.extra == 'talon' then
        return {0, 0, -1*MoveData.SlideLength(moveInfo)*(part/MoveData.partMax), 0}
    else
        return {0, 0, MoveData.SlideLength(moveInfo)*(part/MoveData.partMax), 0}
    end
end

-- Table telling us how moves final position is determined
-- Format: {xOffset, yOffset, zOffset, rotOffset}
-- Axis' offsets are in milimeters, rotation offset is in degrees



XW_cmd.AddCommand('[sk][012345][r]?', 'move')

XW_cmd.AddCommand('b[rle][123][sr]?', 'move')

XW_cmd.AddCommand('t[rle][123][str]?', 'move')

-- Barrel roll RIGHT (member function to modify to left)
-- Large ships are hard to handle exceptions so their rolls are defined separately as 5 speeds higher

XW_cmd.AddCommand('x[rle][fb]?', 'actionMove')
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

-- Change an entry to be reverse type
MoveData.ReverseVariant = function(entry)
    return {entry[1], entry[2], -1*entry[3], -1*entry[4]}
end

MoveData.RotateEntry = function(entry, angDeg)
    local rotEntry = Vect_RotateDeg(entry, angDeg)
    return {rotEntry[1], rotEntry[2], rotEntry[3], entry[4]+angDeg}
end

MoveData.ApplyBasicModifiers = function(entry, info)
    local out = Lua_ShallowCopy(entry)
    if info.dir == 'left' then
        out = MoveData.LeftVariant(out)
    end
    if info.extra == 'reverse' then
        out = MoveData.ReverseVariant(out)
    end
    return out
end

MoveData.ApplyFinalModifiers = function(entry, info)
    local out = Lua_ShallowCopy(entry)
    if info.dir == 'talon' then
        out = MoveData.TurnInwardVariant(out)
    elseif info.extra == 'koiogran' or info.extra == 'segnor' then
        out = MoveData.TurnAroundVariant(out)
    end
    return out
end


-- Decode a move command into table with type, direction, speed etc info
MoveData.DecodeInfo = function (move_code, ship)
    local info = {
                    type='invalid',     -- [straight] [bank] [turn] [roll]
                    speed=nil,          -- [1] [2] [3] [4] [5]
                    dir=nil,            -- [left] [right] [nil]
                    extra=nil,          -- [koiogran] [segnor] [talon] [reverse] [straight] [forward] [backward] [nil]
                    noPartial=false,    -- [true] [false]
                    slideMove=false,    -- [true] [false]
                    size=nil,           -- [small] [large]
                    note=nil,           -- [string] eg. 'banked xxx'
                    collNote=nil,       -- [string] eg. 'tried to do xxx'
                    code=move_code      -- [string] eg. 'be2'
    }

    info.slideMove = MoveData.IsSlideMove(move_code)

    if DB_isLargeBase(ship) == true then info.size = 'large'
    else info.size = 'small' end

 -- TO_DO: Notes for invalid
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
        if move_code:sub(-1,-1) == 'r' and info.extra ~= 'koiogran' then
            info.extra = 'reverse'
            info.note = 'flew reverse ' .. info.speed
            info.collNote = 'tried to fly reverse ' .. info.speed
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
        elseif move_code:sub(-1,-1) == 'r' then
            info.extra = 'reverse'
            info.note = 'flew reverse bank ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to fly reverse bank ' .. info.dir .. ' ' .. info.speed
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
        elseif move_code:sub(-1,-1) == 'r' then
            info.extra = 'reverse'
            info.note = 'flew reverse turn ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to fly reverse turn ' .. info.dir .. ' ' .. info.speed
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
        info.noPartial = true
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        info.note = 'barrel rolled'
        info.collNote = 'tried to barrel roll'
        -- (fucking decloak) is treated as a roll before, now just return straight 2 data
        if move_code:sub(2,2) == 's' then
            info.type = 'straight'
            info.speed = 2
            --info.extra = 'straight'
            info.note = 'decloaked forward'
            info.collNote = 'tried to decloak forward'
            if info.size == 'large' then info.type = 'invalid' end
            info.dir = nil
        elseif move_code:sub(1,1) == 'c' then
            info.note = 'decloaked'
            info.collNote = 'tried to decloak'
            info.speed = 2
            if info.size == 'large' then return MoveData.DecodeInfo(move_code:gsub('c', 'x'), ship) end
        end

        if info.type ~= 'straight' then
            if move_code:sub(-1,-1) == 'f' then
                info.extra = 'forward'
                info.note = info.note .. ' forward ' .. info.dir
                info.collNote = info.collNote .. ' forward ' .. info.dir
            elseif move_code:sub(-1,-1) == 'b' then
                info.extra = 'backward'
                info.note = info.note .. ' backward ' .. info.dir
                info.collNote = info.collNote .. ' forward ' .. info.dir
            else
                info.note = info.note .. ' ' .. info.dir
                info.collNote = info.collNote .. ' ' .. info.dir
            end
        end

    end
    --for k,v in pairs(info) do
    --    print(k .. ' : ' .. tostring(v))
    --end
    return info
end

-- Decode a "move" from the standard X-Wing notation into a valid movement data
-- Provide a 'ship' object reference to determine if it is large based
-- Returns offset data ship has to be treated with to perform a full move
-- Standard format {xOffset, yOffset, zOffset, rotOffset}
MoveData.DecodeFullMove = function(move_code, ship)
    local data = {}
    -- get the info about the move
    local info = MoveData.DecodeInfo(move_code, ship)
    if info.type == 'invalid' then
        print('MoveData.DecodeFullMove: invalid move type')
        return {0, 0, 0, 0}
    elseif info.speed == 0 then
        data = {0, 0, 0, 0}
    else
        data = MoveData.DecodePartMove(move_code, ship, MoveData.partMax)
    end
    data = MoveData.ApplyFinalModifiers(data, info)
    return data
end

-- Max part value for partial moves
-- Part equal to this is a full move
-- Value is largely irrelevant since part can be a fraction (any kind of number really)
MoveData.partMax = 1000

MoveData.DecodePartMove = function(move_code, ship, part)

    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)

    -- handle part out of (0, PartMax) bounds
    --if part >= MoveData.partMax then return MoveData.DecodeFullMove(move_code, ship)
    part = Var_Clamp(part, 0, MoveData.partMax)
    if info.type == 'invalid' then
        print('MoveData.DecodePartMove: invalid move type')
        return {0, 0, 0, 0}
    end
    data = MoveData.LUT.ConstructData(info, part)
    data = MoveData.ApplyBasicModifiers(data, info)
    return data
end

MoveData.DecodePartSlide = function(move_code, ship, part)
    local info = MoveData.DecodeInfo(move_code, ship)
    local slideOrigin = MoveData.SlideMoveOrigin(info)
    local offset = MoveData.SlidePartOffset(info, part)
    return Vect_Sum(slideOrigin, offset)
end


--------
-- MAIN MOVEMENT MODULE
-- Lets us move ships around and handles what comes with moving

MoveModule = {}

MoveModule.EntryToPos = function(entry, ship)
    --print('EntryToPos: ' .. entry[1] .. ' : ' .. entry[2] .. ' : ' .. entry[3] .. ' : ' .. entry[4] .. ' : ' .. ship.getName())
    local finalPos = MoveData.ConvertDataToIGU(entry)
    local finalRot = entry[4] + ship.getRotation()[2]
    --print('EntryToPos finalPos1: ' .. finalPos[1] .. ' : '  .. finalPos[2] .. ' : ' .. finalPos[3])
    --print('EntryToPos finalRot: ' .. finalRot)
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    --print('EntryToPos finalPos2: ' .. finalPos[1] .. ' : ' ..  finalPos[2] .. ' : ' .. finalPos[3])
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- Simply get the final position for a 'ship' if it did a move (standard move code)
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetFullMove = function(move, ship)
    local entry = MoveData.DecodeFullMove(move, ship)
    return MoveModule.EntryToPos(entry, ship)
end

-- Simply get the final position for a 'ship' if it did a part of a move (standard move code)
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetPartMove = function(move, ship, part)
    --print('GetPartMove: ' .. move .. ' : ' .. ship.getName() .. ' : ' .. part )
    local entry = MoveData.DecodePartMove(move, ship, part)
    --print('GetPartMove entry: ' .. entry[1] .. ' : ' .. entry[2] .. ' : ' .. entry[3] .. ' : ' .. entry[4])
    return MoveModule.EntryToPos(entry, ship)
end

MoveModule.GetPartSlide = function(move, ship, part)
    local entry = MoveData.DecodePartSlide(move, ship, part)
    return MoveModule.EntryToPos(entry, ship)
end

--TO_DO Part (0 - MoveData.partMax) to (1 - dataNum) index range

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
-- Entry: {pos=position, rot=rotation, move=moveThatGotShipHere, part=partOfMovePerformed}
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
        k = k+1
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
    local entry = {pos=ship.getPosition(), rot=ship.getRotation(), move='position save', part=nil}
    MoveModule.AddHistoryEntry(ship, entry, beQuiet)
end

-- Move a ship to a previous state from the history
-- Return true if action was taken
-- Return false if there is no more data
MoveModule.UndoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
    local shipMoved = false
    -- No history
    if histData.actKey == 0 then
        announceInfo.note = 'has no more moves to undo'
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
            shipMoved = true
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
                shipMoved = true
            else
                -- There is no data to go back to
                announceInfo.note = 'has no more moves to undo'
            end
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
    -- Flag ship as done processing if it didn't move (and didn't get queued for rest wait)
    if shipMoved == false then XW_cmd.SetReady(ship) end
    return shipMoved
end

-- Move a ship to next state from the history
-- Return true if action was taken
-- Return false if there is no more data
MoveModule.RedoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
    local shipMoved = false
    -- No history
    if histData.actKey == 0 then
        announceInfo.note = 'has no more moves to redo'
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
            shipMoved = true
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
    -- Flag ship as done processing if it didn't move (and didn't get queued for rest wait)
    if shipMoved == false then XW_cmd.SetReady(ship) end
    return shipMoved
end

-- Get the last move code from ship history
MoveModule.GetLastMove = function(ship)
    local move = 'none'
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey < 1 then
        print('lmrn')
        return {move='none'}
    else
        return histData.history[histData.actKey]
    end
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
function restWaitCoroutine()
    if MoveModule.restWaitQueue[1] == nil then
        dummy()
        print('coroutine table empty') --TO_DO: Exception handling?
        -- Should not happen since I try to keep 1 entry added = 1 coroutine started ratio
        --  but who knows, it's kinda harmless anyways
        return 0
    end

    local waitData = MoveModule.restWaitQueue[#MoveModule.restWaitQueue]
    local actShip = waitData.ship
    table.remove(MoveModule.restWaitQueue, #MoveModule.restWaitQueue)
    repeat
        if actShip.getLock() == true then actShip.unlock() end
        if actShip.getPosition()[2] > 1.5 and actShip.resting == true and actShip.isSmoothMoving ~= true then
            actShip.setPositionSmooth({actShip.getPosition()[1], actShip.getPosition()[2]-0.1, actShip.getPosition()[3]})
            actShip.resting = false
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
            -- Ckeck if final position makes this ship owner of a token
            if destData.owner ~= actShip or destData.margin < Convert_mm_igu(20) then
                local destLen
                if DB_isLargeBase(actShip) == true then
                    destLen = Convert_mm_igu(mm_largeBase/4)
                else
                    destLen = Convert_mm_igu(mm_smallBase/4)
                end
                -- If not, place it on the base instead
                offset = Vect_Scale(offset, (destLen/Vect_Length(offset)))
                dest = Vect_Sum(offset, actShip.getPosition())
            end
            dest[2] = dest[2] + 1.5
            tokenInfo.token.setPositionSmooth(dest)
            local tRot = tokenInfo.token.getRotation()
            tokenInfo.token.setRotationSmooth({tRot[1], actShip.getRotation()[2] + tokenInfo.relRot, tRot[3]})
            tokenInfo.token.highlightOn({0, 1, 0}, 2)
        else
            -- Index back tokens that are not waiting for this ship
            table.insert(newTokenTable, tokenInfo)
        end

    end
    MoveModule.tokenWaitQueue = newTokenTable
    actShip.lock()
    -- Save this position if last move code was provided
    if waitData.lastMove ~= nil then MoveModule.AddHistoryEntry(actShip, {pos=actShip.getPosition(), rot=actShip.getRotation(), move=waitData.lastMove}, true) end
    -- Free the object so it can do other stuff
    XW_cmd.SetReady(actShip)
    -- TO_DO: Set busy here and set ready in process
    return 1
end


-- TO_DO if large base switches to base size table
-- Check if provided ship in a provided position/rotation would collide with anything from the provided table
MoveModule.CheckCollisions = function(ship, shipPosRot, collShipTable)
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

    for k, collShip in pairs(collShipTable) do
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
                print('MoveModule.CheckCollisions: certain')
                if certBumpDist - dist > info.minMargin then
                    info.minMargin = certBumpDist - dist
                end
            elseif collide(shipInfo, {pos=collShip.getPosition(), rot=collShip.getRotation(), ship=collShip}) == true then
                info.coll = collShip
                info.numCheck = info.numCheck + 1
                print('MoveModule.CheckCollisions: calc\'d')
                break
            else
                print('MoveModule.CheckCollisions: no calc\'d')
                info.numCheck = info.numCheck + 1
            end
        else
            print('MoveModule.CheckCollisions: impossible')
        end
    end
    return info
end

MoveModule.partResolutionRough = 1/100
MoveModule.partResolutionFine = 1/1000
MoveModule.GetFreePart = function(info, ship, partFun, partRange, moveLength, fullFun)
    if moveLength == nil then moveLength = 0 end
    moveLength = Convert_mm_igu(moveLength)
    local out = {part = nil, info = nil, collObj = nil}
    local checkNum = {full=0, rough=0, fine=0}
    print('GetFreePart start')
    if invertPartDelta == nil then
        invertPartDelta = false
    end
    local certShipReach = Convert_mm_igu(mm_baseSize[info.size])/2
    local maxShipReach = Convert_mm_igu(mm_baseSize[info.size]*math.sqrt(2))/2

    local moveReach = math.max( Dist_Pos(partFun(info.code, ship, MoveData.partMax/2).pos, partFun(info.code, ship, MoveData.partMax).pos),
                                Dist_Pos(partFun(info.code, ship, MoveData.partMax/2).pos, partFun(info.code, ship, 0).pos) )


    --print('MoveModule.GetFreePart range breakdown: ' .. Convert_igu_mm(moveReach) .. ' + ' .. Convert_igu_mm(maxShipReach) .. ' + ' .. mm_largeBase*math.sqrt(2)/2 .. ' + 10')

    local collShipRange = moveReach + maxShipReach + Convert_mm_igu(mm_largeBase*math.sqrt(2))/2 + Convert_mm_igu(10)
    local collShips = XW_ObjWithinDist(partFun(info.code, ship, MoveData.partMax/2).pos, collShipRange, 'ship', {ship})
    --print('MoveModule.GetFreePart cShipList: ')
    --for k, ship in pairs(collShips) do print('  -- ' .. ship.getName()) end

    if fullFun ~= nil then
        fullInfo = MoveModule.CheckCollisions(ship, fullFun(info.code, ship), collShips)
        checkNum.full = checkNum.full + fullInfo.numCheck
        if fullInfo.coll == nil then
            out.info = 'full'
            return out
        elseif info.noPartial == true then
            out.info = 'overlap'
            return out
        end
    end

    local actPart = partRange.from
    local partDelta = math.sgn(partRange.to - partRange.from)*(MoveData.partMax*MoveModule.partResolutionRough)
    local minPartDelta = math.abs(partDelta)
        -- There was a collision!
    local collision = false

    print('GetFreePart rough ranges: ' .. partRange.from .. ' : ' .. partRange.to .. ' :: ' .. partDelta)

    -- First, we will check collisions every 1/100th of a move
    -- BUT WITH A CATCH
    repeat
        print('GetFreePart rough iter: ' .. actPart)

        local nPos = partFun(info.code, ship, actPart)
        local collInfo = MoveModule.CheckCollisions(ship, nPos, collShips)
        checkNum.rough = checkNum.rough + collInfo.numCheck
        local distToSkip = nil
        if collInfo.coll ~= nil then
            collision = true
            distToSkip = collInfo.minMargin
            -- If there is a distance we can travel that assures collison will not end
            if distToSkip > 0 then
                -- Calculate how big part it is and skip away!
                -- This saves A LOT of iterations, for real
                partDelta = math.sgn(partDelta)*((distToSkip * MoveData.partMax)/moveLength)
                print('GetFreePart rough to_skip:' .. distToSkip)

                if math.abs(partDelta) < minPartDelta then partDelta = math.sgn(partDelta)*minPartDelta end
                -- Else we're back at 1/100th of a move back
            else
                partDelta = math.sgn(partDelta)*minPartDelta
            end
        else
            collision = false
        end

        if collision == true then
            out.collObj = collInfo.coll
            actPart = actPart + partDelta
        end
    until collision == false or ((partRange.to - actPart)*math.sgn(partDelta) < 0) or partDelta == 0
print('GetFreePart rough FINISH: ' .. actPart)
----- <=====


    -- Right now, we're out of any collisions or at part 0 (no move)
    -- Go 1/1000th of a move forward until we have a collision, then skip to last free 1/1000th
    if collision == false and partDelta ~= 0 and actPart ~= partRange.from then
        partDelta = math.sgn(partRange.to - partRange.from)*(MoveData.partMax*MoveModule.partResolutionFine)*-1
        print('GetFreePart fine ranges: ' .. partRange.from .. ' : ' .. actPart .. ' : ' .. partRange.to .. ' :: ' .. partDelta)

        local collInfo
        repeat
            print('GetFreePart fine iter: ' .. actPart .. ' [to ' .. out.collObj.getName() .. ']')
            local nPos = partFun(info.code, ship, actPart)
            collInfo = MoveModule.CheckCollisions(ship, nPos, {out.collObj})
            checkNum.fine = checkNum.fine + collInfo.numCheck
            if collInfo.coll ~= nil then
                collision = true
            else
                collision = false
            end
            actPart = actPart + partDelta
        until collision == true or (partRange.from - actPart)*math.sgn(partDelta) < 0
        actPart = actPart - partDelta
        out.collObj = collInfo.coll -- This is what we hit
        out.part = actPart
    elseif collision == false then
        print('GetFreePart fine SKIP: dP zero or first')
        out.part = actPart
        out.info = 'first'
    elseif collision == true then
        print('GetFreePart fine SKIP: not exited overlap')
        out.info = 'overlap'
        out.part = partRange.to
    end
    print('-- GetFreePart CHECK_COUNT: ' .. checkNum.rough+checkNum.fine .. ' (' .. checkNum.rough .. ' + ' .. checkNum.fine .. ')')
    return out
end

-- TO_DO return finPos from GetFreePart
MoveModule.GetFinalPos = function(move_code, ship, ignoreCollisions)
    local out = {finPos = nil, collObj = nil, finType = nil, finPart = nil}
    local info = MoveData.DecodeInfo(move_code, ship)

    -- Don't bother with collisions if it's stationary
    if info.speed == 0 then
        ignoreCollisions = true
    end

    if ignoreCollisions then
        if info.slideMove then
            local initPart = MoveData.partMax/2
            if info.extra == 'forward' then
                initPart = MoveData.partMax
            elseif info.extra == 'backward' then
                initPart = 0
            end
            out.finPos = MoveModule.GetPartSlide(info.code, ship, initPart)
            out.finType = 'slide'
            out.finPart = initPart
            return out
        else
            out.finPos = MoveModule.GetFullMove(info.code, ship)
            out.finType = 'move'
            out.finPart = 'max'
            return out
        end
    else
        --(info, ship, partFun, partRange, moveLength fullFun)
        if info.slideMove then
            local partRange = {from=0, to=MoveData.partMax}
            if info.extra == 'forward' then
                partRange = {from=MoveData.partMax, to=0}
            elseif info.extra ~= 'backward' then
                --local firstCheckRange = {from=MoveData.partMax/2, to=MoveData.partMax/2}
                local firstCheckRange = {from=500, to=500}
                local freePartData = MoveModule.GetFreePart(info, ship, MoveModule.GetPartSlide, firstCheckRange, MoveData.SlideLength(info))
                if freePartData.info ~= 'overlap' then
                    out.finPos = MoveModule.GetPartSlide(info.code, ship, freePartData.part)
                    out.finType = 'slide'
                    out.finPart = freePartData.part
                    print('GetFinalPos finPart: ' .. freePartData.part)
                    return out
                end
            end
            local freePartData = MoveModule.GetFreePart(info, ship, MoveModule.GetPartSlide, partRange, MoveData.SlideLength(info))
            if freePartData.info ~= 'overlap' then
                out.finPos = MoveModule.GetPartSlide(info.code, ship, freePartData.part)
                out.finType = 'slide'
                out.finPart = freePartData.part
                print('GetFinalPos finPart: ' .. freePartData.part)
                return out
            end
        end
        if not info.noPartial then
            local partRange = {from=MoveData.partMax, to=0}
            local freePartData = MoveModule.GetFreePart(info, ship, MoveModule.GetPartMove, partRange, MoveData.MoveLength(info), MoveModule.GetFullMove)
            if freePartData.info == 'full' then
                out.finPos = MoveModule.GetFullMove(info.code, ship)
                out.finType = 'move'
                out.finPart = 'max'
                return out
            else
                out.finPos = MoveModule.GetPartMove(info.code, ship, freePartData.part)
                out.finType = 'move'
                out.finPart = freePartData.part
                print('GetFinalPos finPart: ' .. freePartData.part)
                out.collObj = freePartData.collObj
                return out
            end
        else
            local partRange = {from=MoveData.partMax, to=MoveData.partMax}
            local freePartData = MoveModule.GetFreePart(info, ship, MoveModule.GetPartMove, partRange, MoveData.MoveLength(info), MoveModule.GetFullMove)
            if freePartData.info == 'full' then
                out.finPos = MoveModule.GetFullMove(info.code, ship)
                out.finType = 'move'
                out.finPart = 'max'
                return out
            end
        end
        out.finType = 'overlap'
        return out
    end

    --[[if ignoreCollisions ~= true then
        -- LET THE SPAGHETTI FLOW!
        -- Check move length so we can relate how far some part of a move will take us
        local moveLength = MoveData.MoveLength(info)
        --moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        --moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
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
        local ships = XW_ObjWithinDist(MoveModule.GetPartMove(move_code, ship, MoveData.partMax/2).pos, moveLength+(2*maxShipReach), 'ship')
        for k, collShip in pairs(ships) do if collShip == ship then table.remove(ships, k) end end

        -- Let's try collisions at the end of a move
        local finalInfo = MoveModule.CheckCollisions(ship, MoveModule.GetFullMove(move_code, ship), ships)

        -- (if there will be collisions) we will start with maximum part of a move (ending position)
        local actPart = MoveData.partMax
        if finalInfo.coll ~= nil then
            -- There was a collision!
            local checkNum = 0 -- this is just to see how efficient stuff is
            local collision = false

            -- First, we will check collisions every 1/100th of a move
            -- BUT WITH A CATCH
            local partDelta = -1*(MoveData.partMax/100)
            repeat
                local nPos = MoveModule.GetPartMove(move_code, ship, actPart)
                local collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                local distToSkip = nil
                if collInfo.coll ~= nil then
                    collision = true
                    distToSkip = collInfo.minMargin
                    -- If there is a distance we can travel that assures collison will not end
                    if distToSkip > 0 then
                        -- Calculate how big part it is and skip away!
                        -- This saves A LOT of iterations, for real
                        partDelta = -1*((distToSkip * MoveData.partMax)/moveLength)
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
            partDelta = (1/1000)*MoveData.partMax
            local collInfo
            repeat
                local nPos = MoveModule.GetPartMove(move_code, ship, actPart)
                collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                if collInfo.coll ~= nil then collision = true
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
            until (collision == true and collInfo.coll == info.collidedShip) or actPart > MoveData.partMax
            actPart = actPart - partDelta
            info.collidedShip = collInfo.coll -- This is what we hit
        end

        -- We get the final position as a calculated part or as a full move if ignoring collisions
        finPos = MoveModule.GetPartMove(move_code, ship, actPart)
    else
        finPos = MoveModule.GetFullMove(move_code, ship)
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

    -- Bump notification button
    Ship_RemoveOverlapReminder(ship)
    if info.collidedShip ~= nil then
        MoveModule.SpawnOverlapReminder(ship)
    end

    -- Get the ship in a queue to do stuff once resting
    table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove=move_code})
    startLuaCoroutine(Global, 'restWaitCoroutine')]]--
end

XW_cmd.AddCommand('d:x[rle]', 'demoMove')
XW_cmd.AddCommand('d:x[rle][fb]', 'demoMove')
XW_cmd.AddCommand('d:c[srle]', 'demoMove')
XW_cmd.AddCommand('d:c[rle][fb]', 'demoMove')
XW_cmd.AddCommand('d:t[rle][123][str]?', 'demoMove')
XW_cmd.AddCommand('d:b[rle][123][sr]?', 'demoMove')
XW_cmd.AddCommand('d:[sk][012345][r]?', 'demoMove')
MoveModule.DemoMove = function(move_code, ship, ignoreCollisions, frameStep)
    if demoMoveData ~= nil then return end

    if frameStep == nil then frameStep = 1 end
    demoMoveData = {startPos = {pos = ship.getPosition(), rot=ship.getRotation()},
    ship = ship,
    moveInfo = MoveData.DecodeInfo(move_code, ship),
    ignoreCollisions = ignoreCollisions,
    frameStep = frameStep,
    currMovePart = 0,
    currSlidePart = 0}
    startLuaCoroutine(Global, 'DemoMoveCoroutine')
end

demoMoveData = nil

function DemoMoveCoroutine()
    local data = demoMoveData
    local movePartDelta = 0
    local slidePartDelta = 0
    if MoveData.MoveLength(data.moveInfo) ~= nil then
        movePartDelta = 300/MoveData.MoveLength(data.moveInfo)
    end
    if MoveData.SlideLength(data.moveInfo) ~= nil then
        slidePartDelta = 300/MoveData.SlideLength(data.moveInfo)
    end
    if data.moveInfo.noPartial and (not data.moveInfo.slideMove) then
        print('Demo: stiff move')
        local targetPos = MoveModule.GetFullMove(data.moveInfo.code, data.ship)
        data.ship.setPosition(targetPos.pos)
        data.ship.setRotation(targetPos.rot)
    end
    if data.moveInfo.noPartial then
        data.currMovePart = 2*MoveData.partMax
    end
    if not data.moveInfo.slideMove then
        data.currSlidePart = 2*MoveData.partMax
    end
    while data.currMovePart <= MoveData.partMax do
        print('M: ' .. data.currMovePart)
        data.ship.setPosition(data.startPos.pos)
        data.ship.setRotation(data.startPos.rot)
        local targetPos = nil
        if data.currMovePart < MoveData.partMax then
            targetPos = MoveModule.GetPartMove(data.moveInfo.code, data.ship, data.currMovePart)
        else
            targetPos = MoveModule.GetFullMove(data.moveInfo.code, data.ship)
        end
        data.ship.setPosition(targetPos.pos)
        data.ship.setRotation(targetPos.rot)
        data.currMovePart = data.currMovePart + movePartDelta
        if data.currMovePart > MoveData.partMax and (data.currMovePart - movePartDelta) < MoveData.partMax then
            data.currMovePart = MoveData.partMax
        end
        coroutine.yield(0)
    end
    while data.currSlidePart <= MoveData.partMax do
        print('S: ' .. data.currSlidePart)
        data.ship.setPosition(data.startPos.pos)
        data.ship.setRotation(data.startPos.rot)
        local targetPos = nil
        targetPos = MoveModule.GetPartSlide(data.moveInfo.code, data.ship, data.currSlidePart)
        data.ship.setPosition(targetPos.pos)
        data.ship.setRotation(targetPos.rot)
        data.currSlidePart = data.currSlidePart + slidePartDelta
        if data.currSlidePart > MoveData.partMax and (data.currSlidePart - slidePartDelta) < MoveData.partMax then
            data.currSlidePart = MoveData.partMax
        end
        coroutine.yield(0)
    end

    demoMoveData = nil
    XW_cmd.SetReady(data.ship)
    return 1
end

TokenModule = {}

TokenModule.tokenSources = {}

-- Update token sources on each load
-- Restore sets if data is loaded
TokenModule.onLoad = function()
    for k, obj in pairs(getAllObjects()) do
        if obj.tag == 'Infinite' then
            if obj.getName() == 'Focus' then TokenModule.tokenSources.Focus = {src=obj, hlColor={0, 0.5, 0}}
            elseif obj.getName() == 'Evade' then TokenModule.tokenSources.Evade = {src=obj, hlColor={0, 1, 0}}
            elseif obj.getName() == 'Stress' then TokenModule.tokenSources.Stress = {src=obj, hlColor={0.8, 0, 0}}
            elseif obj.getName() == 'Target Locks' then TokenModule.tokenSources['Target Lock'] = {src=obj, hlColor={0, 0, 1}}
            elseif obj.getName():find('Templates') ~= nil then
                if obj.getName():find('Straight') ~= nil then
                    TokenModule.tokenSources['s' .. obj.getName():sub(1,1)] = obj
                elseif obj.getName():find('Turn') ~= nil then
                    TokenModule.tokenSources['t' .. obj.getName():sub(1,1)] = obj
                elseif obj.getName():find('Bank') ~= nil then
                    TokenModule.tokenSources['b' .. obj.getName():sub(1,1)] = obj
                end
            end
        end
    end
end

-- Table for locks to be set and callback to call setting of them
-- It's easiest this way if we want target lock tokens to still retain functionality
--  when manually handled too
TokenModule.locksToBeSet = {}
function TokenModule_SetLocks()
    for k,info in pairs(TokenModule.locksToBeSet) do
        info.lock.call('manualSet', {info.color, info.name})
        info.lock.highlightOn({0,0,0}, 0.01)
    end
    TokenModule.locksToBeSet = {}
end

TokenModule.TakeToken = function(type, playerColor, dest)
    local takeTable = {}
    if dest ~= nil then
        takeTable.position = dest
    end
    local highlightColor = TokenModule.tokenSources[type].hlColor
    if type == 'Target Lock' then
        takeTable.callback = 'TokenModule_SetLocks'
        takeTable.callback_owner = Global
    end
    local newToken = TokenModule.tokenSources[type].src.takeObject(takeTable)
    newToken.highlightOn(highlightColor, 3)
    return newToken
end

TokenModule.TakeTemplate = function(infoCode)

end

TokenModule.tokenReachDistance = Convert_mm_igu(100)
TokenModule.visibleMargin = Convert_mm_igu(15)

TokenModule.basePos = {}
TokenModule.basePos.small = {}
TokenModule.basePos.small.Focus     = { 12,  12}
TokenModule.basePos.small.Evade     = { 12, -12}
TokenModule.basePos.small.Stress    = {-12,  12}
TokenModule.basePos.small.rest      = {-12, -12}
TokenModule.basePos.large = {}
TokenModule.basePos.large.Focus     = { 30,  30}
TokenModule.basePos.large.Evade     = { 30,   0}
TokenModule.basePos.large.Stress    = { 30, -30}
TokenModule.basePos.large.Tractor   = {-30,  30}
TokenModule.basePos.large.Ion       = {-30,   0}
TokenModule.basePos.large.Lock      = {  0,  30}
TokenModule.basePos.large.rest      = {-30, -30}
TokenModule.nearPos = {}
TokenModule.nearPos.small = {}
TokenModule.nearPos.small.Focus     = { 35,  25}
TokenModule.nearPos.small.Evade     = { 35,   0}
TokenModule.nearPos.small.Stress    = { 35, -25}
TokenModule.nearPos.small.Ion       = {-35,  25}
TokenModule.nearPos.small.Tractor   = {-35,   0}
TokenModule.nearPos.small.Lock      = {  0,  40}
TokenModule.nearPos.small.rest      = {-35, -25}
TokenModule.nearPos.large = {}
TokenModule.nearPos.large.Focus     = { 55,  30}
TokenModule.nearPos.large.Evade     = { 55,   0}
TokenModule.nearPos.large.Stress    = { 55, -30}
TokenModule.nearPos.large.Tractor   = {-55,  45}
TokenModule.nearPos.large.Ion       = {-55,  15}
TokenModule.nearPos.large.Weapons   = {-55, -15}
TokenModule.nearPos.large.Lock      = {  0,  50}
TokenModule.nearPos.large.rest      = {-55, -45}

TokenModule.tokenPos = function(tokenName, ship, posTable)
    local baseSize = DB_getBaseSize(ship)
    local entry = posTable[baseSize].rest
    for tokenEntryName, tEntry in pairs(posTable[baseSize]) do
        if tokenName:find(tokenEntryName) ~= nil then
            entry = tEntry
        end
    end
    local tsPos = {Convert_mm_igu(entry[1]), 0.5, Convert_mm_igu(entry[2])}
    return Vect_Sum(ship.getPosition(), Vect_RotateDeg(tsPos, ship.getRotation()[2]+180))
end

TokenModule.BasePosition = function(tokenName, ship)
    local name = nil
    if type(tokenName) == 'string' then
            name = tokenName
    elseif type(tokenName) == 'userdata' then
        name = tokenName.getName()
    else
        print('fill me pls1')
    end
    return TokenModule.tokenPos(name, ship, TokenModule.basePos)
end
TokenModule.NearPosition = function(tokenName, ship)
    local name = nil
    if type(tokenName) == 'string' then
            name = tokenName
    elseif type(tokenName) == 'userdata' then
        name = tokenName.getName()
    else
        print('fill me pls2')
    end
    return TokenModule.tokenPos(name, ship, TokenModule.nearPos)
end

TokenModule.VisiblePosition = function(tokenName, ship)
    local currTokensInfo = TokenModule.GetShipTokensInfo(ship)
    local currStack = {qty=-2, obj=nil}
    for k,tokenInfo in pairs(currTokensInfo) do
        if tokenInfo.token.getName() == tokenName and tokenInfo.token.getQuantity() > currStack.qty then
            currStack.obj = tokenInfo.token
            currStack.qty = currStack.obj.getQuantity()
        end
    end
    if currStack.obj ~= nil then
        return Vect_Sum(currStack.obj.getPosition(), {0, 0.7, 0})
    end
    local nearPos = TokenModule.NearPosition(tokenName, ship)
    local nearData = TokenModule.TokenOwnerInfo(nearPos)
    if nearData.margin < TokenModule.visibleMargin then
        return TokenModule.BasePosition(tokenName, ship)
    else
        return nearPos
    end
end

TokenModule.TokenOwnerInfo = function(tokenPos)
    local pos = nil
        local out = {token=nil, owner=nil, dist=0, margin=-1}
    if type(tokenPos) == 'table' then
        pos = tokenPos
    elseif type(tokenPos) == 'userdata' then
        out.token = tokenPos
        pos = tokenPos.getPosition()
    else
        print('fill me pls')
    end
    local nearShips = XW_ObjWithinDist(pos, TokenModule.tokenReachDistance, 'ship')
    if nearShips[1] == nil then return out end
    local baseDist = {}
    -- Take the base size into account for distances
    for k,ship in pairs(nearShips) do
        local realDist = Dist_Pos(pos, ship.getPosition())
        if DB_isLargeBase(ship) == true then realDist = realDist-Convert_mm_igu(10) end
        table.insert(baseDist, {ship=ship, dist=realDist})
    end
    local nearest = {ship=nil, dist=999}
    local nextNearest = {ship=nil, dist=999}
    for k,data in pairs(baseDist) do
        if data.dist < nearest.dist then
            nextNearest = nearest
            nearest = data
        elseif data.dist < nextNearest.dist then
            nextNearest = data
        end
    end
    out.owner = nearest.ship
    out.dist = nearest.dist
    if nextNearest.ship == nil then
        out.margin = 999
        print('ja jebie')
    else
        out.margin = (nextNearest.dist-nearest.dist)/2
    end
    return out
end

TokenModule.GetNearTokensInfo = function(pos, dist)
    local nearTokens = XW_ObjWithinDist(pos, TokenModule.tokenReachDistance, 'token')
    local shipTokensInfo = {}
    for k,token in pairs(nearTokens) do
        local tokenInfo = TokenModule.TokenOwnerInfo(token)
        table.insert(shipTokensInfo, tokenInfo)
    end
    return shipTokensInfo
end

TokenModule.GetShipTokensInfo = function(ship)
    -- Check for nearby tokens
    local nearTokens = XW_ObjWithinDist(ship.getPosition(), TokenModule.tokenReachDistance, 'token')
    local shipTokensInfo = {}
    for k,token in pairs(nearTokens) do
        local tokenInfo = TokenModule.TokenOwnerInfo(token)
        if tokenInfo.owner == ship then
            table.insert(shipTokensInfo, tokenInfo)
        end
    end
    return shipTokensInfo
end

TokenModule.GetShipTokens = function(ship)
    -- Check for nearby tokens
    local shipTokensInfo = TokenModule.GetShipTokensInfo(ship)
    local tokens = {}
    for k,tokenInfo in pairs(shipTokensInfo) do
        table.insert(tokens, tokenInfo.token)
    end
end

TokenModule.MoveOnBase = function(token, ship)

end

TokenModule.ClearPosition = function(pos, dist)
    local posTokenInfo = nil

end

-- Perform move designated by move_code on a ship
-- For some moves (like barrel rolls) collisons are automatically ignored, rest considers them normally
-- Includes token handling so nothing obscurs the final position
-- Starts the wait coroutine that handles stuff done when ship settles down
MoveModule.PerformMove = function(move_code, ship, ignoreCollisions)

    local info = MoveData.DecodeInfo(move_code, ship)
    local finData = MoveModule.GetFinalPos(move_code, ship, ignoreCollisions)
    local annInfo = {type=finData.finType, note=info.note, code=info.code}
    if finData.finType == 'overlap' then
        annInfo.note = info.collNote
        print('---- chuja')
    elseif finData.finType == 'slide' then
        print('---- Dobry slajd: ' .. '"' .. move_code .. '[' .. math.round(finData.finPart) .. ']"')
        local finPos = finData.finPos
        ship.setPosition(finPos.pos)
        ship.setRotation(finPos.rot)
        MoveModule.AddHistoryEntry(ship, {pos=finPos.pos, rot=finPos.rot, move=move_code, part=finData.finPart}, true)
    elseif finData.finType == 'move' then
        local finPos = finData.finPos
        ship.setPosition(finPos.pos)
        ship.setRotation(finPos.rot)
        if finData.collObj == nil then
            print('---- Dobry move: ')
        else
            print('---- Move kolizja: ' .. finData.collObj.getName())
            annInfo.note = info.collNote
            annInfo.collidedShip = finData.collObj
        end
    else
        print('???? Dziwne rzeczy')
        print(finData.finType)
    end

    MoveModule.Announce(ship, annInfo, 'all')

    XW_cmd.SetReady(ship)
    --[[local finPos = nil
    local info = MoveData.DecodeInfo(move_code, ship)

    -- Don't bother with collisions if it's stationary
    if info.speed == 0 then
        ignoreCollisions = true
    end


    if ignoreCollisions ~= true then
        -- LET THE SPAGHETTI FLOW!
        -- Check move length so we can relate how far some part of a move will take us
        local moveLength = MoveData.MoveLength(info)
        --moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        --moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
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
        local ships = XW_ObjWithinDist(MoveModule.GetPartMove(move_code, ship, MoveData.partMax/2).pos, moveLength+(2*maxShipReach), 'ship')
        for k, collShip in pairs(ships) do if collShip == ship then table.remove(ships, k) end end

        -- Let's try collisions at the end of a move
        local finalInfo = MoveModule.CheckCollisions(ship, MoveModule.GetFullMove(move_code, ship), ships)

        -- (if there will be collisions) we will start with maximum part of a move (ending position)
        local actPart = MoveData.partMax
        if finalInfo.coll ~= nil then
            -- There was a collision!
            local checkNum = 0 -- this is just to see how efficient stuff is
            local collision = false

            -- First, we will check collisions every 1/100th of a move
            -- BUT WITH A CATCH
            local partDelta = -1*(MoveData.partMax/100)
            repeat
                local nPos = MoveModule.GetPartMove(move_code, ship, actPart)
                local collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                local distToSkip = nil
                if collInfo.coll ~= nil then
                    collision = true
                    distToSkip = collInfo.minMargin
                    -- If there is a distance we can travel that assures collison will not end
                    if distToSkip > 0 then
                        -- Calculate how big part it is and skip away!
                        -- This saves A LOT of iterations, for real
                        partDelta = -1*((distToSkip * MoveData.partMax)/moveLength)
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
            partDelta = (1/1000)*MoveData.partMax
            local collInfo
            repeat
                local nPos = MoveModule.GetPartMove(move_code, ship, actPart)
                collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                if collInfo.coll ~= nil then collision = true
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
            until (collision == true and collInfo.coll == info.collidedShip) or actPart > MoveData.partMax
            actPart = actPart - partDelta
            info.collidedShip = collInfo.coll -- This is what we hit
        end

        -- We get the final position as a calculated part or as a full move if ignoring collisions
        finPos = MoveModule.GetPartMove(move_code, ship, actPart)
    else
        finPos = MoveModule.GetFullMove(move_code, ship)
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

    -- Bump notification button
    Ship_RemoveOverlapReminder(ship)
    if info.collidedShip ~= nil then
        MoveModule.SpawnOverlapReminder(ship)
    end

    -- Get the ship in a queue to do stuff once resting
    table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove=move_code})
    startLuaCoroutine(Global, 'restWaitCoroutine')]]--
end

-- Spawn a 'BUMPED' informational button on the base that removes itself on click
-- TO_DO: Some non-obscuring way to indicate that?
MoveModule.SpawnOverlapReminder = function(ship)
    Ship_RemoveOverlapReminder(ship)
    --remindButton = {click_function = 'Ship_RemoveOverlapReminder', label = 'B\nU\nM\nP', rotation =  {0, 0, 0}, width = 200, height = 1100, font_size = 200}
    remindButton = {click_function = 'Ship_RemoveOverlapReminder', label = 'BUMPED', rotation =  {0, 0, 0}, width = 1000, height = 350, font_size = 250}
    if DB_isLargeBase(ship) == true then
        remindButton.position = {0, 0.2, 2}
    else
        remindButton.position = {0, 0.3, 0.8}
        --remindButton.position = {-1, 0.25, 0}
    end
    ship.createButton(remindButton)
end

-- Removes 'BUMPED' button from ship (click function)
function Ship_RemoveOverlapReminder(ship)
    local buttons = ship.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do if but.label == 'BUMPED' then ship.removeButton(but.index) end end
    end
end

-- Check which ship has it's base closest to position (large ships have large bases!), thats the owner
--  also check how far it is to the owner-changing position (out margin of safety)
-- Kinda tested: margin > 20mm = visually safe
MoveModule.GetTokenOwner = function(tokenPos)
    local out = {owner=nil, dist=0, margin=-1}
    local nearShips = XW_ObjWithinDist(tokenPos, Convert_mm_igu(120), 'ship')
    if nearShips[1] == nil then return out end
    local baseDist = {}
    -- Take the base size into account for distances
    for k,ship in pairs(nearShips) do
        local realDist = Dist_Pos(tokenPos, ship.getPosition())
        if DB_isLargeBase(ship) == true then realDist = realDist-Convert_mm_igu(10) end
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
            infoTable.relRot = token.getRotation()[2] - ship.getRotation()[2]
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
MoveModule.AnnounceColor.warn = {1, 0.25, 0.05}        -- Red - orange
MoveModule.AnnounceColor.info = {0.6, 0.1, 0.6}        -- Purple

MoveModule.ActiveLogs = {}
MoveModule.ActiveLogs['R-G'] = {}
MoveModule.ActiveLogs['T-B'] = {}
MoveModule.SkipChat = {}
MoveModule.SkipChat['R-G'] = false
MoveModule.SkipChat['T-B'] = false

function EventLogDropped(infoTable)
    if infoTable[1].getVar('idTag') == 'XW_set' then return end
    local side = 'R-G'
    if infoTable[2] < 0 then side = 'T-B' end
    table.insert(MoveModule.ActiveLogs[side], infoTable[1])
    infoTable[1].setVar('idTag', 'XW_set')
    if #MoveModule.ActiveLogs[side] >= 2 then MoveModule.SkipChat[side] = true end
    local logName = 'Event Log ('
    if side == 'R-G' then logName = logName .. 'Red - Green)'
    else logName = logName .. 'Teal - Blue)' end
    return logName
end

MoveModule.ObjDestroyedHandle = function(obj)
    for k,log in pairs(MoveModule.ActiveLogs['R-G']) do
        if log == obj then
            table.remove(MoveModule.ActiveLogs['R-G'], k)
            if #MoveModule.ActiveLogs['R-G'] < 2 then MoveModule.SkipChat['R-G'] = false end
        end
    end
    for k,log in pairs(MoveModule.ActiveLogs['T-B']) do
        if log == obj then
            table.remove(MoveModule.ActiveLogs['T-B'], k)
            if #MoveModule.ActiveLogs['T-B'] < 2 then MoveModule.SkipChat['T-B'] = false end
        end
    end
end

MoveModule.LogMessage = function(messString, messColor, groupID, side)
    for k,log in pairs(MoveModule.ActiveLogs[side]) do
        log.call('API_AddNewMessage', {text = messString, color=messColor, groupID=groupID})
    end
end

-- Notify color or all players of some event
-- Info: {ship=shipRef, info=announceInfo, target=targetStr}
-- announceInfo: {type=typeOfEvent, note=notificationString}
MoveModule.Announce = function(ship, info, target, prefix)
    local annString = ''
    local annColor = {1, 1, 1}
    local shipName = ''

    if ship == nil then return end

    local eventSide = nil
    if ship.getPosition()[1] > 0 then eventSide = 'R-G'
    else eventSide = 'T-B' end

    if prefix ~= false then
        shipName = ship.getName() .. ' '
    end
    if info.type == 'move' or info.type == 'slide' then
        if info.collidedShip == nil then
            annString = shipName .. info.note .. ' (' .. info.code .. ')'
            annColor = MoveModule.AnnounceColor.moveClear
        else
            annString = shipName .. info.note .. ' (' .. info.code .. ') but is now touching ' .. info.collidedShip.getName()
            annColor = MoveModule.AnnounceColor.moveCollision
        end
    elseif info.type == 'overlap' then
        annString = shipName .. info.note .. ' (' .. info.code .. ') but there was no space to complete the move'
        annColor = MoveModule.AnnounceColor.moveCollision
    elseif info.type == 'historyHandle' then
        annString = shipName .. info.note
        annColor = MoveModule.AnnounceColor.historyHandle
    elseif info.type == 'action' then
        annString = shipName .. info.note
        annColor = MoveModule.AnnounceColor.action
    elseif info.type:find('error') ~= nil then
        annString = shipName .. info.note
        annColor = MoveModule.AnnounceColor.error
    elseif info.type:find('warn') ~= nil then
        annString = shipName .. info.note
        annColor = MoveModule.AnnounceColor.warn
    elseif info.type:find('info') ~= nil then
        annString = shipName .. info.note
        annColor = MoveModule.AnnounceColor.info
    end

    if target == 'all' then
        local id = ship.getGUID()
        MoveModule.LogMessage(annString, annColor, id, eventSide)
        if MoveModule.SkipChat[eventSide] ~= true then
            printToAll(annString, annColor)
        end
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
XW_cmd.AddCommand('cd', 'dialHandle')

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
    local hadDials = false
    for k, set in pairs(DialModule.ActiveSets) do
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
    end
    if hadDials == false then MoveModule.Announce(ship, {type='info_DialModule', note='had no assigned dials'}, 'all') end
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
            actSet.dialSet[k] = newDialData
        end
    else
        table.insert(DialModule.ActiveSets, {ship=ship, activeDial=nil, dialSet=set})
        ship.setVar('DialModule_hasDials', true)
    end
end

-- Distance (circle from ship) at wchich dials can be to be registered
saveNearbyCircleDist = Convert_mm_igu(160)

-- Save nearby dials layout
-- Detects layout center (straight dials as reference) and assigns dials that are appropriately placed
-- If dials are already assigned to this ship, they are ignored
-- If one of dials is assigned to other ship, unassign and proceed
DialModule.SaveNearby = function(ship, onlySpawnGuides)
    local nearbyDialsAll = XW_ObjWithinDist(ship.getPosition(), saveNearbyCircleDist, 'dial')
    -- Nothing nearby
    if nearbyDialsAll[1] == nil then
        MoveModule.Announce(ship, {type='info_DialModule', note=('has no valid dials nearby')}, 'all')
        return
    end
    -- Filter dials to only get ones of uniue description
    -- If there are duplicate dials, save closer ones
    local positionWarning = false
    local nearbyDialsUnique = {}
    for k,dial in pairs(nearbyDialsAll) do
        if math.abs(dial.getPosition()[3]) < 24 then positionWarning = true end
        -- Warn if dial command is invalid (changed most likely)
        if XW_cmd.CheckCommand(dial.getDescription()) ~= 'move' then
            MoveModule.Announce(ship, {type='error_DialModule', note=('One of the dials near ' .. ship.getName() .. ' has an unsupported command in the description (\'' .. dial.getDescription() .. '\'), make sure you only select the ship when inserting \'sd\'/\'cd\'')}, 'all', false)
            return
        end
        if nearbyDialsUnique[dial.getDescription()] ~= nil then
            if Dist_Obj(ship, dial) < Dist_Obj(ship, nearbyDialsUnique[dial.getDescription()]) then
                nearbyDialsUnique[dial.getDescription()] = dial
            end
        else
            nearbyDialsUnique[dial.getDescription()] = dial
        end
    end
    -- Warn if some dials are outside hidden zones
    if positionWarning == true then
        MoveModule.Announce(ship, {type='warn_DialModule', note=('Some dials ' .. ship.getName() .. ' is trying to save are placed outside the hidden zones!')}, 'all', false)
    end
    local refDial1 = nil -- reference dial with a straight, speed X move
    local refDial2 = nil -- reference dial with a straight, speed X+1 move
    -- Detect reference dials
    for k, dial in pairs(nearbyDialsUnique) do
        refDial1 = dial
        local move = dial.getDescription():sub(1, -2)
        local speed = tonumber(dial.getDescription():sub(-1, -1))
        if move == 's' and speed ~= nil then
            if nearbyDialsUnique[move .. (speed+1)] ~= nil then
                refDial2 = nearbyDialsUnique[move .. (speed+1)]
                break
            end
        end
    end
    -- If tow reference dials were not found (there;s no straight and 1 speed faster straight nearby)
    if refDial2 == nil then
        MoveModule.Announce(ship, {type='warn_DialModule', note=('needs to be moved closer to the dial layout center')}, 'all')
        return
    end
    -- Distance between any adjacent dials (assuming a regular grid)
    local dialSpacing = math.abs(refDial1.getPosition()[3] - refDial2.getPosition()[3])
    -- If distance between two dials appears to be huge
    if dialSpacing > Convert_mm_igu(120) then
        MoveModule.Announce(ship, {type='error_DialModule', note=('Dial layout nearest to ' .. ship.getName() .. ' seems to be invalid or not laid out on a proper grid (check dials descriptions)')}, 'all', false)
        return
    end
    -- Determine center of the dial layout (between s2 and s3 dials)
    local refSpeed = tonumber(refDial1.getDescription():sub(-1,-1))
    local centerOffset = 2.5 - refSpeed
    local z_half = refDial1.getPosition()[3]/math.abs(refDial1.getPosition()[3])
    centerOffset = centerOffset * z_half * -1
    local centerPos = {refDial1.getPosition()[1], refDial1.getPosition()[2], refDial1.getPosition()[3] + (centerOffset * dialSpacing)}
    -- Place the ship in the center and spawn assignment guides
    local straightRot = 180
    if z_half > 0 then straightRot = 0 end
    ship.setPositionSmooth(Vect_Sum(centerPos, {0, 1, 0}), false, true)
    ship.setRotationSmooth({0, straightRot, 0}, false, true)
    local zoneWidth = 5*dialSpacing
    local zoneHeight = 6*dialSpacing
    -- Check if dials in the depicted zone are all unique
    local layoutDials = XW_ObjWithinRect(centerPos, zoneWidth, zoneHeight, 'dial')
    local layoutDialsUnique = {}
    for k,dial in pairs(layoutDials) do
        if layoutDialsUnique[dial.getDescription()] == nil then
            layoutDialsUnique[dial.getDescription()] = dial
        else
            MoveModule.Announce(ship, {type='error_DialModule', note=('Dial layout nearest to ' .. ship.getName() .. ' seems to be invalid or overlapping another layout (check dials descriptions)')}, 'all', false)
            return
        end
    end
    if onlySpawnGuides == true then
        DialModule.SpawnLayoutZoneGuides(ship, zoneWidth, zoneHeight)
        MoveModule.Announce(ship, {type='info_DialModule', note=('would have dials from the depicted zone assigned using the \'sd\' command')}, 'all')
        return
    end
    -- There is a valid set nearby!
    local conqueredDials = {}
    local nearbyDials = {}
    for k,dial in pairs(layoutDials) do
        -- If a dial is already assigned, unassign if it belongs to another ship
        -- Ingore if it's this ship
        if DialModule.isAssigned(dial) == true then
            if dial.getVar('assignedShip') ~= ship then
                local prevOwner = dial.getVar('assignedShip')
                DialModule.UnassignDial(dial)
                table.insert(nearbyDials, dial)
                if conqueredDials[prevOwner] == nil then
                    conqueredDials[prevOwner] = {}
                end
                table.insert(conqueredDials[prevOwner], dial)
            end
        else
            table.insert(nearbyDials, dial)
        end
    end
    for poorShip, takenDials in pairs(conqueredDials) do
        local dialsStr = ' ('
        for k, dial in pairs(takenDials) do
            dialsStr = dialsStr .. dial.getDescription() .. ', '
        end
        dialsStr = dialsStr:sub(1, -3)
        dialsStr = dialsStr .. ') '
        MoveModule.Announce(ship, {type='warn_DialModule', note=('assigned' .. dialsStr ..  'dial(s) that previously belonged to ' .. poorShip.getName())}, 'all')
    end

    -- If there are no filtered (not this ship already) dials
    if nearbyDials[1] == nil then
        MoveModule.Announce(ship, {type='info_DialModule', note=('already has all nearby dials assigned')}, 'all')
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
        dialInfo.dial.highlightOn({0, 1, 0}, 5)
    end
    DialModule.AddSet(ship, dialSet)
    MoveModule.Announce(ship, {type='info_dialModule', note='had ' .. dialCount .. ' dials assigned (' .. DialModule.DialCount(ship) .. ' total now)' }, 'all')
end

-- Spawn a rectangle zone depiction centered over the ship with appropriate size
-- Size is in world units and ship scale does not matter
DialModule.SpawnLayoutZoneGuides = function(ship, width, height)
    LayoutGuides_Remove(ship)
    local shipScale = ship.getScale()[1]
    local zoneLUpos = Vect_Scale({width/2, 0.1, height/2}, 1/shipScale)
    local zoneLLpos = Vect_Scale({-1*width/2, 0.1, height/2}, 1/shipScale)
    local zoneRUpos = Vect_Scale({width/2, 0.1, -1*height/2}, 1/shipScale)
    local zoneRLpos = Vect_Scale({-1*width/2, 0.1, -1*height/2}, 1/shipScale)
    ship.createButton({position=zoneLUpos, rotation={0, 0, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneLUpos, rotation={0, 90, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneLLpos, rotation={0, 0, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneLLpos, rotation={0, 90, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneRUpos, rotation={0, 0, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneRUpos, rotation={0, 90, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneRLpos, rotation={0, 0, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    ship.createButton({position=zoneRLpos, rotation={0, 90, 0}, label='', height=80, width=1000, click_function='dummy', function_owner=Global})
    deleteButton = {click_function = 'LayoutGuides_Remove', label = 'REMOVE', rotation =  {0, 0, 0}, width = 1500, height = 450, font_size = 300}
    if DB_isLargeBase(ship) == true then
        deleteButton.position = {0, 0.2, 2.5}
    else
        deleteButton.position = {0, 0.3, 1}
    end
    ship.createButton(deleteButton)
end

function LayoutGuides_Remove(ship)
    local buttons = ship.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do if but.label == '' or but.label == 'REMOVE' then ship.removeButton(but.index) end end
    end
end

-- Unassign this dial from any sets it is found in
-- Could check what ship set this is first, but it's more reliable this way
DialModule.UnassignDial = function(dial)
    for k,set in pairs(DialModule.ActiveSets) do
        local filteredSet = {}
        local changed = false
        for k2,dialInfo in pairs(set.dialSet) do
            if dialInfo.dial == dial then
                dialInfo.dial.setVar('assignedShip', nil)
                dialInfo.dial.clearButtons()
                ClearButtonsPatch(dialInfo.dial)
                changed = true
            else
                filteredSet[k2]=dialInfo
            end
        end
        if set.activeDial ~= nil and set.activeDial.dial == dial then set.activeDial = nil end
        if changed == true then set.dialSet = filteredSet end
        local empty = true
        if set.dialSet ~= nil then
            for k2,dialInfo in pairs(set.dialSet) do empty = false break end
        end
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
-- TO_DO: Replace other checks with this, maybe ckeck sets to be sure too?
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
        -- Unassign deleted dial
    elseif obj.tag == 'Card' and obj.getDescription() ~= '' then
        if DialModule.isAssigned(obj) then DialModule.UnassignDial(obj) end
    elseif obj.getName() == 'Target Lock' then
        for k,lockInfo in pairs(DialModule.locksToBeSet) do
            if lockInfo.lock == obj then table.remove(DialModule.locksToBeSet, k) break end
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


-- Update token sources on each load
-- Restore sets if data is loaded
DialModule.onLoad = function(saveTable)
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
DialModule.PerformAction = function(ship, type, playerColor)
    local tokenActions = ' Focus Evade Stress Target Lock '
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
                custom.mesh = 'http://pastebin.com/raw/sZkuCV8a'
                custom.collider = 'http://pastebin.com/raw/zucpQryb'
                scale = {0.623, 0.623, 0.623}
            else
                custom.mesh = 'http://pastebin.com/raw/p3cjDpBk'
                custom.collider = 'http://pastebin.com/raw/5G8JN2B6'
                scale = {0.629, 0.629, 0.629}
            end
            newRuler.setCustomObject(custom)
            newRuler.lock()
            newRuler.setScale(scale)
            local button = {click_function = 'Ruler_SelfDestruct', label = 'DEL', position = {0, 0.5, 0}, rotation =  {0, 0, 0}, width = 900, height = 900, font_size = 250}
            newRuler.createButton(button)
            table.insert(DialModule.SpawnedRulers, {ruler=newRuler, ship=ship})
            announceInfo.note = 'spawned a ruler'
        end
    elseif type == 'spawnMoveTemplate' then
        print('temp')
    elseif type == 'unstress' then
        local stressInfo = {token=nil, dist=-1}
        for k,tokenInfo in pairs(TokenModule.GetShipTokensInfo(ship)) do
            if tokenInfo.token.getName() == 'Stress' and tokenInfo.dist > stressInfo.dist then
                stressInfo.token = tokenInfo.token
            end
        end
        if stressInfo.token == nil then
            announceInfo.note = 'tried to shed a stress but doesn\'t have any'
        else
            announceInfo.note = 'sheds a stress token'
            if stressInfo.token.getQuantity() > 0 then
                stressInfo.token = stressInfo.token.takeObject({})
            end
            stressInfo.token.highlightOn({0, 0.7, 0}, 3)
            stressInfo.token.setPositionSmooth(Vect_Sum(TokenModule.tokenSources.Stress.src.getPosition(), {0, 2, 0}))
        end
    elseif tokenActions:find(' ' .. type .. ' ') ~= nil then
        local dest = TokenModule.VisiblePosition(type, ship)
        local newToken = TokenModule.TakeToken(type, playerColor, dest)
        if type == 'Target Lock' then
            table.insert(TokenModule.locksToBeSet, {lock=newToken, name=ship.getName(), color=playerColor})
            announceInfo.note = 'acquired a target lock'
        else
            if type == 'Evade' then
                announceInfo.note = 'takes an evade token'
            else
                announceInfo.note = 'takes a ' .. string.lower(type) .. ' token'
            end
        end
    end
    MoveModule.Announce(ship, announceInfo, 'all')
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
    if XW_cmd.Process(actShip, dial.getDescription()) == true then
        DialModule.SwitchMainButton(dial, 'undo')
    end
end
function DialClick_Undo(dial)
    if XW_cmd.Process(dial.getVar('assignedShip'), 'q') == true then
        DialModule.SwitchMainButton(dial, 'move')
    end
end
function DialClick_Focus(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'Focus')
end
function DialClick_Evade(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'Evade')
end
function DialClick_Stress(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'Stress')
end
function DialClick_Unstress(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'unstress')
end
function DialClick_TargetLock(dial, playerColor)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'Target Lock', playerColor)
end
function DialClick_SpawnMoveTemplate(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'spawnMoveTemplate')
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
function DialClick_ToggleMainExpanded(dial)
    local befMove = false
    for k,but in pairs(dial.getButtons()) do
        if but.label == 'Move' then befMove = true end
    end
    if DialModule.GetMainButtonsState(dial) ~= 2 then
        DialModule.SetMainButtonsState(dial, 2)
    else
        if befMove == true then DialModule.SetMainButtonsState(dial, 0)
        else DialModule.SetMainButtonsState(dial, 1) end
    end
end
function DialClick_ToggleInitialExpanded(dial)
    if DialModule.GetInitialButtonsState(dial) == 0 then
        DialModule.SetInitialButtonsState(dial, 1)
    else
        DialModule.SetInitialButtonsState(dial, 0)
    end
end
function DialClick_SlideStart(dial, playerColor)
    if dial.getVar('Slide_ongoing') == true then
        dial.setVar('Slide_ongoing', false)
    else
        local ship = dial.getVar('assignedShip')
        if XW_cmd.isReady(ship) ~= true then return end
        local lastMove = MoveModule.GetLastMove(ship)
        print('DialClick_SlideStart lastMove.move: ' .. lastMove.move)
        if lastMove.part ~= nil and MoveData.IsSlideMove(lastMove.move) then
            dial.setVar('Slide_ongoing', true)
            local slideRange = DialModule.GetSlideRange(ship, lastMove.move, lastMove.part)
            table.insert(DialModule.slideDataQueue, {dial=dial, ship=ship, pColor=playerColor, range=slideRange})
            MoveModule.QueueShipTokensMove(ship)
            XW_cmd.SetBusy(ship)
            MoveModule.Announce(ship, {type='move', note='manually adjusted base slide on his last move', code=lastMove.move}, 'all')
            startLuaCoroutine(Global, 'SlideCoroutine')
        elseif lastMove.code == 'manual slide' then
            printToColor(ship.getName() .. ' needs to undo the manual slide before adjusting again', playerColor, {1, 0.5, 0.1})
        else
            printToColor(ship.getName() .. '\'s last move (' .. lastMove.move .. ') does not allow sliding!', playerColor, {1, 0.5, 0.1})
        end
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
DialModule.Buttons.shedStress = {label = '-', click_function='DialClick_Unstress', height=500, width=200, position={0.53, 0.5, 0}, font_size=250}
DialModule.Buttons.evade = {label = 'E', click_function='DialClick_Evade', height=500, width=200, position={0.9, 0.5, 1}, font_size=250}
DialModule.Buttons.toggleMainExpanded = {label = 'A', click_function='DialClick_ToggleMainExpanded', height=500, width=200, position={-0.9, 0.5, 0}, font_size=250}
DialModule.Buttons.moveTemplate = {label = 'T', click_function='DialClick_SpawnMoveTemplate', height=500, width=200, position={-0.53, 0.5, 0}, font_size=250}
DialModule.Buttons.toggleInitialExpanded = {label = 'A', click_function='DialClick_ToggleInitialExpanded', height=500, width=200, position={0.9, -0.5, 1}, rotation={180, 180, 0}, font_size=250}
DialModule.Buttons.undo = {label = 'Q', click_function='DialClick_Undo', height=500, width=200, position={-0.9, 0.5, -1}, font_size=250}
DialModule.Buttons.nameButton = function(ship)
    local shortName = DialModule.GetShortName(ship)
    local nameWidth = 900
    local len = string.len(shortName)
    if len*150 > nameWidth then nameWidth = len*150 end
    return {label=shortName, click_function='dummy', height=300, width=nameWidth, position={0, -0.5, -1}, rotation={180, 180, 0}, font_size=250}
end
DialModule.Buttons.nameButtonLifted = function(ship)
    local regularButton = DialModule.Buttons.nameButton(ship)
    regularButton.position[3] = regularButton.position[3]-2.2
    return regularButton
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
DialModule.Buttons.slide = {label='Slide', click_function='DialClick_SlideStart', height=250, width=1600, position={2.5, 0.5, 0}, font_size=250, rotation={0, 90, 0}}

DialModule.Buttons.FlipVersion = function(buttonEntry)
    --print('Flip: ' .. buttonEntry.label)
    local out = Lua_ShallowCopy(buttonEntry)
    if out.rotation == nil then out.rotation = {0, 0, 0} end
    out.rotation = {out.rotation[1]+180, out.rotation[2]+180, out.rotation[3]}
    out.position = {-1*out.position[1], -2*out.position[2], out.position[3]}
    return out
end

-- DELETE THIS BEFORE RELEASE
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Get slide range of a ship based on his last move
-- Return: {fLen=howMuchForwardCanSlide, bLen=howMuchBackwardCanSlide}
-- Return nil if last move doesn't allow slides
DialModule.GetSlideRange = function(ship, moveCode, currPart)
    local info = MoveData.DecodeInfo(moveCode, ship)
    local fullLength = Convert_mm_igu(MoveData.SlideLength(info))
    local travelledLength = (currPart/MoveData.partMax)*fullLength
    return {fLen = fullLength - travelledLength, bLen = travelledLength}
end

-- Table with data slide coroutines pop and process
-- Entry: {dial=dialRef, ship=shipRef, pColor=playerColor, range={fLen=forwardLength, bLen=backwardLength}}
DialModule.slideDataQueue = {}

function SlideCoroutine()
    if #DialModule.slideDataQueue < 1 then
        return 1
    end
    -- Save data from last element of queue, pop it
    local dial = DialModule.slideDataQueue[#DialModule.slideDataQueue].dial
    local ship = DialModule.slideDataQueue[#DialModule.slideDataQueue].ship
    local pColor = DialModule.slideDataQueue[#DialModule.slideDataQueue].pColor
    local range = DialModule.slideDataQueue[#DialModule.slideDataQueue].range
    table.remove(DialModule.slideDataQueue)
    broadcastToColor(ship.getName() .. '\'s slide adjust started!', pColor, {0.5, 1, 0.5})
    local initShipPos = ship.getPosition()
    local shipRot = ship.getRotation()[2]+180
    -- Position of the ship on most-backward slide
    local zeroShipPos = Vect_Sum(initShipPos, Vect_RotateDeg({0, 0, -1*range.bLen}, shipRot))
    -- Slide vector, adding it to zeroShipPos gives us position on most-forward slide
    local tranVect = Vect_RotateDeg({0, 0, range.fLen + range.bLen}, shipRot)

    -- Ships that can collide with sliding one
    local collShips = {}
    local shipCollRange = nil
    -- Since we'll be doing collision checks every frame, aggresively filter out duplicate ships
    local uniqueFilter = {}
    uniqueFilter[ship.getGUID()] = true
    if DB_isLargeBase(ship) then
        shipCollRange = mm_largeBase/2
    else
        shipCollRange = mm_smallBase/2
    end
    -- Range = (large ship radius + current ship radius)*1.05 -- so it covers every ship
    --   a collision is possible with
    -- May be not enough for super long slides (for now its OK)
    local totalCollRange = ((Convert_mm_igu((mm_largeBase/2)*math.sqrt(2)))+Convert_mm_igu(shipCollRange*math.sqrt(2)))*1.05
    -- Add ships near zero position
    for k,cShip in pairs(XW_ObjWithinDist(zeroShipPos, totalCollRange, 'ship')) do
        if cShip ~= ship and uniqueFilter[cShip.getGUID()] == nil then
            table.insert(collShips, cShip)
            uniqueFilter[cShip.getGUID()] = true
        end
    end
    -- Add ships near max position
    for k,cShip in pairs(XW_ObjWithinDist(Vect_Sum(zeroShipPos, tranVect), totalCollRange, 'ship')) do
        if uniqueFilter[cShip.getGUID()] == nil then
            table.insert(collShips, cShip)
            uniqueFilter[cShip.getGUID()] = true
        end
    end

    -- Get a "measurement" based on sliding player cursor position
    -- Dial scale invariant
    -- Return: {shift=forwardCursorSway, sideslip=sidewaysCursorSway}
    -- Shift and sideslip are measured from the button center
    local function getPointerOffset(dial, pColor)
        local sPos = dial.getPosition()
        local pPos = Player[pColor].getPointerPosition()
        local syRot = dial.getRotation()[2]
        local dtp = Vect_Sum(pPos, Vect_Scale(sPos, -1))
        local rdtp = Vect_RotateDeg(dtp, -1*syRot-180)
        local dScale = dial.getScale()[1]
        return {shift=rdtp[3]/dScale, sideslip=(rdtp[1]/dScale - 3.566)}
    end

    -- Set up initial shift offset so user doesn't get a "snap" on imperfect position button click
    -- Also add it if slide is not even forward/backward
    local initShift=getPointerOffset(dial,pColor).shift
    local len = range.fLen + range.bLen
    initShift = initShift + (range.fLen/(range.fLen + range.bLen))*3 - 1.5
    local lastShift = initShift

    -- To skip some checks if we already slid into collision, skip subsequent check
    --  if minimal slide forward/backward would collide
    local blockFwd = false
    local blockBwd = false

    -- SLIDE LOOP
    repeat
        local meas = getPointerOffset(dial, pColor)
        -- Trim the shift offset whenever possible so it eventually goes down to zero
        --  as if user started at center button click
        local adjMeas = meas.shift - initShift
        if initShift ~= 0 then
            if initShift > 0 and adjMeas < -1.5 then
                local takeoff = -1.5 - adjMeas
                initShift = initShift - takeoff
                if initShift < 0 then initShift = 0 end
            elseif initShift < 0 and adjMeas > 1.5 then
                local takeoff = adjMeas - 1.5
                initShift = initShift + takeoff
                if initShift > 0 then initShift = 0 end
            end
        end
        adjMeas = meas.shift - initShift
        --print('RSH: ' .. round(adjMeas, 2) .. ', OFF: ' .. round(initShift, 2) .. ', SS: ' .. round(meas.sideslip, 2))

        -- End if shift or sideslip goes out of bound
        if math.abs(adjMeas) > 3 or math.abs(meas.sideslip) > 2 then
            dial.setVar('Slide_ongoing', false)
        end

        -- Normalize the shift to [0-3] range
        --[[if adjMeas > 1.5 then
            adjMeas = 1.5
        elseif adjMeas < -1.5 then
            adjMeas = -1.5
        end]]--
        adjMeas = Var_Clamp(adjMeas, -1.5, 1.5)
        adjMeas = adjMeas + 1.5

        -- Check for collisions on requested slide position
        local targetPos = Vect_Sum(zeroShipPos, Vect_Scale(tranVect, adjMeas/3))
        local collInfo = MoveModule.CheckCollisions(ship, {pos=targetPos, rot=ship.getRotation()}, collShips)
        if collInfo.coll == nil then
            -- If position is clear, set it
            ship.setPosition(targetPos)
            lastShift = adjMeas
            -- Set the blocking variables to false
            blockFwd = false
            blockBwd = false
        else
            -- If position is obstructed, try to slide the ship towards cursor if possible
            -- Try last clear position + 1/100 towards cursor
            local dirFwd = nil
            if lastShift < adjMeas then
                adjMeas = lastShift + 0.015
                dirFwd = true
            else
                adjMeas = lastShift - 0.015
                dirFwd = false
            end
            if (dirFwd and not blockFwd) or (not dirFwd and not blockBwd) then
                local tryPos = Vect_Sum(zeroShipPos, Vect_Scale(tranVect, adjMeas/3))
                -- Check for collisions there
                collInfo = MoveModule.CheckCollisions(ship, {pos=tryPos, rot=ship.getRotation()}, collShips)
                -- If it is clear, set it
                if collInfo.coll == nil then
                    ship.setPosition(Vect_Sum(zeroShipPos, Vect_Scale(tranVect, adjMeas/3)))
                    lastShift = adjMeas
                else
                    -- Indicate that this sirection is blocked
                    if adjMeas > lastShift then
                        blockFwd = true
                    else
                        blockBwd = true
                    end
                end
            end
        end
        coroutine.yield(0)

        -- This ends if player switches color, ship or dial vanishes or button is clicked setting slide var to false
    until Player[pColor] == nil or ship == nil or dial.getVar('Slide_ongoing') ~= true or dial == nil
    if Player[pColor] ~= nil then broadcastToColor(ship.getName() .. '\'s slide adjust ended!', pColor, {0.5, 1, 0.5}) end
    dial.setVar('Slide_ongoing', false)
    table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove='manual slide'})
    startLuaCoroutine(Global, 'restWaitCoroutine')
    return 1
end

-- Get short name of a ship for dial indication "button"
DialModule.GetShortName = function(ship)
    local shipNameWords = {}
    local numWords = 0
    local ambigNames = 'The Captain Colonel Cartel'
    for word in ship.getName():gmatch('%w+') do table.insert(shipNameWords, word) numWords = numWords+1 end
    for k,w in pairs(shipNameWords) do if w == 'LGS' then table.remove(shipNameWords, k) numWords = numWords-1 end end
    local currWord = 1
    local shipShortName = shipNameWords[1]
    if ambigNames:find(shipShortName) ~= nil then shipShortName = shipNameWords[2] currWord = 2 end
    if shipShortName:len() > 9 and shipNameWords[currWord+1] ~= nil then
        if shipNameWords[currWord+1]:len() > 3 and shipNameWords[currWord+1]:len() < shipShortName:len() then
            shipShortName = shipNameWords[currWord+1]
            currWord = currWord + 1
        end
    end
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
    dialTable.dial.createButton(DialModule.Buttons.toggleInitialExpanded)
end

-- Spawn main buttons on a dial (move, actions, undo) when it is flipped over
DialModule.SpawnMainActiveButtons = function (dialTable)
    dialTable.dial.clearButtons()
    ClearButtonsPatch(dialTable.dial)
    dialTable.dial.createButton(DialModule.Buttons.deleteFaceup)
    dialTable.dial.createButton(DialModule.Buttons.move)
    dialTable.dial.createButton(DialModule.Buttons.moveTemplate)
    dialTable.dial.createButton(DialModule.Buttons.toggleMainExpanded)
end


DialModule.GetInitialButtonsState = function(dial)
    local state = 0
    local buttons = dial.getButtons()
    if buttons == nil then return -1 end
    for k,but in pairs(buttons) do
        if but.label == 'R' then state = 1 end
    end
    return state
end

DialModule.SetInitialButtonsState = function(dial, newState)
    local actShip = dial.getVar('assignedShip')
    local extActionsMatch = ' Br B Bl Xf X Xb TL R F S E Q Slide '  -- labels for buttons of EXTENDED set
    local nameButton = DialModule.Buttons.nameButton(actShip)
    local currentState = DialModule.GetInitialButtonsState(dial)

        print(currentState .. ' -> ' .. newState)
    if newState > currentState then
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.boostS))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.boostR))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.boostL))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollR))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollRF))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollRB))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollL))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollLF))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rollLB))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.ruler))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.targetLock))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.slide))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.focus))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.stress))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.evade))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.undo))
            local buttons = dial.getButtons()
            for k,but in pairs(buttons) do
                if but.label == nameButton.label then
                    dial.removeButton(but.index)
                end
            end
            dial.createButton(DialModule.Buttons.nameButtonLifted(actShip))
        -- if REMOVING buttons
    elseif newState < currentState then
        local buttons = dial.getButtons()
        for k,but in pairs(buttons) do
            if extActionsMatch:find(' ' .. but.label .. ' ') ~= nil or but.label == nameButton.label then
                dial.removeButton(but.index)
            end
        end
        dial.createButton(DialModule.Buttons.nameButton(actShip))
    end
end


-- Check what buttons state the dial is in
-- -1: no buttons, generally should not occur
-- 0: just basic buttons
-- 1: above plus FSEQ buttons
-- 2: above plus boost, rolls, ruler and lock
DialModule.GetMainButtonsState = function(dial)
    local state = 0
    local buttons = dial.getButtons()
    if buttons == nil then return -1 end
    for k,but in pairs(buttons) do
        if but.label == 'F' then if state == 0 then state = 1 end end
        if but.label == 'B' then state = 2 end
    end
    return state
end


-- Adjust button set between states like explained over GetMainButtonsState function
DialModule.SetMainButtonsState = function(dial, newState)
    local standardActionsMatch = ' F S E Q -'           -- labels for buttons of STANDARD set
    local extActionsMatch = ' Br B Bl Xf X Xb TL R Slide '  -- labels for buttons of EXTENDED set

    local currentState = DialModule.GetMainButtonsState(dial)
    if newState > currentState then
        if currentState == 0 then -- BASIC -> STANDARD
            dial.createButton(DialModule.Buttons.focus)
            dial.createButton(DialModule.Buttons.stress)
            dial.createButton(DialModule.Buttons.shedStress)
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
            dial.createButton(DialModule.Buttons.slide)
        end
        -- if REMOVING buttons
    elseif newState < currentState then
        local buttons = dial.getButtons()
        if currentState == 2 then -- remove EXTENDED set ones
            for k,but in pairs(buttons) do
                if extActionsMatch:find(' ' .. but.label .. ' ') ~= nil then dial.removeButton(but.index) end
            end
        end
        if newState == 0 then -- remove STANDARD set ones
            for k,but in pairs(buttons) do
                if standardActionsMatch:find(' ' .. but.label .. ' ') ~= nil then dial.removeButton(but.index) end
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
                if DialModule.GetMainButtonsState(dial) == 0 then
                    DialModule.SetMainButtonsState(dial, 1)
                end
            end
        elseif type == 'move' then
            if but.label == 'Undo' then
                dial.removeButton(but.index)
                dial.createButton(DialModule.Buttons.move)
                if DialModule.GetMainButtonsState(dial) == 1 then
                    DialModule.SetMainButtonsState(dial, 0)
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
    if actSet ~= nil and actSet.ship == ship and actSet.activeDial ~= nil then
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
        if set.dialSet[dial.getDescription()] ~= nil and set.dialSet[dial.getDescription()].dial == dial then
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
    MoveModule.ObjDestroyedHandle(dying_object)
end

-- When table is loaded up, this is called
-- save_state contains everything separate modules saved before to restore table state
-- TO_DO: I swear I wanted to save/load something else too
function onLoad(save_state)
    if save_state ~= '' and save_state ~= nil then
        local savedData = JSON.decode(save_state)
        DialModule.onLoad(savedData['DialModule'])
    end
    MoveData.onLoad()
    TokenModule.onLoad()
end

function onSave()
    local tableToSave = {}
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

function DB_getShipInfo(shipRef)
    if shipRef.getTable('DB_shipInfo') ~= nil then
        return shipRef.getTable('DB_shipInfo')
    end
    local mesh = shipRef.getCustomObject().mesh
    for shipType, typeTable in pairs(shipTypeDatabase) do
        for k2, model in pairs(typeTable.meshes) do
            local ssl_switch_model = ''
            if model:sub(1,5) == 'https' then
                -- http variant
                ssl_switch_model = 'http' .. model:sub(6, -1)
            else
                -- https variant
                ssl_switch_model = 'https' .. model:sub(5, -1)
            end
            if model == mesh or ssl_switch_model == mesh then
                local info = {shipType = shipType, largeBase = typeTable.largeBase, faction = typeTable.faction}
                shipRef.setTable('DB_shipInfo', info)
                return info
            end
        end
    end
    return nil
end
-- Return ship type like it's written on the back of a dial
-- Return 'Unknown' is ship is not in the database
function DB_getShipType(shipRef)
    local shipInfo = DB_getShipInfo(shipRef)
    if shipInfo ~= nil then
        return shipInfo.shipType
    end
    return 'Unknown'
end

-- Return true if large base, false if small
-- First checks database, then LGS in name, warns and treat as small if both fail
function DB_isLargeBase(shipRef)
    local shipInfo = DB_getShipInfo(shipRef)
    if shipInfo ~= nil then
        return shipInfo.largeBase
    end
    if shipRef.getName():find('LGS') ~= nil then
        return true
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

-- Same as above with table argument to allow call from outside Global
function DB_getShipInfoCallable(table)
    return DB_getShipInfo(table[1])
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
    ['X-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/54FLC', 'https://paste.ee/r/eAdkb', 'https://paste.ee/r/hxWah', 'https://paste.ee/r/ZxcTT', 'https://paste.ee/r/FfWNK', 'http://cloud-3.steamusercontent.com/ugc/82591194029070509/ECA794EC4771A195A6EB641226DF1F986041EFFF/', 'http://cloud-3.steamusercontent.com/ugc/82591194029077829/B7E898109E3F3B115DF0D60BB0CA215A727E3F38/', 'http://cloud-3.steamusercontent.com/ugc/82591194029083210/BFF5BAE2A45EC9D647E14D9041140FFE114BF2D4/', 'http://cloud-3.steamusercontent.com/ugc/82591194029107313/95BAD08906334FBA628F6628E5DE2D0D30112A53/', 'http://cloud-3.steamusercontent.com/ugc/82591194029079708/B215C5ADC2F6D83F441BA9C7659C91E3100D3BDC/'}},
    ['Y-Wing Rebel'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/MV6qP', 'http://cloud-3.steamusercontent.com/ugc/82591194029097150/75A486189FEDE8BEEBFBACC0D76DE926CB42E52A/'}},
    ['YT-1300'] = { faction = 'Rebel', largeBase = true, meshes = {'https://paste.ee/r/kkPoB', 'http://pastebin.com/VdHhgdFr', 'http://cloud-3.steamusercontent.com/ugc/82591194029088151/213EF50E847F62BB943430BA93094F1E794E866B/', 'http://pastebin.com/VdHhgdFr'}},
    ['YT-2400'] = { faction = 'Rebel', largeBase = true, meshes = {'https://paste.ee/r/Ff0vZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029079241/206F408212849DCBB3E1934A623FD7A8844AAE47/'}},
    ['A-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/tIdib', 'https://paste.ee/r/mow3U', 'https://paste.ee/r/ntg8n', 'http://cloud-3.steamusercontent.com/ugc/82591194029101910/5B04878FCA189712681D1CF6C92F8CD178668FD2/', 'http://cloud-3.steamusercontent.com/ugc/82591194029092256/19939432DC769A3B77BA19F2541C9EA11B72C73B/', 'http://cloud-3.steamusercontent.com/ugc/82591194029099778/264B65BA198B1A004192B898AD32F48FD3D400E3/'}},
    ['B-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/8CtXr', 'http://cloud-3.steamusercontent.com/ugc/82591194029071704/78677576E07A2F091DEC4CE58129B42714E8A19E/'}},
    ['HWK-290 Rebel'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/MySkn', 'http://cloud-3.steamusercontent.com/ugc/82591194029098250/4E8A65B9C156B7882A729BC9D93B2B434D549834/'}},
    ['VCX-100'] = { faction = 'Rebel', largeBase = true, meshes = {'https://paste.ee/r/VmV6q', 'http://cloud-3.steamusercontent.com/ugc/82591194029104609/DDD1DE36F998F9175669CB459734B1A89AD3549B/'}},
    ['Attack Shuttle'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/jrwRJ', 'http://cloud-3.steamusercontent.com/ugc/82591194029086137/2D8471654F7BA70A5B65BB3A5DC4EB6CBE8F7C1C/'}},
    ['T-70 X-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/NH1KI', 'http://cloud-3.steamusercontent.com/ugc/82591194029099132/056C807B114DE0023C1B8ABD28F4D5E8F0B5D76E/'}},
    ['E-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/A57A8', 'http://cloud-3.steamusercontent.com/ugc/82591194029072231/46CA6A77D12681CA1B1B4A9D97BD6917811D561C/'}},
    ['K-Wing'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/2Airh', 'http://cloud-3.steamusercontent.com/ugc/82591194029069099/CDF24012FD0342ED8DE472CFA0C7C2748E3AF541/'}},
    ['Z-95 Headhunter Rebel'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/d91Hu', 'http://cloud-3.steamusercontent.com/ugc/82591194029075380/02AE170F8A35A5619E57B3380F9F7FE0E127E567/'}},
    ['TIE Fighter Rebel'] = { faction = 'Rebel', largeBase = false, meshes = {'https://paste.ee/r/aCJSv', 'http://cloud-3.steamusercontent.com/ugc/82591194029072635/C7C5DAD08935A68E342BED0A8583D23901D28753/', 'http://cloud-3.steamusercontent.com/ugc/200804981461390083/2E300B481E6474A8F71781FB38D1B0CD74BBC427/'}},
    ['U-Wing'] = { faction = 'Rebel', largeBase = true, meshes = {'https://paste.ee/r/D4Jjb', 'http://cloud-3.steamusercontent.com/ugc/82591194029075014/E561AA8493F86562F48EE85AB0C02F9C4F54D1B3/', 'http://cloud-3.steamusercontent.com/ugc/89352927638740227/F17424FAEF4C4429CE544FEF03DAE0E7EA2A672E/'}},
    ['ARC-170'] = { faction = 'Rebel', largeBase = false, meshes = {'http://cloud-3.steamusercontent.com/ugc/489018224649021380/CF0BE9820D8123314E976CF69F3EA0A2F52A19AA/'}},

    ['Firespray-31 Scum'] = { faction = 'Scum', largeBase = true, meshes = {'https://paste.ee/r/3INxK', 'http://cloud-3.steamusercontent.com/ugc/82591194029069521/B5F857033DD0324E7508645821F17B572BC1AF6A/'}},
    ['Z-95 Headhunter Scum'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/OZrhd', 'http://cloud-3.steamusercontent.com/ugc/82591194029101027/02AE170F8A35A5619E57B3380F9F7FE0E127E567/'}},
    ['Y-Wing Scum'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/1T0ii', 'http://cloud-3.steamusercontent.com/ugc/82591194029068678/DD4A3DBC4B9ED3E108C39E736F9AA3DD816E1F6F/'}},
    ['HWK-290 Scum'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/tqTsw', 'http://cloud-3.steamusercontent.com/ugc/82591194029102663/71BDE5DC2D31FF4D365F210F037254E9DD62D6A7/'}},
    ['M3-A Interceptor'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/mUFjk', 'http://cloud-3.steamusercontent.com/ugc/82591194029096648/6773CD675FA734358137849555B2868AC513801B/'}},
    ['StarViper'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/jpEbC', 'http://cloud-3.steamusercontent.com/ugc/82591194029085780/6B4B13CE7C78700EF474D06F44CEB27A14731011/'}},
    ['Aggressor'] = { faction = 'Scum', largeBase = true, meshes = {'https://paste.ee/r/0UFlm', 'http://cloud-3.steamusercontent.com/ugc/82591194029067417/A6D736A64063BC3BC26C10E5EED6848C1FCBADB7/'}},
    ['YV-666'] = { faction = 'Scum', largeBase = true, meshes = {'https://paste.ee/r/lLZ8W', 'http://cloud-3.steamusercontent.com/ugc/82591194029090900/DD6BFD31E1C7254018CF6B03ABA1DA40C9BD0D2D/'}},
    ['Kihraxz Fighter'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/E8ZT0', 'http://cloud-3.steamusercontent.com/ugc/82591194029077425/6C88D57B03EF8B0CD7E4D91FED266EC15C614FA9/'}},
    ['JumpMaster 5000'] = { faction = 'Scum', largeBase = true, meshes = {'https://paste.ee/r/1af5C', 'http://cloud-3.steamusercontent.com/ugc/82591194029067863/A8F7079195681ECD24028AE766C8216E6C27EE21/'}},
    ['G-1A StarFighter'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/aLVFD', 'http://cloud-3.steamusercontent.com/ugc/82591194029072952/254A466DCA5323546173CA6E3A93EFD37A584FE6/'}},
    ['Lancer-Class Pursuit Craft'] = { faction = 'Scum', largeBase = true, meshes = {'https://paste.ee/r/Dp2Ge', 'http://cloud-3.steamusercontent.com/ugc/82591194029076583/E561AA8493F86562F48EE85AB0C02F9C4F54D1B3/', 'http://cloud-3.steamusercontent.com/ugc/89352769134140020/49113B3BA0A5C67FD7D40A3F61B6AFAFF02E0D1F/'}},
    ['Quadjumper'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/njJYd', 'http://cloud-3.steamusercontent.com/ugc/82591194029099470/6F4716CB145832CC47231B4A30F26153C90916AE/', 'http://cloud-3.steamusercontent.com/ugc/89352927637054865/CA43D9DEC1EF65DA30EC657EC6A9101E15905C78/'}},
    ['Protectorate Starfighter'] = { faction = 'Scum', largeBase = false, meshes = {'https://paste.ee/r/GmKW8', 'http://cloud-3.steamusercontent.com/ugc/82591194029065993/9838180A02D9960D4DE949001BBFD05452DA90D2/', 'http://cloud-3.steamusercontent.com/ugc/89352769138031546/C70B323524602140897D8E195C19522DB450A7E0/'}},

    ['TIE Fighter'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/Yz0kt', 'http://cloud-3.steamusercontent.com/ugc/82591194029106682/C7C5DAD08935A68E342BED0A8583D23901D28753/'}},
    ['TIE Interceptor'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/cedkZ', 'https://paste.ee/r/JxWNX', 'http://cloud-3.steamusercontent.com/ugc/82591194029074075/3AAF855C4A136C58E933F7409D0DB2C73E1958A9/', 'http://cloud-3.steamusercontent.com/ugc/82591194029086817/BD640718BFFAC3E4B5DF6C1B0220FB5A87E5B13C/'}},
    ['Lambda-Class Shuttle'] = { faction = 'Imperial', largeBase = true, meshes = {'https://paste.ee/r/4uxZO', 'http://cloud-3.steamusercontent.com/ugc/82591194029069944/4B8CB031A438A8592F0B3EF8FA0473DBB6A5495A/'}},
    ['Firespray-31 Imperial'] = { faction = 'Imperial', largeBase = true, meshes = {'https://paste.ee/r/p3iYR', 'http://cloud-3.steamusercontent.com/ugc/82591194029101385/B5F857033DD0324E7508645821F17B572BC1AF6A/'}},
    ['TIE Bomber'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/5A0YG', 'http://cloud-3.steamusercontent.com/ugc/82591194029070985/D0AF97C6FB819220CF0E0E93137371E52B77E2DC/'}},
    ['TIE Phantom'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/JN16g', 'http://cloud-3.steamusercontent.com/ugc/82591194029085339/CD9FEC659CF2EB67EE15B525007F784FB13D62B7/'}},
    ['VT-49 Decimator'] = { faction = 'Imperial', largeBase = true, meshes = {'https://paste.ee/r/MJOFI', 'http://cloud-3.steamusercontent.com/ugc/82591194029091549/10F641F82963B26D42E062ED8366A4D38C717F73/'}},
    ['TIE Advanced'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/NeptF', 'http://cloud-3.steamusercontent.com/ugc/82591194029098723/CAF618859C1894C381CA48101B2D2D05B14F83C0/', 'http://cloud-3.steamusercontent.com/ugc/82591194029104263/D0F4E672CBFA645B586FFC94A334A8364B30FD38/', 'http://cloud-3.steamusercontent.com/ugc/82591194029080088/D0F4E672CBFA645B586FFC94A334A8364B30FD38/'}},
    ['TIE Punisher'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/aVGkQ', 'http://cloud-3.steamusercontent.com/ugc/82591194029073355/7A1507E4D88098D19C8EAFE4A763CC33A5EC35CB/'}},
    ['TIE Defender'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/0QVhZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029067091/F2165ABE4580BD5CCECF258CCE790CD9A942606F/'}},
    ['TIE/fo Fighter'] = { faction = 'Imperial', largeBase = false, meshes = {'http://pastebin.com/jt2AzA8t'}},
    ['TIE Adv. Prototype'] = { faction = 'Imperial', largeBase = false, meshes = {'https://paste.ee/r/l7cuZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029089434/A4DA1AD96E4A6D65CC6AE4F745EDA966BA4EF85A/'}},
    ['TIE Striker'] = { faction = 'Imperial', largeBase = false, meshes = {'http://cloud-3.steamusercontent.com/ugc/200804896212875955/D04F1FF5B688EAB946E514650239E7772F4DC64E/'}},
    ['TIE/sf Fighter'] = { faction = 'Imperial', largeBase = false, meshes = {'http://pastebin.com/LezDjunY'}},
    ['Upsilon Class Shuttle'] = { faction = 'Imperial', largeBase = true, meshes = {'http://pastebin.com/nsHXF9XV'}}

}
-- END SHIP DATABASE MODULE
--------