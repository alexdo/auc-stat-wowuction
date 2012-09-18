--[[
	Auc-Stat-wowuction - WowUction price statistics module

	This is an Auctioneer statistics module that returns price data from 
	TradeSkillMaster_WoWuction addon.  You must have either The Undermine Journal
	or TradeSkillMaster_WoWuction addon installed for this module to have any
	effect.

	Copyright (c) 2011 Johnny C. Lam, 2012 Chris Hennick
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:

	1. Redistributions of source code must retain the above copyright
	   notice, this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
	BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
 --]]
if not AucAdvanced then
--  error("AucAdvanced not found!")
return end

-- register this file with Ace Libraries
local wowuction = select(2, ...)
wowuction = LibStub("AceAddon-3.0"):NewAddon(wowuction, "Auc-Stat-WoWuction", "AceConsole-3.0")

local TSM

local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local libType, libName = "Stat", "WoWuction"
local lib, parent, private = AucAdvanced.NewModule(libType, libName)

if not lib then return end
local aucPrint, decode, _, _, replicate, empty, get, set, default, debugPrint, fill, _TRANS = AucAdvanced.GetModuleLocals()
local GetFaction = AucAdvanced.GetFaction

lib.Processors = {}
lib.Processors.tooltip = function(callbackType, ...)
--	private.ProcessTooltip(...)
end

lib.Processors.config = function(callbackType, gui)
	if private.SetupConfigGui then
		private.SetupConfigGui(gui)
	end
end

lib.Processors.load = function(callbackType, addon)
	-- check that this is our load message, and that our OnLoad function still exists
	if addon == "auc-stat-wowuction" and private.OnLoad then
		private.OnLoad(addon)
	end
end

function lib.GetPrice(hyperlink, serverKey)
	if not get("stat.wowuction.enable") then return end
	local array = lib.GetPriceArray(hyperlink, serverKey)
	return array.latest, array.median, array.mean, array.stddev
end

function lib.GetPriceColumns()
	return "Market Latest", "Market Median", "Market Mean", "Market Std Dev"
end

local array = {}
local seen
function lib.GetPriceArray(hyperlink, serverKey)
	if not get("stat.wowuction.enable") then return end
--	seen = get("stat.wowuction.seen")
	wipe(array)

	-- Required entries (see Stat-Example2)
	array.price = TSM:GetData(hyperlink, "marketValue")
--	array.seen = seen
	array.latest = TSM:GetData(hyperlink, "minBuyout")
	array.median = TSM:GetData(hyperlink, "medianPrice")
	array.mean = array.price
	array.stddev = TSM:GetData(hyperlink, "medianPriceErr") or TSM:GetData(hyperlink, "marketValueErr")
--	array.qty = seen

	return array
end

local bellCurve = AucAdvanced.API.GenerateBellCurve()
local weight
function lib.GetItemPDF(hyperlink, serverKey)
	if not get("stat.wowuction.enable") then return end
	local array = lib.GetPriceArray(hyperlink, serverKey)
	local median = array.median
	local price = array.price
	local stddev = array.stddev
	local priceshock = get("stat.wowuction.detectpriceshocks")
	local stddevshock = get("stat.wowuction.detectstddevshocks")
	if (not price) or (not stddev) then
		return -- no available data
	end
	if median then
		local minpct = get("stat.wowuction.minerrorpct") * .01
		if stddev < median*minpct then stddev = median*minpct end
		local zlimit = get("stat.wowuction.maxz")
		if priceshock or stddevshock then
			local regionMedian = TSM:GetData(hyperlink, "regionMedianPrice")
			local regionStddev = TSM:GetData(hyperlink, "regionMedianPriceErr")
			local regionPrice = TSM:GetData(hyperlink, "regionPrice")
			if regionMedian and regionStddev and regionPrice then 
				local n = get("stat.wowuction.n")
				if regionStddev < regionMedian*minpct then regionStddev = regionMedian * minpct end
				-- use this realm's medianPriceErr and the number of realms to estimate
				-- how much increase of regionMarketPriceErr over regionMedianPriceErr
				-- could be explained by "normal" within-realm fluctuations
				-- (multiplied by regionMedian/median to convert from realm-specific to median-realm coins,
				-- and assuming we're on a representative realm in all other respects)
				local adjustedStddev = sqrt(regionStddev*regionStddev + regionMedian*stddev*stddev/((n-1)*median))
				if stddevshock then
					local regionCurrentStddev = TSM:GetData(hyperlink, "regionMarketPriceErr") or 0
					if regionCurrentStddev > adjustedStddev * zlimit then
						-- stddev-widening shock detected!
						io.write(string.format(_TRANS('WOWUCTION_alert_stddevshock_item_%s_expected_%d_actual_%d'), hyperlink, adjustedStddev, regionCurrentStddev))
						stddev = stddev * regionCurrentStddev / adjustedStddev
					end
				end
				if priceshock then
					local z = (regionPrice - regionMedian)/adjustedStddev
					if (z > zlimit and price > median) or (z < -limit and price < median) then
						-- price shock detected!
						io.write(string.format(_TRANS('WOWUCTION_alert_priceshock_item_%s_Z_%f_expected_%d'), hyperlink, adjustedStddev, z))
						-- median now obsolete, so use latest price
						median = price
						-- check for widened stddev
						local newErr = TSM:GetData(hyperlink, "marketPriceErr")
						if newErr and (newErr > stddev) then
							stddev = newErr
						end
					end
				end
			end
		end
		local z = (price - median)/stddev
		if z > zlimit then
			price = median + zlimit*stddev
		elseif z < -zlimit then
			price = median - zlimit*stddev
		end
		local currWeight = get("stat.wowuction.cur_price_weight")
		median = median * (1 - currWeight) + price * currWeight
	else
		median = price
	end
	-- Calculate the lower and upper bounds as +/- 3 standard deviations
	local lower, upper = (median - 3 * stddev), (median + 3 * stddev)

	bellCurve:SetParameters(median, stddev)
	return bellCurve, lower, upper
end

function lib.IsValidAlgorithm()
	if not get("stat.wowuction.enable") then return false end
	if not private.IswowuctionLoaded() then return false end
	return true
end

function private.OnLoad(addon)
	default("stat.wowuction.enable", false)
--	default("stat.wowuction.seen", 100)
	default("stat.wowuction.cur_price_weight", 0.1)
	default("stat.wowuction.maxz", 2) -- because this parameter is used to effectively apply median-centered Bollinger Bands
	default("stat.wowuction.minerrorpct", 1)
	default("stat.wowuction.detectpriceshocks", true)
	default("stat.wowuction.detectstddevshocks", true)
	default("stat.wowuction.n", 492) -- 2 factions * 246 US realms as of 2012-09-17 (excludes Arena Pass)
	private.OnLoad = nil -- only run this function once
end

function private.GetInfo(hyperlink, serverKey)
	if not private.IswowuctionLoaded() then return end

	local linkType, itemId, suffix, factor = decode(hyperlink)
	if (linkType ~= "item") then return end

	local dta = TSM:GetData(itemId, serverKey)
	return dta
end

-- Localization via Auctioneer's Babylonian; from Auc-Advanced/CoreUtil.lua
local Babylonian = LibStub("Babylonian")
assert(Babylonian, "Babylonian is not installed")
local babylonian = Babylonian(AucStatwowuctionLocalizations)
_TRANS = function (stringKey)
	local locale = get("SelectedLocale")	-- locales are user choose-able
	-- translated key or english Key or Raw Key
	return babylonian(locale, stringKey) or babylonian[stringKey] or stringKey
end

function private.SetupConfigGui(gui)
	local id = gui:AddTab(lib.libName, lib.libType.." Modules")

	gui:AddHelp(id, "what wowuction",
		_TRANS('WOWUCTION_Help_wowuction'),
		_TRANS('WOWUCTION_Help_wowuctionAnswer')
	)

	-- All options in here will be duplicated in the tooltip frame
	local function addTooltipControls(id)
--		gui:AddControl(id, "Header",     0,    _TRANS('TUJ_Interface_wowuctionOptions'))
--		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.enable", _TRANS('WOWUCTION_Interface_Enablewowuction'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_Enablewowuction'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.cur_price_weight", 0, 1, 0.05, _TRANS('WOWUCTION_Interface_CurrentPriceWeight') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_CurrentPriceWeight'))
		gui:AddControl(id, "NumberBox",	0, 1, "stat.wowuction.maxz", 0, 1000, _TRANS('WOWUCTION_Interface_MaxZScore') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_MaxZScore'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.minerrorpct", 0, 10, 0.5, _TRANS('WOWUCTION_Interface_MinErrorPercent') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_MinErrorPercent'))
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.detectpriceshocks", _TRANS('WOWUCTION_Interface_DetectPriceShocks'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_DetectPriceShocks'))
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.detectstddevshocks", _TRANS('WOWUCTION_Interface_DetectStddevShocks'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_DetectStddevShocks'))
		gui:AddControl(id, "NumberBox",	0, 1, "stat.wowuction.n", 0, 1000, _TRANS('WOWUCTION_N') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_N'))

	end

	local tooltipID = AucAdvanced.Settings.Gui.tooltipID

	addTooltipControls(id)
	if tooltipID then addTooltipControls(tooltipID) end

	private.SetupConfigGui = nil -- only run once
end

function private.IswowuctionLoaded()
	TSM = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster_WoWuction")
	return TSM and true or false
end

private.IswowuctionLoaded()