BALL_PARTICLE_Z_OFFSET=45 --this makes the particle look nicer.
GROUND_FRICTION = .035
AIR_FRICTION = .015
GRAVITY = -2200
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 120
BOUNCE_MULTIPLIER = .9
BOUNCE_VEL_THRESHOLD = 500
CRACK_THRESHOLD = BOUNCE_VEL_THRESHOLD*2
PP_COLLISION_THRESHOLD = CRACK_THRESHOLD -- player-player collision threshold

BALL_HANDLED_OFFSET = BALL_COLLISION_DIST-30
NUM_BOUNCE_SOUNDS = 5
NUM_KICK_SOUNDS = 6
NUM_CATCH_SOUNDS = 5

BALL_ROUNDSTART_KICK = {230,260}
CONTROLLER_MOVESPEED_FACTOR = 1/5

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	unit.currPos = unitPos
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
			elseif unit ~= ball then
				TryPlayCracks(unit)
			end
		end

		if unit.noBounce then
			if unit.isUsingJump then
				unit.isUsingJump = false
			end
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
				-- remove the current pull acceleration.
				unit:SetPhysicsAcceleration(unit:GetPhysicsAcceleration()-unit.currPullAccel)
				unit.currPullAccel = dirToBall*PULL_ACCEL_FORCE
				-- add the new one
				unit:SetPhysicsAcceleration(unit:GetPhysicsAcceleration()+unit.currPullAccel)
			end
		end
	end

	-- do above ground think logic
	if unit.isAboveGround then
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= AIR_FRICTION then
			--if unit == Ball.unit then print("Changing ball friciton.") end
			unit:SetPhysicsFriction(AIR_FRICTION)
		end
		if not unit:HasModifier("modifier_flail_passive") and not unit.noBounce and ball.controller ~= unit then
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_flail_passive", {})
		end

	else
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= GROUND_FRICTION then
			--if unit == Ball.unit then print("Changing ball friciton.") end
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end
		if unit:HasModifier("modifier_flail_passive") then
			unit:RemoveModifierByName("modifier_flail_passive")
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

	-- this is for black holes.
	ball.last_bh_accels = {}
	for i=0,9 do
		ball.last_bh_accels[i] = Vector(0,0,0)
	end

	function ball:SpawnParticle(  )
		-- constantly reposition the ball particle dummy.
		ball.particleDummy:SetAbsOrigin(Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET))
		Timers:CreateTimer(2*NEXT_FRAME, function()
			if not ball.ballParticle then
				ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)
				ball:AddPhysicsVelocity(ball:GetAbsOrigin() + RandomVector(RandomInt(BALL_ROUNDSTART_KICK[1], BALL_ROUNDSTART_KICK[2])))
			end
			local pos = ball:GetAbsOrigin()
			ball.particleDummy:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+BALL_PARTICLE_Z_OFFSET))
			return .01
		end)
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
		-- don't perform velocity calculations on the ball if it has a controller.
		if ball.controller then
			ball:SetPhysicsVelocity(Vector(0,0,0))
		end

		DotaStrikers:OnMyPhysicsFrame(ball)
		local ballPos = ball:GetAbsOrigin()
		--print("ball vel: " .. VectorString(ball:GetPhysicsVelocity()))
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
					if not ball.affectedByPowershot then
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
				ball:SetAbsOrigin(hero:GetAbsOrigin() + Vector(fv.x,fv.y,0)*BALL_HANDLED_OFFSET)
				ball:SetForwardVector(fv)
			end
			-- reset the movespeed if this guy isn't the ball handler anymore.
			if ball.controller ~= hero and hero.slowedByBall then
				hero:SetBaseMoveSpeed(hero:GetBaseMoveSpeed() + hero.base_move_speed*CONTROLLER_MOVESPEED_FACTOR)
				if hero:HasModifier("modifier_ball_controller") then
					hero:RemoveModifierByName("modifier_ball_controller")
				end

				hero.slowedByBall = false
			end
		end

		if ball.controller ~= nil then
			if ball.lastController ~= ball.controller then
				--print("new ball.lastController")
				ball.lastController = ball.controller
			end

			-- slow the movespeed of the controller if we haven't already.
			local cont = ball.controller
			if not cont.slowedByBall then
				cont:SetBaseMoveSpeed(cont:GetBaseMoveSpeed() - cont.base_move_speed*CONTROLLER_MOVESPEED_FACTOR)
				if not cont:HasModifier("modifier_ball_controller") then
					GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, cont, "modifier_ball_controller", {})
				end
				cont.slowedByBall = true
			end

			ball.particleDummy:SetForwardVector(ball.controller:GetForwardVector())
			-- handle when controller took the ball out of bounds
			local isBallOutOfBounds = ball:IsBallOutOfBounds()
			--[[if isBallOutOfBounds and not ball.outOfBoundsProc then
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
			end]]
		else
			-- turn the facing direction of the ball for aesthetics.
			local ballVelocityDir = ball:GetPhysicsVelocity():Normalized()
			local ballFV = ball.particleDummy:GetForwardVector()

			if ball.bStarted and ball.velocityMagnitude > 150*150 and ballFV ~= ball.lastForwardVector then
				ball.lastForwardVector = ballFV
				ball.particleDummy:SetForwardVector(ballVelocityDir)
			end
			ballPos = ball:GetAbsOrigin()
			if ballPos.x < SCORE_X_MIN and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Dire")
			elseif ballPos.x > SCORE_X_MAX and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Radiant")
			end
		end
	end)

	return ball
end

function TryPlayCracks( ... )
	local t = {...}
	local unit = t[1]
	local location = t[2]
	local checkFence = t[3]
	local ground_thresh = 30
	local currTime = GameRules:GetGameTime()
	local unitPos = unit:GetAbsOrigin()
	local soundPlayed = false
	if unit.velocityMagnitude > CRACK_THRESHOLD*CRACK_THRESHOLD and (not unit.lastCrackTime or currTime-unit.lastCrackTime > .3) then
		--if unitPos.z < (GroundZ + ground_thresh) then
		if not location then
			ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_ABSORIGIN, unit)
		else
			ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_CUSTOMORIGIN, unit)
			ParticleManager:SetParticleControl(p, 0, location)
		end
		--end

		if checkFence then
			EmitSoundAtPosition("fence_smash_2", unitPos)
			soundPlayed = true
		end

		if not soundPlayed then
			EmitSoundAtPosition("ThunderClapCaster", unitPos)
		end
		unit.lastCrackTime = currTime
	end
end

function Components:Init( unit )
	unit.physics_components = {}
	self.dummy_dump = Vector(-4500,-3900,0)
	local dummy_dump = self.dummy_dump
	local components = unit.physics_components

	function unit:PhysicsComponent( ... )
		local t = {...}
		local velocityVector = t[1]
		local name = t[2]

		if type(velocityVector) ~= "userdata" then
			name = t[1]
			velocityVector = Vector(0,0,0)
		end

		local possibleExisting = components[name]
		if possibleExisting and IsValidEntity(possibleExisting) then
			possibleExisting:RemoveSelf()
			components[name] = nil
		end

		local component = CreateUnitByName("dummy", dummy_dump, false, nil, nil, DOTA_TEAM_GOODGUYS)
		Physics:Unit(component)
		component:SetPhysicsVelocity(velocityVector)
		components[name] = component

		component:OnPhysicsFrame(function(x)
			-- make the dummy stay in 1 place
			component:SetAbsOrigin(dummy_dump)
		end)

		function component:RemoveComponent(  )
			if not component or not IsValidEntity(component) then return end
			components:ForceKill(true)
			components[name] = nil
		end

		return component
	end
end

function Components:SetDummyDumpVector( vec )
	self.dummy_dump = vec
end