buttonsSpawned = false
shipsWithButtons = {}
dialSet = {}

-- Script for child dials
dialLuaScript = [[
assignedShip = nil

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

function onLoad()
    -- if just spawned out of the blue
    if self.getVar('proceedAssignment') ~= true then
        local button = {}
        button.click_function = 'toggleChoiceButtons'
        button.function_owner = self
        button.label = 'Assign ship'
        button.position = {0, -0.3, 0}
        button.rotation = {180, 180, 0}
        button.width = 1500
        button.height = 500
        button.font_size = 300
        self.createButton(button)
    else
    -- if spawned because ship has been chosen and state changed
        local dialSpacing = (2/0.625)*(self.getScale()[1])
        self.setRotation(correctQuadrantRotation(false))
        local te0pos = self.getPosition()
        local stackDials = self.getObjects()
        kNum = 1
        for k, dial in pairs(stackDials) do
            if dial['description'] ~= 'spec' then
                local dialPos = decodePos(dial['description'], te0pos, dialSpacing)
                newDial = self.takeObject({position=dialPos, rotation=correctQuadrantRotation(true), guid=dial['guid']})
                newDial.setLuaScript(dialLuaScript)
                table.insert(dialSet, newDial)
                newDial.setPosition(dialPos)
                newDial.setRotation(correctQuadrantRotation(true))
                newDial.setName(self.getVar('setShip').getName())
            end
        end
        local button = {}
        button.click_function = 'FinishSetup'
        button.function_owner = self
        button.label = 'CONFIRM\nPLACEMENT'
        button.position = {0, -0.3, 0}
        button.rotation = {180, 180, 0}
        button.width = 1500
        button.height = 900
        button.font_size = 300
        self.createButton(button)
    end
end

-- Report all dials to be set to global
function FinishSetup()
    Global.call('DialAPI_AssignSet', {set=dialSet, ship=self.getVar('setShip')})
    self.destruct()
end

-- Get correct dial position
function decodePos(desc, te0pos, dialSpacing)
    dir = nil
    speed = nil
    type = nil
    if desc:sub(-1, -1) == 's' then
        type = 'seg'
        speed = tonumber(desc:sub(-2, -2))
        dir = desc:sub(-3, -3)
    elseif desc:sub(-1, -1) == 't' then
        type = 'tal'
        speed = tonumber(desc:sub(-2, -2))
        dir = desc:sub(-3, -3)
    elseif desc:sub(1, 1) == 'k' then
        type = 'koi'
        speed = tonumber(desc:sub(2, 2))
        dir = 's'
    elseif desc:sub(1, 1) == 's' then
        type = 's'
        speed = tonumber(desc:sub(2, 2))
        dir = 's'
    else
        type = desc:sub(1, 1)
        dir = desc:sub(2, 2)
        speed = tonumber(desc:sub(3, 3))
    end

    local outPos = {x=0, y=0.1, z=0}
    outPos['z'] = speed * dialSpacing
    if type == 's' then outPos['x'] = 0

    elseif type == 'seg' or type == 'tal' then
        if dir == 'r' then outPos['x'] = dialSpacing
        else outPos['x'] = -1*dialSpacing end
        outPos['z'] = 4*dialSpacing

    elseif type == 'koi' then
        if kNum == 1 or kNum == 2 then outPos['x'] = 2*dialSpacing
        else outPos['x'] = -2*dialSpacing end
        if kNum == 1 or kNum == 3 then outPos['z'] = 4*dialSpacing
        else outPos['z'] = 5*dialSpacing end
        kNum = kNum + 1

    else
        if type == 'b' then outPos['x'] = dialSpacing
        elseif type == 't' then outPos['x'] = 2*dialSpacing
        end

        if dir == 'e' or dir == 'l' then outPos['x'] = outPos['x'] * -1 end
    end

    if z_half(self) == 1 then
        outPos['x'] = outPos['x'] * -1
        outPos['y'] = outPos['y'] * -1
        outPos['z'] = outPos['z'] * -1
    end


    outPos['x'] = outPos['x'] + te0pos['x'] - (2*dialSpacing*z_half(self))
    outPos['y'] = outPos['y'] + te0pos['y']
    outPos['z'] = outPos['z'] + te0pos['z']
    return outPos
end

-- Choose a ship, check its type and adjust self state
-- Prepare next state object to continue
function AssignAndProceed(ship)
    local currState = 1
    local currType = self.getObjects()[1].nickname
    currType = currType:gsub(' Dial', '')
    for type, state in pairs(dialStateIndex) do
        if currType == type then currState = state end
    end
    local type = Global.call('DB_getShipTypeCallable', {ship})
    if type ~= 'Unknown' then
        local newState = dialStateIndex[type]
        local newObj
        if currState ~= newState then
            newObj = self.setState(newState)
            newObj.setLuaScript(self.getLuaScript())
        else
            newObj = self
        end
        newObj.setVar('proceedAssignment', true)
        newObj.setVar('setShip', ship)
        if newObj == self then onLoad() end
    else
        printToAll('This ship model has been not recognized (contact author about it)', {1, 0.1, 0.1})
    end
end

-- Get which table half an object is
function z_half(obj) if(obj.getPosition()[3] < 0) then return -1 else return 1 end end
function x_half(obj) if(obj.getPosition()[1] < 0) then return -1 else return 1 end end

-- Is this object in the same quadrant as me?
function sameQuadrant(obj)
    if z_half(obj) == z_half(self) and x_half(obj) == x_half(self) then return true
    else return false end
end

-- (._.)
function correctQuadrantRotation(faceup)
    if z_half(self) > 0 then
        if faceup == false then return {x=180, y=180, z=0}
        else return {x=0, y=0, z=0} end
    else
        if faceup == false then return {x=180, y=0, z=0}
        else return {x=0, y=180, z=0} end
    end
end


function toggleChoiceButtons()
    if buttonsSpawned ~= true then
        self.setRotation(correctQuadrantRotation(false))
        local ships = {}
        for k,obj in pairs(getAllObjects()) do
            if obj.tag == 'Figurine' and sameQuadrant(obj, self) and obj.getVar('DialModule_hasDials') ~= true then
                table.insert(ships, obj)
            end
        end
        for k,obj in pairs(ships) do
            local button = {}
            button.click_function = 'chooseShip'
            button.function_owner = self
            button.label = '\n\nASSIGN'
            button.rotation = {180, 180, 0}
            button.width = 900
            button.height = 1100
            button.font_size = 250
            local opos = obj.getPosition()
            local spos = self.getPosition()
            local bpos = {(spos[1]-opos[1])*(-1.12*z_half(self)), -0.4, (spos[3]-opos[3])*((-1*z_half(self))/self.getScale()[3])}
            button.position = bpos
            self.createButton(button)
            buttonsSpawned = true
            table.insert(shipsWithButtons, obj)
        end
        if buttonsSpawned == true then
            local buttons = self.getButtons()
            for k,but in pairs(buttons) do
                if but.label == 'Assign ship' then self.editButton({index=but.index, label='Cancel choice', width=1800}) end
            end
        end
    else
        local buttons = self.getButtons()
        for k,but in pairs(buttons) do
            if but.label == '\n\nASSIGN' then self.removeButton(but.index) end
            if but.label == 'Cancel choice' then self.editButton({index=but.index, label='Assign ship', width=1500}) end
        end
        buttonsSpawned = false
    end
end

function Dist_Pos(pos1, pos2)
    return math.sqrt( math.pow(pos1[1]-pos2[1], 2) + math.pow(pos1[3]-pos2[3], 2) )
end

function ClearButtonsPatch(obj)
    local buttons = obj.getButtons()
    if buttons ~= nil then
        for k,but in pairs(buttons) do
            obj.removeButton(but.index)
        end
    end
end

function chooseShip(obj, color)
    local nearest = shipsWithButtons[1]
    local minDist = Dist_Pos(nearest.getPosition(), Player[color].getPointerPosition())
    for k,ship in pairs(shipsWithButtons) do
        local newDist = Dist_Pos(ship.getPosition(), Player[color].getPointerPosition())
        if newDist < minDist then
            nearest = ship
            minDist = newDist
        end
    end
    self.clearButtons()
    ClearButtonsPatch(self)
    AssignAndProceed(nearest)
end

dialStateIndex = {}
dialStateIndex['A-Wing']=1
dialStateIndex['Attack Shuttle']=2
dialStateIndex['B-Wing']=3
dialStateIndex['E-Wing']=4
dialStateIndex['HWK-290 Rebel']=5
dialStateIndex['K-Wing']=6
dialStateIndex['T-70 X-Wing']=7
dialStateIndex['X-Wing']=8
dialStateIndex['Y-Wing Rebel']=9
dialStateIndex['YT-1300']=10
dialStateIndex['YT-2400']=11
dialStateIndex['VCX-100']=12
dialStateIndex['Z-95 Headhunter Rebel']=13
dialStateIndex['Aggressor']=14
dialStateIndex['Firespray-32']=15
dialStateIndex['G-1A StarFighter']=16
dialStateIndex['HWK-290 Scum']=17
dialStateIndex['JumpMaster 5000']=18
dialStateIndex['Kihraxz Fighter']=19
dialStateIndex['M3-A Interceptor']=20
dialStateIndex['StarViper']=21
dialStateIndex['Y-Wing']=22
dialStateIndex['YV-666']=23
dialStateIndex['Z-95 Headhunter Scum']=24
dialStateIndex['Firespray-31 Imperial']=25
dialStateIndex['Lambda-Class Shuttle']=26
dialStateIndex['TIE Adv. Prototype']=27
dialStateIndex['TIE Advanced']=28
dialStateIndex['TIE Bomber']=29
dialStateIndex['TIE Defender']=30
dialStateIndex['TIE/fo Fighter']=31
dialStateIndex['TIE Fighter']=32
dialStateIndex['TIE Interceptor']=33
dialStateIndex['TIE Phantom']=34
dialStateIndex['TIE Punisher']=35
dialStateIndex['VT-49 Decimator']=36