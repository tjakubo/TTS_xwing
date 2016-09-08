-- TO_DO: If final position of moved token doesnt make its owner ship it moved with,
--  move it on its base
-- TO_DO: keep command
--TO_DO: dont lock ship after completeing if it;s not level
-- TO_DO: rulers, bomb ranges

-- TO_DO: Dials: Assign -> change state -> lay out -> confirm position ->
-- -> call Global for each dialling -> self destruct
-- Intercept remove, eemove all physically and from Global on one removed
-- Think about twhen to spawn active dial buttons
-- On drop among dials, return to origin

function ClearButtonsPatch(obj)
    local buttons = obj.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do
            obj.removeButton(but.index)
        end
    end
end

function onLoad(save_state)
    DialModule.onLoad()
end

DialModule = {}

function DialPickedUp(dialTable)
    DialModule.MakeNewActive(dialTable.ship, dialTable.dial)
end

function DialDropped(dialTable)
    local actSet = DialModule.GetSet(dialTable.ship)
    if actSet.activeDial.dial == dialTable.dial then
        DialModule.SpawnFirstActiveButtons(dialTable)
    else
        DialModule.RestoreDial(dialTable.dial)
    end
end

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
    MoveModule.AddHistoryEntry(actShip, {pos=actShip.getPosition(), rot=actShip.getRotation(), move='manual reposition'})
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
function DialClick_TargetLock(dial)
    DialModule.PerformAction(dial.getVar('assignedShip'), 'targetLock')
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


DialModule.PerformAction = function(ship, type)
    local tokenActions = 'focus evade stress targetLock'
    if type == 'ruler' then
        print('ding')
    elseif type == 'targetLock' then
        print('dang')
    elseif tokenActions:find(type) ~= nil then
        print('dong')
    end
end

-- set: {ship=shipRef, activeDial=actDialInfo, dials=dialData}
-- dialData: {dial1Info, dial2Info, dial3Info ...}
-- dialInfo: {dial=dialRef, originPos=origin}
DialModule.ActiveSets = {}

DialModule.TokenSources = {}

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
    print(string.len(shortName)*120)
    return {label=shortName, click_function='dummy', height=300, width=string.len(shortName)*140, position={0, -0.5, -1}, rotation={180, 180, 0}, font_size=250}
end
DialModule.Buttons.boostS = {label='B', click_function='DialClick_BoostS', height=500, width=365, position={0, 0.5, -2.2}, font_size=250}
DialModule.Buttons.boostR = {label='Br', click_function='DialClick_BoostR', height=500, width=365, position={0.75, 0.5, -2.2}, font_size=250}
DialModule.Buttons.boostL = {label='Bl', click_function='DialClick_BoostL', height=500, width=365, position={-0.75, 0.5, -2.2}, font_size=250}
DialModule.Buttons.rollR = {label='X', click_function='DialClick_RollR', height=500, width=365, position={1.5, 0.5, 0}, font_size=250}
DialModule.Buttons.rollRF = {label='Xf', click_function='DialClick_RollRF', height=500, width=365, position={1.5, 0.5, -1}, font_size=250}
DialModule.Buttons.rollRB = {label='Xb', click_function='DialClick_RollRB', height=500, width=365, position={1.5, 0.5, 1}, font_size=250}
DialModule.Buttons.rollL = {label='X', click_function='DialClick_RollL', height=500, width=365, position={-1.5, 0.5, 0}, font_size=250}
DialModule.Buttons.rollLF = {label='Xf', click_function='DialClick_RollLF', height=500, width=365, position={-1.5, 0.5, -1}, font_size=250}
DialModule.Buttons.rollLB = {label='Xb', click_function='DialClick_rollLB', height=500, width=365, position={-1.5, 0.5, 1}, font_size=250}
DialModule.Buttons.ruler = {label='R', click_function='DialClick_Ruler', height=500, width=365, font_size=250}
DialModule.Buttons.targetLock = {label='TL', click_function='DialClick_TargetLock', height=500, width=365, font_size=250}

DialModule.GetShortName = function(ship)
    local shipNameWords = {}
    local numWords = 0
    for word in ship.getName():gmatch('%w+') do table.insert(shipNameWords, word) numWords = numWords+1 end
    for k,w in pairs(shipNameWords) do if w == 'LGS' then table.remove(shipNameWords, k) numWords = numWords-1 end end
    local shipShortName = shipNameWords[1]
    if shipShortName:sub(1,1) == '\'' or shipShortName:sub(1,1) == '\"' then shipShortName = shipShortName:sub(2, -1) end
    if shipNameWords[numWords]:sub(1,1) == shipNameWords[numWords]:sub(-1,-1) then shipShortName = shipShortName .. ' ' .. shipNameWords[numWords]:sub(1,1) end
    return shipShortName
end

DialModule.SpawnFirstActiveButtons = function(dialTable)
    dialTable.dial.clearButtons()
    ClearButtonsPatch(dialTable.dial)
    dialTable.dial.createButton(DialModule.Buttons.deleteFacedown)
    dialTable.dial.createButton(DialModule.Buttons.flip)
    dialTable.dial.createButton(DialModule.Buttons.nameButton(dialTable.ship))
end

DialModule.SpawnMainActiveButtons = function (dialTable)
    dialTable.dial.clearButtons()
    ClearButtonsPatch(dialTable.dial)
    dialTable.dial.createButton(DialModule.Buttons.deleteFaceup)
    dialTable.dial.createButton(DialModule.Buttons.move)
    dialTable.dial.createButton(DialModule.Buttons.toggleExpanded)
end

--[[
activeDial.createButton(button)
button.click_function = 'spawnMoveTemplate'
button.width = 450
button.height = 200
button.font_size = 150
button.label = 'temp'
button.position = {-0.3, 0.5, 0.3}
activeDial.createButton(button)]]--

DialModule.GetButtonsState = function(dial)
    local state = 0
    local buttons = dial.getButtons()
    for k,but in pairs(buttons) do
        if but.label == 'F' then if state == 0 then state = 1 end end
        if but.label == 'B' then state = 2 end
    end
    return state
end

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

DialModule.onLoad = function()
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
    --[[for k,source in pairs(DialModule.TokenSources) do
        print(k .. ' : ' .. source.getName())
    end]]--
end

DialModule.SpawnActiveButtons = function(ship)
    local dial = DialModule.GetSet(ship).activeDial.dial
    if dial == nil then
        print('wtf')
    else
        local button = {position = {0, -0.3, 0}, rotation = {180, 180, 0}, label='DEL', click_function='DialClick_Delete'}
        dial.createButton(button)
    end
end

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
            allDialsStr = allDialsStr .. ' ' .. dialInfo.dial.getDescription()
        end
        if allDialStr ~= '' then
            print(' - allDials: ' .. allDialsStr)
        else
            print(' - allDials: nil')
        end
    end
end

DialModule.RemoveSet = function(ship)
    for k, set in pairs(DialModule.ActiveSets) do
        if set.ship == ship then
            if set.activeDial ~= nil then
                DialModule.RestoreActive(set.ship)
            end
            for k,dialData in pairs(set.dialSet) do
                dialData.dial.flip()
                dialData.dial.call('setShip', {nil})
            end
            table.remove(DialModule.ActiveSets, k)
            break
        end
    end
end

DialModule.GetSet = function(ship)
    for k, set in pairs(DialModule.ActiveSets) do
        if set.ship == ship then
            return set
        end
    end
end

DialModule.AddSet = function(ship, set)
    local actSet = DialModule.GetSet(ship)
    if actSet ~= nil then
        for k, newDialData in pairs(set) do
            table.insert(actSet.dialSet, newDialData)
        end
    else
        table.insert(DialModule.ActiveSets, {ship=ship, activeDial=nil, dialSet=set})
    end
end

DialModule.MakeNewActive = function(ship, dial)
    local actSet = DialModule.GetSet(ship)
    if actSet.dialSet[dial.getDescription()].dial == dial then
        if actSet.activeDial ~= nil then
            DialModule.RestoreActive(ship)
        end
        actSet.activeDial = actSet.dialSet[dial.getDescription()]
    end
end

DialModule.RestoreActive = function(ship)
    local actSet = DialModule.GetSet(ship)
    if actSet.ship == ship and actSet.activeDial ~= nil then
        actSet.activeDial.dial.setPosition(actSet.activeDial.originPos)
        actSet.activeDial.dial.setRotation(Dial_FaceupRot(actSet.activeDial.dial))
        actSet.activeDial = nil
    end
end

DialModule.RestoreDial = function(dial)
    for k, set in pairs(DialModule.ActiveSets) do
        if set.dialSet[dial.getDescription()].dial == dial then
            if set.activeDial.dial == dial then
                DialModule.RestoreActive(set.ship)
            else
                dial.setPosition(set.dialSet[dial.getDescription()].originPos)
                dial.setRotation(Dial_FaceupRot(dial))
            end
        end
    end
end

function DialAPI_AssignSet(set_ship)
    local actSet = DialModule.GetSet(set_ship.ship)
    if actSet ~= nil then
        DialModule.RemoveSet(set_ship.ship)
    end
    local validSet = {}
    for k,dial in pairs(set_ship[1]) do
        --table.insert(validSet, {dial=dial, originPos=dial.getPosition()})
        if validSet[dial.getDescription()] ~= nil then
            print('o fuck')
        else
            validSet[dial.getDescription()] = {dial=dial, originPos=dial.getPosition()}
        end
        if dial.getVar('assignedShip') == nil then
            dial.call('setShip', {set_ship[2]})
        end
    end
    DialModule.AddSet(set_ship[2], validSet)
end

function Dial_FaceupRot(dial)
    local z_half = nil
    if(dial.getPosition()[3] < 0) then z_half = -1 else z_half = 1 end
    if z_half > 0 then
        return {x=0, y=0, z=0}
    else
        return {x=0, y=180, z=0}
    end
end
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

    function Vect_Scale(vector, factor)
        local out = {}
        local k = 1
        while vector[k] ~= nil do
            out[k] = vector[k]*factor
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
        if type == 'any' then
            return true
        elseif type == 'ship' then
            if obj.tag == 'Figurine' then return true end
        elseif type == 'token' then
            if obj.tag == 'Chip' or obj.getVar('XW_lockSet') ~= nil then return true end
        elseif type == 'lock' then
            if obj.getVar('XW_lockSet') ~= nil then return true end
        end
        return false
    end

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

    function XW_ObjWithinDist(position, maxDist, type)
        local ships = {}
        --print(position[1] .. position[2] .. position[3])
        for k,obj in pairs(getAllObjects()) do
            if XW_ObjMatchType(obj, type) == true then
                if Dist_Pos(position, obj.getPosition()) < maxDist then
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

    -- This takes care of hadnling description-based commands
    XW_cmd = {}

    -- Table of valid commands: their patterns and general types
    XW_cmd.ValidCommands = {}
    XW_cmd.AddCommand = function(cmdRegex, type)
        if cmdRegex:sub(1,1) ~= '^' then cmdRegex = '^' .. cmdRegex end
        if cmdRegex:sub(-1,-1) ~= '$' then cmdRegex = cmdRegex .. '$' end
        table.insert(XW_cmd.ValidCommands, {cmdRegex, type})
    end

    -- Process provided command on a provided object
    XW_cmd.Process = function(obj, cmd)
        cmd = cmd:match( "^%s*(.-)%s*$" )
        local type = nil
        for k,pat in pairs(XW_cmd.ValidCommands) do
            if cmd:match(pat[1]) ~= nil then
                type = pat[2]
                break
            end
        end
        if type ~= nil then print('Caught: ' .. cmd .. ', type: ' .. type)
        else print('Not recognised: ' .. cmd) end

        if type == 'move' then
            MoveModule.PerformMove(cmd, obj)
        elseif type == 'actionMove' then
            MoveModule.PerformMove(cmd, obj, true)
        elseif type == 'histHandle' then
            if cmd == 'q' or cmd == 'undo' then
                MoveModule.UndoMove(obj)
            elseif cmd == 'z' or cmd == 'redo' then
                MoveModule.RedoMove(obj)
            end
            MoveModule.PrintHistory(obj)
        end
        obj.setDescription('')
    end

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

-- Decode a move command into table with type, direction, speed etc info
MoveData.DecodeInfo = function (move_code, ship)
    local info = {type='invalid', speed=nil, dir=nil, extra=nil, size=nil, note=nil}

    if DB_isLargeBase(ship) == true then info.size = 'large'
    else info.size = 'small' end

    if move_code:sub(1,1) == 's' or move_code:sub(1,1) == 'k' then
        info.type = 'straight'
        info.speed = tonumber(move_code:sub(2,2))
        if move_code:sub(1,1) == 'k' then
            info.extra = 'koiogran'
            info.note = 'koiogran turned ' .. info.speed
        else
            info.note = 'flew straight ' .. info.speed
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
            info.note = 'segnor looped ' .. info.dir .. ' ' .. info.speed
        else
            info.note = 'banked ' .. info.dir .. ' ' .. info.speed
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
            info.note = 'talon rolled ' .. info.dir .. ' ' .. info.speed
        elseif move_code:sub(-1,-1) == 's' then
            info.extra = 'segnor'
            info.note = 'segnor looped (turn template) ' .. info.dir .. ' ' .. info.speed
        else
            info.note = 'turned ' .. info.dir .. ' ' .. info.speed
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
        info.note = 'barrel rolled'
        if move_code:sub(-1,-1) == 'f' then
            info.extra = 'forward'
            info.note = info.note .. ' forward ' .. info.dir
        elseif move_code:sub(-1,-1) == 'b' then
            info.extra = 'backward'
            info.note = info.note .. ' backward' .. info.dir
        end

        if move_code:sub(2,2) == 's' then
            info.speed = 2
            info.extra = 'straight'
            info.note = 'decloaked forward'
        end

        if  (info.size == 'small' and info.speed > 2) or (info.size == 'large' and info.speed ~= 6) then info.type = 'invalid' end

    end
    -- check database
    -- else

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
    if info.type == 'invalid' then print('Wrong move') return {0, 0, 0, 0} end
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
    if info.type == 'invalid' then print('Wrong move partial') return {0, 0, 0, 0} end

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

-- Table containing all the high-level functions used to move stuff around
MoveModule = {}

-- Simply get the final position for a 'ship' if it did a move (standard move code)
-- Format:  out.pos for position, out.rot for rotation
-- Position and rotation are ready to feed TTS functions
MoveModule.GetFinalPos = function(move, ship)
    local finalPos = MoveData.DecodeFull(move, ship)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- Simply get the final position for a 'ship' if it did a part of a move (standard move code)
-- part goes from 0 to PartMax
-- Format:  out.pos for position, out.rot for rotation
-- Position and rotation are ready to feed TTS functions
MoveModule.GetPartialPos = function(move, ship, part)
    local finalPos = MoveData.DecodePartial(move, ship, part)
    local finalRot = finalPos[4] + ship.getRotation()[2]
    finalPos = Vect_RotateDeg(finalPos, ship.getRotation()[2]+180)
    finalPos = Vect_Offset(ship.getPosition(), finalPos)
    return {pos=finalPos, rot={0, finalRot, 0}}
end

-- moveHistory:{ship=shipRef, actKey=actHistoryKey, history=history}
-- history: {entry1, entry2, entry3 .. etc}
-- entry: {pos=postion, rot=rotation, move=lastMove}

MoveModule.moveHistory = {}
XW_cmd.AddCommand('[qz]', 'histHandle')
XW_cmd.AddCommand('undo', 'histHandle')
XW_cmd.AddCommand('redo', 'histhandle')

MoveModule.GetHistory = function(ship)
    for k,hist in pairs(MoveModule.moveHistory) do
        if hist.ship == ship then
            return hist
        end
    end
    table.insert(MoveModule.moveHistory, {ship=ship, actKey=0, history={}})
    return MoveModule.GetHistory(ship)
end

MoveModule.ErasePastCurrent = function(ship)
    local histData = MoveModule.GetHistory(ship)
    local k=1
    while histData.history[histData.actKey + k] ~= nil do
        histData.history[histData.actKey + k] = nil
    end
end

undoPosCutoff = Convert_mm_igu(1)
undoRotCutoffDeg = 1

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

MoveModule.AddHistoryEntry = function(ship, entry)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey > 0 then
        local currEntry = histData.history[histData.actKey]
        --print(currEntry.pos[1])
        --print(currEntry.rot[2])
        --print(currEntry.move)
        if Dist_Pos(ship.getPosition(), currEntry.pos) < undoPosCutoff
        and math.abs(ship.getRotation()[2] - currEntry.rot[2]) < undoRotCutoffDeg then
            print('pos already saved')
            return
        end
    end
    histData.history[histData.actKey+1] = entry
    --print(entry.pos[1])
    --print(entry.rot[2])
    --print(entry.move)
    histData.actKey = histData.actKey+1
    MoveModule.ErasePastCurrent(ship)
    MoveModule.PrintHistory(ship)
end



MoveModule.UndoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey == 0 then
        print('no histtory')
        return
    else
        local currEntry = histData.history[histData.actKey]
        --print(currEntry.pos[1])
        --print(currEntry.rot[2])
        --print(currEntry.move)
        local rotDiff = math.abs(ship.getRotation()[2] - currEntry.rot[2])
        if rotDiff > 180 then rotDiff = 360 - rotDiff end
        if Dist_Pos(ship.getPosition(), currEntry.pos) > undoPosCutoff
        or rotDiff > undoRotCutoffDeg then
            print('moved to last known pos, lastmove: ' .. currEntry.move)
            print('pmarg: ' .. Dist_Pos(ship.getPosition(), currEntry.pos) .. ' rmarg: ' .. rotDiff)
            ship.setPosition(currEntry.pos)
            ship.setRotation(currEntry.rot)
            ship.lock()
        else
            if histData.actKey > 1 then
                print('undid ' .. currEntry.move)
                histData.actKey = histData.actKey - 1
                currEntry = histData.history[histData.actKey]
                ship.setPosition(currEntry.pos)
                ship.setRotation(currEntry.rot)
                ship.lock()
            else
                print('already at last known')
            end
        end
    end
end

MoveModule.RedoMove = function(ship)
    local histData = MoveModule.GetHistory(ship)
    if histData.actKey == 0 then
        print('no histtory')
        return
    else
        if histData.history[histData.actKey+1] == nil then
            print('no more to redo')
        else
            histData.actKey = histData.actKey+1
            local currEntry = histData.history[histData.actKey]
            ship.setPosition(currEntry.pos)
            ship.setRotation(currEntry.rot)
            ship.lock()
            print('redid ' .. currEntry.move)
        end
    end
end

--TO_DO: dont add an entry if its same as last


-- This tidbit lets us wait till ships lands WITHOUT checking for this condition
--  on everything all the time

-- Queue containing ships that want to be watched
MoveModule.restWaitQueue = {}
MoveModule.tokenWaitQueue = {}

-- This completes when a ship is resting at a table level
-- also yanks it down if TTS decides it should just hang out resting midair
function restWaitCoroutine()
    if MoveModule.restWaitQueue[1] == nil then print('EMPTY') return 0 end
    local waitData = MoveModule.restWaitQueue[#MoveModule.restWaitQueue]
    local actShip = waitData.ship
    local yank = false
    table.remove(MoveModule.restWaitQueue, #MoveModule.restWaitQueue)
    repeat
        if actShip.getPosition()[2] > 1.5 and actShip.resting == true then
            actShip.setPositionSmooth({actShip.getPosition()['x'], actShip.getPosition()['y']-0.1, actShip.getPosition()['z']})
            --print('yank')
        end
        coroutine.yield(0)
    until actShip.resting == true and actShip.held_by_color == nil and actShip.getPosition()[2] < 1.5
    for k,tokenInfo in pairs(MoveModule.tokenWaitQueue) do
        if tokenInfo.ship == actShip then
            local offset = Vect_RotateDeg(tokenInfo.offset, actShip.getRotation()[2])
            local dest = Vect_Sum(offset, actShip.getPosition())
            dest[2] = dest[2] + 1.5
            tokenInfo.token.setPositionSmooth(dest)
            table.remove(MoveModule.tokenWaitQueue, k)
            k = k-1
        end
    end
    print('MF: ' .. actShip.getName())
    actShip.lock()
    MoveModule.AddHistoryEntry(actShip, {pos=actShip.getPosition(), rot=actShip.getRotation(), move=waitData.lastMove})

    return 1
end

-- Check if provided ship in a provided position/rotation would collide
--  with anything from the provided table
-- This is ALMOST where shit gets real
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
                --print('CertBump')
                if certBumpDist - dist > info.minMargin then
                    info.minMargin = certBumpDist - dist
                    --print('Dist: ' .. Convert_igu_mm(dist) .. ' to_go: ' .. Convert_igu_mm(info.minMargin))
                end
            elseif collide(shipInfo, {pos=collShip.getPosition(), rot=collShip.getRotation(), ship=collShip}) == true then
                info.coll = collShip
                info.numCheck = info.numCheck + 1
                --print('CheckBump')
                break
            end
            if info.coll ~= nil then
                --print('col: ' .. collShip.getName() .. ' : ' .. dist)
            end
        end
    end
    return info
end

function test(table)
    return MoveModule.CheckCollisions(table[1], table[2], table[3])
end

MoveModule.PerformMove = function(move_code, ship, ignoreCollisions)

    local finPos = nil

    if ignoreCollisions ~= true then
        local info = MoveData.DecodeInfo(move_code, ship)
        local moveLength = MoveData[info.type].length[info.speed]
        moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetInit'])
        moveLength = moveLength + Vect_Length(MoveData[info.type][info.size .. 'BaseOffsetFinal'])
        moveLength = Convert_mm_igu(moveLength)
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
        --print(maxShipReach)
        local ships = XW_ObjWithinDist(MoveModule.GetPartialPos(move_code, ship, PartMax/2).pos, moveLength+(2*maxShipReach), 'ship')
        for k, collShip in pairs(ships) do if collShip == ship then table.remove(ships, k) end end

        local finalInfo = MoveModule.CheckCollisions(ship, MoveModule.GetFinalPos(move_code, ship), ships)
        local actPart = PartMax
        if finalInfo.coll ~= nil then
            local checkNum = 0

            local collision = false
            --print(actPart)
            local partDelta = -10
            repeat
                local nPos = MoveModule.GetPartialPos(move_code, ship, actPart)
                local collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                local distToSkip = nil
                if collInfo.coll ~= nil then
                    collision = true
                    distToSkip = collInfo.minMargin
                    if distToSkip > 0 then
                        partDelta = -1*((distToSkip * PartMax)/moveLength)
                        if partDelta > -10 then partDelta = -10 end
                        --print('skip: ' .. partDelta*-1)
                    else partDelta = -10 end
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
            until collision == false or actPart < 0
            partDelta = 1
            repeat
                local nPos = MoveModule.GetPartialPos(move_code, ship, actPart)
                local collInfo = MoveModule.CheckCollisions(ship, nPos, ships)
                if collInfo.coll ~= nil then collision = true
                else collision = false end
                actPart = actPart + partDelta
                checkNum = checkNum + collInfo.numCheck
            until collision == true or actPart > PartMax
            actPart = actPart - 1

            --print('CN: ' .. checkNum)
        end
        finPos = MoveModule.GetPartialPos(move_code, ship, actPart)
    else
        finPos = MoveModule.GetFinalPos(move_code, ship)
    end

    local isShipLargeBase = DB_isLargeBase(ship)
    local maxShipReach = nil
    if isShipLargeBase == true then
        maxShipReach = Convert_mm_igu(mm_largeBase*math.sqrt(2)/2)
    else
        maxShipReach = Convert_mm_igu(mm_smallBase*math.sqrt(2)/2)
    end

    local selfTokens = XW_ObjWithinDist(ship.getPosition(), maxShipReach+Convert_mm_igu(50), 'token')
    for k, token in pairs(selfTokens) do
        local owner = XW_ClosestWithinDist(token, Convert_mm_igu(80), 'ship').obj
        if owner == ship then
            print('ASS: ' .. token.getName())
            local infoTable = {}
            infoTable.token = token
            infoTable.ship = ship
            local offset = Vect_Sum(token.getPosition(), Vect_Scale(ship.getPosition(), -1))
            infoTable.offset = Vect_RotateDeg(offset, -1*ship.getRotation()[2])
            table.insert(MoveModule.tokenWaitQueue, infoTable)
        end
    end

    local obstrTokens = XW_ObjWithinDist(finPos.pos, maxShipReach+Convert_mm_igu(20), 'token')
    for k, token in pairs(obstrTokens) do
        local owner = XW_ClosestWithinDist(token, Convert_mm_igu(80), 'ship').obj
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
        else
            local dir = Vect_Sum(token.getPosition(), Vect_Scale(finPos.pos, -1))
            local dist = Vect_Length(dir)
            dir = Vect_Scale(dir, ((maxShipReach+Convert_mm_igu(20))/dist))
            local dest = Vect_Sum(finPos.pos, dir)
            dest[2] = 2
            token.setPositionSmooth(dest)
        end
    end

    finPos.pos[2] = finPos.pos[2] + 1
    ship.setPosition(finPos.pos)
    ship.setRotation(finPos.rot)
    ship.setDescription('')
    table.insert(MoveModule.restWaitQueue, {ship=ship, lastMove=move_code})
    startLuaCoroutine(Global, 'restWaitCoroutine')

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
                --MoveModule.PerformMove(obj.getDescription(), obj)
                XW_cmd.Process(obj, obj.getDescription())
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
    local size = nil
    if DB_isLargeBase(shipInfo.ship) == true then
        size = Convert_mm_igu((mm_largeBase/2) + 0.2)
    else
        size = Convert_mm_igu((mm_smallBase/2) + 0.2)
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

function DB_getShipTypeCallable(table)
    return DB_getShipType(table[1])
end

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
        print(shipRef.getName() .. '\'s model not recognized - use LGS in name if large base and contact author about the issue')
        return false
    end
end

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