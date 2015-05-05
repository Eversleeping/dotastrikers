GROUND_FRICTION = .04
AIR_FRICTION = .02
GRAVITY = -2900
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 120
BOUNCE_MULTIPLIER = .9
PULL_ACCEL_FORCE = 2300
BOUNCE_VEL_THRESHOLD = 500
CRACK_THRESHOLD = BOUNCE_VEL_THRESHOLD*2

NUM_BOUNCE_SOUNDS = 3

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	local currVel = unit:GetPhysicsVelocity()
	local ball = Ball.unit
	local len3dSq = Length3DSq(currVel)
	local currTime = GameRules:GetGameTime()
	unit.velocityMagnitude = len3dSq

	if unitPos.z > (GroundZ+20) and not unit.isAboveGround then
		unit.isAboveGround = true
		unit:SetGroundBehavior(PHYSICS_GROUND_NONE)
		--print("unit.isAboveGround")
		-- if hero, set the modifier up
		if not unit:HasModifier("modifier_rooted_passive") then
			if unit ~= ball then
				GlobalDummy.rooted_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_rooted_passive", {})
			end
		end

		unit.bounce_multiplier = BOUNCE_MULTIPLIER

	elseif unitPos.z <= (GroundZ+20) and unit.isAboveGround then
		-- bounce takes priority
		-- determine if bounce should occur.
		local bounceOccured = false
		if len3dSq > BOUNCE_VEL_THRESHOLD*BOUNCE_VEL_THRESHOLD and not unit.noBounce then
			--print("Bouncing.")
			currVel = Vector(currVel.x, currVel.y, math.abs(currVel.z)*unit.bounce_multiplier)
			unit.bounce_multiplier = unit.bounce_multiplier*.8
			unit:SetPhysicsVelocity(currVel)
			bounceOccured = true
			if not unit.dontChangeFriction then
				unit:SetPhysicsFriction(GROUND_FRICTION)
			end
			if unit == ball and (currTime-ball.lastBounceTime > .3) and not ball.controller then
				if not ball.affectedByPowershot then -- powershot will call this sound too many times.
					ball:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
				end
				ball.lastBounceTime = currTime
				--[[if ball.affectedByPowershot then
					ParticleManager:CreateParticle("particles/units/heroes/hero_silencer/silencer_last_word_trigger_cracks.vpcf", PATTACH_ABSORIGIN, ball)
				else
					ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze_ground_cracks.vpcf", PATTACH_ABSORIGIN, ball)
				end]]
			elseif unit ~= ball then
				if len3dSq > CRACK_THRESHOLD*CRACK_THRESHOLD then
					unit:EmitSound("ThunderClapCaster")
					ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_ABSORIGIN, unit)
				end
			end
		end

		if unit.noBounce then
			unit.noBounce = false
		end

		if not bounceOccured then
			unit.isAboveGround = false
			--print("not unit.isAboveGround")
			-- if hero, remove the modifier
			if unit:HasModifier("modifier_rooted_passive") then
				unit:RemoveModifierByName("modifier_rooted_passive")
			end
			unit:SetGroundBehavior(PHYSICS_GROUND_ABOVE)
		end
	end

	if unit.isDSHero then
		local fv = unit:GetForwardVector()
		if unit.isUsingPull then
			-- it's imba is the puller already has the pull and she's using pull.
			if ball.controller ~= unit then
				local dirToBall = (Ball.unit:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
				unit:SetPhysicsAcceleration(BASE_ACCELERATION + dirToBall*PULL_ACCEL_FORCE)
			end
		end
	end

	-- do above ground think logic
	if unit.isAboveGround then
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= AIR_FRICTION then
			--if unit == Ball.unit then print("Changing ball friciton.") end
			unit:SetPhysicsFriction(AIR_FRICTION)
		end

	else
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= GROUND_FRICTION then
			--if unit == Ball.unit then print("Changing ball friciton.") end
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end

	end
end