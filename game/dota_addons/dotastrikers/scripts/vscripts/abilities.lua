THROW_VELOCITY = 1700
SURGE_TICK = .2
SLAM_Z = 2100
SLAM_XY = 1000

PSHOT_VELOCITY = 1600
PSHOT_ONHIT_VEL = 1300
PSHOT_COOLDOWN = 10

NINJA_JUMP_Z = 1400
NINJA_JUMP_XY = 800

PULL_ACCEL_FORCE = 2300
PULL_MAX_DURATION = 4.55
PULL_COOLDOWN = 15

SPRINT_ACCEL_FORCE = 900
SPRINT_INITIAL_FORCE = 600
SPRINT_COOLDOWN = 6

TACKLE_SLOW_DURATION = 4

BH_RADIUS = 430
BH_DURATION = 6
BH_FORCE_MAX = 4000
BH_FORCE_MIN = 3000
BH_TIME_TILL_MAX_GROWTH = BH_DURATION-2
--BH_COOLDOWN = 11

TACKLE_DURATION = .5
TACKLE_VEL_FORCE = 1500

BLINK_WAIT_TIME = .5
BLINK_DISTANCE = 700

SWAP_PROJ_VELOCITY = 1400
SWAP_DURATION = 2

-- ball goes up a lil in the z direction if hero throws ball while in the air.
KICK_BALL_Z_PUSH = 280
GOALIE_JUMP_Z = 1300
GOALIE_JUMP_XY = 120

NUM_FROWNS = 6
NUM_TAUNTS = 6
SMILEY_COOLDOWN = 2

REF_OOB_HIT_VEL = 2200 -- referee out of bounds hit velocity.
SURGE_MOVESPEED_FACTOR = 1/3

function DotaStrikers:OnAbilityUsed( keys )
	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()
	local ball = Ball.unit

	if abilityname == "slam" then

	end
end

function DotaStrikers:OnRefereeAttacked( keys )
	--print("OnRefereeAttacked")
	local attacked = keys.target
	local ball = Ball.unit

	if not attacked == ball then return end

	local towardsCenter = (Vector(0,0,GroundZ)-ball:GetAbsOrigin()):Normalized()

	ball.controlledByRef = true

	-- ball is going out of hands of the ref
	ball.controller = nil

	ball.lastMovedBy = Referee

	ball:SetPhysicsVelocity(towardsCenter*REF_OOB_HIT_VEL)

	local caster = keys.caster -- Referee

	-- reset pos of ref
	Timers:CreateTimer(.5, function()
		Referee:SetAbsOrigin(RefereeSpawnPos)
		Timers:CreateTimer(.06, function()
			AddEndgameRoot(Referee)
			AddDisarmed(Referee)
		end)
	end)

	ball:SetHealth(ball:GetMaxHealth())
end

function DotaStrikers:on_powershot_succeeded( keys, dir )
	local caster = keys.caster
	local ball = Ball.unit
	-- occurs when invoker got his ball stolen while channeling pshot.
	if ball.controller ~= caster then return end

	ball.controller:EmitSound("Hero_VengefulSpirit.MagicMissile")
	ball.dontChangeFriction = true
	ball:SetPhysicsFriction(0)
	ball.powershot_particle = ParticleManager:CreateParticle("particles/powershot/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, ball.particleDummy)

	ball:AddPhysicsVelocity(dir*PSHOT_VELOCITY)

	ball.affectedByPowershot = true

	ball.lastMovedBy = caster

	ball.controller = nil

	if not Testing then
		caster:FindAbilityByName("powershot"):StartCooldown(PSHOT_COOLDOWN)
	end
end

function DotaStrikers:throw_ball( keys )
	local caster = keys.caster
	local ball = Ball.unit

	if Testing then
		keys.ability:EndCooldown()
	end

	if caster ~= ball.controller then return end

	local point = keys.target_points[1]
	local ballPos = ball:GetAbsOrigin()
	local casterPos = caster:GetAbsOrigin()
	local targetpoint_at_ball_z = Vector(point.x,point.y,ballPos.z)

	local dir = (targetpoint_at_ball_z-ballPos):Normalized()

	if keys.ability:GetAbilityName() == "powershot" then
		print("powershot")
		self:on_powershot_succeeded(keys, dir)
	else
		-- if caster is above ground, give the ball more of a push in z direction.
		if caster.isAboveGround then
			ball:AddPhysicsVelocity(dir*THROW_VELOCITY + Vector(0,0,KICK_BALL_Z_PUSH))
		else
			ball:AddPhysicsVelocity(dir*THROW_VELOCITY)
		end

		ball:EmitSound("Kick" .. RandomInt(1, NUM_KICK_SOUNDS))

		ball.lastMovedBy = caster

		ball.controller = nil
	end
end

function DotaStrikers:surge( keys )
	local caster = keys.caster
	caster.surgeOn = true

	-- apply effects
	--particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf
	if caster.isSprinter then
		caster:RemoveAbility("super_sprint")
		caster:AddAbility("super_sprint_break")
		caster:FindAbilityByName("super_sprint_break"):SetLevel(1)

		caster.surgeParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		
		caster.sprint_fv = caster:GetForwardVector()
		caster:AddPhysicsVelocity(caster.sprint_fv*SPRINT_INITIAL_FORCE)
		
		caster.sprint_accel = caster.sprint_fv*SPRINT_ACCEL_FORCE
		caster.last_supersprint_time = GameRules:GetGameTime()
		
		caster:SetPhysicsAcceleration(caster:GetPhysicsAcceleration()+caster.sprint_accel)

		local component = AddPhysicsComponent("super_sprint", caster)
		component:SetPhysicsAcceleration(caster.sprint_accel)
		component:OnPhysicsFrame(function(x)
			if not caster:HasAbility("super_sprint_break") then
				return
			end

			if GameRules:GetGameTime() - caster.last_supersprint_time > .1 then
				if caster.velocityMagnitude < 200*200 then
					caster:CastAbilityNoTarget(caster:FindAbilityByName("super_sprint_break"), 0)
				end
			end

			local orig_accel = caster:GetPhysicsAcceleration()-caster.sprint_accel

			caster.sprint_accel = caster:GetForwardVector()*SPRINT_ACCEL_FORCE

			caster:SetPhysicsAcceleration(orig_accel+caster.sprint_accel)
			component:SetPhysicsAcceleration(orig_accel+caster.sprint_accel)
			--print("curr vel mag: " .. caster.velocityMagnitude)
		end)
		caster.super_sprint_component = component

		caster:EmitSound("Hero_Weaver.Shukuchi")

		-- this is for animation purposes. We also needed to add "OverrideAnimation" "ACT_DOTA_RUN" in the super_sprint ability for this to work.
		-- because the rooted sets movespeed to 0, which causes ACT_DOTA_RUN to never be called.
		caster:AddNewModifier(caster, nil, "modifier_rune_haste", {})

		-- root hero so the haste movespeed doesn't influence him
		AddEndgameRoot(caster)

		Timers:CreateTimer(.03, function()
			AddHasteAnimation(caster)
		end)

		caster.isUsingSuperSprint = true

	elseif caster.isNinja then
		caster:RemoveAbility("ninja_invis_sprint")
		caster:AddAbility("ninja_invis_sprint_break")
		caster:FindAbilityByName("ninja_invis_sprint_break"):SetLevel(1)
		caster.surgeParticle = ParticleManager:CreateParticle("particles/ninja_invis_sprint/dark_seer_surge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		caster:EmitSound("Hero_BountyHunter.WindWalk")

		if caster.dust_particle then
			ParticleManager:DestroyParticle(caster.dust_particle, false)
			caster.dust_particle = nil
		end

		-- we need neutral particle so enemies can see the dust too.
		caster.dust_particle = CreateNeutralParticle( "particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf", caster:GetAbsOrigin(), PATTACH_ABSORIGIN, 2 )

		caster:SetBaseMoveSpeed(caster:GetBaseMoveSpeed() + caster.base_move_speed*SURGE_MOVESPEED_FACTOR)
	else
		caster:RemoveAbility("surge")
		caster:AddAbility("surge_break")
		caster:FindAbilityByName("surge_break"):SetLevel(1)

		--particles/generic_gameplay/rune_haste_owner.vpcf
		caster.surgeParticle = ParticleManager:CreateParticle("particles/items2_fx/phase_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

		-- play local phaseboots sound.
		local phaseBoots = CreateItem("item_phase", caster, caster)
		-- apparently this works fine without timers.
		caster:AddItem(phaseBoots)
		caster:CastAbilityImmediately(phaseBoots, 0)
		caster:RemoveItem(phaseBoots)

		caster:SetBaseMoveSpeed(caster:GetBaseMoveSpeed() + caster.base_move_speed*SURGE_MOVESPEED_FACTOR)
	end
end

function DotaStrikers:surge_break( keys )
	local caster = keys.caster
	caster.surgeOn = false

	if caster.isSprinter then
		caster:RemoveAbility("super_sprint_break")
		caster:AddAbility("super_sprint")
		local super_sprint = caster:FindAbilityByName("super_sprint")
		super_sprint:SetLevel(1)

		Timers:RemoveTimer(caster.sprint_timer)
		Timers:RemoveTimer(caster.dist_check_timer)
		caster:SetPhysicsAcceleration(caster:GetPhysicsAcceleration()-caster.sprint_accel)
		caster:SetPhysicsVelocity(caster:GetPhysicsVelocity()-(caster.super_sprint_component:GetPhysicsVelocity()*3/4))
		caster.super_sprint_component:RemoveComponent()

		--[[ remove most of the vel gained from that sprint
		local comp = caster.super_sprint_component
		local compVel = comp:GetPhysicsVelocity()]]

		if not Testing then
			super_sprint:StartCooldown(SPRINT_COOLDOWN)
		else
			super_sprint:EndCooldown()
			caster:SetMana(caster:GetMaxMana())
		end
		if caster:HasModifier("modifier_rune_haste") then
			caster:RemoveModifierByName("modifier_rune_haste")
			RemoveEndgameRoot(caster)
		end
		RemoveHasteAnimation(caster)
		caster.isUsingSuperSprint = false

		--caster:EmitSound("Hero_Slardar.MovementSprint")
	elseif caster.isNinja then
		caster:RemoveAbility("ninja_invis_sprint_break")
		caster:AddAbility("ninja_invis_sprint")
		local ninja_invis_sprint = caster:FindAbilityByName("ninja_invis_sprint")
		ninja_invis_sprint:SetLevel(1)
		-- we need to add 1 apparently because going back and forth between the values decreases the movespeed
		-- by 1 each time. No idea why.
		caster:SetBaseMoveSpeed(caster:GetBaseMoveSpeed() - caster.base_move_speed*SURGE_MOVESPEED_FACTOR+1)
		if caster:HasModifier("modifier_ninja_invis") then
			caster:RemoveModifierByName("modifier_ninja_invis")
		end
	else
		caster:RemoveAbility("surge_break")
		caster:AddAbility("surge")
		caster:FindAbilityByName("surge"):SetLevel(1)
		caster:SetBaseMoveSpeed(caster:GetBaseMoveSpeed() - caster.base_move_speed*SURGE_MOVESPEED_FACTOR+1)
	end
	if caster.surgeParticle then
		ParticleManager:DestroyParticle(caster.surgeParticle, false)
	end
end

function DotaStrikers:pull( keys )
	local caster = keys.caster

	-- cant cast pull while being ball controller.
	if caster == Ball.unit.controller then
		ShowErrorMsg(caster, "Can't cast Pull as the ball controller")
		return
	end

	caster.currPullAccel = Vector(0,0,0)
	caster.isUsingPull = true
	caster:RemoveAbility("pull")
	caster:AddAbility("pull_break")
	caster.pull_break = caster:FindAbilityByName("pull_break")
	caster.pull_break:SetLevel(1)

	local ball = Ball.unit

	-- particle
	caster.pullParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(caster.pullParticle, 1, ball.particleDummy, 1, "follow_origin", ball.particleDummy:GetAbsOrigin(), true)

	caster:EmitSound("Hero_Wisp.Tether")
	caster:EmitSound("Hero_Wisp.Tether.Target")

	--caster.pullParticle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_overcharge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	caster.pull_start_time = GameRules:GetGameTime()
	caster.pull_timer = Timers:CreateTimer(PULL_MAX_DURATION, function()
		--caster.pull_duration = caster.pull_duration + .5
		if caster.isUsingPull then
			caster:CastAbilityNoTarget(caster.pull_break, 0)
		end
	end)


end

function DotaStrikers:pull_break( keys )
	local caster = keys.caster
	caster.isUsingPull = false
	caster:RemoveAbility("pull_break")
	caster:AddAbility("pull")
	local pullAbility = caster:FindAbilityByName("pull")
	pullAbility:SetLevel(1)

	-- remove particle effect
	ParticleManager:DestroyParticle(caster.pullParticle, false)
	--ParticleManager:DestroyParticle(caster.pullParticle2, false)

	caster:EmitSound("Hero_Wisp.Tether.Stop")
	caster:StopSound("Hero_Wisp.Tether")

	Timers:RemoveTimer(caster.pull_timer)

	-- revert acceleration
	caster:SetPhysicsAcceleration(caster:GetPhysicsAcceleration()-caster.currPullAccel)

	-- give hero one final push
	--local dirToBall = (Ball.unit:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	--caster:AddPhysicsVelocity(1000*dirToBall)

	-- determine cooldown to set
	--[[local timeDiff = GameRules:GetGameTime() - caster.pull_start_time
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
	end]]
	pullAbility:StartCooldown(PULL_COOLDOWN)
	if Testing then
		pullAbility:EndCooldown()
	end

end

function DotaStrikers:ninja_jump( keys )
	local caster = keys.caster
	caster:AddPhysicsVelocity(caster:GetForwardVector()*NINJA_JUMP_XY + Vector(0,0,NINJA_JUMP_Z))
	caster.noBounce = true
	caster.isUsingJump = true

	if caster:HasAbility("ninja_invis_sprint_break") then
		caster:CastAbilityNoTarget(caster:FindAbilityByName("ninja_invis_sprint_break"), 0)
	end

	if Testing then keys.ability:EndCooldown() end
end

function DotaStrikers:text_particle( keys )
	local caster = keys.caster
	if not caster then print("text_particle, caster nil") return end

	local abilName = ""
	if keys.ability then
		abilName = keys.ability:GetAbilityName()
	end

	local particle = "particles/pass_me.vpcf"

	if abilName == "item_frown" then
		local frownIndex = RandomInt(1, NUM_FROWNS)
		particle = "particles/frowns/frown" .. frownIndex .. ".vpcf"

		-- helps reduce spam
		if caster.tauntItem then
			caster.tauntItem:StartCooldown(SMILEY_COOLDOWN)
		end

	elseif abilName == "item_taunt" then
		local tauntIndex = RandomInt(1, NUM_TAUNTS)
		particle = "particles/taunts/taunt" .. tauntIndex .. ".vpcf"

		-- helps reduce spam
		if caster.frownItem then
			caster.frownItem:StartCooldown(SMILEY_COOLDOWN)
		end
	end

	-- remove the current text particle above the caster, if any. to avoid clutter
	if caster.textParticle then
		if type(caster.textParticle) == "table" then
			for i,v in ipairs(caster.textParticle) do
				ParticleManager:DestroyParticle(v, true)
			end
		else
			ParticleManager:DestroyParticle(caster.textParticle, true)
		end
		caster.textParticle = nil
	end

	if abilName == "pass_me" then
		local parts = {}
		local teammates = GetTeammates(caster)
		local part = ParticleManager:CreateParticleForPlayer("particles/pass_me.vpcf", PATTACH_OVERHEAD_FOLLOW, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControlEnt(part, 3, caster, 3, "follow_origin", caster:GetAbsOrigin(), true)
		table.insert(parts, part)
		for i,hero2 in ipairs(teammates) do
			part = ParticleManager:CreateParticleForPlayer("particles/pass_me.vpcf", PATTACH_OVERHEAD_FOLLOW, hero2, hero2:GetPlayerOwner())
			ParticleManager:SetParticleControlEnt(part, 3, caster, 3, "follow_origin", caster:GetAbsOrigin(), true)
			table.insert(parts, part)
		end
		caster.textParticle = parts
	else
		if keys.exclamation then
			particle = "particles/exclamation.vpcf"
		end

		caster.textParticle = ParticleManager:CreateParticle(particle, PATTACH_OVERHEAD_FOLLOW, caster)
		if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
			ParticleManager:SetParticleControl(caster.textParticle, 1, Vector(0,255,0))
		else
			ParticleManager:SetParticleControl(caster.textParticle, 1, Vector(255,0,0))
		end
		ParticleManager:SetParticleControlEnt(caster.textParticle, 3, caster, 3, "follow_origin", caster:GetAbsOrigin(), true)
	end

end

function DotaStrikers:slam( keys )
	local caster = keys.caster
	local hero = caster
	local ball = Ball.unit

	local radius = hero:FindAbilityByName("slam"):GetCastRange()
	local affected = 0
	--print("radius: " .. radius)
	for i, ent in ipairs(Entities:FindAllInSphere(hero:GetAbsOrigin(), radius)) do
		if IsPhysicsUnit(ent) and (ent.isDSHero or ent.isBall) then
			local dir = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Normalized()
			local dist = (ent:GetAbsOrigin()-hero:GetAbsOrigin()):Length()
			local knockbackScale = (radius-dist)/radius
			-- if it's the ball and ball has a controller, don't move the ball.
			-- if it's the slammer, don't move him
			if (ent == ball and ball.controller ~= nil) or ent == hero then

			else
				if ent == ball then
					--ball.lastController = caster
					ball.lastMovedBy = caster
				end
				ent:AddPhysicsVelocity((dir*SLAM_XY + Vector(0,0,SLAM_Z)*knockbackScale))
				affected = affected + 1
			end
		end
	end

	local echoDummy = CreateUnitByName("dummy", hero:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NEUTRALS)
	echoDummy:AddAbility("slam_dummy")
	local slamAbil = echoDummy:FindAbilityByName("slam_dummy")
	slamAbil:SetLevel(1)

	Timers:CreateTimer(NEXT_FRAME, function()
		echoDummy:CastAbilityImmediately(slamAbil, 0)
		Timers:CreateTimer(1, function()
			echoDummy:ForceKill(true)
		end)
	end)

	if Testing then
		keys.ability:EndCooldown()
	end
end

function DotaStrikers:black_hole( keys )
	local caster = keys.caster
	local ball = Ball.unit
	local point = keys.target_points[1]
	local casterID = caster:GetPlayerID()
	local bh_z = BH_RADIUS*.7

	-- adjust the z level of the point
	point = Vector(point.x,point.y,point.z+bh_z)

	--particles/black_hole/enigma_blackhole.vpcf
	caster.bh_particle = ParticleManager:CreateParticle("particles/black_hole/enigma_blackhole.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(caster.bh_particle, 0, point)
	EmitSoundAtPosition("Hero_Enigma.Black_Hole", point, BH_DURATION)

	local time_quantum = .033
	--local ents = Entities:FindAllInSphere(point, BH_RADIUS)
	caster.bh_timer = Timers:CreateTimer(function()
		OnBHThink(caster, point, casterID, ball)
		return time_quantum
	end)

	caster.bh_max_growth_endtime = GameRules:GetGameTime()+BH_TIME_TILL_MAX_GROWTH
	caster.bh_growth_interval = (BH_FORCE_MAX/BH_TIME_TILL_MAX_GROWTH)*time_quantum
	caster.bh_endtime = GameRules:GetGameTime() + BH_DURATION
	caster.bh_curr_force = 700

	-- end timer
	Timers:CreateTimer(BH_DURATION, function()
		Timers:RemoveTimer(caster.bh_timer)
		ParticleManager:DestroyParticle(caster.bh_particle, false)
		EmitSoundAtPosition("Hero_Enigma.Black_Hole.Stop", point)

		for k,hero in pairs(DotaStrikers.colliderFilter) do
			if hero ~= caster then
				hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()-hero.last_bh_accels[casterID])
				hero.last_bh_accels[casterID] = Vector(0,0,0)
			end
		end

		--hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()+hero.last_bh_accels[casterID])
	end)

	if Testing then
		keys.ability:EndCooldown()
	end
end

function OnBHThink( caster, point, casterID, ball )
	local currTime = GameRules:GetGameTime()

	-- increase the force
	--[[if currTime < caster.bh_max_growth_endtime then
		caster.bh_curr_force = caster.bh_curr_force + caster.bh_growth_interval
		print(caster.bh_curr_force)
	else
		caster.bh_curr_force = BH_FORCE_MAX
	end]]
	caster.bh_curr_force = BH_FORCE_MAX

	for k,unit in pairs(DotaStrikers.colliderFilter) do
		if unit ~= caster and (unit.isDSHero or unit == ball) then
			local hero = unit
			--print("Point: " .. VectorString(point))
			local p1 = hero:GetAbsOrigin()
			local pID = 20 -- 20 is the ball
			if hero ~= ball then
				pID = hero:GetPlayerID()
			end
			--print("len: " .. (point-p1):Length())
			local len = (point-p1):Length()
			local force = (len/BH_RADIUS)*caster.bh_curr_force
			if force < BH_FORCE_MIN then
				force = BH_FORCE_MIN
			end
			if len <= (BH_RADIUS) then
				if not caster.bh_targets[pID] then
					caster.bh_targets[pID] = true
				end
				hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()-hero.last_bh_accels[casterID])
				local dir = (point-p1):Normalized()
				hero.last_bh_accels[casterID] = dir*force
				hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()+hero.last_bh_accels[casterID])
				if hero == ball then
					ball.lastMovedBy = caster
				end
			else
				if hero.last_bh_accels[casterID] ~= Vector(0,0,0) then
					hero:SetPhysicsAcceleration(hero:GetPhysicsAcceleration()-hero.last_bh_accels[casterID])
					hero.last_bh_accels[casterID] = Vector(0,0,0)
				end
				if caster.bh_targets[pID] then
					caster.bh_targets[pID] = false
				end
			end
		end
	end
end

function DotaStrikers:tackle( keys )
	local caster = keys.caster
	local ball = Ball.unit
	local point = keys.target_points[1]
	point = Vector(point.x, point.y, caster:GetAbsOrigin().z)
	
	caster.isUsingTackle = true
	
	caster.tackle_end_time = GameRules:GetGameTime() + TACKLE_DURATION
	
	caster:AddNewModifier(caster, nil, "modifier_rune_haste", {})
	AddEndgameRoot(caster)

	Timers:CreateTimer(.03, function()
		AddHasteAnimation(caster)
	end)

	caster.tackle_vel = caster:GetForwardVector()*TACKLE_VEL_FORCE
	caster:SetPhysicsVelocity(caster:GetPhysicsVelocity()+caster.tackle_vel)

	caster:EmitSound("Hero_FacelessVoid.TimeWalk")

	local tackleDummy = CreateUnitByName("dummy", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeam())
	caster.tackleDummy = tackleDummy
	caster.tackleDummy:AddAbility("bloodseeker_rupture_datadriven")
	caster.tackleDummyAbil = caster.tackleDummy:FindAbilityByName("bloodseeker_rupture_datadriven")
	caster.tackleDummyAbil:SetLevel(1)

	-- move order to turn the unit
	ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
		Position = 2000*(point-caster:GetAbsOrigin()):Normalized(), Queue = false})

	caster.tackleTimer = Timers:CreateTimer(function()
		if GameRules:GetGameTime() > caster.tackle_end_time or caster.tackled_someone then
			caster.isUsingTackle = false
			caster.tackle_vel = caster.tackle_vel-(caster.tackle_vel*caster:GetPhysicsFriction())
			caster:SetPhysicsVelocity(caster:GetPhysicsVelocity()-caster.tackle_vel)
			if caster:HasModifier("modifier_rune_haste") then
				caster:RemoveModifierByName("modifier_rune_haste")
				RemoveEndgameRoot(caster)
			end
			RemoveHasteAnimation(caster)
			Timers:CreateTimer(1, function()
				tackleDummy:ForceKill(true)
			end)
			caster.tackled_someone = false
			caster:Stop()

			return nil
		end
		
		-- remove last vel
		caster.tackle_vel = caster.tackle_vel-(caster.tackle_vel*caster:GetPhysicsFriction())
		local orig_vel = caster:GetPhysicsVelocity()-caster.tackle_vel
		caster.tackle_vel = caster:GetForwardVector()*TACKLE_VEL_FORCE
		caster:SetPhysicsVelocity(orig_vel+caster.tackle_vel)

		if not caster.last_tackle_particle_time or GameRules:GetGameTime() - caster.last_tackle_particle_time > .03 then
			local part = ParticleManager:CreateParticle("particles/ghost_model.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControlEnt(part, 1, caster, 1, "follow_origin", caster:GetAbsOrigin(), true)
			caster.last_tackle_particle_time = GameRules:GetGameTime()
		end

		return .01
	end)



	if Testing then
		keys.ability:EndCooldown()
	end
end

function DotaStrikers:goalie_jump(keys)
	local caster = keys.caster
	local part = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(part, 1, caster, 1, "follow_origin", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(part, 2, Vector(.8,0,0))
	--ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin())

	caster:AddPhysicsVelocity(caster:GetForwardVector()*GOALIE_JUMP_XY + Vector(0,0,GOALIE_JUMP_Z))
	caster.noBounce = true
	caster.isUsingGoalieJump = true

	-- no need to do this because the game automatically keeps the cooldown when adding/removing the same spell
	caster.timeToRefreshGoalieJump = GameRules:GetGameTime() + keys.ability:GetCooldown(1)

	caster:EmitSound("Hero_Rubick.Telekinesis.Cast")

	if Testing then keys.ability:EndCooldown() end

end

function DotaStrikers:blink( keys )
	local caster = keys.caster

	caster.blink_timer = Timers:CreateTimer(BLINK_WAIT_TIME, function()
		local fv = caster:GetForwardVector()

		local part = ParticleManager:CreateParticle("particles/units/heroes/hero_queenofpain/queen_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControlEnt(part, 1, caster, 1, "attach_hitloc", caster:GetAbsOrigin(), true)
		--caster:EmitSound("Hero_QueenOfPain.Blink_out")
		EmitSoundAtPosition("Hero_QueenOfPain.Blink_out", caster:GetAbsOrigin())

		-- execute a movement order in the current fv direction, to prevent hero from immediately moving backwards after teleporting.
		if not caster:IsIdle() then
			ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
				Position = caster:GetAbsOrigin() + fv*1500, Queue = false})
		end

		local newPos = caster:GetAbsOrigin() + BLINK_DISTANCE*fv
		caster:SetAbsOrigin(newPos)

		local part2 = ParticleManager:CreateParticle("particles/units/heroes/hero_queenofpain/queen_blink_end.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(part2, 0, newPos)
		EmitSoundAtPosition("Hero_QueenOfPain.Blink_in",newPos )

	end)

	if Testing then keys.ability:EndCooldown() end

end

function DotaStrikers:swap(keys)
	local caster = keys.caster
	local point = keys.target_points[1]
	local ball = Ball.unit

	local swapDummy = CreateUnitByName("dummy", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeam())
	caster.swapDummy = swapDummy
	swapDummy.isSwapDummy = true
	swapDummy.caster = caster

	swapDummy.swapParticle = ParticleManager:CreateParticle("particles/illusory_orb/puck_illusory_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, swapDummy)
	local part = swapDummy.swapParticle
	--ParticleManager:SetParticleControlEnt(part, 1, swapDummy, 1, "follow_origin", swapDummy:GetAbsOrigin(), true)
	
	swapDummy:EmitSound("Hero_Puck.Illusory_Orb")

	self:SetupPhysicsSettings( swapDummy )
	--Physics:Unit(swapDummy)
	swapDummy:SetPhysicsFriction(0)
	local dir = (point-caster:GetAbsOrigin()):Normalized()
	local vel = dir*SWAP_PROJ_VELOCITY
	swapDummy:SetPhysicsVelocity(vel)

	swapDummy:OnPhysicsFrame(function(x)
		DebugDrawCircle(swapDummy:GetAbsOrigin(), Vector(255,0,0), 30, 50, true, .03)
		ParticleManager:SetParticleControl(part, 4, swapDummy:GetAbsOrigin())
	end)

	--table.insert(self.colliderFilter, swapDummy)
	swapDummy.colliderID = DoUniqueString("a")
	self.colliderFilter[swapDummy.colliderID] = swapDummy

	function swapDummy:OnSwapCollision( collided )
		local casterVel = caster:GetPhysicsVelocity()
		local casterPos = caster:GetAbsOrigin()
		local collidedVel = collided:GetPhysicsVelocity()
		local collidedPos = collided:GetAbsOrigin()


		caster:SetPhysicsVelocity(collidedVel)
		caster:SetAbsOrigin(collidedPos)
		caster:EmitSound("Hero_Puck.EtherealJaunt")
		Timers:CreateTimer(.03, function()
			ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, collided)
		end)

		collided:SetPhysicsVelocity(casterVel)
		collided:SetAbsOrigin(casterPos)

		local ball_controller = nil
		local newPos = collidedPos
		if caster == ball.controller then
			ball_controller = caster
		elseif collided == ball.controller then
			ball_controller = collided
			newPos = casterPos
		end

		if ball_controller then
			ball.controller = nil
			ball_controller.ballProc = false
			ball:SetAbsOrigin(newPos+ball_controller:GetForwardVector()*20)

		end


		self:DS_Destroy(true)


	end

	function swapDummy:DS_Destroy( bSuccess )
		ParticleManager:DestroyParticle(self.swapParticle, false)
		self:StopSound("Hero_Puck.Illusory_Orb")

		swapDummy.isSwapDummy = false
		swapDummy:StopPhysicsSimulation()
		swapDummy:ForceKill(true)
		DotaStrikers.colliderFilter[swapDummy.colliderID] = nil


	end

	caster.swapTimer = Timers:CreateTimer(SWAP_DURATION, function()
		if swapDummy.isSwapDummy then
			swapDummy:DS_Destroy(false)
		end

	end)

	if Testing then keys.ability:EndCooldown() end

end