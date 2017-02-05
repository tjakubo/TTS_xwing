-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: http://github.com/tjakubo2/TTS_xwing
-- ~~~~~~

-- TO ADD NEW IMAGES TO THE SET
-- Just add their links to the table below in the same fashion
-- (comma after the currrent last one and your link enclosed in apostrophes following)

-- Table of all images to be cycled through with NextImage()
imageSet = {'http://i.imgur.com/6IkNucB.jpg',
            'http://i.imgur.com/dczrasC.jpg',
            'http://i.imgur.com/YdIAcvP.png',
            'http://i.imgur.com/5CcjDzM.jpg',
            'http://i.imgur.com/4WMSCSV.jpg',
            'http://i.imgur.com/0FWrq21.jpg',
            'http://i.imgur.com/x4LEk1A.jpg',
            'http://i.imgur.com/fy6kooO.png'}

-- {Postions, Scale} data for mat object of each type
matData = {}
matData['Custom_Board'] = {{-20.5142, -0.17, 0}, {1.225, 1.2, 1.225}}
matData['Custom_Tile'] = {{-20.5142, 0.85, 0}, {16.28, 0, 16.28}}

function onload()
    self.lock()
    self.setPosition(matData[SelfType()][1])
    self.setScale(matData[SelfType()][2])
    self.setRotation({0, 180, 0})
    self.interactable = false
end

-- Only differentiates between Csutom_Tile and Custom_Board
function SelfType()
    if self.getCustomObject().thickness ~= nil then
        return 'Custom_Tile'
    else
        return 'Custom_Board'
    end
end

-- Respawn self (with same image)
-- if typeChange is TRUE, change type Tile <-> Board
function Respawn(typeChange)

    local newType = SelfType()
    if typeChange == true and SelfType() == 'Custom_Tile' then
        newType = 'Custom_Board'
    elseif typeChange == true then
        newType = 'Custom_Tile'
    end

    local newMatProperties = {}
    newMatProperties.type = newType
    newMatProperties.position = matData[newType][1]
    newMatProperties.rotation = self.getRotation()
    newMatProperties.scale = matData[newType][2]
    newMat = spawnObject(newMatProperties)
    newMat.setLuaScript(self.getLuaScript())

    local currentImageNum = 1
    if self.getVar('ImageNum') ~= nil then currentImageNum = self.getVar('ImageNum') end

    local customMatParams = {}
    customMatParams.image = imageSet[currentImageNum]
    if newType == 'Custom_Tile' then
        customMatParams.type = 0
        customMatParams.thickness = 0.1
    end
    newMat.setCustomObject(customMatParams)
    newMat.setVar('ImageNum', currentImageNum)
    newMat.setName(self.getName())
    self.destruct()
end

function ChangeType()
    Respawn(true)
end

-- Change image to the next from the list
-- Image numbers wrap around
-- RESPAWNS MAT OBJECT (neccesary to actually render with new image)
function NextImage()
    local currentImageNum = 1
    if self.getVar('ImageNum') ~= nil then currentImageNum = self.getVar('ImageNum') end

    if imageSet[currentImageNum + 1] ~= nil then
        currentImageNum = currentImageNum + 1
    else
        currentImageNum = 1
    end

    self.setVar('ImageNum', currentImageNum)

    Respawn(false)
end