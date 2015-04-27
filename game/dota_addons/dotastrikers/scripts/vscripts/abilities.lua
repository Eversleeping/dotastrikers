THROW_VELOCITY = 2000
SURGE_TICK = .2
SLAM_Z = 2500
BASE_SPEED = 380
MAX_PULL_DURATION = 4.55

function DotaStrikers:OnRefereeAttacked( keys )
	print("OnRefereeAttacked")
	local attacked = keys.target
	local ball = Ball.unit

	local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()
	--print("towardsCenter: " .. VectorString(towardsCenter))
	ball.controlledByRef = true
	ball.controller = nil
	ball:SetPhysicsVelocity(towardsCenter*4000)
	local caster = keys.caster
	caster:SetAbsOrigin(Vector(4000,4000,0))
	caster:Stop()
	ball:SetHealth(ball:GetMaxHealth())
end

function DotaStrikers:on_powershot_succeeded( keys )
	print("on_powershot_succeeded")
	local caster = keys.caster
	local ball = Ball.unit
	local dir = caster.throw_direction
	ball.controller:EmitSound("Hero_VengefulSpirit.MagicMissile")
	ball.dontChangeFriction = true
	ball.affectedByPowershot = true
	ball:SetPhysicsFriction(0)
	ball.powershot_particle = ParticleManager:CreateParticle("particles/powershot/windrunner_spell_powershot.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball)
	ParticleManager:SetParticleControl(ball.powershot_particle, 1, ball:GetPhysicsVelocity())
	ball:AddPhysicsVelocity(dir*1600)

end

function DotaStrikers:throw_ball( keys )
	--PrintTable(keys)
	--print("get_throw_point")
	local caster = keys.caster
	local ball = Ball.unit
	if caster ~= ball.controller then return end

	local point = keys.target_points[1]
	local dir = (point-ball:GetAbsOrigin()):Normalized()

	if keys.ability:GetAbilityName() == "powershot" then
		-- begin the channeling portion
		caster.throw_direction = dir
		caster:CastAbilityNoTarget(caster:FindAbilityByName("powershot_channel"), 0)
	else
		ball.controller:EmitSound("Hero_Puck.Attack")
		ball:AddPhysicsVelocity(dir*THROW_VELOCITY)
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

		caster.surgeParticle = ParticleManager:CreateParticle("particles/generic_gameplay/rune_haste_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		caster:SetBaseMoveSpeed(caster.base_move_speed + caster.base_move_speed*2/3)
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
	caster:AddPhysicsVelocity(caster:GetForwardVector()*700 + Vector(0,0,1500))
	if caster == Ball.unit.controller then
		Ball.unit:AddPhysicsVelocity(Vector(0,0,1400))
	end
	caster.noBounce = true

end
