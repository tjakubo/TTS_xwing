local dropped = false

function onDropped(player_color)
    dropped = true
end

-- Return key with minimum element from the table
function minimum(inTable)
    local minKey = nil
    for k,v in pairs(inTable) do
        if minKey == nil then
            minKey = k
        else
            if v < inTable[minKey] then
                minKey = k
            end
        end
    end
    return minKey
end

-- When colliding with a Lancer-Class Pursuit craft, set position to its center
--  and rotation to nearest 90 deg point
-- Only after being manually dropped
function onCollisionEnter(collision_info)
    local body = collision_info.collision_object
    if body.tag ~= 'Figurine' or dropped ~= true then return end
    local type = Global.call('DB_getShipTypeCallable', {body})
    if type == 'Lancer-Class Pursuit Craft' then
        local sPos = body.getPosition()
        self.setPositionSmooth({sPos[1], sPos[2]+0.3, sPos[3]})
        local relRot = body.getRotation()[2] - self.getRotation()[2]
        local rotTable = {}
        rotTable['0'] = math.abs(relRot)
        rotTable['-90'] = math.abs(relRot - 90)
        rotTable['-180'] = math.abs(relRot - 180)
        rotTable['180'] = math.abs(relRot + 180)
        rotTable['90'] = math.abs(relRot + 90)
        local evenRot = tonumber(minimum(rotTable))
        self.setRotationSmooth({0, body.getRotation()[2]+evenRot, 0})
        dropped = false
    end
end