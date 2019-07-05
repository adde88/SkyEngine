DispelList = { -- Proving Grounds
			   'Aqua Bomb', 
			   -- Atal'Dazar
			   'Unstable Hex', 'Wracking Pain', 'Lingering Nausea', 'Wildfire', 'Molten Gold', 'Terrifying Screech', 'Terrifying Visage', 'Venomfang Strike', 'Soulburn', 'Rending Maul',
               'Devour', 'Serrated Teeth', 'Soulfeast', 'Tainted Blood', 'Soulrend',
			   -- Kings Rest		
			   }
PlayerIsInCombat = false 
IsSafe = false
OnOff = "Off"
AverageGroupHealthPercent = 100
local CurrentSpecID = 0

local function MainEvents(self,event,...)
	if event == "PLAYER_REGEN_ENABLED" then
		print("Leaving combat")
		PlayerIsInCombat = false        
	end
	if event == "PLAYER_REGEN_DISABLED" then
		print("Entering combat")
		PlayerIsInCombat = true        
	end
	if event == "PLAYER_ENTERING_WORLD" then
		--IsSafe = issecure() 
		IsSafe = true
		if not IsSafe then		
			print('Please make this addon safe to use')
		else
			print('Sky Engine Loaded.')			
			CurrentSpecID = GetSpecialization() and select(1,GetSpecializationInfo(GetSpecialization())) or 0
			print('Current Spec ID: ' .. CurrentSpecID)
		end		
	end	
	if event == "UNIT_SPELLCAST_SUCCEEDED" then				
		local unit, _, spellId = ...
		if unit == 'player' then
			LastSuccessfulSpell = GetSpellInfo(spellId)
			--print(LastSuccessfulSpell)
		end
	end	
	if event == "UNIT_SPELLCAST_START" then				
		local unit, _, spellId = ...
		if unit == 'player' then			
			print(GetSpellInfo(spellId))
		end
	end	
end

mainFrame = CreateFrame("frame","",parent)
mainFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
mainFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
mainFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
--mainFrame:RegisterEvent("UNIT_SPELLCAST_START")
mainFrame:SetScript("OnEvent",MainEvents)
	
function EffectiveHealthPercent(unit)
	if UnitIsDead(unit) or UnitIsGhost(unit) then
		return 0
	end
			
	return ceil((UnitHealth(unit) + UnitGetIncomingHeals(unit) / UnitHealthMax(unit)) * 100)
end


function HealthPercent(unit)
	if UnitIsDead(unit) or UnitIsGhost(unit) then
		return 0
	end
			
	return ceil((UnitHealth(unit) / UnitHealthMax(unit)) * 100)
end

local function NeedsDispel(unit)
    --print('Checking if unit ['..unit..'] needs a dispel')
    for _,spellName in pairs(DispelList) do        
		if HasDebuff(spellName, unit) then 
			print('Dispel: ' .. spellName)
			return true 
		end
    end
    return false
end

local function IsMoving()
	return GetUnitSpeed('player') ~= 0
end

function DispelUnit()	
	local groupType 
	local dispelUnit = nil
	if GetNumGroupMembers() == 0 or GetNumGroupMembers() == 1 then 
		if NeedsDispel('player') then return 'player' end
	else		
		local unit = 'player'		
		groupType = IsInRaid() and 'raid' or 'party'
		for unitNo = 1, GetNumGroupMembers() do		 
			if (groupType == "party") then
				if (unitNo == 1) then unit = 'player' else unit = groupType..(unitNo - 1) end			
				if NeedsDispel(unit) then return unit end				
			end
			if (groupType == "raid") then
				unit = groupType..unitNo 
				if NeedsDispel(unit) then return unit end
			end
		end
	end
	return dispelUnit
end

function LowestHealthUnit()	
	local TotalHealthPercent = 0
	local groupType 
	local lowestUnit
	if GetNumGroupMembers() == 0 or GetNumGroupMembers() == 1 then 
		lowestUnit = HealthPercent('player') 		
		AverageGroupHealthPercent = lowestUnit
		groupType = 'solo'
	else
		local lowestHP = 100
		local unit = 'player'
		lowestUnit = 'player'	
		groupType = IsInRaid() and 'raid' or 'party'
		for unitNo = 1, GetNumGroupMembers() do		 
			if (groupType == "party") then
				if (unitNo == 1) then unit = 'player' else unit = groupType..(unitNo - 1) end			
				currentHP = HealthPercent(unit)
				TotalHealthPercent = TotalHealthPercent + currentHP
				--print ('Unit ['..unit..'] Health: ' .. currentHP)
				if currentHP < lowestHP and currentHP > 0 then 
					lowestHP = currentHP
					lowestUnit = unit
				end
			end
			if (groupType == "raid") then
				unit = groupType..unitNo 
				currentHP = HealthPercent(unit)
				TotalHealthPercent = TotalHealthPercent + currentHP
				--print ('Unit ['..unit..'] Health: ' .. currentHP)
				if currentHP < lowestHP and currentHP > 0 then 
					lowestHP = currentHP
					lowestUnit = unit
				end
			end
		end
		AverageGroupHealthPercent = floor(TotalHealthPercent / GetNumGroupMembers())
	end
	
	--print('Group Type: ['..groupType..'] Lowest HP unit: [' .. lowestUnit ..']')
	--print('Group Type: ['..groupType..'] AverageGroupHealthPercent: [' .. AverageGroupHealthPercent ..']')
	return lowestUnit
end

function HasBuff(auraName, target) 
	if not UnitExists(target) then 
		return false 
	end			
	for index = 1, 40 do
		name = UnitBuff(target, index)
		if (name == auraName) then
			return true				
		end	
	end
	return false
end

function HasDebuff(auraName, target) 
	if not UnitExists(target) then 
		return false 
	end			
	for index = 1, 40 do
		name = UnitDebuff(target, index)
		if (name == auraName) then
			return true				
		end	
	end
	return false
end

local function CanCast(spellName)
	local start, duration, enabled, modRate = GetSpellCooldown(spellName)
	local remainingTime = (start + duration - GetTime() - select(4, GetNetStats()) / 1000)
	if remainingTime < 0 then
		remainingTime = 0
	end
	
	local isUsable, notEnoughMana = IsUsableSpell(spellName)
	if notEnoughMana then return false end	
	if not isUsable then return false end	
	return remainingTime == 0
end

local function CastSpell(spellName, target)
	if not UnitExists(target) then return end
	if not UnitCastingInfo('player') and CanCast(spellName) then	
	if HealthPercent(target) == 0 then return end
		CastSpellByName(spellName, target)
		if StaticPopup1:IsVisible() then StaticPopup1:Hide() end
	end
end

local function IsEnemy(target)
	if not UnitExists(target) then return false end
	return UnitCanAttack('player', target)
end

local function IsFriend(target)
	if not UnitExists(target) then return true end
	return not UnitCanAttack('player', target)
end

local function AssistFocus()	
	if not UnitExists('focus') then return end
	RunMacroText('/assist focus')	
	if StaticPopup1:IsVisible() then StaticPopup1:Hide() end
end

function PulseMain()
	 DispelUnit()
end

C_Timer.NewTicker(0.5, PulseMain)

function PulseDisc()				
	if OnOff ~= "On" then return end;	
	if CurrentSpecID ~= 256 then return end	
	if not IsSafe then return end
	if IsMounted() then return end
	if UnitChannelInfo('player') then return end	
	if HealthPercent('player') <= 0 then return end
	
	-- Return if we on GCD
	local start, duration, enabled, modRate = GetSpellCooldown(61304) 
	local cdLeft = start + duration - GetTime() - select(4, GetNetStats()) / 1000
	if cdLeft > 0 then return end
	
	if not HasBuff('Power Word: Fortitude', 'player') then CastSpell("Power Word: Fortitude", 'player') end
	
	if IsMoving() and not HasBuff('Angelic Feather', 'player') and IsSpellKnown(121536) then CastSpell("Angelic Feather", 'player') end
	
	dispelUnit = DispelUnit()	
	if dispelUnit then CastSpell('Purify', dispelUnit) end
		
	healUnit = LowestHealthUnit()
	if HealthPercent(healUnit) < 95 then
		if not HasBuff('Power Word: Shield', healUnit) then CastSpell('Power Word: Shield', healUnit) end
		CastSpell('Penance', healUnit) 		
		if not IsMoving() then CastSpell('Shadow Mend', healUnit) end		
	end
	
	if not PlayerIsInCombat then return end
	if not UnitExists('target') then 
		AssistFocus()
	end	
	
	if IsEnemy('target') then
		CastSpell('Penance', 'target') 
		CastSpell('Mindbender', 'target') 	
		if not HasDebuff('Purge the Wicked', 'target') then CastSpell('Purge the Wicked', 'target') end		
		if not HasDebuff('Schism', 'target') and not IsMoving() then CastSpell('Schism', 'target') end
		if not IsMoving() then CastSpell('Smite', 'target') end
	end	
end

C_Timer.NewTicker(0.5, PulseDisc)

function PulseWind()				
	if OnOff ~= "On" then return end;	
	if CurrentSpecID ~= 269 then return end
	if not IsSafe then return end
	if IsMounted() then return end
	if UnitChannelInfo('player') then return end	
	if HealthPercent('player') <= 0 then return end	
	
	-- Return if we on GCD
	local start, duration, enabled, modRate = GetSpellCooldown(61304) 
	local cdLeft = start + duration - GetTime() - select(4, GetNetStats()) / 1000
	if cdLeft > 0 then return end
	
	if HealthPercent('player') <= 50 or (not PlayerIsInCombat and HealthPercent('player') < 100) then
		CastSpell('Vivify', 'player') 
	end
	
	if IsEnemy('target') then
		if HealthPercent('player') <= 20 then CastSpell('Touch of Karma', 'target') end	
		CastSpell('Invoke Xuen, the White Tiger', 'target') 		
		CastSpell('Storm, Earth, and Fire', 'target') 
		CastSpell('Touch of Death', 'target') 
		if LastSuccessfulSpell ~= 'Fists of Fury' then CastSpell('Fists of Fury', 'target') end
		if LastSuccessfulSpell ~= 'Chi Wave' then CastSpell('Chi Wave', 'target') end
		if LastSuccessfulSpell ~= 'Tiger Palm' then CastSpell('Tiger Palm', 'target') end
		if LastSuccessfulSpell ~= 'Rising Sun Kick' then CastSpell('Rising Sun Kick', 'target') end
		if LastSuccessfulSpell ~= 'Blackout Kick' then CastSpell('Blackout Kick', 'target') end
		CastSpell('Energizing Elixir', 'player') 
	end
end

C_Timer.NewTicker(0.5, PulseWind)

function PulseGuardian()	
    if OnOff ~= "On" then return end;				
	if CurrentSpecID ~= 104 then return end
	if not IsSafe then return end
	if IsMounted() then return end
	if UnitChannelInfo('player') then return end	
	if HealthPercent('player') <= 0 then return end	
	
	-- Return if we on GCD
	local start, duration, enabled, modRate = GetSpellCooldown(61304) 
	local cdLeft = start + duration - GetTime() - select(4, GetNetStats()) / 1000
	if cdLeft > 0 then return end
	
	if HealthPercent('player') < 90 and not PlayerIsInCombat then CastSpell('Regrowth', 'player') return end	
	
	if IsSwimming() and GetShapeshiftForm() ~=3 and not PlayerIsInCombat then CastSpell('Travel Form', 'player') return end
	
	if IsFalling() and GetShapeshiftForm() == 0 then
		CastSpell('Cat Form', 'player') return 
	else
		if GetShapeshiftForm() ~= 1 and PlayerIsInCombat then CastSpell('Bear Form', 'player') return end		
	end
	
	if IsEnemy('target') then
		if HealthPercent('player') <= 20 then CastSpell('Survival Instincts', 'target') end	
		if not HasDebuff('Moonfire', 'target') then CastSpell('Moonfire', 'target') end		
		if not HasDebuff ('Thrash', 'target') then CastSpell('Thrash', 'target') end
		CastSpell('Mangle', 'target')
		CastSpell('Thrash', 'target')
		if HasBuff('Galactic Guardian', 'player') then CastSpell('Moonfire', 'target') end
		if HealthPercent('player') <= 90 and PlayerIsInCombat then CastSpell('Ironfur', 'player') end	
		if HealthPercent('player') <= 70 and PlayerIsInCombat then CastSpell('Frenzied Regeneration', 'player') end	
		CastSpell('Maul', 'target')
		CastSpell('Swipe', 'target')
	end
end

C_Timer.NewTicker(0.5, PulseGuardian)

function PulseResto()	
    if OnOff ~= "On" then return end;				
	if CurrentSpecID ~= 104 then return end
	if not IsSafe then return end
	if IsMounted() then return end
	if UnitChannelInfo('player') then return end	
	if HealthPercent('player') <= 0 then return end	
	
	-- Return if we on GCD
	local start, duration, enabled, modRate = GetSpellCooldown(61304) 
	local cdLeft = start + duration - GetTime() - select(4, GetNetStats()) / 1000
	if cdLeft > 0 then return end
	
	dispelUnit = DispelUnit()	
	if dispelUnit then CastSpell("Nature's Cure", dispelUnit) end
		
	healUnit = LowestHealthUnit()
	if HealthPercent(healUnit) < 95 then		
		if not HasBuff('Rejuvenation', healUnit) then CastSpell('Rejuvenation', healUnit) end		
		if not IsMoving() then CastSpell('Regrowth', healUnit) end		
	end
end

C_Timer.NewTicker(0.5, PulseResto)