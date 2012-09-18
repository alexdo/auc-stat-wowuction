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

 AucStatwowuctionLocalizations = {
	enUS = {
		-- Section: Alerts
		['WOWUCTION_alert_stddevshock_item_%s_expected_%d_actual_%d'] = "Region-wide volatility shock detected on %s! Expected region market price to be +/- no more than %d; actually +/- %d. Increasing the error margin on this realm's price.\n",
		['WOWUCTION_alert_priceshock_item_%s_Z_%f_expected_%d'] = "Region-wide price shock detected on %s! Region market price is %f times as far from the median as expected error %d. Using this realm's latest price instead of the 14-day moving median.\n", 
		-- Section: Help
		['WOWUCTION_Help_wowuction'] = "What is WoWuction?",
		['WOWUCTION_Help_wowuctionAnswer'] = "WoWuction is a website that reads most of a realm's Auction House data about once every hour and packages that market data into an addon. Data is collected for every item on the auction house, except for randomly-enchanted weapons and armor. The data includes the most recent market price, the average price from the past 14 days, and the standard deviation. Similar data from the entire region (i.e. all US servers or all EU servers) is also available.",

		-- Section: HelpTooltip
		["WOWUCTION_HelpTooltip_Enablewowuction"] = "Allow Auctioneer to use market data from WoWuction for this realm and faction.",
		["WOWUCTION_HelpTooltip_RegionFallback"] = "Use the region-wide price for items that WoWuction hasn't seen on this realm in 14 days.",
		["WOWUCTION_HelpTooltip_MaxZScore"] = "Current prices are considered outliers when they deviate from the 14-day median by more than this number times the standard error of the median (the +/- range in the tooltip), i.e. when they fall outside modified Bollinger Bands with N=14 and this value of K.",
		["WOWUCTION_HelpTooltip_DetectStddevShocks"] = "Widen the margin of error for item prices that show more realm-to-realm variation today than normally. This may indicate that a recent systematic change, such as a patch, has shrunk the markets for the item.",
		["WOWUCTION_HelpTooltip_DetectPriceShocks"] = "Use the current market price instead of the 14-day moving median when today's region-wide median price is an outlier on the same side. This may indicate that a recent systematic change, such as a patch, has permanently changed the price range.",
		["WOWUCTION_HelpTooltip_CurrentPriceWeight"] = "Percentage of the price estimate that comes from the latest market price rather than the 14-day median. Increase if Auctioneer market prices aren't keeping up with market trends; decrease if they become unstable. If Price Breakout Detection is enabled, it will override this setting when triggered.",
		["WOWUCTION_HelpTooltip_N"] = "The number of active Auction Houses in this region (usually one Alliance and one Horde in every realm), excluding public test and Arena Pass realms. Only used if Price Breakout Detection, Volatility Shock Detection or Region-Wide Fallback is enabled.",
		["WOWUCTION_HelpTooltip_MinErrorPercent"] = "A minimum estimate of the standard error of the median, as a percentage. Use this to avoid overreacting to small fluctuations when the tooltip +/- ranges are abnormally low.",
		-- Section: Interface
		["WOWUCTION_Interface_Enablewowuction"] = "Enable WoWuction Realm Stats",
		["WOWUCTION_Interface_RegionFallback"] = "Region-Wide Fallback",
		["WOWUCTION_Interface_MaxZScore"] = "Critical Z-score",
		["WOWUCTION_Interface_DetectStddevShocks"] = "Volatility Shock Detection",
		["WOWUCTION_Interface_DetectPriceShocks"] = "Price Breakout Detection",
		["WOWUCTION_Interface_CurrentPriceWeight"] = "Weight of current price",
		["WOWUCTION_Interface_MinErrorPercent"] = "Minimum standard error",
		["WOWUCTION_Interface_N"] = "Region-wide auction house count",
	},
}