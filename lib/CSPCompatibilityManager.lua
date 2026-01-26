--- Responsible for checking if required CSP elements (functions, fields, enums, etc...) are available in the current CSP version.
--- When making use of a CSP element that was added in a specific CSP version, it is recommended to add it to the list of used elements here
--- so that we can check for its existence at runtime
--- Author: https://github.com/dreasgrech
local CSPCompatibilityManager = {}

---@class TableForUsedElement
---@field elementFn function
---@field name string

local LOG_MISSING_ELEMENTS_WHILE_CHECKING = false
local ADD_NON_EXISTANT_FUNCTIONS_TO_TEST_MISSING = false
--local ADD_NON_EXISTANT_FUNCTIONS_TO_TEST_MISSING = true

-- capture ac.getSim() here
---@diagnostic disable-next-line: deprecated -- ac.getSimState is deprecated but we need to check for it here for backwards compatibility
local simStateFn = ac.getSim or ac.getSimState
local simStateFnAvailable, ac_sim = pcall(function() return simStateFn() end)

--- The collection used to store metadata of CSP elements set by the caller
---@type table<TableForUsedElement>
local usedElements = {}

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

---Goes through the caller-supplied list of functions and determine which functions don't exist in the current CSP version
---@return table<string> @A list of names of missing CSP elements
local checkForMissingCSPElements = function()
    -- For testing: add some non-existant functions to see if the missing check works
    if ADD_NON_EXISTANT_FUNCTIONS_TO_TEST_MISSING then
        CSPCompatibilityManager.addFunction(function() return ac.nonExistantFunction end, "ac.nonExistantFunction")
        CSPCompatibilityManager.addFunction(function() return ui.nonExistantFunction end, "ui.nonExistantFunction")
        if simStateFnAvailable then
            ---@diagnostic disable-next-line: undefined-field -- Doing this here to disable to warning on the following non-existant function
            CSPCompatibilityManager.addSimStateFunction(function(sim) return sim.nonExistantFunction end, "ac.getSim().nonExistantFunction")
        end
    end

    -- Check for the missing elements that were added by the user
    ---@type table<string>
    local missingElementsNames = {}

    for _, usedElement in ipairs(usedElements) do
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
            if LOG_MISSING_ELEMENTS_WHILE_CHECKING then
                ac.log(string.format("[CSPCompatibilityManager] function '%s' is not available (nil)", usedElement.name))
            end
        end
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

---Add a function to be checked for existence in Custom Shaders Patch (CSP)
---@param fn function @The function that retrieves the CSP element to be checked
---@param name string @The name of the CSP element (for logging purposes)
CSPCompatibilityManager.addFunction = function(fn, name)
    local tableForUsedElement = getTableForUsedElement(fn, name)
    table.insert(usedElements, tableForUsedElement)
end

---Add a function that takes ac.getSim() as a parameter to be checked for existence in Custom Shaders Patch (CSP)
---@param fn fun(sim: ac.StateSim): any @The function that takes ac.getSim() as a parameter and retrieves the CSP element to be checked
---@param name string @The name of the CSP element (for logging purposes)
CSPCompatibilityManager.addSimStateFunction = function(fn, name)
    CSPCompatibilityManager.addFunction(function()
        return fn(ac_sim)
    end, name)
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