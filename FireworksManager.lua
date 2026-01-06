---A standalone manager for creating and controlling fireworks emitters.
---Author: dreasgrech
local FireworksManager = {}

local fireworks = require('shared/sim/fireworks')

local nextFireworksIndex = 1

---@type table<number, ac.FireworksEmitter>
local createdFireworks = {}

---@enum FIREWORKS_VALUES
local FIREWORKS_VALUES = {
    Position = 1,
    Intensity = 2,
    HolidayType = 3,
}
FireworksManager.FIREWORKS_VALUES = FIREWORKS_VALUES

local fireworksValueSetters = {
    ---@param emitter ac.FireworksEmitter
    ---@param value vec3
    [FIREWORKS_VALUES.Position] = function(emitter, value)
        emitter:setPosition(value)
    end,
    ---@param emitter ac.FireworksEmitter
    ---@param value number
    [FIREWORKS_VALUES.Intensity] = function(emitter, value)
        emitter:setIntensity(value)
    end,
    ---@param emitter ac.FireworksEmitter
    ---@param value ac.HolidayType
    [FIREWORKS_VALUES.HolidayType] = function(emitter, value)
        emitter:setType(value)
    end,
}

local fireworksValueGetters = {
    ---@param emitter ac.FireworksEmitter
    ---@return vec3
    [FIREWORKS_VALUES.Position] = function(emitter)
        return emitter:getPosition()
    end,
    ---@param emitter ac.FireworksEmitter
    ---@return number
    [FIREWORKS_VALUES.Intensity] = function(emitter)
        return emitter:getIntensity()
    end,
    ---@param emitter ac.FireworksEmitter
    ---@return ac.HolidayType
    [FIREWORKS_VALUES.HolidayType] = function(emitter)
        return emitter:getType()
    end,
}

--- Starts fireworks at the specified position.
--- @param position vec3 @The position to start the fireworks.
--- @param intensity number @The intensity of the fireworks.
--- @param holidayType ac.HolidayType @The type of holiday for the fireworks.
--- @return number @The index of the created fireworks emitter.
FireworksManager.startFireworks = function(position, intensity, holidayType)
    local fireworksIndex = nextFireworksIndex
    nextFireworksIndex = nextFireworksIndex + 1

    ---@type ac.FireworksEmitter
    local fireworksEmitter = fireworks.Emitter(position, intensity, holidayType)
    -- fireworksEmitter:initialize()
    createdFireworks[fireworksIndex] = fireworksEmitter

    ac.log(string.format('Started fireworks index %d at position (%.3f, %.3f, %.3f) with intensity %.2f and holiday type %d', fireworksIndex, position.x, position.y, position.z, intensity, holidayType))
    return fireworksIndex
end

---Sets the specified fireworks value
---@param fireworksIndex number @The index of the fireworks emitter.
---@param valueType FIREWORKS_VALUES @The type of value to set.
-- ---@param value any @The value to set.
---@param value vec3|ac.HolidayType|number @The value to set.
---@return boolean
FireworksManager.setFireworksValue = function(fireworksIndex, valueType, value)
    local fireworksEmitter = createdFireworks[fireworksIndex]
    if not fireworksEmitter then
        ac.error(string.format('No fireworks emitter found for index %d', fireworksIndex))
        return false
    end

    local setter = fireworksValueSetters[valueType]
    if not setter then
        ac.log(string.format('No setter found for value type %d', valueType))
        return false
    end

    setter(fireworksEmitter, value)
    return true
end

---Gets the specified fireworks value
---@param fireworksIndex number @The index of the fireworks emitter.
---@param valueType FIREWORKS_VALUES @The type of value to get.
---@return any @The value of the specified type, or nil if not found.
FireworksManager.getFireworksValue = function(fireworksIndex, valueType)
    local fireworksEmitter = createdFireworks[fireworksIndex]
    if not fireworksEmitter then
        -- ac.error(string.format('No fireworks emitter found for index %d', fireworksIndex))
        return nil
    end

    local getter = fireworksValueGetters[valueType]
    if not getter then
        ac.log(string.format('No getter found for value type %d', valueType))
        return nil
    end

    return getter(fireworksEmitter)
end

---Stops the specified fireworks
---WARNING: There's a bug in CSP v0.3.0-preview212 and possibly previous versions where stopping fireworks doesn't work.  Possibly fixed in the future.
---@param fireworksIndex number @The index of the fireworks emitter.
---@return boolean @True if the fireworks emitter was found and stopped, false otherwise.
FireworksManager.stopFireworks = function(fireworksIndex)
    local fireworksEmitter = createdFireworks[fireworksIndex]
    if not fireworksEmitter then
        -- ac.error(string.format('No fireworks emitter found for index %d', fireworksIndex))
        return false
    end

    FireworksManager.setFireworksValue(fireworksIndex, FIREWORKS_VALUES.Intensity, 0)
    fireworksEmitter:dispose()
    createdFireworks[fireworksIndex] = nil

    ac.log(string.format('Stopped fireworks index %d', fireworksIndex))
    return true
end

---Stops all active fireworks
---WARNING: There's a bug in CSP v0.3.0-preview212 and possibly previous versions where stopping fireworks doesn't work.  Possibly fixed in the future.
FireworksManager.stopAllFireworks = function()
    for i = 1, nextFireworksIndex - 1 do
        FireworksManager.stopFireworks(i)
    end
end

return FireworksManager