MyllPhysics = {}
MyllPhysics.Units = {}
DEFAULT_GROUND_FRICTION = .05
DEFAULT_AIR_FRICTION = .02
ABOVE_GROUND_THRESHOLD = 10

function MyllPhysics:AddUnit( unit )
	unit.myllPhysics = {}
	local phys = unit.myllPhysics
	phys.id = DoUniqueString("id")
	MyllPhysics.Units[phys.id] = unit

	function unit:GetMyllPhysics(  )
		return phys
	end

	-- ADDING FUNCTIONS

	-- AddVelocity("x_spell", Vector(2000,0,0))
	function phys:AddVelocity( ... )
		AddVector("velocity", {...})
	end

	function phys:AddAcceleration( ... )
		AddVector("acceleration", {...})
	end

	function phys:AddVector( vectType, t )
		local currTable = phys[vectType .. "s"]
		local name = t[1]
		local vect = t[2]
		local properties = t[3]
		if type(name) ~= "string" then
			vect = t[1]
			name = DoUniqueString(vectType)
		end

		MyllPhysics:SpecialVector(name, vectType, vect)

		for k,v in pairs(properties) do
			vect.special_properties[k] = v
		end

		print(name .. ": " .. VectorString(vect))
		currTable[name] = vect
		return vect
	end

	-- GETTING FUNCTIONS

	function phys:GetVector( vectType, t )
		local currTable = phys[vectType .. "s"]
		local name = t[1]
		if not name then
			return phys:GetTotal(currTable)
		else
			return currTable[name]
		end
	end

	function phys:GetVelocity( ... )
		return self:GetVector("velocity", {...})
	end

	function phys:GetAcceleration( ... )
		return self:GetVector("acceleration", {...})
	end

	function phys:GetFriction(  )
		for name,vect in pairs(self.velocities) do
			if vect.friction then return vect.friction end
		end

	end

	-- SETTING FUNCTIONS

	function phys:SetVector( vectType, t )
		local currTable = phys[vectType .. "s"]
		if type(t[1]) == "table" then
			local newTable = {}
			for name,vect in pairs(t[1]) do
				newTable[name] = MyllPhysics:SpecialVector(name, vectType, vect)
			end
			phys[vectType .. "s"] = newTable
			return
		end

		local name = t[1]
		local vect = t[2]
		local keepSpecialProperties = true
		if t[3] == "false" then keepSpecialProperties = false end

		if type(name) ~= "string" then
			-- The user doesn't want to change a specific velocity, but rather the whole velocity of the unit. So, we need
			-- to wipe this table.
			vect = t[1]
			name = DoUniqueString(vectType)
			phys[vectType .. "s"] = {[name] = MyllPhysics:SpecialVector(name, vectType, vect)}
		else
			local oldVect = currTable[name]
			if keepSpecialProperties then vect:SetSpecialProperties(oldVect:GetSpecialProperties()) end
			currTable[name] = acceleration
		end
	end

	function phys:SetVelocity( ... )
		self:SetVector("velocity", {...})
	end

	function phys:SetAcceleration( ... )
		self:SetVector("acceleration", {...})
	end

	function phys:SetFriction( friction )
		for name,vect in pairs(self.velocities) do
			if vect.special_properties.friction then
				vect.special_properties.friction = friction
			end
		end
	end


	--[[function phys:SetFriction( ... )
		local t = {...}
		local overrideAll = false
		local key = t[1]
		local value = t[2]
		if type(key) == "number" then
			--print("phys:SetFriction Error. Must specify name for the friction.")
			overrideAll = true
			value = key
			key = nil
		end
		if overrideAll then
			for name,vect in pairs(self.velocities) do
				if not vect.special_properties.dontChangeFriction then
					vect.special_properties.frictions = {[DoUniqueString("friction")]=value}
				end
			end
		else
			for name,vect in self.velocities do
				if vect.special_properties.frictions[key] then
					vect.special_properties.frictions[key] = value
				end
			end
		end
	end]]



	-- TOGGLES

	function phys:SetContinuePhysicsOnDeath( bool )
		phys.continuePhysicsOnDeath = bool
	end

	function phys:SetClamp( nClamp )
		phys.clamp = nClamp
	end

	-- HELPERS (private functions)

	function phys:GetTotal( vectorTable )
		if not vectorTable then return Vector(0,0,0) end
		local total = Vector(0,0,0)
		for name,vect in pairs(vectorTable) do
			total = total + vect
		end
		return total
	end

	function phys:Reset(  )
		phys.velocities = {}
		phys.accelerations = {}
		--self:SetVelocity(Vector(0,0,0))
		--self:SetAcceleration(Vector(0,0,0))
		self:SetFriction(.05)
	end

	-- THINKERS

	function phys:OnFrame( func )
		phys.onFrame = func
	end

	function phys:Think(  )
		if not phys.simulationOn and not phys.reset then
			self:Reset()
			phys.reset = true
		elseif phys.simulationOn and phys.reset then
			phys.reset = false
			return
		end

		if not unit:IsAlive() and not phys.continuePhysicsOnDeath then
			phys.simulationOn = false
			return
		end
		-- actual stuff starts here.
		local currTime = GameRules:GetGameTime()
		local deltaT = currTime-phys.timeSinceLastUpdate
		local currPos = unit:GetAbsOrigin()
		phys.timeSinceLastUpdate = currTime

		local currTotalAcceleration = self:GetTotal(self.accelerations)
		local newTotalVelocity = Vector(0,0,0)
		for name,vect in pairs(self.velocities) do
			-- alter the velocities from the acceleration
			local thisVel = vect:ChangeValue(vect + currTotalAcceleration*deltaT)
			-- alter the velocities from the friction
			--print("friction: " .. self:GetTotalFriction())
			local friction = vect.special_properties.friction
			if friction then
				thisVel = thisVel:ChangeValue(thisVel - thisVel*friction)
			end

			self.velocities[name] = thisVel
			newTotalVelocity = newTotalVelocity + thisVel
		end
		if Length3DSq(newTotalVelocity) > phys.clamp*phys.clamp then
			local newPos = currPos + newTotalVelocity*deltaT
			if newPos.z > ABOVE_GROUND_THRESHOLD then
				--[[if not unit:HasModifier("") then

				end]]
			end

			--print("new vel: " .. VectorString(newTotalVelocity))
			unit:SetAbsOrigin(newPos)
		end

		if phys.onFrame then
			phys.onFrame()
		end
	end

	phys:Reset()
	phys.timeSinceLastUpdate = 0
	phys.simulationOn = true
	phys.continuePhysicsOnDeath = false
	phys.clamp = 40

	phys.timer = Timers:CreateTimer(.03, function()
		--if phys.simulationOn then
		phys:Think()
		--end
		return .01
	end)
	return phys
end

function MyllPhysics:SpecialVector( name, vectType, vect )
	print("type of vect: " .. tostring(type(vect)))
	DeepPrintTable(vect)
	vect.special_properties = 
	{
		["name"] = name,
		["type"] = vectType,
	}
	local sp = vect.special_properties

	if vectType == "velocity" then
		sp.friction = DEFAULT_GROUND_FRICTION
		--[[sp.frictions = 
		{
			["ground"] = DEFAULT_GROUND_FRICTION,
			["air"] = DEFAULT_AIR_FRICTION,
		}]]
	end

	function vect:SetFriction(friction)
		self.special_properties.friction = friction
	end

	--[[function vect:SetFriction(...)
		local t = {...}
		local key = t[1]
		local value = t[2]
		local frictions = sp.frictions
		if type(key) == "number" then
			value = t[1]
			key = nil
			frictions = {[DoUniqueString("friction")]=value}
		else
			frictions[key] = value
		end
	end]]

	function vect:GetFriction(  )
		return self.special_properties.friction
	end

	--[[function vect:GetFriction(...)
		local t = {...}
		if not t then
			local totalFriction = 0
			for name,friction in pairs(sp.frictions) do
				totalFriction = totalFriction + friction
			end
			return totalFriction
		else
			local name = t[1]
			if type(name) == "string" then
				return sp.frictions[name]
			end
		end
	end]]

	if vectType == "velocity" then
		print("added velocity vect.")
	elseif vectType == "acceleration" then
		print("added acceleration vect.")
	end

	function vect:ChangeValue( newVector )
		local newSpecialVect = MyllPhysics:SpecialVector( sp.name, sp.type, newVector )
		newSpecialVect.special_properties = sp
		return newSpecialVect

	end

	function vect:SetSpecialProperties( specialProperties )
		vect.special_properties = specialProperties
	end
	function vect:GetSpecialProperties(  )
		return vect.special_properties
	end

	return vect
end

--[[function MyllPhysics:SetFriction( frict )
	-- body
end]]