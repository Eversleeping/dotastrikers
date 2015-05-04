GROUND_FRICTION = .04
AIR_FRICTION = .02
GRAVITY = -2900
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 120
BOUNCE_MULTIPLIER = .9
PULL_ACCEL_FORCE = 2300
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
			if len3dSq > 700*700 then
				--self:DisplayCracksOnGround(unit)
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

function DotaStrikers:DisplayCracksOnGround( unit )
	if unit == Ball.unit and unit.controller then return end
	local pos = unit:GetAbsOrigin()
	local crackDummy = CreateUnitByName("dummy", pos, false, nil, nil, DOTA_TEAM_NOTEAM)
	--particles/units/heroes/hero_nevermore/nevermore_shadowraze_ground_cracks.vpcf
	crackDummy.crackParticle = ParticleManager:CreateParticle("particles/thunderclap/brewmaster_thunder_clap.vpcf", PATTACH_ABSORIGIN, crackDummy)
	crackDummy:EmitSound("Hero_EarthShaker.IdleSlam")
	Timers:CreateTimer(2, function()
		crackDummy:RemoveSelf()
	end)

end