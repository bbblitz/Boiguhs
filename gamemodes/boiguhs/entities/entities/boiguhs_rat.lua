AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= false

function ENT:Initialize()
	self:SetModel("models/rat.mdl")
	self:SetHealth(99999)
	self:SetCollisionGroup(20)
	self:DrawShadow(false)
	
	self.Searching = true
	self.Leaving   = false
	self.IsDead	   = false
	self.Ent	   = nil
	self.Hostile   = false
	
	self.Entity:SetCollisionBounds(Vector(-10,-10,-10), Vector(10,10,10))

	util.PrecacheSound("vo/ravenholm/madlaugh01.wav")	
	util.PrecacheSound("vo/ravenholm/madlaugh02.wav")	
	util.PrecacheSound("vo/ravenholm/madlaugh03.wav")	
	util.PrecacheSound("vo/ravenholm/madlaugh04.wav")
	util.PrecacheSound("vo/ravenholm/monk_pain09.wav")
	util.PrecacheSound("vo/ravenholm/monk_pain10.wav")	
	
	self.Bite = CreateSound(self,"NPC_HeadCrab.Bite")
end

function ENT:Think()
	if(IsValid(self.Ent)) then
		self.Ent:SetPos(self:LocalToWorld(Vector(0,0,45)))
	end
end

function ENT:OnContact(ent)
	if(ent:GetClass() == "boiguhs_grill") then
		self:Ignite(20)
	end
end

-- AI stuff

function ENT:SetEnemy( ent )
	self.Enemy = ent
end
function ENT:GetEnemy()
	return self.Enemy
end


function ENT:RunBehaviour()	
	while (true) do
		if(self.Searching) then
			self:FindFood(1)
		elseif(self.Leaving) then
			self:StartActivity(ACT_WALK)
			self.loco:SetDesiredSpeed(250)
			self.loco:FaceTowards(Vector(0,0,0))
			self:MoveToPos(Vector(0,0,0))
			self:Remove()
			if(IsValid(self.Ent)) then self.Ent:Remove() end
		elseif(self.Hostile) then
			self:SetEnemy(table.Random(ents.FindByClass("player")))
			self.loco:FaceTowards(self:GetEnemy():GetPos())	-- Face our enemy
			self:StartActivity( ACT_WALK )			-- Set the animation
			self.loco:SetDesiredSpeed( 250 )		-- Set the speed that we will be moving at. Don't worry, the animation will speed up/slow down to match
			self:ChaseEnemy() 						-- The new function like MoveToPos that will be looked at soon.
			self:StartActivity( ACT_IDLE )
		end
		
		coroutine.yield()
	end
end

function ENT:FindFood(num)
	local tbl = ents.FindByClass("boiguh_*")
	local _food  = tbl[num]

	if (num == (table.Count(tbl)+1)) then self.Searching = false self.Hostile = true return end --self.Searching = false self.Leaving = true return end
	
	if(IsValid(_food)) then
		if(math.abs(_food:GetPos().z - self:GetPos().z) > 15) then return self:FindFood(num + 1) end
		local food = _food
		if IsValid(_food:GetParent()) then food = _food:GetParent() end
		if(food.Claimed) then return self:FindFood(num+1) end 
		food.Claimed	 = true
		self.Searching   = false
		self.loco:FaceTowards(food:GetPos())
		self:StartActivity(ACT_WALK)
		self.loco:SetDesiredSpeed(200)
		self:MoveToPos(food:GetPos())
		self:StartActivity(ACT_IDLE)
		if(math.abs(_food:GetPos().z - self:GetPos().z) > 15) then food.Claimed = false return self:FindFood(num + 1) end
		if(self:GetPos():Distance(_food:GetPos()) > 20) then food.Claimed = false return self:FindFood(num) end
		self.Ent	 = food
		if self.Ent:IsOnFire() then self:Ignite(60) end
		self.Leaving = true
		self:EmitSound("vo/ravenholm/madlaugh0"..math.random(1,4)..".wav",75,130)
	end 
end

function ENT:ChaseEnemy( options )

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, self:GetEnemy():GetPos() )		-- Compute the path towards the enemies position

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and IsValid(self:GetEnemy()) ) do

		if ( path:GetAge() > 0.1 ) then					-- Since we are following the player we have to constantly remake the path
			path:Compute( self, self:GetEnemy():GetPos() )-- Compute the path towards the enemy's position again
		end
		path:Update( self )								-- This function moves the bot along the path

		if ( options.draw ) then path:Draw() end
		-- If we're stuck, then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end
		
		if(IsValid(self:GetEnemy()) and self:GetPos():Distance(self:GetEnemy():GetPos()) < 30) then
			self:GetEnemy():ViewPunch( Angle( -10, 0, 0 ) )		
			self:GetEnemy():TakeDamage(1,self,self) 
			self.Bite:Play()
		else
			self.Bite:Stop()
		end
		
		coroutine.yield()

	end
	return "ok"
end

function ENT:OnInjured(dmg)
	if dmg:GetDamageType() == 268435464 then return false end 
	self:EmitSound("vo/ravenholm/monk_pain09.wav",80,130)
	if(IsValid(self.Ent)) then 
		self.Ent.Claimed = false
		self.Ent:GetPhysicsObject():Wake()	
	end
	self:Remove()
end

function ENT:OnRemove()
		if SERVER then
		local body = ents.Create("boiguhs_ratcorpse")
		body:SetPos(self:LocalToWorld(Vector(0,0,5)))
		body:SetAngles(self:GetAngles())
		body:Spawn()
		
		timer.Simple(10, function()
			if(IsValid(body) and body:GetColor().r == 255 and !IsValid(body:GetParent())) then
				body:Remove()
			end		
		end)
	end
end


list.Set( "NPC", "boiguhs_rat", {
	Name = "Boiguhs Rat",
	Class = "boiguhs_rat",
	Category = "Boiguhs"
} )