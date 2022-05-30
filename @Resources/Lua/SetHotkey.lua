function Set(hotkey, useWin, useSpace)
    if hotkey ~= nil then
        local SecNum = SKIN:GetVariable('Sec.Num')
        if useSpace == 1 then
            hotkey = hotkey:gsub('.$', '')
            hotkey = hotkey .. 'Space'
        end
        if useWin == 1 then
            hotkey = '#' .. hotkey
            print(hotkey)
        end
        local matchArray = { '%#', '%!', '%^', '%+' }
        local replaceArray = { 'Win ', 'Alt ', 'Ctrl ', 'Shift ' }
        local hotkeyString = hotkey
        for i = 1, 4 do
            hotkeyString = hotkeyString:gsub(matchArray[i], replaceArray[i])
        end
        hotkeyString = hotkeyString:gsub('%s.$', ' '..hotkeyString:sub(-1):upper())
        local saveLocation = [[#SKINSPATH##Skin.Name#\@Resources\Actions\HotKeys.ini]]
        SKIN:Bang('[!WriteKeyvalue Variables Key' .. SecNum .. ' "' .. hotkey .. '" "' .. saveLocation .. '"][!WriteKeyvalue Variables Key' .. SecNum .. 'InString "' .. hotkeyString .. '" "' .. saveLocation .. '"][!UpdateMeasure Auto_Refresh:M "#JaxCore\\Main"][!Refresh "#JaxCore\\Main"]')
    end
    SKIN:Bang('[!DeactivateConfig]')
end

function Start()
    local bang = ''
    local winbool = 0
    local spacebool = 0
    local currentKey = SKIN:ReplaceVariables('[#Key[#Sec.Num]]')
    if currentKey:find('#') then
        currentKey = currentKey:gsub('#', '')
        winbool = 1
    end
    if currentKey:find('Space') then
        currentKey = currentKey:gsub('Space', '')
        spacebool = 1
    end
    local saveLocation = [[#@#Actions\\AHKCacheVariables.inc]]
    bang = bang .. '[!WriteKeyvalue Variables CurrentKey "' .. currentKey .. '" "' .. saveLocation .. '"]'
    bang = bang .. '[!WriteKeyvalue Variables WinBool "' .. winbool .. '" "' .. saveLocation .. '"]'
    bang = bang .. '[!WriteKeyvalue Variables SpaceBool "' .. spacebool .. '" "' .. saveLocation .. '"]'
    bang = bang .. '[!WriteKeyvalue Variables RMPATH "#PROGRAMPATH#Rainmeter.exe" "' .. saveLocation .. '"]'
    bang = bang .. '[!WriteKeyvalue Variables Config "#CURRENTCONFIG#" "' .. saveLocation .. '"]'
    bang = bang .. '["#@#Actions\\AHKv1.exe" "#@#Actions\\Hotkey.AHK"]'
    SKIN:Bang(bang)
end
