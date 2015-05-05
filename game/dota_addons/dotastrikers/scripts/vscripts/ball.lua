BALL_PARTICLE_Z_OFFSET=40 --this makes the particle look nicer.
NUM_CATCH_SOUNDS = 3

function Ball:Init(  )
	Ball.unit = CreateUnitByName("ball", Vector(0,0,GroundZ), true, nil, nil, DOTA_TEAM_NOTEAM)
	local ball = Ball.unit
	BALL = ball.unit
	ball.isBall = true
	ball.particleDummy = CreateUnitByName("dummy", Vector(0,0,GroundZ+BALL_PARTICLE_Z_OFFSET), false, nil, nil, DOTA_TEAM_NOTEAM)
	ball.lastBounceTime = 0

	function ball:IsBallOutOfBounds()
		local ballPos = ball:GetAbsOrigin()
		local smoothing = 20
		return ballPos.x > (Bounds.max+RectangleOffset+smoothing) or ballPos.x < (Bounds.min-RectangleOffset-smoothing) or 
			ballPos.y > (Bounds.max+smoothing) or ballPos.y < (Bounds.min-smoothing)
	end

	function ball:InGoalPost(  )
		local ballPos = ball:GetAbsOrigin()
		local inGoalPost = true
		for i=1,2 do
			local gc = GoalColliders[i]
			local corner1 = gc.corners[1]
			local corner2 = gc.corners[3]
			if ballPos.x > corner1.x or ballPos.x < corner2.x or ballPos.y > corner1.y or ballPos.y < corner2.y then
				inGoalPost = false
			end
		end
		return inGoalPost
	end

	ball.controller = nil
	DotaStrikers:ApplyDSPhysics(ball)

	-- constantly reposition the ball particle dummy.
	Timers:CreateTimer(1, function()
		if not ball.ballParticle then
			ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)
		end
		local pos = ball:GetAbsOrigin()
		ball.particleDummy:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+BALL_PARTICLE_Z_OFFSET))
		return .01
	end)

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
						ParticleManager:DestroyParticle(ball.powershot_particle, true)
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
	end)

	return ball
end
