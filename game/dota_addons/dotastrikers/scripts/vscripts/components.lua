
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
			unit:SetBaseMoveSpeed(total)

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