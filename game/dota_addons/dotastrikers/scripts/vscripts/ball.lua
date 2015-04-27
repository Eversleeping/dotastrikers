Ball = {}

function Ball:Init(  )
	Ball.unit = CreateUnitByName("ball", Vector(0,0,GroundZ), true, nil, nil, DOTA_TEAM_GOODGUYS)
	local ball = Ball.unit
	BALL = ball.unit
	ball.isBall = true
	ball.lastBallVelocityDir = ball:GetForwardVector()

	function ball:IsBallOutOfBounds()
		local ballPos = ball:GetAbsOrigin()
		return ballPos.x > Bounds.max or ballPos.x < Bounds.min or ballPos.y > Bounds.max or ballPos.y < Bounds.min
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

	Timers:CreateTimer(1, function()
		if not ball.ballParticle then
			ball.ballParticle = ParticleManager:CreateParticle("particles/ball/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball)
		end
	end)

	ball:OnPhysicsFrame(function(unit)
		DotaStrikers:OnMyPhysicsFrame(ball)
		local ballPos = ball:GetAbsOrigin()
		for _,hero in ipairs(DotaStrikers.vHeroes) do
			local collision = (hero:GetAbsOrigin()-ball:GetAbsOrigin()):Length() <= BALL_COLLISION_DIST
			--if collision then print ("collision.") end
			if hero ~= ball.controller and collision then
				if not hero.ballProc then
					ball:SetPhysicsVelocity(Vector(0,0,0))
					if hero.isUsingPull then
						hero:CastAbilityNoTarget(hero.pull_break, 0)
					end
					print("new controller.")
					if ball.affectedByPowershot then
						ball.affectedByPowershot = false
						ball.dontChangeFriction = false
						hero:EmitSound("Hero_VengefulSpirit.MagicMissileImpact")
					else
						hero:EmitSound("Hero_Puck.ProjectileImpact")
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
			elseif hero == ball.controller and not collision then
				--print("ball.controller is nil")
				ball.controller = nil
				hero.ballProc = false
			end
		end

		--[[if ball:InGoalPost() then
			ball.inGoalPost = true
		else
			ball.inGoalPost = false
		end]]

		--print("ball veL: " .. VectorString(ball:GetPhysicsVelocity()))

		if ball.controller ~= nil then
			-- handle when controller took the ball out of bounds
			local isBallOutOfBounds = ball:IsBallOutOfBounds()

			if isBallOutOfBounds and not ball.outOfBoundsProc then
				--Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsTimer = Timers:CreateTimer(2, function()
					if not ball.outOfBoundsProc then return end
					print("Referee.unit:GetBallInBounds()")
					Referee.unit:GetBallInBounds()
				end)
				ball.outOfBoundsProc = true
			elseif not isBallOutOfBounds and ball.outOfBoundsProc then
				Timers:RemoveTimer(ball.outOfBoundsTimer)
				ball.outOfBoundsProc = false
			end
		else
			-- turn the facing direction of the ball. prolly went a lil overboard with this.
			local ballVelocityDir = ball:GetPhysicsVelocity():Normalized()
			local ballFV = ball:GetForwardVector()

			local angDelta = math.abs(RotationDelta(VectorToAngles(ballVelocityDir), VectorToAngles(ballFV)).y)
			if angDelta > 20 and angDelta ~= 180 then
				ball.lastForwardVector = ballVelocityDir
				if ball.velocityMagnitude > 100*100 and ball.bStarted then
					--print("velocityMagnitude: " .. ball.velocityMagnitude)
					ball:SetForwardVector(ballVelocityDir)
					--print("angDelta: " .. angDelta)
				end
			end
		end
	end)

	return ball
end