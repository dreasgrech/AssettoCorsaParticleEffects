---@enum ParticleEffectsType
ParticleEffectsType = {
    Flame = 1,
    Smoke = 2,
    Sparks = 3,
}

StringBuilder = require('StringBuilder')
StorageManager = require('StorageManager')
UIOperations = require('UIOperations')
MathOperations = require('MathOperations')
ParticleEffectsManager = require('ParticleEffectsManager')
ExtConfigDefinitions = require('ExtConfigDefinitions')
ExtConfigCodeGenerator = require('ExtConfigCodeGenerator')
ExtConfigFileHandler = require('ExtConfigFileHandler')
ParticleEffectsExtConfigFileHandler = require("ParticleEffectsExtConfigFileHandler")

-- local bindings
local ac = ac
local ac_getSim = ac.getSim
local ui = ui
local ui_columns = ui.columns
local ui_setColumnWidth = ui.setColumnWidth
local ui_dwriteText = ui.dwriteText
local ui_sameLine = ui.sameLine
local ui_pushID = ui.pushID
local ui_popID = ui.popID
local ui_text = ui.text
local ui_nextColumn = ui.nextColumn
local ui_button = ui.button
local string_format = string.format
local UIOperations_newLine = UIOperations.newLine
local UIOperations_renderButton = UIOperations.renderButton


local UI_HEADER_TEXT_FONT_SIZE = 15
local DEFAULT_SLIDER_WIDTH = 200
local DEFAULT_SLIDER_FORMAT = '%.2f'

--[======[
---Flame emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit flames.
---@param params {color: rgbm, size: number, temperatureMultiplier: number, flameIntensity: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), size = 0.2, temperatureMultiplier = 1, flameIntensity = 0}` "Table with properties:\n- `color` (`rgbm`): Flame color multiplier (for red/yellow/blue adjustment use `temperatureMultiplier` instead).\n- `size` (`number`): Particles size. Default value: 0.2.\n- `temperatureMultiplier` (`number`): Temperature multipler to vary base color from red to blue. Default value: 1.\n- `flameIntensity` (`number`): Flame intensity affecting flame look and behaviour. Default value: 0."
---@return ac.Particles.Flame
function ac.Particles.Flame(params) end



---Sparks emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit sparks.
---@param params {color: rgbm, life: number, size: number, directionSpread: number, positionSpread: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), life = 4, size = 0.2, directionSpread = 1, positionSpread = 0.2}` "Table with properties:\n- `color` (`rgbm`): Sparks color.\n- `life` (`number`): Base lifetime. Default value: 4.\n- `size` (`number`): Base size. Default value: 0.2.\n- `directionSpread` (`number`): How much sparks directions vary. Default value: 1.\n- `positionSpread` (`number`): How much sparks position vary. Default value: 0.2."
---@return ac.Particles.Sparks
function ac.Particles.Sparks(params) end



---Smoke flags for emitters.
ac.Particles.SmokeFlags = { FadeIn = 1, DisableCollisions = 256 }

---Smoke emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit smoke.
---@param params {color: rgbm, colorConsistency: number, thickness: number, life: number, size: number, spreadK: number, growK: number, targetYVelocity: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), colorConsistency = 0.5, thickness = 1, life = 4, size = 0.2, spreadK = 1, growK = 1, targetYVelocity = 0}` "Table with properties:\n- `color` (`rgbm`): Smoke color with values from 0 to 1. Alpha can be used to adjust thickness. Default alpha value: 0.5.\n- `colorConsistency` (`number`): Defines how much color dissipates when smoke expands, from 0 to 1. Default value: 0.5.\n- `thickness` (`number`): How thick is smoke, from 0 to 1. Default value: 1.\n- `life` (`number`): Smoke base lifespan in seconds. Default value: 4.\n- `size` (`number`): Starting particle size in meters. Default value: 0.2.\n- `spreadK` (`number`): How randomized is smoke spawn (mostly, speed and direction). Default value: 1.\n- `growK` (`number`): How fast smoke expands. Default value: 1.\n- `targetYVelocity` (`number`): Neutral vertical velocity. Set above zero for hot gasses and below zero for cold, to collect at the bottom. Default value: 0."
---@return ac.Particles.Smoke
function ac.Particles.Smoke(params) end
--]======]

local storage = StorageManager.getStorage()

---@type ui.ColorPickerFlags
local colorPickerFlags = bit.bor(
  ui.ColorPickerFlags.PickerHueWheel
)
local colorPickerSize = vec2(DEFAULT_SLIDER_WIDTH, 20)

---@type FlameEffectWrapper
local flameInstance = ParticleEffectsManager.generateParticleEffect(ParticleEffectsType.Flame)
flameInstance.enabled = storage.flame_enabled
flameInstance.position = storage.flame_position
flameInstance.positionOffset = storage.flame_positionOffset
flameInstance.velocity = storage.flame_velocity
flameInstance.amount = storage.flame_amount
local flame = flameInstance.effect
flame.color = storage.flame_color
flame.size = storage.flame_size
flame.temperatureMultiplier = storage.flame_temperatureMultiplier
flame.flameIntensity = storage.flame_flameIntensity

---@type SparksEffectWrapper
local sparksInstance = ParticleEffectsManager.generateParticleEffect(ParticleEffectsType.Sparks)
sparksInstance.enabled = storage.sparks_enabled
sparksInstance.position = storage.sparks_position
sparksInstance.positionOffset = storage.sparks_positionOffset
sparksInstance.velocity = storage.sparks_velocity
sparksInstance.amount = storage.sparks_amount
local sparks = sparksInstance.effect
sparks.color = storage.sparks_color
sparks.size = storage.sparks_size
sparks.life = storage.sparks_life
sparks.directionSpread = storage.sparks_directionSpread
sparks.positionSpread = storage.sparks_positionSpread

---@type SmokeEffectWrapper
local smokeInstance = ParticleEffectsManager.generateParticleEffect(ParticleEffectsType.Smoke)
smokeInstance.enabled = storage.smoke_enabled
smokeInstance.position = storage.smoke_position
smokeInstance.positionOffset = storage.smoke_positionOffset
smokeInstance.velocity = storage.smoke_velocity
smokeInstance.amount = storage.smoke_amount
local smoke = smokeInstance.effect
smoke.color = storage.smoke_color
smoke.size = storage.smoke_size
smoke.colorConsistency = storage.smoke_colorConsistency
smoke.thickness = storage.smoke_thickness
smoke.life = storage.smoke_life
smoke.spreadK = storage.smoke_spreadK
smoke.growK = storage.smoke_growK
smoke.targetYVelocity = storage.smoke_targetYVelocity


--[====[
local flamesInstances = {}
local sparksInstances = {}
local smokeInstances = {}

tables.insert(flamesInstances, flameInstance)

local collectionsStorage = StorageManager.getCollectionsStorage()
collectionsStorage.flame_emitters = flamesInstances
--]====]


local StorageManager__options_label = StorageManager.options_label
local StorageManager__options_tooltip = StorageManager.options_tooltip
local StorageManager__options_default = StorageManager.options_default
local StorageManager__options_min = StorageManager.options_min
local StorageManager__options_max = StorageManager.options_max

---
---@param optionType StorageManager.Options
local renderOptionSlider = function(optionType, currentValue)
    return UIOperations.renderSlider(StorageManager__options_label[optionType], StorageManager__options_tooltip[optionType], currentValue, StorageManager__options_min[optionType], StorageManager__options_max[optionType], DEFAULT_SLIDER_WIDTH, DEFAULT_SLIDER_FORMAT, StorageManager__options_default[optionType])
end

local renderFlamesSection = function()
    ui_pushID("FlamesSection")
    
    ui_dwriteText('Flames', UI_HEADER_TEXT_FONT_SIZE)
    UIOperations_newLine(1)
    
    -- Enabled
    flameInstance.enabled = UIOperations.renderCheckbox(StorageManager__options_label[StorageManager.Options.Flame_Enabled], StorageManager__options_tooltip[StorageManager.Options.Flame_Enabled], flameInstance.enabled, StorageManager__options_default[StorageManager.Options.Flame_Enabled])

    UIOperations_newLine(1)

    UIOperations.createDisabledSection(not flameInstance.enabled, function()
        -- Show the position value label
        ui.alignTextToFramePadding() -- called to align text properly with the button
        ui_text(string_format('Position: (%.2f, %.2f, %.2f)', flameInstance.position.x, flameInstance.position.y, flameInstance.position.z))

        ui_sameLine()

        local buttonText = flameInstance.waitingForClickToSetPosition and 'Click in the world' or 'Set Position'
        if ui_button(buttonText) then
            flameInstance.waitingForClickToSetPosition  = true
        end
        
        --UIOperations_newLine()

        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Flame_PositionOffset])
        flameInstance.positionOffset = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Flame_PositionOffset], flameInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Flame_PositionOffset], StorageManager__options_max[StorageManager.Options.Flame_PositionOffset])
        
        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Flame_Velocity])
        flameInstance.velocity = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Flame_Velocity], flameInstance.velocity, StorageManager__options_min[StorageManager.Options.Flame_Velocity], StorageManager__options_max[StorageManager.Options.Flame_Velocity])

        UIOperations_newLine(1)

        flame.color = UIOperations.renderColorPicker(StorageManager__options_label[StorageManager.Options.Flame_Color], StorageManager__options_tooltip[StorageManager.Options.Flame_Color], flame.color, colorPickerFlags, colorPickerSize)
        flame.size = renderOptionSlider(StorageManager.Options.Flame_Size, flame.size)
        flameInstance.amount = renderOptionSlider(StorageManager.Options.Flame_Amount, flameInstance.amount)
        UIOperations_newLine(1)
        flame.temperatureMultiplier = renderOptionSlider(StorageManager.Options.Flame_TemperatureMultiplier, flame.temperatureMultiplier)
        flame.flameIntensity = renderOptionSlider(StorageManager.Options.Flame_FlameIntensity, flame.flameIntensity)
    end)
    
    ui_popID()

    if flameInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations.tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            ac.log('Flame position set to: ' .. tostring(out_worldPosition))
            flameInstance.position = out_worldPosition
            flameInstance.waitingForClickToSetPosition = false
        end
    end

    -- Update the storage values with the instance values
    storage.flame_enabled = flameInstance.enabled
    storage.flame_position = flameInstance.position
    storage.flame_positionOffset = flameInstance.positionOffset
    storage.flame_velocity = flameInstance.velocity
    storage.flame_amount = flameInstance.amount

    storage.flame_color = flame.color
    storage.flame_size = flame.size
    storage.flame_temperatureMultiplier = flame.temperatureMultiplier
    storage.flame_flameIntensity = flame.flameIntensity
end

local renderSparksSection = function()
    ui_pushID("SparksSection")
    
    ui_dwriteText('Sparks', UI_HEADER_TEXT_FONT_SIZE)
    UIOperations_newLine(1)
    
    -- Enabled
    sparksInstance.enabled = UIOperations.renderCheckbox(StorageManager__options_label[StorageManager.Options.Sparks_Enabled], StorageManager__options_tooltip[StorageManager.Options.Sparks_Enabled], sparksInstance.enabled, StorageManager__options_default[StorageManager.Options.Sparks_Enabled])
    
    UIOperations_newLine(1)
    
    UIOperations.createDisabledSection(not sparksInstance.enabled, function()
        -- Show the position value label
        ui.alignTextToFramePadding() -- called to align text properly with the button
        ui_text(string_format('Position: (%.2f, %.2f, %.2f)', sparksInstance.position.x, sparksInstance.position.y, sparksInstance.position.z))
        
        ui_sameLine()
        
        local buttonText = sparksInstance.waitingForClickToSetPosition and 'Click in the world' or 'Set Position'
        if ui_button(buttonText) then
            sparksInstance.waitingForClickToSetPosition = true
        end

        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Sparks_PositionOffset])
        sparksInstance.positionOffset = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Sparks_PositionOffset], sparksInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Sparks_PositionOffset], StorageManager__options_max[StorageManager.Options.Sparks_PositionOffset])

        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Sparks_Velocity])
        sparksInstance.velocity = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Sparks_Velocity], sparksInstance.velocity, StorageManager__options_min[StorageManager.Options.Sparks_Velocity], StorageManager__options_max[StorageManager.Options.Sparks_Velocity])
        
        UIOperations_newLine(1)

        sparks.color = UIOperations.renderColorPicker(StorageManager__options_label[StorageManager.Options.Sparks_Color], StorageManager__options_tooltip[StorageManager.Options.Sparks_Color], sparks.color, colorPickerFlags, colorPickerSize)
        sparks.size = renderOptionSlider(StorageManager.Options.Sparks_Size, sparks.size)
        sparksInstance.amount = renderOptionSlider(StorageManager.Options.Sparks_Amount, sparksInstance.amount)
        UIOperations_newLine(1)
        sparks.life = renderOptionSlider(StorageManager.Options.Sparks_Life, sparks.life)
        sparks.directionSpread = renderOptionSlider(StorageManager.Options.Sparks_DirectionSpread, sparks.directionSpread)
        sparks.positionSpread = renderOptionSlider(StorageManager.Options.Sparks_PositionSpread, sparks.positionSpread)
    end)
    
    ui_popID()

    if sparksInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations.tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            ac.log('Sparks position set to: ' .. tostring(out_worldPosition))
            sparksInstance.position = out_worldPosition
            sparksInstance.waitingForClickToSetPosition = false
        end
    end

    -- Update the storage values with the instance values
    storage.sparks_enabled = sparksInstance.enabled
    storage.sparks_position = sparksInstance.position
    storage.sparks_positionOffset = sparksInstance.positionOffset
    storage.sparks_velocity = sparksInstance.velocity
    storage.sparks_amount = sparksInstance.amount

    storage.sparks_color = sparks.color
    storage.sparks_life = sparks.life
    storage.sparks_size = sparks.size
    storage.sparks_directionSpread = sparks.directionSpread
    storage.sparks_positionSpread = sparks.positionSpread
end

local renderSmokeSection = function()
    ui_pushID("SmokeSection")
    
    ui_dwriteText('Smoke', UI_HEADER_TEXT_FONT_SIZE)
    UIOperations_newLine(1)
    
    -- Enabled
    smokeInstance.enabled = UIOperations.renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_Enabled], StorageManager__options_tooltip[StorageManager.Options.Smoke_Enabled], smokeInstance.enabled, StorageManager__options_default[StorageManager.Options.Smoke_Enabled])
    
    UIOperations_newLine(1)

    UIOperations.createDisabledSection(not smokeInstance.enabled, function()
        -- Show the position value label
        ui.alignTextToFramePadding() -- called to align text properly with the button
        ui_text(string_format('Position: (%.2f, %.2f, %.2f)', smokeInstance.position.x, smokeInstance.position.y, smokeInstance.position.z))
        
        ui_sameLine()
        
        local buttonText = smokeInstance.waitingForClickToSetPosition and 'Click in the world' or 'Set Position'
        if ui_button(buttonText) then
            smokeInstance.waitingForClickToSetPosition = true
        end

        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Smoke_PositionOffset])
        smokeInstance.positionOffset = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Smoke_PositionOffset], smokeInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Smoke_PositionOffset], StorageManager__options_max[StorageManager.Options.Smoke_PositionOffset])

        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Smoke_Velocity])
        smokeInstance.velocity = UIOperations.renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Smoke_Velocity], smokeInstance.velocity, StorageManager__options_min[StorageManager.Options.Smoke_Velocity], StorageManager__options_max[StorageManager.Options.Smoke_Velocity])
        
        UIOperations_newLine(1)

        smoke.color = UIOperations.renderColorPicker(StorageManager__options_label[StorageManager.Options.Smoke_Color], StorageManager__options_tooltip[StorageManager.Options.Smoke_Color], smoke.color, colorPickerFlags, colorPickerSize)
        smoke.size = renderOptionSlider(StorageManager.Options.Smoke_Size, smoke.size)
        smokeInstance.amount = renderOptionSlider(StorageManager.Options.Smoke_Amount, smokeInstance.amount)
        UIOperations_newLine(1)
        smoke.life = renderOptionSlider(StorageManager.Options.Smoke_Life, smoke.life)
        smoke.colorConsistency = renderOptionSlider(StorageManager.Options.Smoke_ColorConsistency, smoke.colorConsistency)
        smoke.thickness = renderOptionSlider(StorageManager.Options.Smoke_Thickness, smoke.thickness)
        smoke.spreadK = renderOptionSlider(StorageManager.Options.Smoke_SpreadK, smoke.spreadK)
        smoke.growK = renderOptionSlider(StorageManager.Options.Smoke_GrowK, smoke.growK)
        smoke.targetYVelocity = renderOptionSlider(StorageManager.Options.Smoke_TargetYVelocity, smoke.targetYVelocity)
        UIOperations_newLine(1)
        
        smokeInstance.disableCollisions = UIOperations.renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_DisableCollisions], StorageManager__options_tooltip[StorageManager.Options.Smoke_DisableCollisions], smokeInstance.disableCollisions, StorageManager__options_default[StorageManager.Options.Smoke_DisableCollisions])
        smokeInstance.fadeIn = UIOperations.renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_FadeIn], StorageManager__options_tooltip[StorageManager.Options.Smoke_FadeIn], smokeInstance.fadeIn, StorageManager__options_default[StorageManager.Options.Smoke_FadeIn])

        local flags = 0
        if smokeInstance.disableCollisions then
            flags = bit.bor(flags, ac.Particles.SmokeFlags.DisableCollisions)
        end
        if smokeInstance.fadeIn then
            flags = bit.bor(flags, ac.Particles.SmokeFlags.FadeIn)
        end
        smoke.flags = flags
    end)
    
    ui_popID()

    if smokeInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations.tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            ac.log('Smoke position set to: ' .. tostring(out_worldPosition))
            smokeInstance.position = out_worldPosition
            smokeInstance.waitingForClickToSetPosition = false
        end
    end

    -- Update the storage values with the instance values
    storage.smoke_enabled = smokeInstance.enabled
    storage.smoke_position = smokeInstance.position
    storage.smoke_positionOffset = smokeInstance.positionOffset
    storage.smoke_velocity = smokeInstance.velocity
    storage.smoke_amount = smokeInstance.amount

    storage.smoke_color = smoke.color
    storage.smoke_colorConsistency = smoke.colorConsistency
    storage.smoke_thickness = smoke.thickness
    storage.smoke_life = smoke.life
    storage.smoke_size = smoke.size
    storage.smoke_spreadK = smoke.spreadK
    storage.smoke_growK = smoke.growK
    storage.smoke_targetYVelocity = smoke.targetYVelocity
    storage.smoke_disableCollisions = smokeInstance.disableCollisions
    storage.smoke_fadeIn = smokeInstance.fadeIn
end

local COLUMNS_WIDTH = 370

local renderExtConfigFormatSection = function(extConfigFormat)
    ui_text(extConfigFormat)

    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        ui.setTooltip('Click to copy to clipboard')
    end

    if ui.itemClicked(ui.MouseButton.Left, true) then
        ac.setClipboardText(extConfigFormat)
        ac.setMessage('Copied', 'Copied to clipboard', nil, 5.0)
    end
end

-- TODO: most of this stuff has moved to ExtConfigFileHandler.lua - refactor this to use that module properly
local EXTENSION_PATH = '/extension/'
local EXT_CONFIG_FILENAME = 'ext_config.ini'
local EXT_CONFIG_RELATIVE_PATH = EXTENSION_PATH .. EXT_CONFIG_FILENAME

local function renderOpenTrackExtConfigLink()
  local trackLayoutFolder = ac.getFolder(ac.FolderID.CurrentTrackLayout)
  if not trackLayoutFolder or trackLayoutFolder == '' then
    ui.text(EXT_CONFIG_FILENAME)
    return
  end

  local extConfigPath = trackLayoutFolder .. EXT_CONFIG_RELATIVE_PATH

  if ui.textHyperlink(EXT_CONFIG_FILENAME) then
    if io.fileExists(extConfigPath) then
      ac.log(os.findAssociatedExecutable(extConfigPath))
      os.openTextFile(extConfigPath, 0)
    else
      os.showInExplorer(trackLayoutFolder .. EXTENSION_PATH)
    end
  end

  if ui.itemHovered() then
    ui.setMouseCursor(ui.MouseCursor.Hand)
  end
end

---@param particleEffectsType ParticleEffectsType
---@param particleEffectInstance FlameEffectWrapper|SparksEffectWrapper|SmokeEffectWrapper
local renderExportButtons = function(particleEffectsType, particleEffectInstance)
    if UIOperations_renderButton(
        'Save to global track config', 
        string_format(
            'Save to the track main config file which is applied for all layouts of this track.\n\n%s', 
            ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.Track)
        )
    ) then
        ParticleEffectsExtConfigFileHandler.writeToExtConfig(ExtConfigFileHandler.ExtConfigFileTypes.Track, particleEffectsType, particleEffectInstance)
        ac.setMessage('Saved', string_format('Particle effect saved to global track config file: %s', ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.Track)), nil, 5.0)
    end

    ui_sameLine()

    if UIOperations_renderButton(
        'Save to track layout config', 
        string_format(
            "Save to the track layout config file which is applied for only this layout.\nIf this track only has one layout, the global track config is used.\n\n%s",
            ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
        )
    ) then
        ParticleEffectsExtConfigFileHandler.writeToExtConfig(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout, particleEffectsType, particleEffectInstance)
        ac.setMessage('Saved', string_format('Particle effect saved to track layout config file: %s', ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)), nil, 5.0)
    end
end

local openGlobalTrackConfigButtonToolTipText = string_format(
    'Open the track main config file which is applied for all layouts of this track.\n\nRight click to show the file in its directory instead.\n\n%s', 
    ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.Track)
)

local openTrackLayoutConfigButtonTooltipText = string_format(
    'Open the track layout config file which is applied for only this layout.\n\nRight click to show the file in its directory instead.\n\n%s', 
    ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
)

if ExtConfigFileHandler.isTrackLayoutFileSameAsTrackFile() then
    openTrackLayoutConfigButtonTooltipText = openTrackLayoutConfigButtonTooltipText .. '\n\n\n(Note: This track only has one layout, so the global track config is used.)'
end

-- Function defined in manifest.ini
-- wiki: function to be called each frame to draw window content
---
function script.MANIFEST__FUNCTION_MAIN(dt)
    ui.textColored('Particle Effects is a helper app for adding particle effects to tracks.', rgbm(1, 1, 1, 1))
    UIOperations_newLine(1)
--[==[
    ui.textColored('To add a particle effect to this track, first set a position using the button and once you are satisfied with your options, click the generated code below and paste it into the', rgbm(1, 1, 1, 0.7))
    ui_sameLine()
    renderOpenTrackExtConfigLink()
--]==]

    ui.textColored(
    'To add a particle effect to this track, set a position using the [Set Position] button and once you are satisfied with your options, save it to the track using the Save buttons below.', rgbm(1, 1, 1, 0.7))

    UIOperations_newLine(1)

    -- ui.textColored('Alternatively you can save the particle effect directly to the track config files with the buttons at the bottom of the window.', rgbm(1, 1, 1, 0.7))
    ui.textColored('Alternatively you can click on the generated ext_config code below and paste it into the ext_config.ini file manually.', rgbm(1, 1, 1, 0.7))
    -- UIOperations_newLine(1)
    ui.alignTextToFramePadding() -- called to align text properly with the button
    ui.textColored('The ext_config.ini files can be found from:', rgbm(1, 1, 1, 0.7))
    ui_sameLine()

    --UIOperations_newLine(1)

    if UIOperations_renderButton(
        'Open global track config', 
        openGlobalTrackConfigButtonToolTipText,
        function() 
            -- show the file in its directory in explorer
            ExtConfigFileHandler.showExtConfigFileInExplorer(ExtConfigFileHandler.ExtConfigFileTypes.Track)
        end
    ) then
        -- open the file directly
        ExtConfigFileHandler.openExtConfigFile(ExtConfigFileHandler.ExtConfigFileTypes.Track)
    end

    ui_sameLine()

    if UIOperations_renderButton(
        'Open track layout config', 
        openTrackLayoutConfigButtonTooltipText,
        function() 
            -- show the file in its directory in explorer
            ExtConfigFileHandler.showExtConfigFileInExplorer(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
        end
    ) then
        -- open the file directly
        ExtConfigFileHandler.openExtConfigFile(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
    end

    UIOperations_newLine(1)

    ui.separator()

    UIOperations_newLine(1)

    ui_columns(3, true, "sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    -- Flames section
    renderFlamesSection()
    
    ui_nextColumn()

    -- Sparks section
    renderSparksSection()
    
    ui_nextColumn()
    
    -- Smoke section
    renderSmokeSection()
    
    -- finish the sections table
    ui_columns(1, false)

    UIOperations_newLine(1)
    
    --ui.separator()
    
    -- The table for the ext_config.ini code sections
    ui_columns(3, true, "ext_config_sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    -- Flames ext_config.ini section
    UIOperations.createDisabledSection(not flameInstance.enabled, function()
        local flameExtConfigFormat = ExtConfigCodeGenerator.generateCode(ParticleEffectsType.Flame, flame, flameInstance.getFinalPosition(), flameInstance.velocity, flameInstance.amount)
        renderExtConfigFormatSection(flameExtConfigFormat)
    end)
    
    ui_nextColumn()
    
    -- Sparks ext_config.ini section
    UIOperations.createDisabledSection(not sparksInstance.enabled, function()
        local sparksExtConfigFormat = ExtConfigCodeGenerator.generateCode(ParticleEffectsType.Sparks, sparks, sparksInstance.getFinalPosition(), sparksInstance.velocity, sparksInstance.amount)
        renderExtConfigFormatSection(sparksExtConfigFormat)
    end)
    
    ui_nextColumn()
    
    -- Smoke ext_config.ini section
    UIOperations.createDisabledSection(not smokeInstance.enabled, function()
        local smokeExtConfigFormat = ExtConfigCodeGenerator.generateCode(ParticleEffectsType.Smoke, smoke, smokeInstance.getFinalPosition(), smokeInstance.velocity, smokeInstance.amount)
        renderExtConfigFormatSection(smokeExtConfigFormat)
    end)
    
    -- finish the ext_config_sections table
    ui_columns(1, false)

    UIOperations_newLine(1)

    ui_columns(3, true, "export_sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    ui_pushID("ExportFlameSection")
    UIOperations.createDisabledSection(not flameInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Flame, flameInstance)
    end)
    ui_popID()

    ui_nextColumn()

    ui_pushID("ExportSparksSection")
    UIOperations.createDisabledSection(not sparksInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Sparks, sparksInstance)
    end)
    ui_popID()

    ui_nextColumn()

    ui_pushID("ExportSmokeSection")
    UIOperations.createDisabledSection(not smokeInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Smoke, smokeInstance)
    end)
    ui_popID()

    -- finish the export_sections table
    ui_columns(1, false)
end

--[====[
----- Andreas: this is the sample code to Ilja
local sampleFlame = ac.Particles.Flame({
    color = rgbm(0.72156864404678,0.70980393886566,0.54117649793625,1),
    size = 5,
    temperatureMultiplier = 1,
    flameIntensity = 2
})
local sampleFlamePosition = vec3(632.77020263672,88.856018066406,1431.8325195313)
local sampleFlameDirection = vec3(0, 1, 0)
local sampleFlameSpeed = 10
local sampleFlameIntensity = 1
local sampleFlameVelocity = sampleFlameDirection * sampleFlameSpeed

--[==[
[FLAME_1]
COLOR=0.72156864404678,0.70980393886566,0.54117649793625,1
SIZE=5
TEMPERATURE_MULT=1
FLAME_INTENSITY=2
POSITION=632.77020263672,88.856018066406,1431.8325195313
DIRECTION=0,1,0
SPEED=10
INTENSITY=1
--]==]
--]====]


---
-- wiki: called after a whole simulation update
---
function script.MANIFEST__UPDATE(dt)
    if flameInstance.enabled then
        flame:emit(flameInstance.getFinalPosition(), flameInstance.velocity, flameInstance.amount)
    end
    
    if sparksInstance.enabled then
        sparks:emit(sparksInstance.getFinalPosition(), sparksInstance.velocity, sparksInstance.amount)
    end
    
    if smokeInstance.enabled then
        smoke:emit(smokeInstance.getFinalPosition(), smokeInstance.velocity, smokeInstance.amount)
    end

--[====[
    -- Andreas: sample code to Ilja
    sampleFlame:emit(sampleFlamePosition, sampleFlameVelocity, sampleFlameIntensity)
--]====]
end

---
-- wiki: called when transparent objects are finished rendering
---
function script.MANIFEST__TRANSPARENT(dt)
end

--[==[
local extCfgSys = ac.getFolder(ac.FolderID.ExtCfgSys)
local extCfgUser = ac.getFolder(ac.FolderID.ExtCfgUser)
local extCfgCurrentTrackLayout = ac.getFolder(ac.FolderID.CurrentTrackLayout)

ac.log('ExtCfgSys folder: ' .. tostring(extCfgSys))
ac.log('ExtCfgUser folder: ' .. tostring(extCfgUser))
ac.log('CurrentTrackLayout folder: ' .. tostring(extCfgCurrentTrackLayout))

local currentTrackLayoutFile = extCfgCurrentTrackLayout .. EXT_CONFIG_RELATIVE_PATH
ac.log('Current track layout ext_config.ini path: ' .. tostring(currentTrackLayoutFile))
local file = ac.INIConfig.load(currentTrackLayoutFile, ac.INIFormat.Extended, nil)

local largestSectionNameIndex = 0
for index, section in file:iterate('FLAME') do -- example => index: 1, section: "FLAME_0"
    ac.log('FLAME section index: ' .. tostring(index))
    ac.log(section)

    -- extract the numeric part from the section name by taking the substring after 'FLAME_' without using regexes
    local sectionNameSuffix = string.sub(section, 7) -- 'FLAME_' has 6 characters, so start from the 7th character
    local sectionNameIndex = tonumber(sectionNameSuffix)
    if sectionNameIndex and sectionNameIndex > largestSectionNameIndex then
        largestSectionNameIndex = sectionNameIndex
    end
end

local nextSectionNameIndex = largestSectionNameIndex + 1
-- ac.log('Next FLAME section name index: ' .. tostring(nextSectionNameIndex))
local nextSectionName = string_format('FLAME_%d', nextSectionNameIndex)
ac.log('Next FLAME section name: ' .. tostring(nextSectionName))

file:set(nextSectionName, 'POSITION', vec3(0, 0, 0))

--file:save(currentTrackLayoutFile)
ac.log('Saved ext_config.ini with new FLAME section at: ' .. tostring(currentTrackLayoutFile))
--]==]

--[==[
ExtConfigFileHandler.writeNewSectionToExtConfigFile(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout, 'FLAME', function(file, fullSectionName)
    file:set(fullSectionName, 'POSITION', vec3(0, 0, 0))
    ac.log('Wrote POSITION to section: ' .. tostring(fullSectionName))
end)
--]==]