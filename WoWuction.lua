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
	array.stddev = TSM:GetData(hyperlink, "marketValueErr")
--	array.qty = seen

	return array
end

local bellCurve = AucAdvanced.API.GenerateBellCurve()
local weight
function lib.GetItemPDF(hyperlink, serverKey)
	if not get("stat.wowuction.enable") then return end
	local mean = TSM:GetData(hyperlink, "marketValue")
	local stddev = TSM:GetData(hyperlink, "marketValueErr")
	if (not mean) or (not stddev) then
		return -- no available data
	end

	-- Calculate the lower and upper bounds as +/- 3 standard deviations
	local lower, upper = (mean - 3 * stddev), (mean + 3 * stddev)

	bellCurve:SetParameters(mean, stddev)
	return bellCurve, lower, upper
end

function lib.IsValidAlgorithm()
	if not get("stat.wowuction.enable") then return false end
	if not private.IswowuctionLoaded() then return false end
	return true
end

function private.OnLoad(addon)
	default("stat.wowuction.enable", false)
	default("stat.wowuction.seen", 100)
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
--		gui:AddControl(id, "NumberBox",	0, 1, "stat.wowuction.seen", 0, 1000, 1, _TRANS('WOWUCTION_Interface_Seen') )--Weight for cross-realm data: %d %%
--		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_Seen')) -- count regionwide data as this many points
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