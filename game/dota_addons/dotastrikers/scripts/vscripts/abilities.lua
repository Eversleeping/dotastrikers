function OnRefereeAttacked( keys )
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

function get_throw_point( keys )
	local hero = keys.caster
	local ball = Ball.unit
	if not ball.controller or hero ~= ball.controller then return end

	local point = keys.target_points[1]
	local pos = ball.controller:GetAbsOrigin()
	local dir = (point-pos):Normalized()

	local dummy = CreateUnitByName("dummy_no_invuln", pos + dir*200, false, nil, nil, ball.controller:GetOpposingTeamNumber())
	ball.controller.throwPoint = point
	local abil = ball.controller:FindAbilityByName("throw_target")
	dummy.throwDummy = true

	Timers:CreateTimer(NEXT_FRAME, function()
		ball.controller:CastAbilityOnTarget(dummy, abil, 0)
	end)

	Timers:CreateTimer(1, function()
		dummy:ForceKill(false)
	end)
end

function throw_target( keys )
	local ball = Ball.unit
	-- prevent ability from being used on things other than the throwDummy.
	if not keys.target.throwDummy then
		return
	end
	local direction = (keys.caster.throwPoint-ball:GetAbsOrigin()):Normalized()
	ball.controller:EmitSound("Hero_Puck.Attack")
	ball:SetForwardVector(direction)
	ball:AddPhysicsVelocity(direction*1900)
	--print("adding vel.")
end

function surge( keys )
	local caster = keys.caster
	caster:RemoveAbility("surge")
	caster:AddAbility("surge_break")
	caster:FindAbilityByName("surge_break"):SetLevel(1)
	caster.surgeOn = true

	-- apply effects
	--particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf
	--particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf
	--particles/generic_gameplay/rune_haste_owner.vpcf
	--caster.surgeParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	caster.surgeParticle = ParticleManager:CreateParticle("particles/generic_gameplay/rune_haste_owner.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	-- use this 1 for DH
	--caster.surgeParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	caster:SetBaseMoveSpeed(caster.base_move_speed + caster.base_move_speed*2/3)



end

function surge_break( keys )
	local caster = keys.caster
	caster:RemoveAbility("surge_break")
	caster:AddAbility("surge")
	caster:FindAbilityByName("surge"):SetLevel(1)
	caster.surgeOn = false

	ParticleManager:DestroyParticle(caster.surgeParticle, false)
	caster:SetBaseMoveSpeed(caster.base_move_speed)

end

function pull( keys )
	local caster = keys.caster
	caster.isUsingPull = true
	caster:RemoveAbility("pull")
	caster:AddAbility("pull_break")
	caster.pull_break = caster:FindAbilityByName("pull_break")
	caster.pull_break:SetLevel(1)

	local ball = Ball.unit

	--[[Timers:CreateTimer(.03, function()
		if caster.isUsingPull then
			if caster.lastPullAccel then
				caster:SetPhysicsAcceleration(caster:GetPhysicsAcceleration()-caster.lastPullAccel)
				--caster:SetPhysicsVelocity(caster:GetPhysicsVelocity()-caster.lastPullVel)
			end
			local dirToBall = (ball:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
			caster.lastPullAccel = 1200*dirToBall
			caster:AddPhysicsAcceleration(caster.lastPullAccel)
		else
			return nil
		end
		return .1
	end)

	caster:AddDirectionalInfluence()]]

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

function pull_break( keys )
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

function ninja_jump( keys )
	local caster = keys.caster
	caster:AddPhysicsVelocity(caster:GetForwardVector()*700 + Vector(0,0,1500))
	if caster == Ball.unit.controller then
		Ball.unit:AddPhysicsVelocity(Vector(0,0,900))
	end
	caster.noBounce = true

end

BASE_SPEED = 380
MAX_PULL_DURATION = 4.55
