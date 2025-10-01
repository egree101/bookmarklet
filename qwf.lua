--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- Client-sided player teleportation script with no collision and activation notification
-- Places players in front of your character at regular intervals without collision

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local TELEPORT_DISTANCE = 4  -- Distance in front of your character
local TELEPORT_INTERVAL = 0.5  -- Time between teleports in seconds
local INCLUDE_SELF = false   -- Set to true if you want to teleport yourself too

-- Create the notification GUI
local function createNotification()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportScriptNotification"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.5, 0, 0.2, 0)
    frame.Position = UDim2.new(0.25, 0, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.3
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.1, 0)
    corner.Parent = frame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(0.9, 0, 0.9, 0)
    textLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "The teleport script has been activated!\nTo deactivate it you will have to relog unfortunately."
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = frame

    -- Close after 5 seconds
    delay(5, function()
        screenGui:Destroy()
    end)
end

-- Store original collision states
local originalCollisionStates = {}

local function setPlayerCollision(player, enable)
    if not player.Character then return end
    
    -- Save original state if we haven't already
    if not originalCollisionStates[player] then
        originalCollisionStates[player] = {}
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCollisionStates[player][part] = part.CanCollide
            end
        end
    end
    
    -- Apply new collision state
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = enable and (originalCollisionStates[player][part] or false)
        end
    end
end

local function teleportPlayers()
    -- Get all players except yourself (unless INCLUDE_SELF is true)
    local playersToTeleport = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == rth080 then
            table.insert(playersToTeleport, player)
        end
    end
    print(playersToTeleport)
    
    -- Get your current position and orientation
    local myPosition = humanoidRootPart.Position
    local myLookVector = humanoidRootPart.CFrame.LookVector
    
    -- Calculate the teleport position in front of you
    local teleportPosition = myPosition + (myLookVector * TELEPORT_DISTANCE)
    teleportPosition = Vector3.new(teleportPosition.X, myPosition.Y, teleportPosition.Z)
    
    -- Teleport each player
    for _, player in ipairs(playersToTeleport) do
        if player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                -- Disable collision before teleporting
                setPlayerCollision(player, false)
                
                -- Create a CFrame that faces the same direction as you
                local targetCFrame = CFrame.new(teleportPosition, teleportPosition + myLookVector)
                
                -- Teleport the player
                targetHRP.CFrame = targetCFrame
                
                -- Optional: Add a small effect to make it noticeable
                local effect = Instance.new("Part")
                effect.Size = Vector3.new(1, 1, 1)
                effect.Position = teleportPosition
                effect.Anchored = true
                effect.CanCollide = false
                effect.Transparency = 0.5
                effect.BrickColor = BrickColor.new("Bright blue")
                effect.Parent = workspace
                game:GetService("Debris"):AddItem(effect, 0.5)
            end
        end
    end
end

-- Show the notification when the script starts
createNotification()

-- Set up the loop
local teleportLoop
local function startLoop()
    if teleportLoop then teleportLoop:Disconnect() end
    
    teleportLoop = RunService.Heartbeat:Connect(function()
        -- Only run at the specified interval
        if tick() % TELEPORT_INTERVAL < 0.1 then
            teleportPlayers()
        end
    end)
end

-- Handle character respawns
localPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    startLoop()
end)

-- Clean up collision states when players leave
Players.PlayerRemoving:Connect(function(player)
    originalCollisionStates[player] = nil
end)

-- Initial start
startLoop()
