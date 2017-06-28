-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
-- ~~~~~~

assignedShip = nil      -- Ref to assigned ship if there is one
idle = false

nameUnassigned = 'Bomb drop token (unassigned)'
nameAssigned = '\'s bomb drop token'

-- Save self state
function onSave()
    if assignedShip ~= nil then
        local state = {assignedShipGUID=assignedShip.getGUID()}
        return JSON.encode(state)
    end
end

-- Restore self state
function onLoad(save_state)
    self.setName(nameUnassigned)
    if save_state ~= '' and save_state ~= 'null' and save_state ~= nil then
        local assignedShipGUID = JSON.decode(save_state).assignedShipGUID
        if assignedShipGUID ~= nil and getObjectFromGUID(assignedShipGUID) ~= nil then
            assignedShip = getObjectFromGUID(assignedShipGUID)
            self.setName(assignedShip.getName() .. nameAssigned)
            SpawnFirstButtons()
        end
    end
end

-- Spawn initial drop/unsassign buttons
function SpawnFirstButtons()
    self.clearButtons()
    local decloakButton = {['function_owner'] = self, ['click_function'] = 'SpawnDropButtons', ['label'] = 'Drop bomb', ['position'] = {0, 0.25, -1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1500, ['height'] = 500, ['font_size'] = 250}
    self.createButton(decloakButton)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfUnassign', ['label'] = 'Unassign', ['position'] = {0, 0.25, 1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1100, ['height'] = 500, ['font_size'] = 250}
    self.createButton(deleteButton)
end

-- Assign on drop near a small base ship
function onDropped()
    if assignedShip == nil then
        local spos = self.getPosition()
        local nearest = nil
        local minDist = 2.89 -- 80mm
        for k,ship in pairs(getAllObjects()) do
            if ship.tag == 'Figurine' and ship.name ~= '' then
                local pos = ship.getPosition()
                local dist = math.sqrt(math.pow((spos[1]-pos[1]),2) + math.pow((spos[3]-pos[3]),2))
                if dist < minDist then
                    nearest = ship
                    minDist = dist
                end
            end
        end
        if nearest ~= nil then
            printToAll('Bomb drop token assigned to ' .. nearest.getName(), {0.2, 0.2, 1})
            SpawnFirstButtons()
            assignedShip = nearest
            self.setName(assignedShip.getName() .. nameAssigned)
        end
    end
end

local sp = 0.7
local butPos = {}
butPos['s1'] = {0, 1*sp}
butPos['s2'] = {0, 2*sp}
butPos['s3'] = {0, 3*sp}
butPos['s4'] = {0, 4*sp}
butPos['s5'] = {0, 5*sp}
butPos['br1'] = {1*sp, 1*sp}
butPos['br2'] = {1*sp, 2*sp}
butPos['br3'] = {1*sp, 3*sp}
butPos['tr1'] = {2*sp, 1*sp}
butPos['tr2'] = {2*sp, 2*sp}
butPos['tr3'] = {2*sp, 3*sp}

function ButtonPos(butCode)
    local rev = false
    local left = false
    if butCode:sub(-1, -1) == 'r' then
        rev = true
        butCode = butCode:sub(1, -2)
    end
    if butCode:sub(2, 2) == 'e' or butCode:sub(2, 2) == 'l' then
        left = true
        butCode = butCode:sub(1, 1) .. 'r' .. butCode:sub(3, -1)
    end
    local height = 0.3
    local src = butPos[butCode]
    if src == nil then return nil end
    local pos = {src[1], height, src[2]}
    if rev then pos[3] = -1*pos[3] end
    if left then pos[1] = -1*pos[1] end
    return pos
end
--
function SpawnDropButtons()
    self.clearButtons()
    local drops = {{code='s1', pos=ButtonPos('s1')}}
    for drop in string.gmatch(self.getDescription(), "[^:]+") do
        if ButtonPos(drop) ~= nil then
            table.insert(drops, {code=drop, pos=ButtonPos(drop)})
        end
    end
    local labBut = {position={0, 0.3, 0}, width=1300, height=250, font_size=120, label='(choose drop template)', click_function = 'dummy'}
    self.createButton(labBut)
    local dBut = {width=350, height=350, function_owner=self, font_size=200}
    for k, dTable in pairs(drops) do
        dBut.position = dTable.pos
        dBut.label = dTable.code
        _G[dTable.code] = function() DropBomb(dTable.code) end
        dBut.click_function = dTable.code
        self.createButton(dBut)
    end
end

function DropBomb(code)
    assignedShip.setDescription('b:' .. code)
    SpawnFirstButtons()
end

function selfUnassign()
    assignedShip = nil
    self.clearButtons()
    self.setName(nameUnassigned)
end
function assignCallback(argTable)
    local ship = argTable.ship
    printToAll('Bomb drop token assigned to ' .. ship.getName(), {0.2, 0.2, 1})
    SpawnFirstButtons()
    assignedShip = ship
    self.setName(assignedShip.getName() .. nameAssigned)
end
function dummy() return end