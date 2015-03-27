-- Date Picker example

local composer = require("composer")
local scene = composer.newScene()
local widget = require("widget")
widget.setTheme("widget_theme_ios")
require("datePickerWheel")

---------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE
-- unless "composer.removeScene()" is called.
---------------------------------------------------------------------------------

-- local forward references should go here
local loaded

-- Add widgets to this table so they get removed automatically.
local widgets = {}
local displayText, datePicker

local function validateDate(m, d, y)
	--[[
	If you want to validate that the user chose a date in the past.
	
	Parameters:
		m : int | string
			Month number (not name!)
		d : int | string
			Day
		y : int | string
			Year
	]]
	local time = os.time({year=y, month=m, day=d})
	if time > os.time() then
		native.showAlert("Date Picker", "You cannot choose a date in the future.", {"OK"})
		return false
	end
	return true
end

local function onAccept()
	-- Make sure the scene is fully loaded before we accept button events.
	if not loaded then return true end
	
	local values = datePicker:getValues()
	
	-- CORONA BUG: Sometimes the values can be nil.
	-- This happens when one of the tables stopped scrolling but hasn't "snapped" to a selected index.
	-- Prompt the user to fix the bad column.
	if not values[1] then
		native.showAlert(_M.appName, "Please make sure a month is selected.", {"OK"})
	elseif not values[2] then
		native.showAlert(_M.appName, "Please make sure a day is selected.", {"OK"})
	elseif not values[3] then
		native.showAlert(_M.appName, "Please make sure a year is selected.", {"OK"})
	else
		local valid = validateDate(values[1].index, values[2].value, values[3].value)
		
		-- Do whatever you want with the date now.
		if valid then
			displayText.text = values[1].value .. " " .. values[2].value .. ", " .. values[3].value
		end
	end
	
	return true -- indicates successful touch
end

---------------------------------------------------------------------------------

-- "scene:create()"
function scene:create(event)
	local sceneGroup = self.view
	
	-- Initialize the scene here.
	-- Example: add display objects to "sceneGroup", add touch listeners, etc.
	local okBtn = widget.newButton{
		x=display.contentCenterX,
		y=0,
		onRelease=onAccept,
		label="Accept"
	}
	widgets[#widgets+1] = okBtn
	okBtn.anchorY = 0
	okBtn.x = display.contentCenterX
	okBtn.y = 10
	
	-- Figure out which date to start with.
	local p = event.params or {}
	local currYear = tonumber(p.year or os.date("%Y"))
	local currMonth = tonumber(p.month or os.date("%m"))
	local currDay = tonumber(p.day or os.date("%d"))
	
	-- Create the widget.
	datePicker = widget.newDatePickerWheel(currYear, currMonth, currDay)
	widgets[#widgets+1] = datePicker
	
	-- Position it however you like.
	datePicker.anchorChildren = true
	datePicker.anchorX = 0.5
	datePicker.anchorY = 0
	datePicker.x = okBtn.x
	datePicker.y = okBtn.y + okBtn.height + 10
	
	-- Display the selected date when user presses "Accept"
	displayText = display.newText{
		text = "The Date Picker supports months with different days, and even leap years!",
		width = display.contentWidth - 20,
		font = native.systemFont,
		fontSize = 18,
		align = "center"
	}
	displayText:setFillColor(1)
	displayText.anchorY = 0
	displayText.x = datePicker.x
	displayText.y = datePicker.y + datePicker.height + 10
	
	sceneGroup:insert(okBtn)
	sceneGroup:insert(datePicker)
	sceneGroup:insert(displayText)
end

-- "scene:show()"
function scene:show(event)
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen (but is about to come on screen).
	elseif phase == "did" then
		-- Called when the scene is now on screen.
		-- Insert code here to make the scene come alive.
		-- Example: start timers, begin animation, play audio, etc.
		loaded = true
	end
end

-- "scene:hide()"
function scene:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is on screen (but is about to go off screen).
		-- Insert code here to "pause" the scene.
		-- Example: stop timers, stop animation, stop audio, etc.
		loaded = false
	elseif phase == "did" then
		-- Called immediately after scene goes off screen.
	end
end

-- "scene:destroy()"
function scene:destroy(event)
	local sceneGroup = self.view
	
	-- Called prior to the removal of scene's view ("sceneGroup").
	-- Insert code here to clean up the scene.
	-- Example: remove display objects, save state, etc.
	for i=1, #widgets do
		local w = table.remove(widgets)
		if w then
			w:removeSelf()
			w = nil
		end
	end
	widgets = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

---------------------------------------------------------------------------------

return scene