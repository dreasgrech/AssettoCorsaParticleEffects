local StorageManager = {}

local fillInDoDTables = function(collection_beforeDoD, options_default, options_min, options_max, options_label, options_tooltip)
    options_default = {}
    options_min = {}
    options_max = {}
    options_label = {}
    options_tooltip = {}

    for i, option in ipairs(collection_beforeDoD) do
        local optionName = option.name
        options_default[optionName] = option.default
        options_min[optionName] = option.min
        options_max[optionName] = option.max
        options_label[optionName] = option.label
        options_tooltip[optionName] = option.tooltip
    end

    return options_default, options_min, options_max, options_label, options_tooltip
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

---@enum StorageManager.Options
StorageManager.Options = {
    Flame_Enabled = 1,
    Flame_Position = 2,
    Flame_PositionOffset = 3,
    Flame_Velocity = 4,
    Flame_Color = 5,
    Flame_Size = 6,
    Flame_Amount = 7,
    Flame_TemperatureMultiplier = 8,
    Flame_FlameIntensity = 9,
    
    Sparks_Enabled = 10,
    Sparks_Position = 11,
    Sparks_PositionOffset = 12,
    Sparks_Velocity = 13,
    Sparks_Color = 14,
    Sparks_Size = 15,
    Sparks_Amount = 16,
    Sparks_Life = 17,
    Sparks_DirectionSpread = 18,
    Sparks_PositionSpread = 19,
    
    Smoke_Enabled = 20,
    Smoke_Position = 21,
    Smoke_PositionOffset = 22,
    Smoke_Velocity = 23,
    Smoke_Color = 24,
    Smoke_Size = 25,
    Smoke_Amount = 26,
    Smoke_ColorConsistency = 27,
    Smoke_Thickness = 28,
    Smoke_Life = 29,
    Smoke_SpreadK = 30,
    Smoke_GrowK = 31,
    Smoke_TargetYVelocity = 32,
    Smoke_DisableCollisions = 33,
    Smoke_FadeIn = 34,
}

local POSITION_OFFSET_MIN = -10
local POSITION_OFFSET_MAX = 10

local settingNotSupportedTooltip = 'Warning: This setting is not supported by ext_config.ini so it cannot be represented in config format.'

-- only used to fill in DoD tables, memory freed right after
local optionsCollection_beforeDoD = {
    { name = StorageManager.Options.Flame_Enabled, default=false, min=nil, max=nil, label='Enabled', tooltip='Enable the Flames particle effect.' },
    { name = StorageManager.Options.Flame_Position, default=vec3(0,0,0), min=nil, max=nil, label='Position', tooltip='Flame position in world coordinates' },
    { name = StorageManager.Options.Flame_PositionOffset, default=vec3(0,0,0), min=POSITION_OFFSET_MIN, max=POSITION_OFFSET_MAX, label='Position Offset', tooltip='Offset in position from the base position.' },
    { name = StorageManager.Options.Flame_Velocity, default=vec3(0,1,0), min=-100, max=100, label='Velocity', tooltip='The velocity applied to the flames' },
    { name = StorageManager.Options.Flame_Color, default=rgbm(0.5, 0.5, 0.5, 0.5), min=nil, max=nil, label='Color', tooltip='Flame color multiplier.\n\nFor red/yellow/blue adjustment use `Temperature Multiplier` instead.' },
    { name = StorageManager.Options.Flame_Size, default=1, min=0, max=50, label='Size', tooltip='Particles size.' },
    { name = StorageManager.Options.Flame_TemperatureMultiplier, default=1.0, min=0, max=10, label='Temperature Multiplier', tooltip='Temperature multipler to vary base color from red to blue.' },
    { name = StorageManager.Options.Flame_FlameIntensity, default=0.0, min=0, max=10, label='Flame Intensity', tooltip='Flame intensity affecting flame look and behaviour.' },
    { name = StorageManager.Options.Flame_Amount, default=1, min=0, max=5, label='Amount', tooltip='The amount of particles emitted.' }, -- max=5 value from conversation with Ilya
    
    { name = StorageManager.Options.Sparks_Enabled, default=false, min=nil, max=nil, label='Enabled', tooltip='Enable the Sparks particle effect.' },
    { name = StorageManager.Options.Sparks_Position, default=vec3(0,0,0), min=nil, max=nil, label='Position', tooltip='Sparks position in world coordinates.' },
    { name = StorageManager.Options.Sparks_PositionOffset, default=vec3(0,0,0), min=POSITION_OFFSET_MIN, max=POSITION_OFFSET_MAX, label='Position Offset', tooltip='Offset in position from the base position.' },
    { name = StorageManager.Options.Sparks_Velocity, default=vec3(0,1,0), min=-100, max=100, label='Velocity', tooltip='The velocity applied to the sparks' },
    { name = StorageManager.Options.Sparks_Color, default=rgbm(0.5, 0.5, 0.5, 0.5), min=nil, max=nil, label='Color', tooltip='Sparks color.' },
    { name = StorageManager.Options.Sparks_Life, default=4.0, min=0, max=100, label='Life', tooltip='Base lifetime.' },
    { name = StorageManager.Options.Sparks_Size, default=0.2, min=0, max=50, label='Size', tooltip='Base size.' },
    { name = StorageManager.Options.Sparks_DirectionSpread, default=1.0, min=0, max=10, label='Direction Spread', tooltip='How much sparks directions vary.' },
    { name = StorageManager.Options.Sparks_PositionSpread, default=0.2, min=0, max=10, label='Position Spread', tooltip='How much sparks position vary.' },
    { name = StorageManager.Options.Sparks_Amount, default=1, min=0, max=5, label='Amount', tooltip='The amount of particles emitted.' }, -- max=5 value from conversation with Ilya
    
    { name = StorageManager.Options.Smoke_Enabled, default=false, min=nil, max=nil, label='Enabled', tooltip='Enable the Smoke particle effect.' },
    { name = StorageManager.Options.Smoke_Position, default=vec3(0,0,0), min=nil, max=nil, label='Position', tooltip='Smoke position in world coordinates.' },
    { name = StorageManager.Options.Smoke_PositionOffset, default=vec3(0,0,0), min=POSITION_OFFSET_MIN, max=POSITION_OFFSET_MAX, label='Position Offset', tooltip='Offset in position from the base position.' },
    { name = StorageManager.Options.Smoke_Velocity, default=vec3(0,1,0), min=-100, max=100, label='Velocity', tooltip='The velocity applied to the smoke' },
    { name = StorageManager.Options.Smoke_Color, default=rgbm(0.5, 0.5, 0.5, 0.5), min=nil, max=nil, label='Color', tooltip='Smoke color with values from 0 to 1. Alpha can be used to adjust thickness.' },
    { name = StorageManager.Options.Smoke_ColorConsistency, default=0.5, min=0, max=1, label='Color Consistency', tooltip='Defines how much color dissipates when smoke expands, from 0 to 1.' },
    { name = StorageManager.Options.Smoke_Thickness, default=1.0, min=0, max=1, label='Thickness', tooltip='How thick is smoke, from 0 to 1.' },
    { name = StorageManager.Options.Smoke_Life, default=4.0, min=0, max=100, label='Life', tooltip='Smoke base lifespan in seconds.' },
    { name = StorageManager.Options.Smoke_Size, default=0.2, min=0, max=50, label='Size', tooltip='Starting particle size in meters.' },
    { name = StorageManager.Options.Smoke_SpreadK, default=1.0, min=0, max=10, label='Spread K', tooltip='How randomized is smoke spawn (mostly, speed and direction).' },
    { name = StorageManager.Options.Smoke_GrowK, default=1.0, min=0, max=10, label='Grow K', tooltip='How fast smoke expands.' },
    { name = StorageManager.Options.Smoke_TargetYVelocity, default=0.0, min=-100, max=100, label='Target Y Velocity', tooltip='Neutral vertical velocity. Set above zero for hot gasses and below zero for cold, to collect at the bottom.' },
    { name = StorageManager.Options.Smoke_Amount, default=1, min=0, max=5, label='Amount', tooltip='The amount of particles emitted.' }, -- max=5 value from conversation with Ilya
    { name = StorageManager.Options.Smoke_DisableCollisions, default=false, min=nil, max=nil, label='Disable Collisions', tooltip=string.format('Disable smoke collisions with the environment.\n\n%s', settingNotSupportedTooltip) },
    { name = StorageManager.Options.Smoke_FadeIn, default=false, min=nil, max=nil, label='Fade In', tooltip=string.format('Enable smoke fade-in effect.\n\n%s', settingNotSupportedTooltip) },
}

-- -- Since the label is used as an identifier in the ui elements, make sure we only have unique labels (otherwise the ui elements will conflict)
-- UPDATE: Andreas: solved by using ui.pushID/popID around each section
-- local labelsSet = {}
-- for _, option in ipairs(optionsCollection_beforeDoD) do
--     local label = option.label
--     if labelsSet[label] then
--         ac.warn(string.format("[StorageManager] Duplicate label found in options: '%s'. Please ensure all labels are unique.", label))
--     end
--     
--     labelsSet[label] = true
-- end


StorageManager.options_default,
StorageManager.options_min,
StorageManager.options_max,
StorageManager.options_label,
StorageManager.options_tooltip = fillInDoDTables(
        optionsCollection_beforeDoD,
        StorageManager.options_default,
        StorageManager.options_min,
        StorageManager.options_max
)
optionsCollection_beforeDoD = nil  -- free memory

---@class StorageTable
---@field appRanFirstTime boolean
---@field flame_enabled boolean
---@field flame_position vec3
---@field flame_positionOffset vec3
---@field flame_velocity vec3
---@field flame_color rgbm
---@field flame_size number
---@field flame_temperatureMultiplier number
---@field flame_flameIntensity number
---@field flame_amount number
---@field sparks_enabled boolean
---@field sparks_position vec3
---@field sparks_positionOffset vec3
---@field sparks_velocity vec3
---@field sparks_color rgbm
---@field sparks_life number
---@field sparks_size number
---@field sparks_directionSpread number
---@field sparks_positionSpread number
---@field sparks_amount number
---@field smoke_enabled boolean
---@field smoke_position vec3
---@field smoke_positionOffset vec3
---@field smoke_velocity vec3
---@field smoke_color rgbm
---@field smoke_colorConsistency number
---@field smoke_thickness number
---@field smoke_life number
---@field smoke_size number
---@field smoke_spreadK number
---@field smoke_growK number
---@field smoke_targetYVelocity number
---@field smoke_amount number
---@field smoke_disableCollisions boolean
---@field smoke_fadeIn boolean

---@type StorageTable
local storageTable = {
    appRanFirstTime = false,

    flame_enabled = StorageManager.options_default[StorageManager.Options.Flame_Enabled],
    flame_position = StorageManager.options_default[StorageManager.Options.Flame_Position],
    flame_positionOffset = StorageManager.options_default[StorageManager.Options.Flame_PositionOffset],
    flame_velocity = StorageManager.options_default[StorageManager.Options.Flame_Velocity],
    flame_color = StorageManager.options_default[StorageManager.Options.Flame_Color],
    flame_size = StorageManager.options_default[StorageManager.Options.Flame_Size],
    flame_temperatureMultiplier = StorageManager.options_default[StorageManager.Options.Flame_TemperatureMultiplier],
    flame_flameIntensity = StorageManager.options_default[StorageManager.Options.Flame_FlameIntensity],
    flame_amount = StorageManager.options_default[StorageManager.Options.Flame_Amount],
    
    sparks_enabled = StorageManager.options_default[StorageManager.Options.Sparks_Enabled],
    sparks_position = StorageManager.options_default[StorageManager.Options.Sparks_Position],
    sparks_positionOffset = StorageManager.options_default[StorageManager.Options.Sparks_PositionOffset],
    sparks_velocity = StorageManager.options_default[StorageManager.Options.Sparks_Velocity],
    sparks_color = StorageManager.options_default[StorageManager.Options.Sparks_Color],
    sparks_life = StorageManager.options_default[StorageManager.Options.Sparks_Life],
    sparks_size = StorageManager.options_default[StorageManager.Options.Sparks_Size],
    sparks_directionSpread = StorageManager.options_default[StorageManager.Options.Sparks_DirectionSpread],
    sparks_positionSpread = StorageManager.options_default[StorageManager.Options.Sparks_PositionSpread],
    sparks_amount = StorageManager.options_default[StorageManager.Options.Sparks_Amount],
    
    smoke_enabled = StorageManager.options_default[StorageManager.Options.Smoke_Enabled],
    smoke_position = StorageManager.options_default[StorageManager.Options.Smoke_Position],
    smoke_positionOffset = StorageManager.options_default[StorageManager.Options.Smoke_PositionOffset],
    smoke_velocity = StorageManager.options_default[StorageManager.Options.Smoke_Velocity],
    smoke_color = StorageManager.options_default[StorageManager.Options.Smoke_Color],
    smoke_colorConsistency = StorageManager.options_default[StorageManager.Options.Smoke_ColorConsistency],
    smoke_thickness = StorageManager.options_default[StorageManager.Options.Smoke_Thickness],
    smoke_life = StorageManager.options_default[StorageManager.Options.Smoke_Life],
    smoke_size = StorageManager.options_default[StorageManager.Options.Smoke_Size],
    smoke_spreadK = StorageManager.options_default[StorageManager.Options.Smoke_SpreadK],
    smoke_growK = StorageManager.options_default[StorageManager.Options.Smoke_GrowK],
    smoke_targetYVelocity = StorageManager.options_default[StorageManager.Options.Smoke_TargetYVelocity],
    smoke_amount = StorageManager.options_default[StorageManager.Options.Smoke_Amount],
    smoke_disableCollisions = StorageManager.options_default[StorageManager.Options.Smoke_DisableCollisions],
    smoke_fadeIn = StorageManager.options_default[StorageManager.Options.Smoke_FadeIn]
}

---@type StorageTable
local storage = ac.storage(storageTable, "global")

---@return StorageTable
StorageManager.getStorage = function()
    return storage
end

--[====[
local collectionsStorageTable = {
    flame_emitters = {},
    sparks_emitters = {},
    smoke_emitters = {}
}

local collectionsStorage = ac.storage(collectionsStorageTable, "collections")
StorageManager.getCollectionsStorage = function()
    return collectionsStorage
end
--]====]

return StorageManager