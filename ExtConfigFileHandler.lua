--- A standalone module to handle reading and writing to ext_config.ini files for tracks and track layouts in Assetto Corsa.
local ExtConfigFileHandler = {}

---@enum ExtConfigFileHandler.ExtConfigFileTypes 
ExtConfigFileHandler.ExtConfigFileTypes ={
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\extension\ext_config.ini
    Track = 1,
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\touristenfahrten\extension\ext_config.ini
    TrackLayout = 2,
    --[====[
    -- E:\Games\Steam\steamapps\common\assettocorsa\extension\config\tracks\loaded\ks_nordschleife.ini
    TrackLoaded = 3
    --]====]
}

-- ExtConfigFileHandler.EXTENSION_PATH = '/extension/'
ExtConfigFileHandler.EXTENSION_PATH = '\\extension\\'
ExtConfigFileHandler.EXT_CONFIG_FILENAME = 'ext_config.ini'
ExtConfigFileHandler.EXT_CONFIG_RELATIVE_PATH = ExtConfigFileHandler.EXTENSION_PATH .. ExtConfigFileHandler.EXT_CONFIG_FILENAME

local trackFolder = ac.getFolder(ac.FolderID.CurrentTrack)
local trackLayoutFolder = ac.getFolder(ac.FolderID.CurrentTrackLayout)

---@type table<ExtConfigFileHandler.ExtConfigFileTypes, string> 
local availableDirectories = {
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\
    [ExtConfigFileHandler.ExtConfigFileTypes.Track] = trackFolder,
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\touristenfahrten\
    [ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout] = trackLayoutFolder,
}

---Returns the file directory for the specified ext_config.ini file type
---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
ExtConfigFileHandler.getFileDirectory = function (extConfigFileType)
    return availableDirectories[extConfigFileType]
end

---@type table<ExtConfigFileHandler.ExtConfigFileTypes, string> 
local availableFiles = {
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\extension\ext_config.ini
    [ExtConfigFileHandler.ExtConfigFileTypes.Track] = string.format('%s%s', availableDirectories[ExtConfigFileHandler.ExtConfigFileTypes.Track], ExtConfigFileHandler.EXT_CONFIG_RELATIVE_PATH),
    -- E:\Games\Steam\steamapps\common\assettocorsa\content\tracks\ks_nordschleife\touristenfahrten\extension\ext_config.ini
    [ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout] = string.format('%s%s', availableDirectories[ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout], ExtConfigFileHandler.EXT_CONFIG_RELATIVE_PATH),
}

-- Check if the track layout ext_config.ini file is the same as the track ext_config.ini file
-- This happens when the track only has a single layout and the layout folder is the same as the track folder
local isTrackLayoutFileSameAsTrackFile = availableFiles[ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout] == availableFiles[ExtConfigFileHandler.ExtConfigFileTypes.Track]

ExtConfigFileHandler.isTrackLayoutFileSameAsTrackFile = function ()
    return isTrackLayoutFileSameAsTrackFile
end

---Returns the file path for the specified ext_config.ini file type
---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
ExtConfigFileHandler.getFilePath = function (extConfigFileType)
    return availableFiles[extConfigFileType]
end

--[==[
ac.log('Track Folder: ' .. availableDirectories[ExtConfigFileHandler.ExtConfigFileTypes.Track])
ac.log('Track ext_config.ini file: ' .. availableFiles[ExtConfigFileHandler.ExtConfigFileTypes.Track])
ac.log()
ac.log('Track Layout Folder: ' .. availableDirectories[ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout])
ac.log('Track Layout ext_config.ini file: ' .. availableFiles[ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout])
--]==]

---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes @The type of ext_config.ini file to write to
---@param sectionName string @The section name prefix, e.g., "FLAME"
---@param setCallback fun(file: ac.INIConfig, fullSectionName: string) @A callback function that receives the INIConfig object and the full section name to set values in the new section
ExtConfigFileHandler.writeNewSectionToExtConfigFile = function (extConfigFileType, sectionName, setCallback)
    local extConfigFilePath = ExtConfigFileHandler.getFilePath(extConfigFileType)
    -- ac.log('Writing to ext_config.ini file at: ' .. extConfigFilePath)

    local sectionNameLength = string.len(sectionName)

    -- open the file for reading and writing
    local file = ac.INIConfig.load(extConfigFilePath, ac.INIFormat.Extended, nil)

    -- find the largest existing section name index for the given section prefix
    local largestSectionNameIndex = 0
    for index, section in file:iterate(sectionName) do -- example => index: 1, section: "FLAME_0"
        -- ac.log('FLAME section index: ' .. tostring(index))
        -- ac.log(string.format('%s section index %d: %s', sectionName, index, section))

        -- extract the numeric part from the section name by taking the substring after 'FLAME_' without using regexes
        -- local sectionNameSuffix = string.sub(section, 7) -- 'FLAME_' has 6 characters, so start from the 7th character
        local sectionNameSuffix = string.sub(section, sectionNameLength + 1 + 1) -- + 1 to move past the last character, + 1 more to start after the underscore
        -- ac.log(string.format('%s section name suffix: %s', sectionName, sectionNameSuffix))
        local sectionNameIndex = tonumber(sectionNameSuffix)
        if sectionNameIndex and sectionNameIndex > largestSectionNameIndex then
            largestSectionNameIndex = sectionNameIndex
        end
    end

    local nextSectionNameIndex = largestSectionNameIndex + 1
    local fullNextSectionName = string.format('%s_%d', sectionName, nextSectionNameIndex) -- e.g., "FLAME_2"

    setCallback(file, fullNextSectionName)

    -- save the modified file
    file:save(extConfigFilePath)
    ac.log(string.format('Saved ext_config.ini with new %s section at: %s', sectionName, extConfigFilePath))
end

---Open the specific ext_config file
---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
---@return boolean @True if opened successfully
ExtConfigFileHandler.openExtConfigFile = function (extConfigFileType)
    local extConfigFilePath = ExtConfigFileHandler.getFilePath(extConfigFileType)
    if not io.fileExists(extConfigFilePath) then
        ac.error(string.format('ext_config.ini file does not exist at path: %s', extConfigFilePath))
        return false
    end

    os.openTextFile(extConfigFilePath, 0)
    return true
end

---Open the specific ext_config file
---@param extConfigFileType ExtConfigFileHandler.ExtConfigFileTypes
---@return boolean @True if opened successfully
ExtConfigFileHandler.showExtConfigFileInExplorer = function (extConfigFileType)
    local extConfigFilePath = ExtConfigFileHandler.getFilePath(extConfigFileType)
    if not io.fileExists(extConfigFilePath) then
        ac.error(string.format('ext_config.ini file does not exist at path: %s', extConfigFilePath))
        return false
    end

    os.showInExplorer(extConfigFilePath)
    return true
end

return ExtConfigFileHandler