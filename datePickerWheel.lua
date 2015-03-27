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
	["January"]   = 31,
	["February"]  = 28,
	["March"]     = 31,
	["April"]     = 30,
	["May"]       = 31,
	["June"]      = 30,
	["July"]      = 31,
	["August"]    = 31,
	["September"] = 30,
	["October"]   = 31,
	["November"]  = 30,
	["December"]  = 31
}
local months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

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
		month : string
			Name of month
		year : int
			Year, used to calculate leap years
	:Returns
		Number of days in the given month for the given year
	:Rtype:
		int
	]]
	if year and month == "February" and isLeapYear(year) then
		return 29
	end
	return dayCount[month]
end

local function daysTable(month, year)
	--[[
	:Parameters:
		month : string
			Name of month
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
			labels = daysTable(months[month], year)
		},
		{ -- Years
			align = "center",
			width = 80,
			startIndex = tonumber(os.date("%Y")) + 1 - year,
			labels = years
		}
	}
	return widget.newPickerWheel{columns = columnData}
end

function widget.newDatePickerWheel(year, month, day)
	year = year or tonumber(os.date("%Y"))
	month = month or tonumber(os.date("%m"))
	day = day or tonumber(os.date("%d"))
	
	local w = display.newGroup()
	
	w.selectedMonth = nil
	w.selectedYear = nil
	w.wheel = newWheel(year, month, day)
	w:insert(w.wheel)
	
	function w.finalize(event)
		print("Finalize Event Dispatched!")
		Runtime:removeEventListener("enterFrame", w)
	end
	
	function w.getValues()
		return w.wheel:getValues()
	end
	
	-- NOTE: If day or year column are still scrolling when month column changes, those will
	-- snap back to their original selection.
	function w.enterFrame(self)
		-- Get selections from the picker wheel.
		local values = self:getValues()
		-- CORONA BUG: Sometimes the values can be nil.
		-- This happens when one of the tables stopped scrolling but hasn't "snapped" to a selected index.
		if not values[1] or not values[2] or not values[3] then return end
		
		local month = values[1].index
		local year = tonumber(values[3].value)
		local maxDays = daysInMonth(months[month], year)
		
		-- If the selected month has changed and the month has a different number of days than
		-- before, or the selected month is February and the year changes to/from a leap year,
		-- then redraw the picker wheel.
		if (month ~= self.selectedMonth and maxDays ~= daysInMonth(months[self.selectedMonth], year)) or
		   (month == 2 and year ~= self.selectedYear and isLeapYear(year) ~= isLeapYear(self.selectedYear)) then
			-- Make sure we no longer have a day selected greater than the number of days in
			-- the current month.
			local day = math.min(values[2].index, maxDays)
			
			-- Remove the old widget.
			self.wheel:removeSelf()
			
			-- Create the new wheel.
			self.wheel = newWheel(year, month, day)
			self:insert(self.wheel)
			
			-- Save the current selection so we can tell if it changes.
			self.selectedMonth = month
			self.selectedYear = year
		end
	end
	
	return w
end