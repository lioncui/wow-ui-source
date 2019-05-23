PVPMatchUtil = {
	RowColors = {
		CreateColor(0.52, 0.075, 0.18), -- Horde
		CreateColor(0.72, 0.37, 1.0),	-- Horde Alternate
		CreateColor(0.11, 0.26, 0.51),	-- Alliance
		CreateColor(0.85, 0.71, 0.26),	-- Alliance Alternate
	},
	CellColors = {
		CreateColor(1.0, 0.1, 0.1),		-- Horde
		CreateColor(0.72, 0.37, 1.0),	-- Horde Alternate
		CreateColor(0.0, 0.68, 0.94),	-- Alliance
		CreateColor(1.0, 0.82, 0.0),	-- Alliance Alternate
	},
};

PVPMatchUtil.MatchTimeFormatter = CreateFromMixins(SecondsFormatterMixin);
PVPMatchUtil.MatchTimeFormatter:Init(0, SecondsFormatter.Abbreviation.Truncate, true);

function PVPMatchUtil.MatchTimeFormatter:GetDesiredUnitCount(seconds)
	return 2;
end

function PVPMatchUtil.MatchTimeFormatter:GetMinInterval(seconds)
	return SecondsFormatter.Interval.Seconds;
end

function PVPMatchUtil.IsActiveMatchComplete()
	return C_PvP.GetActiveMatchState() == Enum.PvpMatchState.Complete;
end

function PVPMatchUtil.GetColorIndex(factionIndex, useAlternateColor)
	return (useAlternateColor and 2 or 1) + (factionIndex * 2);
end

function PVPMatchUtil.GetRowColor(factionIndex, useAlternateColor)
	local index = PVPMatchUtil.GetColorIndex(factionIndex, useAlternateColor);
	return PVPMatchUtil.RowColors[index];
end

function PVPMatchUtil.GetCellColor(factionIndex, useAlternateColor)
	local index = PVPMatchUtil.GetColorIndex(factionIndex, useAlternateColor);
	return PVPMatchUtil.CellColors[index];
end

function PVPMatchUtil.GetOptionalCategories()
	local categories = {};
	categories.honorableKills = C_PvP.CanDisplayHonorableKills();
	categories.deaths = C_PvP.CanDisplayDeaths();
	
	local isRated = C_PvP.IsRatedBattleground();
	categories.rating = isRated;
	categories.ratingChange = isRated;

	return categories;
end

PVPMatchStyle = {
	PanelColors = {
			CreateColor(1.0, 0.0, 0.0),		-- Horde
			CreateColor(0.557, 0.0, 1.0),	-- Horde Alternate
			CreateColor(0.0, .376, 1.0),	-- Alliance
			CreateColor(1.0, 0.824, 0.0),	-- Alliance Alternate
	},
	Theme = {
		Horde = {
			decoratorOffsetY = -37,
			decoratorTexture = "scoreboard-horde-header",
			nineSliceLayout = "BFAMissionHorde",
		},
		Alliance = {
			decoratorOffsetY = -28,
			decoratorTexture = "scoreboard-alliance-header",
			nineSliceLayout = "BFAMissionAlliance",
		},
		Neutral = {
			nineSliceLayout = "BFAMissionNeutral",
		},
	},
}

function PVPMatchStyle.GetPanelColor(factionIndex, useAlternateColor)
	local index = PVPMatchUtil.GetColorIndex(factionIndex, useAlternateColor);
	return PVPMatchStyle.PanelColors[index];
end

function PVPMatchStyle.GetLocalPlayerFactionTheme()
	local factionGroup = UnitFactionGroup("player");
	return PVPMatchStyle.GetFactionPanelTheme(factionGroup);
end

function PVPMatchStyle.GetFactionPanelTheme(factionGroup)
	local index = PLAYER_FACTION_GROUP[factionGroup];
	return GetFactionPanelThemeByIndex(index);
end

function PVPMatchStyle.GetFactionPanelThemeByIndex(index)
	if index == 0 then
		return PVPMatchStyle.Theme.Horde;
	elseif index == 1 then
		return PVPMatchStyle.Theme.Alliance;
	end
end

function PVPMatchStyle.GetNeutralPanelTheme()
	return PVPMatchStyle.Theme.Neutral;
end