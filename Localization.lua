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
		-- Section: Help
		['WOWUCTION_Help_wowuction'] = "What is WoWuction?",
		['WOWUCTION_Help_wowuctionAnswer'] = "WoWuction is a website that reads most of a realm's Auction House data about once every hour and packages that market data into an addon. Data is collected for every item on the auction house, except for randomly-enchanted weapons and armor. The data includes the most recent market price, the average price from the past 14 days, and the standard deviation. Similar data from the entire region (i.e. all US servers or all EU servers) is also available.",

		-- Section: HelpTooltip
		["WOWUCTION_HelpTooltip_Enablewowuction"] = "Allow Auctioneer to use market data from WoWuction for this realm and faction.",
		["WOWUCTION_HelpTooltip_Seen"] = "Count realm-specific WoWuction data as this many auctions for Appraiser purposes (since WoWuction doesn't report actual seen counts).",
		-- Section: Interface
		["WOWUCTION_Interface_Enablewowuction"] = "Enable WoWuction Realm Stats",
		["WOWUCTION_Interface_Seen"] = "Seen count",
	},
}