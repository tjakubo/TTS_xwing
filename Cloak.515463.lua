-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of Flolania
-- ~~~~~~

owner = nil

function onLoad(save_state)
    if save_state ~= '' and save_state ~= 'null' and save_state ~= nil then
        print(save_state)
        local ownerGUID = JSON.decode(save_state).ownerGUID
        if ownerGUID ~= nil then
            owner = getObjectFromGUID(ownerGUID)
        end
        SpawnFirstButtons()
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

function onSave()
    if owner ~= nil then
        local state = {ownerGUID=owner.getGUID()}
        return JSON.encode(state)
    end
end

function SpawnFirstButtons()
    local decloakButton = {['function_owner'] = self, ['click_function'] = 'SpawnDecloakButtons', ['label'] = 'Decloak', ['position'] = {0, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 900, ['height'] = 550, ['font_size'] = 250}
    self.createButton(decloakButton)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 900, ['height'] = 550, ['font_size'] = 250}
    self.createButton(deleteButton)
end

function onDropped()
    if owner == nil then
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
            printToAll('Cloak token assigned to ' .. nearest.getName(), {0.2, 0.2, 1})
            self.setRotation(nearest.getRotation())
            SpawnFirstButtons()
            owner = nearest
        end
    end
end

function SpawnFinalButtons()
    self.clearButtons()
    ClearButtonsPatch(self)
    local undoButton = {['function_owner'] = self , ['click_function'] = 'performUndo', ['label'] = 'Q', ['position'] = {0, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 900, ['height'] = 550, ['font_size'] = 250}
    self.createButton(undoButton)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 900, ['height'] = 550, ['font_size'] = 250}
    self.createButton(deleteButton)
end

function SpawnDecloakButtons()
    self.clearButtons()
    ClearButtonsPatch(self)
    local decloakStr_Button = {['function_owner'] = self,['click_function'] = 'decloakStraight', ['label'] = 'CS', ['position'] = {0, 1, -2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakStr_Button)
    local decloakLF_Button = {['function_owner'] = self,['click_function'] = 'decloakLF', ['label'] = 'CF', ['position'] = {-1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakLF_Button)
    local decloakL_Button = {['function_owner'] = self,['click_function'] = 'decloakL', ['label'] = 'CL', ['position'] = {-1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakL_Button)
    local decloakLB_Button = {['function_owner'] = self,['click_function'] = 'decloakLB', ['label'] = 'CB', ['position'] = {-1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakLB_Button)
    local decloakRF_Button = {['function_owner'] = self,['click_function'] = 'decloakRF', ['label'] = 'CF', ['position'] = {1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakRF_Button)
    local decloakR_Button = {['function_owner'] = self,['click_function'] = 'decloakR', ['label'] = 'CR', ['position'] = {1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakR_Button)
    local decloakRB_Button = {['function_owner'] = self,['click_function'] = 'decloakRB', ['label'] = 'CB', ['position'] = {1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
    self.createButton(decloakRB_Button)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
    self.createButton(deleteButton)
end

function decloakStraight()
    owner.setDescription('cs')
    SpawnFinalButtons()
end
function decloakRF()
    owner.setDescription('crf')
    SpawnFinalButtons()
end
function decloakR()
    owner.setDescription('cr')
    SpawnFinalButtons()
end
function decloakRB()
    owner.setDescription('crb')
    SpawnFinalButtons()
end
function decloakLF()
    owner.setDescription('cef')
    SpawnFinalButtons()
end
function decloakL()
    owner.setDescription('ce')
    SpawnFinalButtons()
end
function decloakLB()
    owner.setDescription('ceb')
    SpawnFinalButtons()
end
function selfDestruct()
    self.destruct()
end
function performUndo()
    owner.setDescription('q')
    SpawnDecloakButtons()
end