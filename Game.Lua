-- Services
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverStorage = game:GetService("ServerStorage")

local status = replicatedStorage.Values.Status

local timer = replicatedStorage.Values.Timer

local playersLeft = replicatedStorage.Values.PlayerLeft

local hitbox = serverStorage:WaitForChild("Hitbox")
-- Config
local playersToStart = 2

local contestants = {} --[]

-- Functions

local function chooseSeeker(availablePlayers)
	math.randomseed(tick())
	return availablePlayers[math.random(1,#availablePlayers)]
end

local function teleportPlayers(availablePlayers,spawns) -- availablePlayers: Table / spawns: Table
	for _, plr in pairs(availablePlayers) do
		if plr.Character then
			
			local tag = Instance.new("BoolValue")
			tag.Name = "Playing"
			tag.Parent = plr
					
			--if plr.Name == "XxxcodedudexxX" then
				--plr.Character.Humanoid.WalkSpeed = 100
			--else
				--plr.Character.Humanoid.WalkSpeed = 16
			--end
			
			if plr.Character:FindFirstChild("HumanoidRootPart") then
				plr.Character.HumanoidRootPart.CFrame = spawns[math.random(1,#spawns)].CFrame + Vector3.new(0,5,0)
			end
		end
	end
end

local function toMS(s)
	return ("%02i:%02i"):format(s/60%60, s%60)
end

local function beamMeUp(seeker)
	if seeker then
		local seekerChar = seeker.Character

		if seekerChar:FindFirstChild("HumanoidRootPart") then
			
			local attachment = Instance.new("Attachment")
			attachment.Parent = seekerChar.HumanoidRootPart
			
			for i, contestant in pairs(contestants) do
				
				local contestantChar = contestant.Character
				local beam = game.ServerStorage.Beam:Clone()
				beam.Parent = seekerChar.HumanoidRootPart
				beam.Attachment0 = attachment
				local attachment2 = Instance.new("Attachment")
				
				if contestantChar:FindFirstChild("HumanoidRootPart") then
					attachment2.Parent = contestantChar.HumanoidRootPart
					beam.Attachment1 = attachment2
				end
				
			end
		end	
	end
end
		
local function addHitbox(player)

	if player then
		if player.Character then
			local character = player.Character
			local hitboxClone = hitbox:Clone()
			hitboxClone.CFrame = character.HumanoidRootPart.CFrame
			local weld = Instance.new("Weld")
			weld.Part0 = hitboxClone
			weld.Part1 = character.HumanoidRootPart
			weld.Parent = hitboxClone
			hitboxClone.Parent = character
			print("hitbox added for "..player.Name)
			
			local itGUI = game.ServerStorage.ItGui:Clone()
			itGUI.Parent = player.Character.Head
			
			local seekerTag = Instance.new("BoolValue")
			seekerTag.Name = "Seeker"
			seekerTag.Parent = player
			
			return hitboxClone
		end
	end
end

local function removeHitBox(player)
	if player.Character then
		if player.Character:FindFirstChild("Hitbox") then
			player.Character.Hitbox:Destroy()
		end
		if player.Character.Head:FindFirstChild("ItGui") then
			player.Character.Head.ItGui:Destroy()
		end
		
		if player:FindFirstChild("Seeker") then
			player.Seeker:Destroy()
		end
	end
end

local function isContestant(plr)
	for _, contestant in pairs(contestants) do
		if contestant == plr then
			return true
		end
	end

	return false
end

local function isSeeker(plr)
	if plr:FindFirstChild("Seeker") then
		return true
	end

	return false
end

local function kickOutContestant(plr)
	for i, contestant in pairs(contestants) do
		if contestant == plr then
			table.remove(contestants,i)

			--warn("Booted "..contestant.Name" from the game")
		end
	end
end


game.Players.PlayerRemoving:Connect(function(player)
	if isContestant(player) then
		kickOutContestant(player)
	end
	
	if isSeeker(player) then
		-- kick the seeker out
	end
	
end)

local Weights = {}

function getSeekerFromChanceTable()
	
	local currentList = {}
	
	local selected = nil
	local selectedIndex = nil
	local TotalWeight = 0 
	
	for i, player in pairs(contestants) do
		if Weights[i] then
			if Weights[i] >= 98 then
				Weights[i] = Weights[i] + 0.005
			else
				Weights[i] = Weights[i] + 5
			end
		else
			Weights[i] = 5
		end
		table.insert(currentList,player.Name.." - "..tostring(Weights[i]))
		game.ReplicatedStorage.ShowPercentChance:FireClient(player,Weights[i])
		TotalWeight = TotalWeight + Weights[i]
	end
	

	
	local chosen = Random.new():NextInteger(1,TotalWeight) -- random number
	
	for i = 1, TotalWeight do
		chosen = chosen - Weights[i]
		if chosen <= 0 then
			selectedIndex = i
			selected = contestants[i]
			Weights[selectedIndex] = 0
			if currentList[selectedIndex] then
				currentList[selectedIndex] = selected.Name.." - 0"
			end
			break
		end
	end
	
	game.ReplicatedStorage.SendData:FireAllClients(currentList)
	if selected then
		return selected
	end
	
end

while wait(1) do

	contestants = {}

	repeat

		print("Not enough players in-game")
		status.Value = playersToStart.." players needed to start ("..#game.Players:GetPlayers().."/"..playersToStart..")"

		wait(2)

	until #game.Players:GetPlayers() >= playersToStart --  and game.Players:FindFirstChild("XxxcodedudexxX")

	for i = 10,0,-1 do
		status.Value = "Next round starts in "..i.." seconds"
		wait(1)
	end

	contestants = game.Players:GetPlayers()

	local seeker = getSeekerFromChanceTable()
	
	--game.Players:WaitForChild("XxxcodedudexxX")

	status.Value = "The chosen seeker is..."
	wait(2)
	status.Value = seeker.Name.."!"

	wait(0.5)

	local map = game.Workspace.TempMap
	
	kickOutContestant(seeker)
	
	teleportPlayers(contestants,map.Spawns:GetChildren())
	
	math.randomseed(tick())
	
	local hitbox = addHitbox(seeker)
	-- disconnect me
	seekerHitboxConnection = hitbox.Touched:Connect(function(hit)
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			if isContestant(player) then
				print("Real contestant")
				kickOutContestant(player)
				player:LoadCharacter()
				if player:FindFirstChild("Playing") then
					player:FindFirstChild("Playing"):Destroy()
				end
				print("Kicked")
			end
		end
	end)
	
	status.Value = "Get ready to hide!"
	
	wait(1)
	
	for i = 35,0,-1 do
		status.Value = "Go Hide "..i
		timer.Value = toMS(i)
		playersLeft.Value = #contestants -- .."/"..maxPlayers
		wait(0.14)
	end
	
	teleportPlayers({seeker},map.SeekerSpawns:GetChildren())
	
	status.Value = "The Seeker Has Been Released!"
	
	if seeker.Character then
		seeker.Character.Humanoid.WalkSpeed = 30
	end
	
	wait(2)
	
	local outcome = nil
	
	for i = 60,0,-1 do
		status.Value = "Game In Pogress"
		timer.Value = toMS(i)
		playersLeft.Value = #contestants -- .."/"..maxPlayers
		
		if #contestants == 0 then
			outcome = "SeekerWon"
			break 
		end
		
		if seeker == nil then
			print("Seeker left!")
			outcome = "SeekerLeft"
			break
		end
		
		wait(1)
	end
	
	if outcome == "SeekerWon" then
		status.Value = "The Seeker Wins"
		if seeker.leaderstats then
			seeker.leaderstats.Cash.Value = seeker.leaderstats.Cash.Value + 30
		end
	elseif outcome == "SeekerLeft" then
		
		status.Value = "Seeker left so Contestants win"
		for _, contestant in pairs(contestants) do
			if contestant.leaderstats then
				contestant.leaderstats.Cash.Value = contestant.leaderstats.Cash.Value + 5
			end
		end
	else
		status.Value = "Time Up! Contestants Win!"
		for _, contestant in pairs(contestants) do
			if contestant.leaderstats then
				contestant.leaderstats.Cash.Value = contestant.leaderstats.Cash.Value + 5
			end
		end
	end
	
	removeHitBox(seeker)
	
	
	for _, plr in pairs(game.Players:GetPlayers()) do
		if plr:FindFirstChild("Playing") or plr:FindFirstChild("Seeker") then
			if plr.Character:FindFirstChild("HumanoidRootPart") then
				plr.Character.HumanoidRootPart.CFrame = game.Workspace.Lobby.SpawnLocations:GetChildren()[math.random(1, #game.Workspace.Lobby.SpawnLocations:GetChildren())].CFrame + Vector3.new(0,5,0)
			end
		end
	end
	
	wait(1)
	
	status.Value = "End of Round"
	
	if seekerHitboxConnection then seekerHitboxConnection:Disconnect()  print("Successfully disconnected") end
	
end
