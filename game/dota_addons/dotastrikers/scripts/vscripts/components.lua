
function AddMovementComponent( ... )
	local t = {...}
	local unit = t[1]
	local name = t[2]
	local speed = t[3]

	if not unit.movement_components then
		unit.movement_components = {}
	end

	local mcs = unit.movement_components

	mcs[name] = speed
	
	function unit:GetMovementComponent( name )
		return mcs[name]
	end

	if not unit.movement_component_timer then
		unit.movement_component_timer = Timers:CreateTimer(function()
			local total = 0
			for name,val in pairs(mcs) do
				total = total + val
			end
			--unit:SetBaseMoveSpeed(total)
			total = math.floor(total)

			if total > 600 then
				total = 600
			elseif total < 1 then
				total = 1
			end

			local needsNewAbil = false

			if unit.movespeedAbil and IsValidEntity(unit.movespeedAbil) then
				local abilName = unit.movespeedAbil:GetAbilityName()
				local old = tonumber(abilName:sub(11))
				if old ~= total then
					unit:RemoveAbility(abilName)
					if unit:HasModifier("modifier_movespeed_" .. old) then
						unit:RemoveModifierByName("modifier_movespeed_" .. old)
					end

					unit.movespeedAbil = nil
				end
			else
				if unit.movespeedModifierName and unit:HasModifier(unit.movespeedModifierName) then
					unit:RemoveModifierByName(unit.movespeedModifierName)
				end

				needsNewAbil = true
			end

			if needsNewAbil then
				--unit:SetBaseMoveSpeed(0)
				local abilName = "movespeed_" .. total
				unit:AddAbility(abilName)
				unit.movespeedAbil = unit:FindAbilityByName(abilName)
				unit.movespeedAbil:SetLevel(1)
				unit.movespeedModifierName = "modifier_movespeed_" .. total
				--print("change to " .. "modifier_movespeed_" .. total)
			end

			return .01
		end)
	end
end

function RemoveMovementComponent( unit, name )
	unit.movement_components[name] = nil
end

function ModifyMovementComponent( unit, name, val )
	unit.movement_components[name] = val
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
	component.semaphore = 0
	component.rollback_sem = 0
	component.rollback_vels = {}
	DotaStrikers:SetupPhysicsSettings(component)
	component:SetPhysicsBoundingRadius(unit:GetPhysicsBoundingRadius()+10)
	component.isComponent = true
	component.componentOwner = unit
	components[name] = component
	local colliderID = DoUniqueString("a")
	DotaStrikers.colliderFilter[colliderID] = component

	component.component_timer = Timers:CreateTimer(function()
		if not IsValidEntity(component) or not component:IsAlive() then
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
		component:SetPhysicsVelocity(Vector(0,0,0))
		components[name] = nil
		DotaStrikers.colliderFilter[colliderID] = nil
		component:RemoveSelf()
	end

	return component
end

function IsComponent( unit )
	return unit.isComponent
end

function TrySignalComponents(passTest, unit )
	if passTest and unit.components then
		for k,component in pairs(unit.components) do
			component.semaphore = component.semaphore + 1
		end
	end
end

function TryWaitComponent( unit )
	if unit.isComponent and unit.semaphore > 0 then
		unit.semaphore = unit.semaphore - 1
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