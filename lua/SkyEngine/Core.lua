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
	secured = false
    while not secured do
      RunScript([[
        for index = 1, 500 do
          if not issecure() then
            return
          end
        end
        CastSpellByName("]] .. spellName .. [[", "]] .. target .. [[")
        secured = true
      ]])
	end
	if StaticPopup1:IsVisible() then StaticPopup1:Hide() end	
end

function Rotation()					
	if IsMounted() then return end
	
	if not HasBuff('Flash Heal', 'player') then CastSpell('Flash Heal', 'player') end
end

C_Timer.NewTicker(0.5, Rotation)