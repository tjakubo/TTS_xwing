-- ~~~~~~
-- Script by dzikakulka
-- Issues, history at: https://github.com/tjakubo2/TTS_xwing
--
-- Based on a work of: Indimeco
-- Original mod: http://steamcommunity.com/sharedfiles/filedetails/?id=701636321
-- This is a general refit for event-logging notecards
-- ~~~~~~

LogContainer = {}

-- ~~~~~~
-- COFIGURATION:

-- How many lines is avaialable for events text
displayLinesAvailable = 8

-- Tag for this log, not used in this script (useful for outside identification)
idTag = 'XW'

-- How many lines should pass when you click the fast skip button (inner, marked '<<')
fastSkipLines = 3

-- Starting line offset (0 displaying is from latest message back)
currentOffset = 0

-- Different group ID messages separator and color (keep this 1 line long please):
LogContainer.IDseparatorText = ' --  --  --  -- '
LogContainer.IDseparatorColor = {0.3, 0.3, 0.3}

-- ~~~~~~


function API_AddNewMessage(msgTable)
    if currentOffset > 0 then
        LogContainer.NotifyON = true
        LogContainer.RenderView(currentOffset)
        currentOffset = currentOffset + 1
    end
    LogContainer.AddMessage(msgTable.text, msgTable.color, msgTable.groupID)
    if currentOffset == 0 then LogContainer.RenderView(currentOffset) end
end

function API_Render(offset)
    currentOffset = LogContainer.RenderView(currentOffset + offset[1])
end

LogContainer.NotifyON = false
LogContainer.lastID = nil
LogContainer.Lines = {}

LogContainer.AddMessage = function(text, color, groupID)
    if LogContainer.lastID ~= nil and LogContainer.lastID ~= groupID then
        table.insert(LogContainer.Lines, LogHandle.ColorMessage(LogContainer.IDseparatorText, LogContainer.IDseparatorColor))
    end
    LogContainer.lastID = groupID
    local lines = LogHandle.Dissect(text)
    for k,line in pairs(lines) do
        table.insert(LogContainer.Lines, LogHandle.ColorMessage(line, color))
    end
end

LogContainer.RenderView = function(backOffset)
    if backOffset == 0 then LogContainer.NotifyON = false end
    if LogContainer.Lines[1] == nil then return end
    local desc = ''
    local kLast = #LogContainer.Lines - backOffset
    if kLast > #LogContainer.Lines then kLast = #LogContainer.Lines end
    if kLast < 1 then kLast = 1 end
    local kFirst = kLast - (displayLinesAvailable - 1)
    local displayLines = 0
    if kFirst < 1 then
        while kLast < #LogContainer.Lines and kFirst < 1 do
            kFirst = kFirst + 1
            kLast = kLast + 1
        end
    end
    displayLines = (kLast - kFirst) + 1
    while kLast < #LogContainer.Lines and displayLines < displayLinesAvailable do
        kLast = kLast + 1
        displayLines = displayLines + 1
    end
    while kFirst < 1 do
        kFirst = kFirst + 1
        displayLines = displayLines - 1
    end
    local prefix = ''
    local suffix = ''
    if kFirst == 1 then
        prefix = '(no older messages)\n'
    else
        prefix = '/\\   /\\   /\\\n'
    end
    if kLast == #LogContainer.Lines then
        suffix = '(no newer messages)'
    else
        suffix = '\\/   \\/   \\/'
    end
    prefix = LogHandle.ColorMessage(prefix, {0.2, 0.2, 0.2})
    if LogContainer.NotifyON == true then
        suffix = LogHandle.ColorMessage('[THERE ARE NEW UNREAD MESSAGES]', {1, 0, 0})
    else
        suffix = LogHandle.ColorMessage(suffix, {0.2, 0.2, 0.2})
    end

    desc = prefix .. desc
    for k=kFirst,kLast,1 do
        desc = desc .. LogContainer.Lines[k] .. '\n'
    end
    for k=displayLines,(displayLinesAvailable-1),1 do
        desc = desc .. '\n'
    end
    desc = desc .. suffix
    self.setDescription(desc)
    return #LogContainer.Lines - kLast
end

LogHandle = {}
LogHandle.characterWidthTable = {
['`'] = 2381, ['~'] = 2381, ['1'] = 1724, ['!'] = 1493, ['2'] = 2381,
['@'] = 4348, ['3'] = 2381, ['#'] = 3030, ['4'] = 2564, ['$'] = 2381,
['5'] = 2381, ['%'] = 3846, ['6'] = 2564, ['^'] = 2564, ['7'] = 2174,
['&'] = 2777, ['8'] = 2564, ['*'] = 2174, ['9'] = 2564, ['('] = 1724,
['0'] = 2564, [')'] = 1724, ['-'] = 1724, ['_'] = 2381, ['='] = 2381,
['+'] = 2381, ['q'] = 2564, ['Q'] = 3226, ['w'] = 3704, ['W'] = 4167,
['e'] = 2174, ['E'] = 2381, ['r'] = 1724, ['R'] = 2777, ['t'] = 1724,
['T'] = 2381, ['y'] = 2564, ['Y'] = 2564, ['u'] = 2564, ['U'] = 3030,
['i'] = 1282, ['I'] = 1282, ['o'] = 2381, ['O'] = 3226, ['p'] = 2564,
['P'] = 2564, ['['] = 1724, ['{'] = 1724, [']'] = 1724, ['}'] = 1724,
['|'] = 1493, ['\\'] = 1923, ['a'] = 2564, ['A'] = 2777, ['s'] = 1923,
['S'] = 2381, ['d'] = 2564, ['D'] = 3030, ['f'] = 1724, ['F'] = 2381,
['g'] = 2564, ['G'] = 2777, ['h'] = 2564, ['H'] = 3030, ['j'] = 1075,
['J'] = 1282, ['k'] = 2381, ['K'] = 2777, ['l'] = 1282, ['L'] = 2174,
[';'] = 1282, [':'] = 1282, ['\''] = 855, ['"'] = 1724, ['z'] = 1923,
['Z'] = 2564, ['x'] = 2381, ['X'] = 2777, ['c'] = 1923, ['C'] = 2564,
['v'] = 2564, ['V'] = 2777, ['b'] = 2564, ['B'] = 2564, ['n'] = 2564,
['N'] = 3226, ['m'] = 3846, ['M'] = 3846, [','] = 1282, ['<'] = 2174,
['.'] = 1282, ['>'] = 2174, ['/'] = 1923, ['?'] = 2174, [' '] = 1282,
['\t'] = 5128, ['\r'] = 0, ['\n'] = 100000
}
LogHandle.fullLineWidth = LogHandle.characterWidthTable['\n']

LogHandle.WordWidth = function(word)
    local length = string.len(word)
    local widthCount = 0
    for i=1,length,1 do
        if LogHandle.characterWidthTable[word:sub(i,i)] ~= nil then
            widthCount=widthCount+LogHandle.characterWidthTable[word:sub(i,i)]
        else
            print('unhandled char: ' .. word:sub(i,i))
        end
    end
    return widthCount
end

LogHandle.Dissect = function(text)
    local words = {}
    for word in text:gmatch("%S+") do table.insert(words, word) end

    local lines = {}
    local line = ''
    local widthCount = 0
    for k,word in pairs(words) do
        if k ~= #words then word = word .. ' ' end
        local newWidthCount = widthCount + LogHandle.WordWidth(word)
        if newWidthCount > LogHandle.fullLineWidth then
            table.insert(lines, line)
            line = word
            widthCount = 0
        else
            line = line .. word
            widthCount = widthCount + LogHandle.WordWidth(word)
        end
    end
    if line ~= '' then table.insert(lines, line) end
    return lines
end

LogHandle.LineCount = function(text)
    local words = {}
    for word in text:gmatch("%S+") do table.insert(words, word) end

    local lineCount = 0
    local fractLineCount = 0

    for k,word in pairs(words) do
        if words[k+1] ~= nil then word = word .. ' ' end
        local widthCount = 0
        local length = string.len(word)
        for i=1,length,1 do
            if LogHandle.characterWidthTable[word:sub(i,i)] ~= nil then
                widthCount=widthCount+LogHandle.characterWidthTable[word:sub(i,i)]
            else
                print('unhandled char: ' .. word:sub(i,i))
            end
        end
        local wordLineCount = widthCount/LogHandle.characterWidthTable['\n']
        if (fractLineCount + wordLineCount) > 1 then
            lineCount = lineCount+1
            fractLineCount = 0
        end
        fractLineCount = fractLineCount + wordLineCount
        while fractLineCount > 1 do
            lineCount = lineCount+1
            fractLineCount = fractLineCount-1
        end
    end
    return lineCount + fractLineCount
end

LogHandle.RGBTableToBB = function(RGBTable)
    local Rpart = string.format('%x', RGBTable[1]*255)
    if string.len(Rpart) == 1 then Rpart = '0' .. Rpart end
    local Gpart = string.format('%x', RGBTable[2]*255)
    if string.len(Gpart) == 1 then Gpart = '0' .. Gpart end
    local Bpart = string.format('%x', RGBTable[3]*255)
    if string.len(Bpart) == 1 then Bpart = '0' .. Bpart end
    return Rpart .. Gpart .. Bpart
end

LogHandle.ColorMessage = function(message, RGBTable)
    return '[' .. LogHandle.RGBTableToBB(RGBTable) .. ']' .. message .. '[-]'
end

function onDropped()
    local x_half = self.getPosition()[1]/math.abs(self.getPosition()[1])
    self.setName(Global.call('EventLogDropped', {self, x_half}))
    self.setDescription('')
end

XW_welcomeMess = [[
This is a event log card designed for X-Wing.

Pick me up to initialize and start writing notification messages here.

Once there are at least two initialized event logs on a table side, notifications will no longer appear in chat window (chat for chatting!).

]]

function onLoad()
    self.tooltip = false
    idTag = 'XW'
    self.setName('Event Log (inactive)')
    self.setDescription(XW_welcomeMess)
    local scrollDownOneBut = {click_function='scrollDownOne', function_owner=self, label='', position={-0.38,0,-0.35}, rotation={0,90,0}, width=1, height=1, font_size=1}
    self.createButton(scrollDownOneBut)
    local scrollDownOneLabel = {click_function='dummy', function_owner=self, label='<', position={-0.46,5,-0.45}, rotation={0,90,0}, width=0, height=0, font_size=70}
    self.createButton(scrollDownOneLabel)
    local scrollUpOneBut = {click_function='scrollUpOne', function_owner=self, label='', position={-0.38,0,0.35}, rotation={0,-90,0}, width=1, height=1, font_size=1}
    self.createButton(scrollUpOneBut)
    local scrollUpOneLabel = {click_function='dummy', function_owner=self, label='<', position={-0.46,5,0.45}, rotation={0,-90,0}, width=0, height=0, font_size=70}
    self.createButton(scrollUpOneLabel)

    local scrollDownMoreBut = {click_function='scrollDownMore', function_owner=self, label='', position={-0.38,0,-0.1}, rotation={0,90,0}, width=1, height=1, font_size=1}
    self.createButton(scrollDownMoreBut)
    local scrollDownMoreLabel = {click_function='dummy', function_owner=self, label='<<', position={-0.46,5,-0.2}, rotation={0,90,0}, width=0, height=0, font_size=70}
    self.createButton(scrollDownMoreLabel)
    local scrollUpMoreBut = {click_function='scrollUpMore', function_owner=self, label='', position={-0.38,0,0.1}, rotation={0,-90,0}, width=1, height=1, font_size=1}
    self.createButton(scrollUpMoreBut)
    local scrollUpMoreLabel = {click_function='dummy', function_owner=self, label='<<', position={-0.46,5,0.2}, rotation={0,-90,0}, width=0, height=0, font_size=70}
    self.createButton(scrollUpMoreLabel)
end

function scrollUpOne()
    API_Render({1})
end
function scrollDownOne()
    API_Render({-1})
end

function scrollUpMore()
    API_Render({fastSkipLines})
end
function scrollDownMore()
    API_Render({-1*fastSkipLines})
end

function dummy() end