GROUND_FRICTION = .04
AIR_FRICTION = .02
GRAVITY = -2900
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 110
BOUNCE_MULTIPLIER = .9

BOUNCE_VEL_THRESHOLD = 500

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	local currVel = unit:GetPhysicsVelocity()
	local ball = Ball.unit
	local len3dSq = Length3DSq(currVel)
	unit.velocityMagnitude = len3dSq

	if unitPos.z > (GroundZ+20) and not unit.isAboveGround then
		unit.isAboveGround = true
		unit:SetGroundBehavior(PHYSICS_GROUND_NONE)
		print("unit.isAboveGround")
		--print("currVel: " .. VectorString(unit:GetPhysicsVelocity()))
		-- if hero, set the modifier up
		if not unit:HasModifier("modifier_rooted_passive") then --len3dSq > BOUNCE_VEL_THRESHOLD*BOUNCE_VEL_THRESHOLD
			if unit ~= ball then
				GlobalDummy.rooted_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_rooted_passive", {})
			end
		end

		unit.bounce_multiplier = BOUNCE_MULTIPLIER

	elseif unitPos.z <= (GroundZ+20) and unit.isAboveGround then
		-- bounce takes priority
		-- determine if bounce should occur.
		local bounceOccured = false
		--print("len3dSq: " .. len3dSq)
		if len3dSq > BOUNCE_VEL_THRESHOLD*BOUNCE_VEL_THRESHOLD and not unit.noBounce then
			--print("Bouncing.")
			currVel = Vector(currVel.x, currVel.y, math.abs(currVel.z)*unit.bounce_multiplier)
			unit.bounce_multiplier = unit.bounce_multiplier*.8
			unit:SetPhysicsVelocity(currVel)
			--print("currVel: " .. VectorString(currVel))
			bounceOccured = true
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end

		if unit.noBounce then
			unit.noBounce = false
		end

		if not bounceOccured then
			unit.isAboveGround = false
			print("not unit.isAboveGround")
			--print("currVel: " .. VectorString(unit:GetPhysicsVelocity()))
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
				unit:SetPhysicsAcceleration(BASE_ACCELERATION + dirToBall*2500)
			end
		end
		if unit == ball.controller then
			-- reposition ball to in front of controller.
			ball:SetAbsOrigin(unit:GetAbsOrigin() + Vector(fv.x,fv.y,0)*(BALL_COLLISION_DIST-40))
			ball:SetForwardVector(fv)
		end
		if unit:GetPlayerID() == 0 then
			--print("currVel: " .. VectorString(unit:GetPhysicsVelocity()))
		end
	end

	-- do above ground think logic
	if unit.isAboveGround then
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= AIR_FRICTION then
			unit:SetPhysicsFriction(AIR_FRICTION)
		end

	else
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= GROUND_FRICTION then
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end

	end

	--[[if unit.isAboveGround then
		if unit.isDSHero then
			if not unit.physics_directional_influence then
				unit.lastMovespeedVect = fv*unit:GetBaseMoveSpeed()
				unit:SetPhysicsVelocity(currVel + unit.lastMovespeedVect)
				unit.physics_directional_influence = true
			end
		end
	elseif not unit.isAboveGround then
		if unit.isDSHero then
			if unit.physics_directional_influence and not unit.isUsingPull then
				unit.physics_directional_influence = false
			end
		end
	end

	if unit.physics_directional_influence then
		local baseVel = currVel - unit.lastMovespeedVect
		unit.lastMovespeedVect = fv*unit:GetBaseMoveSpeed()
		unit:SetPhysicsVelocity(baseVel + unit.lastMovespeedVect)
	end]]

end