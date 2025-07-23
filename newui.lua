--!strict
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

if not WindUI then return end

local Window = WindUI:CreateWindow({
    Title = "Knight Hub",
    Icon = "rbxassetid://129260712070622",
    Author = "Grow A Garden",
    Folder = "KnightHub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    Transparent = true,
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = true,
    },
})

local Tabs = {}
Tabs.FarmSection = Window:Section({ Title = "Farm" })
Tabs.Farm = Tabs.FarmSection:Tab({ Title = "Garden", Icon = "leaf" })

-- Show Pet/Gear UI
pcall(function()
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("Teleport_UI")
    gui.Frame.Pets.Visible = true
    gui.Frame.Gear.Visible = true
end)

-- Utility functions
local function findMyGarden()
	local playerName = player.Name
	local farms = Workspace:WaitForChild("Farm"):GetChildren()

	for _, farm in ipairs(farms) do
		local sign = farm:FindFirstChild("Sign")
		local important = farm:FindFirstChild("Important")

		if sign and important then
			local corePart = sign:FindFirstChild("Core_Part")
			local surfaceGui = corePart and corePart:FindFirstChild("SurfaceGui")
			local textLabel = surfaceGui and surfaceGui:FindFirstChild("TextLabel")

			if textLabel and textLabel:IsA("TextLabel") and textLabel.Text == playerName .. "'s Garden" then
				local plantLocations = important:FindFirstChild("Plant_Locations")
				if plantLocations then
					local canPlants = {}
					for _, child in ipairs(plantLocations:GetChildren()) do
						if child.Name == "Can_Plant" then
							table.insert(canPlants, child)
						end
					end
					if #canPlants > 0 then
						return {
							FarmModel = farm,
							Important = important,
							PlantLocations = plantLocations,
							CanPlants = canPlants,
							GardenName = textLabel.Text
						}
					end
				end
			end
		end
	end
	return nil
end

local function teleportToNearestCanPlant()
	local garden = findMyGarden()
	if not garden then return end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local closest, dist = nil, math.huge
	for _, canPlant in ipairs(garden.CanPlants) do
		local d = (hrp.Position - canPlant.Position).Magnitude
		if d < dist then
			dist = d
			closest = canPlant
		end
	end
	if closest then
		hrp.CFrame = closest.CFrame + Vector3.new(0, 3, 0)
	end
end

-- Auto Collect
local collecting = false
local taskConnection = nil
local promptRange = 28

local function getHumanoidRootPart()
    local character = player.Character or player.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart")
end

local function isPromptValid(prompt)
	if not prompt:IsA("ProximityPrompt") then return false end
	if prompt.KeyboardKeyCode ~= Enum.KeyCode.E then return false end
	local hrp = getHumanoidRootPart()
	if not hrp then return false end
	local part = prompt.Parent
	if part:IsA("BasePart") then
		return (hrp.Position - part.Position).Magnitude <= promptRange
	elseif part:IsA("Model") and part.PrimaryPart then
		return (hrp.Position - part.PrimaryPart.Position).Magnitude <= promptRange
	end
	return false
end

Tabs.Farm:Toggle({
    Title = "Auto Collect Plant",
    Value = false,
    Callback = function(state)
        collecting = state
        if state then
            teleportToNearestCanPlant()
            taskConnection = task.spawn(function()
                local garden = findMyGarden()
                if not garden then warn("❌ Không tìm thấy garden của bạn.") return end
                local myPlants = garden.Important:WaitForChild("Plants_Physical")

                while collecting do
                    local hrp = getHumanoidRootPart()
                    if not hrp then task.wait(0.5) continue end
                    for _, descendant in ipairs(myPlants:GetDescendants()) do
                        if isPromptValid(descendant) then
                            task.spawn(function()
                                descendant:InputHoldBegin()
                                task.wait(descendant.HoldDuration)
                                descendant:InputHoldEnd()
                            end)
                        end
                    end
                    task.wait(0.05)
                end
            end)
        else
            if taskConnection then task.cancel(taskConnection) taskConnection = nil end
        end
    end
})
