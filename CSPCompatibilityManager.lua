--- Responsible for checking if required CSP elements (functions, fields, enums, etc...) are available in the current CSP version.
--- When making use of a CSP element that was added in a specific CSP version, it is recommended to add it to the list of used elements here
--- so that we can check for its existence at runtime
--- Author: dreasgrech
local CSPCompatibilityManager = {}

local LOG_MISSING_ELEMENTS_WHILE_CHECKING = false
local ADD_NON_EXISTANT_FUNCTIONS_TO_TEST_MISSING = false

---@class TableForUsedElement
---@field elementFn function
---@field name string

--- Creates a table for metadata of a used CSP element
---@param elementFn function
---@param elementName string
---@return TableForUsedElement
local getTableForUsedElement = function(elementFn, elementName)
    return {
        name = elementName,
        elementFn = elementFn
    }
end

---Returns the current version of Custom Shaders Patch
---@return string
local getCSPVersion = function()
    local getPatchVersionFn = ac.getPatchVersion
    if not getPatchVersionFn then
        return "Unknown"
    end

    local versionStr = getPatchVersionFn()
    return string.format("v%s", versionStr)
end

--- Checks for missing CSP elements (functions, fields, enums, etc...) used in the app
--- @return table<string> @List of missing element names
local checkForMissingCSPElements = function()
    -- bindings (need to be in here for this class since we need to check for their existence)
    local ac = ac
    local ui = ui
    -- local physics = physics

    ---@type table<TableForUsedElement>
    local usedACElements = {
        getTableForUsedElement(function() return ac.log end, "ac.log"),
        getTableForUsedElement(function() return ac.warn end, "ac.warn"),
        getTableForUsedElement(function() return ac.error end, "ac.error"),
        getTableForUsedElement(function() return ac.getSim end, "ac.getSim"),
        getTableForUsedElement(function() return ac.storage end, "ac.storage"),
        getTableForUsedElement(function() return ac.setWindowOpen end, "ac.setWindowOpen"),
    }

    ---@type table<TableForUsedElement>
    local usedUIElements = {
        getTableForUsedElement(function() return ui.button end, "ui.button"),
        getTableForUsedElement(function() return ui.newLine end, "ui.newLine"),
        getTableForUsedElement(function() return ui.text end, "ui.text"),
        getTableForUsedElement(function() return ui.pushItemWidth end, "ui.pushItemWidth"),
        getTableForUsedElement(function() return ui.popItemWidth end, "ui.popItemWidth"),
        getTableForUsedElement(function() return ui.itemHovered end, "ui.itemHovered"),
        getTableForUsedElement(function() return ui.setTooltip end, "ui.setTooltip"),
        getTableForUsedElement(function() return ui.pushDisabled end, "ui.pushDisabled"),
        getTableForUsedElement(function() return ui.popDisabled end, "ui.popDisabled"),
        getTableForUsedElement(function() return ui.columns end, "ui.columns"),
        getTableForUsedElement(function() return ui.ButtonFlags end, "ui.buttonFlags"),
        getTableForUsedElement(function() return ui.pushStyleColor end, "ui.pushStyleColor"),
        getTableForUsedElement(function() return ui.popStyleColor end, "ui.popStyleColor"),
        getTableForUsedElement(function() return ui.textColored end, "ui.textColored"),
        getTableForUsedElement(function() return ui.setColumnWidth end, "ui.setColumnWidth"),
        getTableForUsedElement(function() return ui.separator end, "ui.separator"),
        getTableForUsedElement(function() return ui.nextColumn end, "ui.nextColumn"),
        getTableForUsedElement(function() return ui.pushID end, "ui.pushID"),
        getTableForUsedElement(function() return ui.popID end, "ui.popID"),
        getTableForUsedElement(function() return ui.itemClicked end, "ui.itemClicked"),
        getTableForUsedElement(function() return ui.sameLine end, "ui.sameLine"),
        getTableForUsedElement(function() return ui.slider end, "ui.slider"),
        getTableForUsedElement(function() return ui.dwriteText end, "ui.dwriteText"),
        getTableForUsedElement(function() return ui.checkbox end, "ui.checkbox"),
        getTableForUsedElement(function() return ui.MouseButton end, "ui.MouseButton"),
        getTableForUsedElement(function() return ui.mouseClicked end, "ui.mouseClicked"),
        getTableForUsedElement(function() return ui.alignTextToFramePadding end, "ui.alignTextToFramePadding"),
        getTableForUsedElement(function() return ui.setMouseCursor end, "ui.setMouseCursor"),
        getTableForUsedElement(function() return ui.styleColor end, "ui.styleColor"),
        getTableForUsedElement(function() return ui.StyleColor end, "ui.StyleColor"),
    }

    -- ---@type table<TableForUsedElement>
    -- local usedPhysicsElements = {
    --     getTableForUsedElement(function() return physics.overrideRacingFlag end, "physics.overrideRacingFlag"),
    --     getTableForUsedElement(function() return physics.setAIThrottleLimit end, "physics.setAIThrottleLimit"),
    --     getTableForUsedElement(function() return physics.setAITopSpeed end, "physics.setAITopSpeed"),
    --     getTableForUsedElement(function() return physics.setAICaution end, "physics.setAICaution"),
    --     getTableForUsedElement(function() return physics.setAIAggression end, "physics.setAIAggression"),
    --     getTableForUsedElement(function() return physics.setAIStopCounter end, "physics.setAIStopCounter"),
    --     getTableForUsedElement(function() return physics.setExtraAIGrip end, "physics.setExtraAIGrip"),
    --     getTableForUsedElement(function() return physics.disableCarCollisions end, "physics.disableCarCollisions"),
    --     getTableForUsedElement(function() return physics.setGentleStop end, "physics.setGentleStop"),
    --     getTableForUsedElement(function() return physics.preventAIFromRetiring end, "physics.preventAIFromRetiring"),
    --     getTableForUsedElement(function() return physics.setAISplineOffset end, "physics.setAISplineOffset"),
    --     getTableForUsedElement(function() return physics.overrideRacingFlag end, "physics.overrideRacingFlag"),
    --     -- getTableForUsedElement(function() return physics.setEngineStallEnabled end, "physics.setEngineStallEnabled"),
    --     -- getTableForUsedElement(function() return physics.setCarPosition end, "physics.setCarPosition"),
    --     -- getTableForUsedElement(function() return physics.setCarFuel end, "physics.setCarFuel"),
    --     -- getTableForUsedElement(function() return physics.engageGear end, "physics.engageGear"),
    --     -- getTableForUsedElement(function() return physics.setEngineRPM end, "physics.setEngineRPM"),
    --     -- getTableForUsedElement(function() return physics.awakeCar end, "physics.awakeCar"),
    --     -- getTableForUsedElement(function() return physics.setAINoInput end, "physics.setAINoInput"),
    -- }

    -- Make sure we have access to the ac.getSim or ac.getSimState functions!
    ---@type table<TableForUsedElement>
    local usedAcStateSimElements
    ---@diagnostic disable-next-line: deprecated -- ac.getSimState is deprecated but we need to check for it here for backwards compatibility
    local simStateFn = ac.getSim or ac.getSimState
    local simStateFnAvailable, sim = pcall(function() return simStateFn() end)
    if simStateFnAvailable then
        usedAcStateSimElements = {
            getTableForUsedElement(function() return sim.trackLengthM end, "ac.getSim().trackLengthM"),
            getTableForUsedElement(function() return sim.raceSessionType end, "ac.getSim().raceSessionType"),
        }
    end

    -- For testing: add some non-existant functions to see if the missing check works
    if ADD_NON_EXISTANT_FUNCTIONS_TO_TEST_MISSING then
        table.insert(usedACElements, getTableForUsedElement(function() return ac.nonExistantFunction end, "ac.nonExistantFunction"))
        table.insert(usedUIElements, getTableForUsedElement(function() return ui.nonExistantFunction end, "ui.nonExistantFunction"))
        -- table.insert(usedPhysicsElements, getTableForUsedElement(function() return physics.nonExistantFunction end, "physics.nonExistantFunction"))
        if simStateFnAvailable then
            table.insert(usedAcStateSimElements, getTableForUsedElement(function() return sim.nonExistantFunction end, "ac.getSim().nonExistantFunction"))
        end
    end

    ---Goes through the list of used elements and checks if any are not available
    ---@param elements table<TableForUsedElement>
    ---@param missingElementsNames table<string>
    ---@param namespace string
    local checkMissingElements = function(elements, missingElementsNames, namespace)
        for _, usedElement in ipairs(elements) do
            local elementFn = usedElement.elementFn
            -- using pcall here to catch any errors that may occur when calling the function that retrieves the element, which is an indication that the element is missing
            local success, result = pcall(function()
                local elementFnValue = elementFn()
                return elementFnValue ~= nil
            end)

            if
                not success or  -- if success is false, there was an error calling the function, so the element is missing
                result == false -- if result is false, the element is nil, so it's missing
            then
                -- add the missing element name metadata to the list of missing elements
                table.insert(missingElementsNames, usedElement.name)
                if LOG_MISSING_ELEMENTS_WHILE_CHECKING then ac.log(string.format("[CSPCompatibilityManager] %s function '%s' is not available (nil)", namespace, usedElement.name)) end
            end
        end
    end

    ---@type table<string>
    local missingElementsNames = {}

    -- Check for missing elements in ac
    checkMissingElements(usedACElements, missingElementsNames, "ac")

    -- Check for missing elements in ui
    checkMissingElements(usedUIElements, missingElementsNames, "ui")

    -- -- Check for missing elements in physics
    -- checkMissingElements(usedPhysicsElements, missingElementsNames, "physics")

    -- Check for missing elements in ac.getSim()
    if simStateFnAvailable then
        checkMissingElements(usedAcStateSimElements, missingElementsNames, "ac.getSim()")
    end

    return missingElementsNames
end

local showMissingCSPElementsErrorModalDialog = function(appName, message)
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

  ui.modalDialog(string.format('[Error] Missing CSP elements needed to run the %s app', appName), function()
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

CSPCompatibilityManager.checkAndAlert = function(appName, appVersion)
    local cspVersion = getCSPVersion()
    ac.log(string.format("[CSPCompatibilityManager] Checking %s v%s.  Custom Shaders Patch: %s", appName, appVersion, cspVersion))

    -- Check if any CSP elements used by the app are missing
    local missingCSPElements = checkForMissingCSPElements()
    local anyMissingCSPElements = (#missingCSPElements > 0)
    local missingCSPElementsErrorMessage

    -- Show an error modal dialog if any CSP elements are missing
    if anyMissingCSPElements then
        -- Build the CSP missing elements error message
        missingCSPElementsErrorMessage = string.format("%s may not run as expected because some required Custom Shaders Patch elements are missing.", appName)
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
        showMissingCSPElementsErrorModalDialog(appName, missingCSPElementsErrorMessage)
    end

    return not anyMissingCSPElements
end

return CSPCompatibilityManager