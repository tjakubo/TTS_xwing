-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: http://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of: Flolania, Hera Vertigo
-- ~~~~~~

-- ~~~~~~
-- Code contributions
--  - Characted width data: Indimeco
--  - http://github.com/Indimeco/Tabletop-Simulator-Misc
-- ~~~~~~

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

-- Sebtract vector from another
function Vect_Sub(vec1, vec2)
    return Vect_Sum(vec1, Vect_Scale(vec2, -1))
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
        print('Vect_Scale: arg not a table/number pair!')
    end
    local out = {}
    local k = 1
    while vector[k] ~= nil do
        out[k] = vector[k]*factor
        k = k+1
    end
    return out
end

-- Multiply each element of a vector by an element from factor vector
-- (element-wise vector multiplication)
function Vect_ScaleEach(vector, factorVec)
    if type(vector) ~= 'table' or type(factorVec) ~= 'table' then
        print('Vect_ScaleEach: arg not a table/table pair!')
    end
    local out = {}
    local k = 1
    while vector[k] ~= nil and factorVec[k] ~= nil do
        out[k] = vector[k]*factorVec[k]
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

-- Scale the vector to have set length
-- Negative "length" - opposite of set length
function Vect_SetLength(vector, len)
    if type(vector) ~= 'table' or type(len) ~= 'number' then
        print('Vect_SetLength: arg not a table/number pair!')
    end
    return Vect_Scale(vector, len/Vect_Length(vector))
end

-- Rotation of a 3D vector over its second element axis, arg in degrees
-- Elements past 3rd are copied
function Vect_RotateDeg(vector, degRotation)
    local radRotation = math.rad(degRotation)
    return Vect_RotateRad(vector, radRotation)
end

-- Rotation of a 3D vector over its second element axis, arg in radians
-- Elements past 3rd are copied
function Vect_RotateRad(vector, radRotation)
    if type(vector) ~= 'table' or type(radRotation) ~= 'number' then
        print('Vect_RotateRad: arg not a table/number pair!')
    end
    local newX = math.cos(radRotation) * vector[1] + math.sin(radRotation) * vector[3]
    local newZ = math.sin(radRotation) * vector[1] * -1 + math.cos(radRotation) * vector[3]
    local out = {newX, vector[2], newZ}
    local k=4
    while vector[k] ~= nil do
        table.insert(out, vector[k])
        k = k+1
    end
    return out
end

-- Vector pointing from one position to another
function Vect_Between(fromVec, toVec)
    if type(fromVec) ~= 'table' or type(toVec) ~= 'table' then
        print('Vect_Between: arg not a table!')
    end
    return Vect_Sum(toVec, Vect_Scale(fromVec, -1))
end

-- Print vector elements
function Vect_Print(vec, name)
    local out = ''
    if name ~= nil then
        out = name .. ': [ '
    end
    local k = 1
    while vec[k] ~= nil do
        out = out .. vec[k] .. ' : '
        k = k+1
    end
    out = out:sub(1,-3) .. ']'
    print(out)
end

-- END VECTOR RELATED FUNCTIONS
--------

--------
-- MISC FUNCTIONS

-- Return value limited by mina nd max bounds
function Var_Clamp(var, min, max)
    if min ~= nil and var < min then
        return min
    elseif max ~= nil and var > max then
        return max
    else
        return var
    end
end

-- Check if table is empty
function table.empty(tab)
    return (next(tab) == nil)
end

-- Sign function, zero for zero
function math.sgn(arg)
    if arg < 0 then
        return -1
    elseif arg > 0 then
        return 1
    end
    return 0
end

-- Round to decPlaces decimal places
-- if decPlaces nil round to nearest integer
function math.round(arg, decPlaces)
    if decPlaces == nil then decPlaces = 0 end

    if dec == 0 then
        frac = arg - math.floor(arg)
        if frac >= 0.5 then
            return math.ceil(arg)
        else
            return math.floor(arg)
        end
    else
        local mult = 10^(dec or 0)
        return math.floor(num * mult + 0.5) / mult
    end
end

-- Dumbest TTS issue ever workaround
function TTS_Serialize(pos)
    return {pos[1], pos[2], pos[3]}
end

-- Check if object matches some of predefined X-Wing types
function XW_ObjMatchType(obj, type)
    if type == 'any' then
        return true
    elseif type == 'ship' then
        return (obj.tag == 'Figurine')
    elseif type == 'token' then
        if obj.getName() == 'Cloak' or obj.getName():find('roll token') ~= nil then
            return (obj.getVar('idle') == true)
        end
        if (obj.tag == 'Chip' or obj.getVar('set') ~= nil) and obj.getName() ~= 'Shield' then
            return true
        end
        if obj.getName():find('Reinforce') ~= nil then
            return true
        end
    elseif type == 'lock' then
        return (obj.getVar('set') ~= nil)
    elseif type == 'dial' then
        return (obj.tag == 'Card' and obj.getDescription() ~= '')
    end
    return false
end

-- Get an object closest to (object OR position) + optional X-Wing type filter
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

-- Get objects within distance of (object OR position) + optional X-Wing type filter
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
-- API FUNCTIONS
-- For easy acces from other objects
-- (TTS requires external call to have a single table as an argument)

-- Perform a move using a standard move command
-- Argument: { code = moveCode, ship = shipReference, ignoreCollisions = [true/false] }
-- Return: TRUE if move completed, FALSE if overlap prevented ship from moving
-- Return:                         FALSE if invalid (non-move) command or ship not ready
function API_PerformMove(argTable)
    local type = XW_cmd.CheckCommand(argTable.code)
    if (type ~= 'move' and type ~= 'actionMove') or not XW_cmd.isReady(argTable.ship) then
        return false
    end
    return MoveModule.PerformMove(argTable.code, argTable.ship, argTable.ignoreCollisions)
end

-- Assign a set of dials to a ship
-- Removes any set ship has when this is called
-- Uniqueness of set description is checked (warn & skip)
-- Current owner of dials checked (warn & skip)
-- *Dial script requirement not checked*
-- Argument: { ship = shipRef, set = {dialRef1, dialRef2, ... dialRefN} }
-- Return: TRUE if some dials were assigned, FALSE if none were assigned
function DialAPI_AssignSet(argTable)
    -- Remove any current set
    local actSet = DialModule.GetSet(argTable.ship)
    if actSet ~= nil then
        DialModule.RemoveSet(argTable.ship)
    end
    -- Filter out duplicate description and already assigned dials
    local validSet = {}
    for k,dial in pairs(argTable.set) do
        if validSet[dial.getDescription()] ~= nil then
            AnnModule.Announce({type='error_DialModule', note='tried to assign few of same dials (API call)'}, 'all', argTable.ship)
        else
            if dial.getVar('assignedShip') == nil then
                validSet[dial.getDescription()] = {dial=dial, originPos=dial.getPosition()}
                dial.call('setShip', {argTable.ship})
                dial.setName(argTable.ship.getName())
            else
                AnnModule.Announce({type='error_DialModule', note='tried to assign dial that belong to other ship (API call)'}, 'all', argTable.ship)
            end
        end
    end
    -- Add those that remain
    if not table.empty(validSet) then
        DialModule.AddSet(argTable.ship, validSet)
        return true
    else
        return false
    end
end

-- Start ship slide on some object (dial or anything)
-- "Slide" button for move zone depiction is not created
-- Control & constraints identical to slide button on a dial
-- *OBJ NEEDS TO HAVE 'assignedShip' VARIABLE SET TO SHIP REF*
-- Argument: { obj = objRef, playerColor = clickingPlayerColor }
function API_StartSlide(argTable)
    return DialModule.StartSlide(argTable.obj, argTable.playerColor)
end

-- Queue tokens near a ship for movement
-- To be called immediately before changing position of a ship
-- Argument: { ship = shipRef, finPos = { pos = finalPosition, rot = finalRotation} }
-- finPos field may be nil (no position set after wait then)
function API_QueueShipTokensMove(argTable)
    -- Set the ship busy if it's not to try prevent double ready later
    if XW_cmd.isReady(argTable.ship) then
        XW_cmd.SetBusy(argTable.ship)
    end
    local lockFun = nil
    if argTable.noLock == true then
        lockFun = function(ship)
            ship.unlock()
        end
    end
    TokenModule.QueueShipTokensMove(argTable.ship)
    MoveModule.WaitForResting(argTable.ship, argTable.finPos, lockFun)
end

-- Indicate dropping of a bomb token from outside Global
-- Argument: { token = droppedTokenRef }
-- Return: true if token snapped, false otherwise
function API_BombTokenDrop(argTable)
    return BombModule.OnTokenDrop(argTable.token)
end

-- END API FUNCTIONS
--------

--------
-- OBJECT SPECIFIC VARIABLES
-- These variables are set per object and have some specific meaning
-- Some may be linked to another so caution must be kept when modifying

-- objectType : varName         - val / val2 ... / valN     <- meaning
-- ship : 'hasDials'            - true / (false/nil)        <- Has assigned set of dials (ONLY informative) / Not
-- ship : 'slideOngoing'        - true / (false/nil)        <- Is in process of manually adjusting slide / Not
-- ship : 'cmdBusy'             - true / (false/nil)        <- Is currently processing some command / Not
-- ship : 'missingModelWarned'  - true / (false/nil)        <- Printed a warning that model is unrecognized (once) / Not yet
-- dial : 'slideOngoing'        - true / (false/nil)        <- Its ship in process of manually adjusting slide / Not
-- dial : 'assignedShip'        - shipRef / nil             <- Object reference to its owner / No owner
-- token : 'idle'               - false / (true/nil)        <- This token should be ignored when moving tokens / Not

-- END OBJECT SPECIFIC VARIABLES
--------

--------
-- COMMAND HANDLING MODULE
-- Sanitizes input (more like ignores anything not explicitly allowed)
-- Allows other modules to add available commands and passes their execution where they belong

XW_cmd = {}

-- Table of valid commands: their patterns and general types
XW_cmd.ValidCommands = {}

-- Add given regen expression as a valid command for processing
XW_cmd.AddCommand = function(cmdRegex, type)
    -- When adding available commands, assert beggining and end of string automatically
    if cmdRegex:sub(1,1) ~= '^' then cmdRegex = '^' .. cmdRegex end
    if cmdRegex:sub(-1,-1) ~= '$' then cmdRegex = cmdRegex .. '$' end
    table.insert(XW_cmd.ValidCommands, {string.lower(cmdRegex), type})
end

-- Check if command is registered as valid
-- If it is return its type identifier, if not return nil
XW_cmd.CheckCommand = function(cmd)
    -- Trim whitespaces
    cmd = string.lower(cmd:match( "^%s*(.-)%s*$" ))
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

-- (special function)
-- Purge all save data (everything that goes to onSave)
XW_cmd.AddCommand('purgeSave', 'special')
XW_cmd.PurgeSave = function()
    MoveModule.moveHistory = {}
    while DialModule.ActiveSets[1] ~= nil do
        DialModule.RemoveSet(DialModule.ActiveSets[1].ship)
    end
end

-- (special function)
-- Print ship hitory
XW_cmd.AddCommand('hist', 'special')
XW_cmd.ShowHist = function(ship)
    MoveModule.PrintHistory(ship)
end

-- (special function)
-- Check for typical issues with a ship
XW_cmd.AddCommand('diag', 'special')
XW_cmd.Diagnose = function(ship)
    -- Check and unlock XW_cmd lock if it's on
    local issueFound = false
    if XW_ObjMatchType(ship, 'ship') ~= true then return end
    if XW_cmd.isReady(ship) ~= true then
        XW_cmd.SetReady(ship)
        printToAll(ship.getName() .. '\'s deadlock resolved', {0.1, 0.1, 1})
        issueFound = true
    end
    -- Delete lingering buttons
    if ship.getButtons() ~= nil then
        ship.clearButtons()
        printToAll(ship.getName() .. '\'s lingering buttons deleted', {0.1, 0.1, 1})
        issueFound = true
    end
    -- If ship is tagged as sliding now, reset
    if ship.getVar('slideOngoing') == true then
        ship.setVar('slideOngoing', false)
        printToAll(ship.getName() .. '\'s stuck slide resolved', {0.1, 0.1, 1})
        issueFound = true
    end
    -- If ship has unrecognized model and said that before, remind
    if ship.getVar('missingModelWarned') == true then
        printToAll('I hope you do remember that I told you about ' .. ship.getName() .. '\'s model being unrecognized when it was first moved/used', {0.1, 0.1, 1})
        issueFound = true
    -- If its model is unrecognized and haven't been used yet, notify
    elseif shipType == 'Unknown' then
        local shipType = DB_getShipType(ship)
        printToAll(ship.getName() .. '\'s ship type not reconized. If this model was taken from Squad Builder or Collection, notify author of the issue.', {1, 0.1, 0.1})
        issueFound = true
    end
    -- CHECK SHIP DIAL SET
    local set = DialModule.GetSet(ship)
    local dialError = false
    local dialErrorCode = ''
    -- Restore active dial in case it's been lost somewhere
    DialModule.RestoreActive(ship)
    if set ~= nil and set.dialSet ~= nil then
        for k, dInfo in pairs(set.dialSet) do
            -- If any dial ref in set is nil, critical error
            if dInfo.dial == nil then
                dialError = true
                dialErrorCode = 'nilDial'
            -- If any dial is not set to this ship, critical error
            elseif dial.getVar('assignedShip') ~= ship then
                dialError = true
                dialErrorCode = 'wrongShip'
            -- If dial is stuck to slide mode, reset
            elseif dial.getVar('slideOngoing') == true then
                printToAll(ship.getName() .. '\'s dial stuck slide resolved', {0.1, 0.1, 1})
                issueFound = true
            end
        end
    end
    -- Critical error notify
    if dialError == true then
        printToAll( ship.getName() .. '\'s dial data corrupted - it\'s bad, delete model and dials and reassign new set (may need table reload, notify author of this)' ..
                    ' [' .. dialErrorCode .. ']', {1, 0.1, 0.1})
        issueFound = true
    end
    -- No issues found
    if issueFound ~= true then
        printToAll(ship.getName() .. ' looks OK', {0.1, 1, 0.1})
    end
end

-- Process provided command on a provided object
-- Return true if command has been executed/started
-- Return false if object cannot process commands right now or command was invalid
XW_cmd.Process = function(obj, cmd)

    -- Trim whitespaces
    cmd = cmd:match( "^%s*(.-)%s*$" )

    -- Resolve command type
    local type = XW_cmd.CheckCommand(cmd)

    -- Process special commands without taking lock into consideration
    if type == nil then
        return false
    elseif type == 'special' then
        if cmd == 'diag' then
            XW_cmd.Diagnose(obj)
        elseif cmd == 'purgeSave' then
            XW_cmd.PurgeSave()
        elseif cmd == 'hist' then
            XW_cmd.ShowHist(obj)
        end
    end

    -- Return if not ready, else process
    if XW_cmd.isReady(obj) ~= true then
        return false
    end

    if type == 'demoMove' then
        MoveModule.DemoMove(cmd:sub(3, -1), obj)
    elseif type == 'move' or type == 'actionMove' then
        local info = MoveData.DecodeInfo(cmd, obj)
        MoveModule.PerformMove(cmd, obj)
    elseif type == 'historyHandle' then
        if cmd == 'q' or cmd == 'undo' then
            MoveModule.UndoMove(obj)
        elseif cmd == 'z' or cmd == 'redo' then
            MoveModule.RedoMove(obj)
        elseif cmd == 'keep' then
            MoveModule.SaveStateToHistory(obj, false)
        elseif cmd:sub(1,8) == 'restore#' then
            local keyNum = tonumber(cmd:sub(9, -1))
            MoveModule.Restore(obj, keyNum)
        end
    elseif type == 'dialHandle' then
        if cmd == 'sd' then
            DialModule.SaveNearby(obj)
        elseif cmd == 'rd' then
            DialModule.RemoveSet(obj)
        end
    elseif type == 'rulerHandle' then
        AnnModule.NotifyOnce('RULER SPAWN COMMANDS HAVE CHANGED!\nNew commands are described on "New rulers" notebook page.', 'newRulersInfo', 'all')
        RulerModule.ToggleRuler(obj, string.upper(cmd))
    elseif type == 'action' then
        DialModule.PerformAction(obj, cmd)
    elseif type == 'bombDrop' then
        BombModule.ToggleDrop(obj, cmd)
    end
    obj.setDescription('')
    return true
end

-- Is object not processing some commands right now?
XW_cmd.isReady = function(obj)
    return (obj.getVar('cmdBusy') ~= true)
end

-- Flag the object as processing commands to ignore any in the meantime
XW_cmd.SetBusy = function(obj)
    if XW_cmd.isReady(obj) ~= true then
        print('Nested process on ' .. obj.getName())
    end
    obj.setVar('cmdBusy', true)
end

-- Flag the object as ready to process next command
XW_cmd.SetReady = function(obj)
    if XW_cmd.isReady(obj) == true then
        print('Double ready on ' .. obj.getName())
    end
    obj.setVar('cmdBusy', false)
end

--------
-- MOVEMENT DATA MODULE
-- Stores and processes data about moves
-- NOT aware of any ship position, operation solely on relative movements
-- Used for feeding data about a move to a higher level movement module
-- Exclusively uses milimeters and degrees for values, needs external conversion

-- Possible commands supported by this module
XW_cmd.AddCommand('[sk][012345][r]?', 'move')   -- Straights/Koiograns + stationary moves
XW_cmd.AddCommand('b[rle][123][sr]?', 'move')   -- Banks + segnor and reverse versions
XW_cmd.AddCommand('t[rle][123][str]?', 'move')  -- Turns + segnor, talon and reverse versions

XW_cmd.AddCommand('x[rle][fb]?', 'actionMove')  -- Barrel rolls
XW_cmd.AddCommand('s[12345]b', 'actionMove')    -- Boost straights
XW_cmd.AddCommand('b[rle][123]b', 'actionMove') -- Boost banks
XW_cmd.AddCommand('t[rle][123]b', 'actionMove') -- Boost turns
XW_cmd.AddCommand('c[srle]', 'actionMove')      -- Decloaks side middle + straight
XW_cmd.AddCommand('c[rle][fb]', 'actionMove')   -- Decloaks side forward + backward
XW_cmd.AddCommand('ch[rle][fb]', 'actionMove')  -- Echo's bullshit
XW_cmd.AddCommand('chs[rle]', 'actionMove')     -- Echo's bullshit, part 2
XW_cmd.AddCommand('vr[rle][fb]', 'actionMove')  -- StarViper Mk.II rolls

MoveData = {}

-- Lookup table for most of the moves
-- Generated using Matlab, source: https://github.com/tjakubo2/xwing_traj
-- Stored on another object to reduce clutter, passsed on load
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

-- Max part value for partial moves
-- Part equal to this is a full move
-- Value is largely irrelevant since part can be a fraction (any kind of number really)
MoveData.partMax = 1000

-- Construct data from a lookup table entry
-- Move info provided from MoveData.DecodeInfo
-- Return format: {xPos_offset, yPos_offset, zPos_offset, yRot_offset}
-- Linear interpolation between points in lookup table
--
-- Only returns data for RIGHT direction move (if applies)
-- Doesn't take any segnor, talon versions etc into considerations
-- Above things are considered MODIFIERS with functions to apply them defined futher
MoveData.LUT.ConstructData = function(moveInfo, part)
    if part == nil then
        part = MoveData.partMax
    end
    if moveInfo.speed == 0 then
        return {0, 0, 0, 0}
    end
    part = Var_Clamp(part, 0, MoveData.partMax)
    local LUTtable = MoveData.LUT.Data[moveInfo.size .. 'Base'][moveInfo.type][moveInfo.speed]
    local LUTindex = (part/MoveData.partMax)*LUTtable.dataNum
    if LUTindex < 1 then LUTindex = 1 end
    -- Interpolation between two nearest indexes
    local aProp = LUTindex - math.floor(LUTindex)
    local bProp = 1 - aProp
    local outPos = Vect_Sum(Vect_Scale(LUTtable.posXZ[math.floor(LUTindex)], bProp), Vect_Scale(LUTtable.posXZ[math.ceil(LUTindex)], aProp))
    local outRot = (LUTtable.rotY[math.floor(LUTindex)] * bProp) + (LUTtable.rotY[math.ceil(LUTindex)] * aProp)

    local outData = {outPos[1], 0, outPos[2], outRot}
    return outData
end

-- Get true move length from LUT data *IN MILIMETERS*
-- True as in trajectory length, not distance between start and end
-- (stored in LUT to reduce load here)
MoveData.MoveLength = function(moveInfo)
    if moveInfo.traits.part == false then
        return nil
    elseif moveInfo.speed == 0 then
        return 0
    else
        return MoveData.LUT.Data[moveInfo.size .. 'Base'][moveInfo.type][moveInfo.speed].length
    end
end

-- Regex match for moves that support sliding base after execution
MoveData.slideMatchTable = {    'x[rle]',
                                'x[rle][fb]?',
                                'c[rle][fb]?',
                                't[rle][123]t',
                                'ch[rle][fb]',
                                'chadj',
                                'vr[rle][fb]',
                                'vradj'             }
-- Check if move allows sliding based on above table
-- Argumant can be either move code or move info as per MoveData.DecodeInfo
MoveData.IsSlideMove = function(moveInfoCode)
    local code = nil
    if type(moveInfoCode) == 'table' and type(moveInfoCode.code) == 'string' then
        code = moveInfoCode.code
    elseif type(moveInfoCode) == 'string' then
        code = moveInfoCode
    else
        print('MoveData.IsSlideMove: arg of invalid type')
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

-- Get slide length (if move supports sliding) IN MILIMETERS
MoveData.SlideLength = function(moveInfo)
    if type(moveInfo) ~= 'table' then
        print('MoveData.SlideLength: arg of invalid type')
    end
    if moveInfo.traits.slide ~= true then
        return nil
    else
        baseSize = mm_baseSize[moveInfo.size]
        if moveInfo.type == 'roll' then
            return baseSize
        elseif (moveInfo.type == 'turn' and moveInfo.extra == 'talon') or moveInfo.type == 'echo' or moveInfo.type == 'viper' then
            return baseSize/2
        end
    end
    return nil
end

-- Get the position at which slide after move should start
-- This is the position when ship is slid as far BACK as possible (part=0 in later processing)
MoveData.SlideMoveOrigin = function(moveInfo)
    local code = moveInfo.code
    local baseSize = mm_baseSize[moveInfo.size]
    local data = nil
    if moveInfo.type == 'roll' then
        -- Rolls are straights rotated 90deg sideways
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
    elseif moveInfo.type == 'echo' or moveInfo.type == 'viper' then
        -- FUCKING ECHO is appropriate bank 2 rotated 90deg sideways
        -- Viper is same but bank 1
        local ang = -90
        if moveInfo.dir == 'right' then
            ang = 90
        end
        local bankSpeed = 2
        if moveInfo.type == 'viper' then bankSpeed = 1 end
        data = MoveData.LUT.ConstructData({type='bank', speed=bankSpeed, size='small', code='br' .. tostring(bankSpeed)})
        if (moveInfo.dir == 'left' and moveInfo.extra == 'backward') or (moveInfo.dir == 'right' and moveInfo.extra == 'forward') then
            data = MoveData.LeftVariant(data)
        end
        data = MoveData.RotateEntry(data, ang)
        if moveInfo.dir == 'right' then
            data[4] = data[4] - 90
        else
            data[4] = data[4] + 90
        end
        data[3] = data[3] - MoveData.SlideLength(moveInfo)/2
    elseif moveInfo.type == 'turn' and moveInfo.extra == 'talon' then
        -- Talon roll are simply talons rolls slid forward
        -- (forward cause this is initial position relative and talons do a 180)
        data = MoveData.LUT.ConstructData(moveInfo)
        data[3] = data[3] + MoveData.SlideLength(moveInfo)/2
        if moveInfo.dir == 'left' then
            data = MoveData.LeftVariant(data)
        end
        data = MoveData.TurnInwardVariant(data)
    end
    return data
end

-- Get the offset sliding by part/maxPart applies to ship position
-- MoveData.SlideMoveOrigin and this provide total offset for some part of a slide
-- THIS IS ZERO-SLIDE-POSITION RELATIVE
MoveData.SlidePartOffset = function(moveInfo, part)

    if moveInfo.type == 'echo' or moveInfo.type == 'viper' then
        if moveInfo.extra == 'adjust' then
            -- Echo 2nd adjust is similair to a barrel roll
            -- This is when ship is slid against the template
            return {0, 0, MoveData.SlideLength(moveInfo)*(part/MoveData.partMax), 0}
        else
            -- Echo 1st adjust is a diagonal 45deg line through base
            -- This is when template is slid against ship before it is moved
            local dirVec = {-1, 0, 1, 0}
            if (moveInfo.dir == 'left' and moveInfo.extra == 'backward') or (moveInfo.dir == 'right' and moveInfo.extra == 'forward') then
                dirVec[1] = -1*dirVec[1]
            end
            dirVec = Vect_SetLength(dirVec, MoveData.SlideLength(moveInfo))
            return Vect_Scale(dirVec, part/MoveData.partMax)
        end
    else
        -- Normal rolls/talons are simply slid forward
        return {0, 0, MoveData.SlideLength(moveInfo)*(part/MoveData.partMax), 0}
    end
end

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

-- Rotate an entry by given degrees
-- Helps define rolls as straights rotated 90deg sideways etc
MoveData.RotateEntry = function(entry, angDeg)
    local rotEntry = Vect_RotateDeg(entry, angDeg)
    return {rotEntry[1], rotEntry[2], rotEntry[3], entry[4]+angDeg}
end

-- Apply move modifiers that happen even if move is partial
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

-- Apply move modifiers that only happen if move is performed fully
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
-- TODO make a lookup table?
MoveData.DecodeInfo = function (move_code, ship)
    local info = {
                                        -- [option1] [option2] ... [optionN]  // [errorOption]
                    type='invalid',     -- [straight] [bank] [turn] [roll] [echo] //  [invalid]
                    speed=nil,          -- [1] [2] [3] [4] [5]  //  [nil]
                    dir=nil,            -- [left] [right] [nil]
                    extra=nil,          -- [koiogran] [segnor] [talon] [reverse] [straight] [forward] [backward] [nil]
                    traits =
                    {   slide=false,    -- [true] [false] if this move can be slid afterwards
                        full=false,     -- [true] [false] if this move can be attempted as a full move
                        part=false      -- [true] [false] if this move can be attempted as a partial move
                    },
                    size=nil,           -- [small] [large]  //  [nil]
                    note=nil,           -- [string] eg. 'banked xxx'       //  [nil]
                    collNote=nil,       -- [string] eg. 'tried to do xxx'  //  [nil]
                    code=move_code      -- [string] eg. 'be2'              //  [nil]
    }

    -- Set to slide-able if it is
    if MoveData.IsSlideMove(move_code) then
        info.traits.slide = true
    end

    if DB_isLargeBase(ship) == true then info.size = 'large'
    else info.size = 'small' end

    -- Straights and koiograns, regular stuff
    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info.type = 'straight'
        info.speed = tonumber(move_code:sub(2,2))
        info.traits.full = true
        info.traits.part = true
        if move_code:sub(1,1) == 'k' then
            info.extra = 'koiogran'
            info.note = 'koiogran turned ' .. info.speed
            info.collNote = 'tried to koiogran turn ' .. info.speed
        elseif move_code:sub(-1,-1) == 'r' then
            info.extra = 'reverse'
            info.note = 'flew reverse ' .. info.speed
            info.collNote = 'tried to fly reverse ' .. info.speed
        elseif move_code:sub(-1,-1) == 'b' then
            info.traits.part = false
            local boostSpd = ''
            if info.speed > 1 then
                boostSpd = ' ' .. info.speed
            end
            info.note = 'boosted straight' .. boostSpd
            info.collNote = 'tried to boost straight' .. boostSpd
        else
            info.note = 'flew straight ' .. info.speed
            info.collNote = 'tried to fly straight ' .. info.speed
        end
        if info.speed == 0 then
            info.traits.part = false
            if info.extra == 'koiogran' then
                info.note = 'turned around'
            else
                info.note = 'is stationary'
            end
        end
    -- Banks, regular stuff
    elseif move_code:sub(1,1) == 'b' then
        info.type = 'bank'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        info.traits.full = true
        info.traits.part = true
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
        elseif move_code:sub(-1,-1) == 'b' then
            info.traits.part = false
            local boostSpd = ''
            if info.speed > 1 then
                boostSpd = ' ' .. info.speed
            end
            info.note = 'boosted ' .. info.dir .. boostSpd
            info.collNote = 'tried to boost ' .. info.dir .. boostSpd
        else
            info.note = 'banked ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to bank ' .. info.dir .. ' ' .. info.speed
        end
    -- Turns, regular stuff
    elseif move_code:sub(1,1) == 't' then
        info.type = 'turn'
        info.dir = 'right'
        info.speed = tonumber(move_code:sub(3,3))
        info.traits.full = true
        info.traits.part = true
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
        elseif move_code:sub(-1,-1) == 'b' then
            info.traits.part = false
            local boostSpd = ''
            if info.speed > 1 then
                boostSpd = ' ' .. info.speed
            end
            info.note = 'boosted (turn template) ' .. info.dir .. boostSpd
            info.collNote = 'tried to boost (turn template) ' .. info.dir .. boostSpd
        else
            info.note = 'turned ' .. info.dir .. ' ' .. info.speed
            info.collNote = 'tried to turn ' .. info.dir .. ' ' .. info.speed
        end
    -- Barrel rolls and decloaks, spaghetti
elseif move_code:sub(1,2) == 'ch' or move_code:sub(1,2) == 'vr' then
        -- Echo's fucking bullshit which goes against ALL the standards
        -- StarViper handled the same
        info.type = 'echo'
        if move_code:sub(1,2) == 'vr' then
            info.type = 'viper'
        end
        info.dir = 'right'
        info.extra = 'forward'
        if move_code:sub(4,4) == 'b' then
            info.extra = 'backward'
        end
        if move_code:sub(3,3) == 'l' or move_code:sub(3,3) == 'e' then
            -- Ones going right/left
            info.dir = 'left'
        elseif move_code:sub(3,3) == 's' then
            -- Ones going forward
            info = MoveData.DecodeInfo('b' .. move_code:sub(4,4) .. '2', ship)
            info.traits.part = false
            info.code = move_code
        end
        if move_code:sub(1,2) == 'ch' then
            -- Echo dedscriptions
            if info.type == 'echo' then
                info.note = 'dechocloaked ' .. info.dir .. ' ' .. info.extra
                info.collNote = 'tried to dechocloak ' .. info.dir .. ' ' .. info.extra
            else
                info.note = 'dechocloaked forward ' .. info.dir
                info.collNote = 'tried to dechocloak forward ' .. info.dir
            end
        else
            -- SV descriptions
            info.note = 'bank rolled ' .. info.dir .. ' ' .. info.extra
            info.collNote = 'tried to bank roll ' .. info.dir .. ' ' .. info.extra
        end
        -- Special 2nd adjust move
        if move_code == 'chadj' or move_code == 'vradj' then
            info.extra = 'adjust'
        end
    elseif move_code:sub(1,1) == 'x' or move_code:sub(1,1) == 'c' then
        -- Rolls
        info.type = 'roll'
        info.dir = 'right'
        info.speed = 1
        if move_code:sub(2,2) == 'l' or move_code:sub(2,2) == 'e' then
            info.dir = 'left'
        end
        info.note = 'barrel rolled'
        info.collNote = 'tried to barrel roll'
        -- Decloaks
        -- Straigh decloak is treated as a roll before, now just return straight 2 data
        if move_code:sub(2,2) == 's' then
            info.type = 'straight'
            info.speed = 2
            info.traits.full = true
            info.note = 'decloaked forward'
            info.collNote = 'tried to decloak forward'
            info.dir = nil
        -- Side decloak is a barrel roll, but with 2 speed
        elseif move_code:sub(1,1) == 'c' then
            info.note = 'decloaked'
            info.collNote = 'tried to decloak'
            info.speed = 2
        end

        -- Forward/backward modifiers
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
    return info
end

-- Get the offset data for a full move
-- Return format: {xPos_offset, yPos_offset, zPos_offset, yRot_offset}
MoveData.DecodeFullMove = function(move_code, ship)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)
    if info.type == 'invalid' then
        print('MoveData.DecodeFullMove: invalid move type')
        return {0, 0, 0, 0}
    else
        data = MoveData.DecodePartMove(move_code, ship, MoveData.partMax)
    end
    data = MoveData.ApplyFinalModifiers(data, info)
    return data
end

-- Get the offset data for a partial move
-- Return format: {xPos_offset, yPos_offset, zPos_offset, yRot_offset}
MoveData.DecodePartMove = function(move_code, ship, part)
    local data = {}
    local info = MoveData.DecodeInfo(move_code, ship)
    part = Var_Clamp(part, 0, MoveData.partMax)
    if info.type == 'invalid' then
        print('MoveData.DecodePartMove: invalid move type')
        return {0, 0, 0, 0}
    end
    data = MoveData.LUT.ConstructData(info, part)
    data = MoveData.ApplyBasicModifiers(data, info)
    return data
end

-- Get the offset data for a partial slide
-- Return format: {xPos_offset, yPos_offset, zPos_offset, yRot_offset}
MoveData.DecodePartSlide = function(move_code, ship, part)
    local info = MoveData.DecodeInfo(move_code, ship)
    local slideOrigin = MoveData.SlideMoveOrigin(info)
    local offset = Vect_RotateDeg(MoveData.SlidePartOffset(info, part), slideOrigin[4])
    return Vect_Sum(slideOrigin, offset)
end

-- END MOVEMENT DATA MODULE
--------


--------
-- MAIN MOVEMENT MODULE
-- Lets us move ships around and handles what comes with moving

MoveModule = {}

-- Called when game is saved
-- Returns table for encoding
MoveModule.onSave = function()
    return MoveModule.GetSaveData()
end

-- Convert a typical entry from MoveData functions
-- (this: {xPos_offset, yPos_offset, zPos_offset, yRot_offset} )
-- to a real ship position in world
MoveModule.EntryToPos = function(entry, shipPos)
    local basePos = nil
    local baseRot = nil
    if type(shipPos) == 'userdata' then
        basePos = shipPos.getPosition()
        baseRot = shipPos.getRotation()
    elseif type(shipPos) == 'table' then
        basePos = shipPos.pos
        baseRot = shipPos.rot
    end
    local finalPos = MoveData.ConvertDataToIGU(entry)
    local finalRot = entry[4] + baseRot[2]
    finalPos = Vect_RotateDeg(finalPos, baseRot[2]+180)
    finalPos = Vect_Sum(basePos, finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- Get the position for a ship if it did a full move
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetFullMove = function(move, ship)
    local entry = MoveData.DecodeFullMove(move, ship)
    return MoveModule.EntryToPos(entry, ship)
end

-- Get the position for a ship if it did a part of a move
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetPartMove = function(move, ship, part)
    local entry = MoveData.DecodePartMove(move, ship, part)
    return MoveModule.EntryToPos(entry, ship)
end

-- Get the position for a ship if it did a part of a slide
-- Returned position and rotation are ready to feed TTS functions with
MoveModule.GetPartSlide = function(move, ship, part)
    local entry = MoveData.DecodePartSlide(move, ship, part)
    return MoveModule.EntryToPos(entry, ship)
end

-- HISTORY HANDLING:
-- Lets us undo, redo and save positions a ship was seen at

-- History table: {ship=shipRef, actKey=keyOfHistoryEntryShipWasLastSeenAt (._.), history=entryList}
-- Entry list: {entry1, entry2, entry3, ...}
-- Entry: {pos=position, rot=rotation, move=moveThatGotShipHere, part=partOfMovePerformed}
MoveModule.moveHistory = {}

-- Hostory-related commads
XW_cmd.AddCommand('[qz]', 'historyHandle')
XW_cmd.AddCommand('undo', 'historyHandle')
XW_cmd.AddCommand('redo', 'historyHandle')
XW_cmd.AddCommand('keep', 'historyHandle')

-- Return history of a ship
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
            local typeStr = ' (' .. entry.finType
            if entry.part ~= nil then
                typeStr = typeStr .. ':' .. entry.part .. ')'
            else
                typeStr = typeStr .. ')'
            end
            if k == histData.actKey then
                print(' >> ' .. entry.move .. typeStr)
            else
                print(' -- ' .. entry.move .. typeStr)
            end
            k = k+1
        end
        print(' -- -- -- -- ')
    end
end

-- Save <some> ship position to the history
-- Saves on the position after current and deletes any past that
MoveModule.AddHistoryEntry = function(ship, entry)
    local histData = MoveModule.GetHistory(ship)
    histData.actKey = histData.actKey+1
    histData.history[histData.actKey] = entry
    MoveModule.ErasePastCurrent(ship)
end

-- How much position can be offset to be considered 'same'
MoveModule.undoPosCutoff = Convert_mm_igu(1)
-- How much rotation can be offset to be considered 'same'
MoveModule.undoRotCutoffDeg = 1

-- Check if the ship is on the curent history position (tolerance above)
MoveModule.IsAtSavedState = function(ship)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey > 0 then
        local currEntry = histData.history[histData.actKey]
        local dist = Dist_Pos(ship.getPosition(), currEntry.pos)
        local angDiff = math.abs(ship.getRotation()[2] - currEntry.rot[2])
        if math.abs(angDiff) > 180 then
            angDiff = math.abs(angDiff - math.sgn(angDiff)*360)
        end
        return (dist < MoveModule.undoPosCutoff and angDiff < MoveModule.undoRotCutoffDeg)
    end
    return false
end

-- Save curent ship position to the history
-- Can be quiet when not explicitly called by the user
MoveModule.SaveStateToHistory = function(ship, beQuiet)
    local histData = MoveModule.GetHistory(ship)
    -- Don't add an entry if it's current position/rotation
    if MoveModule.IsAtSavedState(ship) then
        if beQuiet ~= true then
            AnnModule.Announce({type='historyHandle', note='already has current position saved'}, 'all', ship)
        end
    else
        local entry = {pos=ship.getPosition(), rot=ship.getRotation(), move='position save', part=nil, finType='special'}
        MoveModule.AddHistoryEntry(ship, entry)
        if beQuiet ~= true then
            AnnModule.Announce({type='historyHandle', note='stored current position'}, 'all', ship)
        end
    end
end

-- Move a ship to a previous state from the history
-- Return true if action was taken
-- Return false if there is no more data
MoveModule.UndoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
    -- No history
    if histData.actKey == 0 then
        announceInfo.note = 'has no more moves to undo'
    else
        -- There is history
        local currEntry = histData.history[histData.actKey]
        -- current position not matching history
        if not MoveModule.IsAtSavedState(ship) then
            MoveModule.MoveShip(ship, {finPos={pos=currEntry.pos, rot=currEntry.rot}, noSave=true})
            announceInfo.note = 'moved to the last saved position'
        else
        -- current position matching current histor
            if histData.actKey > 1 then
                local undidMove = currEntry.move
                histData.actKey = histData.actKey - 1
                currEntry = histData.history[histData.actKey]
                MoveModule.MoveShip(ship, {finPos={pos=currEntry.pos, rot=currEntry.rot}, noSave=true})
                announceInfo.note = 'performed an undo of (' .. undidMove .. ')'
            else
                -- There is no data to go back to
                announceInfo.note = 'has no more moves to undo'
            end
        end
    end
    AnnModule.Announce(announceInfo, 'all', ship)
    return shipMoved
end

-- Move a ship to next state from the history
MoveModule.RedoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local announceInfo = {type='historyHandle'}
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
            MoveModule.MoveShip(ship, {finPos={pos=currEntry.pos, rot=currEntry.rot}, noSave=true})
            announceInfo.note = 'performed a redo of (' .. currEntry.move .. ')'
        end
    end
    AnnModule.Announce(announceInfo, 'all', ship)
    return shipMoved
end

-- Get the last move code from ship history
-- Always returns an "entry" table, if there's no move, move key is 'none'
MoveModule.GetLastMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey < 1 then
        return {move='none'}
    else
        return Lua_ShallowCopy(histData.history[histData.actKey])
    end
end

-- Get some old move from ship history (arg in number of moves back)
-- Always returns an "entry" table, if there's no move, move key is 'none'
MoveModule.GetOldMove = function(ship, numMovesBack)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey-numMovesBack < 1 then
        return {move='none'}
    else
        return Lua_ShallowCopy(histData.history[histData.actKey-numMovesBack])
    end
end

-- THING THAT ALLOWS US TOR ESTORE SHIP POSITION AFTER IT WAS DELETED
-- Table of deleted ships last positions
MoveModule.emergencyRestore = {}
-- Pointer at the most recently added restore entry
MoveModule.restoreBufferPointer = 0
-- Max size of the restore entry table
MoveModule.restoreBufferSize = 25
-- Restore command
XW_cmd.AddCommand('restore#[1-9][0-9]?', 'historyHandle')

-- Try to restore some ship position to an entry with given key
MoveModule.Restore = function(ship, key)
    if #MoveModule.emergencyRestore < key or key <= 0 then
        AnnModule.Announce({type='historyHandle', note='Restore key (number after the #) invalid'}, 'all')
        return false
    else
        local data = MoveModule.emergencyRestore[key]
        ship.setPosition(data.savedPos.pos)
        ship.setRotation(data.savedPos.rot)
        MoveModule.SaveStateToHistory(ship, true)
        AnnModule.Announce({type='historyHandle', note='has been restored to position ' .. data.srcName .. ' was last seen at'}, 'all', ship)
        return true
    end
end

-- Save some restore data and notify the user of it
MoveModule.AddRestorePoint = function(entry)
    local newKey = MoveModule.restoreBufferPointer + 1
    if newKey > MoveModule.restoreBufferSize then
        newKey = 1
    end
    AnnModule.Announce({type='historyHandle', note=entry.srcName .. '\'s ship has been deleted - you can respawn the model and use \'restore#' .. newKey .. '\' command to restore its position'}, 'all')
    MoveModule.emergencyRestore[newKey] = entry
    MoveModule.restoreBufferPointer = newKey
end

-- Handle destroyed objects
-- Create a restore entry from last set position in history
-- Delete history if present
MoveModule.onObjectDestroyed = function(obj)
    if not XW_ObjMatchType(obj, 'ship') then return end
    if MoveModule.GetLastMove(obj).move ~= 'none' then
        local lastMove = MoveModule.GetLastMove(obj)
        MoveModule.AddRestorePoint({srcName=obj.getName(), savedPos={pos=lastMove.pos, rot=lastMove.rot}})
    end
    for k,hist in pairs(MoveModule.moveHistory) do
        if hist.ship == ship then
            table.remove(MoveModule.moveHistory, k)
            break
        end
    end
end

-- Get the history table with "serialized" positions/rotations
-- I hate this so much
-- Devs, fix your shit, goddamnit
MoveModule.GetSaveData = function()
    local currHistory = {}
    for k,hist in pairs(MoveModule.moveHistory) do
        if hist.history[1] ~= nil then
            local currEntry = MoveModule.GetLastMove(hist.ship)
            currEntry.pos = TTS_Serialize(currEntry.pos)
            currEntry.rot = TTS_Serialize(currEntry.rot)
            table.insert(currHistory, {ship=hist.ship.getGUID(), actKey=1, history={currEntry}})
        end
    end
    if currHistory[1] == nil then return nil else
    return currHistory end
end

-- On load, restore data
MoveModule.onLoad = function(saveTable)
    MoveModule.RestoreSaveData(saveTable)
end

-- Restore provided table and notify of the results
MoveModule.RestoreSaveData = function(saveTable)
    if saveTable == nil then
        return
    end
    local annInfo = {}
    annInfo.type = 'info'
    local count = 0
    local missCount = 0
    for k,hist in pairs(saveTable) do
        hist.ship = getObjectFromGUID(hist.ship)
        if hist.ship == nil then
            missCount = missCount + 1
        else
            count = count + 1
            table.insert(MoveModule.moveHistory, hist)
        end
    end
    annInfo.note = 'LOAD: Restored last position save for ' .. count .. ' ship(s)'
    if missCount > 0 then
        annInfo.note = ' (' .. missCount .. ' ship model(s) missing)'
    end
    if count > 0 or missCount > 0 then
        AnnModule.Announce(annInfo, 'all')
    end
end

-- Join hit tables t1 .. t5 resulting from Physics.cast call
-- Return a table of unique objects that pass selection function
-- (apaprently cant use '...' arg type when a function is a table field)
-- Arguments:
--      exclObj     <- object excluded from return table (for casts over a ship)
--      SelectFun   <- function taking an object and returning true/false (obj type selection)
--      t1 .. t5    <- hit tables returned from Physics.cast, some can be nil or empty
-- Return:
--      Concatenated table of unique objects from hit tables that also passed selection function
MoveModule.JoinHitTables = function(exclObj, SelectFun, t1, t2, t3, t4, t5)
    local gTable = {[exclObj.getGUID()]=true}
    local out = {}
    local tbls = {a=t1, b=t2, c=t3, d=t4, e=t5}
    for k,hTable in pairs(tbls) do
        for k2,hit in pairs(hTable) do
            if SelectFun(hit.hit_object) and gTable[hit.hit_object.getGUID()] == nil then
                gTable[hit.hit_object.getGUID()] = true
                table.insert(out, hit.hit_object)
            end
        end
    end
    return out
end

-- Selection function for MoveModule.JoinHitTables - ships only
MoveModule.SelectShips = function(obj)
    return (obj.tag == 'Figurine')
end

-- Selection function for MoveModule.JoinHitTables - obstacles only
MoveModule.SelectObstacles = function(obj)
    return (obj.getName():find('Asteroid') ~= nil or obj.getName():find('Debris') ~= nil)
end

-- Selection function for MoveModule.JoinHitTables - mine tokens only
MoveModule.SelectMineTokens = function(obj)
    return (obj.getName():find('Mine') ~= nil or obj.getName():find('Connor') ~= nil or obj.getName():find('Chute debris') ~= nil)
end

-- Selection function for MoveModule.JoinHitTables - anything aside from global table object
MoveModule.SelectAny = function(obj)
    return obj.getGUID() ~= nil
end

-- Cast data for checking collisions over a ship type shape
MoveModule.castData = {}
MoveModule.castData.small = {}
MoveModule.castData.small.base = {
    direction={0, 1, 0},
    type=3,
    size={Convert_mm_igu(20), Convert_mm_igu(3), Convert_mm_igu(20)}
    -- + Origin
    -- + Orientation
}
MoveModule.castData.small.nubFR = {
    localPos = {-1*Convert_mm_igu(11.38), Convert_mm_igu(-1.86), -1*Convert_mm_igu(20.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.small.nubFL = {
    localPos = {Convert_mm_igu(11.38), Convert_mm_igu(-1.86), -1*Convert_mm_igu(20.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.small.nubBR = {
    localPos = {-1*Convert_mm_igu(11.38), Convert_mm_igu(-1.86), Convert_mm_igu(20.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.small.nubBL = {
    localPos = {Convert_mm_igu(11.38), Convert_mm_igu(-1.86), Convert_mm_igu(20.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.large = {}
MoveModule.castData.large.base = {
    direction={0, 1, 0},
    type=3,
    size={Convert_mm_igu(40), Convert_mm_igu(3), Convert_mm_igu(40)}
    -- + Origin
    -- + Orientation
}
MoveModule.castData.large.nubFR = {
    localPos = {-1*Convert_mm_igu(11.38), Convert_mm_igu(-1.86), -1*Convert_mm_igu(40.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.large.nubFL = {
    localPos = {Convert_mm_igu(11.38), Convert_mm_igu(-1.86), -1*Convert_mm_igu(40.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.large.nubBR = {
    localPos = {-1*Convert_mm_igu(11.38), Convert_mm_igu(-1.86), Convert_mm_igu(40.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}
MoveModule.castData.large.nubBL = {
    localPos = {Convert_mm_igu(11.38), Convert_mm_igu(-1.86), Convert_mm_igu(40.858)},
    direction = {0, 1, 0},
    type=2,
    size={Convert_mm_igu(1.8), Convert_mm_igu(4), Convert_mm_igu(1.8)}
    -- + Origin
}

-- Get cast data for particular ship situation
-- Arguments:
--      ship        <- ship ref (for base size)
--      shipPosRot  <- table with ship check position and rotation ('pos' and 'rot' keys)
--      castType    <- 'base' for base, 'nub[FB][RL]' for one of four nubs
-- Return:
--      Table ready to be fed to Physics.cast
MoveModule.GetCast = function(ship, shipPosRot, castType)
    local castTable = MoveModule.castData[DB_getBaseSize(ship)][castType]
    if castType == 'base' then
        castTable.origin = shipPosRot.pos
        castTable.orientation = shipPosRot.rot
        return castTable
    else
        castTable.origin = Vect_Sum(shipPosRot.pos, Vect_RotateDeg(castTable.localPos, shipPosRot.rot[2]))
        return castTable
    end
end

-- Return all objects that pass selection function and would overlap ship in some situation
-- Arguments:
--      ship        <- ship ref (for base size)
--      shipPosRot  <- table with ship check position and rotation ('pos' and 'rot' keys)
--      SelectFun   <- selection function that returns true/false for an object
-- Return:
--      Concatenated table of all objects that would overlap ship in this situation and pass select function
MoveModule.FullCastCheck = function(ship, shipPosRot, SelectFun)
    return MoveModule.JoinHitTables(
    ship,
    SelectFun,
    Physics.cast(MoveModule.GetCast(ship, shipPosRot, 'base')),
    Physics.cast(MoveModule.GetCast(ship, shipPosRot, 'nubFR')),
    Physics.cast(MoveModule.GetCast(ship, shipPosRot, 'nubFL')),
    Physics.cast(MoveModule.GetCast(ship, shipPosRot, 'nubBR')),
    Physics.cast(MoveModule.GetCast(ship, shipPosRot, 'nubBL'))
    )
end

-- Check if provided ship in a provided position/rotation would collide with anything from the provided table
-- Return: {coll=collObject, minMargin=howFarCollisionIsStillCertain, numCheck=numCollideChecks}
MoveModule.CheckCollisions = function(ship, shipPosRot, collShipTable)
    local info = {coll=nil, minMargin=0, numCheck=0, numCast=0}
    local shipInfo = {pos=shipPosRot.pos, rot=shipPosRot.rot, ship=ship}
    local shipSize = DB_getBaseSize(ship)
    local certShipReach = Convert_mm_igu(mm_baseSize[shipSize]/2)              -- distance at which other ships MUST bump it
    local maxShipReach = Convert_mm_igu(mm_baseSize[shipSize]*math.sqrt(2)/2)  -- distance at which other ships CAN bump it

    for k, collShip in pairs(collShipTable) do
        local collShipSize = DB_getBaseSize(collShip)
        local certBumpDist = certShipReach + Convert_mm_igu(mm_baseSize[collShipSize]/2)            -- distance at which these two particular ships ships MUST bump
        local maxBumpDist = maxShipReach + Convert_mm_igu(mm_baseSize[collShipSize]*math.sqrt(2)/2) -- distance at which these two particular ships ships CAN bump

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
        end
    end
    if info.coll == nil then
        local hTable = MoveModule.FullCastCheck(ship, shipPosRot,  MoveModule.SelectShips)
        info.coll = hTable[1]
    end
    return info
end

MoveModule.partResolutionRough = 1/100  -- Resolution for rough checks (guaranteed)
MoveModule.partResolutionFine = 1/1000  -- Resolution for fine checks  (for forward adjust)

-- Module for trying and finding free positions
MoveModule.MoveProbe = {}

-- Get near ships when trying a move that allows for partial execution
-- Args: SEE MoveModule.MoveProbe.GetFreePart
-- Return: {shipRef1, shipRef2, ... , shipRefN}
MoveModule.MoveProbe.GetShipsNearPart = function(info, ship, partFun, partRange)
    local middlePart = (partRange.to - partRange.from)/2
    local maxShipReach = Convert_mm_igu(mm_baseSize[info.size]*math.sqrt(2))/2
    local moveReach = math.max( Dist_Pos(partFun(info.code, ship, middlePart).pos, partFun(info.code, ship, partRange.to).pos),
                                Dist_Pos(partFun(info.code, ship, middlePart).pos, partFun(info.code, ship, partRange.from).pos) )
    local collShipRange = moveReach + maxShipReach + Convert_mm_igu(mm_largeBase*math.sqrt(2))/2 + Convert_mm_igu(10)
    return XW_ObjWithinDist(partFun(info.code, ship, MoveData.partMax/2).pos, collShipRange, 'ship', {ship})
end
-- Get first free part for a partial-enabled move (going through parts as partRange specifies)
-- Args:
--      info        <- move info as per MoveData.DecodeInfo
--      ship        <- object ref to a ship we want to move
--      partFun     <- function that takes (moveInfo, shipRef, part) and returns {pos=position, rot=rotation} (pure data, ignores collisions)
--      partRange   <- { from = partValueFromToCheck, to = partValueToCheckTo} ((from < to), (from > to) and (from == to) to all handled)
-- Return:  {
--      part        <- number of the part that was last checked (first free if other args specify free part was found)
--      info        <- nil if free part was found sowmehere, 'first' if partRange.from was free, 'overlap' if no part was free
--      collObj     <- nil if first part was free, object ref to last colliding ship otherwise
--          }
MoveModule.MoveProbe.GetFreePart = function(info, ship, partFun, partRange, moveLength)
    if moveLength == nil then moveLength = 0 end
    moveLength = Convert_mm_igu(moveLength)
    local out = {part = nil, info = nil, collObj = nil}
    local checkNum = {rough=0, fine=0}

    -- Get ships that *can* possibly collide during this move
    local collShips = MoveModule.MoveProbe.GetShipsNearPart(info, ship, partFun, partRange)

    -- Current part and part delts for ROUGH CHECKING
    local actPart = partRange.from
    local partDelta = math.sgn(partRange.to - partRange.from)*(MoveData.partMax*MoveModule.partResolutionRough)
    local minPartDelta = math.abs(partDelta)
    local collision = false

    -- Collision check, then part delta step or margin step
    repeat
        local nPos = partFun(info.code, ship, actPart)
        local collInfo = MoveModule.CheckCollisions(ship, nPos, collShips)
        checkNum.rough = checkNum.rough + collInfo.numCheck
        local distToSkip = nil
        if collInfo.coll ~= nil then
            collision = true
            distToSkip = collInfo.minMargin
            -- If there is a distance we can travel that assures collison will not end
            if distToSkip > 0 then
                -- Calculate how big part it is and skip away
                partDelta = math.sgn(partDelta)*((distToSkip * MoveData.partMax)/moveLength)
                if math.abs(partDelta) < minPartDelta then partDelta = math.sgn(partDelta)*minPartDelta end
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
    -- until we're out of collisions OR we're out of part range
    until collision == false or ((partRange.to - actPart)*math.sgn(partDelta) < 0) or partDelta == 0

    if collision == false and partDelta ~= 0 and actPart ~= partRange.from then
        -- Right now, we're out of any collisions or at part 0 (no move)
        -- Go fineResolution of a move forward until we have a collision, then skip one back
        partDelta = math.sgn(partRange.to - partRange.from)*(MoveData.partMax*MoveModule.partResolutionFine)*-1
        local collInfo
        repeat
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
        -- This happens if rough check didn't do anything (first part free, but no fullMove function)
        out.part = actPart
        out.info = 'first'
    elseif collision == true then
        -- This happens if rough check didn't escape collisions (no free part)
        out.info = 'overlap'
        out.part = partRange.to
    end
    -- print('-- GetFreePart CHECK_COUNT: ' .. checkNum.rough+checkNum.fine .. ' (' .. checkNum.rough .. ' + ' .. checkNum.fine .. ')')
    return out
end
-- Get near ships when trying a move that only allows for full execution
-- Args: SEE MoveModule.MoveProbe.TryFullMove
-- Return: {shipRef1, shipRef2, ... , shipRefN}
MoveModule.MoveProbe.GetShipsNearFull = function(info, ship, fullFun)
    local maxShipReach = Convert_mm_igu(mm_baseSize[info.size]*math.sqrt(2))/2
    local collShipRange = maxShipReach + Convert_mm_igu(mm_largeBase*math.sqrt(2))/2 + Convert_mm_igu(10)
    return XW_ObjWithinDist(fullFun(info.code, ship).pos, collShipRange, 'ship', {ship})
end
-- Try a full version of a move
-- Args:
--      info        <- move info as per MoveData.DecodeInfo
--      ship        <- object ref to a ship we want to move
--      fullFun     <- function that takes (moveInfo, shipRef) and returns {pos=position, rot=rotation} (pure data, ignores collisions)
-- Return:  {
--      done        <- TRUE if move was completed, FALSE if it was obstructed
--      collObj     <- nil if completed, object ref to colliding ship otherwise
--          }
MoveModule.MoveProbe.TryFullMove = function(info, ship, fullFun)
    local collShips = MoveModule.MoveProbe.GetShipsNearFull(info, ship, fullFun)
    local out = {done=nil, collObj=nil}
    local checkNum = 0

    fullInfo = MoveModule.CheckCollisions(ship, fullFun(info.code, ship), collShips)
    checkNum = checkNum + fullInfo.numCheck
    if fullInfo.coll == nil then
        out.done = true
        return out
    else
        out.done = false
        out.collObj = fullInfo.coll
        return out
    end
end

-- Get the FINAL position for a given move, including partial move and collisions
-- Follows traits from MoveData.DecodeInfo to try different move functions
-- Return:  {
--      finType     <- 'slide' when did a slide, 'move' when did full/part mvoe
--                     'stationary' when there was no position change (rotation change allowed)
--                     'overlap' if there was no valid free target position
--                     IF OVERLAP, OTHER KEYS ARE TO BE IGNORED
--      finPos      <- { pos = finalPosition, rot = finalRotation }
--      collObj     <- nil if no collision, object ref to colliding ship otherwise
--      finPart     <- part of partial move/slide performed, 'max' if full move, nil if not applicable
--          }
MoveModule.GetFinalPosData = function(move_code, ship, ignoreCollisions)
    local out = {finPos = nil, collObj = nil, finType = nil, finPart = nil}
    local info = MoveData.DecodeInfo(move_code, ship)

    -- Don't bother with collisions if it's stationary
    if info.speed == 0 then
        ignoreCollisions = true
    end

    -- NON-COLLISION VERSION
    if ignoreCollisions then
        -- If move can slide at the end, get final position including 'backward'/'forward' modifiers
        if info.traits.slide == true then
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
        elseif info.traits.full == true then
        -- If full moves are allowed, get a full move
            out.finPos = MoveModule.GetFullMove(info.code, ship)
            if info.speed == 0 then
                out.finType = 'stationary'
            else
                out.finType = 'move'
            end
            out.finPart = 'max'
            return out
        elseif info.traits.part == true then
        -- If partial moves are allowed, get max part move
            out.finPos = MoveModule.GetPartMove(info.code, ship, MoveData.partMax)
            out.finType = 'move'
            out.finPart = 'max'
            return out
        end

    -- COLLISION VERSION
    else
        -- If move can slide at the end, check the slide parts
        -- Respect the 'forward'/'backward' option as "as far forward/backward as possible"
        -- Respect the middle slide option by checking for middle once, then treat as forward if obstructed
        if info.traits.slide == true then
            local partRange = {from=0, to=MoveData.partMax}
            if info.extra == 'forward' then
                partRange = {from=MoveData.partMax, to=0}
            elseif info.extra ~= 'backward' then
                local firstCheckRange = {from=500, to=500}
                local freePartData = MoveModule.MoveProbe.GetFreePart(info, ship, MoveModule.GetPartSlide, firstCheckRange, MoveData.SlideLength(info))
                if freePartData.info ~= 'overlap' then
                    out.finPos = MoveModule.GetPartSlide(info.code, ship, freePartData.part)
                    out.finType = 'slide'
                    out.finPart = freePartData.part
                    return out
                end
            end
            local freePartData = MoveModule.MoveProbe.GetFreePart(info, ship, MoveModule.GetPartSlide, partRange, MoveData.SlideLength(info))
            if freePartData.info ~= 'overlap' then
                out.finPos = MoveModule.GetPartSlide(info.code, ship, freePartData.part)
                out.finType = 'slide'
                out.finPart = freePartData.part
                return out
            end
        end
        -- If move allows for full move check, try it
        if info.traits.full == true then
            local fullData = MoveModule.MoveProbe.TryFullMove(info, ship, MoveModule.GetFullMove)
            if fullData.done == true then
                out.finPos = MoveModule.GetFullMove(info.code, ship)
                out.finType = 'move'
                out.finPart = 'max'
                return out
            end
        end
        -- If move allows for partial execution, try to find a free part
        if info.traits.part == true then
            local partRange = {from=MoveData.partMax, to=0}
            local freePartData = MoveModule.MoveProbe.GetFreePart(info, ship, MoveModule.GetPartMove, partRange, MoveData.MoveLength(info))
            if freePartData.info ~= 'overlap' then
                out.finPos = MoveModule.GetPartMove(info.code, ship, freePartData.part)
                out.finType = 'move'
                out.finPart = freePartData.part
                out.collObj = freePartData.collObj
                return out
            end
        end
        -- If nothing worked out, we have an all-overlap
        out.finType = 'overlap'
        out.finPos = {pos=ship.getPosition(), rot=ship.getRotation()}
        return out
    end
end

--[[

--------
-- DANGER ZONE
-- SOON TO BE DELETED

XW_cmd.AddCommand('d:x[rle]', 'demoMove')
XW_cmd.AddCommand('d:x[rle][fb]', 'demoMove')
XW_cmd.AddCommand('d:c[srle]', 'demoMove')
XW_cmd.AddCommand('d:c[rle][fb]', 'demoMove')
XW_cmd.AddCommand('d:t[rle][123][str]?', 'demoMove')
XW_cmd.AddCommand('d:b[rle][123][sr]?', 'demoMove')
XW_cmd.AddCommand('d:[sk][012345][r]?', 'demoMove')

-- DANGER ZONE
-- SOON TO BE DELETED

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

-- DANGER ZONE
-- SOON TO BE DELETED

demoMoveData = nil

function DemoMoveCoroutine()
    local data = demoMoveData
        XW_cmd.SetBusy(data.ship)
    local movePartDelta = 0
    local slidePartDelta = 0
    if MoveData.MoveLength(data.moveInfo) ~= nil then
        movePartDelta = 300/MoveData.MoveLength(data.moveInfo)
    end
    if MoveData.SlideLength(data.moveInfo) ~= nil then
        slidePartDelta = 300/MoveData.SlideLength(data.moveInfo)
    end

    -- DANGER ZONE
    -- SOON TO BE DELETED

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

        -- DANGER ZONE
        -- SOON TO BE DELETED

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

        -- DANGER ZONE
        -- SOON TO BE DELETED

        coroutine.yield(0)
    end

    demoMoveData = nil
    XW_cmd.SetReady(data.ship)
    return 1
end

-- END DANGER ZONE
--------

]]--

--------

-- Move ship to some position and handle stuff around it
-- If move is not stationary, clear target position and move tokens with it
-- Add history entry if save move name is provided
-- Args:
--      ship        <- object reference to ship to move
--      finData     <- {pos = targetPos, rot=targetRot}
--      saveName    <- move code for history save, no save done if nil
MoveModule.MoveShip = function(ship, finData, saveName)
    XW_cmd.SetBusy(ship)
    MoveModule.RemoveOverlapReminder(ship)
    if finData.type ~= 'stationary' then
        TokenModule.QueueShipTokensMove(ship)
        local shipReach = Convert_mm_igu(mm_baseSize[DB_getBaseSize(ship)]+5)*(math.sqrt(2)/2)
        TokenModule.ClearPosition(finData.finPos.pos, shipReach, ship)
    end
    local finPos = finData.finPos
    if finData.noSave ~= true then
        MoveModule.SaveStateToHistory(ship, true)
    end
    ship.setPositionSmooth(finPos.pos, false, true)
    ship.setRotationSmooth(finPos.rot, false, true)
    -- Wait for resting, but provide final position to set so smooth move doesn't fuck with accuracy
    MoveModule.WaitForResting(ship, finPos)
    if saveName ~= nil then
        MoveModule.AddHistoryEntry(ship, {pos=finPos.pos, rot=finPos.rot, move=saveName, part=finData.finPart, finType=finData.finType})
    end
end

-- This part controls the waiting part of moving
-- Basically, if anything needs to be done after the ship rests, this can trigger it

-- Ships waiting to be resting
-- Entry: {ship = shipRef, finPos={pos=posToSet, rot=rotToSet}}
MoveModule.restWaitQueue = {}

-- Tokens waiting to be moved with ships
-- Entry: { tokens={t1, t2, ... , tN}, ship=shipWaitingFor }
-- tX: {ref = tokenRef, relPos = pos, relRot = rot}
-- elements wait here until ships are ready
MoveModule.tokenWaitQueue = {}

-- Add ship to the queue so it fires once it completes the move
-- OPTIONAL: finPos     <- position to be set at the end of the wait
-- OPTIONAL: finFun     <- function to be execeuted at the end of the wait (argument: waiting ship)
MoveModule.WaitForResting = function(ship, finPos, finFun)
    table.insert(MoveModule.restWaitQueue, {ship=ship, finPos=finPos, finFun=finFun})
    startLuaCoroutine(Global, 'restWaitCoroutine')
end

-- This completes when a ship is resting at a table level
-- Does token movement and ship locking after
-- IF a final position was provided in the data table, set it at the end
-- IF a final function was provideed in the data table, execute it at the end
function restWaitCoroutine()
    if MoveModule.restWaitQueue[1] == nil then
        return 1
    end

    local waitData = MoveModule.restWaitQueue[#MoveModule.restWaitQueue]
    local actShip = waitData.ship
    local finPos = waitData.finPos
    local finFun = waitData.finFun
    table.remove(MoveModule.restWaitQueue, #MoveModule.restWaitQueue)
    -- Wait
    repeat
        coroutine.yield(0)
    until actShip.resting == true and actShip.isSmoothMoving() == false and actShip.held_by_color == nil and actShip.getVar('slideOngoing') ~= true

    if finPos ~= nil then
        actShip.setPosition(finPos.pos)
        actShip.setRotation(finPos.rot)
    end

    local newTokenTable = {}
    for k,tokenSetInfo in pairs(MoveModule.tokenWaitQueue) do
        -- Move and pop waiting tokens
        if tokenSetInfo.ship == actShip then
            for k2,tokenData in pairs(tokenSetInfo.tokens) do
                local offset = Vect_RotateDeg(tokenData.relPos, actShip.getRotation()[2])
                local dest = Vect_Sum(offset, actShip.getPosition())
                dest[2] = dest[2]+0.5
                dest = TokenModule.VisiblePosition(tokenData.ref, tokenSetInfo.ship, dest)
                tokenData.ref.setPositionSmooth(dest)
                local tRot = tokenData.ref.getRotation()
                tokenData.ref.setRotationSmooth({tRot[1], actShip.getRotation()[2] + tokenData.relRot, tRot[3]})
                tokenData.ref.highlightOn({0, 1, 0}, 2)
            end
        else
            -- Index back tokens that are not waiting for this ship
            table.insert(newTokenTable, tokenSetInfo)
        end
    end

    MoveModule.tokenWaitQueue = newTokenTable
    actShip.lock()
    actShip.highlightOn({0, 1, 0}, 0.1)
    XW_cmd.SetReady(actShip)
    if finFun ~= nil then
        finFun(actShip)
    end
    return 1
end

-- Perform move designated by move_code on a ship and announce the result
-- How move is preformed generally relies on MoveData.DecodeInfo for its code
-- Includes token handling so nothing obscurs the final position
-- Starts the wait coroutine that handles stuff done when ship settles down
MoveModule.PerformMove = function(move_code, ship, ignoreCollisions)
    ship.lock()
    local info = MoveData.DecodeInfo(move_code, ship)
    local finData = MoveModule.GetFinalPosData(move_code, ship, ignoreCollisions)
    local annInfo = {type=finData.finType, note=info.note, code=info.code}
    if finData.finType == 'overlap' then
        annInfo.note = info.collNote
    elseif finData.finType == 'slide' then
        -- I feel like something was supposed to be here
    elseif finData.finType == 'move' then
        if finData.collObj ~= nil then
            annInfo.note = info.collNote
            annInfo.collidedShip = finData.collObj
        end
    elseif finData.finType == 'stationary' then
        -- And here as well
    end

    if finData.finType ~= 'overlap' then
        MoveModule.MoveShip(ship, finData, move_code)
        if finData.collObj ~= nil then
            MoveModule.SpawnOverlapReminder(ship)
        end
    end
    AnnModule.Announce(annInfo, 'all', ship)
    MoveModule.CheckObstacleCollisions(ship, finData.finPos, true)
    MoveModule.CheckMineCollisions(ship, finData.finPos, true)
    return (finData.finType ~= 'overlap')
end

-- Spawn a 'BUMPED' informational button on the base that removes itself on click or next move
MoveModule.SpawnOverlapReminder = function(ship)
    Ship_RemoveOverlapReminder(ship)
    remindButton = {click_function = 'Ship_RemoveOverlapReminder', label = 'BUMPED', rotation =  {0, 0, 0}, width = 1000, height = 350, font_size = 250}
    if DB_isLargeBase(ship) == true then
        remindButton.position = {0, 0.2, 2}
    else
        remindButton.position = {0, 0.3, 0.8}
    end
    ship.createButton(remindButton)
end

-- Remove the 'BUMPED' dummy button from a ship
MoveModule.RemoveOverlapReminder = function(ship)
    local buttons = ship.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do if but.label == 'BUMPED' then ship.removeButton(but.index) end end
    end
end

-- Check if a ship in some situation is overlapping any obstacles
-- Highlight overlapped obstacles red
-- If 'vocal' set to true, add a notification
-- Return table of overlapped obstacles
MoveModule.CheckObstacleCollisions = function(ship, targetPosRot, vocal)
    local collList = MoveModule.FullCastCheck(ship, targetPosRot,  MoveModule.SelectObstacles)
    if collList[1] ~= nil then
        local obsList = '('
        for k,obs in pairs(collList) do
            obs.highlightOn({1, 0, 0}, 3)
            obsList = obsList .. obs.getName() .. ', '
        end
        obsList = obsList:sub(1, -3) .. ')'
        if vocal then
            AnnModule.Announce({type='warn', note=ship.getName() .. ' appears to have overlapped an obstacle ' .. obsList}, 'all')
        end
    end
    return collList
end

-- Check if a ship in some situation is overlapping any mine tokens
-- Highlight overlapped tokens red
-- If 'vocal' set to true, add a notification
-- Return table of overlapped tokens
--TODO maybe check mine colision after bomb drop?
MoveModule.CheckMineCollisions = function(ship, targetPosRot, vocal)
    local collList = MoveModule.FullCastCheck(ship, targetPosRot,  MoveModule.SelectMineTokens)
    if collList[1] ~= nil then
        local mineList = '('
        for k,mine in pairs(collList) do
            mine.highlightOn({1, 0, 0}, 3)
            mineList = mineList .. mine.getName() .. ', '
        end
        mineList = mineList:sub(1, -3) .. ')'
        if vocal then
            AnnModule.Announce({type='warn', note=ship.getName() .. ' appears to have overlapped a mine token ' .. mineList}, 'all')
        end
    end
    return collList
end

-- Remove the 'BUMPED' button from a ship (click function)
function Ship_RemoveOverlapReminder(ship)
    MoveModule.RemoveOverlapReminder(ship)
end

-- Check which ship has it's base closest to position (large ships have large bases!), that's the owner
--   also check how far it is to the owner-changing position (margin of safety)
-- Kinda tested: margin > 20mm = visually safe
-- Arg can be a token ref or a position
-- Returns {dist=distanceFromOwner, owner=ownerRef, margin=marginForNextCloseShip}
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

-- END MAIN MOVEMENT MODULE
--------

--------
-- TOKEN MODULE
-- Moves tokens, clears positions from tokens, checks its owners, deducts a visible position after a ship move

TokenModule = {}
-- Table with refs for different token and template sources
TokenModule.tokenSources = {}

-- Update token and template sources on each load
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

-- How far can tokens be to be considered owned bya  ship
TokenModule.tokenReachDistance = Convert_mm_igu(100)
-- By how much this token has to be distant from other ship "interception zone" to be visible
-- (how far from an owner-switching-border it has to be so you can see whose it is)
TokenModule.visibleMargin = Convert_mm_igu(20)

-- Preset positions for tokens on and near the base
-- Generally used only when their current position switches its owner after a move
-- Positions on the base
TokenModule.basePos = {}
-- On base - small ships
TokenModule.basePos.small = {}
TokenModule.basePos.small.Focus     = { 12,  12}
TokenModule.basePos.small.Evade     = { 12, -12}
TokenModule.basePos.small.Stress    = {-12,  12}
TokenModule.basePos.small.rest      = {-12, -12}
-- On base - large ships
TokenModule.basePos.large = {}
TokenModule.basePos.large.Focus     = { 30,  30}
TokenModule.basePos.large.Evade     = { 30,   0}
TokenModule.basePos.large.Stress    = { 30, -30}
TokenModule.basePos.large.Tractor   = {-30,  30}
TokenModule.basePos.large.Ion       = {-30,   0}
TokenModule.basePos.large.Lock      = {  0,  30}
TokenModule.basePos.large.rest      = {-30, -30}
-- Positions near the base
-- Near base - small ships
TokenModule.nearPos = {}
TokenModule.nearPos.small = {}
TokenModule.nearPos.small.Focus     = { 35,  25}
TokenModule.nearPos.small.Evade     = { 35,   0}
TokenModule.nearPos.small.Stress    = { 35, -25}
TokenModule.nearPos.small.Ion       = {-35,  25}
TokenModule.nearPos.small.Tractor   = {-35,   0}
TokenModule.nearPos.small.Lock      = {  0,  40}
TokenModule.nearPos.small.rest      = {-35, -25}
-- Near base - large ships
TokenModule.nearPos.large = {}
TokenModule.nearPos.large.Focus     = { 55,  30}
TokenModule.nearPos.large.Evade     = { 55,   0}
TokenModule.nearPos.large.Stress    = { 55, -30}
TokenModule.nearPos.large.Tractor   = {-55,  45}
TokenModule.nearPos.large.Ion       = {-55,  15}
TokenModule.nearPos.large.Weapons   = {-55, -15}
TokenModule.nearPos.large.Lock      = {  0,  50}
TokenModule.nearPos.large.rest      = {-55, -45}

-- Deduct target token position in the world for a ship, token and some entry from TokenModule.basePos or .nearPos
TokenModule.TokenPos = function(tokenName, ship, posTable)
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

-- Return position for a given token that is on the base of given ship
TokenModule.BasePosition = function(tokenName, ship)
    local name = nil
    if type(tokenName) == 'string' then
            name = tokenName
    elseif type(tokenName) == 'userdata' then
        name = tokenName.getName()
    end
    return TokenModule.TokenPos(name, ship, TokenModule.basePos)
end
-- Return position for a given token that is near the base of given ship
TokenModule.NearPosition = function(tokenName, ship)
    local name = nil
    if type(tokenName) == 'string' then
            name = tokenName
    elseif type(tokenName) == 'userdata' then
        name = tokenName.getName()
    end
    return TokenModule.TokenPos(name, ship, TokenModule.nearPos)
end

-- Return a visible position for some token near some ship
-- Priorities as follows (OK if token is still visible there as in you can see who is its owner easily):
-- 1. Prefer the position given as 3rd argument if passed
-- 2. Prefer position on a stack if a stack of tokens already belongs to a ship
-- 3. Prefer position NEAR ship base as position table dictates
-- 3. Prefer position ON ship base as position table dictates (if all else fails, this will be returned)
TokenModule.VisiblePosition = function(tokenName, ship, preferredPos)
    -- Check preferred position margin
    if preferredPos ~= nil then
        local prefInfo = TokenModule.TokenOwnerInfo(preferredPos)
        if prefInfo.owner == ship and prefInfo.margin > TokenModule.visibleMargin then
            return preferredPos
        end
    end
    -- Check for present stacks
    local currTokensInfo = TokenModule.GetShipTokensInfo(ship)
    local currStack = {qty=-2, obj=nil}
    for k,tokenInfo in pairs(currTokensInfo) do
        if tokenInfo.token.getName() == tokenName and tokenInfo.token.getQuantity() > currStack.qty and (not tokenInfo.token.IsSmoothMoving()) then
            currStack.obj = tokenInfo.token
            currStack.qty = currStack.obj.getQuantity()
        end
    end
    if currStack.obj ~= nil then
        return Vect_Sum(currStack.obj.getPosition(), {0, 0.7, 0})
    end
    -- Check for near near base position or return base position
    local nearPos = TokenModule.NearPosition(tokenName, ship)
    local nearData = TokenModule.TokenOwnerInfo(nearPos)
    if nearData.margin < TokenModule.visibleMargin then
        return TokenModule.BasePosition(tokenName, ship)
    else
        return nearPos
    end
end

-- Check which tokens belong to a ship and queue them to be moved with it
-- Needs the MoveModule.WaitForResting fired to actually use stuff from this queue
TokenModule.QueueShipTokensMove = function(ship)
    local selfTokens = TokenModule.GetShipTokens(ship)
    if selfTokens[1] == nil then
        return
    end
    -- Exclude currently used cloak tokens
    local tokensExcl = {}
    for k,token in pairs(selfTokens) do
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
    local waitTable = {tokens = {}, ship=ship}
    -- Save relative position/rotation
    for k,token in pairs(selfTokens) do
        local relPos = Vect_RotateDeg(Vect_Between(ship.getPosition(), token.getPosition()), -1*ship.getRotation()[2])
        local relRot = token.getRotation()[2] - ship.getRotation()[2]
        table.insert(waitTable.tokens, {ref=token, relPos=relPos, relRot=relRot})
    end
    table.insert(MoveModule.tokenWaitQueue, waitTable)
end

-- Table for locks to be set and callback to trigger their naming and coloring
-- Entry: {lock=targetLockRef, color=colorToTint, name=nameToSet}
TokenModule.locksToBeSet = {}

-- Callback to set ALL the locks in wueue
function TokenModule_SetLocks()
    for k,info in pairs(TokenModule.locksToBeSet) do
        info.lock.call('manualSet', {info.color, info.name})
        info.lock.highlightOn({0,0,0}, 0.01)
    end
    TokenModule.locksToBeSet = {}
end

-- Take a token of some type and move to some position
-- Player color argument only matters when taking target locks
-- Returns ref to a newly taken token
-- Highlights the token with type-aware color
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

-- Get owner info from a token or positions
-- Return:  {
--      token   <- passed token ref if arg was a token ref
--      owner   <- ship ref to owner, nil if none
--      dist    <- distance to owner (igu)
--      margin  <- how far from owner token would have to be moved to change owner
--          }
TokenModule.TokenOwnerInfo = function(tokenPos)
    local pos = nil
        local out = {token=nil, owner=nil, dist=0, margin=-1}
    if type(tokenPos) == 'table' then
        pos = tokenPos
    elseif type(tokenPos) == 'userdata' then
        out.token = tokenPos
        pos = tokenPos.getPosition()
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
    else
        out.margin = (nextNearest.dist-nearest.dist)/2
    end
    local owner = 'nil'
    if out.owner ~= nil then
        owner = out.owner.getName()
    end
    return out
end

-- Return table of MoveModule.GetTokenInfo entries for all tokens withis some distance of given position
TokenModule.GetNearTokensInfo = function(pos, dist)
    local reachDist = TokenModule.tokenReachDistance
    if dist ~= nil then
        reachDist = dist
    end
    local nearTokens = XW_ObjWithinDist(pos, reachDist, 'token')
    local shipTokensInfo = {}
    for k,token in pairs(nearTokens) do
        local tokenInfo = TokenModule.TokenOwnerInfo(token)
        table.insert(shipTokensInfo, tokenInfo)
    end
    return shipTokensInfo
end

-- Return table of MoveModule.GetTokenInfo enties for all tokens that are owned by given ship
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

-- Return table of object references for all tokens that are owned by given ship
TokenModule.GetShipTokens = function(ship)
    -- Check for nearby tokens
    local shipTokensInfo = TokenModule.GetShipTokensInfo(ship)
    local tokens = {}
    for k,tokenInfo in pairs(shipTokensInfo) do
        table.insert(tokens, tokenInfo.token)
    end
    return tokens
end

-- Clear given distance within position from tokens
-- If given third argument, this hip tokens will be ignored
-- Tokens that have an owner will be moved near(er)/on it
-- Stray tokens will be yanked away
TokenModule.ClearPosition = function(pos, dist, ignoreShip)
    local clearDist = dist + Convert_mm_igu(20)
    local posTokenInfo = TokenModule.GetNearTokensInfo(pos, clearDist)
    for k,tokenInfo in pairs(posTokenInfo) do
        if tokenInfo.token.getButtons() == nil then
            if tokenInfo.owner ~= nil and tokenInfo.owner ~= ignoreShip then
                local visPos = TokenModule.VisiblePosition(tokenInfo.token.getName(), tokenInfo.owner)
                if Dist_Pos(visPos, pos) <= clearDist then
                    local basePos = TokenModule.BasePosition(tokenInfo.token.getName(), tokenInfo.owner)
                    tokenInfo.token.setPositionSmooth(basePos)
                else
                    tokenInfo.token.setPositionSmooth(visPos)
                end
            else
                local ptVect = Vect_Between(pos, tokenInfo.token.getPosition())
                ptVect[2] = 0
                local actDist = Dist_Pos(tokenInfo.token.getPosition(), pos)
                local distToMove = 2*clearDist - actDist
                local targetPos = Vect_Sum(tokenInfo.token.getPosition(), Vect_SetLength(ptVect, distToMove))
                targetPos[2] = targetPos[2] + 0.5
                tokenInfo.token.setPositionSmooth(targetPos)
            end
        end
    end
end

-- END TOKEN MODULE
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
-- Spawn first buttons if this is an active dial or return if it's not
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

-- Active dial sets for ships
-- {Set1, Set2, ... , SetN}
-- Set: {ship=shipRef, activeDial=actDialInfo, dialSet=dialData}
-- dialData: {dial1Info, dial2Info, dial3Info ...}
-- dialInfo, actDialInfo: {dial=dialRef, originPos=origin}
DialModule.ActiveSets = {}
XW_cmd.AddCommand('rd', 'dialHandle')
XW_cmd.AddCommand('sd', 'dialHandle')


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
            ship.setVar('hasDials', false) -- Just informative
            if set.activeDial ~= nil then
                DialModule.RestoreActive(set.ship)
            end
            for k,dialData in pairs(set.dialSet) do
                dialData.dial.flip()
                dialData.dial.call('setShip', {nil})
                dialData.dial.setName('')
            end
            table.remove(DialModule.ActiveSets, k)
            AnnModule.Announce({type='info_DialModule', note='had all dials unassigned'}, 'all', ship)
            break
        end
    end
    if hadDials == false then AnnModule.Announce({type='info_DialModule', note='had no assigned dials'}, 'all', ship) end
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
    -- Force dial height so physics won't push it into the table (sometimes)
    for k,setEntry in pairs(set) do
        setEntry.originPos[2] = 1.05
        setEntry.originPos.y = 1.05
    end

    local actSet = DialModule.GetSet(ship)
    if actSet ~= nil then
        for k, newDialData in pairs(set) do
            actSet.dialSet[k] = newDialData
        end
    else
        table.insert(DialModule.ActiveSets, {ship=ship, activeDial=nil, dialSet=set})
        ship.setVar('hasDials', true)
    end
end

-- Distance (circle from ship) at which dials can be palce to be registered
saveNearbyCircleDist = Convert_mm_igu(160)

-- Save nearby dials layout
-- Detects layout center (straight dials as reference) and assigns dials that are appropriately placed
-- If dials are already assigned to this ship, they are ignored
-- If one of dials is assigned to other ship, unassign and proceed
-- TO_DO: Split this shit down
DialModule.SaveNearby = function(ship)
    local nearbyDialsAll = XW_ObjWithinDist(ship.getPosition(), saveNearbyCircleDist, 'dial')
    -- Nothing nearby
    if nearbyDialsAll[1] == nil then
        AnnModule.Announce({type='info_DialModule', note=('has no valid dials nearby')}, 'all', ship)
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
            AnnModule.Announce({type='error_DialModule', note=('One of the dials near ' .. ship.getName() .. ' has an unsupported command in the description (\'' .. dial.getDescription() .. '\'), make sure you only select the ship when inserting \'sd\'/\'cd\'')}, 'all')
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
        AnnModule.Announce({type='warn_DialModule', note=('Some dials ' .. ship.getName() .. ' is trying to save are placed outside the hidden zones!')}, 'all')
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
        AnnModule.Announce({type='warn_DialModule', note=('needs to be moved closer to the dial layout center')}, 'all', ship)
        return
    end
    -- Distance between any adjacent dials (assuming a regular grid)
    local dialSpacing = math.abs(refDial1.getPosition()[3] - refDial2.getPosition()[3])
    -- If distance between two dials appears to be huge
    if dialSpacing > Convert_mm_igu(120) then
        AnnModule.Announce({type='error_DialModule', note=('Dial layout nearest to ' .. ship.getName() .. ' seems to be invalid or not laid out on a proper grid (check dials descriptions)')}, 'all')
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
            AnnModule.Announce({type='error_DialModule', note=('Dial layout nearest to ' .. ship.getName() .. ' seems to be invalid or overlapping another layout (check dials descriptions)')}, 'all')
            return
        end
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
        AnnModule.Announce({type='warn_DialModule', note=('assigned' .. dialsStr ..  'dial(s) that previously belonged to ' .. poorShip.getName())}, 'all', ship)
    end

    -- If there are no filtered (not this ship already) dials
    if nearbyDials[1] == nil then
        AnnModule.Announce({type='info_DialModule', note=('already has all nearby dials assigned')}, 'all', ship)
        return
    end
    local dialSet = {}
    local actSet = DialModule.GetSet(ship)
    -- Break if this ship already has a dial of same description as we're trying to save
    if actSet ~= nil then
        for k,dial in pairs(nearbyDials) do
            if actSet.dialSet[dial.getDescription()] ~= nil and actSet.dialSet[dial.getDescription()] ~= dial then
                AnnModule.Announce({type='error_DialModule', note='tried to assign a second dial of same move (' .. dial.getDescription() .. ')'}, 'all', ship)
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
            AnnModule.Announce({type='error_DialModule', note='tried to assign few dials with same move (' .. dialOK.getDescription() .. ')'}, 'all', ship)
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
    AnnModule.Announce({type='info_dialModule', note='had ' .. dialCount .. ' dials assigned (' .. DialModule.DialCount(ship) .. ' total now)' }, 'all', ship)
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
    return (dial.getVar('assignedShip') ~= nil)
end

-- Handle destroyed objects that may be of DialModule interest
DialModule.onObjectDestroyed = function(obj)
    -- Remove dial set of destroyed ship
    if obj.tag == 'Figurine' then
        if DialModule.GetSet(obj) ~= nil then
            DialModule.RemoveSet(obj)
        end
        -- Unassign deleted dial
    elseif obj.tag == 'Card' and obj.getDescription() ~= '' then
        if DialModule.isAssigned(obj) then
            if not DialModule.PreventDelete(obj) then
                DialModule.UnassignDial(obj)
            end
        end
    elseif obj.getName() == 'Target Lock' then
        for k,lockInfo in pairs(TokenModule.locksToBeSet) do
            if lockInfo.lock == obj then table.remove(TokenModule.locksToBeSet, k) break end
        end
    end
    for k,info in pairs(DialModule.SpawnedTemplates) do
        if info.ship == obj or info.template == obj then
            info.template.destruct()
            table.remove(DialModule.SpawnedTemplates, k)
        end
    end
end

-- Table of dials that were restored to prevent accidentally breaking dial sets
-- Key: Owner ship GUID
-- Entry: { dial = restoredDialRef, keep = noMoreWasDeleted}
DialModule.restoredDials = {}

-- Prevent deletion of a single dial
-- If it is the first deleted dial, restore it and set a timer
-- If no other dials from the set were destroyed while timer ran, keep restored dial
-- Otherwise delete restored dial when timer expires
DialModule.PreventDelete = function(dial)
    if dial.getVar('noRestore') then
        return false
    end
    local ship = dial.getVar('assignedShip')
    if ship ~= nil then
        -- Restore dial, add entry, run timer
        if DialModule.restoredDials[ship.getGUID()] == nil then
            local set = DialModule.GetSet(ship)
            local activeDial = (set.activeDial ~= nil and set.activeDial.dial == dial)
            local newDial = dial.clone()
            newDial.setVar('assignedShip', ship)
            set.dialSet[dial.getDescription()].dial = newDial
            DialModule.RestoreDial(newDial)
            DialModule.restoredDials[ship.getGUID()] = { dial = newDial, keep = true }
            Timer.create({ identifier = ship.getGUID(), function_name = 'DialModule_ResetRestored', parameters = { guid = ship.getGUID(), active = activeDial}, delay = 0.5 })
            return true
        else
        -- Flag restored dial to be deleted later
            DialModule.restoredDials[ship.getGUID()].keep = false
            return false
        end
    end
end

-- Timer expiration function for dial restore
-- If no other dials from set were deleted, notify about restoration
-- Otherwise delete the restored dial as well (flag as non-erstorable cause it will pop up there next frame)
function DialModule_ResetRestored(params)
    local shipGUID = params.guid
    if DialModule.restoredDials[shipGUID].keep then
        local shipName = DialModule.restoredDials[shipGUID].dial.getVar('assignedShip').getName()
        local dialDesc = DialModule.restoredDials[shipGUID].dial.getDescription()
        local activeStatus = 'ACTIVE (drawn out) '
        if not params.active then activeStatus = '' end
        AnnModule.Announce({ type = 'info', note = shipName .. '\'s ' .. activeStatus .. 'dial (' .. dialDesc .. ') was just restored - do not delete single dials!'}, 'all')
    else
        if DialModule.restoredDials[shipGUID].dial ~= nil then
            DialModule.restoredDials[shipGUID].dial.setVar('noRestore', true)
            DialModule.restoredDials[shipGUID].dial.destruct()
        end
    end
    DialModule.restoredDials[shipGUID] = nil
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
    if saveTable == nil then return end
    for k,set in pairs(DialModule.ActiveSets) do
        DialModule.RemoveSet(set.ship)
    end
    local annInfo = {}
    annInfo.type = 'info'
    local count = 0
    local missShipCount = 0
    local missDialCount = 0
    for k,set in pairs(saveTable) do
        if getObjectFromGUID(set.ship) == nil then
            missShipCount = missShipCount + 1
        else
            DialModule.ActiveSets[k] = {ship=getObjectFromGUID(set.ship), dialSet={}}
            for k2,dialInfo in pairs(set.dialSet) do
                if getObjectFromGUID(dialInfo.dial) ~= nil then
                    DialModule.ActiveSets[k].dialSet[k2] = {dial=getObjectFromGUID(dialInfo.dial), originPos=dialInfo.originPos}
                    getObjectFromGUID(dialInfo.dial).call('setShip', {getObjectFromGUID(set.ship)})
                else
                    missDialCount = missDialCount + 1
                end
            end
            getObjectFromGUID(set.ship).setVar('hasDials', true)
            if set.activeDialGUID ~= nil then
                local actDial = getObjectFromGUID(set.activeDialGUID)
                DialModule.RestoreDial(actDial)
            end
            count = count + 1
        end
    end
    annInfo.note = 'LOAD: Restored ' .. count .. ' saved dial set(s)'
    if missShipCount+missDialCount > 0 then
        annInfo.note = annInfo.note .. ' ('
        if missShipCount > 0 then
            annInfo.note = annInfo.note .. missShipCount .. ' ship model(s) missing'
        end
        if missDialCount > 0 then
            if missShipCount > 0 then
                annInfo.note = annInfo.note .. ', '
            end
            annInfo.note = annInfo.note .. missDialCount .. ' dial card(s) missing'
        end
        annInfo.note = annInfo.note .. ')'
    end
    if count+missShipCount+missDialCount > 0 then
        AnnModule.Announce(annInfo, 'all')
    end
end

-- Retrieve all sets data with serialize-able guids instead of objects references
DialModule.GetSaveData = function()
    local saveTable = {}
    for k,set in pairs(DialModule.ActiveSets) do
        saveTable[k] = {ship=set.ship.getGUID(), dialSet={}}
        if set.activeDial ~= nil then saveTable[k].activeDialGUID = set.activeDial.dial.getGUID() end
        for k2,dialInfo in pairs(set.dialSet) do
            saveTable[k].dialSet[k2] = {dial=dialInfo.dial.getGUID(), originPos=TTS_Serialize(dialInfo.originPos)}
        end
    end
    if saveTable[1] == nil then return nil
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
    if type:find('ruler') ~= nil then
        local scPos = type:find(':')
        local rulerCode = type:sub(scPos+1,-1)
        RulerModule.ToggleRuler(ship, rulerCode)
        return
    elseif type:find('spawnMoveTemplate') ~= nil then
        if DialModule.DeleteTemplate(ship) == false then
            local scPos = type:find(':')
            local dialCode = type:sub(scPos+1,-1)
            if DialModule.SpawnTemplate(ship, dialCode) ~= nil then
                announceInfo.note = 'spawned a move template'
            else
                announceInfo.note = 'looks at you weird'
            end
        else
            return
        end
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
    AnnModule.Announce(announceInfo, 'all', ship)
end

-- Spawned tempaltes are kept there
-- Entry: {ship=shipRef, template=templateObjRef}
DialModule.SpawnedTemplates = {}

-- Position data for template spawning
-- "Trim" entries are to fine-tune the position
-- (its quite rough by the numbers since their origin was not perfectly at the center)
DialModule.TemplateData = {}
DialModule.TemplateData.straight = {}
DialModule.TemplateData.straight[1] = {0, -2.5, 20, 0}
DialModule.TemplateData.straight[2] = {0, -2.5, 40, 0}
DialModule.TemplateData.straight[3] = {0, -2.5, 60, 0}
DialModule.TemplateData.straight[4] = {0, -2.5, 80, 0}
DialModule.TemplateData.straight[5] = {0, -2.5, 100, 0}
DialModule.TemplateData.bank = {}
DialModule.TemplateData.bank.leftRot = 45
DialModule.TemplateData.bank.trim = { left = {{-2,0,-4,0}, {-5.5,0,-5.2,0}, {-9.3,0,-6.45,0}}, right={{4.2,0,1.2,0}, {7.8,0,-0.3,0}, {11.5,0,-1.4,0}} }
DialModule.TemplateData.bank[1] = {80*(1-math.cos(math.pi/8)), 0, 80*math.sin(math.pi/8), 180}
DialModule.TemplateData.bank[2] = {130*(1-math.cos(math.pi/8)), 0, 130*math.sin(math.pi/8), 180}
DialModule.TemplateData.bank[3] = {180*(1-math.cos(math.pi/8)), 0, 180*math.sin(math.pi/8), 180}
DialModule.TemplateData.turn = {}
DialModule.TemplateData.turn.leftRot = 90
DialModule.TemplateData.turn.trim = { left = {{0,-2.5,0,0}, {-3,-2.5,-3.66,0}, {-4.7,-2.5,-7.5,0}}, right={{0,-2.5,0,0}, {3,-2.5,-4.1,0}, {4.5,-2.5,-7.8,0}} }
DialModule.TemplateData.turn[1] = {35*(1-math.cos(math.pi/4))+2, 0, 35*math.sin(math.pi/4)-2, 180}
DialModule.TemplateData.turn[2] = {62.5*(1-math.cos(math.pi/4))+5, 0, 62.5*math.sin(math.pi/4)-4, 180}
DialModule.TemplateData.turn[3] = {90*(1-math.cos(math.pi/4))+9, 0, 90*math.sin(math.pi/4)-6, 180}

DialModule.TemplateData.baseOffset = {}
DialModule.TemplateData.baseOffset.small = {0, 0, 20, 0}
DialModule.TemplateData.baseOffset.large = {0, 0, 40, 0}


-- Spawn a tempalte on given ship
-- dialCode is move code PLUS identifier if ship arelready did it or not
-- be3_A means "spawn a bank left 3 template behind me" (A as in after move)
-- tr1_B means "spawn a turn right 1 tempalte in front of me" (B as in before move)
-- Return template reference
-- TODO toggletemplate?
DialModule.SpawnTemplate = function(ship, dialCode)
    local moveCode = dialCode:sub(1, -3)
    local moveInfo = MoveData.DecodeInfo(moveCode, ship)
    if moveInfo.speed == 0 then
        return nil
    end
    local tempEntry = DialModule.TemplateData[moveInfo.type][moveInfo.speed]
    tempEntry = Vect_Sum(tempEntry, DialModule.TemplateData.baseOffset[DB_getBaseSize(ship)])
    local ref = ship
    if dialCode:sub(-1,-1) == 'A' then
        ref = MoveModule.GetOldMove(ship, 1)
    end
    --TODO LAST MOVE LOGIC OUT!!!
    --TODO dont barf if no last move
    if moveInfo.dir == 'left' then
        tempEntry = MoveData.LeftVariant(tempEntry)
        tempEntry[4] = tempEntry[4] + 180 - DialModule.TemplateData[moveInfo.type].leftRot
    end
    if moveInfo.extra == 'reverse' then
        tempEntry = MoveData.ReverseVariant(tempEntry)
        if moveInfo.type ~= 'straight' then
            tempEntry[4] = tempEntry[4] - DialModule.TemplateData[moveInfo.type].leftRot
        end
    end
    if moveInfo.dir ~= nil then
        if moveInfo.extra ~= 'reverse' then
            tempEntry = Vect_Sum(tempEntry, DialModule.TemplateData[moveInfo.type].trim[moveInfo.dir][moveInfo.speed])
        else
            if moveInfo.dir == 'right' then
                moveInfo.dir = 'left'
            elseif moveInfo.dir == 'left' then
                moveInfo.dir = 'right'
            end
            tempEntry = Vect_Sum(tempEntry, Vect_ScaleEach(DialModule.TemplateData[moveInfo.type].trim[moveInfo.dir][moveInfo.speed], {-1, 1, -1, -1}))
        end
    end
    local finPos = MoveModule.EntryToPos(tempEntry, ref)
    local src = TokenModule.tokenSources[moveInfo.type:sub(1,1) .. moveInfo.speed]
    local newTemplate = src.takeObject({position=finPos.pos, rotation=finPos.rot})
    newTemplate.lock()
    newTemplate.setPosition(finPos.pos)
    newTemplate.setRotation(finPos.rot)
    table.insert(DialModule.SpawnedTemplates, {template=newTemplate, ship=ship})
    return newTemplate
end

-- Delete template spawned for a ship, return true if deleted, false if there was none
DialModule.DeleteTemplate = function(ship)
    for k,info in pairs(DialModule.SpawnedTemplates) do
        if info.ship == ship then
            info.template.destruct()
            table.remove(DialModule.SpawnedTemplates, k)
            return true
        end
    end
    return false
end

-- Is the dial faceup?
DialModule.IsDialFaceup = function(dial)
    local castData = Physics.cast({origin=dial.getPosition(), direction={0, 1, 0}, type=1})
    return castData[1] == nil
end

-- DIAL BUTTON CLICK FUNCTIONS (self-explanatory)
function DialClick_Return(dial)
    dial.clearButtons()
    DialModule.RestoreActive(dial.getVar('assignedShip'))
end
function DialClick_Flip(dial)
    if not DialModule.IsDialFaceup(dial) then
        dial.flip()
    end
    dial.clearButtons()
    DialModule.SpawnMainActiveButtons({dial=dial, ship=dial.getVar('assignedShip')})
end
function DialClick_Move(dial)
    local actShip = dial.getVar('assignedShip')
    if XW_cmd.Process(actShip, dial.getDescription()) == true then
        if DialModule.GetMainButtonsState(dial) == 0 then
            -- Temporary
            -- DialModule.SetMainButtonsState(dial, 1)
            DialModule.SetMainButtonsState(dial, 2)
        end
        DialModule.SetMoveUndoButtonState(dial, 'undo')
    end
end
function DialClick_Undo(dial)
    if MoveModule.GetLastMove(dial.getVar('assignedShip')).move == dial.getDescription() and
                                XW_cmd.Process(dial.getVar('assignedShip'), 'q') == true then
        DialModule.SetMoveUndoButtonState(dial, 'move')
        if DialModule.GetMainButtonsState(dial) == 1 then
            DialModule.SetMainButtonsState(dial, 0)
        end
    elseif MoveModule.GetOldMove(dial.getVar('assignedShip'), 1).move == dial.getDescription() and
                                XW_cmd.Process(dial.getVar('assignedShip'), 'q') == true then
        DialModule.SetMoveUndoButtonState(dial, 'undo')
    else
        XW_cmd.Process(dial.getVar('assignedShip'), 'q')
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
    local befAfter = '_A'
    for k,but in pairs(dial.getButtons()) do
        if but.label == 'Move' then befAfter = '_B' end
    end
    DialModule.PerformAction(dial.getVar('assignedShip'), 'spawnMoveTemplate:' .. dial.getDescription() .. befAfter)
end
function DialClick_BoostS(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 's1b')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_BoostR(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'br1b')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_BoostL(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'be1b')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollR(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xr')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollRF(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xrf')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollRB(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xrb')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollL(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xe')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollLF(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xef')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RollLB(dial)
    XW_cmd.Process(dial.getVar('assignedShip'), 'xeb')
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
end
function DialClick_RulerArc(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler:A')
end
function DialClick_RulerTurr(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler:AT')
end
function DialClick_RulerR1(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler:R1')
end
function DialClick_RulerR2(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler:R2')
end
function DialClick_RulerR3(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'ruler:R3')
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
    if DialModule.GetMoveUndoButtonState(dial) == 2 then
        DialModule.SetMoveUndoButtonState(dial, 'none')
    end
    DialModule.StartSlide(dial, playerColor)
end
function DialClick_HighlightShip(dial)
    dial.highlightOn({0, 1, 0}, 0.8)
    dial.getVar('assignedShip').highlightOn({0, 1, 0}, 0.8)
end

-- Dial buttons definitions (centralized so it;s easier to adjust)
DialModule.Buttons = {}
DialModule.Buttons.deleteFacedown = {label='Return', click_function='DialClick_Return', height = 400, width=1000, position={0, -0.5, 2}, rotation={180, 180, 0}, font_size=300}
DialModule.Buttons.flipNotify = {label='(flip to start)', click_function='dummy', height = 0, width = 0, position={0, 0.5, 0.2}, font_size=150, font_color={1,1,1}}
DialModule.Buttons.deleteFaceup = {label='Return', click_function='DialClick_Return', height = 400, width=1000, position={0, 0.5, 2}, font_size=300}
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
    --local len = string.len(shortName)
    --if len*150 > nameWidth then nameWidth = len*150 end
    local strWidth = StringLen.GetStringLength(shortName)/15
    if strWidth > nameWidth then
        nameWidth = strWidth
    end
    return {label=shortName, click_function='DialClick_HighlightShip', height=300, width=nameWidth, position={0, -0.5, -1}, rotation={180, 180, 0}, font_size=250}
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
DialModule.Buttons.rulerArc = {label='Arc', click_function='DialClick_RulerArc', height=500, width=400, position={-2.35, 0.5, 2}, font_size=220}
DialModule.Buttons.rulerTurr = {label='Tur', click_function='DialClick_RulerTurr', height=500, width=400, position={-1.55, 0.5, 2}, font_size=220}
DialModule.Buttons.rulerR1 = {label='1', click_function='DialClick_RulerR1', height=500, width=250, position={-2.45, 0.5, 3}, font_size=250}
DialModule.Buttons.rulerR2 = {label='2', click_function='DialClick_RulerR2', height=500, width=250, position={-1.95, 0.5, 3}, font_size=250}
DialModule.Buttons.rulerR3 = {label='3', click_function='DialClick_RulerR3', height=500, width=250, position={-1.45, 0.5, 3}, font_size=250}
DialModule.Buttons.targetLock = {label='TL', click_function='DialClick_TargetLock', height=500, width=365, position={1.5, 0.5, 2}, font_size=250}
DialModule.Buttons.slide = {label='Slide', click_function='DialClick_SlideStart', height=250, width=2000, position={2.5, 0.5, 0}, font_size=250, rotation={0, 90, 0}}

-- Get a button data if it was to be placen on the other side of a  card
DialModule.Buttons.FlipVersion = function(buttonEntry)
    local out = Lua_ShallowCopy(buttonEntry)
    if out.rotation == nil then out.rotation = {0, 0, 0} end
    out.rotation = {out.rotation[1]+180, out.rotation[2]+180, out.rotation[3]}
    out.position = {-1*out.position[1], -2*out.position[2], out.position[3]}
    return out
end

-- Start the magic slide action (will return if move doesn't allow slides)
-- No depiction of the hand move zone or anything, hardcoded in the coroutine
-- Player's hand position is object-scale-invariant
-- Args:
--      dial            <- Obj ref to an object relative to which player moves the hand to slide
--      playerColor     <- Color of the player whose hand we watch
DialModule.StartSlide = function(dial, playerColor)
    if dial.getVar('slideOngoing') == true then
        dial.setVar('slideOngoing', false)
    else
        local ship = dial.getVar('assignedShip')
        if XW_cmd.isReady(ship) ~= true then return end
        local lastMove = MoveModule.GetLastMove(ship)
        if lastMove.part ~= nil and lastMove.finType == 'slide' and MoveData.IsSlideMove(lastMove.move) then
            dial.setVar('slideOngoing', true)
            local info = MoveData.DecodeInfo(lastMove.move, ship)
            local zeroPos = DialModule.SlideZeroPos(ship, info, lastMove.part)
            table.insert(DialModule.slideDataQueue, {dial=dial, ship=ship, pColor=playerColor, zeroPos=zeroPos, moveInfo=info})
            TokenModule.QueueShipTokensMove(ship)
            XW_cmd.SetBusy(ship)
            AnnModule.Announce({type='move', note='manually adjusted base slide on the last move', code=lastMove.move}, 'all', ship)
            startLuaCoroutine(Global, 'SlideCoroutine')
            MoveModule.WaitForResting(ship)
            return true
        elseif lastMove.move == 'manual slide' then
            printToColor(ship.getName() .. ' needs to undo the manual slide before adjusting again', playerColor, {1, 0.5, 0.1})
        else
            printToColor(ship.getName() .. '\'s last move (' .. lastMove.move .. ') does not allow sliding!', playerColor, {1, 0.5, 0.1})
        end
    end
end



-- Get the part-zero-position for a ship given his state, last move and part it is at currently
DialModule.SlideZeroPos = function(ship, info, currPart)
    local currData = MoveData.SlidePartOffset(info, currPart)
    local zeroPos = MoveModule.EntryToPos(Vect_Scale(currData, -1), ship)
    return zeroPos
end

-- Table with data slide coroutines pop and process
-- Entry: {dial=dialRef, ship=shipRef, pColor=playerColor, zeroPos=slidePartZeroPos, moveInfo=moveInfo}
DialModule.slideDataQueue = {}

-- Sliding coroutine
-- It, uh, works
--[[
                                  (slide zone)
                                        V
     + - - - - - - - - - +           + - - +    ^
     |                   |           |     |    |
     |    (dial here)    |           |     |    |
     |                   |           |     |    |
     |                   |           |  X  |    | 3.0
     |                   |           |     |    |
     |                   |           |     |    |
     |                   |           |     |    |
     + - - - - - - - - - +           + - - +    V
              < - - - - - - - - - - - - >
                        3.566

]]--
-- X is the position where user should hold their mouse to get around "middle slide"
-- Movement left/right is ingored until it snaps too far and turns off slide
-- Movement up/down slides the ship until it snaps too far and turns off slide
function SlideCoroutine()
    if #DialModule.slideDataQueue < 1 then
        return 1
    end
    -- Save data from last element of queue, pop it
    local dial = DialModule.slideDataQueue[#DialModule.slideDataQueue].dial
    local ship = DialModule.slideDataQueue[#DialModule.slideDataQueue].ship
    local pColor = DialModule.slideDataQueue[#DialModule.slideDataQueue].pColor
    local zeroPos = DialModule.slideDataQueue[#DialModule.slideDataQueue].zeroPos
    local info = DialModule.slideDataQueue[#DialModule.slideDataQueue].moveInfo
    -- Obstacle collision detection data
    local obsCollFrameNum = 10
    local obsCollCounter = 0
    local lastColl = nil

    table.remove(DialModule.slideDataQueue)
    ship.setVar('slideOngoing', true)
    broadcastToColor(ship.getName() .. '\'s slide adjust started!', pColor, {0.5, 1, 0.5})

    -- Ships that can collide with sliding one
    local collShips = {}
    local shipCollRange = Convert_mm_igu(mm_baseSize[info.size]*math.sqrt(2)/2)
    -- Since we'll be doing collision checks every frame, aggresively filter out duplicate ships
    local uniqueFilter = {}
    uniqueFilter[ship.getGUID()] = true

    -- Range = (large ship radius + current ship radius)*1.05 -- so it covers every ship
    --   a collision is possible with
    -- May be not enough for super long slides (for now its OK)
    local totalCollRange = ( Convert_mm_igu(mm_largeBase*math.sqrt(2)/2) + shipCollRange ) * 1.05
    -- Add ships near zero position
    for k,cShip in pairs(XW_ObjWithinDist(zeroPos.pos, totalCollRange, 'ship')) do
        if uniqueFilter[cShip.getGUID()] == nil then
            table.insert(collShips, cShip)
            uniqueFilter[cShip.getGUID()] = true
        end
    end
    -- Add ships near max position
    for k,cShip in pairs(XW_ObjWithinDist(MoveModule.EntryToPos(MoveData.SlidePartOffset(info, MoveData.partMax), zeroPos).pos, totalCollRange, 'ship')) do
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
        local pPos = Player[pColor].getPointerPosition()
        local syRot = dial.getRotation()[2]
        local dtp = Vect_Between(dial.getPosition(), pPos)
        local rdtp = Vect_RotateDeg(dtp, -1*syRot-180)
        local dScale = dial.getScale()[1]
        return {shift=rdtp[3]/dScale, sideslip=(rdtp[1]/dScale - 3.566)}
    end

    -- Set up initial shift offset so user doesn't get a "snap" on imperfect position button click
    -- Also add it if slide is not even forward/backward
    local initShift = getPointerOffset(dial,pColor).shift
    local fullSlideLen = Convert_mm_igu(MoveData.SlideLength(info))
    local lenToTravel = fullSlideLen - Dist_Pos(ship.getPosition(), zeroPos.pos)
    initShift = initShift + (lenToTravel/(fullSlideLen))*3 - 1.5
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
            dial.setVar('slideOngoing', false)
        end

        -- Normalize the shift to [0-3] range
        adjMeas = Var_Clamp(adjMeas, -1.5, 1.5)
        adjMeas = adjMeas + 1.5

        -- Check for collisions on requested slide position
        local measPart = adjMeas*(MoveData.partMax/3)
        targetPos = MoveModule.EntryToPos(MoveData.SlidePartOffset(info, measPart), zeroPos)
        local collInfo = MoveModule.CheckCollisions(ship, {pos=targetPos.pos, rot=targetPos.rot}, collShips)
        if collInfo.coll == nil then
            -- If position is clear, set it
            ship.setPosition(targetPos.pos)
            ship.setRotation(targetPos.rot)
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
                measPart = adjMeas*(MoveData.partMax/3)
                local tryPos = MoveModule.EntryToPos(MoveData.SlidePartOffset(info, measPart), zeroPos)
                -- Check for collisions there
                collInfo = MoveModule.CheckCollisions(ship, {pos=tryPos.pos, rot=tryPos.rot}, collShips)
                -- If it is clear, set it
                if collInfo.coll == nil then
                    ship.setPosition(tryPos.pos)
                    ship.setRotation(tryPos.rot)
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
        obsCollCounter = obsCollCounter + 1
        if obsCollCounter > obsCollFrameNum then
            local newColl = MoveModule.CheckObstacleCollisions(ship, targetPos, false)[1]
            if lastColl ~= nil and lastColl ~= newColl then lastColl.highlightOff() end
            lastColl = newColl
            obsCollCounter = 0
        end
        coroutine.yield(0)

        -- This ends if player switches color, ship or dial vanishes or button is clicked setting slide var to false
    until Player[pColor] == nil or ship == nil or dial.getVar('slideOngoing') ~= true or dial == nil
    if Player[pColor] ~= nil then broadcastToColor(ship.getName() .. '\'s slide adjust ended!', pColor, {0.5, 1, 0.5}) end
    dial.setVar('slideOngoing', false)
    ship.setVar('slideOngoing', false)
    if (info.type == 'echo' or info.type == 'viper') and info.extra ~= 'adjust' then
        if info.type == 'echo' then
            MoveModule.AddHistoryEntry(ship, {pos=ship.getPosition(), rot=ship.getRotation(), move='chadj', part=MoveData.partMax/2, finType='slide'})
        elseif info.type == 'viper' then
            MoveModule.AddHistoryEntry(ship, {pos=ship.getPosition(), rot=ship.getRotation(), move='vradj', part=MoveData.partMax/2, finType='slide'})
        end
    else
        MoveModule.AddHistoryEntry(ship, {pos=ship.getPosition(), rot=ship.getRotation(), move='manual slide', finType='special'})
    end
    MoveModule.CheckObstacleCollisions(ship, targetPos, true)
    MoveModule.CheckMineCollisions(ship, targetPos, true)
    return 1
end

-- Get short name of a ship for dial indication "button"

-- Char width table by Indimeco
StringLen = {}
StringLen.charWidthTable = {
        ['`'] = 2381, ['~'] = 2381, ['1'] = 1724, ['!'] = 1493, ['2'] = 2381,
        ['@'] = 4348, ['3'] = 2381, ['#'] = 3030, ['4'] = 2564, ['$'] = 2381,
        ['5'] = 2381, ['%'] = 3846, ['6'] = 2564, ['^'] = 2564, ['7'] = 2174,
        ['&'] = 2777, ['8'] = 2564, ['*'] = 2174, ['9'] = 2564, ['('] = 1724,
        ['0'] = 2564, [')'] = 1724, ['-'] = 1724, ['_'] = 2381, ['='] = 2381,
        ['+'] = 2381, ['q'] = 2564, ['Q'] = 3226, ['w'] = 3704, ['W'] = 4167,
        ['e'] = 2174, ['E'] = 2381, ['r'] = 1724, ['R'] = 2777, ['t'] = 1724,
        ['T'] = 2381, ['y'] = 2564, ['Y'] = 2564, ['u'] = 2564, ['U'] = 3030,
        ['i'] = 1282, ['I'] = 1282, ['o'] = 2381, ['O'] = 3226, ['p'] = 2564,
        ['P'] = 2564, ['['] = 1724, ['{'] = 1724, [']'] = 1724, ['}'] = 1724,
        ['|'] = 1493, ['\\'] = 1923, ['a'] = 2564, ['A'] = 2777, ['s'] = 1923,
        ['S'] = 2381, ['d'] = 2564, ['D'] = 3030, ['f'] = 1724, ['F'] = 2381,
        ['g'] = 2564, ['G'] = 2777, ['h'] = 2564, ['H'] = 3030, ['j'] = 1075,
        ['J'] = 1282, ['k'] = 2381, ['K'] = 2777, ['l'] = 1282, ['L'] = 2174,
        [';'] = 1282, [':'] = 1282, ['\''] = 855, ['"'] = 1724, ['z'] = 1923,
        ['Z'] = 2564, ['x'] = 2381, ['X'] = 2777, ['c'] = 1923, ['C'] = 2564,
        ['v'] = 2564, ['V'] = 2777, ['b'] = 2564, ['B'] = 2564, ['n'] = 2564,
        ['N'] = 3226, ['m'] = 3846, ['M'] = 3846, [','] = 1282, ['<'] = 2174,
        ['.'] = 1282, ['>'] = 2174, ['/'] = 1923, ['?'] = 2174, [' '] = 1282,
        ['avg'] = 2500
    }

-- Get real string lenght per char table
StringLen.GetStringLength = function(str)
    local len = 0
    for i = 1, #str do
        local c = str:sub(i,i)
        if StringLen.charWidthTable[c] ~= nil then
            len = len + StringLen.charWidthTable[c]
        else
            len = len + StringLen.charWidthTable.avg
        end
    end
    return len
end

-- Get a short name for some ship
-- Avoid user-added LGS
-- Avoid name prepositions as in ambigNames
-- Avoid too short or long names
-- Add a single number/char on the end if there is one on the ship
DialModule.GetShortName = function(ship)
    local shipNameWords = {}
    local numWords = 0
    local ambigNames = 'The Captain Colonel Cartel Lieutenant Commander Old'
    local shipName = ship.getName()
    shipName = shipName:gsub('LGS', '')             -- Delete LGS
    shipName = shipName:match( "^%s*(.-)%s*$" )     -- Trim whitespaces
    -- Fill words table
    for word in shipName:gmatch('[\'\"%-%w]+') do
        table.insert(shipNameWords, word)
    end
    -- Delete first word if ambiguous and there's more
    if ambigNames:find(shipNameWords[1]) ~= nil and #shipNameWords > 1 then
        table.remove(shipNameWords, 1)
    end
    -- Fucntion for checking if "short name"
    local function sizeJustRight(str)
        if str == nil then
            return false
        end
        return ( (str:len() < 10) and (str:len() > 3) )
    end
    -- Delete the first word if too short/long and next is better
    if ( not sizeJustRight(shipNameWords[1]) ) and ( sizeJustRight(shipNameWords[2]) ) then
        table.remove(shipNameWords, 1)
    end
    -- Take the resulting first "valid" word
    local shortName = shipNameWords[1]
    -- If there were apostrophes and they are asymmetrical now, trim them
    if ( (string.find('\'\"', shortName:sub(1,1)) ~= nil) or (string.find('\'\"', shortName:sub(-1,-1)) ~= nil) ) and ( shortName:sub(1,1) ~= shortName:sub(-1,-1) ) then
        shortName = shortName:gsub('\'', '')
        shortName = shortName:gsub('\"', '')
    end
    if shipNameWords[#shipNameWords]:len() == 1 then
        shortName = shortName .. ' ' .. shipNameWords[#shipNameWords]
    end
    return shortName
end

-- Spawn first buttons on a dial (flip, indication, delete, name, action expand)
DialModule.SpawnFirstActiveButtons = function(dialTable)
    dialTable.dial.clearButtons()
    dialTable.dial.createButton(DialModule.Buttons.deleteFacedown)
    dialTable.dial.createButton(DialModule.Buttons.flip)
    dialTable.dial.createButton(DialModule.Buttons.nameButton(dialTable.ship))
    dialTable.dial.createButton(DialModule.Buttons.toggleInitialExpanded)
    dialTable.dial.createButton(DialModule.Buttons.flipNotify)
end

-- Spawn main buttons on a dial (move, actions, undo, templade, return) when it is flipped over
DialModule.SpawnMainActiveButtons = function (dialTable)
    dialTable.dial.clearButtons()
    dialTable.dial.createButton(DialModule.Buttons.deleteFaceup)
    dialTable.dial.createButton(DialModule.Buttons.move)
    dialTable.dial.createButton(DialModule.Buttons.moveTemplate)
    dialTable.dial.createButton(DialModule.Buttons.toggleMainExpanded)
end

-- Get the state of initial buttons (before flipped over)
-- Return:
--          -1      <- no buttons at all (error state)
--           0      <- initial buttons set
--           1      <- initial set + expanded actions
DialModule.GetInitialButtonsState = function(dial)
    local state = 0
    local buttons = dial.getButtons()
    if buttons == nil then return -1 end
    for k,but in pairs(buttons) do
        if but.label == 'TL' then state = 1 end
    end
    return state
end

-- Set initial buttons state (before flipped over) to desired state
-- newState arg:
--           0      <- initial buttons set
--           1      <- initial set + expanded actions
DialModule.SetInitialButtonsState = function(dial, newState)
    local actShip = dial.getVar('assignedShip')
    local extActionsMatch = ' Br B Bl Xf X Xb TL Tur Arc 1 2 3 F S E Q Slide '  -- labels for buttons of EXTENDED set
    local nameButton = DialModule.Buttons.nameButton(actShip)
    local currentState = DialModule.GetInitialButtonsState(dial)

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
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rulerArc))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rulerTurr))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rulerR1))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rulerR2))
            dial.createButton(DialModule.Buttons.FlipVersion(DialModule.Buttons.rulerR3))
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


-- Get the state of main buttons (after flipping over)
-- Return:
--          -1      <- no buttons at all (error state)
--           0      <- basic (move, delete, A etc)
--           1      <- above + FSEQ
--           2      <- above + boosts, rolls, R, TL
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


-- Set the state of main buttons (after flipping over)
-- newState arg:
--           0      <- basic (move, delete, A etc)
--           1      <- above + FSEQ
--           2      <- above + boosts, rolls, R, TL
DialModule.SetMainButtonsState = function(dial, newState)
    local standardActionsMatch = ' F S E Q -'           -- labels for buttons of STANDARD set
    local extActionsMatch = ' Br B Bl Xf X Xb TL Tur Arc 1 2 3 Slide '  -- labels for buttons of EXTENDED set

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
            dial.createButton(DialModule.Buttons.rulerArc)
            dial.createButton(DialModule.Buttons.rulerTurr)
            dial.createButton(DialModule.Buttons.rulerR1)
            dial.createButton(DialModule.Buttons.rulerR2)
            dial.createButton(DialModule.Buttons.rulerR3)
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

-- Get the state of the move/undo and template button on activated dial
-- Return:
--      0       <- no button
--      1       <- Move button present
--      2       <- Undo button present
DialModule.GetMoveUndoButtonState = function(dial)
    local buttons = dial.getButtons()
    local state = 0
    for k,but in pairs(buttons) do
        if but.label == 'Move' then
            state = 1
        elseif but.label == 'Undo' then
            state = 2
        end
    end
    return state
end

-- Set the state of the move/undo and template button on activated dial
-- newState arg:
--      0 OR 'none'      <- Delete any
--      1 OR 'move'      <- Set to Move and Template
--      2 OR 'undo'      <- Set to Undo and Template
DialModule.SetMoveUndoButtonState = function(dial, newState)
    if type(newState) == 'string' then
        if newState == 'none' then
            newState = 0
        elseif newState == 'move' then
            newState = 1
        elseif newState == 'undo' then
            newState = 2
        end
    end
    local buttons = dial.getButtons()
    for k,but in pairs(buttons) do
        if but.label == 'Undo' or but.label == 'Move' or but.label == 'T' then
            dial.removeButton(but.index)
        end
    end
    if newState == 1 then
        dial.createButton(DialModule.Buttons.move)
        dial.createButton(DialModule.Buttons.moveTemplate)
    elseif newState == 2 then
        dial.createButton(DialModule.Buttons.undoMove)
        dial.createButton(DialModule.Buttons.moveTemplate)
    end
end

-- Make said dial a new active one
-- If there is one, return it to origin
DialModule.MakeNewActive = function(ship, dial)
    local actSet = DialModule.GetSet(ship)
    if actSet.dialSet[dial.getDescription()] ~= nil and actSet.dialSet[dial.getDescription()].dial == dial then
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
        DialModule.DeleteTemplate(ship)
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
-- RULERS MODULE

-- Since there are many ruler types (models) and commands, this takes carre of all ruler-related handling
-- TO_DO: ActionModule and include it there

RulerModule = {}

-- Table of existing spawned rulers
-- Entry: {ship=shipRef, tuler=rulerRef, type=rulerTypeCode}
RulerModule.spawnedRulers = {}
-- Click function for ruler button (destroy)
function Ruler_SelfDestruct(obj)
    for k, rTable in pairs(RulerModule.spawnedRulers) do
        if rTable.ruler == obj then
            table.remove(RulerModule.spawnedRulers, k)
            break
        end
    end
    obj.destruct()
end
-- Remove appropriate entry if ruler is destroyed
RulerModule.onObjectDestroyed = function(obj)
    for k,info in pairs(RulerModule.spawnedRulers) do
        if info.ship == obj or info.ruler == obj then
            if info.ship == obj then info.ruler.destruct() end
            table.remove(RulerModule.spawnedRulers, k)
            break
        end
    end
end

-- RULER MESHES DATABASE
RulerModule.meshes = {}
RulerModule.meshes.smallBase = {}
RulerModule.meshes.smallBase.scale = {0.629, 0.629, 0.629}
RulerModule.meshes.smallBase.collider = 'http://pastebin.com/raw/5G8JN2B6'
RulerModule.meshes.smallBase.full = 'http://cloud-3.steamusercontent.com/ugc/856096260992686885/93A78E32E8B4D456A8850956D0A394AFDD339BD7/'
RulerModule.meshes.smallBase.primary = 'http://cloud-3.steamusercontent.com/ugc/856096260992683070/F2A246F3E449439892E5721CC8210097D0717FB1/'
RulerModule.meshes.smallBase.side = 'http://cloud-3.steamusercontent.com/ugc/856096260992684737/67D7CC3612702885FAF89DABA36B7FF03102E245/'
RulerModule.meshes.smallBase.rear = 'http://cloud-3.steamusercontent.com/ugc/856096260992274940/BCD8DB9C2B0ABC3975EA2742979D5D1D2B0C29F2/'
RulerModule.meshes.smallBase.turret = 'http://cloud-3.steamusercontent.com/ugc/856096260992685072/A3075630B5140D7BF0823686F2351E97E6567B05/'
RulerModule.meshes.smallBase.mobile = 'http://cloud-3.steamusercontent.com/ugc/856096260992687154/37CCFB22293664504026A894695267EF85D44EB7/'
RulerModule.meshes.smallBase.range = {}
RulerModule.meshes.smallBase.range[1] = 'http://cloud-3.steamusercontent.com/ugc/856096260992685573/70C3A5276DCCAE87290B97C695FCED9D09780DC6/'
RulerModule.meshes.smallBase.range[2] = 'http://cloud-3.steamusercontent.com/ugc/856096260992685960/485F895A4B71F611D656A3132E9D6189595CD10E/'
RulerModule.meshes.smallBase.range[3] = 'http://cloud-3.steamusercontent.com/ugc/856096260992686270/2B3DE67C10C59C985D5D153A70046E355BA6C058/'
RulerModule.meshes.smallBase.range[4] = 'http://cloud-3.steamusercontent.com/ugc/856096260992686557/6B2001736D0C1DFEFB3B543C58CA725D11A9735F/'
RulerModule.meshes.largeBase = {}
RulerModule.meshes.largeBase.scale = {0.623, 0.623, 0.623}
RulerModule.meshes.largeBase.collider = 'http://pastebin.com/raw/zucpQryb'
RulerModule.meshes.largeBase.full = 'http://cloud-3.steamusercontent.com/ugc/856096260994307914/2022E0748DDB4695583F4DD32D4514B9A71D8A7A/'
RulerModule.meshes.largeBase.primary = 'http://cloud-3.steamusercontent.com/ugc/856096260994304623/DDEEE542CE2CCFD3E5B9C9F76C159028D5926833/'
RulerModule.meshes.largeBase.side = 'http://cloud-3.steamusercontent.com/ugc/856096260994305380/E709140C72864CCC651E01F84DFC8789BF81C511/'
RulerModule.meshes.largeBase.rear = 'http://cloud-3.steamusercontent.com/ugc/856096260994305005/06D006D4FFD6E300AD4DB5DB355C998557E4967E/'
RulerModule.meshes.largeBase.turret = 'http://cloud-3.steamusercontent.com/ugc/856096260994305633/45D6DBE621E0BB261CB61DE2D003F6EF5F7A2DA5/'
RulerModule.meshes.largeBase.mobile = 'http://cloud-3.steamusercontent.com/ugc/856096260994308150/EC076D46580BAE7249F51AEF266B9C068ED87949/'
RulerModule.meshes.largeBase.range = {}
RulerModule.meshes.largeBase.range[1] = 'http://cloud-3.steamusercontent.com/ugc/856096260994306246/BBAA29F3241362AD4EA6ABBFB75F9A20335FCD61/'
RulerModule.meshes.largeBase.range[2] = 'http://cloud-3.steamusercontent.com/ugc/856096260994306498/814A249E87CB5AFEC2902B58C3F74D326DA4A036/'
RulerModule.meshes.largeBase.range[3] = 'http://cloud-3.steamusercontent.com/ugc/856096260994306731/3574957E0E1E09E967F78119159F36A709AED2C5/'
RulerModule.meshes.largeBase.range[4] = 'http://cloud-3.steamusercontent.com/ugc/856096260994307579/38AF04F20E7A7067E7385AAB44A95CAC7EBC4510/'


-- Avaialble ruler codes:
-- R            - 1-3 range rings
-- R1/R2/R3     - 1/2/3 range rings
-- A            - contextual arc
-- AA           - full ruler
-- AP           - primary arc
-- AS           - side arc
-- AR           - rear arc
-- AT           - turret arc
-- AM           - mobile arc
XW_cmd.AddCommand('r[1-3]?', 'rulerHandle')     -- Range "rings"
XW_cmd.AddCommand('a[apsrtm]?', 'rulerHandle')  -- Rulers with arc lines

-- Translate ruler code to a mesh entry
RulerModule.typeToKey = {}
RulerModule.typeToKey['AA'] = 'full'
RulerModule.typeToKey['AP'] = 'primary'
RulerModule.typeToKey['AS'] = 'side'
RulerModule.typeToKey['AR'] = 'rear'
RulerModule.typeToKey['AT'] = 'turret'
RulerModule.typeToKey['AM'] = 'mobile'
RulerModule.typeToKey['R'] = 'range'

-- Get ruler spawn tables for some ship and some ruler code
-- Return table with "mesh", "collider" and "scale" keys
--  (for appropriate ruler)
RulerModule.GetRulerData = function(ship, rulerType)
    local baseSize = DB_getBaseSize(ship)
    if baseSize == 'Unknown' then
        baseSize = 'small'
    end
    local out = {mesh = nil, collider = nil, scale = nil}
    if rulerType:sub(1,1) == 'R' then
        rKey = tonumber(rulerType:sub(2,2))
        if rKey == nil then
            rKey = 4
        end
        out.mesh = RulerModule.meshes[baseSize .. 'Base'].range[rKey]
    else
        local key = RulerModule.typeToKey[rulerType]
        out.mesh = RulerModule.meshes[baseSize .. 'Base'][key]
    end
    out.scale = RulerModule.meshes[baseSize .. 'Base'].scale
    out.collider = RulerModule.meshes[baseSize .. 'Base'].collider
    return out
end

-- Return a descriptive arc name of command (for announcements)
RulerModule.DescriptiveName = function(ship, rulerType)
    if rulerType:sub(1,1) == 'R' then
        ranges = rulerType:sub(2,2)
        if ranges == '' then
            ranges = '1-3'
        end
        return 'range ' .. ranges .. ' ruler'
    else
        if rulerType == 'A' then
            rulerType = rulerType .. RulerModule.DefaultShipArc(ship)
        end
        local arcName = RulerModule.typeToKey[rulerType]
        return arcName .. ' arc ruler'
    end
end

-- Get the default ship arc type code
-- e.g. whip with just primary arc will return code for priamry arc spawn
RulerModule.DefaultShipArc = function(ship)
    local info = DB_getShipInfo(ship)
    if info ~= nil then
        return info.arcType
    end
    return 'A'
end

-- Create tables for spawning a ruler
-- Return:  {
--      params      <- table suitable for spawnObject(params) call
--      custom      <- tabgle suitable for obj.setCustomObject(custom) call
--          }
RulerModule.CreateCustomTables = function(ship, rulerType)
    if rulerType == 'A' then
        rulerType = rulerType .. RulerModule.DefaultShipArc(ship)
    end
    local rulerData = RulerModule.GetRulerData(ship, rulerType)
    local paramsTable = {}
    paramsTable.type = 'Custom_Model'
    paramsTable.position = ship.getPosition()
    paramsTable.rotation = {0, ship.getRotation()[2], 0}
    paramsTable.scale = rulerData.scale
    local customTable = {}
    customTable.mesh = rulerData.mesh
    customTable.collider = rulerData.collider
    return {params = paramsTable, custom = customTable}
end

-- Spawn a ruler for a ship
-- Returns new ruler reference
RulerModule.SpawnRuler = function(ship, rulerType, beQuiet)
    local rulerData = RulerModule.CreateCustomTables(ship, rulerType)
    local newRuler = spawnObject(rulerData.params)
    newRuler.setCustomObject(rulerData.custom)
    table.insert(RulerModule.spawnedRulers, {ship = ship, ruler = newRuler, type = rulerType})
    newRuler.lock()
    newRuler.setScale(rulerData.params.scale)
    local button = {click_function = 'Ruler_SelfDestruct', label = 'DEL', position = {0, 0.5, 0}, rotation =  {0, 0, 0}, width = 900, height = 900, font_size = 250}
    newRuler.createButton(button)
    return newRuler
end

-- Delete existing ruler for a ship
-- Return deleted ruler type or nil if there was none
RulerModule.DeleteRuler = function(ship)
    for k,rTable in pairs(RulerModule.spawnedRulers) do
        if rTable.ship == ship then
            rTable.ruler.destruct()
            local destType = rTable.type
            table.remove(RulerModule.spawnedRulers, k)
            return destType
        end
    end
    return nil
end

-- Toggle ruler for a ship
-- If a ruler of queried type exists, just delete it and return nil
-- If any other ruler exists, delete it (and spawn queried one), return new ruler ref
RulerModule.ToggleRuler = function(ship, rulerType, beQuiet)
    local destType = RulerModule.DeleteRuler(ship)
    if destType ~= rulerType then
        if beQuiet ~= true then
            local annInfo = {type='action'}
            annInfo.note = 'spawned a ' .. RulerModule.DescriptiveName(ship, rulerType) .. ' (' .. rulerType .. ')'
            AnnModule.Announce(annInfo, 'all', ship)
        end
        return RulerModule.SpawnRuler(ship, rulerType, beQuiet)
    end
end

-- END RULERS MODULE
--------

--------
-- BOMB MODULE

-- Allows for creating "bomb drops" that snap bomb tokens to position

BombModule = {}

-- Delete button for the spawned template
BombModule.deleteButton = {click_function = 'BombDrop_SelfDestruct', label = 'OK', position = {0, 0.1, 0}, rotation =  {0, 0, 0}, scale = {0.1, 0.1, 0.1}, width = 900, height = 900, font_size = 400}
function BombDrop_SelfDestruct(temp)
    BombModule.DeleteDrop(temp)
end

BombModule.dropTable = {}

XW_cmd.AddCommand('b:s[1-5][r]?', 'bombDrop')
XW_cmd.AddCommand('b:b[rle][1-3][r]?', 'bombDrop')
XW_cmd.AddCommand('b:t[rle][1-3][r]?', 'bombDrop')

-- Spawn a bomb drop, delete old ones
-- If that exact one existed, just delete
BombModule.ToggleDrop = function(ship, dropCode)
    if BombModule.DeleteDrop(ship) ~= dropCode then
        BombModule.SpawnDrop(ship, dropCode)
    end
end

-- Create a bomb drop with a template
BombModule.SpawnDrop = function(ship, dropCode)
    local scPos = dropCode:find(':')
    local templateCode = dropCode:sub(scPos+1,-1)
    DialModule.DeleteTemplate(ship)
    local dropPos = nil
    local temp = nil
    if dropCode:sub(-1, -1) == 'r' then
        -- FRONT drops
        temp = DialModule.SpawnTemplate(ship, templateCode:sub(1, -2) .. '_B')
        temp.createButton(BombModule.deleteButton)
        dropPos = MoveModule.GetFinalPosData(templateCode:sub(1, -2), ship, true)
        dropPos.finPos.rot[2] = dropPos.finPos.rot[2] - 180
    else
        -- BACK drops
        temp = DialModule.SpawnTemplate(ship, templateCode .. 'r_B')
        temp.createButton(BombModule.deleteButton)
        dropPos = MoveModule.GetFinalPosData(templateCode .. 'r', ship, true)
    end
    if dropPos == nil or temp == nil then return end
    table.insert(BombModule.dropTable, {ship=ship, temp=temp, code=dropCode, dest=dropPos.finPos})
end

-- Delete existing drop, return deleted code or nil if there was none
BombModule.DeleteDrop = function(temp_ship)
    local newTable = {}
    local deleteCode = nil
    for k,dTable in pairs(BombModule.dropTable) do
        if dTable.ship == temp_ship or dTable.temp == temp_ship then
            deleteCode = dTable.code
            DialModule.DeleteTemplate(dTable.ship)
        else
            table.insert(newTable, dTable)
        end
    end
    BombModule.dropTable = newTable
    return deleteCode
end

-- Delete drops on ship/template delete
BombModule.onObjectDestroyed = function(obj)
    for k,dTable in pairs(BombModule.dropTable) do
        if dTable.ship == obj or dTable.temp == obj then
            BombModule.DeleteDrop(obj)
        end
    end
end

-- Bomb type -> offset data
BombModule.tokenOffset = {}
BombModule.tokenOffset.standardAoE = {pos={0, Convert_mm_igu(-2), Convert_mm_igu(-4.5)}, rot={0, 90, 0}}
BombModule.tokenOffset.prox = {pos={0, Convert_mm_igu(-2), Convert_mm_igu(15)}, rot={0, 90, 0}}
BombModule.tokenOffset.cluster = {pos={0, Convert_mm_igu(-2), 0}, rot={0, 180, 0}}
BombModule.tokenOffset.connor = {pos={0, Convert_mm_igu(-2), Convert_mm_igu(21)}, rot={0, 180, 0}}
BombModule.tokenOffset.rgc = {pos={0, Convert_mm_igu(-1), Convert_mm_igu(9.5)}, rot={0, 0, 0}}

-- Bomb name -> type data
BombModule.snapTable = {}
BombModule.snapTable['Ion Bomb'] = 'standardAoE'
BombModule.snapTable['Proton Bomb'] = 'standardAoE'
BombModule.snapTable['Seismic Charge'] = 'standardAoE'
BombModule.snapTable['Thermal Detonator'] = 'standardAoE'
BombModule.snapTable['Bomblet'] = 'standardAoE'
BombModule.snapTable['Proximity Mine'] = 'prox'
BombModule.snapTable['Cluster Mine (middle)'] = 'cluster'
BombModule.snapTable['Connor Net'] = 'connor'
BombModule.snapTable['Rigged Cargo Chute debris'] = 'rgc'

-- Minimum distance to snap
BombModule.snapDist = 1.5
-- Snap on drop
BombModule.OnTokenDrop = function(token)
    -- Get the offset data
    local offset = BombModule.tokenOffset[BombModule.snapTable[token.getName()]]
    if offset == nil then print('nil') return end

    -- Deduct closest bomb drop point within snap distance
    local closest = {dist=BombModule.snapDist+1, pointKey=nil}
    local tPos = token.getPosition()
    for k,dTable in pairs(BombModule.dropTable) do
        local newDist = Dist_Pos(tPos, dTable.dest.pos)
        if newDist < closest.dist then
            closest.dist = newDist
            closest.pointKey = k
        end
    end

    -- If there was one
    if closest.pointKey ~= nil then
        -- Move the token to the snap points
        local drop = BombModule.dropTable[closest.pointKey]
        local destPos = Vect_Sum(drop.dest.pos, Vect_RotateDeg(offset.pos, drop.dest.rot[2]))
        if DB_isLargeBase(drop.ship) then
            destPos = Vect_Sum(destPos, Vect_RotateDeg({0, 0, Convert_mm_igu(-20)}, drop.dest.rot[2]))
        end
        local destRot = Vect_Sum(drop.dest.rot, offset.rot)
        destPos[2] = drop.ship.getPosition()[2] + offset.pos[2]
        token.lock()
        token.setPositionSmooth(destPos, false, true)
        token.setRotationSmooth(destRot, false, true)
        XW_cmd.SetBusy(token)
        MoveModule.WaitForResting(token, {pos=destPos, rot=destRot})
        -- Expand clusters
        if token.getName() == 'Cluster Mine (middle)' then
            BombModule.ExpandCluster({pos=destPos, rot=destRot})
        end
        AnnModule.Announce({type='action', note=drop.ship.getName() .. ' dropped a ' .. token.getName():gsub('%(middle%)', 'set')}, 'all')
        return true
    else
        return false
    end
end

-- Spawn side tokens for cluster mine
BombModule.ExpandCluster = function(center)
    local offset = {Convert_mm_igu(43.5), 0, Convert_mm_igu(-1.5)}
    local tParams = {type='Custom_Token'}
    local tCustom = {image='http://i.imgur.com/MqlYZzR.png', thickness=0.1, merge_distance=5}

    local t1 = spawnObject(tParams)
    t1.setCustomObject(tCustom)
    t1.lock()
    local destOffset1 = Vect_RotateDeg(offset, center.rot[2])
    t1.setPosition(Vect_Sum(center.pos, destOffset1))
    t1.setRotation(center.rot)
    t1.setScale({0.4554, 0.4554, 0.4554})
    t1.setName('Cluster Mine (side)')

    local t2 = spawnObject(tParams)
    t2.setCustomObject(tCustom)
    t2.lock()
    local destOffset2 = Vect_RotateDeg(Vect_ScaleEach(offset, {-1, 1, 1}), center.rot[2])
    t2.setPosition(Vect_Sum(center.pos, destOffset2))
    t2.setRotation(center.rot)
    t2.setScale({0.4554, 0.4554, 0.4554})
    t2.setName('Cluster Mine (side)')
end

-- END BOMB MODULE
--------

--------
-- ANNOUNCEMENTS MODULE

-- For writing out stuff in chat

AnnModule = {}

-- COLOR CONFIGURATION FOR ANNOUNCEMENTS
AnnModule.announceColor = {}
AnnModule.announceColor.moveClear = {0.1, 1, 0.1}     -- Green
AnnModule.announceColor.moveCollision = {1, 0.5, 0.1} -- Orange
AnnModule.announceColor.action = {0.2, 0.2, 1}        -- Blue
AnnModule.announceColor.historyHandle = {0.1, 1, 1}   -- Cyan
AnnModule.announceColor.error = {1, 0.1, 0.1}         -- Red
AnnModule.announceColor.warn = {1, 0.25, 0.05}        -- Red - orange
AnnModule.announceColor.info = {0.6, 0.1, 0.6}        -- Purple

-- Notify color or all players of some event
-- announceInfo: {type=typeOfEvent, note=notificationString}
AnnModule.Announce = function(info, target, shipPrefix)
    local annString = ''
    local annColor = {1, 1, 1}
    local shipName = ''

    if shipPrefix ~= nil then
        if type(shipPrefix) == 'string' then
            shipName = shipPrefix .. ' '
        elseif type(shipPrefix) == 'userdata' then
            shipName = shipPrefix.getName() .. ' '
        end
    end
    if info.type == 'move' or info.type == 'slide' or info.type == 'stationary' then
        if info.collidedShip == nil then
            annString = shipName .. info.note .. ' (' .. info.code .. ')'
            annColor = AnnModule.announceColor.moveClear
        else
            annString = shipName .. info.note .. ' (' .. info.code .. ') but is now touching ' .. info.collidedShip.getName()
            annColor = AnnModule.announceColor.moveCollision
        end
    elseif info.type == 'overlap' then
        annString = shipName .. info.note .. ' (' .. info.code .. ') but there was no space to complete the move'
        annColor = AnnModule.announceColor.moveCollision
    elseif info.type == 'historyHandle' then
        annString = shipName .. info.note
        annColor = AnnModule.announceColor.historyHandle
    elseif info.type == 'action' then
        annString = shipName .. info.note
        annColor = AnnModule.announceColor.action
    elseif info.type:find('error') ~= nil then
        annString = shipName .. info.note
        annColor = AnnModule.announceColor.error
    elseif info.type:find('warn') ~= nil then
        annString = shipName .. info.note
        annColor = AnnModule.announceColor.warn
    elseif info.type:find('info') ~= nil then
        annString = shipName .. info.note
        annColor = AnnModule.announceColor.info
    end

    if target == 'all' then
        printToAll(annString, annColor)
    else
        printToColor(target, annString, annColor)
    end
end

-- Record of players that already got note of some ID
-- Key: playerSteamID
-- Value: table of true's on keys of received noteIDs
AnnModule.notifyRecord = {}

-- Print note to playerColor
-- Any further calls with same noteID will not notify same player
-- Print to everyone if playerColor is 'all'
AnnModule.NotifyOnce = function(note, noteID, playerColor)
    if playerColor == 'all' then
        local seatedPlayers = getSeatedPlayers()
        for _,color in pairs(seatedPlayers) do
            AnnModule.NotifyOnce(note, noteID, color)
        end
    else
        local steamID = Player[playerColor].steam_id
        if AnnModule.notifyRecord[steamID] == nil then
            AnnModule.notifyRecord[steamID] = {}
        end
        if AnnModule.notifyRecord[steamID][noteID] ~= true then
            broadcastToColor(note, playerColor, AnnModule.announceColor.info)
            AnnModule.notifyRecord[steamID][noteID] = true
        end
    end
end


-- END ANNOUNCEMENTS MODULE
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
    -- Handle unassignment of dial sets
    DialModule.onObjectDestroyed(dying_object)
    -- Handle history delete and emergency restore saving
    MoveModule.onObjectDestroyed(dying_object)
    -- Handle killing rulers
    RulerModule.onObjectDestroyed(dying_object)
    -- Handle killing bomb drop templates
    BombModule.onObjectDestroyed(dying_object)
end

-- When table is loaded up, this is called
-- save_state contains everything separate modules saved before to restore table state
function onLoad(save_state)
    if save_state ~= '' and save_state ~= nil and save_state ~= '[]' then
        AnnModule.Announce({note='Attempting to restore state. If you are rewinding game, STOP! \nPlease read the \'Undoing things\' page from wiki (on side note).', type='info'}, 'all')
        local savedData = JSON.decode(save_state)
        DialModule.onLoad(savedData.DialModule)
        MoveModule.onLoad(savedData.MoveModule)
    end
    MoveData.onLoad()
    TokenModule.onLoad()
end

function onSave()
    local tableToSave = {}
    tableToSave.DialModule = DialModule.onSave()
    tableToSave.MoveModule = MoveModule.onSave()
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
addidionalCollisionMargin_mm = -0.5
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

-- Get full ship info
-- Return:  {
--      shipType        <- ship type name, exact as on pilot card
--      largeBase       <- TRUE if ship is large base, FALSE otherwise
--      faction         <- 'Rebel', 'Scum' or 'Imperial'
--      arcType         <- 'P' primary, 'T' turret, 'S' side, 'M' mobile, 'R' rear
--          }
-- Return nil and warn if ship unrecognized
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
                local info = {shipType = shipType, largeBase = typeTable.largeBase, faction = typeTable.faction, arcType = typeTable.arcType}
                shipRef.setTable('DB_shipInfo', info)
                return info
            end
        end
    end
    if shipRef.getVar('missingModelWarned') ~= true then
        printToAll(shipRef.getName() .. '\'s model not recognized - use LGS in name if large base and contact author about the issue', {1, 0.1, 0.1})
        shipRef.setVar('missingModelWarned', true)
    end
    return nil
end

-- Same as above with table argument to allow call from outside Global
function DB_getShipInfoCallable(table)
    return DB_getShipInfo(table[1])
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

-- Same as above with table argument to allow call from outside Global
function DB_getShipTypeCallable(table)
    return DB_getShipType(table[1])
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
        return false
    end
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
    ['X-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/54FLC', 'https://paste.ee/r/eAdkb', 'https://paste.ee/r/hxWah', 'https://paste.ee/r/ZxcTT', 'https://paste.ee/r/FfWNK', 'http://cloud-3.steamusercontent.com/ugc/82591194029070509/ECA794EC4771A195A6EB641226DF1F986041EFFF/', 'http://cloud-3.steamusercontent.com/ugc/82591194029077829/B7E898109E3F3B115DF0D60BB0CA215A727E3F38/', 'http://cloud-3.steamusercontent.com/ugc/82591194029083210/BFF5BAE2A45EC9D647E14D9041140FFE114BF2D4/', 'http://cloud-3.steamusercontent.com/ugc/82591194029107313/95BAD08906334FBA628F6628E5DE2D0D30112A53/', 'http://cloud-3.steamusercontent.com/ugc/82591194029079708/B215C5ADC2F6D83F441BA9C7659C91E3100D3BDC/', 'http://cloud-3.steamusercontent.com/ugc/82591194029074494/80096860E52453F4F998632714F86DF49884720A/'}},
    ['Y-Wing Rebel'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/MV6qP', 'http://cloud-3.steamusercontent.com/ugc/82591194029097150/75A486189FEDE8BEEBFBACC0D76DE926CB42E52A/'}},
    ['YT-1300'] = { faction = 'Rebel', largeBase = true, arcType = 'T', meshes = {'https://paste.ee/r/kkPoB', 'http://pastebin.com/VdHhgdFr', 'http://cloud-3.steamusercontent.com/ugc/82591194029088151/213EF50E847F62BB943430BA93094F1E794E866B/', 'http://pastebin.com/VdHhgdFr'}},
    ['YT-2400'] = { faction = 'Rebel', largeBase = true, arcType = 'T', meshes = {'https://paste.ee/r/Ff0vZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029079241/206F408212849DCBB3E1934A623FD7A8844AAE47/'}},
    ['A-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/tIdib', 'https://paste.ee/r/mow3U', 'https://paste.ee/r/ntg8n', 'http://cloud-3.steamusercontent.com/ugc/82591194029101910/5B04878FCA189712681D1CF6C92F8CD178668FD2/', 'http://cloud-3.steamusercontent.com/ugc/82591194029092256/19939432DC769A3B77BA19F2541C9EA11B72C73B/', 'http://cloud-3.steamusercontent.com/ugc/82591194029099778/264B65BA198B1A004192B898AD32F48FD3D400E3/'}},
    ['B-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/8CtXr', 'http://cloud-3.steamusercontent.com/ugc/82591194029071704/78677576E07A2F091DEC4CE58129B42714E8A19E/'}},
    ['HWK-290 Rebel'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/MySkn', 'http://cloud-3.steamusercontent.com/ugc/82591194029098250/4E8A65B9C156B7882A729BC9D93B2B434D549834/'}},
    ['VCX-100'] = { faction = 'Rebel', largeBase = true, arcType = 'R', meshes = {'https://paste.ee/r/VmV6q', 'http://cloud-3.steamusercontent.com/ugc/82591194029104609/DDD1DE36F998F9175669CB459734B1A89AD3549B/'}},
    ['Attack Shuttle'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/jrwRJ', 'http://cloud-3.steamusercontent.com/ugc/82591194029086137/2D8471654F7BA70A5B65BB3A5DC4EB6CBE8F7C1C/'}},
    ['T-70 X-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/NH1KI', 'http://cloud-3.steamusercontent.com/ugc/82591194029099132/056C807B114DE0023C1B8ABD28F4D5E8F0B5D76E/'}},
    ['E-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/A57A8', 'http://cloud-3.steamusercontent.com/ugc/82591194029072231/46CA6A77D12681CA1B1B4A9D97BD6917811D561C/'}},
    ['K-Wing'] = { faction = 'Rebel', largeBase = false, arcType = 'T', meshes = {'https://paste.ee/r/2Airh', 'http://cloud-3.steamusercontent.com/ugc/82591194029069099/CDF24012FD0342ED8DE472CFA0C7C2748E3AF541/'}},
    ['Z-95 Headhunter Rebel'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/d91Hu', 'http://cloud-3.steamusercontent.com/ugc/82591194029075380/02AE170F8A35A5619E57B3380F9F7FE0E127E567/'}},
    ['TIE Fighter Rebel'] = { faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/aCJSv', 'http://cloud-3.steamusercontent.com/ugc/82591194029072635/C7C5DAD08935A68E342BED0A8583D23901D28753/', 'http://cloud-3.steamusercontent.com/ugc/200804981461390083/2E300B481E6474A8F71781FB38D1B0CD74BBC427/'}},
    ['U-Wing'] = { faction = 'Rebel', largeBase = true, arcType = 'P', meshes = {'https://paste.ee/r/D4Jjb', 'http://cloud-3.steamusercontent.com/ugc/82591194029075014/E561AA8493F86562F48EE85AB0C02F9C4F54D1B3/', 'http://cloud-3.steamusercontent.com/ugc/89352927638740227/F17424FAEF4C4429CE544FEF03DAE0E7EA2A672E/'}},
    ['ARC-170'] = { faction = 'Rebel', largeBase = false, arcType = 'R', meshes = {'http://cloud-3.steamusercontent.com/ugc/489018224649021380/CF0BE9820D8123314E976CF69F3EA0A2F52A19AA/'}},
    ['Auzituck Gunship'] = {faction = 'Rebel', largeBase = false, arcType = 'S', meshes = {'http://cloud-3.steamusercontent.com/ugc/830199836523150434/792F09608618B0AC2FF114BAA88567BA214B4A62/'}},
    ['Scurrg H-6 Bomber Rebel'] = {faction = 'Rebel', largeBase = false, arcType = 'P', meshes = {'http://cloud-3.steamusercontent.com/ugc/856096098866548845/FA5948D17379237DF015D8EE177A7F61B2452595/'}},

    ['Firespray-31 Scum'] = { faction = 'Scum', largeBase = true, arcType = 'R', meshes = {'https://paste.ee/r/3INxK', 'http://cloud-3.steamusercontent.com/ugc/82591194029069521/B5F857033DD0324E7508645821F17B572BC1AF6A/'}},
    ['Z-95 Headhunter Scum'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/OZrhd', 'http://cloud-3.steamusercontent.com/ugc/82591194029101027/02AE170F8A35A5619E57B3380F9F7FE0E127E567/'}},
    ['Y-Wing Scum'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/1T0ii', 'http://cloud-3.steamusercontent.com/ugc/82591194029068678/DD4A3DBC4B9ED3E108C39E736F9AA3DD816E1F6F/'}},
    ['HWK-290 Scum'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/tqTsw', 'http://cloud-3.steamusercontent.com/ugc/82591194029102663/71BDE5DC2D31FF4D365F210F037254E9DD62D6A7/'}},
    ['M3-A Interceptor'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/mUFjk', 'http://cloud-3.steamusercontent.com/ugc/82591194029096648/6773CD675FA734358137849555B2868AC513801B/'}},
    ['StarViper'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/jpEbC', 'http://cloud-3.steamusercontent.com/ugc/82591194029085780/6B4B13CE7C78700EF474D06F44CEB27A14731011/'}},
    ['Aggressor'] = { faction = 'Scum', largeBase = true, arcType = 'P', meshes = {'https://paste.ee/r/0UFlm', 'http://cloud-3.steamusercontent.com/ugc/82591194029067417/A6D736A64063BC3BC26C10E5EED6848C1FCBADB7/'}},
    ['YV-666'] = { faction = 'Scum', largeBase = true, arcType = 'S', meshes = {'https://paste.ee/r/lLZ8W', 'http://cloud-3.steamusercontent.com/ugc/82591194029090900/DD6BFD31E1C7254018CF6B03ABA1DA40C9BD0D2D/'}},
    ['Kihraxz Fighter'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/E8ZT0', 'http://cloud-3.steamusercontent.com/ugc/82591194029077425/6C88D57B03EF8B0CD7E4D91FED266EC15C614FA9/'}},
    ['JumpMaster 5000'] = { faction = 'Scum', largeBase = true, arcType = 'T', meshes = {'https://paste.ee/r/1af5C', 'http://cloud-3.steamusercontent.com/ugc/82591194029067863/A8F7079195681ECD24028AE766C8216E6C27EE21/'}},
    ['G-1A StarFighter'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/aLVFD', 'http://cloud-3.steamusercontent.com/ugc/82591194029072952/254A466DCA5323546173CA6E3A93EFD37A584FE6/'}},
    ['Lancer-Class Pursuit Craft'] = { faction = 'Scum', largeBase = true, arcType = 'M', meshes = {'https://paste.ee/r/Dp2Ge', 'http://cloud-3.steamusercontent.com/ugc/82591194029076583/E561AA8493F86562F48EE85AB0C02F9C4F54D1B3/', 'http://cloud-3.steamusercontent.com/ugc/89352769134140020/49113B3BA0A5C67FD7D40A3F61B6AFAFF02E0D1F/'}},
    ['Quadjumper'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/njJYd', 'http://cloud-3.steamusercontent.com/ugc/82591194029099470/6F4716CB145832CC47231B4A30F26153C90916AE/', 'http://cloud-3.steamusercontent.com/ugc/89352927637054865/CA43D9DEC1EF65DA30EC657EC6A9101E15905C78/'}},
    ['Protectorate Starfighter'] = { faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/GmKW8', 'http://cloud-3.steamusercontent.com/ugc/82591194029065993/9838180A02D9960D4DE949001BBFD05452DA90D2/', 'http://cloud-3.steamusercontent.com/ugc/89352769138031546/C70B323524602140897D8E195C19522DB450A7E0/'}},
    ['Scurrg H-6 Bomber Scum'] = {faction = 'Scum', largeBase = false, arcType = 'P', meshes = {'http://cloud-3.steamusercontent.com/ugc/830199511120337844/FA5948D17379237DF015D8EE177A7F61B2452595/'}},

    ['TIE Fighter'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/Yz0kt', 'http://cloud-3.steamusercontent.com/ugc/82591194029106682/C7C5DAD08935A68E342BED0A8583D23901D28753/'}},
    ['TIE Interceptor'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/cedkZ', 'https://paste.ee/r/JxWNX', 'http://cloud-3.steamusercontent.com/ugc/82591194029074075/3AAF855C4A136C58E933F7409D0DB2C73E1958A9/', 'http://cloud-3.steamusercontent.com/ugc/82591194029086817/BD640718BFFAC3E4B5DF6C1B0220FB5A87E5B13C/'}},
    ['Lambda-Class Shuttle'] = { faction = 'Imperial', largeBase = true, arcType = 'P', meshes = {'https://paste.ee/r/4uxZO', 'http://cloud-3.steamusercontent.com/ugc/82591194029069944/4B8CB031A438A8592F0B3EF8FA0473DBB6A5495A/'}},
    ['Firespray-31 Imperial'] = { faction = 'Imperial', largeBase = true, arcType = 'R', meshes = {'https://paste.ee/r/p3iYR', 'http://cloud-3.steamusercontent.com/ugc/82591194029101385/B5F857033DD0324E7508645821F17B572BC1AF6A/'}},
    ['TIE Bomber'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/5A0YG', 'http://cloud-3.steamusercontent.com/ugc/82591194029070985/D0AF97C6FB819220CF0E0E93137371E52B77E2DC/'}},
    ['TIE Phantom'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/JN16g', 'http://cloud-3.steamusercontent.com/ugc/82591194029085339/CD9FEC659CF2EB67EE15B525007F784FB13D62B7/'}},
    ['VT-49 Decimator'] = { faction = 'Imperial', largeBase = true, arcType = 'T', meshes = {'https://paste.ee/r/MJOFI', 'http://cloud-3.steamusercontent.com/ugc/82591194029091549/10F641F82963B26D42E062ED8366A4D38C717F73/'}},
    ['TIE Advanced'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/NeptF', 'http://cloud-3.steamusercontent.com/ugc/82591194029098723/CAF618859C1894C381CA48101B2D2D05B14F83C0/', 'http://cloud-3.steamusercontent.com/ugc/82591194029104263/D0F4E672CBFA645B586FFC94A334A8364B30FD38/', 'http://cloud-3.steamusercontent.com/ugc/82591194029080088/D0F4E672CBFA645B586FFC94A334A8364B30FD38/'}},
    ['TIE Punisher'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/aVGkQ', 'http://cloud-3.steamusercontent.com/ugc/82591194029073355/7A1507E4D88098D19C8EAFE4A763CC33A5EC35CB/'}},
    ['TIE Defender'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/0QVhZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029067091/F2165ABE4580BD5CCECF258CCE790CD9A942606F/'}},
    ['TIE/fo Fighter'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'http://pastebin.com/jt2AzA8t'}},
    ['TIE Adv. Prototype'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'https://paste.ee/r/l7cuZ', 'http://cloud-3.steamusercontent.com/ugc/82591194029089434/A4DA1AD96E4A6D65CC6AE4F745EDA966BA4EF85A/'}},
    ['TIE Striker'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'http://cloud-3.steamusercontent.com/ugc/200804896212875955/D04F1FF5B688EAB946E514650239E7772F4DC64E/'}},
    ['TIE/sf Fighter'] = { faction = 'Imperial', largeBase = false, arcType = 'R', meshes = {'http://pastebin.com/LezDjunY'}},
    ['Upsilon Class Shuttle'] = { faction = 'Imperial', largeBase = true, arcType = 'P', meshes = {'http://pastebin.com/nsHXF9XV'}},
    ['TIE Aggressor'] = { faction = 'Imperial', largeBase = false, arcType = 'P', meshes = {'http://cloud-3.steamusercontent.com/ugc/767149048511803270/CCF070748EEB6BE259A107E63685A03015510D37/'}}

}
-- END SHIP DATABASE MODULE
--------