AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props/cs_office/Fire_Extinguisher.mdl")
	
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	if (SERVER) then self:PhysicsInit(SOLID_VPHYSICS) end

	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then phys:Wake() end

	self.Picked = false
	self.Whoosh = CreateSound(self, "ambient/gas/steam2.wav")
	
	self.Smoke = ents.Create("env_smokestack")
	self.Smoke:SetKeyValue("InitialState", "1")
	self.Smoke:SetKeyValue("WindAngle", "0 0 0")
	self.Smoke:SetKeyValue("WindSpeed", "0")
	self.Smoke:SetKeyValue("rendercolor", "255 255 255")
	self.Smoke:SetKeyValue("renderamt", "255")
	self.Smoke:SetKeyValue("SmokeMaterial", "particle/smokesprites_0001")
	self.Smoke:SetKeyValue("BaseSpread", "0")
	self.Smoke:SetKeyValue("SpreadSpeed", "30")
	self.Smoke:SetKeyValue("Speed", "256")
	self.Smoke:SetKeyValue("StartSize", "0")
	self.Smoke:SetKeyValue("EndSize", "25")
	self.Smoke:SetKeyValue("roll", "0")
	self.Smoke:SetKeyValue("Rate", "64")
	self.Smoke:SetKeyValue("JetLength", "75")
	self.Smoke:SetKeyValue("twist", "0")
	
	if !self.Smoke || !self.Smoke:IsValid() then return false end
	self.Smoke:Spawn()
	self.Smoke:Activate()
	self.Smoke:SetPos(self:LocalToWorld(Vector(3,0,23)))
	self.Smoke:SetAngles(self:LocalToWorldAngles(Angle(90,-90,0)))
	timer.Simple(0.1,function() self.Smoke:SetParent(self) end)
	self.Smoke:Fire("TurnOff")
end

function ENT:Think()
	if self:IsPlayerHolding() then
		self.Whoosh:Play()
		self.Smoke:Fire("TurnOn")
	
		local ents = ents.FindInCone(self:LocalToWorld(Vector(0,0,10)), Vector(0,1,0),75,0)
		for i=1,table.Count(ents) do
			ents[i]:Extinguish()
		end
	else
		self.Whoosh:Stop()
		self.Smoke:Fire("TurnOff")
	end
end

function ENT:OnRemove()
	self.Whoosh:Stop()
end