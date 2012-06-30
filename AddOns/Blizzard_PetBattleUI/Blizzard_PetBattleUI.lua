NUM_BATTLE_PETS_IN_BATTLE = 3;
NUM_BATTLE_PET_ABILITIES = 3;
END_OF_PET_BATTLE_PET_LEVEL_UP = "petbattlepetlevel";
END_OF_PET_BATTLE_RESULT = "petbattleresult";
END_OF_PET_BATTLE_CAPTURE = "petbattlecapture";

BATTLE_PET_DISPLAY_ROTATION = 3 * math.pi / 8;

PET_BATTLE_WEATHER_TEXTURES = {
	--[54] = "Interface\\PetBattles\\Weather-ArcaneStorm",
	[205] = "Interface\\PetBattles\\Weather-Blizzard",
	[171] = "Interface\\PetBattles\\Weather-BurntEarth",
	[257] = "Interface\\PetBattles\\Weather-Darkness",
	[203] = "Interface\\PetBattles\\Weather-StaticField",
	--[55] = "Interface\\PetBattles\\Weather-Moonlight",
	--[59] = "Interface\\PetBattles\\Weather-Mud",
	[229] = "Interface\\PetBattles\\Weather-Rain",
	[454] = "Interface\\PetBattles\\Weather-Sandstorm",
	[403] = "Interface\\PetBattles\\Weather-Sunlight",
	--[63] = "Interface\\PetBattles\\Weather-Windy",

	[235] = "Interface\\PetBattles\\Weather-Rain",
};

local endOfBattleMessages = {};

--------------------------------------------
-------------Pet Battle Frame---------------
--------------------------------------------
function PetBattleFrame_OnLoad(self)
	self.BottomFrame.actionButtons = {};

	local flowFrame = self.BottomFrame.FlowFrame;
	FlowContainer_Initialize(flowFrame);
	FlowContainer_SetOrientation(flowFrame, "horizontal");
	FlowContainer_SetHorizontalSpacing(flowFrame, 10);

	for i=1, NUM_BATTLE_PETS_IN_BATTLE do
		PetBattleUnitFrame_SetUnit(self.BottomFrame.PetSelectionFrame["Pet"..i], LE_BATTLE_PET_ALLY, i);
	end

	self:RegisterEvent("PET_BATTLE_TURN_STARTED");
	self:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE");
	self:RegisterEvent("PET_BATTLE_PET_CHANGED");

	-- End of battle events:
	self:RegisterEvent("PET_BATTLE_CLOSE");
	self:RegisterEvent("PET_BATTLE_LEVEL_CHANGED");
	self:RegisterEvent("PET_BATTLE_CAPTURED");
	self:RegisterEvent("PET_BATTLE_FINAL_ROUND");
end

function PetBattleFrame_OnEvent(self, event, ...)
	if ( event == "PET_BATTLE_TURN_STARTED" ) then
		PetBattleFrameTurnTimer_UpdateValues(self.BottomFrame.TurnTimer);
	elseif ( event == "PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE" ) then
		PetBattleFrame_UpdatePetSelectionFrame(self);
		PetBattleFrame_UpdateInstructions(self);
	elseif ( event == "PET_BATTLE_PET_CHANGED" ) then
		PetBattleFrame_UpdateAssignedUnitFrames(self);
		PetBattleFrame_UpdateAllActionButtons(self);
	elseif ( event == "PET_BATTLE_CLOSE" ) then
		PetBattleFrame_Remove(self);
	elseif ( event == "PET_BATTLE_LEVEL_CHANGED" ) then
		local activePlayer, activePetSlot = ...;
		if ( activePlayer == 1 ) then
			local petID = C_PetJournal.GetPetLoadOutInfo(activePetSlot);
			local speciesID, customName, petLevel, xp, maxXp, displayID, name, petIcon = C_PetJournal.GetPetInfoByPetID(petID);
			table.insert(endOfBattleMessages, {type=END_OF_PET_BATTLE_PET_LEVEL_UP, name = customName or name, level = petLevel, icon = petIcon, speciesID = speciesID});
		end
	elseif ( event == "PET_BATTLE_CAPTURED") then
		local fromPlayer, activePetSlot = ...;
		if (fromPlayer == 2) then
			local petName = C_PetBattles.GetName(fromPlayer, activePetSlot);
			local petIcon = C_PetBattles.GetIcon(fromPlayer, activePetSlot);
			table.insert(endOfBattleMessages, {type=END_OF_PET_BATTLE_CAPTURE, name = petName, icon = petIcon});
		end
	elseif ( event == "PET_BATTLE_FINAL_ROUND") then
		local str = PET_BATTLE_RESULT_LOSE;
		local winningPlayer = ...;
		if ( winningPlayer == 1 ) then
			str = PET_BATTLE_RESULT_WIN;
		end;
		table.insert(endOfBattleMessages, 1, {type=END_OF_PET_BATTLE_RESULT, winner=str});
	end
end

function PetBattleFrame_UpdateInstructions(self)
	local battleState = C_PetBattles.GetBattleState();
	if ( ( ( battleState == LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE ) or ( battleState == LE_PET_BATTLE_STATE_WAITING_FOR_FRONT_PETS ) ) and 
		( not C_PetBattles.GetSelectedAction() ) ) then
		self.BottomFrame.FlowFrame.SelectPetInstruction:Show();
	else
		self.BottomFrame.FlowFrame.SelectPetInstruction:Hide();
	end
end

function PetBattleFrame_Display(self)
	self:Show();
	PetBattleFrame_UpdatePetSelectionFrame(self);
	PetBattleFrame_UpdateAssignedUnitFrames(self);
	PetBattleFrame_UpdateActionBarLayout(self);
	PetBattleFrame_UpdateAllActionButtons(self);
	PetBattleFrame_UpdateInstructions(self);
	PetBattleWeatherFrame_Update(self.WeatherFrame);
end

function PetBattleFrame_UpdatePetSelectionFrame(self)
	local battleState = C_PetBattles.GetBattleState();
	if ( ( ( battleState == LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE ) or ( battleState == LE_PET_BATTLE_STATE_WAITING_FOR_FRONT_PETS ) ) and
		( not C_PetBattles.GetSelectedAction() ) ) then
		PetBattlePetSelectionFrame_Show(PetBattleFrame.BottomFrame.PetSelectionFrame);
	else
		PetBattlePetSelectionFrame_Hide(PetBattleFrame.BottomFrame.PetSelectionFrame);
	end	
end

function PetBattleFrame_UpdateAllActionButtons(self)
	for i=1, #self.BottomFrame.actionButtons do
		local button = self.BottomFrame.actionButtons[i];
		PetBattleAbilityButton_UpdateIcons(button);
		PetBattleActionButton_UpdateState(button);
	end
	PetBattleActionButton_UpdateState(self.BottomFrame.SwitchPetButton);
	PetBattleActionButton_UpdateState(self.BottomFrame.CatchButton);
end

function PetBattleFrame_UpdateActionButtonLevel(self, actionButton)
	actionButton:SetFrameLevel(self.BottomFrame.FlowFrame:GetFrameLevel() + 1);
end

function PetBattleFrame_UpdateActionBarLayout(self)
	local flowFrame = self.BottomFrame.FlowFrame;
	FlowContainer_RemoveAllObjects(flowFrame);
	FlowContainer_PauseUpdates(flowFrame);

	FlowContainer_SetStartingOffset(flowFrame, 0, -4);

	for i=1, NUM_BATTLE_PET_ABILITIES do
		local actionButton = self.BottomFrame.actionButtons[i];
		if ( not actionButton ) then
			self.BottomFrame.actionButtons[i] = CreateFrame("CheckButton", nil, self.BottomFrame, "PetBattleAbilityButtonTemplate", i);
			actionButton = self.BottomFrame.actionButtons[i];
			PetBattleFrame_UpdateActionButtonLevel(PetBattleFrame, actionButton);
		end

		FlowContainer_AddObject(flowFrame, actionButton);
	end

	FlowContainer_AddObject(flowFrame, self.BottomFrame.SwitchPetButton);
	PetBattleFrame_UpdateActionButtonLevel(PetBattleFrame, self.BottomFrame.SwitchPetButton);

	FlowContainer_AddObject(flowFrame, self.BottomFrame.Delimiter);
	PetBattleFrame_UpdateActionButtonLevel(PetBattleFrame, self.BottomFrame.Delimiter);

	FlowContainer_AddObject(flowFrame, self.BottomFrame.CatchButton);
	PetBattleFrame_UpdateActionButtonLevel(PetBattleFrame, self.BottomFrame.CatchButton);

	FlowContainer_AddObject(flowFrame, self.BottomFrame.ForfeitButton);
	PetBattleFrame_UpdateActionButtonLevel(PetBattleFrame, self.BottomFrame.ForfeitButton);

	FlowContainer_ResumeUpdates(flowFrame);

	local usedX, usedY = FlowContainer_GetUsedBounds(flowFrame);
	flowFrame:SetWidth(usedX);
	self.BottomFrame:SetWidth(usedX + 260);

	self.BottomFrame.FlowFrame.SelectPetInstruction:ClearAllPoints();
	self.BottomFrame.FlowFrame.SelectPetInstruction:SetPoint("TOPLEFT", self.BottomFrame.actionButtons[1], "TOPLEFT", 0, 0);
	self.BottomFrame.FlowFrame.SelectPetInstruction:SetPoint("BOTTOMRIGHT", self.BottomFrame.SwitchPetButton, "BOTTOMRIGHT", 0, 0);

end

function PetBattleAbilityButton_OnClick(self)
	if ( IsModifiedClick() ) then
		local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY);
		local abilityID = C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, activePet, self:GetID());
		local maxHealth = C_PetBattles.GetMaxHealth(LE_BATTLE_PET_ALLY, activePet);
		local power = C_PetBattles.GetPower(LE_BATTLE_PET_ALLY, activePet);
		local speed = C_PetBattles.GetSpeed(LE_BATTLE_PET_ALLY, activePet);
		
		HandleModifiedItemClick(GetBattlePetAbilityHyperlink(abilityID, maxHealth, power, speed));
	else
		C_PetBattles.UseAbility(self:GetID());
	end
end

function PetBattleFrame_UpdateAssignedUnitFrames(self)
	local activeAlly = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY);
	local activeEnemy = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY);

	PetBattleUnitFrame_SetUnit(self.ActiveAlly, LE_BATTLE_PET_ALLY, activeAlly);
	local nextIndex = 2;
	for i=1, NUM_BATTLE_PETS_IN_BATTLE do
		if ( i ~= activeAlly ) then
			PetBattleUnitFrame_SetUnit(self["Ally"..nextIndex], LE_BATTLE_PET_ALLY, i);
			nextIndex = nextIndex + 1;
		end
	end

	PetBattleUnitFrame_SetUnit(self.ActiveEnemy, LE_BATTLE_PET_ENEMY, activeEnemy);
	nextIndex = 2;
	for i=1, NUM_BATTLE_PETS_IN_BATTLE do
		if ( i ~= activeEnemy ) then
			PetBattleUnitFrame_SetUnit(self["Enemy"..nextIndex], LE_BATTLE_PET_ENEMY, i);
			nextIndex = nextIndex + 1;
		end
	end

	PetBattleAuraHolder_SetUnit(self.EnemyBuffFrame, LE_BATTLE_PET_ENEMY, activeEnemy);
	PetBattleAuraHolder_SetUnit(self.EnemyDebuffFrame, LE_BATTLE_PET_ENEMY, activeEnemy);
	PetBattleAuraHolder_SetUnit(self.AllyBuffFrame, LE_BATTLE_PET_ALLY, activeAlly);
	PetBattleAuraHolder_SetUnit(self.AllyDebuffFrame, LE_BATTLE_PET_ALLY, activeAlly);
	PetBattleAuraHolder_SetUnit(self.EnemyPadBuffFrame, LE_BATTLE_PET_ENEMY, PET_BATTLE_PAD_INDEX);
	PetBattleAuraHolder_SetUnit(self.EnemyPadDebuffFrame, LE_BATTLE_PET_ENEMY, PET_BATTLE_PAD_INDEX);
	PetBattleAuraHolder_SetUnit(self.AllyPadBuffFrame, LE_BATTLE_PET_ALLY, PET_BATTLE_PAD_INDEX);
	PetBattleAuraHolder_SetUnit(self.AllyPadDebuffFrame, LE_BATTLE_PET_ALLY, PET_BATTLE_PAD_INDEX);
end

function PetBattleFrame_Remove(self)
	ActionButton_HideOverlayGlow(PetBattleFrame.BottomFrame.CatchButton);
	self:Hide();
	RemoveFrameLock("PETBATTLES");
end

local TIMER_BAR_TEXCOORD_LEFT = 0.56347656;
local TIMER_BAR_TEXCOORD_RIGHT = 0.89453125;
local TIMER_BAR_TEXCOORD_TOP = 0.00195313;
local TIMER_BAR_TEXCOORD_BOTTOM = 0.03515625;
function PetBattleFrameTurnTimer_OnUpdate(self, elapsed)
	if ( C_PetBattles.GetBattleState() == LE_PET_BATTLE_STATE_WAITING_FOR_ROUND_PLAYBACK ) then
		self.Bar:SetAlpha(0);
		self.TimerText:SetText("");
	elseif ( self.turnExpires ) then
		local timeRemaining = self.turnExpires - GetTime();

		--Deal with variable lag from the server without looking weird
		if ( timeRemaining <= 0.01 ) then
			timeRemaining = 0.01;
		end

		local timeRatio = 1.0;
		if ( self.turnTime > 0.0 ) then
			timeRatio = timeRemaining / self.turnTime;
		end
		local usableSpace = 337;

		self.Bar:SetWidth(timeRatio * usableSpace);
		self.Bar:SetTexCoord(TIMER_BAR_TEXCOORD_LEFT, TIMER_BAR_TEXCOORD_LEFT + (TIMER_BAR_TEXCOORD_RIGHT - TIMER_BAR_TEXCOORD_LEFT) * timeRatio, TIMER_BAR_TEXCOORD_TOP, TIMER_BAR_TEXCOORD_BOTTOM);

		if ( C_PetBattles.IsWaitingOnOpponent() ) then
			self.Bar:SetAlpha(0.5);
			self.TimerText:SetText(PET_BATTLE_WAITING_FOR_OPPONENT);
		else
			self.Bar:SetAlpha(1);
			if ( self.turnTime > 0.0 ) then
				self.TimerText:SetText(ceil(timeRemaining));
			else
				self.TimerText:SetText("")
			end
		end
	else
		self.Bar:SetAlpha(0);
		if ( C_PetBattles.IsWaitingOnOpponent() ) then
			self.TimerText:SetText(PET_BATTLE_WAITING_FOR_OPPONENT);
		else
			self.TimerText:SetText(PET_BATTLE_SELECT_AN_ACTION);
		end
	end
end

function PetBattleFrameTurnTimer_UpdateValues(self)
	local timeRemaining, turnTime = C_PetBattles.GetTurnTimeInfo(); 
	self.turnExpires = GetTime() + timeRemaining;
	self.turnTime = turnTime;
end

function PetBattleForfeitButton_OnClick(self)
	C_PetBattles.ForfeitGame();
end

function PetBattleCatchButton_OnClick(self)
	C_PetBattles.UseTrap();
end

function PetBattleFrame_GetBattleResults()
	return endOfBattleMessages;
end

function PetBattleFrame_GetAbilityAtLevel(speciesID, targetLevel)
	local abilities, levels = C_PetJournal.GetPetAbilityList(speciesID);
	for i, level in pairs(levels) do
		if level == targetLevel then
			return abilities[i];
		end
	end

	return nil;
end

--------------------------------------------
------Pet Battle Pet Selection Frame--------
--------------------------------------------
function PetBattlePetSelectionFrame_Show(self)
	local numPets = C_PetBattles.GetNumPets(LE_BATTLE_PET_ALLY);
	self:SetWidth((self.Pet1:GetWidth() + 10) * numPets + 30);

	for i=1, numPets do
		PetBattleUnitFrame_UpdateHealthInstant(self["Pet"..i]);
		PetBattleUnitFrame_UpdateDisplay(self["Pet"..i]);
		self["Pet"..i]:Show();
	end
	for i=numPets + 1, NUM_BATTLE_PETS_IN_BATTLE do
		self["Pet"..i]:Hide();
	end
	self:Show();
	PetBattleFrame.BottomFrame.SwitchPetButton:SetChecked(true);
end

function PetBattlePetSelectionFrame_Hide(self)
	self:Hide();
	PetBattleFrame.BottomFrame.SwitchPetButton:SetChecked(false);
end

--------------------------------------------
--------Pet Battle Action Button------------
--------------------------------------------
function PetBattleActionButton_Initialize(self, actionType, actionIndex)
	self.actionType = actionType;
	self.actionIndex = actionIndex;

	self:RegisterEvent("PET_BATTLE_ACTION_SELECTED");
	self:RegisterEvent("PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE");
	PetBattleActionButton_UpdateState(self);
end

function PetBattleActionButton_OnEvent(self, event, ...)
	if ( event == "PET_BATTLE_ACTION_SELECTED" ) then
		PetBattleActionButton_UpdateState(self);
	elseif ( event == "PET_BATTLE_PET_ROUND_PLAYBACK_COMPLETE" ) then
		PetBattleActionButton_UpdateState(self);
	end
end

function PetBattleActionButton_UpdateState(self)
	local actionType = self.actionType;
	local actionIndex = self.actionIndex;

	local _, usable, cooldown, hasSelected, isSelected, isLocked, isHidden;
	local selectedActionType, selectedActionIndex = C_PetBattles.GetSelectedAction();

	--Decide whether we have a selected action and if it's this button.
	if ( selectedActionType ) then
		hasSelected = true;
		if ( actionType == selectedActionType and (not actionIndex or actionIndex == selectedActionIndex) ) then
			isSelected = true;
		end
	end

	--Get the battle state to check when looking at each action type.
	local battleState = C_PetBattles.GetBattleState();

	--Set up usable/cooldown/locked for each action type.
	if ( actionType == LE_BATTLE_PET_ACTION_ABILITY ) then
		local _, name, icon = C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY), actionIndex);

		--If we're being forced to swap pets, hide us
		if ( battleState == LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE or
			battleState == LE_PET_BATTLE_STATE_WAITING_FOR_FRONT_PETS ) then
			isHidden = true;
		end

		--If we exist, check whether we're usable and what the cooldown is.
		if ( name ) then
			local isUsable, currentCooldown = C_PetBattles.GetAbilityState(LE_BATTLE_PET_ALLY, C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY), actionIndex);
			usable, cooldown = isUsable, currentCooldown;
		else
			isLocked = true;
		end
	elseif ( actionType == LE_BATTLE_PET_ACTION_TRAP ) then
		usable = C_PetBattles.IsTrapAvailable();
	elseif ( actionType == LE_BATTLE_PET_ACTION_SWITCH_PET ) then
		--If we're being forced to swap pets, hide us
		if ( battleState == LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE or
			battleState == LE_PET_BATTLE_STATE_WAITING_FOR_FRONT_PETS ) then
			isHidden = true;
		end
		for i = 1, NUM_BATTLE_PETS_IN_BATTLE do
			usable = usable or C_PetBattles.IsPetSwapAvailable(i);
		end
	else
		usable = true;
	end

	if ( isHidden or isLocked ) then
		self:Disable();
		self:SetAlpha(0);
	elseif ( cooldown and cooldown > 0 ) then
		--Set the frame up to look like a cooldown.
		if ( self.Icon ) then
			self.Icon:SetVertexColor(0.5, 0.5, 0.5);
			self.Icon:SetDesaturated(true);
		end
		self:Disable();
		self:SetAlpha(1);
		if ( self.SelectedHighlight ) then
			self.SelectedHighlight:Hide();
		end
		if ( self.CooldownShadow ) then
			self.CooldownShadow:Show();
		end
		if ( self.Cooldown ) then
			self.Cooldown:SetText(cooldown);
			self.Cooldown:Show();
		end
		if ( self.AdditionalIcon ) then
			self.AdditionalIcon:SetVertexColor(0.5, 0.5, 0.5);
		end
	elseif ( not usable or (hasSelected and not isSelected) ) then
		--Set the frame up to look unusable.
		if ( self.Icon ) then
			self.Icon:SetVertexColor(0.5, 0.5, 0.5);
			self.Icon:SetDesaturated(true);
		end
		self:Disable();
		self:SetAlpha(1);
		if ( self.SelectedHighlight ) then
			self.SelectedHighlight:Hide();
		end
		if ( self.CooldownShadow ) then
			self.CooldownShadow:Hide();
		end
		if ( self.Cooldown ) then
			self.Cooldown:Hide();
		end
		if ( self.AdditionalIcon ) then
			self.AdditionalIcon:SetVertexColor(0.5, 0.5, 0.5);
		end
	elseif ( hasSelected and isSelected ) then
		--Set the frame up to look selected.
		if ( self.Icon ) then
			self.Icon:SetVertexColor(1, 1, 1);
			self.Icon:SetDesaturated(false);
		end
		self:Enable();
		self:SetAlpha(1);
		if ( self.SelectedHighlight ) then
			self.SelectedHighlight:Show();
		end
		if ( self.CooldownShadow ) then
			self.CooldownShadow:Hide();
		end
		if ( self.Cooldown ) then
			self.Cooldown:Hide();
		end
		if ( self.AdditionalIcon ) then
			self.AdditionalIcon:SetVertexColor(1, 1, 1);
		end
	else
		--Set the frame up to look clickable/usable.
		if ( self.Icon ) then
			self.Icon:SetVertexColor(1, 1, 1);
			self.Icon:SetDesaturated(false);
		end
		self:Enable();
		self:SetAlpha(1);
		if ( self.SelectedHighlight ) then
			self.SelectedHighlight:Hide();
		end
		if ( self.CooldownShadow ) then
			self.CooldownShadow:Hide();
		end
		if ( self.Cooldown ) then
			self.Cooldown:Hide();
		end
		if ( self.AdditionalIcon ) then
			self.AdditionalIcon:SetVertexColor(1, 1, 1);
		end
		if ( actionType == LE_BATTLE_PET_ACTION_TRAP ) then
			PlaySoundKitID(28814);
			ActionButton_ShowOverlayGlow(self);
		end
	end
end

--------------------------------------------
--------Pet Battle Ability Button-----------
--------------------------------------------
function PetBattleAbilityButton_OnLoad(self)
	PetBattleActionButton_Initialize(self, LE_BATTLE_PET_ACTION_ABILITY, self:GetID());
end

function PetBattleAbilityButton_UpdateIcons(self)
	local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY);
	local id, name, icon = C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, activePet, self:GetID());
	if ( not icon ) then
		icon = "Interface\\Icons\\INV_Misc_QuestionMark";
	end
	if ( not name ) then
		--We don't have an ability here.
		self.Icon:SetTexture("INTERFACE\\ICONS\\INV_Misc_Key_05");
		self.Icon:SetVertexColor(1, 1, 1);
		self:Disable();
		return;
	end
	self.Icon:SetTexture(icon);
end

function PetBattleAbilityButton_OnEnter(self)
	local petIndex = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY);
	if ( self:GetEffectiveAlpha() > 0 and C_PetBattles.GetAbilityInfo(LE_BATTLE_PET_ALLY, petIndex, self:GetID()) ) then
		PetBattleAbilityTooltip_SetAbility(LE_BATTLE_PET_ALLY, petIndex, self:GetID());
		PetBattleAbilityTooltip_Show("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 120);
	else
		PetBattlePrimaryAbilityTooltip:Hide();
	end
end

function PetBattleAbilityButton_OnLeave(self)
	PetBattlePrimaryAbilityTooltip:Hide();
end

--------------------------------------------
----------Pet Battle Unit Frame-------------
--------------------------------------------
function PetBattleUnitFrame_OnLoad(self)
	self:RegisterEvent("PET_BATTLE_MAX_HEALTH_CHANGED");
	self:RegisterEvent("PET_BATTLE_HEALTH_CHANGED");
	self:RegisterEvent("PET_BATTLE_PET_CHANGED");
	
	self:RegisterEvent("PET_BATTLE_AURA_APPLIED");
	self:RegisterEvent("PET_BATTLE_AURA_CANCELED");
	self:RegisterEvent("PET_BATTLE_AURA_CHANGED");
end

function PetBattleUnitFrame_OnEvent(self, event, ...)
	if ( event == "PET_BATTLE_HEALTH_CHANGED" or event == "PET_BATTLE_MAX_HEALTH_CHANGED" ) then
		local petOwner, petIndex = ...;
		if ( petOwner == self.petOwner and petIndex == self.petIndex ) then
			PetBattleUnitFrame_UpdateHealthInstant(self);
		end
	elseif ( event == "PET_BATTLE_PET_CHANGED" ) then
		PetBattleUnitFrame_UpdateDisplay(self);
	elseif ( event == "PET_BATTLE_AURA_APPLIED" or
		event == "PET_BATTLE_AURA_CANCELED" or
		event == "PET_BATTLE_AURA_CHANGED" ) then
		local petOwner, petIndex = ...;
		if ( petOwner == self.petOwner and petIndex == self.petIndex ) then
			PetBattleUnitFrame_UpdatePetType(self);
		end
	end
end

function PetBattleUnitFrame_SetUnit(self, petOwner, petIndex)
	self.petOwner = petOwner;
	self.petIndex = petIndex;
	PetBattleUnitFrame_UpdateDisplay(self);
	PetBattleUnitFrame_UpdateHealthInstant(self);
	if ( petIndex > C_PetBattles.GetNumPets(petOwner) ) then
		self:Hide();
	else
		self:Show();
	end
end

function PetBattleUnitFrame_UpdateDisplay(self)
	local petOwner = self.petOwner;
	local petIndex = self.petIndex;

	if ( not petOwner or not petIndex ) then
		return;
	end

	local battleState = C_PetBattles.GetBattleState();

	--Update the pet species icon
	if ( self.Icon ) then
		if ( petOwner == LE_BATTLE_PET_ALLY ) then
			self.Icon:SetTexCoord(1, 0, 0, 1);
		else
			self.Icon:SetTexCoord(0, 1, 0, 1);
		end
		self.Icon:SetTexture(C_PetBattles.GetIcon(petOwner, petIndex));
	end

	--Get name info
	local name, speciesName = C_PetBattles.GetName(petOwner, petIndex);

	--Update the pet's custom name (will be the species name if it hasn't been changed).
	if ( self.Name ) then
		self.Name:SetText(name);
	end

	--Update the pet's species name (will be hidden if the custom name matches).
	if ( self.SpeciesName ) then
		if ( name ~= speciesName ) then
			self.SpeciesName:SetText(speciesName);
			self.SpeciesName:Show();
		else
			self.SpeciesName:Hide();
		end
	end

	--Update the display of the level
	if ( self.Level ) then
		self.Level:SetText(C_PetBattles.GetLevel(petOwner, petIndex));
	end

	--Update the 3D model of the pet
	if ( self.PetModel ) then
		self.PetModel:SetDisplayInfo(C_PetBattles.GetDisplayID(petOwner, petIndex));
		self.PetModel:SetRotation(-BATTLE_PET_DISPLAY_ROTATION);
		self.PetModel:SetDoBlend(false);
		if ( C_PetBattles.GetHealth(petOwner, petIndex) == 0 ) then
			self.PetModel:SetAnimation(6, 0); --Display the dead animation
			--self.PetModel:SetAnimation(0, 0);
		else
			self.PetModel:SetAnimation(0, 0);
		end
	end

	--Updated the indicator that this is the active pet
	if ( self.SelectedTexture ) then
		if ( battleState ~= LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE and
			battleState ~= LE_PET_BATTLE_STATE_WAITING_FOR_FRONT_PETS and
			C_PetBattles.GetActivePet(petOwner) == petIndex ) then
			self.SelectedTexture:Show();
		else
			self.SelectedTexture:Hide();
		end
	end

	--Update the XP bar
	if ( self.XPBar ) then
		local xp, maxXp = C_PetBattles.GetXP(petOwner, petIndex);
		self.XPBar:SetWidth(max((xp / max(maxXp,1)) * self.xpBarWidth, 1));
	end

	--Update the XP text
	if ( self.XPText ) then
		local xp, maxXp = C_PetBattles.GetXP(petOwner, petIndex);
		self.XPText:SetFormattedText(self.xpTextFormat or PET_BATTLE_CURRENT_XP_FORMAT, xp, maxXp);
	end

	--Update the pet type (e.g. "Flying", "Critter", "Magical", etc.)
	PetBattleUnitFrame_UpdatePetType(self);
end

function PetBattleUnitFrame_UpdateHealthInstant(self)
	local petOwner = self.petOwner;
	local petIndex = self.petIndex;

	local health = C_PetBattles.GetHealth(petOwner, petIndex);
	local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex);

	if ( self.HealthText ) then
		self.HealthText:SetFormattedText(self.healthTextFormat or PET_BATTLE_CURRENT_HEALTH_FORMAT, health, maxHealth);
	end
	if ( self.ActualHealthBar ) then
		if ( health == 0 ) then
			self.ActualHealthBar:Hide();
		else
			self.ActualHealthBar:Show();
		end
		self.ActualHealthBar:SetWidth((health / maxHealth) * self.healthBarWidth);
	end
	if ( self.BorderAlive ) then
		if ( health == 0 ) then
			self.BorderAlive:Hide();
		else
			self.BorderAlive:Show();
		end
	end
	if ( self.BorderDead ) then
		if ( health == 0 ) then
			self.BorderDead:Show();
		else
			self.BorderDead:Hide();
		end
	end
	if ( self.hideWhenDeadList ) then
		for _, object in pairs(self.hideWhenDeadList) do
			if ( health == 0 ) then
				object:Hide();
			else
				object:Show();
			end
		end
	end
	if ( self.showWhenDeadList ) then
		for _, object in pairs(self.showWhenDeadList) do
			if ( health == 0 ) then
				object:Show();
			else
				object:Hide();
			end
		end
	end
end

function PetBattleUnitFrame_UpdatePetType(self)
	if ( self.PetType ) then
		local petType = C_PetBattles.GetPetType(self.petOwner, self.petIndex);

		self.PetType.Icon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType]);

		local auraID = PET_BATTLE_PET_TYPE_PASSIVES[petType];
		self.PetType.auraID = auraID;

		if ( auraID and self.PetType.ActiveStatus ) then
			local hasAura = PetBattleUtil_PetHasAura(self.petOwner, self.petIndex, auraID);
			if ( hasAura ) then
				self.PetType.ActiveStatus:Show();
			else
				self.PetType.ActiveStatus:Hide();
			end
		end
	end
end

--------------------------------------------
----------Pet Battle Unit Tooltips----------
--------------------------------------------
function PetBattleUnitTooltip_OnLoad(self)
	self.healthBarWidth = 230;
	self.xpBarWidth = 230;
	self.healthTextFormat = PET_BATTLE_HEALTH_VERBOSE;
	self.xpTextFormat = PET_BATTLE_CURRENT_XP_FORMAT_VERBOSE;
	PetBattleUnitFrame_OnLoad(self);

	self.weakToTextures = { self.WeakTo1 };
	self.resistantToTextures = { self.ResistantTo1 };
	self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
	self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
end

function PetBattleUnitTooltip_UpdateForUnit(self, petOwner, petIndex)
	PetBattleUnitFrame_SetUnit(self, petOwner, petIndex);

	local height = 193;
	local attack = C_PetBattles.GetPower(petOwner, petIndex);
	local speed = C_PetBattles.GetSpeed(petOwner, petIndex);
	self.AttackAmount:SetText(attack);
	self.SpeedAmount:SetText(speed);

	if ( petOwner == LE_BATTLE_PET_ALLY ) then
		--Add the XP bar
		self.XPBar:Show();
		self.XPBG:Show();
		self.XPBorder:Show();
		self.XPText:Show();
		self.Delimiter:SetPoint("TOP", self.XPBG, "BOTTOM", 0, -10);
		height = height + 18;

		--Show and update abilities
		self.AbilitiesLabel:Show();
		for i=1, NUM_BATTLE_PET_ABILITIES do
			local id, name, texture = C_PetBattles.GetAbilityInfo(petOwner, petIndex, i);
			local abilityIcon = self["AbilityIcon"..i];
			local abilityName = self["AbilityName"..i];
			abilityIcon:SetTexture(texture);
			abilityName:SetText(name);
			abilityIcon:Show();
			abilityName:Show();
		end

		--Hide the weak to/resistant to
		self.WeakToLabel:Hide();
		self.ResistantToLabel:Hide();

		for _, texture in pairs(self.weakToTextures) do
			texture:Hide();
		end
		for _, texture in pairs(self.resistantToTextures) do
			texture:Hide();
		end
	else
		--Remove the XP bar
		self.XPBar:Hide();
		self.XPBG:Hide();
		self.XPBorder:Hide();
		self.XPText:Hide();
		self.Delimiter:SetPoint("TOP", self.HealthBG, "BOTTOM", 0, -10);

		--Hide abilities
		self.AbilitiesLabel:Hide();
		for i=1, NUM_BATTLE_PET_ABILITIES do
			self["AbilityIcon"..i]:Hide();
			self["AbilityName"..i]:Hide();
		end

		--Show and update weak to/resistant against
		self.WeakToLabel:Show();
		self.ResistantToLabel:Show();
		
		local nextWeakIndex, nextResistIndex = 1, 1;
		local currentPetType = C_PetBattles.GetPetType(petOwner, petIndex);
		for i=1, C_PetBattles.GetNumPetTypes() do
			local modifier = C_PetBattles.GetAttackModifier(i, currentPetType);
			if ( modifier > 1 ) then
				local icon = self.weakToTextures[nextWeakIndex];
				if ( not icon ) then
					self.weakToTextures[nextWeakIndex] = self:CreateTexture(nil, "ARTWORK", "PetBattleUnitTooltipPetTypeStrengthTemplate");
					icon = self.weakToTextures[nextWeakIndex];
					icon:ClearAllPoints();
					icon:SetPoint("LEFT", self.weakToTextures[nextWeakIndex - 1], "RIGHT", 5, 0);
				end
				icon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[i]);
				icon:Show();
				nextWeakIndex = nextWeakIndex + 1;
			elseif ( modifier < 1 ) then
				local icon = self.resistantToTextures[nextResistIndex];
				if ( not icon ) then
					self.resistantToTextures[nextResistIndex] = self:CreateTexture(nil, "ARTWORK", "PetBattleUnitTooltipPetTypeStrengthTemplate");
					icon = self.resistantToTextures[nextResistIndex];
					icon:ClearAllPoints();
					icon:SetPoint("LEFT", self.resistantToTextures[nextResistIndex - 1], "RIGHT", 5, 0);
				end
				icon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[i]);
				icon:Show();
				nextResistIndex = nextResistIndex + 1;
			end
		end

		for i=nextWeakIndex, #self.weakToTextures do
			self.weakToTextures[i]:Hide();
		end
		for i=nextResistIndex, #self.resistantToTextures do
			self.resistantToTextures[i]:Hide();
		end

		height = height + 5;
	end

	self:SetHeight(height);
end

function PetBattleUnitTooltip_Attach(self, point, frame, relativePoint, xOffset, yOffset)
	self:SetParent(frame);
	self:SetFrameStrata("TOOLTIP");
	self:ClearAllPoints();
	self:SetPoint(point, frame, relativePoint, xOffset, yOffset);
end

--------------------------------------------
---------Pet Battle Ability Tooltip---------
--------------------------------------------
PET_BATTLE_ABILITY_INFO = {};

function PET_BATTLE_ABILITY_INFO:GetCooldown()
	local isUsable, currentCooldown = C_PetBattles.GetAbilityState(self.petOwner, self.petIndex, self.abilityIndex);
	return currentCooldown;
end

function PET_BATTLE_ABILITY_INFO:GetRemainingDuration()
	return 0;
end

function PET_BATTLE_ABILITY_INFO:GetAbilityID()
	local id = C_PetBattles.GetAbilityInfo(self.petOwner, self.petIndex, self.abilityIndex);
	return id;
end

function PET_BATTLE_ABILITY_INFO:IsInBattle()
	return true;
end

function PET_BATTLE_ABILITY_INFO:GetMaxHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetMaxHealth(petOwner, petIndex);
end

function PET_BATTLE_ABILITY_INFO:GetHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetHealth(petOwner, petIndex);
end

function PET_BATTLE_ABILITY_INFO:GetAttackStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetPower(petOwner, petIndex);
end

function PET_BATTLE_ABILITY_INFO:GetSpeedStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetSpeed(petOwner, petIndex);
end

function PET_BATTLE_ABILITY_INFO:GetState(stateID, target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetStateValue(petOwner, petIndex, stateID);
end

--For use by other functions here
function PET_BATTLE_ABILITY_INFO:GetUnitFromToken(target)
	if ( target == "default" ) then
		target = "self";
	end

	if ( target == "self" ) then
		return self.petOwner, self.petIndex;
	elseif ( target == "enemy" ) then
		local owner = PetBattleUtil_GetOtherPlayer(self.petOwner);
		return owner, C_PetBattles.GetActivePet(owner);
	else
		error("Unsupported token: "..tostring(target));
	end
end

function PetBattleAbilityTooltip_SetAbility(petOwner, petIndex, abilityIndex)
	PET_BATTLE_ABILITY_INFO.petOwner = petOwner;
	PET_BATTLE_ABILITY_INFO.petIndex = petIndex;
	PET_BATTLE_ABILITY_INFO.abilityIndex = abilityIndex;
	SharedPetBattleAbilityTooltip_SetAbility(PetBattlePrimaryAbilityTooltip, PET_BATTLE_ABILITY_INFO);
end


--------------------------------------------
----------Pet Battle Opening Frame----------
--------------------------------------------
function PetBattleOpeningFrame_OnLoad(self)
	self:RegisterEvent("PET_BATTLE_OPENING_START");
	self:RegisterEvent("PET_BATTLE_OPENING_DONE");
	self:RegisterEvent("PET_BATTLE_CLOSE");
end

function PetBattleOpeningFrame_OnEvent(self, event, ...)
	local open;
	local openMainFrame;
	local close;
	if ( event == "PET_BATTLE_OPENING_START" ) then
		endOfBattleMessages = {};
		open = true;
		if ( C_PetBattles.GetBattleState() ~= LE_PET_BATTLE_STATE_WAITING_PRE_BATTLE ) then
			-- bypassing intro
			close = true;
			openMainFrame = true;
		else
			-- play intro
		end
	elseif ( event == "PET_BATTLE_OPENING_DONE" ) then
		-- end intro, open main frame
		close = true;
		openMainFrame = true;
		StartSplashTexture.splashAnim:Play();
	elseif ( event == "PET_BATTLE_CLOSE" ) then
		-- end battle all together
		close = true;
	end
	
	if ( open == true ) then
		PetBattleOpeningFrame_Display(self);
	end
	
	if ( close == true ) then
		PetBattleOpeningFrame_Remove(self);
	end
	
	if ( openMainFrame == true ) then
		PetBattleFrame_Display(PetBattleFrame);	
	end
end

function PetBattleOpeningFrame_Display(self)
	PetBattleOpeningFrame_UpdatePanel(self.MyPet, LE_BATTLE_PET_ALLY, 1);
	PetBattleOpeningFrame_UpdatePanel(self.EnemyPet, LE_BATTLE_PET_ENEMY, 1);
	--self:Show();
	AddFrameLock("PETBATTLES");
	AddFrameLock("PETBATTLEOPENING");
end

function PetBattleOpeningFrame_Remove(self)
	self:Hide();
	RemoveFrameLock("PETBATTLEOPENING");
end

function PetBattleOpeningFrame_UpdatePanel(panel, petOwner, petIndex)
	panel.PetModel:SetDisplayInfo(C_PetBattles.GetDisplayID(petOwner, petIndex));
	panel.PetModel:SetRotation((petOwner == LE_BATTLE_PET_ALLY and 1 or -1) * BATTLE_PET_DISPLAY_ROTATION);
	panel.PetModel:SetAnimation(0, 0);	--Only use the first variation of the stand animation to avoid wandering around.
	panel.PetBanner.Name:SetText(C_PetBattles.GetName(petOwner, petIndex));

	SetPortraitToTexture(panel.PetBanner.Icon, C_PetBattles.GetIcon(petOwner, petIndex));
end

----------------------------------------------
------------Pet Battle Weather Frame----------
----------------------------------------------
function PetBattleWeatherFrame_OnLoad(self)
	self:RegisterEvent("PET_BATTLE_AURA_APPLIED");
	self:RegisterEvent("PET_BATTLE_AURA_CANCELED");
	self:RegisterEvent("PET_BATTLE_AURA_CHANGED");
end

function PetBattleWeatherFrame_OnEvent(self, event, ...)
	if ( event == "PET_BATTLE_AURA_APPLIED" or
		event == "PET_BATTLE_AURA_CANCELED" or
		event == "PET_BATTLE_AURA_CHANGED" ) then
		local petOwner, petIndex = ...;
		if ( petOwner == LE_BATTLE_PET_WEATHER ) then
			PetBattleWeatherFrame_Update(self);
		end
	end
end

function PetBattleWeatherFrame_Update(self)
	local auraID, instanceID, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(LE_BATTLE_PET_WEATHER, PET_BATTLE_PAD_INDEX, 1);
	if ( auraID ) then
		local id, name, icon, maxCooldown, description = C_PetBattles.GetAbilityInfoByID(auraID);
		self.Icon:SetTexture(icon);
		self.Name:SetText(name);
		if ( turnsRemaining < 0 ) then
			self.Duration:SetText("");
		else
			self.Duration:SetText(turnsRemaining);
		end

		local backgroundTexture = PET_BATTLE_WEATHER_TEXTURES[auraID];
		if ( backgroundTexture ) then
			self.BackgroundArt:SetTexture(backgroundTexture);
			self.BackgroundArt:Show();
		else
			self.BackgroundArt:Hide();
		end

		self:Show();
	else
		self:Hide();
	end
end

----------------------------------------------
------------Pet Battle Aura Holder------------
----------------------------------------------
function PetBattleAuraHolder_OnLoad(self)
	if ( not self.template ) then
		GMError("Must provide template for PetBattleAuraHolder");
	end
	if ( not self.displayBuffs and not self.displayDebuffs ) then
		GMError("Neither buffs nor nebuffs are displayed in a PetBattleAuraHolder");
	end

	self.frames = {};

	self:RegisterEvent("PET_BATTLE_AURA_APPLIED");
	self:RegisterEvent("PET_BATTLE_AURA_CANCELED");
	self:RegisterEvent("PET_BATTLE_AURA_CHANGED");
end

function PetBattleAuraHolder_OnEvent(self, event, ...)
	if ( event == "PET_BATTLE_AURA_APPLIED" or event == "PET_BATTLE_AURA_CANCELED" or event == "PET_BATTLE_AURA_CHANGED" ) then
		local petOwner, petIndex, instanceID = ...;
		if ( petOwner == self.petOwner and petIndex == self.petIndex ) then
			PetBattleAuraHolder_Update(self);
		end
	end
end

function PetBattleAuraHolder_SetUnit(self, petOwner, petIndex)
	self.petOwner = petOwner;
	self.petIndex = petIndex;
	PetBattleAuraHolder_Update(self);
end

function PetBattleAuraHolder_Update(self)
	if ( not self.petOwner or not self.petIndex ) then
		self:Hide();
		return;
	end

	local growsTo = self.growsToDirection;
	local numPerRow = self.numPerRow;
	local growsFrom = "LEFT";
	if ( growsTo == "LEFT" ) then
		growsFrom = "RIGHT";
	end

	local nextFrame = 1;
	for i=1, C_PetBattles.GetNumAuras(self.petOwner, self.petIndex) do
		local auraID, instanceID, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(self.petOwner, self.petIndex, i);
		if ( (isBuff and self.displayBuffs) or (not isBuff and self.displayDebuffs) ) then
			--We want to display this frame.
			local frame = self.frames[nextFrame];
			if ( not frame ) then
				--No frame, create one
				self.frames[nextFrame] = CreateFrame("FRAME", nil, self, self.template);
				frame = self.frames[nextFrame];

				--Anchor the new frame
				if ( nextFrame == 1 ) then
					frame:SetPoint("TOP"..growsFrom, self, "TOP"..growsFrom, 0, 0);
				elseif ( (nextFrame - 1) % numPerRow == 0 ) then
					frame:SetPoint("TOP"..growsFrom, self.frames[nextFrame - numPerRow], "BOTTOM"..growsFrom, 0, 0);
				else
					frame:SetPoint("TOP"..growsFrom, self.frames[nextFrame - 1], "TOP"..growsTo, 0, 0);
				end
			end

			--Update the actual aura
			local id, name, icon, maxCooldown, description = C_PetBattles.GetAbilityInfoByID(auraID);

			if ( isBuff ) then
				frame.DebuffBorder:Hide();
			else
				frame.DebuffBorder:Show();
			end

			frame.Icon:SetTexture(icon);
			if ( turnsRemaining < 0 ) then
				frame.Duration:SetText("");
			else
				frame.Duration:SetFormattedText(PET_BATTLE_AURA_TURNS_REMAINING, turnsRemaining);
			end
			frame.auraIndex = i;
			frame:Show();

			nextFrame = nextFrame + 1;
		end
	end

	if ( nextFrame > 1 ) then
		--We have at least one aura displayed
		local numRows = math.floor((nextFrame - 2) / numPerRow) + 1; -- -2, 1 for this being the "next", not "previous" frame, 1 for 0-based math.
		self:SetHeight(self.frames[1]:GetHeight() * numRows);
		self:Show();
	else
		--Empty
		self:SetHeight(1);
		self:Hide();
	end

	for i=nextFrame, #self.frames do
		self.frames[i]:Hide();
	end
end

function PetBattleAura_OnEnter(self)
	local parent = self:GetParent();
	local isEnemy = (parent.petOwner == LE_BATTLE_PET_ENEMY);
	PetBattleAbilityTooltip_SetAura(parent.petOwner, parent.petIndex, self.auraIndex);
	if ( isEnemy ) then
		PetBattleAbilityTooltip_Show("TOPRIGHT", self, "BOTTOMLEFT", 15, 5);
	else
		PetBattleAbilityTooltip_Show("TOPLEFT", self, "BOTTOMRIGHT", -15, 5);
	end
end

function PetBattleAura_OnLeave(self)
	PetBattlePrimaryAbilityTooltip:Hide();
end

PET_BATTLE_AURA_INFO = {};
function PET_BATTLE_AURA_INFO:GetAbilityID()
	local auraID, instanceID, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(self.petOwner, self.petIndex, self.auraIndex);
	return auraID;
end

function PET_BATTLE_AURA_INFO:GetCooldown()
	return 0;
end

function PET_BATTLE_AURA_INFO:GetRemainingDuration()
	local auraID, instanceID, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(self.petOwner, self.petIndex, self.auraIndex);
	return turnsRemaining;
end

function PET_BATTLE_AURA_INFO:IsInBattle()
	return true;
end

function PET_BATTLE_AURA_INFO:GetMaxHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetMaxHealth(petOwner, petIndex);
end

function PET_BATTLE_AURA_INFO:GetHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetHealth(petOwner, petIndex);
end

function PET_BATTLE_AURA_INFO:GetAttackStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetPower(petOwner, petIndex);
end

function PET_BATTLE_AURA_INFO:GetSpeedStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetSpeed(petOwner, petIndex);
end

function PET_BATTLE_AURA_INFO:GetState(stateID, target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetStateValue(petOwner, petIndex, stateID);
end

function PET_BATTLE_AURA_INFO:GetUnitFromToken(target)
	if ( target == "default" ) then
		target = "aurawearer";
	end

	if ( target == "aurawearer" ) then
		return self.petOwner, self.petIndex;
	elseif ( target == "auracaster" ) then
		--TODO: return the actual caster
		error("JSEGAL - Support auracaster");
	else
		error("Unsupported token: "..tostring(target));
	end
end

function PetBattleAbilityTooltip_SetAura(petOwner, petIndex, auraIndex)
	PET_BATTLE_AURA_INFO.petOwner = petOwner;
	PET_BATTLE_AURA_INFO.petIndex = petIndex;
	PET_BATTLE_AURA_INFO.auraIndex = auraIndex;
	SharedPetBattleAbilityTooltip_SetAbility(PetBattlePrimaryAbilityTooltip, PET_BATTLE_AURA_INFO);
end

----------------------------------------------
----------Pet Battle Aura ID Tooltip----------
----------------------------------------------
PET_BATTLE_AURA_ID_INFO = {};
function PET_BATTLE_AURA_ID_INFO:GetAbilityID()
	return self.auraID;
end

function PET_BATTLE_AURA_ID_INFO:GetCooldown()
	return 0;
end

function PET_BATTLE_AURA_ID_INFO:GetRemainingDuration()
	return 0;
end

function PET_BATTLE_AURA_ID_INFO:IsInBattle()
	return true;
end

function PET_BATTLE_AURA_ID_INFO:GetMaxHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetMaxHealth(petOwner, petIndex);
end

function PET_BATTLE_AURA_ID_INFO:GetHealth(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetHealth(petOwner, petIndex);
end

function PET_BATTLE_AURA_ID_INFO:GetAttackStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetPower(petOwner, petIndex);
end

function PET_BATTLE_AURA_ID_INFO:GetSpeedStat(target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetSpeed(petOwner, petIndex);
end

function PET_BATTLE_AURA_ID_INFO:GetState(stateID, target)
	local petOwner, petIndex = self:GetUnitFromToken(target);
	return C_PetBattles.GetStateValue(petOwner, petIndex, stateID);
end

function PET_BATTLE_AURA_ID_INFO:GetUnitFromToken(target)
	if ( target == "default" ) then
		target = "aurawearer";
	end

	if ( target == "aurawearer" ) then
		return self.petOwner, self.petIndex;
	elseif ( target == "auracaster" ) then
		--TODO: return the actual caster
		error("JSEGAL - Support auracaster");
	else
		error("Unsupported token: "..tostring(target));
	end
end

function PetBattleAbilityTooltip_SetAuraID(petOwner, petIndex, auraID)
	PET_BATTLE_AURA_ID_INFO.petOwner = petOwner;
	PET_BATTLE_AURA_ID_INFO.petIndex = petIndex;
	PET_BATTLE_AURA_ID_INFO.auraID = auraID;
	SharedPetBattleAbilityTooltip_SetAbility(PetBattlePrimaryAbilityTooltip, PET_BATTLE_AURA_ID_INFO);
end

----------------------------------------------
-------Pet Battle Ability Tooltip Funcs-------
----------------------------------------------
function PetBattleAbilityTooltip_Show(anchorPoint, anchorTo, relativePoint, xOffset, yOffset)
	PetBattlePrimaryAbilityTooltip:ClearAllPoints();
	PetBattlePrimaryAbilityTooltip:SetPoint(anchorPoint, anchorTo, relativePoint, xOffset, yOffset);
	PetBattlePrimaryAbilityTooltip:Show();
end

----------------------------------------------
------------Pet Battle Util Funcs-------------
----------------------------------------------
function PetBattleUtil_GetOtherPlayer(player)
	if ( player == LE_BATTLE_PET_ALLY ) then
		return LE_BATTLE_PET_ENEMY;
	elseif ( player == LE_BATTLE_PET_ENEMY ) then
		return LE_BATTLE_PET_ALLY;
	end
end

function PetBattleUtil_PetHasAura(petOwner, petIndex, auraID)
	for i=1, C_PetBattles.GetNumAuras(petOwner, petIndex) do
		local id, instanceID, turnsRemaining, isBuff = C_PetBattles.GetAuraInfo(petOwner, petIndex, i);
		if ( id == auraID ) then
			return true;
		end
	end
	return false;
end

