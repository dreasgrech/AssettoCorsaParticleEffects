local ui_colorButton = ui.colorButton
local ui_itemHovered = ui.itemHovered
local ui_setTooltip = ui.setTooltip
local ui_sameLine = ui.sameLine
local ui_text = ui.text
local ui_pushItemWidth = ui.pushItemWidth
local ui_popItemWidth = ui.popItemWidth
local ui_slider = ui.slider
local ui_MouseButton = ui.MouseButton
local ui_pushID = ui.pushID
local ui_popID = ui.popID
local ui_pushDisabled = ui.pushDisabled
local ui_popDisabled = ui.popDisabled
local ui_checkbox = ui.checkbox
local ui_newLine = ui.newLine
local ui_button = ui.button
local ui_itemClicked = ui.itemClicked
local ui_pushStyleColor = ui.pushStyleColor
local ui_popStyleColor = ui.popStyleColor
local ui_styleColor = ui.styleColor
local ui_StyleColor = ui.StyleColor
local ui_mouseBusy = ui.mouseBusy
local ui_mouseClicked = ui.mouseClicked
local string_format = string.format
local render_isPositioningHelperBusy = render.isPositioningHelperBusy
local render_createMouseRay = render.createMouseRay

local UIOperations = {}

local emptyVec3 = vec3(0, 0, 0)

UIOperations.DEFAULT_UI_COMPONENT_COLORS = {
    sliderGrab = ui_styleColor(ui_StyleColor.SliderGrab),
    -- text = ui_styleColor(ui_StyleColor.Text), -- Andreas: for some reason, this returns black instead of white so I'm hardcoding it below
    text = rgbm.colors.white
}

ac.log(UIOperations.DEFAULT_UI_COMPONENT_COLORS.text)
ac.log(UIOperations.DEFAULT_UI_COMPONENT_COLORS.sliderGrab)

local setTooltip = function(tooltip)
    if ui_itemHovered() then
        -- render the tooltip
        ui_pushStyleColor(ui_StyleColor.Text, UIOperations.DEFAULT_UI_COMPONENT_COLORS.text) -- make sure that the tooltip text is in default color
        ui_setTooltip(tooltip)
        ui_popStyleColor()
    end
end
UIOperations.setTooltip = setTooltip

---Color button control. Returns true if color has changed (as usual with Lua, colors are passed)
---by reference so update value would be put in place of old one automatically.
---@param label string
---@param color rgbm
---@param flags ui.ColorPickerFlags?
---@param size vec2?
---@return rgbm
UIOperations.renderColorPicker = function(label, tooltip, color, flags, size)
    ui_colorButton(label, color, flags, size)
    setTooltip(tooltip)

    ui_sameLine()
    ui_text(label)

    return color
end


-- UIOperations.renderButton = function(label, tooltip, width, height)
UIOperations.renderButton = function(label, tooltip, rightClickCallback)
    -- ui_pushItemWidth(width)
    -- local clicked = ui_button(label, vec2(width, height))
    -- ui_popItemWidth()
    local clicked = ui_button(label)
    setTooltip(tooltip)

    if rightClickCallback ~= nil then
        if ui_itemClicked(ui_MouseButton.Right, true) then
            rightClickCallback()
        end
    end

    return clicked
end

---Used to render a button with custom colors.
---This function is meant to be called with a callback that renders the button itself.
--- 
---Example:
-- if UIOperations.renderColorButton(
--      normalColor, hoveredColor, activeColor, textColor,
--      function()
--          return UIOperations.renderButton(buttonText, toolTipText)
--      end
-- ) 
-- then
--      -- Button was clicked
-- end
---@param backColor rgbm @Background color of the button.
---@param backHoveredColor rgbm @Background color of the button when hovered.
---@param backActiveColor rgbm @Background color of the button when active (pressed).
---@param textColor rgbm @Text color of the button.
---@param renderButtonCallback function @A callback function which should render the button and return whether it was clicked.
---@return boolean @Whether the button was clicked.
UIOperations.renderColorButton = function(backColor, backHoveredColor, backActiveColor, textColor, renderButtonCallback)
  ui_pushStyleColor(ui_StyleColor.Button, backColor)
  ui_pushStyleColor(ui_StyleColor.ButtonHovered, backHoveredColor)
  ui_pushStyleColor(ui_StyleColor.ButtonActive, backActiveColor)
  ui_pushStyleColor(ui_StyleColor.Text, textColor)

  -- render the button
  local buttonResult = renderButtonCallback()

  ui_popStyleColor(4) -- 4 styles

  return buttonResult
end

---Tries to get world position from mouse click.
---@return boolean hit @Whether a valid world position was found.
---@return vec3 out_worldPosition @The world position if hit is true.
UIOperations.tryGetWorldPositionFromMouseClick = function()
    -- Avoid conflicts if you’re using CSP’s gizmo/positioning helper
    if render_isPositioningHelperBusy() then return false, emptyVec3 end

    -- Only act on a left-click (and avoid UI clicks)
    if ui_mouseBusy() then return false, emptyVec3 end
    if not ui_mouseClicked(ui.MouseButton.Left) then return false, emptyVec3 end

    local ray = render_createMouseRay()

    -- Option A: intersect visual track mesh
    local hitDistance = ray:track(1)
    if hitDistance >= 0 then
        local out_worldPosition = ray.pos + ray.dir * hitDistance
        -- ac.log(string_format('[UIOperations] Track hit at distance %.2f, world position: (%.2f, %.2f, %.2f)', hitDistance, out_worldPosition.x, out_worldPosition.y, out_worldPosition.z))
        return true, out_worldPosition
    end

    -- Option B: intersect physics meshes (also gives normal if you pass out params)
    local outPos = vec3()
    local outNormal = vec3()
    local physDistance = ray:physics(outPos, outNormal)
    if physDistance >= 0 then
        -- outPos already contains the contact point
        local out_worldPosition = outPos
        -- ac.log(string_format('[UIOperations] Physics hit at distance %.2f, world position: (%.2f, %.2f, %.2f)', physDistance, out_worldPosition.x, out_worldPosition.y, out_worldPosition.z))
        return true, out_worldPosition
    end

    return false, emptyVec3
end

---Renders a slider with a tooltip
---@param label string @Slider label.
---@param tooltip string|nil @Tooltip text.
---@param value refnumber|number @Current slider value.
---@param minValue number? @Default value: 0.
---@param maxValue number? @Default value: 1.
---@param sliderWidth number
---@param labelFormat string|'%.3f'|nil @C-style format string. Default value: `'%.3f'`.
---@param defaultValue number @The default value to reset to on right-click and is shown in the tooltip.
---@return number @Possibly updated slider value.
UIOperations.renderSlider = function(label, tooltip, value, minValue, maxValue, sliderWidth, labelFormat, defaultValue)
    -- set the width of the slider
    ui_pushItemWidth(sliderWidth)

    -- render the slider
    -- Andreas: doing the ' ' .. label thing here because when writing a label after the slider manually, there's an extra space so here I'm adding an extra space so they can match
    --local newValue = ui_slider(' ' .. label, value, minValue, maxValue, labelFormat)
    local newValue = ui_slider(label, value, minValue, maxValue, labelFormat)

    -- reset the item width
    ui_popItemWidth()

    setTooltip(string_format('%s%sDefault: %.2f', tooltip, tooltip ~= '' and '\n\n' or '', defaultValue))

    -- reset the slider to default value on right-click
    if ui_mouseClicked(ui_MouseButton.Right) then
        newValue = defaultValue
    end

    return newValue
end

UIOperations.renderCheckbox = function(label, tooltip, value, defaultValue)
    if ui_checkbox(label, value) then
        value = not value
    end
    setTooltip(string_format('%s\n\nDefault: %s', tooltip, tostring(defaultValue)))
    
    return value
end

---Renders vec3 sliders
---@param label string @Slider label.
---@param value vec3 @Current vec3 value.
---@param minValue number @Minimum slider value.
---@param maxValue number @Maximum slider value.
---@param format string|'X: %.3f'|'Y: %.3f'|'Z: %.3f'|nil @C-style format string. Default value: `'X: %.3f'`, `'Y: %.3f'`, `'Z: %.3f'
---@param xSliderGrabColor rgbm|nil @Optional custom color for the X slider grab.
---@param ySliderGrabColor rgbm|nil @Optional custom color for the Y slider grab.
---@param zSliderGrabColor rgbm|nil @Optional custom color for the Z slider grab.
---@return vec3 newValue
UIOperations.renderVec3Sliders = function(label, value, minValue, maxValue, format, xSliderGrabColor, ySliderGrabColor, zSliderGrabColor)
    ui_pushID(label)


    local xGrabColor = xSliderGrabColor or UIOperations.DEFAULT_UI_COMPONENT_COLORS.sliderGrab
    ui_pushStyleColor(ui_StyleColor.SliderGrab, xGrabColor)
    local x = UIOperations.renderSlider('##x', '', value.x, minValue, maxValue, 350, format or 'X: %.3f', 0)
    ui_popStyleColor()

    --ui_sameLine()

    local yGrabColor = ySliderGrabColor or UIOperations.DEFAULT_UI_COMPONENT_COLORS.sliderGrab
    ui_pushStyleColor(ui_StyleColor.SliderGrab, yGrabColor)
    local y = UIOperations.renderSlider('##y', '', value.y, minValue, maxValue, 350, format or 'Y: %.3f', 0)
    ui_popStyleColor()

    --ui_sameLine()

    local zGrabColor = zSliderGrabColor or UIOperations.DEFAULT_UI_COMPONENT_COLORS.sliderGrab
    ui_pushStyleColor(ui_StyleColor.SliderGrab, zGrabColor)
    local z = UIOperations.renderSlider('##z', '', value.z, minValue, maxValue, 350, format or 'Z: %.3f', 0)
    ui_popStyleColor()

    ui_popID()

    return vec3(x, y, z)
end

--- Creates a disabled section in the UI.
---@param createSection boolean @If true, will create a disabled section.
---@param callback function @Function to call to render the contents of the section.
UIOperations.createDisabledSection = function(createSection, callback)
    if createSection then
        ui_pushDisabled()
    end

    callback()

    if createSection then
        ui_popDisabled()
    end
end

UIOperations.newLine = function(total)
    total = total or 1
    for i = 1, total do
        ui_newLine(1)
    end
end

return UIOperations