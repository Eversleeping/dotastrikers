Referee = {}

function Referee:Init(  )
	Referee.unit = CreateUnitByName("npc_dota_hero_omniknight", Vector(4000,4000,0), true, nil, nil, DOTA_TEAM_NEUTRALS)
	local referee = Referee.unit
	--table.insert(DotaStrikers.vHeroes, referee)

	function referee:GetBallInBounds(  )
		local ball = Ball.unit
		local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()
		local backOfBall = -250*towardsCenter + ball:GetAbsOrigin()
		referee:SetAbsOrigin(backOfBall)

	end

	function referee:TakeBallFromGoalie(  )
		
	end

	function referee:OnThink(  )
		-- snap
	end

	Timers:CreateTimer(.04, function()
		if not Referee.firstTime then
			referee:FindAbilityByName("referee_passive"):SetLevel(1)

			Referee.firstTime = true
		end
		referee:OnThink()

		return .01
	end)
end