THROW_VELOCITY = 1300
SURGE_TICK = .2
SLAM_Z = 2900
SLAM_XY = 1300
BASE_SPEED = 380
MAX_PULL_DURATION = 4.55
PSHOT_VELOCITY = 1600
PSHOT_ONHIT_VEL = 1300
NINJA_JUMP_Z = 1300
NINJA_JUMP_XY = 600

REF_OOB_HIT_VEL = 2200 -- referee out of bounds hit velocity.
NUM_KICK_SOUNDS = 4

function DotaStrikers:OnAbilityUsed( keys )
	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()
	local ball = Ball.unit

	if abilityname == "slam" then

	end


end

function DotaStrikers:OnRefereeAttacked( keys )
	print("OnRefereeAttacked")
	local attacked = keys.target
	local ball = Ball.unit

	local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()
	--print("towardsCenter: " .. VectorString(towardsCenter))
	ball.controlledByRef = true
	ball.controller = nil
	ball:SetPhysicsVelocity(towardsCenter*REF_OOB_HIT_VEL)
	local caster = keys.caster
	Timers:CreateTimer(.2, function()
		caster:SetAbsOrigin(Vector(4000,4000,0))
		caster:Stop()
	end)
	ball:SetHealth(ball:GetMaxHealth())
end

function DotaStrikers:on_powershot_succeeded( keys )
	--print("on_powershot_succeeded")
	local caster = keys.caster
	local ball = Ball.unit
	-- occurs when invoker got his ball stolen while channeling pshot.
	if ball.controller ~= caster then return end

	local dir = caster.throw_direction
	ball.controller:EmitSound("Hero_VengefulSpirit.MagicMissile")
	ball.controller = nil
	ball.dontChangeFriction = true
	ball.affectedByPowershot = true
	ball:SetPhysicsFriction(0)
	--ball.powershot_particle = ParticleManager:CreateParticle("particles/powershot/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball)
	ball.powershot_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)
	ball:AddPhysicsVelocity(dir*PSHOT_VELOCITY)

	if not Testing then
		caster:FindAbilityByName("powershot"):StartCooldown(10)
	end
end

function DotaStrikers:throw_ball( keys )
	--PrintTable(keys)
	--print("get_throw_point")
	local caster = keys.caster
	local ball = Ball.unit
	if caster ~= ball.controller then return end

	local point = keys.target_points[1]
	local ballPos = ball:GetAbsOrigin()
	local dir = (Vector(point.x,point.y,ballPos.z)-ballPos):Normalized()

	if keys.ability:GetAbilityName() == "powershot" then
		-- begin the channeling portion
		caster.throw_direction = dir
		caster:CastAbilityNoTarget(caster:FindAbilityByName("powershot_channel"), 0)
	else
		--ball.controller:EmitSound("Hero_Puck.Attack")
		ball:AddPhysicsVelocity(dir*THROW_VELOCITY)
		ball:EmitSound("Kick" .. RandomInt(1, NUM_KICK_SOUNDS))
		ball.controller = nil
	end
end

function DotaStrikers:surge( keys )
	local caster = keys.caster
	caster.surgeOn = true

	-- apply effects
	--particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf
	--particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf
	--particles/generic_gameplay/rune_haste_owner.vpcf
	--caster.surgeParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	-- use this 1 for DH
	--
	if caster:GetClassname() ~= "npc_dota_hero_antimage" then
		caster:RemoveAbility("surge")
		caster:AddAbility("surge_break")
		caster:FindAbilityByName("surge_break"):SetLevel(1)

		--particles/generic_gameplay/rune_haste_owner.vpcf
		caster.surgeParticle = ParticleManager:CreateParticle("particles/items2_fx/phase_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

		-- play local phaseboots sound.
		local phaseBoots = CreateItem("item_phase", caster, caster)
		-- apparently this works fine without timers.
		caster:AddItem(phaseBoots)
		caster:CastAbilityImmediately(phaseBoots, 0)
		caster:RemoveItem(phaseBoots)

		caster:SetBaseMoveSpeed(caster.base_move_speed + caster.base_move_speed*1/3)
	else
		caster:RemoveAbility("surge_sprint")
		caster:AddAbility("surge_break_sprint")
		caster:FindAbilityByName("surge_break_sprint"):SetLevel(1)

		caster.surgeParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		--caster.dontChangeFriction = true
		--caster:SetPhysicsFriction(0)
		--caster:AddPhysicsVelocity(caster:GetForwardVector()*400)
		caster:AddPhysicsAcceleration(caster:GetForwardVector()*800)

	end


end

function DotaStrikers:surge_break( keys )
	local caster = keys.caster
	caster.surgeOn = false

	if caster:GetClassname() ~= "npc_dota_hero_antimage" then
		caster:RemoveAbility("surge_break")
		caster:AddAbility("surge")
		caster:FindAbilityByName("surge"):SetLevel(1)
		caster:SetBaseMoveSpeed(caster.base_move_speed)

	else
		caster:RemoveAbility("surge_break_sprint")
		caster:AddAbility("surge_sprint")
		caster:FindAbilityByName("surge_sprint"):SetLevel(1)
		--[[caster.dontChangeFriction = false
		if caster.isAboveGround then
			caster:SetPhysicsFriction(AIR_FRICTION)
		else
			caster:SetPhysicsFriction(GROUND_FRICTION)
		end]]

	end

	ParticleManager:DestroyParticle(caster.surgeParticle, false)


end

function DotaStrikers:pull( keys )
	local caster = keys.caster
	caster.isUsingPull = true
	caster:RemoveAbility("pull")
	caster:AddAbility("pull_break")
	caster.pull_break = caster:FindAbilityByName("pull_break")
	caster.pull_break:SetLevel(1)

	local ball = Ball.unit

	-- particle
	caster.pullParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	--caster.pullParticle = ParticleManager:CreateParticle("particles/econ/items/puck/puck_alliance_set/puck_dreamcoil_tether_aproset.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	--ParticleManager:SetParticleControl(caster.pullParticle, 1, ball:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(caster.pullParticle, 1, ball, 1, "follow_origin", ball:GetAbsOrigin(), true)

	caster.pull_start_time = GameRules:GetGameTime()
	caster.pull_timer = Timers:CreateTimer(MAX_PULL_DURATION, function()
		--caster.pull_duration = caster.pull_duration + .5
		if caster.isUsingPull then
			caster:CastAbilityNoTarget(caster.pull_break, 0)
		end
	end)


end

function DotaStrikers:pull_break( keys )
	local caster = keys.caster
	caster.isUsingPull = false
	caster:RemoveAbility("pull_break")
	caster:AddAbility("pull")
	local pullAbility = caster:FindAbilityByName("pull")
	pullAbility:SetLevel(1)

	-- remove particle effect
	ParticleManager:DestroyParticle(caster.pullParticle, false)

	Timers:RemoveTimer(caster.pull_timer)

	-- revert acceleration
	caster:SetPhysicsAcceleration(BASE_ACCELERATION)

	-- give hero one final push
	--local dirToBall = (Ball.unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	--caster:AddPhysicsVelocity(1000*dirToBall)

	-- determine cooldown to set
	local timeDiff = GameRules:GetGameTime() - caster.pull_start_time
	if timeDiff < 1.5 then
		pullAbility:StartCooldown(10)
	elseif timeDiff < 2.5 then
		pullAbility:StartCooldown(15)
	elseif timeDiff < 3.5 then
		pullAbility:StartCooldown(20)
	elseif timeDiff < 4.5 then
		pullAbility:StartCooldown(25)
	else
		pullAbility:StartCooldown(30)
	end
	if Testing then
		pullAbility:EndCooldown()
	end

end

function DotaStrikers:ninja_jump( keys )
	local caster = keys.caster
	caster:AddPhysicsVelocity(caster:GetForwardVector()*NINJA_JUMP_XY + Vector(0,0,NINJA_JUMP_Z))
	caster.noBounce = true

	if Testing then keys.ability:EndCooldown() end
end

function DotaStrikers:text_particle( keys )
	local caster = keys.caster
	local abilName = keys.ability:GetAbilityName()
	local particle = "particles/pass_me/legion_commander_duel_victory_text.vpcf"

	if abilName == "frown" then
		local frownIndex = RandomInt(1, 5)
		particle = "particles/frowns/frown" .. frownIndex .. ".vpcf"
	end

	if caster.textParticle then
		ParticleManager:DestroyParticle(caster.textParticle, true)
		caster.textParticle = nil
	end
	caster.textParticle = ParticleManager:CreateParticle(particle, PATTACH_OVERHEAD_FOLLOW, caster)
	if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
		ParticleManager:SetParticleControl(caster.textParticle, 1, Vector(0,255,0))
	else
		ParticleManager:SetParticleControl(caster.textParticle, 1, Vector(255,0,0))
	end
	ParticleManager:SetParticleControlEnt(caster.textParticle, 3, caster, 3, "follow_origin", caster:GetAbsOrigin(), true)

end

function DotaStrikers:OnCantEnterGoalPost( unit )
	local currTime = GameRules:GetGameTime()
	if currTime-unit.lastShieldParticleTime > .03 then
		local pos = unit:GetAbsOrigin()
		local fv = unit:GetForwardVector()
		unit.shieldParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact_highlight01.vpcf", PATTACH_CUSTOMORIGIN, unit)
		ParticleManager:SetParticleControl(unit.shieldParticle, 0, Vector(pos.x,pos.y,pos.z-70) + Vector(fv.x,fv.y,0)*40)
		--ParticleManager:SetParticleControl(unit.shieldParticle, 0, Vector(pos.x,pos.y,pos.z-80) + Vector(fv.x,fv.y,0)*50)
		unit.lastShieldParticleTime = currTime
	end
end

function DotaStrikers:slam( keys )
	local caster = keys.caster
	local hero = caster
	local ball = Ball.unit

	local radius = hero:FindAbilityByName("slam"):GetCastRange()
	local affected = 0
	--print("radius: " .. radius)
	for i, ent in ipairs(Entities:FindAllInSphere(hero:GetAbsOrigin(), radius)) do
		if IsPhysicsUnit(ent) then
			local dir = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized()
			local dist = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Length()
			local knockbackScale = (radius-dist)/radius
			-- if it's the ball and ball has a controller, don't move the ball.
			-- if it's the slammer, don't move him
			if (ent == ball and ball.controller ~= nil) or ent == hero then

			else
				if ent == ball then
					ball.lastController = caster
				end
				ent:AddPhysicsVelocity((dir*SLAM_XY + Vector(0,0,SLAM_Z)*knockbackScale))
				affected = affected + 1
			end
		end
	end
	--[[if affected == 0 then
		hero:EmitSound("Hero_EarthShaker.IdleSlam")
	elseif affected == 1 then
		hero:EmitSound("Hero_EarthShaker.EchoSlamSmall")
	else
		hero:EmitSound("Hero_EarthShaker.EchoSlam")
	end]]

	local echoDummy = CreateUnitByName("dummy", hero:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
	local slamDummyAbil = echoDummy:FindAbilityByName("slam_dummy")
	Timers:CreateTimer(NEXT_FRAME, function()
		echoDummy:CastAbilityImmediately(slamDummyAbil, 0)
		Timers:CreateTimer(1, function()
			echoDummy:ForceKill(true)
		end)
	end)

	if Testing then
		keys.ability:EndCooldown()
	end
end