originPos = {}      -- position of the stack before laying out (left-bottom corner)
x_half = 0          -- which half of table X-axis-wise we play on (+1 or -1)
z_half = 0          -- which half of table Z-axis-wise we play on (+1 or -1)
kNum = 1            -- koiogran turn counter (for layout)

dialLuaScript = [[
function setShip(shipTable)
    assignedShip = shipTable[1]
end

function onPickedUp()
    if assignedShip ~= nil then Global.call('DialPickedUp', {dial=self, ship=assignedShip}) end
end

function onDropped()
    if assignedShip ~= nil then Global.call('DialDropped', {dial=self, ship=assignedShip}) end
end]]

-- SPAWN FLIP AND LAYOUT BUTTONS
function onLoad()
    self.unlock()
    local button = {}
    button.click_function = 'init'
    button.function_owner = self
    button.label = 'Lay out'
    button.position = {0, -0.5, 0}
    button.rotation = {180, 180, 0}
    button.width = 1500
    button.height = 500
    button.font_size = 300
    self.createButton(button)
    button.width = 1800
    button.click_function = 'selfFlip'
    button.label = 'Flip to start'
    button.rotation = {0, 0, 0}
    button.position = {0, 0.5, 0}
    self.createButton(button)
end

function selfFlip()
    local sRot = self.getRotation()
    self.setRotation({sRot['x']+180, sRot['y']+180, sRot['z']})
end

-- RETURN POSITION BASED ON:
-- -- DESCRIPTION (WHICH MOVE IT IS)
-- -- "TURN LEFT ZERO" POSITION, OFFSET
-- -- DIAL SPACING - DEPENDENT ON SCALE
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
    elseif desc:sub(-1,-1) == 'r' then
        type = desc:sub(1, 1)
        if desc:sub(2,2) == 'r' then
            dir = 'r'
        elseif desc:sub(2,2) == 'e' or desc:sub(2,2) == 'l' then
            dir = 'l'
        end
        speed = 0
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

    outPos = {x=0, y=0.1, z=0}
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

    if z_half == 1 then
        outPos['x'] = outPos['x'] * -1
        outPos['y'] = outPos['y'] * -1
        outPos['z'] = outPos['z'] * -1
    end


    outPos['x'] = outPos['x'] + te0pos['x'] - (2*dialSpacing*z_half)
    outPos['y'] = outPos['y'] + te0pos['y']
    outPos['z'] = outPos['z'] + te0pos['z']
    return outPos
end

function moveSpeed(desc)
    local speed = nil
    if desc:sub(-1, -1) == 's' then
        speed = tonumber(desc:sub(-2, -2))
    elseif desc:sub(-1, -1) == 't' then
        speed = tonumber(desc:sub(-2, -2))
    elseif desc:sub(-1,-1) == 'r' then
        speed = 0
    elseif desc:sub(1, 1) == 'k' then
        speed = tonumber(desc:sub(2, 2))
    elseif desc:sub(1, 1) == 's' then
        speed = tonumber(desc:sub(2, 2))
    else
        speed = tonumber(desc:sub(3, 3))
    end
    if speed == nil then print(desc) end
    return speed
end

function offset(table1, table2)
    return {table1[1]+table2[1], table1[2]+table2[2], table1[3]+table2[3]}
end

-- RETURN A ROTATION THAT IS NATURAL TO A PLAYER IN CERTAIN QUADRANT
-- FACEUP OR FACEDOWN
function correctQuadrantRotation(z_halfRot, faceup)
    if z_halfRot > 0 then
        if faceup == false then return {x=180, y=180, z=0}
        else return {x=0, y=0, z=0} end
    else
        if faceup == false then return {x=180, y=0, z=0}
        else return {x=0, y=180, z=0} end
    end
end

-- FUNCTION FOR DIAL ASSIGNMENT UPON LAYOUT
dialCount = #self.getObjects()-2
spawnedDials = {}
function assignCallback(obj, params)
    table.insert(spawnedDials, obj)
    if #spawnedDials == dialCount then
        if params.ship ~= nil then
            Global.call('DialAPI_AssignSet', {set=spawnedDials, ship=params.ship})
        end
        if params.callbackObj ~= nil then
            params.callbackObj.call(params.callbackFun, params.callbackParams)
        end
    end
end

-- LAY OUT DIALS, CALL ASSIGN IF NECCESARY, DESTROY SELF
function init(arg)
    local callbackTable = {}
    if type(arg) == 'table' then callbackTable = arg end
    self.setRotation(offset(self.getRotation(), {180, 180, 0}))
    if(self.getPosition()[1] < 0) then x_half = -1 else x_half = 1 end
    if(self.getPosition()[3] < 0) then z_half = -1 else z_half = 1 end
    local dialSpacing = (2/0.625)*(self.getScale()[1])
    self.setRotation(correctQuadrantRotation(z_half, false))
    local te0pos = self.getPosition()
    originPos = te0pos
    local stackDials = self.getObjects()
    local minSpeed = 5
    for k,dial in pairs(stackDials) do
        if dial.description ~= 'spec' and moveSpeed(dial.description) < minSpeed then
            minSpeed = moveSpeed(dial.description)
        end
    end
    te0pos = {x=te0pos[1], y=te0pos[2], z=(te0pos[3] + (minSpeed*dialSpacing*z_half)/2)}
    local dialNum = 0
    for k, dial in pairs(stackDials) do
        if dial['description'] ~= 'spec' then
            local dialPos = decodePos(dial['description'], te0pos, dialSpacing)
            newDial = self.takeObject({ position=dialPos, rotation=correctQuadrantRotation(z_half, true), guid=dial['guid'],
                                        callback='assignCallback', callback_owner=self, params={ship=callbackTable.ship,
                                        cb=callbackTable.callbackFun, cbArgs=callbackTable.callbackParams, cbObj=callbackTable.callbackObj}})
            newDial.setPosition(dialPos)
            newDial.setRotation(correctQuadrantRotation(z_half, true))
            newDial.setLuaScript(dialLuaScript)
        end
    end
    self.destruct()
    return spawnedDials
end