BALL_PARTICLE_Z_OFFSET=50 --this makes the particle look nicer.
GROUND_FRICTION = .035
AIR_FRICTION = .015
GRAVITY = -2200
BASE_ACCELERATION = Vector(0,0,GRAVITY)
BALL_COLLISION_DIST = 125
ABOVE_GROUND_Z = 20
PEAK_Z_THRESH = 40
BOUNCE_MULTIPLIER = .9
BOUNCE_VEL_THRESHOLD = 500
CRACK_THRESHOLD = BOUNCE_VEL_THRESHOLD*2
PP_COLLISION_RADIUS = 110
PP_COLLISION_THRESHOLD = CRACK_THRESHOLD -- player-player collision threshold

BALL_HANDLED_OFFSET = BALL_COLLISION_DIST-10
NUM_BOUNCE_SOUNDS = 5
NUM_KICK_SOUNDS = 6
NUM_CATCH_SOUNDS = 5

BALL_HOG_DURATION = 6
BALL_OUTOFBOUNDS_DURATION = 5

BALL_ROUNDSTART_KICK = {170,210}
CONTROLLER_MOVESPEED_FACTOR = 1/5

function DotaStrikers:OnMyPhysicsFrame( unit )
	local unitPos = unit:GetAbsOrigin()
	unit.currPos = unitPos
	local currVel = unit:GetPhysicsVelocity()
	local ball = Ball.unit
	local len3dSq = Length3DSq(currVel)
	local currTime = GameRules:GetGameTime()
	unit.velocityMagnitude = len3dSq
	local inAir = unitPos.z > (GroundZ+ABOVE_GROUND_Z)

	-- do above ground think logic
	if unit.isAboveGround then
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= AIR_FRICTION then
			unit:SetPhysicsFriction(AIR_FRICTION)
		end

		if not unit:HasModifier("modifier_flail_passive") and not unit.noBounce and ball.controller ~= unit then -- and not unit.isUsingGoalieJump
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_flail_passive", {})
		end

		if currVel.z < PEAK_Z_THRESH and currVel.z > -1*PEAK_Z_THRESH then
			if unitPos.z > unit.last_peak_z and unitPos.z > (GroundZ+ABOVE_GROUND_Z+30) then
				--DebugDrawSphere(unitPos, Vector(255,0,0), 50, 30, false, 20)
				unit.bounce_multiplier = BOUNCE_MULTIPLIER
			end
			unit.last_peak_z = unitPos.z
			unit.last_peak_time = GameRules:GetGameTime()
		end
	else
		if not unit.dontChangeFriction and unit:GetPhysicsFriction() ~= GROUND_FRICTION then
			unit:SetPhysicsFriction(GROUND_FRICTION)
		end

		if unit:HasModifier("modifier_flail_passive") then
			unit:RemoveModifierByName("modifier_flail_passive")
		end
	end

	if inAir and not unit.isAboveGround then
		unit.isAboveGround = true
		unit:SetGroundBehavior(PHYSICS_GROUND_NONE)

		-- if hero, set the modifier up
		if not unit:HasModifier("modifier_rooted_passive") then
			if unit ~= ball then
				GlobalDummy.rooted_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_rooted_passive", {})
			end
		end

		unit.bounce_multiplier = BOUNCE_MULTIPLIER

	elseif not inAir and unit.isAboveGround then
		-- bounce takes priority
		-- determine if bounce should occur.
		local bounceOccured = false
		if len3dSq > BOUNCE_VEL_THRESHOLD*BOUNCE_VEL_THRESHOLD and not unit.noBounce then
			currVel = Vector(currVel.x, currVel.y, math.abs(currVel.z)*unit.bounce_multiplier)
			unit.bounce_multiplier = unit.bounce_multiplier*.8
			unit:SetPhysicsVelocity(currVel)
			bounceOccured = true

			-- play bounce sound
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
			-- for slark
			if unit.isUsingJump then
				unit.isUsingJump = false
			end

			if unit.isUsingGoalieJump then
				unit:EmitSound("Hero_Rubick.Telekinesis.Target.Land")
				unit.isUsingGoalieJump = false
			end

			unit.noBounce = false
		end

		if not bounceOccured then
			unit.isAboveGround = false
			unit.last_peak_z = 0

			-- remove the modifier
			if unit:HasModifier("modifier_rooted_passive") then
				unit:RemoveModifierByName("modifier_rooted_passive")
			end
			unit:SetGroundBehavior(PHYSICS_GROUND_ABOVE)
		end
	end

	if unit.isDSHero then
		local hero = unit

		local fv = hero:GetForwardVector()
		if hero.isUsingPull then
			-- it's imba is the puller already has the ball and she's using pull.
			if ball.controller ~= hero then
				local dirToBall = (Ball.hero:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
				-- remove the current pull acceleration.
				hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()-hero.currPullAccel)
				hero.currPullAccel = dirToBall*PULL_ACCEL_FORCE
				-- add the new one
				hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()+hero.currPullAccel)
			end
		end

		-- we need to handle player-player collisions, so players don't get stuck.
		-- Phase them if they're in the collision radius of a player, unphase them otherwise.
		local pp_collision = false
		for i2=0,9 do
			local hero2 = hero.pp_collisions[i2]

			local in_collision_radius = false
			if hero2 then
				in_collision_radius = (hero2:GetAbsOrigin()-hero:GetAbsOrigin()):Length() <= hero:GetPaddedCollisionRadius()
			end

			if in_collision_radius then
				pp_collision = true
				break
			end
		end

		if pp_collision and not hero:HasModifier("modifier_phased_on") then
			if hero:HasModifier("modifier_phased_off") then
				hero:RemoveModifierByName("modifier_phased_off")
			end
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_phased_on", {})
			DebugDrawCircle(hero:GetAbsOrigin(), Vector(255,0,0), 50, 30, false, .04)
		elseif not pp_collision and hero:HasModifier("modifier_phased_on") then
			if hero:HasModifier("modifier_phased_on") then
				hero:RemoveModifierByName("modifier_phased_on")
			end
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_phased_off", {})
			print("removing phased.")
		end
	end
end

function Ball:Init(  )
	Ball.unit = CreateUnitByName("ball", Vector(0,0,GroundZ), true, nil, nil, DOTA_TEAM_NOTEAM)
	local ball = Ball.unit
	--table.insert(DotaStrikers.colliderFilter, ball)
	ball.colliderID = DoUniqueString("a")
	DotaStrikers.colliderFilter[ball.colliderID] = ball
	BALL = ball.unit
	ball.isBall = true
	ball.particleDummy = CreateUnitByName("dummy", Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET), false, nil, nil, DOTA_TEAM_NOTEAM)
	ball.lastBounceTime = 0
	ball.last_peak_z = 0
	ball.lastPos = Vector(0,0,GroundZ)
	ball.isRotating = false

	-- this is for black holes.
	ball.last_bh_accels = {}
	for i=0,9 do
		ball.last_bh_accels[i] = Vector(0,0,0)
	end

	function ball:SpawnParticle(  )
		-- constantly reposition the ball particle dummy.
		ball.particleDummy:SetAbsOrigin(Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET))
		Timers:CreateTimer(.06, function()
			if not ball.ballParticle then
				ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)

				ball:AddPhysicsVelocity(ball:GetAbsOrigin() + RandomVector(RandomInt(BALL_ROUNDSTART_KICK[1], BALL_ROUNDSTART_KICK[2])))
			end
		end)
	end

	function ball:Rotate(  )
		if not ball.ballParticle then return end
		local vel_for_max_rotation = 900*900
		local vel_for_zero_rotation = 20*20
		local cp_value_for_max_rotation = -60
		local new_cp_value = ball.velocityMagnitude*(cp_value_for_max_rotation/vel_for_max_rotation)
		if (ball:GetAbsOrigin()-ball.lastPos):Length() < 1 or ball.controller then
			if ball.rotateStarted then
				--DebugDrawBox(ball:GetAbsOrigin(), Vector(-8,-8,0), Vector(8,8,1), 255, 0, 0, 100, 30)
				ParticleManager:SetParticleControl(ball.ballParticle, 11, Vector(0,0,0))
				ball.rotateStarted = false

				if not RoundInProgress and RoundsCompleted > 0 then
					--ball.netParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_meepo/meepo_earthbind.vpcf", PATTACH_ABSORIGIN, ball)
				end
			end
		else
			if not ball.rotateStarted then
				if not ball.controller then
					ParticleManager:SetParticleControl(ball.ballParticle, 11, Vector(0,0,-70))
					ball.rotateStarted = true
				end
			end
		end
	end

	ball.controller = nil
	DotaStrikers:SetupPhysicsSettings(ball)

	ball:OnPhysicsFrame(function(unit)
		-- don't perform velocity calculations on the ball if it has a controller.
		if ball.controller then
			ball:SetPhysicsVelocity(Vector(0,0,0))
		end

		DotaStrikers:OnMyPhysicsFrame(ball)
		DotaStrikers:OnBallPhysicsFrame(ball)
	end)
	return ball
end

function DotaStrikers:OnBallPhysicsFrame( ball )
	local ballPos = ball:GetAbsOrigin()

	--if not RoundInProgress then return end

	for _,hero in ipairs(DotaStrikers.vHeroes) do
		local collision = (hero:GetAbsOrigin()-ballPos):Length() <= BALL_COLLISION_DIST
		if hero ~= ball.controller and collision then
			if not hero.ballProc then
				-- new controller
				ball:SetPhysicsVelocity(Vector(0,0,0))
				if hero.isUsingPull then
					hero:CastAbilityNoTarget(hero.pull_break, 0)
				end
				if not ball.affectedByPowershot then
					ball:EmitSound("Catch" .. RandomInt(1, NUM_CATCH_SOUNDS))
				end

				ball.controller = hero
				if ball.affectedByPowershot then
					-- allow the hero collider to take control and apply collision velocity, by invoking it
					ball.pshotInvoke = true

					ball.affectedByPowershot = false
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
			if ball.outOfBounds then
				ball:SetAbsOrigin(hero:GetAbsOrigin() + Vector(fv.x,fv.y,0)*BALL_HANDLED_OFFSET*3/4)
			else
				ball:SetAbsOrigin(hero:GetAbsOrigin() + Vector(fv.x,fv.y,0)*BALL_HANDLED_OFFSET)
			end
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

	-- treat the referee ball controller separately
	if ball.controller == Referee then
		ball.lastController = Referee

	elseif ball.controller ~= nil then
		-- it's nice to update this
		ballPos = ball:GetAbsOrigin()

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

		-- if goalie, he can't have goalie jump while having the ball
		if ball.controller.goalie then
			DotaStrikers:RemoveGoalieJump(ball.controller)
		end

		ball:SetForwardVector(ball.controller:GetForwardVector())

	else -- ball.controller is nil
		-- turn the facing direction of the ball for aesthetics.
		local ballVelocityDir = ball:GetPhysicsVelocity():Normalized()
		local ballFV = ball:GetForwardVector()

		if ball.bStarted and ball.velocityMagnitude > 150*150 and ballFV ~= ball.lastForwardVector then
			ball.lastForwardVector = ballFV
			ball:SetForwardVector(ballVelocityDir)
		end

		ballPos = ball:GetAbsOrigin()
		
		if ball.lastMovedBy ~= Referee then
			if ballPos.x < SCORE_X_MIN and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Dire")
			elseif ballPos.x > SCORE_X_MAX and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Radiant")
			end
		end
	end

	-- Do ball hog logic
	local goal = GetGoalUnitIsWithin( ball )
	ball.hogged = goal and ((ball.controller and ball.controller.goalie and ball.controller:GetTeam() == goal) or not ball.controller) and RoundInProgress

	if ball.hogged and not ball.hoggedProc then
		ball.timeBecameHogged = GameRules:GetGameTime()

		ball.hog_timer = Timers:CreateTimer(BALL_HOG_DURATION, function()
			-- check again to see if we're in the same situation
			if not ball.hogged then return end

			if GameRules:GetGameTime()-ball.timeBecameHogged >= BALL_HOG_DURATION then
				if RandomInt(1, 2) == 1 then
					EmitGlobalSound("RoshanDT.Scream")
				else
					EmitGlobalSound("RoshanDT.Scream2")
				end
				DotaStrikers:GetBallInBounds()
			end
		end)

		-- if the ball has a controller (the goalie), warn him beforehand.
		ball.hog_warning = Timers:CreateTimer(BALL_HOG_DURATION/2, function()
			-- check again to see if we're in the same situation
			if not ball.hogged then return end

			if GameRules:GetGameTime()-ball.timeBecameHogged >= BALL_HOG_DURATION/2 then
				if not ball.controller or ball.controller == Referee then
					DotaStrikers:text_particle( {caster=ball, exclamation=true} )
				else
					ShowErrorMsg(ball.controller, "#goalie_ball_hog_warning")
					DotaStrikers:text_particle( {caster=ball.controller, exclamation=true} )
				end
			end
		end)

		ball.hoggedProc = true

	elseif not ball.hogged and ball.hoggedProc then
		ball.hoggedProc = false
	end

	-- Check if ball is out of bounds.
	local off = 40
	local isBallOutOfBounds = not goal and (ballPos.x > (RECT_X_MAX+off) or ballPos.x < (RECT_X_MIN-off) or ballPos.y > (Bounds.max+off) or ballPos.y < (Bounds.min-off)) and RoundInProgress
	ball.outOfBounds = isBallOutOfBounds

	if isBallOutOfBounds and not ball.outOfBoundsProc then
		--print("ball.outOfBoundsProc")
		ball.timeBecameOutOfBounds = GameRules:GetGameTime()
		ball.out_of_bounds_timer = Timers:CreateTimer(BALL_OUTOFBOUNDS_DURATION, function()
			-- do the check again
			if not ball.outOfBounds then return end

			if (GameRules:GetGameTime() - ball.timeBecameOutOfBounds) >= BALL_OUTOFBOUNDS_DURATION then
				if RandomInt(1, 2) == 1 then
					EmitGlobalSound("RoshanDT.Scream")
				else
					EmitGlobalSound("RoshanDT.Scream2")
				end
				DotaStrikers:GetBallInBounds()
			end
		end)

		ball.out_of_bounds_warning_timer = Timers:CreateTimer(BALL_OUTOFBOUNDS_DURATION/2, function()
			-- do the check again
			if not ball.outOfBounds then return end

			if (GameRules:GetGameTime() - ball.timeBecameOutOfBounds) >= BALL_OUTOFBOUNDS_DURATION/2 then
				ShowErrorMsg(ball.controller, "#outofbounds_warning")
				DotaStrikers:text_particle( {caster=ball.controller, exclamation=true} )
			end
		end)

		ball.outOfBoundsProc = true
	elseif not isBallOutOfBounds and ball.outOfBoundsProc then
		--print("ball.outOfBoundsProc = false")
		ball.outOfBoundsProc = false
	end

	-- rotate the ball depending if it's not moving or what
	ball:Rotate()

	ball.lastPos = ballPos

	-- move the ball particle dummy, so ball particle displays above ground.
	ball.particleDummy:SetAbsOrigin(Vector(ballPos.x, ballPos.y, ballPos.z+BALL_PARTICLE_Z_OFFSET))

	ball.particleDummy:SetForwardVector(ball:GetForwardVector())
	--print("rotating.")
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

-- Components extension to physics.lua:

function AddPhysicsComponent( ... )
	local t = {...}
	local name = t[1]
	local unit = t[2]

	if not unit.components then
		unit.components = {}
	end

	local components = unit.components

	local possibleExisting = components[name]
	if possibleExisting and IsValidEntity(possibleExisting) then
		possibleExisting:RemoveSelf()
		components[name] = nil
	end

	local component = CreateUnitByName("dummy", unit:GetAbsOrigin(), false, nil, nil, unit:GetTeam())
	DotaStrikers:SetupPhysicsSettings(component)
	component.isComponent = true
	component.componentOwner = unit
	components[name] = component
	local colliderID = DoUniqueString("a")
	DotaStrikers.colliderFilter[colliderID] = component

	component.component_timer = Timers:CreateTimer(function()
		if not IsValidEntity(component) or not component:IsAlive() then
			Timers:RemoveTimer(component.component_timer)
			return nil
		end
		component:SetPhysicsFriction(unit:GetPhysicsFriction())
		component:SetAbsOrigin(unit:GetAbsOrigin())
		--DebugDrawCircle(unit:GetAbsOrigin(), Vector(255,0,0), 30, 40, false, .06)

		return .01
	end)

	--[[component:OnPhysicsFrame(function(x)
		-- make the dummy stay in 1 place
		component:SetAbsOrigin(unit:GetAbsOrigin())
	end)]]

	function component:RemoveComponent(  )
		if not component or not IsValidEntity(component) or not component:IsAlive() then return end
		component:ForceKill(true)
		components[name] = nil
		DotaStrikers.colliderFilter[colliderID] = nil
	end

	return component
end

function IsComponent( unit )
	return unit.isComponent
end

function TryInvokeComponents(passTest, unit )
	if passTest and unit.components then
		for k,component in pairs(unit.components) do
			component.invoked = true
		end
	end
end

function TrySetComponentStatus( unit )
	if unit.isComponent and unit.invoked then
		unit.invoked = false
		return true
	end
end

function TryResetComponentVelocities( unit )
	if unit.components then
		for k,component in pairs(unit.components) do
			component:SetPhysicsVelocity(unit:GetPhysicsVelocity())
		end
	end
end

-- End of components extension.

function DotaStrikers:GetBallInBounds(  )
	local ball = Ball.unit
	local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()
	local backOfBall = -300*towardsCenter + ball:GetAbsOrigin()

	RemoveEndgameRoot(Referee)
	RemoveDisarmed(Referee)

	Referee:SetAbsOrigin(backOfBall)

	Referee:SetForwardVector((ball:GetAbsOrigin()-backOfBall):Normalized())

	Referee:MoveToTargetToAttack(ball)

	local thisController = ball.controller
	ball.controller = Referee
	Timers:CreateTimer(.06, function()
		if thisController == ball.controller then
			print("still same controller.")
			--return .1
		end
	end)
end

function DotaStrikers:SetupPersonalColliders(hero)
	local pshot_coll = hero:AddColliderFromProfile("momentum_full")
	pshot_coll.radius = BALL_COLLISION_DIST
	pshot_coll.filer = self.colliderFilter
	pshot_coll.elasticity = .8
	pshot_coll.test = function(self, collider, collided)
		local passTest = false
		local ball = Ball.unit

		if not IsPhysicsUnit(collided) then return false end

		if TrySetComponentStatus(collider) then return true end

		if collided == ball and ball.pshotInvoke then
			-- 5-17-15 bug: if ball is really close to collided, collided won't receive knockback. 

			ball.dontChangeFriction = false

			ball:SetPhysicsFriction(GROUND_FRICTION)

			hero:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")

			ParticleManager:DestroyParticle(ball.powershot_particle, false)

			ball.pshotInvoke = false

			passTest = true
		end

		TryInvokeComponents(passTest, collider)

		return passTest
	end
	hero.pshot_collider = pshot_coll

	local coll = hero:AddColliderFromProfile("momentum")
	coll.radius = PP_COLLISION_RADIUS
	coll.filer = self.colliderFilter
	coll.elasticity = 1
	coll.test = function(self, collider, collided)
		local passTest = false
		local ball = Ball.unit

		if not IsPhysicsUnit(collided) then return false end
		
		if TrySetComponentStatus(collider) then return true end

		if collided.isSwapDummy and hero ~= collided.caster then
			-- technically treat this as a collision, but return false since we don't want the momentum stuff
			collided:OnSwapCollision(hero) -- in abilities.lua
			TryResetComponentVelocities(hero)
			return false
		end

		if collided.isDSHero then
			hero.pp_collisions[collided:GetPlayerID()] = collided
			hero.lastPPCollisionTime = GameRules:GetGameTime()

			if hero.isUsingTackle and not hero.tackleTargets[collided:GetPlayerID()] then
				hero.tackleTargets[collided:GetPlayerID()] = true

				-- do negative stuff
				if hero:GetTeam() ~= collided:GetTeam() then
					hero.tackleDummy:SetForwardVector((collided:GetAbsOrigin() - hero.tackleDummy:GetAbsOrigin()):Normalized())
					Timers:CreateTimer(.03, function()
						hero.tackleDummy:CastAbilityOnTarget(collided, hero.tackleDummyAbil, 0)
					end)
					print("enemy target tackled.")
					collided:SetBaseMoveSpeed(0)
					--[[if not collided.movespeed_before_tackle then
						collided.movespeed_before_tackle = collided:GetBaseMoveSpeed()
					end]]
				end
				hero.tackle_end_time = GameRules:GetGameTime()
				Timers:CreateTimer(TACKLE_SLOW_DURATION, function()
					if hero:GetTeam() ~= collided:GetTeam() then
						collided:SetBaseMoveSpeed(collided.base_move_speed)
					end
					hero.tackleTargets[collided:GetPlayerID()] = false
				end)

				hero.tackled_someone = true
			elseif collided.isUsingTackle or (collided.tackle_end_time and GameRules:GetGameTime()-collided.tackle_end_time < .2) or hero.isUsingTackle or
				(hero.tackle_end_time and GameRules:GetGameTime()-hero.tackle_end_time < .2) then
				print("not playing cracks.")
			elseif hero.velocityMagnitude > PP_COLLISION_THRESHOLD*PP_COLLISION_THRESHOLD then
				TryPlayCracks(collider)
				passTest = true
			end

		end

		TryInvokeComponents(passTest, collider)

		return passTest
	end
	hero.personal_collider = coll

end

function DotaStrikers:OnGridNavBounce( unit, normal )
	local ball = Ball.unit
	local isBall = unit == ball

	-- done with passTest logic. move onto parsing that logic, add sounds, effects, etc.
	if isBall and not ball.controller and not ball.affectedByPowershot then
		unit:EmitSound("Bounce" .. RandomInt(1, NUM_BOUNCE_SOUNDS))
	
	elseif unit.isDSHero then
		TryPlayCracks(unit, nil, true)
	end

	if unit.isAboveGround then
		DotaStrikers:PlayReflectParticle(unit)
	end

	--[[if unit.components then
		for i,component in ipairs(unit.components) do
			component.invoked = true
		end
	end]]

end