-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
-- ~~~~~~

set = false     -- Was this lock tinted and named already?

-- Colors for tinting on pickup
colorTable = {}
colorTable['Red']= {1, 0, 0}
colorTable['Brown']= {0.6, 0.4, 0}
colorTable['White']= {1, 1, 1}
colorTable['Pink']= {1, 0.4, 0.8}
colorTable['Purple']= {0.8, 0, 0.8}
colorTable['Blue']= {0, 0, 1}
colorTable['Teal']= {0.2, 1, 0.8}
colorTable['Green']= {0, 1, 0}
colorTable['Yellow']= {1, 1, 0}
colorTable['Orange']= {1, 0.4, 0}
colorTable['Black']= {0, 0, 0}

-- Save self state
function onSave()
    if set  then
        local state = {set=set}
        return JSON.encode(state)
    end
end

-- Restore self state
function onLoad(save_state)
    if save_state ~= '' and save_state ~= 'null' and save_state ~= nil then
        set = JSON.decode(save_state).set
    end
end

-- Set function for external calls
function manualSet(color_name)
    set = true
    self.setColorTint(colorTable[color_name[1]])
    self.setName(color_name[2])
end

-- Tint on pick up
function onPickedUp()
    if not set and self.held_by_color ~= nil then
      self.setColorTint(colorTable[self.held_by_color])
    end
end

-- Set name on drop near a ship
function onDropped()
    if not set then
        local spos = self.getPosition()
        local spos = self.getPosition()
        local nearest = nil
        local minDist = 5
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
            self.setName(nearest.getName())
            printToAll('Target lock named for ' .. nearest.getName(), {0.2, 0.2, 1})
            set = true
        end
    end
end