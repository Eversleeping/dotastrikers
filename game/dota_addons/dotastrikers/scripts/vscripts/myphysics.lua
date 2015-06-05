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
CrackThreshSq = CRACK_THRESHOLD*CRACK_THRESHOLD

BALL_HANDLED_OFFSET = BALL_COLLISION_DIST-10

BALL_HOG_DURATION = 6
BALL_OUTOFBOUNDS_DURATION = 5

BALL_ROUNDSTART_KICK = {170,210}
CONTROLLER_MOVESPEED_FACTOR = 1/5

-- this is for tackle
SprintAbilIndex = 2

--SOUNDS
NUM_BOUNCE_SOUNDS = 5
NUM_KICK_SOUNDS = 6
NUM_CATCH_SOUNDS = 5
NumRoundStartSounds = 6
NUM_ROUNDEND_SOUNDS = 10
NUM_FAIL_SOUNDS = 2
NumGiantImpactSounds = 1
NumHeavyImpactSounds = 2
NumMediumImpactSounds = 4
NumLightImpactSounds = 4
NumCheerSounds = 4

RoundCountdownSounds =
{
	-- set # vs. how many in set
	[1] = 1,
	[2] = 2
}

PlayerPlayerCollisionSounds = 
{
	[1] = "ThunderClapCaster",
	--[2] = "Hero_Leshrac.Split_Earth",
	--[3] = "Hero_EarthSpirit.BoulderSmash.Target",
	--[2] = "Hero_ElderTitan.EchoStomp",
}

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
			if unitPos.z > (unit.last_peak_z+10) and unitPos.z > (GroundZ+ABOVE_GROUND_Z+30) then
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
				local dirToBall = (ball:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
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
				in_collision_radius = (hero2:GetAbsOrigin()-hero:GetAbsOrigin()):Length() <= (hero:GetPaddedCollisionRadius()+20)
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
			--DebugDrawCircle(hero:GetAbsOrigin(), Vector(255,0,0), 50, hero:GetPaddedCollisionRadius()+30, false, 3)

		elseif not pp_collision and hero:HasModifier("modifier_phased_on") then
			if hero:HasModifier("modifier_phased_on") then
				hero:RemoveModifierByName("modifier_phased_on")
			end
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, hero, "modifier_phased_off", {})
			--print("removing phased.")
		end

		if hero.isUsingPowersprint then
			--hero:SetForwardVector(hero.psprint_dir)
			local baseVel = hero:GetPhysicsVelocity()
			if hero.last_psprint_vel then
				baseVel = hero:GetPhysicsVelocity()-(hero.last_psprint_vel-hero.last_psprint_vel*hero:GetPhysicsFriction())
			end
			hero.last_psprint_vel = hero.psprint_dir*PSPRINT_VELOCITY
			hero:SetPhysicsVelocity(baseVel + hero.last_psprint_vel)
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
	ball.lastMovedBy = Referee

	-- this is for black holes.
	ball.last_bh_accels = {}
	ball.last_tornado_accels = {}
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

				-- when referee hits the ball, if goalie is in goal area, he shouldn't be able to catch the ball.
				if ball.lastMovedBy == Referee and hero.goalie and hero:GetTeam() == ball.goal then

				else
					local saved = false
					-- determine if catch was a "SAVE!"
					--and hero:GetTeam() ~= ball.lastMovedBy:GetTeam()
					if hero.goalie and (hero.isUsingGoalieJump or ball.velocityMagnitude > CrackThreshSq or
						ball.velocityMagnitude > 400*400 and hero:GetTeam() ~= ball.lastMovedBy:GetTeam()) then

						hero.savedParticle = ParticleManager:CreateParticle("particles/saved_txt/tusk_rubickpunch_txt.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						ParticleManager:SetParticleControlEnt(hero.savedParticle, 4, hero, 4, "follow_origin", hero:GetAbsOrigin(), true)
						--ParticleManager:SetParticleControl( hero.savedParticle, 2, hero:GetAbsOrigin() )
						EmitGlobalSound("Cheer" .. RandomInt(1, NumCheerSounds))
						PlayVictoryAndDeathAnimations(hero:GetTeam(), nil, true)
						hero.numSaves = hero.numSaves + 1
						saved = true
					end

					-- do some stats stuff
					if not ball.controller and not saved then
						-- determine if catch was a pass
						if ball.velocityMagnitude < 500*500 then
							hero.pickups = hero.pickups + 1
						else
							if hero:GetTeam() == ball.lastMovedBy:GetTeam() then
								ball.lastMovedBy.numPasses = ball.lastMovedBy.numPasses + 1
								hero.passesReceived = hero.passesReceived + 1
							else
								hero.steals = hero.steals + 1
								ball.lastMovedBy.turnovers = ball.lastMovedBy.turnovers + 1
								EmitGlobalSound("Cheer" .. RandomInt(1, NumCheerSounds))
								DotaStrikers:text_particle( {caster=hero, stolen=true} )
								PlayVictoryAndDeathAnimations(hero:GetTeam(), nil, true)
							end
						end
					end

					if not hero.isAboveGround and ballPos.z > hero:GetAbsOrigin().z+BALL_COLLISION_DIST-40 then
						if hero:HasAbility("throw_ball") then
							hero:RemoveAbility("throw_ball")
							hero:AddAbility("head_bump")
							hero:FindAbilityByName("head_bump"):SetLevel(1)

							Timers:CreateTimer(TIME_TILL_HEADBUMP_EXPIRES, function()
								if hero:HasAbility("head_bump") then
									hero:RemoveAbility("head_bump")
									hero:AddAbility("throw_ball")
									hero:FindAbilityByName("throw_ball"):SetLevel(1)
								end

							end)

						end
					end

					ball.controller = hero
				end

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
			local heroPos = hero:GetAbsOrigin()
			-- reposition ball to in front of controller.
			if hero:HasAbility("head_bump") then
				ball:SetAbsOrigin(Vector(heroPos.x, heroPos.y, heroPos.z+BALL_HANDLED_OFFSET))
			else
				ball:SetAbsOrigin(hero:GetAbsOrigin() + Vector(fv.x,fv.y,0)*BALL_HANDLED_OFFSET)
			end

			ball:SetForwardVector(fv)
		end
		-- reset the movespeed if this guy isn't the ball handler anymore.
		if ball.controller ~= hero and hero:HasModifier("modifier_ball_controller") then
			RemoveMovementComponent(hero, "ball_slow")
			hero:RemoveModifierByName("modifier_ball_controller")
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
		local controller = ball.controller
		if not controller:HasModifier("modifier_ball_controller") then
			AddMovementComponent(controller, "ball_slow", -1*controller.base_move_speed*CONTROLLER_MOVESPEED_FACTOR)
			GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, controller, "modifier_ball_controller", {})
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
			if ballPos.x < R_SCORE and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Dire")
			elseif ballPos.x > D_SCORE and ballPos.y > -1*GOAL_Y and ballPos.y < GOAL_Y and ballPos.z < GOAL_Z then
				DotaStrikers:OnGoal("Radiant")
			end

		end
	end

	-- Do ball hog logic
	local goal = GetGoalUnitIsWithin( ball )
	ball.goal = goal
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

		ball.lastMovedBy.shotsAgainst = ball.lastMovedBy.shotsAgainst + 1

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
	local bPlayerPlayerColl = t[4]
	local ground_thresh = 30
	local currTime = GameRules:GetGameTime()
	local unitPos = unit:GetAbsOrigin()
	local soundPlayed = false

	if unit.velocityMagnitude > CrackThreshSq and (not unit.lastCrackTime or currTime-unit.lastCrackTime > .3) then
		--if unitPos.z < (GroundZ + ground_thresh) then
		if not location then
			ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_ABSORIGIN, unit)
		else
			ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_ground_cracks.vpcf", PATTACH_CUSTOMORIGIN, unit)
			ParticleManager:SetParticleControl(p, 0, location)
		end
		--end

		if checkFence then
			if unit.velocityMagnitude > 2*CrackThreshSq then
				EmitSoundAtPosition("Fence_Heavy", unitPos)
			else
				EmitSoundAtPosition("Fence_Light", unitPos)
			end
			soundPlayed = true
		end

		if not soundPlayed then
			--local impactSound = "ThunderClapCaster"
			--local impactSound = "Impact_Medium" .. RandomInt(1, NumMediumImpactSounds)
			local impactSound = "Impact_Heavy" .. RandomInt(1, NumHeavyImpactSounds)
			if unit.velocityMagnitude > CrackThreshSq*3 then
				impactSound = "Impact_Giant" .. RandomInt(1, NumGiantImpactSounds)
			elseif unit.velocityMagnitude > CrackThreshSq*2 then
				--impactSound = "Impact_Heavy" .. RandomInt(1, NumHeavyImpactSounds)
				impactSound = "Impact_Giant" .. RandomInt(1, NumGiantImpactSounds)
			end
			if bPlayerPlayerColl then
				--impactSound = "Impact_Heavy" .. RandomInt(1, NumHeavyImpactSounds)
				impactSound = "ThunderClapCaster"
				if unit.isUsingPull then
					impactSound = "Wisp_Collision"
				end
				PlayCentaurBloodEffect(unit)
			end
			--print("sound played: " .. impactSound)
			EmitSoundAtPosition(impactSound, unitPos)
		end
		unit.lastCrackTime = currTime
	end
end

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
	pshot_coll.elasticity = 1
	pshot_coll.test = function(self, collider, collided)
		local passTest = false
		local ball = Ball.unit

		if not IsPhysicsUnit(collided) then return false end

		if TryWaitComponent(collider) then return true end

		if collided == ball and ball.pshotInvoke then
			-- 5-17-15 bug: if ball is really close to collided, collided won't receive knockback. 

			ball.dontChangeFriction = false

			ball:SetPhysicsFriction(GROUND_FRICTION)

			hero:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")

			ParticleManager:DestroyParticle(ball.powershot_particle, false)

			ball.pshotInvoke = false

			passTest = true
		end

		TrySignalComponents(passTest, collider)

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
		
		if TryWaitComponent(collider) then return true end

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
				--print("tackled.")

				-- do negative stuff
				if hero:GetTeam() ~= collided:GetTeam() then
					Timers:CreateTimer(.03, function()
						hero.tackleDummy:SetForwardVector((collided:GetAbsOrigin() - hero.tackleDummy:GetAbsOrigin()):Normalized())
						Timers:CreateTimer(.03, function()
							hero.tackleDummy:CastAbilityOnTarget(collided, hero.tackleDummyAbil, 0)
							Timers:CreateTimer(.06, function()
								--FireGameEvent("toggle_show_ability_silenced", {player_ID=collided:GetPlayerID(), ability_index=2})
							end)
						end)
					end)

					collided.last_time_tackled = GameRules:GetGameTime()
					AddMovementComponent(collided, "tackle", -9999)

					-- give collided a small push
					local pushDir = (collided:GetAbsOrigin() - hero:GetAbsOrigin()):Normalized()
					collided:AddPhysicsVelocity(pushDir*TACKLE_PUSH)

					collided.isTackled = true
				end
				hero.tackle_end_time = GameRules:GetGameTime()

				Timers:CreateTimer(TACKLE_SLOW_DURATION, function()
					if hero:GetTeam() ~= collided:GetTeam() then
						if GameRules:GetGameTime() - collided.last_time_tackled < (TACKLE_SLOW_DURATION+.1) then
							--FireGameEvent("toggle_show_ability_silenced", {player_ID=collided:GetPlayerID(), ability_index=2})
							RemoveMovementComponent(collided, "tackle")
							collided.isTackled = false
						end
					end
					hero.tackleTargets[collided:GetPlayerID()] = false
				end)

				hero.tackled_someone = true
			elseif collided.isUsingTackle or (collided.tackle_end_time and GameRules:GetGameTime()-collided.tackle_end_time < .2) or hero.isUsingTackle or
				(hero.tackle_end_time and GameRules:GetGameTime()-hero.tackle_end_time < .2) then
			elseif hero.velocityMagnitude > PP_COLLISION_THRESHOLD*PP_COLLISION_THRESHOLD then
				TryPlayCracks(collider, nil, nil, true)
				passTest = true
			end

		end

		TrySignalComponents(passTest, collider)

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
		TrySignalComponents(true, unit)
		--print("signaling components")
		--print("signaling. hero vel: " .. unit:GetPhysicsVelocity():Length())
	elseif unit.isComponent and unit.rollback_sem > 0 then
		local rollback_vel = unit.rollback_vels[1]
		unit:SetPhysicsVelocity(rollback_vel)
		--print("rolling back vel: " .. rollback_vel:Length())
		table.remove(unit.rollback_vels, 1)
		unit.rollback_sem = unit.rollback_sem - 1
	elseif unit.isComponent then
		--print("component successful gridnav bounce. component vel: " .. unit:GetPhysicsVelocity():Length())
	end

	if unit.isAboveGround then
		DotaStrikers:PlayReflectParticle(unit)
	end

end

function DotaStrikers:OnPreGridNavBounce( unit, normal )
	-- ensure the component owner bounced first.
	-- "if not TryWaitComponent(unit) then" is the same as saying "if the semaphore can't decrement, i.e. it's at 0"
	if unit.isComponent and not TryWaitComponent(unit) then
		unit.rollback_sem = unit.rollback_sem + 1
		--print("adding vel to rollback: " .. unit:GetPhysicsVelocity():Length())
		table.insert(unit.rollback_vels, 1, unit:GetPhysicsVelocity())
	end
end