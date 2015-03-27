--[[
The MIT License (MIT)

Copyright (c) 2015 Mark Sandell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local widget = require("widget")

-- Create tables to hold data for months, days, and years.
local dayCount = {
	31, -- January
	28, -- February
	31, -- March
	30, -- April
	31, -- May
	30, -- June
	31, -- July
	31, -- August
	30, -- September
	31, -- October
	30, -- November
	31, -- December
}

-- Figure out the local month names.
local months = {}
local now = {year=2015, month=1, day=1, isdst=false}
for i=1, 12 do
	now.month = i
	months[i] = os.date("%B", os.time(now))
end

-- Add the last 100 years.
local years = {}
local currYear = tonumber(os.date("%Y")) + 1
for i = 100, 1, -1 do
	years[i] = currYear - i
end

local function isLeapYear(year)
	--[[
	:Parameters:
		year : int
			Year
	:Returns:
		If the given year is a leap year
	:Rtype:
		boolean
	]]
	if 0 == year % 4 then
		if 0 == year % 100 then
			if 0 == year % 400 then
				return true
			else
				return false
			end
		else
			return true
		end
	else
		return false
	end
end

local function daysInMonth(month, year)
	--[[
	:Parameters:
		month : int
			Number of month
		year : int
			Year, used to calculate leap years
	:Returns
		Number of days in the given month for the given year
	:Rtype:
		int
	]]
	if year and month == 2 and isLeapYear(year) then
		return 29
	end
	return dayCount[month]
end

local function daysTable(month, year)
	--[[
	:Parameters:
		month : int
			Number of month
		year : int
			Year, used to calculate leap years
	:Returns:
		A table of day numbers based on the given month and year. (e.g. {1,2,3,...,31})
	]]
	local t = {}
	for i=1, daysInMonth(month, year) do
		t[#t+1] = i
	end
	return t
end

local function newWheel(year, month, day)
	--[[
	Does not support years in the future. Only goes back 100 years.
	These should be easy to adjust if needed.
	
	:Parameters:
		year : int
			Selected year
		month :int
			Selected month (1-12)
		day : int
			Selected day
	]]
	local columnData = {
		{ -- Months
			align = "right",
			width = 140,
			startIndex = month,
			labels = months
		},
		{ -- Days
			align = "center",
			width = 60,
			startIndex = day,
			labels = daysTable(month, year)
		},
		{ -- Years
			align = "center",
			width = 80,
			startIndex = currYear - year,
			labels = years
		}
	}
	return widget.newPickerWheel{columns = columnData}
end

function widget.newDatePickerWheel(year, month, day)
	year  = year  or tonumber(os.date("%Y"))
	month = month or tonumber(os.date("%m"))
	day   = day   or tonumber(os.date("%d"))
	
	local w = display.newGroup()
	
	w.wheel = newWheel(year, month, day)
	w:insert(w.wheel)
	
	function w:getValues()
		return self.wheel:getValues()
	end
	
	-- NOTE: If day or year column are still scrolling when month column changes, those will
	-- snap back to their original selection.
	function w:monitor()
		-- Get selections from the picker wheel.
		local values = self:getValues()
		-- CORONA BUG: Sometimes the values can be nil.
		-- This happens when one of the tables stopped scrolling but hasn't "snapped" to a selected index.
		if not values[1] or not values[2] or not values[3] then return end
		
		local month = values[1].index
		local year = tonumber(values[3].value)
		local maxDays = daysInMonth(month, year)
		
		-- If the selected month has changed and the month has a different number of days than
		-- before, or the selected month is February and the year changes to/from a leap year,
		-- then redraw the picker wheel.
		if (month ~= self.selectedMonth and maxDays ~= daysInMonth(self.selectedMonth, year)) or
		   (month == 2 and year ~= self.selectedYear and isLeapYear(year) ~= isLeapYear(self.selectedYear)) then
			-- Make sure we no longer have a day selected greater than the number of days in
			-- the current month.
			local day = math.min(values[2].index, maxDays)
			
			-- Remove the old wheel.
			self.wheel:removeSelf()
			
			-- Create the new wheel.
			self.wheel = newWheel(year, month, day)
			self:insert(self.wheel)
			
			-- Save the current selection so we can tell if it changes.
			self.selectedMonth = month
			self.selectedYear = year
		end
	end
	
	function w:finalize(event)
		timer.cancel(self.timer)
		self.timer = nil
		self.wheel:removeSelf()
		self.wheel = nil
	end
	
	w:addEventListener("finalize")
	
	-- Monitor for changes roughly 30 times per second.
	w.timer = timer.performWithDelay(33, function() w:monitor() end, -1)
	
	return w
end