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
function lib.GetPriceArray(id, serverKey)
	if not get("stat.wowuction.enable") then return end
	seen = get("stat.wowuction.seen")
	wipe(array)
--	local _, _, _, _, id = hyperlink:find("|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	-- Required entries (see Stat-Example2)
	array.price = TSM:GetData(id, "medianPrice")
	array.seen = seen
	array.latest = TSM:GetData(id, "minBuyout")
	array.market = TSM:GetData(id, "marketValue")
	array.median = array.price
	array.stddev = TSM:GetData(id, "medianPriceErr")
	array.cstddev = TSM:GetData(id, "marketValueErr")
	array.region_median = TSM:GetData(id, "regionMedianPrice")
	array.region_stddev = TSM:GetData(id, "regionMedianPriceErr")
	array.region_price = TSM:GetData(id, "regionMarketValue")
	array.region_cstddev = TSM:GetData(id, "regionMarketValueErr") or 0
	array.qty = seen

	return array
end

local bellCurve = AucAdvanced.API.GenerateBellCurve()
local weight, median, stddev
local pdfcache = {} -- FIXME: should be cleared when settings change
local n
function lib.GetItemPDF(hyperlink, serverKey)
	if not get("stat.wowuction.enable") then return end
--	if pdfcache[hyperlink] then
--		median = pdfcache[hyperlink]["median"]
--		stddev = pdfcache[hyperlink]["stddev"]
--	else
	n = get("stat.wowuction.n")
	local currWeight = get("stat.wowuction.projection") / 7 - 1
	-- 0 = -7 days = 0% current value, 100% 14-day median
	-- 1 = +0 days = 100% current value, 0% median
	-- 2 = +7 days = 200% current value, -100% median
	local array = lib.GetPriceArray(hyperlink, serverKey)
	local currPrice = array.market
	local median = array.median
	local currStddev = array.cstddev
	local stddev = array.stddev
	local projectedPrice, projectedStddev, regionProjectedPrice, regionProjectedStddev
	local regionCurrPrice = array.region_price
	local regionMedian = array.region_median
	local regionFallback = get("stat.wowuction.regionfallback")
	local confidence = get("stat.wowuction.confidence")
	local regionResidual = regionCurrStddev or regionStddev or nil
	local residual = currStddev or stddev or nil
	if regionStddev and regionCurrStddev then
		regionProjectedStddev = regionStddev * (1 - currWeight) + regionCurrStddev * currWeight
	else
		regionProjectedStddev = regionResidual
	end
	if currStddev and stddev then
		projectedStddev = stddev * (1 - currWeight) + currStddev * currWeight
	else
		projectedStddev = residual
		if not projectedStddev then
			if regionFallback and regionProjectedStddev then
				local n = get("stat.wowuction.n")
				projectedStddev = regionProjectedStddev * sqrt(n - 1) -- conservative estimate: region is a larger sample than realm
				residual = regionResidual * sqrt(n - 1)
			else
				return -- no stddev
			end
		end
	end
	if regionCurrPrice and regionMedian then
		regionProjectedPrice = regionCurrPrice * currWeight + regionMedian * (1 - currWeight)
	else
		regionProjectedPrice = regionCurrPrice or regionMedian or nil
	end
	if currPrice and median then
		local adjCurrWeight
		local regionAgreement = get("stat.wowuction.regionagreement")
		if regionCurrPrice and regionMedian and regionProjectedStddev and regionAgreement then
			-- estimate total variance and covariance of realm and region price time-series
			-- assumes uncorrelated residuals (probably errs on the side of smaller adjustment)
			local totalVariance = sqrt((residual^2 + (currPrice - median)^2/3)*(regionResidual^2 + (regionCurrPrice - median)^2/3))
			local covar = (regionCurrPrice - regionMedian)*(currPrice - median)/totalVariance
			adjCurrWeight = currWeight * (1 + covar * regionAgreement)
		else
			adjCurrWeight = currWeight
		end
		projectedPrice = currPrice * adjCurrWeight + median * (1 - adjCurrWeight)
	else 
		projectedPrice = currPrice or median or nil
		if not projectedPrice then
			if regionFallback and regionProjectedPrice then
				projectedPrice = regionProjectedPrice
				confidence = get("stat.wowuction.fallbackconfidence")
			else
				return -- no price
			end
		end
	end
	local minErrorPct = get("stat.wowuction.minerrorpct")
	projectedStddev = math.max(projectedStddev, minErrorPct * projectedPrice) / confidence
	-- Calculate the lower and upper bounds as +/- 3 standard deviations
	local lower, upper = (projectedPrice - 3 * projectedStddev), (projectedPrice + 3 * projectedStddev)
	bellCurve:SetParameters(projectedPrice, projectedStddev)
	return bellCurve, lower, upper
end

function lib.IsValidAlgorithm()
	if not get("stat.wowuction.enable") then return false end
	if not private.IswowuctionLoaded() then return false end
	return true
end

function private.OnLoad(addon)
	default("stat.wowuction.enable", false)
	default("stat.wowuction.confidence", 20)
--	default("stat.wowuction.shockconfidence", 10)
	default("stat.wowuction.fallbackconfidence", 2)
	default("stat.wowuction.projection", -3.5)
	default("stat.wowuction.regionagreement", 1)
--	default("stat.wowuction.maxz", 2) -- because this parameter is used to effectively apply median-centered Bollinger Bands
	default("stat.wowuction.minerrorpct", 1)
--	default("stat.wowuction.detectpriceshocks", true)
--	default("stat.wowuction.detectstddevshocks", false)
	default("stat.wowuction.n", 492) -- 2 factions * 246 US realms as of 2012-09-17 (excludes Arena Pass)
	private.OnLoad = nil -- only run this function once
end

--~ function private.GetInfo(hyperlink, serverKey)
--~ 	if not private.IswowuctionLoaded() then return end

--~ 	local linkType, itemId, suffix, factor = decode(hyperlink)
--~ 	if (linkType ~= "item") then return end

--~ 	local dta = TSM:GetData(itemId, serverKey)
--~ 	return dta
--~ end

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
		-- FIXME: cache needs to clear when settings change
		gui:AddControl(id, "Header",     0,    _TRANS('WOWUCTION_Interface_wowuctionOptions'))
		gui:AddControl(id, "Note",       0, 1, nil, nil, " ")
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.enable", _TRANS('WOWUCTION_Interface_Enablewowuction'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_Enablewowuction'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.projection", -14, 14, 0.5, _TRANS('WOWUCTION_Interface_Projection') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_Projection'))
		gui:AddControl(id, "NumberBox",	0, 1, "stat.wowuction.maxz", 0, 1000, _TRANS('WOWUCTION_Interface_MaxZScore') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_MaxZScore'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.minerrorpct", 0, 10, 0.5, _TRANS('WOWUCTION_Interface_MinErrorPercent') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_MinErrorPercent'))
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.regionagreement", 0, 1, 0.1, _TRANS('WOWUCTION_Interface_RegionAgreement'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_RegionAgreement'))
		gui:AddControl(id, "NumberBox",	0, 1, "stat.wowuction.n", 0, 1000, _TRANS('WOWUCTION_Interface_N') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_N'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.confidence", 0, 30, 1, _TRANS('WOWUCTION_Interface_Confidence') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_Confidence'))
		gui:AddControl(id, "WideSlider",	0, 1, "stat.wowuction.fallbackconfidence", 0, 30, 1, _TRANS('WOWUCTION_Interface_FallbackConfidence') )
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_FallbackConfidence'))
		gui:AddControl(id, "Checkbox",   0, 1, "stat.wowuction.regionfallback", _TRANS('WOWUCTION_Interface_RegionFallback'))
		gui:AddTip(id, _TRANS('WOWUCTION_HelpTooltip_RegionFallback'))

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