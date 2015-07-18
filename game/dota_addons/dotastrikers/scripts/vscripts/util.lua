--[[
	ExecuteOrderFromTable({
		UnitIndex = caster:GetEntityIndex(),
		AbilityIndex = caster:FindAbilityByName("queenofpain_blink_datadriven"):GetEntityIndex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION, 
		Position = caster.newPos,
		Queue = true })
]]


--------------------- Dayne's stuff -------------------------
X_MAX = 2575
X_MIN = -1 * X_MAX

BORDER_GOAL_X = 3200
BORDER_GOAL_Y = 225

Y_MAX = 1320
Y_MIN = -1 * Y_MAX

function IsPointOnField(point)
	if (point.y > Y_MIN and point.y < Y_MAX and point.x > X_MIN and point.x < X_MAX) then -- In the playing field
		return true
	elseif (point.y > -BORDER_GOAL_Y and point.y < BORDER_GOAL_Y and point.x > -BORDER_GOAL_X and point.x < BORDER_GOAL_X) then -- In a goal
		return true
	end
	return false -- Out of Field
end


-----------------------------------------------------------------------------

function DummyCastBlink(caster, startPos, endPos )
	local dummy = CreateUnitByName("dummy", startPos, false, nil, nil, caster:GetTeam())
	dummy:AddAbility("queenofpain_blink_datadriven")
	local blinkAbil = dummy:FindAbilityByName("queenofpain_blink_datadriven")
	blinkAbil:SetLevel(1)
	Timers:CreateTimer(.03, function()
		dummy:SetForwardVector((endPos-startPos):Normalized())
		Timers:CreateTimer(.03, function()
			dummy:CastAbilityOnPosition(endPos, blinkAbil, 0)
		end)
	end)

	Timers:CreateTimer(2, function()
		dummy:ForceKill(true)
	end)
end

function MergeTables( tableOfTables )
	local index = 1
	local newTable = {}
	for i,t in ipairs(tableOfTables) do
		if type(t) == "table" then
			for i2,val in ipairs(t) do
				newTable[index] = val
				index = index + 1
			end
		end
	end
	return newTable
end

-- ty noya
function PlayCentaurBloodEffect( unit )
	local centaur_blood_fx = "particles/units/heroes/hero_centaur/centaur_double_edge_bloodspray_src.vpcf"
	local targetLoc = unit:GetAbsOrigin()
	local blood = ParticleManager:CreateParticle(centaur_blood_fx, PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleControl(blood, 0, targetLoc)
	ParticleManager:SetParticleControl(blood, 2, targetLoc+RandomVector(RandomInt(20,100)))
	ParticleManager:SetParticleControl(blood, 4, targetLoc+RandomVector(RandomInt(20,100)))
	ParticleManager:SetParticleControl(blood, 5, targetLoc+RandomVector(RandomInt(20,100)))
end

function CreateNeutralParticle( particle, pos, attach_type, duration )
	local handler = CreateUnitByName("dummy", pos, false, nil, nil, DOTA_TEAM_NEUTRALS)
	local part = ParticleManager:CreateParticle(particle, attach_type, handler)

	Timers:CreateTimer(duration, function()
		handler:ForceKill(true)
	end)

	return part
end

function AddHasteAnimation( unit )
	if not unit:HasModifier("modifier_haste_anim") then
		GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_haste_anim", {})
	end
end

function RemoveHasteAnimation( unit )
	if unit:HasModifier("modifier_haste_anim") then
		unit:RemoveModifierByName("modifier_haste_anim")
	end
end

function AddStun( unit )
	if not unit:HasAbility("stun_passive") then
		unit:AddAbility("stun_passive")
		unit:FindAbilityByName("stun_passive"):SetLevel(1)
	end
end

function RemoveStun( unit )
	if unit:HasAbility("stun_passive") then
		unit:RemoveAbility("stun_passive")
		unit:RemoveModifierByName("modifier_stun_passive")
	end
end

function AddSilence( unit )
	if not unit:HasModifier("modifier_endround_silenced_passive") then
		EndRoundDummy.endround_passive:ApplyDataDrivenModifier(EndRoundDummy, unit, "modifier_endround_silenced_passive", {})
	end
end

function RemoveSilence( unit )
	if unit:HasModifier("modifier_endround_silenced_passive") then
		unit:RemoveModifierByName("modifier_endround_silenced_passive")
	end
end

function AddEndgameRoot( unit )
	if not unit:HasModifier("modifier_endround_rooted_passive") then
		EndRoundDummy.endround_passive:ApplyDataDrivenModifier(EndRoundDummy, unit, "modifier_endround_rooted_passive", {})
	end
end

function RemoveEndgameRoot( unit )
	if unit:HasModifier("modifier_endround_rooted_passive") then
		unit:RemoveModifierByName("modifier_endround_rooted_passive")
	end
end

function AddDisarmed( unit )
	if unit:HasModifier("modifier_disarmed_off") then
		unit:RemoveModifierByName("modifier_disarmed_off")
	end
	GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_disarmed_on", {})
end

function RemoveDisarmed( unit )
	if unit:HasModifier("modifier_disarmed_on") then
		unit:RemoveModifierByName("modifier_disarmed_on")
	end
	GlobalDummy.dummy_passive:ApplyDataDrivenModifier(GlobalDummy, unit, "modifier_disarmed_off", {})
end

function InitAbility( ... )
	local t = {...}
	local sAbilName = t[1]
	local unit = t[2]
	local fun = t[3]
	local remove = t[4]

	unit:AddAbility(sAbilName)
	local abil = unit:FindAbilityByName(sAbilName)
	abil:SetLevel(1)

	if fun then
		Timers:CreateTimer(.03, function()
			fun(abil)
			Timers:CreateTimer(.03, function()
				if remove then
					unit:RemoveAbility(sAbilName)
				end
			end)
		end)
	else
		return abil
	end
end

function GetTeammates( hero )
	local teammates = {}
	for i=0,9 do
		local ply = PlayerResource:GetPlayer(i)
			if ply then
			local hero2 = ply:GetAssignedHero()
			if hero2 and hero2:GetTeam() == hero:GetTeam() and hero2 ~= hero then
				table.insert(teammates, hero2)
			end
		end
	end
	return teammates
end

function EmitSoundAtPosition( ... )
	local t = {...}
	local soundName = t[1]
	local pos = t[2]

	if type(pos) ~= "userdata" and IsValidEntity(pos) then
		pos = pos:GetAbsOrigin()
	end

	local duration = t[3]
	local soundDummy = CreateUnitByName("dummy", pos, false, nil, nil, DOTA_TEAM_GOODGUYS)
	soundDummy:EmitSound(soundName)
	if not duration then
		soundDummy:ForceKill(true)
	else
		Timers:CreateTimer(duration, function()
			soundDummy:StopSound(soundName)
			soundDummy:ForceKill(true)
		end)
	end
end

function ShowQuickMessages( linesTable, durBetweenLines )
	for i,line in ipairs(linesTable) do
		if i == 1 then GameRules:SendCustomMessage(line, 0, 0)
		else
			local delay = (i-1)*durBetweenLines
			Timers:CreateTimer(delay, function()
				GameRules:SendCustomMessage(line, 0, 0)
			end)
		end
	end
end

function ShowErrorMsg( unit, msg )
	if not unit or not unit:GetPlayerOwner() then return end
	if not unit.lastErrorPopupTime or (GameRules:GetGameTime()-unit.lastErrorPopupTime > 1) then
		FireGameEvent( 'custom_error_show', { player_ID = unit:GetPlayerOwner():GetPlayerID(), _error = msg } )
		unit.lastErrorPopupTime = GameRules:GetGameTime()
	end
end

function Length3DSq(v) 
    return v.x * v.x + v.y * v.y + v.z * v.z
end

function VectorDistanceSq(v1, v2) 
    return (v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y)
end

function ReplaceAbility( unit, oldAbil, newAbil )
	unit:RemoveAbility(oldAbil)
	unit:AddAbility(newAbil)
	unit:FindAbilityByName(newAbil):SetLevel(1)
end

function ValidAndAlive( ent )
	return IsValidEntity(ent) and ent:IsAlive()
end

function ShowCenterMsg( msg, dur )
      local msgTable = {
        message = msg,
        duration = dur
      }
      FireGameEvent("show_center_message", msgTable)
end

-- Returns a shallow copy of the passed table.
function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function AbilityIterator(unit, callback)
    for i=0, unit:GetAbilityCount()-1 do
        local abil = unit:GetAbilityByIndex(i)
        if abil ~= nil then
            callback(abil)
        end
    end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function VectorString(v)
  return 'x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z
end

function TableLength( t )
    if t == nil or t == {} then
        return 0
    end
    local len = 0
    for k,v in pairs(t) do
        len = len + 1
    end
    return len
end

-- Remove all abilities on a unit.
function ClearAbilities( unit )
	if not unit or not unit.GetAbilityCount or unit:GetAbilityCount() < 1 then return end
	
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
	-- we have to put in dummies and remove dummies so the ability icon changes.
	-- it's stupid but volvo made us
	for i=1,6 do
		unit:AddAbility("dotastrikers_empty" .. tostring(i))
	end
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
end

-- goes through a unit's abilities and sets the abil's level to 1,
-- spending an ability point if possible.
function InitAbilities( hero )
	for i=0, hero:GetAbilityCount()-1 do
		local abil = hero:GetAbilityByIndex(i)
		if abil ~= nil then
			if hero:IsRealHero() and hero:GetAbilityPoints() > 0 then
				hero:UpgradeAbility(abil)
			else
				abil:SetLevel(1)
			end
		end
	end
end

function GetOppositeTeam( unit )
	if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
		return DOTA_TEAM_BADGUYS
	else
		return DOTA_TEAM_GOODGUYS
	end
end

-- returns true 50% of the time.
function CoinFlip(  )
	return RollPercentage(50)
end

-- theta is in radians.
function RotateVector2D(v,theta)
	local xp = v.x*math.cos(theta)-v.y*math.sin(theta)
	local yp = v.x*math.sin(theta)+v.y*math.cos(theta)
	return Vector(xp,yp,v.z):Normalized()
end

function PrintVector(v)
	print('x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z)
end

-- Given element and list, returns true if element is in the list.
function TableContains( list, element )
	if list == nil then return false end
	for k,v in pairs(list) do
		if k == element then
			return true
		end
	end
	return false
end

-- Given element and list, returns the position of the element in the list.
-- Returns -1 if element was not found, or if list is nil.
function GetIndex(list, element)
	if list == nil then return -1 end
	for i=1,#list do
		if list[i] == element then
			return i
		end
	end
	return -1
end

-- useful with GameRules:SendCustomMessage
function ColorIt( ... )
	local t = {...}
	local sStr = t[1]
	local sColor = t[2]

	if sStr == nil or sColor == nil then
		return
	end

	local real = t[3]
	--Default is cyan.
	local color = "00FFFF"

	-- so basically, i find that some colors don't look that great in dota. so unless real==true, i'm using my own
	-- shades of green, shades of blue, shades of red, etc.
	if real then
		if sColor == "green" then
			color = "008000"
		elseif sColor == "purple" then
			color = "800080"
		elseif sColor == "blue" then
			color = "0000FF"
		elseif sColor == "orange" then
			color = "FFA500"
		elseif sColor == "pink" then
			color = "FFC0CB"
		elseif sColor == "red" then
			color = "FF0000"
		elseif sColor == "cyan" then
			color = "00FFFF"
		elseif sColor == "yellow" then
			color = "FFFF00"
		elseif sColor == "brown" then
			color = "A52A2A"
		elseif sColor == "magenta" then
			color = "FF00FF"
		elseif sColor == "teal" then
			color = "008080"
		elseif sColor == "light_green" then
			color = "90EE90"
		elseif sColor == "sky_blue" then
			color = "87CEEB"
		elseif sColor == "dark_green" then
			color = "006400"
		end
	else
		if sColor == "green" then
			color = "22fd23"
		elseif sColor == "purple" then
			color = "ba10bb"
		elseif sColor == "blue" then
			color = "347dee"
		elseif sColor == "orange" then
			color = "fa771f"
		elseif sColor == "pink" then
			color = "f88dbb"
		elseif sColor == "red" then
			color = "fd0618"
		elseif sColor == "cyan" then
			color = "75fbc6"
		elseif sColor == "yellow" then
			color = "ecf739"
		elseif sColor == "brown" then
			color = "a16f26"
		elseif sColor == "magenta" then
			color = "FF00FF"
		elseif sColor == "teal" then
			color = "008080"
		elseif sColor == "light_green" then
			color = "a0b453"
		elseif sColor == "sky_blue" then
			color = "6edee9"
		elseif sColor == "dark_green" then
			color = "087d2f"
		end
	end

	return "<font color='#" .. color .. "'>" .. sStr .. "</font>"
end

--[[
	p: the raw point (Vector)
	center: center of the square. (Vector)
	length: length of 1 side of square. (Float)
]]
function IsPointWithinSquare(p, center, halfLength)
	if (p.x > center.x-halfLength and p.x < center.x+halfLength) and 
		(p.y > center.y-halfLength and p.y < center.y+halfLength) then
		return true
	end
	return false
end

function IsPointWithinCube(p, center, halfLength)
	return (p.x > center.x-halfLength and p.x < center.x+halfLength) and 
		(p.y > center.y-halfLength and p.y < center.y+halfLength) and
		(p.z > center.z-halfLength and p.z < center.z+halfLength)
end

function circle_circle_collision(p1Origin, p2Origin, p1Radius, p2Radius)
  if ((p1Origin.x - p2Origin.x)*(p1Origin.x - p2Origin.x) + (p1Origin.y - p2Origin.y)*(p1Origin.y - p2Origin.y)) <= (p1Radius+p2Radius)*(p1Radius+p2Radius) then
    return true
  else
    return false
  end
end

--[[
  Continuous collision algorithm for circular 2D bodies, see
  http://www.gvu.gatech.edu/people/official/jarek/graphics/material/collisionFitzgeraldForsthoefel.pdf
  
  body1 and body2 are tables that contain:
  v: velocity (Vector)
  c: center (Vector)
  r: radius (Float)

  Returns the time-till-collision.
]]
function TimeTillCollision(body1,body2)
	local W = body2.v-body1.v
	local D = body2.c-body1.c
	local A = DotProduct(W,W)
	local B = 2*DotProduct(D,W)
	local C = DotProduct(D,D)-(body1.r+body2.r)*(body1.r+body2.r)
	local d = B*B-(4*A*C)
	if d>=0 then
		local t1=(-B-math.sqrt(d))/(2*A)
		if t1<0 then t1=2 end
		local t2=(-B+math.sqrt(d))/(2*A)
		if t2<0 then t2=2 end
		local m = math.min(t1,t2)
		--if ((-0.02<=m) and (m<=1.02)) then
		return m
			--end
	end
	return 2
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function DotProduct(v1,v2)
  return (v1.x*v2.x)+(v1.y*v2.y)
end

function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
		-- Ignore FDesc
		if v ~= 'FDesc' then
			local value = t[v]

			if type(value) == "table" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..":")
				PrintTable (value, indent + 2, done)
			elseif type(value) == "userdata" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
			else
				if t.FDesc and t.FDesc[v] then
					print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
				else
					print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				end
			end
		end
	end
end

-- Used for the Say function.
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'



--============ Copyright (c) Valve Corporation, All rights reserved. ==========
--
--
--=============================================================================

--/////////////////////////////////////////////////////////////////////////////
-- Debug helpers
--
--  Things that are really for during development - you really should never call any of this
--  in final/real/workshop submitted code
--/////////////////////////////////////////////////////////////////////////////

-- if you want a table printed to console formatted like a table (dont we already have this somewhere?)
scripthelp_LogDeepPrintTable = "Print out a table (and subtables) to the console"
logFile = "log/log.txt"

function LogDeepSetLogFile( file )
	logFile = file
end

function LogEndLine ( line )
	AppendToLogFile(logFile, line .. "\n")
end

function _LogDeepPrintMetaTable( debugMetaTable, prefix )
	_LogDeepPrintTable( debugMetaTable, prefix, false, false )
	if getmetatable( debugMetaTable ) ~= nil and getmetatable( debugMetaTable ).__index ~= nil then
		_LogDeepPrintMetaTable( getmetatable( debugMetaTable ).__index, prefix )
	end
end

function _LogDeepPrintTable(debugInstance, prefix, isOuterScope, chaseMetaTables )
	prefix = prefix or ""
	local string_accum = ""
	if debugInstance == nil then
		LogEndLine( prefix .. "<nil>" )
		return
	end
	local terminatescope = false
	local oldPrefix = ""
	if isOuterScope then  -- special case for outer call - so we dont end up iterating strings, basically
		if type(debugInstance) == "table" then
			LogEndLine( prefix .. "{" )
			oldPrefix = prefix
			prefix = prefix .. "   "
			terminatescope = true
	else
		LogEndLine( prefix .. " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance))
	end
	end
	local debugOver = debugInstance

	-- First deal with metatables
	if chaseMetaTables == true then
		if getmetatable( debugOver ) ~= nil and getmetatable( debugOver ).__index ~= nil then
			local thisMetaTable = getmetatable( debugOver ).__index
			if vlua.find(_LogDeepprint_alreadyseen, thisMetaTable ) ~= nil then
				LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, "metatable", tostring( thisMetaTable ) ) )
			else
				LogEndLine(prefix .. "metatable = " .. tostring( thisMetaTable ) )
				LogEndLine(prefix .. "{")
				table.insert( _LogDeepprint_alreadyseen, thisMetaTable )
				_LogDeepPrintMetaTable( thisMetaTable, prefix .. "   ", false )
				LogEndLine(prefix .. "}")
			end
		end
	end

	-- Now deal with the elements themselves
	-- debugOver sometimes a string??
	for idx, data_value in pairs(debugOver) do
		if type(data_value) == "table" then
			if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then
				LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, idx, tostring( data_value ) ) )
			else
				local is_array = #data_value > 0
				local test = 1
				for idx2, val2 in pairs(data_value) do
					if type( idx2 ) ~= "number" or idx2 ~= test then
						is_array = false
						break
					end
					test = test + 1
				end
				local valtype = type(data_value)
				if is_array == true then
					valtype = "array table"
				end
				LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), valtype ) )
				LogEndLine(prefix .. (is_array and "[" or "{"))
				table.insert(_LogDeepprint_alreadyseen, data_value)
				_LogDeepPrintTable(data_value, prefix .. "   ", false, true)
				LogEndLine(prefix .. (is_array and "]" or "}"))
			end
		elseif type(data_value) == "string" then
			LogEndLine( string.format( "%s%-32s\t= \"%s\" (%s)", prefix, idx, data_value, type(data_value) ) )
		else
			LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), type(data_value) ) )
		end
	end
	if terminatescope == true then
		LogEndLine( oldPrefix .. "}" )
	end
end


function LogDeepPrintTable( debugInstance, prefix, isPublicScriptScope )
	prefix = prefix or ""
	_LogDeepprint_alreadyseen = {}
	table.insert(_LogDeepprint_alreadyseen, debugInstance)
	_LogDeepPrintTable(debugInstance, prefix, true, isPublicScriptScope )
end


--/////////////////////////////////////////////////////////////////////////////
-- Fancy new LogDeepPrint - handles instances, and avoids cycles
--
--/////////////////////////////////////////////////////////////////////////////

-- @todo: this is hideous, there must be a "right way" to do this, im dumb!
-- outside the recursion table of seen recurses so we dont cycle into our components that refer back to ourselves
_LogDeepprint_alreadyseen = {}


-- the inner recursion for the LogDeep print
function _LogDeepToString(debugInstance, prefix)
	local string_accum = ""
	if debugInstance == nil then
		return "LogDeep Print of NULL" .. "\n"
	end
	if prefix == "" then  -- special case for outer call - so we dont end up iterating strings, basically
		if type(debugInstance) == "table" or type(debugInstance) == "table" or type(debugInstance) == "UNKNOWN" or type(debugInstance) == "table" then
			string_accum = string_accum .. (type(debugInstance) == "table" and "[" or "{") .. "\n"
			prefix = "   "
	else
		return " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance) .. "\n"
	end
	end
	local debugOver = type(debugInstance) == "UNKNOWN" and getclass(debugInstance) or debugInstance
	for idx, val in pairs(debugOver) do
		local data_value = debugInstance[idx]
		if type(data_value) == "table" or type(data_value) == "table" or type(data_value) == "UNKNOWN" or type(data_value) == "table" then
			if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then
				string_accum = string_accum .. prefix .. idx .. " ALREADY SEEN " .. "\n"
			else
				local is_array = type(data_value) == "table"
				string_accum = string_accum .. prefix .. idx .. " = ( " .. type(data_value) .. " )" .. "\n"
				string_accum = string_accum .. prefix .. (is_array and "[" or "{") .. "\n"
				table.insert(_LogDeepprint_alreadyseen, data_value)
				string_accum = string_accum .. _LogDeepToString(data_value, prefix .. "   ")
				string_accum = string_accum .. prefix .. (is_array and "]" or "}") .. "\n"
			end
		else
			--string_accum = string_accum .. prefix .. idx .. "\t= " .. (type(data_value) == "string" and ("\"" .. data_value .. "\"") or data_value) .. "\n"
			string_accum = string_accum .. prefix .. idx .. "\t= " .. "\"" .. tostring(data_value) .. "\"" .. "\n"
		end
	end
	if prefix == "   " then
		string_accum = string_accum .. (type(debugInstance) == "table" and "]" or "}") .. "\n" -- hack for "proving" at end - this is DUMB!
	end
	return string_accum
end


scripthelp_LogDeepString = "Convert a class/array/instance/table to a string"

function LogDeepToString(debugInstance, prefix)
	prefix = prefix or ""
	_LogDeepprint_alreadyseen = {}
	table.insert(_LogDeepprint_alreadyseen, debugInstance)
	return _LogDeepToString(debugInstance, prefix)
end


scripthelp_LogDeepPrint = "Print out a class/array/instance/table to the console"

function LogDeepPrint(debugInstance, prefix)
	prefix = prefix or ""
	LogEndLine(LogDeepToString(debugInstance, prefix))
end
