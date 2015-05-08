BALL_PARTICLE_Z_OFFSET=45 --this makes the particle look nicer.
NUM_CATCH_SOUNDS = 3

GROUND_FRICTION = .04
AIR_FRICTION = .02
GRAVITY = -2900
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 120
BOUNCE_MULTIPLIER = .9
PULL_ACCEL_FORCE = 2300
BOUNCE_VEL_THRESHOLD = 500
CRACK_THRESHOLD = BOUNCE_VEL_THRESHOLD*2
PP_COLLISION_THRESHOLD = CRACK_THRESHOLD -- player-player collision threshold

NUM_BOUNCE_SOUNDS = 3

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	unit.currPos = unitPos
	local currVel = unit:GetPhysicsVelocity()
	local ball = Ball.unit
	local len3dSq = Length3DSq(currVel)
	local currTime = GameRules:GetGameTime()
	unit.velocityMagnitude = len3dSq
	--unit.velocityDir = 

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
					EmitSoundAtPosition("ThunderClapCaster", unit:GetAbsOrigin())
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

function Ball:Init(  )
	Ball.unit = CreateUnitByName("ball", Vector(0,0,GroundZ), true, nil, nil, DOTA_TEAM_NOTEAM)
	local ball = Ball.unit
	table.insert(DotaStrikers.colliderFilter, ball)
	BALL = ball.unit
	ball.isBall = true
	ball.particleDummy = CreateUnitByName("dummy", Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET), false, nil, nil, DOTA_TEAM_NOTEAM)
	ball.lastBounceTime = 0

	function ball:SpawnParticle(  )
		-- constantly reposition the ball particle dummy.
		ball.particleDummy:SetAbsOrigin(Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET))
		Timers:CreateTimer(2*NEXT_FRAME, function()
			if not ball.ballParticle then
				ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)
			end
			local pos = ball:GetAbsOrigin()
			ball.particleDummy:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+BALL_PARTICLE_Z_OFFSET))
			return .01
		end)
	end

	function ball:CleanUp(  )
		if ball.affectedByPowershot then
			ball.affectedByPowershot = false
			ball.dontChangeFriction = false
			ParticleManager:DestroyParticle(ball.powershot_particle, false)
			ball.affectedByPowershot = false
		end
		ball:SetPhysicsAcceleration(BASE_ACCELERATION)
		ball:SetPhysicsVelocity(Vector(0,0,0))
		ball:SetPhysicsFriction(GROUND_FRICTION)
	end

	function ball:IsBallOutOfBounds()
		local ballPos = ball:GetAbsOrigin()
		local smoothing = 20
		return ballPos.x > (Bounds.max+RectangleOffset+smoothing) or ballPos.x < (Bounds.min-RectangleOffset-smoothing) or 
			ballPos.y > (Bounds.max+smoothing) or ballPos.y < (Bounds.min-smoothing)
	end

	ball.controller = nil
	DotaStrikers:ApplyDSPhysics(ball)

	ball:OnPhysicsFrame(function(unit)
		DotaStrikers:OnMyPhysicsFrame(ball)
		local ballPos = ball:GetAbsOrigin()

		for _,hero in ipairs(DotaStrikers.vHeroes) do
			local collision = (hero:GetAbsOrigin()-ballPos):Length() <= BALL_COLLISION_DIST
			--if collision then print ("collision.") end
			if hero ~= ball.controller and collision then
				if not hero.ballProc then
					ball:SetPhysicsVelocity(Vector(0,0,0))
					if hero.isUsingPull then
						hero:CastAbilityNoTarget(hero.pull_break, 0)
					end
					--print("new controller.")
					if ball.affectedByPowershot then
						ball.affectedByPowershot = false
						ball.dontChangeFriction = false
						ball:SetPhysicsFriction(GROUND_FRICTION)
						hero:AddPhysicsVelocity((hero:GetAbsOrigin()-ball:GetAbsOrigin()):Normalized()*PSHOT_ONHIT_VEL)
						hero:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
						ParticleManager:DestroyParticle(ball.powershot_particle, false)
					else
						--hero:EmitSound("Hero_Puck.ProjectileImpact")
						ball:EmitSound("Catch" .. RandomInt(1, NUM_CATCH_SOUNDS))
					end

					if hero == Referee.unit then
						Referee.unit:MoveToTargetToAttack(ball)
					else
						ball.controller = hero
					end
					hero.ballProc = true
				end
			elseif hero ~= ball.controller and not collision then
				if hero.ballProc then
					hero.ballProc = false
				end
			elseif hero == ball.controller then
				local fv = hero:GetForwardVector()
				-- reposition ball to in front of controller.
				ball:SetAbsOrigin(hero:GetAbsOrigin() + Vector(fv.x,fv.y,0)*(BALL_COLLISION_DIST-40))
				ball:SetForwardVector(fv)
			end
		end

		if ball.controller ~= nil then
			ball.particleDummy:SetForwardVector(ball.controller:GetForwardVector())
			-- handle when controller took the ball out of bounds
			local isBallOutOfBounds = ball:IsBallOutOfBounds()
			if isBallOutOfBounds and not ball.outOfBoundsProc then
				--Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsTimer = Timers:CreateTimer(2, function()
					if not ball.outOfBoundsProc then return end
					print("Referee.unit:GetBallInBounds()")
					Referee.unit:GetBallInBounds()
				end)
				-- show error msg
				ShowErrorMsg(ball.controller, "Ball is out of bounds")
				ball.outOfBoundsProc = true
			elseif not isBallOutOfBounds and ball.outOfBoundsProc then
				Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsProc = false
			end
		else
			-- turn the facing direction of the ball for aesthetics.
			local ballVelocityDir = ball:GetPhysicsVelocity():Normalized()
			local ballFV = ball.particleDummy:GetForwardVector()

			if ball.bStarted and ball.velocityMagnitude > 100*100 and ballFV ~= ball.lastForwardVector then
				ball.lastForwardVector = ballFV
				ball.particleDummy:SetForwardVector(ballVelocityDir)
			end
		end
		if ball.controller and ball.lastController ~= ball.controller then
			print("new ball.lastController")
			ball.lastController = ball.controller
		end
	end)

	return ball
end

