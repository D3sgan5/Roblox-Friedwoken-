local Random = Random.new()
local PlaySound = {}

function PlaySound.PlaySound(Sound:Sound,Inst:Instance,Speed:number)
	local Clone = Sound:Clone()
	Clone.Parent = Inst
	
	if Speed then
		Clone.PlaybackSpeed = Speed
	else
		Clone.PlaybackSpeed = Random:NextNumber(0.95,1)
	end
	
	Clone:Play()
	Clone.Ended:Once(function()
		Clone:Destroy()
	end)
end

return PlaySound
