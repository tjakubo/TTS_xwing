-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of Flolania
-- ~~~~~~

assignedShip = nil
idle = true

function onLoad(save_state)
    if save_state ~= '' and save_state ~= 'null' and save_state ~= nil then
        print(save_state)
        local assignedShipGUID = JSON.decode(save_state).assignedShipGUID
        if assignedShipGUID ~= nil and getObjectFromGUID(assignedShipGUID) ~= nil then
            assignedShip = getObjectFromGUID(assignedShipGUID)
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
    if assignedShip ~= nil then
        local state = {assignedShipGUID=assignedShip.getGUID()}
        return JSON.encode(state)
    end
end

function SpawnFirstButtons()
    idle = true
    self.clearButtons()
    local decloakButton = {['function_owner'] = self, ['click_function'] = 'SpawnDecloakButtons', ['label'] = 'Decloak', ['position'] = {0, 0.25, -1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 500, ['font_size'] = 250}
    self.createButton(decloakButton)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 0.25, 1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 500, ['font_size'] = 250}
    self.createButton(deleteButton)
end

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
            printToAll('Cloak token assigned to ' .. nearest.getName(), {0.2, 0.2, 1})
            self.setRotation(nearest.getRotation())
            SpawnFirstButtons()
            assignedShip = nearest
        end
    end
end

function SpawnFinalButtons()
    undoToBackCount = 1
    self.clearButtons()
    ClearButtonsPatch(self)
    local undoButton = {['function_owner'] = self , ['click_function'] = 'performUndo', ['label'] = 'Undo', ['position'] = {0, 0.25, -1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 500, ['font_size'] = 250}
    self.createButton(undoButton)
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 0.25, 1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 500, ['font_size'] = 250}
    self.createButton(deleteButton)
    local slideButton = {['function_owner'] = self , ['click_function'] = 'callSlide', ['label'] = 'Slide', ['position'] = {3, 0.25, 0}, ['rotation'] =  {0, 90, 0}, ['width'] = 2000, ['height'] = 400, ['font_size'] = 250}
    self.createButton(slideButton)
end

function SpawnDecloakButtons()
    idle = false
    self.clearButtons()
    ClearButtonsPatch(self)
    if assignedShip.getName() ~= 'Echo' then
        local decloakStr_Button = {['function_owner'] = self,['click_function'] = 'decloakStraight', ['label'] = 'CS', ['position'] = {0, 0.25, -2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakStr_Button)
        local decloakLF_Button = {['function_owner'] = self,['click_function'] = 'decloakLF', ['label'] = 'CF', ['position'] = {-1.5, 0.25, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakLF_Button)
        local decloakL_Button = {['function_owner'] = self,['click_function'] = 'decloakL', ['label'] = 'CL', ['position'] = {-1.5, 0.25, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakL_Button)
        local decloakLB_Button = {['function_owner'] = self,['click_function'] = 'decloakLB', ['label'] = 'CB', ['position'] = {-1.5, 0.25, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakLB_Button)
        local decloakRF_Button = {['function_owner'] = self,['click_function'] = 'decloakRF', ['label'] = 'CF', ['position'] = {1.5, 0.25, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakRF_Button)
        local decloakR_Button = {['function_owner'] = self,['click_function'] = 'decloakR', ['label'] = 'CR', ['position'] = {1.5, 0.25, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakR_Button)
        local decloakRB_Button = {['function_owner'] = self,['click_function'] = 'decloakRB', ['label'] = 'CB', ['position'] = {1.5, 0.25, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakRB_Button)
    else
        local decloakStrR_Button = {['function_owner'] = self,['click_function'] = 'dechocloakStraightR', ['label'] = 'CR', ['position'] = {0.5, 0.25, -2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakStrR_Button)
        local decloakStrL_Button = {['function_owner'] = self,['click_function'] = 'dechocloakStraightL', ['label'] = 'CL', ['position'] = {-0.5, 0.25, -2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakStrL_Button)
        local decloakLF_Button = {['function_owner'] = self,['click_function'] = 'dechocloakLF', ['label'] = 'CF', ['position'] = {-1.5, 0.25, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakLF_Button)
        local decloakLB_Button = {['function_owner'] = self,['click_function'] = 'dechocloakLB', ['label'] = 'CB', ['position'] = {-1.5, 0.25, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakLB_Button)
        local decloakRF_Button = {['function_owner'] = self,['click_function'] = 'dechocloakRF', ['label'] = 'CF', ['position'] = {1.5, 0.25, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakRF_Button)
        local decloakRB_Button = {['function_owner'] = self,['click_function'] = 'dechocloakRB', ['label'] = 'CB', ['position'] = {1.5, 0.25, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 520, ['font_size'] = 250}
        self.createButton(decloakRB_Button)
    end
    local deleteButton = {['function_owner'] = self , ['click_function'] = 'selfDestruct', ['label'] = 'Delete', ['position'] = {0, 0.25, 2}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 500, ['font_size'] = 250}
    self.createButton(deleteButton)
    local backButton = {['function_owner'] = self , ['click_function'] = 'resetToFirst', ['label'] = 'Back', ['position'] = {0, 0.25, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 500, ['font_size'] = 250}
    self.createButton(backButton)
end

function decloakStraight()
    if Global.call('API_PerformMove', {code='cs', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakRF()
    if Global.call('API_PerformMove', {code='crf', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakR()
    if Global.call('API_PerformMove', {code='cr', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakRB()
    if Global.call('API_PerformMove', {code='crb', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakLF()
    if Global.call('API_PerformMove', {code='cef', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakL()
    if Global.call('API_PerformMove', {code='ce', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function decloakLB()
    if Global.call('API_PerformMove', {code='ceb', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakStraightR()
    if Global.call('API_PerformMove', {code='chsr', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakStraightL()
    if Global.call('API_PerformMove', {code='chse', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakRF()
    if Global.call('API_PerformMove', {code='chrf', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakRB()
    if Global.call('API_PerformMove', {code='chrb', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakLF()
    if Global.call('API_PerformMove', {code='chef', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function dechocloakLB()
    if Global.call('API_PerformMove', {code='cheb', ship=assignedShip}) then
        SpawnFinalButtons()
    end
end
function selfDestruct()
    self.destruct()
end
function resetToFirst()
    SpawnFirstButtons()
end
function performUndo()
    assignedShip.setDescription('q')
    undoToBackCount = undoToBackCount - 1
    if undoToBackCount <= 0 then
        SpawnDecloakButtons()
    end
end
function callSlide(obj, playerColor)
    local started = Global.call('API_StartSlide', {obj=obj, playerColor=playerColor})
    if started then
        undoToBackCount = undoToBackCount + 1
    end
end