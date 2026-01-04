Constants = require("Constants")
CSPCompatibilityManager = require("CSPCompatibilityManager")

local cspVersion = CSPCompatibilityManager.getCSPVersion()
ac.log(string.format("Launching %s v%s.  Custom Shaders Patch: %s",Constants.APP_NAME, Constants.APP_VERSION, cspVersion))

local showMissingCSPElementsErrorModalDialog = function(message)
  local neededFunctionsForModalDialogAvailable =
    ui.modalDialog ~= nil or
    ui.textWrapped ~= nil or
    ui.newLine ~= nil or
    ui.button ~= nil or
    ac.setClipboardText ~= nil or
    ui.sameLine ~= nil

    if not neededFunctionsForModalDialogAvailable then
      ac.error(string.format("Cannot show error dialog because some required CSP elements are missing.\nError text: %s", message))
      return
    end

  ui.modalDialog(string.format('[Error] Missing CSP elements needed to run the %s app', Constants.APP_NAME), function()
    ui.textColored(message, rgbm(1, 0, 0, 1))
    ui.newLine()
    if ui.modernButton('Copy', vec2(110, 40)) then
      ac.setClipboardText(message) 
    end
    ui.sameLine()
    if ui.modernButton('Close', vec2(120, 40)) then
      return true
    end

    return false
  end, true)
end

-- Check if any CSP elements used by the app are missing
local missingCSPElements = CSPCompatibilityManager.checkForMissingCSPElements()
local anyMissingCSPElements = (#missingCSPElements > 0)
local missingCSPElementsErrorMessage

-- Show an error modal dialog if any CSP elements are missing
if anyMissingCSPElements then
  -- Build the CSP missing elements error message
  missingCSPElementsErrorMessage = string.format("%s may not run as expected because some required Custom Shaders Patch elements are missing.", Constants.APP_NAME)
  missingCSPElementsErrorMessage = missingCSPElementsErrorMessage .. "\n\nThe following CSP elements are needed by the app:\n"
  for _, elementName in ipairs(missingCSPElements) do
      missingCSPElementsErrorMessage = missingCSPElementsErrorMessage .. " - " .. elementName .. "\n"
  end
  missingCSPElementsErrorMessage = missingCSPElementsErrorMessage .. "\nSee the CSP log in \"\\Documents\\Assetto Corsa\\logs\\custom_shaders_patch.log\" for more details."
  missingCSPElementsErrorMessage = missingCSPElementsErrorMessage .. "\n\nTo fix the issue, please make sure you're on the latest version of Custom Shaders Patch (https://www.patreon.com/c/x4fab/posts)"
  missingCSPElementsErrorMessage = missingCSPElementsErrorMessage .. string.format("\n\nYour CSP version is %s", cspVersion)

  -- Log the error to the CSP log as well
  ac.error(missingCSPElementsErrorMessage)

  -- Show the error modal dialog
  showMissingCSPElementsErrorModalDialog(missingCSPElementsErrorMessage)
end


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
LuaParticleEffectsCodeGenerator = require("LuaParticleEffectsCodeGenerator")

-- local bindings
local bit_bor = bit.bor
local ac_setClipboardText = ac.setClipboardText
local ac_setMessage = ac.setMessage
local ui_columns = ui.columns
local ui_setColumnWidth = ui.setColumnWidth
local ui_dwriteText = ui.dwriteText
local ui_sameLine = ui.sameLine
local ui_pushID = ui.pushID
local ui_popID = ui.popID
local ui_text = ui.text
local ui_textColored = ui.textColored
local ui_nextColumn = ui.nextColumn
local ui_alignTextToFramePadding = ui.alignTextToFramePadding
local ui_itemHovered = ui.itemHovered
local ui_setMouseCursor = ui.setMouseCursor
local ui_itemClicked = ui.itemClicked
local ui_separator = ui.separator
local string_format = string.format
local UIOperations_newLine = UIOperations.newLine
local UIOperations_renderButton = UIOperations.renderButton
local UIOperations_renderSlider = UIOperations.renderSlider
local UIOperations_renderCheckbox = UIOperations.renderCheckbox
local UIOperations_renderColorButton = UIOperations.renderColorButton
local UIOperations_renderVec3Sliders = UIOperations.renderVec3Sliders
local UIOperations_renderColorPicker = UIOperations.renderColorPicker
local UIOperations_tryGetWorldPositionFromMouseClick = UIOperations.tryGetWorldPositionFromMouseClick
local UIOperations_createDisabledSection = UIOperations.createDisabledSection
local UIOperations_setTooltip = UIOperations.setTooltip
local LuaParticleEffectsCodeGenerator_generateCode = LuaParticleEffectsCodeGenerator.generateCode
local ExtConfigCodeGenerator_generateCode = ExtConfigCodeGenerator.generateCode

local UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab = UIOperations.DEFAULT_UI_COMPONENT_COLORS.sliderGrab

local POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR = rgbm(0.588, 0.544, 0.039, .5) -- yellowish
local POSITION_OFFSET_SETTING_LABEL_TOOLTIP = 'The values set here will be added to the Position values both when emitting the particles and also when saving the particle effect to the ext_config.ini file.\n\nThis is useful to fine-tune the position of the effect.'

local UI_HEADER_TEXT_FONT_SIZE = 15
local DEFAULT_SLIDER_WIDTH = 200
local DEFAULT_SLIDER_FORMAT = '%.2f'

local LUA_CODE_PANEL_FLAGS = bit.bor(
  ui.WindowFlags.ThinScrollbar,
  --ui.WindowFlags.AlwaysVerticalScrollbar,
  --ui.WindowFlags.HorizontalScrollbar
  ui.WindowFlags.AlwaysHorizontalScrollbar
)
local LUA_CODE_PANEL_HEIGHT = 300

local openGlobalTrackConfigButtonToolTipText = string_format(
    'Open the track main config file which is applied for all layouts of this track.\n\nRight click to show the file in its directory instead.\n\n%s', 
    ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.Track)
)

local openTrackLayoutConfigButtonTooltipText = string_format(
    'Open the track layout config file which is applied for only this layout.\n\nRight click to show the file in its directory instead.\n\n%s', 
    ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
)

local ONE_LAYOUT_CONFIG_USED_TEXT = '(Note: This track only has one layout, so the global track config is used.)'

local isTrackLayoutFileSameAsTrackFile = ExtConfigFileHandler.isTrackLayoutFileSameAsTrackFile()
if isTrackLayoutFileSameAsTrackFile then
    openTrackLayoutConfigButtonTooltipText = string_format('%s\n\n\n%s', openTrackLayoutConfigButtonTooltipText, ONE_LAYOUT_CONFIG_USED_TEXT)
end

local saveTrackLayoutConfigButtonTooltipText = string_format(
    'Save the particle effect to the track layout config file which is applied for only this layout.\n\n%s', 
    ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)
)

if isTrackLayoutFileSameAsTrackFile then
    saveTrackLayoutConfigButtonTooltipText = string_format('%s\n\n\n%s', saveTrackLayoutConfigButtonTooltipText, ONE_LAYOUT_CONFIG_USED_TEXT)
end

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
local colorPickerFlags = bit_bor(
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
    return UIOperations_renderSlider(StorageManager__options_label[optionType], StorageManager__options_tooltip[optionType], currentValue, StorageManager__options_min[optionType], StorageManager__options_max[optionType], DEFAULT_SLIDER_WIDTH, DEFAULT_SLIDER_FORMAT, StorageManager__options_default[optionType])
end

local setPositionButtonColors = {
    normal = rgbm(0.00, 0.352, 0.258, 1.0),
    hovered = rgbm(0.00, 0.433, 0.316, 1.0),
    active = rgbm(0.08, 0.55, 0.16, 1.0),
    text = rgbm(1.0, 1.0, 1.0, 1.0),
    waitingForClick_normal = rgbm(1.0, 0.843, 0.0, 1.0),
    waitingForClick_hovered = rgbm(1.0, 0.925, 0.235, 1.0),
    waitingForClick_active = rgbm(1.0, 0.980, 0.513, 1.0),
    waitingForClick_text = rgbm(0.0, 0.0, 0.0, 1.0),
}

local renderPositionSection = function(particleEffectInstance)
        -- Show the position value label
        ui_alignTextToFramePadding() -- called to align text properly with the button
        ui_text(string_format('Position: (%.2f, %.2f, %.2f)', particleEffectInstance.position.x, particleEffectInstance.position.y, particleEffectInstance.position.z))

        ui_sameLine()

        local buttonNormalColor = setPositionButtonColors.normal
        local buttonHoveredColor = setPositionButtonColors.hovered
        local buttonActiveColor = setPositionButtonColors.active
        local buttonTextColor = setPositionButtonColors.text

        if particleEffectInstance.waitingForClickToSetPosition then
            buttonNormalColor = setPositionButtonColors.waitingForClick_normal
            buttonHoveredColor = setPositionButtonColors.waitingForClick_hovered
            buttonActiveColor = setPositionButtonColors.waitingForClick_active
            buttonTextColor = setPositionButtonColors.waitingForClick_text
        end

        if UIOperations_renderColorButton(
            buttonNormalColor, buttonHoveredColor, buttonActiveColor, buttonTextColor,
            function()
                local buttonText = particleEffectInstance.waitingForClickToSetPosition and 'Click in the world' or 'Set Position'
                -- local buttonText = 'Set Position'
                return UIOperations_renderButton(
                    buttonText, 
                    'Set the particle effect position by clicking on the track.\n\nIf the particle effect is not appearing at the exact position where you click, make sure that the Position Offset value is set to 0.\n\nThe final position saved in the ext_config.ini file is this Position value plus the Position Offset value.'
                )
            end
        ) then
            particleEffectInstance.waitingForClickToSetPosition  = true
        end
end

local renderFlamesSection = function()
    ui_pushID("FlamesSection")
    
    ui_dwriteText('Flames', UI_HEADER_TEXT_FONT_SIZE)
    UIOperations_newLine(1)
    
    -- Enabled
    flameInstance.enabled = UIOperations_renderCheckbox(StorageManager__options_label[StorageManager.Options.Flame_Enabled], StorageManager__options_tooltip[StorageManager.Options.Flame_Enabled], flameInstance.enabled, StorageManager__options_default[StorageManager.Options.Flame_Enabled])

    UIOperations_newLine(1)

    UIOperations_createDisabledSection(not flameInstance.enabled, function()
        renderPositionSection(flameInstance)
        
        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Flame_PositionOffset])
        UIOperations_setTooltip(POSITION_OFFSET_SETTING_LABEL_TOOLTIP)

        -- The slider grab color changes if the value is not zero for the position offset so that the user can easily see that an offset is applied
        local positionOffsetXSliderGrabColor = flameInstance.positionOffset.x ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetYSliderGrabColor = flameInstance.positionOffset.y ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetZSliderGrabColor = flameInstance.positionOffset.z ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        flameInstance.positionOffset = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Flame_PositionOffset], flameInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Flame_PositionOffset], StorageManager__options_max[StorageManager.Options.Flame_PositionOffset], nil, positionOffsetXSliderGrabColor, positionOffsetYSliderGrabColor, positionOffsetZSliderGrabColor)
        
        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Flame_Velocity])
        UIOperations_setTooltip(StorageManager__options_tooltip[StorageManager.Options.Flame_Velocity])

        flameInstance.velocity = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Flame_Velocity], flameInstance.velocity, StorageManager__options_min[StorageManager.Options.Flame_Velocity], StorageManager__options_max[StorageManager.Options.Flame_Velocity])

        UIOperations_newLine(1)

        flame.color = UIOperations_renderColorPicker(StorageManager__options_label[StorageManager.Options.Flame_Color], StorageManager__options_tooltip[StorageManager.Options.Flame_Color], flame.color, colorPickerFlags, colorPickerSize)
        flame.size = renderOptionSlider(StorageManager.Options.Flame_Size, flame.size)
        flameInstance.amount = renderOptionSlider(StorageManager.Options.Flame_Amount, flameInstance.amount)
        UIOperations_newLine(1)
        flame.temperatureMultiplier = renderOptionSlider(StorageManager.Options.Flame_TemperatureMultiplier, flame.temperatureMultiplier)
        flame.flameIntensity = renderOptionSlider(StorageManager.Options.Flame_FlameIntensity, flame.flameIntensity)
    end)
    
    ui_popID()

    if flameInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations_tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            -- ac.log('Flame position set to: ' .. tostring(out_worldPosition))
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
    sparksInstance.enabled = UIOperations_renderCheckbox(StorageManager__options_label[StorageManager.Options.Sparks_Enabled], StorageManager__options_tooltip[StorageManager.Options.Sparks_Enabled], sparksInstance.enabled, StorageManager__options_default[StorageManager.Options.Sparks_Enabled])
    
    UIOperations_newLine(1)
    
    UIOperations_createDisabledSection(not sparksInstance.enabled, function()
        renderPositionSection(sparksInstance)

        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Sparks_PositionOffset])
        UIOperations_setTooltip(POSITION_OFFSET_SETTING_LABEL_TOOLTIP)

        -- The slider grab color changes if the value is not zero for the position offset so that the user can easily see that an offset is applied
        local positionOffsetXSliderGrabColor = sparksInstance.positionOffset.x ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetYSliderGrabColor = sparksInstance.positionOffset.y ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetZSliderGrabColor = sparksInstance.positionOffset.z ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        sparksInstance.positionOffset = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Sparks_PositionOffset], sparksInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Sparks_PositionOffset], StorageManager__options_max[StorageManager.Options.Sparks_PositionOffset], nil, positionOffsetXSliderGrabColor, positionOffsetYSliderGrabColor, positionOffsetZSliderGrabColor)

        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Sparks_Velocity])
        UIOperations_setTooltip(StorageManager__options_tooltip[StorageManager.Options.Sparks_Velocity])

        sparksInstance.velocity = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Sparks_Velocity], sparksInstance.velocity, StorageManager__options_min[StorageManager.Options.Sparks_Velocity], StorageManager__options_max[StorageManager.Options.Sparks_Velocity])
        
        UIOperations_newLine(1)

        sparks.color = UIOperations_renderColorPicker(StorageManager__options_label[StorageManager.Options.Sparks_Color], StorageManager__options_tooltip[StorageManager.Options.Sparks_Color], sparks.color, colorPickerFlags, colorPickerSize)
        sparks.size = renderOptionSlider(StorageManager.Options.Sparks_Size, sparks.size)
        sparksInstance.amount = renderOptionSlider(StorageManager.Options.Sparks_Amount, sparksInstance.amount)
        UIOperations_newLine(1)
        sparks.life = renderOptionSlider(StorageManager.Options.Sparks_Life, sparks.life)
        sparks.directionSpread = renderOptionSlider(StorageManager.Options.Sparks_DirectionSpread, sparks.directionSpread)
        sparks.positionSpread = renderOptionSlider(StorageManager.Options.Sparks_PositionSpread, sparks.positionSpread)
    end)
    
    ui_popID()

    if sparksInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations_tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            -- ac.log('Sparks position set to: ' .. tostring(out_worldPosition))
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
    smokeInstance.enabled = UIOperations_renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_Enabled], StorageManager__options_tooltip[StorageManager.Options.Smoke_Enabled], smokeInstance.enabled, StorageManager__options_default[StorageManager.Options.Smoke_Enabled])
    
    UIOperations_newLine(1)

    UIOperations_createDisabledSection(not smokeInstance.enabled, function()
        renderPositionSection(smokeInstance)

        -- Position Offset
        ui_text(StorageManager__options_label[StorageManager.Options.Smoke_PositionOffset])
        UIOperations_setTooltip(POSITION_OFFSET_SETTING_LABEL_TOOLTIP)

        -- The slider grab color changes if the value is not zero for the position offset so that the user can easily see that an offset is applied
        local positionOffsetXSliderGrabColor = smokeInstance.positionOffset.x ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetYSliderGrabColor = smokeInstance.positionOffset.y ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        local positionOffsetZSliderGrabColor = smokeInstance.positionOffset.z ~= 0 and POSITION_OFFSET_SETTING_SLIDER_NOT_ZERO_COLOR or UIOperations_DEFAULT_UI_COMPONENT_COLORS_sliderGrab
        smokeInstance.positionOffset = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Smoke_PositionOffset], smokeInstance.positionOffset, StorageManager__options_min[StorageManager.Options.Smoke_PositionOffset], StorageManager__options_max[StorageManager.Options.Smoke_PositionOffset], nil, positionOffsetXSliderGrabColor, positionOffsetYSliderGrabColor, positionOffsetZSliderGrabColor)

        UIOperations_newLine(1)

        -- Velocity
        ui_text(StorageManager__options_label[StorageManager.Options.Smoke_Velocity])
        UIOperations_setTooltip(StorageManager__options_tooltip[StorageManager.Options.Smoke_Velocity])

        smokeInstance.velocity = UIOperations_renderVec3Sliders(StorageManager__options_label[StorageManager.Options.Smoke_Velocity], smokeInstance.velocity, StorageManager__options_min[StorageManager.Options.Smoke_Velocity], StorageManager__options_max[StorageManager.Options.Smoke_Velocity])
        
        UIOperations_newLine(1)

        smoke.color = UIOperations_renderColorPicker(StorageManager__options_label[StorageManager.Options.Smoke_Color], StorageManager__options_tooltip[StorageManager.Options.Smoke_Color], smoke.color, colorPickerFlags, colorPickerSize)
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
        
        smokeInstance.disableCollisions = UIOperations_renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_DisableCollisions], StorageManager__options_tooltip[StorageManager.Options.Smoke_DisableCollisions], smokeInstance.disableCollisions, StorageManager__options_default[StorageManager.Options.Smoke_DisableCollisions])
        smokeInstance.fadeIn = UIOperations_renderCheckbox(StorageManager__options_label[StorageManager.Options.Smoke_FadeIn], StorageManager__options_tooltip[StorageManager.Options.Smoke_FadeIn], smokeInstance.fadeIn, StorageManager__options_default[StorageManager.Options.Smoke_FadeIn])

        local flags = 0
        if smokeInstance.disableCollisions then
            flags = bit_bor(flags, ac.Particles.SmokeFlags.DisableCollisions)
        end
        if smokeInstance.fadeIn then
            flags = bit_bor(flags, ac.Particles.SmokeFlags.FadeIn)
        end
        smoke.flags = flags
    end)
    
    ui_popID()

    if smokeInstance.waitingForClickToSetPosition then
        local worldPositionFound, out_worldPosition = UIOperations_tryGetWorldPositionFromMouseClick()
        if worldPositionFound then
            -- ac.log('Smoke position set to: ' .. tostring(out_worldPosition))
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

local renderCodeSection = function(extConfigFormat)
    ui_text(extConfigFormat)
    -- ui.textWrapped(extConfigFormat)

    if ui_itemHovered() then
        ui_setMouseCursor(ui.MouseCursor.Hand)
        UIOperations_setTooltip('Click to copy to clipboard')
    end

    if ui_itemClicked(ui.MouseButton.Left, true) then
        ac_setClipboardText(extConfigFormat)
        ac_setMessage('Copied', 'Copied to clipboard', nil, 5.0)
    end
end

-- TODO: most of this stuff has moved to ExtConfigFileHandler.lua - refactor this to use that module properly
-- local EXTENSION_PATH = '/extension/'
-- local EXT_CONFIG_FILENAME = 'ext_config.ini'
-- local EXT_CONFIG_RELATIVE_PATH = EXTENSION_PATH .. EXT_CONFIG_FILENAME

--[===[
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

  if ui_itemHovered() then
    ui_setMouseCursor(ui.MouseCursor.Hand)
  end
end
--]===]

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
        ac_setMessage('Saved', string_format('Particle effect saved to track config file: %s', ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.Track)), nil, 5.0)
    end

    ui_sameLine()

    if UIOperations_renderButton(
        'Save to track layout config',
        saveTrackLayoutConfigButtonTooltipText
    ) then
        ParticleEffectsExtConfigFileHandler.writeToExtConfig(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout, particleEffectsType, particleEffectInstance)
        ac_setMessage('Saved', string_format('Particle effect saved to track config file: %s', ExtConfigFileHandler.getFilePath(ExtConfigFileHandler.ExtConfigFileTypes.TrackLayout)), nil, 5.0)
    end
end

local renderLuaCodeSectionTables = function()
    ui_columns(3, true, "lua_code_sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    ui.childWindow('luaCodePanel_flames', vec2(0, LUA_CODE_PANEL_HEIGHT), false, LUA_CODE_PANEL_FLAGS, function ()
        -- Flames ext_config.ini section
        UIOperations_createDisabledSection(not flameInstance.enabled, function()
            local luaCode = LuaParticleEffectsCodeGenerator_generateCode(ParticleEffectsType.Flame, flameInstance)
            renderCodeSection(luaCode)
        end)
    end)

    ui_nextColumn()

    ui.childWindow('luaCodePanel_sparks', vec2(0, LUA_CODE_PANEL_HEIGHT), false, LUA_CODE_PANEL_FLAGS, function ()
        -- Sparks ext_config.ini section
        UIOperations_createDisabledSection(not sparksInstance.enabled, function()
            local luaCode = LuaParticleEffectsCodeGenerator_generateCode(ParticleEffectsType.Sparks, sparksInstance)
            renderCodeSection(luaCode)
        end)
    end)

    ui_nextColumn()

    ui.childWindow('luaCodePanel_smoke', vec2(0, LUA_CODE_PANEL_HEIGHT), false, LUA_CODE_PANEL_FLAGS, function ()
        -- Smoke ext_config.ini section
        UIOperations_createDisabledSection(not smokeInstance.enabled, function()
            local luaCode = LuaParticleEffectsCodeGenerator_generateCode(ParticleEffectsType.Smoke, smokeInstance)
            renderCodeSection(luaCode)
        end)
    end)

    -- finish the lua_code_sections table
    ui_columns(1, false)
end

local renderExtConfigCodeTables = function()
    -- The table for the ext_config.ini code sections
    ui_columns(3, true, "ext_config_sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    -- Flames ext_config.ini section
    UIOperations_createDisabledSection(not flameInstance.enabled, function()
        local flameExtConfigFormat = ExtConfigCodeGenerator_generateCode(ParticleEffectsType.Flame, flame, flameInstance.getFinalPosition(), flameInstance.velocity, flameInstance.amount)
        renderCodeSection(flameExtConfigFormat)
    end)
    
    ui_nextColumn()
    
    -- Sparks ext_config.ini section
    UIOperations_createDisabledSection(not sparksInstance.enabled, function()
        local sparksExtConfigFormat = ExtConfigCodeGenerator_generateCode(ParticleEffectsType.Sparks, sparks, sparksInstance.getFinalPosition(), sparksInstance.velocity, sparksInstance.amount)
        renderCodeSection(sparksExtConfigFormat)
    end)
    
    ui_nextColumn()
    
    -- Smoke ext_config.ini section
    UIOperations_createDisabledSection(not smokeInstance.enabled, function()
        local smokeExtConfigFormat = ExtConfigCodeGenerator_generateCode(ParticleEffectsType.Smoke, smoke, smokeInstance.getFinalPosition(), smokeInstance.velocity, smokeInstance.amount)
        renderCodeSection(smokeExtConfigFormat)
    end)
    
    -- finish the ext_config_sections table
    ui_columns(1, false)

    UIOperations_newLine(1)

    ui_columns(3, true, "export_sections")
    ui_setColumnWidth(0, COLUMNS_WIDTH)
    ui_setColumnWidth(1, COLUMNS_WIDTH)
    ui_setColumnWidth(2, COLUMNS_WIDTH)

    ui_pushID("ExportFlameSection")
    UIOperations_createDisabledSection(not flameInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Flame, flameInstance)
    end)
    ui_popID()

    ui_nextColumn()

    ui_pushID("ExportSparksSection")
    UIOperations_createDisabledSection(not sparksInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Sparks, sparksInstance)
    end)
    ui_popID()

    ui_nextColumn()

    ui_pushID("ExportSmokeSection")
    UIOperations_createDisabledSection(not smokeInstance.enabled, function()
        renderExportButtons(ParticleEffectsType.Smoke, smokeInstance)
    end)
    ui_popID()

    -- finish the export_sections table
    ui_columns(1, false)

    UIOperations_newLine(2)

    -- ui_textColored('Note: Internally, the CSP lua API is independent from the way ext_config.ini is handled.  This means that you might not always get the exact same results when the particle effects are saved to the ext_config.ini file.', rgbm(1, 1, 0, 1))
    ui_textColored('Note: CSP treats particle effects generated from the lua API (such as the ones generated and shown in this app) independently from particle effects defined in ext_config.ini.', rgbm(1, 1, 0, 1))
    ui_textColored('This means that you might not always get the exact same results when the particle effects are saved to the track config files.', rgbm(1, 1, 0, 1))
    --UIOperations_newLine(1)

end

local WINDOW_TEXT_APP_DESCRIPTION_COLOR = rgbm(1, 1, 1, 0.7)

-- Function defined in manifest.ini
-- wiki: function to be called each frame to draw window content
---
function script.MANIFEST__FUNCTION_MAIN(dt)
    ui_textColored(string_format('Particle Effects v%s is a helper app for adding particle effects to tracks.', Constants.APP_VERSION), rgbm(1, 1, 1, 1))
    UIOperations_newLine(1)

    ui_textColored(
    'To add a particle effect to this track, set a position using the [Set Position] button and once you are satisfied with your options, save it to the track config file using the Save buttons below.', WINDOW_TEXT_APP_DESCRIPTION_COLOR)

    -- UIOperations_newLine(1)

    ui_textColored('Alternatively you can click on the generated ext_config code below and paste it into the ext_config.ini file manually.', WINDOW_TEXT_APP_DESCRIPTION_COLOR)
    
    ui_alignTextToFramePadding() -- called to align text properly with the button
    ui_textColored('The ext_config.ini files can be found from:', WINDOW_TEXT_APP_DESCRIPTION_COLOR)
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

    ui_textColored('You can also copy the lua code to generate the exact same particle effects that are created by this app by switching to the LUA tab from the code tabs at the bottom of the window.', WINDOW_TEXT_APP_DESCRIPTION_COLOR)
    ui_textColored('The lua code can be pasted into a CSP lua app script file to generate the particle effects programmatically.', WINDOW_TEXT_APP_DESCRIPTION_COLOR)

    UIOperations_newLine(1)

    ui_separator()

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
    
    --ui_separator()

    ui.tabBar('CodeSectionsTabBar', function ()
        ui.tabItem('ext_config.ini', renderExtConfigCodeTables)
        ui.tabItem('LUA', renderLuaCodeSectionTables)
    end)

    --[===[
    -- Andreas: use this to determine the window size to be set in the manifest.ini file
    local winSize = ui.windowSize()
    ac.log(string_format('Particle Effects window size: (%.2f, %.2f)', winSize.x, winSize.y))
    --]===]
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
-- function script.MANIFEST__TRANSPARENT(dt)
-- end

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