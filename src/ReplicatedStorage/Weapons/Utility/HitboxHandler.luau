local HitboxHandler = {}

function HitboxHandler.DetectHit(Size:Vector3,CF:CFrame,BlackList:SharedTable)
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = BlackList
	
	local HitTable = {}
	local Hit = workspace:GetPartBoundsInBox(CF,Size,Params)
	
	for _,Inst in pairs(Hit) do
		if Inst.Parent:FindFirstChild("Humanoid") then
			local Target = Inst.Parent.Humanoid
			if table.find(HitTable,Target) then continue end
			table.insert(HitTable,Target)
		end
	end
	
	return HitTable
end

return HitboxHandler
