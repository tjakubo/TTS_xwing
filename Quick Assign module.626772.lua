-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
-- ~~~~~~

-- Data for buttons spawn and dial layout zones
PosData = {}
PosData.buttonCorner = {50, 4, 35}
PosData.zoneCorner = {0, 1, 26}
PosData.zoneSize = {45, 1, 12}

-- Modify position data for each color
PosData.Blue = function(pos)
    return {pos[1], pos[2], pos[3]}
end
PosData.Green = function(pos)
    return {-1*pos[1], pos[2], pos[3]}
end
PosData.Teal = function(pos)
    return {pos[1], pos[2], -1*pos[3]}
end
PosData.Red = function(pos)
    return {-1*pos[1], pos[2], -1*pos[3]}
end

AssignModule = {}

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

-- Is object matching some predefeined X-W type
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

-- Get objects within rectangle
-- Rectangle must be aligned with table (no rotation)
function XW_ObjWithinRect(center, x_size, z_size)
    local objects = {}
    local x_min = center[1] - (x_size/2)
    local x_max = center[1] + (x_size/2)
    local z_min = center[3] - (z_size/2)
    local z_max = center[3] + (z_size/2)
    for k,obj in pairs(getAllObjects()) do
        if obj.tag ~= 'Fog' and obj.interactable == true then
            local obj_x = obj.getPosition()[1]
            local obj_z = obj.getPosition()[3]
            if obj_x < x_max and obj_x > x_min and obj_z < z_max and obj_z > z_min then
                table.insert(objects, obj)
            end
        end
    end
    return objects
end

function Click_Red(n, playerColor)
    if self.getVar('RedBusy') == true then
        broadcastToColor(AssignModule.msg.clickTooFast, playerColor, {1, 0.2, 0})
    else
        AssignModule.Assign('Red', playerColor)
    end
end
function Click_Blue(n, playerColor)
    if self.getVar('BlueBusy') == true then
        broadcastToColor(AssignModule.msg.clickTooFast, playerColor, {1, 0.2, 0})
    else
        AssignModule.Assign('Blue', playerColor)
    end
end
function Click_Teal(n, playerColor)
    if self.getVar('TealBusy') == true then
        broadcastToColor(AssignModule.msg.clickTooFast, playerColor, {1, 0.2, 0})
    else
        AssignModule.Assign('Teal', playerColor)
    end
end
function Click_Green(n, playerColor)
    if self.getVar('GreenBusy') == true then
        broadcastToColor(AssignModule.msg.clickTooFast, playerColor, {1, 0.2, 0})
    else
        AssignModule.Assign('Green', playerColor)
    end
end



AssignModule.maxShipCount = 6
AssignModule.msg = {}
AssignModule.msg.emptyZone = 'Quick Assign: Place ships you want to assign dials for in your hidden zone'
AssignModule.msg.notShipsOnly = 'Quick Assign: Remove objects that are not ship models from your hidden zone and try again'
AssignModule.msg.tooManyShips = 'Quick Assign: Too many ship models (max ' .. AssignModule.maxShipCount ..'), use adjacent hidden zone for some of yor ships'
AssignModule.msg.unrecognizedShips = 'Quick Assign: Some ship models in your zone have not been recognized. Make sure your models are sourced from squad building tray on this table and contact author if this issue persists'
AssignModule.msg.clickTooFast = 'Quick Assign: Clicking too fast, please wait until assignment finishes'

AssignModule.SortShips = function(shipData)
    local sortedData = {}
    repeat
        local xMax = {ind=1, val=math.abs(shipData[1].ref.getPosition()[1])}
        for k,data in pairs(shipData) do
            if math.abs(data.ref.getPosition()[1]) > xMax.val then
                xMax.val = math.abs(data.ref.getPosition()[1])
                xMax.ind = k
            end
        end
        table.insert(sortedData, shipData[xMax.ind])
        table.remove(shipData, xMax.ind)
    until shipData[1] == nil
    return sortedData
end
-- Check zone contents and assign dials if everything is OK
AssignModule.Assign = function(zoneColor, playerColor)
    -- Get objects, assets that there are only ships in and their count
    local zone_c1 = PosData[zoneColor](PosData.zoneCorner)
    local zone_c2 = Vect_Sum(zone_c1, PosData[zoneColor](PosData.zoneSize))
    local zone_center = Vect_Sum(Vect_Scale(zone_c1, 0.5), Vect_Scale(zone_c2, 0.5))
    local x_size = math.max(zone_c1[1], zone_c2[1]) - math.min(zone_c1[1], zone_c2[1])
    local z_size = math.max(zone_c1[3], zone_c2[3]) - math.min(zone_c1[3], zone_c2[3])
    local zoneObjects = XW_ObjWithinRect(zone_center, x_size, z_size)
    if zoneObjects[1] == nil then
        broadcastToColor(AssignModule.msg.emptyZone, playerColor, {1, 0.2, 0})
        return
    end
    local shipsOnly = true
    local tokenObjects = {}
    local shipObjects = {}
    for k,obj in pairs(zoneObjects) do
        if XW_ObjMatchType(obj, 'token') then
            table.insert(tokenObjects, obj)
        elseif XW_ObjMatchType(obj, 'ship') then
            table.insert(shipObjects, obj)
        else
            shipsOnly = false
            break
        end
    end
    if not shipsOnly then
        broadcastToColor(AssignModule.msg.notShipsOnly, playerColor, {1, 0.2, 0})
        return
    end
    if #shipObjects > AssignModule.maxShipCount then
        broadcastToColor(AssignModule.msg.tooManyShips, playerColor, {1, 0.2, 0})
        return
    end

    -- Get ship type data
    local typesOK = true
    local shipData = {}
    local bagData = {}
    for k,ship in pairs(shipObjects) do
        local shipType = Global.call('DB_getShipTypeCallable', {ship})
        if shipType == 'Unknown' then
            typesOK = false
            break
        elseif bagData[shipType] == nil then
            bagData[shipType] = {}
        end
        table.insert(shipData, {ref=ship, type=shipType})
    end
    if not typesOK then
        broadcastToColor(AssignModule.msg.unrecognizedShips, playerColor, {1, 0.2, 0})
        return
    end
    self.setVar(zoneColor .. 'Busy', true)
    shipData = AssignModule.SortShips(shipData)
    -- Dial bags desired position and its step
    local function bPosStep(pos)
        return {pos[1], pos[2], pos[3] - 2.6*math.sgn(pos[3])}
    end
    local bPos = bPosStep(PosData[zoneColor](PosData.buttonCorner))
    bPos[2] = 1.5

    -- If there are valid dial bags on the table, take them
    local function TableConcat(t1,t2)
        for i=1,#t2 do
            t1[#t1+1] = t2[i]
        end
        return t1
    end
    local playerStuff = XW_ObjWithinRect({bPos[1]/2, 0, bPos[3]/2}, math.abs(bPos[1])+1, math.abs(bPos[3])+1)
    -- -85, -27
    -- -57, 27
    -- S: 28, 54
    -- C: -71, 0

    -- 47, 12
    -- 53, 35
    playerStuff = TableConcat(playerStuff, XW_ObjWithinRect({-71, 0, 0}, 28, 54))
    for k,obj in pairs(playerStuff) do
        if obj.tag == 'Infinite' and obj.getName():find('Dials') ~= nil and tonumber(obj.getDescription()) ~= nil and tonumber(obj.getDescription()) >= 1.1 then
            local type = obj.getName():sub(1, obj.getName():find(' Dials')-1)
            if bagData[type] ~= nil and bagData[type].dialBag == nil then
                bagData[type].dialBag = obj
            end
        end
    end
    local currentDials = XW_ObjWithinRect(PosData[zoneColor]({50, 0, 23.5}), 6, 23)
    for k,obj in pairs(currentDials) do
        if obj.tag == 'Infinite' and obj.getName():find('Dials') ~= nil and tonumber(obj.getDescription()) ~= nil and tonumber(obj.getDescription()) >= 1.1 then
            local type = obj.getName():sub(1, obj.getName():find(' Dials')-1)
            if bagData[type] == nil or ( bagData[type] ~= nil and bagData[type].dialBag ~= obj ) then
                obj.destruct()
            end
        end
    end

    -- If some bags were not on the table, grab them from squad builder module
    local bagsToGrab = {}
    local grabbed = nil
    for type,data in pairs(bagData) do
        if data.dialBag == nil then
            table.insert(bagsToGrab, type)
        end
    end
    if bagsToGrab[1] ~= nil then
        grabbed = AssignModule.GrabDialBags(bagsToGrab)
        for type,data in pairs(bagData) do
            if data.dialBag == nil then
                data.dialBag = grabbed[type]
            end
        end
    end

    -- Move the dial bags to desired position
    for type,data in pairs(bagData) do
        data.dialBag.setPositionSmooth(bPos)
        data.dialBag.unlock()
        bPos = bPosStep(bPos)
    end

    -- LAY OUT DIALS

    local dialSize = 3.1                                            -- Physical dial size
    local scaleTable = {0.625, 0.625, 0.625, 0.625, 0.525, 0.45}    -- Dial scale for each ship count
    local currScale = scaleTable[#shipObjects]
    local zoneSize = 45                                             -- Zone width
    local extraSpace = 45 - (5*dialSize*currScale*(#shipObjects))
    local extraSpacing = extraSpace/(#shipObjects+1)

    -- Since dial expand right, blue and green zone must have inset starting position
    local blueGreenOffset = 0
    local stPos = {zone_c2[1] - math.sgn(zone_c2[1])*(dialSize*(currScale/2) + extraSpacing), 1, zone_c2[3] - (math.sgn(zone_c2[3])*dialSize*currScale/2)}
    if math.sgn(stPos[3]) ~= math.sgn(stPos[1]) then
        stPos = {stPos[1] - math.sgn(stPos[1])*dialSize*currScale*5, stPos[2], stPos[3]}
    end

    -- Stacks and ship positions
    local function stPosStep(pos)
        return {pos[1] - math.sgn(pos[1])*(5*dialSize*currScale + extraSpacing), pos[2], pos[3]}
    end
    local function shipPos(stackPos)
        return {stackPos[1] - (math.sgn(stackPos[3])*2.5*dialSize*currScale), stackPos[2]+3, stackPos[3] - (math.sgn(stackPos[3])*6.5*dialSize*currScale)}
    end

    -- Take stacks, set expand callback for them
    for k,data in pairs(shipData) do
        local newStack = bagData[data.type].dialBag.takeObject({position=stPos, callback='expandSet', callback_owner=self, params={ship = data.ref, scale = {currScale, 1, currScale}, unlock=zoneColor}})
        data.ref.setPositionSmooth(shipPos(stPos))
        local rot = 180
        if math.sgn(stPos[3]) > 0 then
            rot = 0
        end
        Global.call('API_QueueShipTokensMove', {ship = data.ref})
        data.ref.setRotationSmooth({0, rot, 0})
        data.ref.highlightOn({0, 1, 0}, 1)
        stPos = stPosStep(stPos)
    end

end

function expandSet(obj, params)
    obj.setScale(params.scale)
    obj.call('init', {ship=params.ship})
    self.setVar(params.unlock .. 'Busy', false)
end

function math.sgn(arg)
    if arg < 0 then
        return -1
    elseif arg > 0 then
        return 1
    end
    return 0
end

-- Grab dial bags for specified types from spawner and return them
AssignModule.GrabDialBags = function(shipTypesTable)
    -- Get spawner bags template
    local spawnerBagsTemp = nil
    for k,obj in pairs(getAllObjects()) do
        if obj.getName() == 'TEMPLATE{Spawner Bags}' then
            spawnerBagsTemp = obj
        end
    end

    -- CLone it and take the accesories bag (with dials)
    local sPos = self.getPosition()
    local bagClone = spawnerBagsTemp.clone({position = {sPos[1], sPos[2]-1, sPos[3]}})
    local accBagGUID = nil
    for k,data in pairs(bagClone.getObjects()) do
        if data.name == 'Accesories Bag' then
            accBagGUID = data.guid
            break
        end
    end
    local accBag = bagClone.takeObject({guid=accBagGUID, position={sPos[1]+3, sPos[2], sPos[3]}})
    accBag.lock()
    accBag.tooltip = false
    accBag.interactable = false

    -- Grab appropriate dials bags
    local dialBagsInfo = {}
    for k,data in pairs(accBag.getObjects()) do
        if data.name:find('Dials') ~= nil then
            dialBagsInfo[data.name] = data.guid
        end
    end
    local grabbed = {}
    for k,type in pairs(shipTypesTable) do
        grabbed[type] = accBag.takeObject({guid = dialBagsInfo[type .. ' Dials'], position = {sPos[1]-3, sPos[2], sPos[3]}})
        grabbed[type].lock()
    end

    -- Cleaup
    bagClone.destruct()
    accBag.destruct()
    return grabbed
end

-- Create quick assign buttons
AssignModule.CreateButtons = function()
    local pos_fList = {PosData.Red, PosData.Blue, PosData.Green, PosData.Teal}
    local click_fList = {'Click_Teal','Click_Green','Click_Blue','Click_Red'}
    for k, posF in pairs(pos_fList) do
        local buttonParams = {label='Assign Dials', rotation={0, 0, 0}, function_owner=self, height=750, width=2500, font_size=400}
        buttonParams.position = posF(PosData.buttonCorner)
        buttonParams.click_function = click_fList[k]
        if buttonParams.position[3] < 0 then
            buttonParams.rotation[2] = 180
        end
        self.createButton(buttonParams)
    end
end

function onLoad(save_state)
    self.lock()
    self.setPosition({0, -3, 0})
    self.setRotation({0, 0, 0})
    self.setScale({1, 1, 1})
    self.interactable = false
    self.tooltip = false
    AssignModule.CreateButtons()
end