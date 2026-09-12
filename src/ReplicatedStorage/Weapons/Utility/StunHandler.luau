local RunService = game:GetService("RunService")

local StunnedTable = {}
local StunnedHumanoids

local StunHandler = {}

function StunHandler.StopStun(Target:Humanoid)
	local data = StunnedTable[Target]
	
	data.stunned = nil

	for _,Con in pairs(data.connections) do
		Con:Disconnect()
		Con = nil
	end
	
	data.connections = nil

	Target.WalkSpeed = data.speed
	Target.JumpHeight = data.jump

	if Target.Parent:GetAttribute("State") == "Stunned" then
		Target.Parent:SetAttribute("State",nil)
	end
end

function StunHandler.Stun(Target:Humanoid,Duration:number)
	local State = Target.Parent:GetAttribute("State")
	if Target.Health <= 0 or State == "Ragdoll" or State == "HyperArmor" then return end
	
	if not StunnedTable[Target] then
		StunnedTable[Target] = {}
	end
	
	local data = StunnedTable[Target]
	
	if not data.stunned then
		data.stunned = true
		data.speed = 14
		data.jump = 7.2
		
		Target.WalkSpeed = 6
		Target.JumpHeight = 0
		
		Target.Parent:SetAttribute("State","Stunned")
	end
	
	if not data.connections then
		data.connections = {}
		
		table.insert(data.connections,
			Target:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				Target.WalkSpeed = 6
				Target.JumpHeight = 0
			end)
		)
		
		table.insert(data.connections,
			Target.Parent:GetAttributeChangedSignal("State"):Connect(function()
				local State = Target.Parent:GetAttribute("State")
				if State == "Ragdolled" then
					coroutine.close(data.timer)

					for _,Con in pairs(data.connections) do
						Con:Disconnect()
						Con = nil
					end

					data.stunned = nil
					
					Target.WalkSpeed = data.speed
					Target.JumpHeight = data.jump
				end
			end)
		)
		
		table.insert(data.connections,
			Target.Parent:GetAttributeChangedSignal("Parried"):Connect(function()
				local State = Target.Parent:GetAttribute("Parried")
				if State then
					coroutine.close(data.timer)

					for _,Con in pairs(data.connections) do
						Con:Disconnect()
						Con = nil
					end

					data.stunned = nil

					Target.WalkSpeed = data.speed
					Target.JumpHeight = data.jump
				end
			end)
		)
		
		
		table.insert(data.connections,
			Target.Died:Connect(function()
				coroutine.close(data.timer)
				
				for _,Con in pairs(data.connections) do
					Con:Disconnect()
					Con = nil
				end

				data = nil
			end)
		)
	end
	
	if data.timer then coroutine.close(data.timer) end
	data.timer = coroutine.create(function()
		task.wait(Duration)
		StunHandler.StopStun(Target)
	end)
	
	coroutine.resume(data.timer)
end

return StunHandler
