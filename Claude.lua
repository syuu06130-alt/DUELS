-- ■■■ Arsenal Game Script with Rayfield UI ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========================================
-- Variables
-- ========================================
local Settings = {
    AutoVote = false,
    SelectedMap = nil,
    AutoFire = false,
    InfiniteAmmo = false,
    NoRecoil = false,
    ESP = false,
    Aimbot = false,
    AimbotFOV = 100,
    TeamCheck = true,
    SilentAim = false
}

local Connections = {}

-- ========================================
-- Utility Functions
-- ========================================
local function FindRunningGame(player)
    for _, v in pairs(workspace:WaitForChild("RunningGames"):GetChildren()) do
        if v.Name:match(tostring(player.UserId)) then
            return v
        end
    end
    return nil
end

local function GetPlayerTeam(player)
    return player:GetAttribute("Team") or "nothing"
end

local function GetPlayerGame(player)
    return player:GetAttribute("Game") or "nothing"
end

local function IsAlly(player)
    if not Settings.TeamCheck then return false end
    return GetPlayerTeam(player) == GetPlayerTeam(LocalPlayer) and
           GetPlayerGame(player) == GetPlayerGame(LocalPlayer)
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = Settings.AimbotFOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and head and humanoid.Health > 0 then
                if not IsAlly(player) then
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(head.Position)
                    if onScreen then
                        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- ========================================
-- ESP Functions
-- ========================================
local function CreateESP(player)
    if not player.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    
    return highlight
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChildOfClass("Highlight")
            
            if Settings.ESP and not IsAlly(player) then
                if not highlight then
                    CreateESP(player)
                end
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

-- ========================================
-- Auto Vote Functions
-- ========================================
local function AutoVoteMap()
    if not Settings.AutoVote or not Settings.SelectedMap then return end
    
    local voteRemote = ReplicatedStorage:FindFirstChild("Vote")
    if voteRemote then
        voteRemote:InvokeServer(Settings.SelectedMap)
    end
end

-- Connect to map vote event
if ReplicatedStorage:FindFirstChild("MapVote") then
    Connections.MapVote = ReplicatedStorage.MapVote.OnClientEvent:Connect(function(maps, ended)
        if not ended and Settings.AutoVote and Settings.SelectedMap then
            task.wait(0.5)
            AutoVoteMap()
        end
    end)
end

-- ========================================
-- Aimbot Functions
-- ========================================
local function UpdateAimbot()
    if not Settings.Aimbot then return end
    
    local target = GetClosestPlayerToCursor()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            if Settings.SilentAim then
                -- Silent aim implementation
                Mouse.Hit = CFrame.new(head.Position)
            else
                -- Visible aimbot
                workspace.CurrentCamera.CFrame = CFrame.new(
                    workspace.CurrentCamera.CFrame.Position,
                    head.Position
                )
            end
        end
    end
end

-- ========================================
-- Weapon Modifications
-- ========================================
local function ModifyWeapon(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Infinite Ammo
    if Settings.InfiniteAmmo then
        local ammoValue = tool:FindFirstChild("Ammo", true)
        if ammoValue and ammoValue:IsA("NumberValue") then
            ammoValue.Value = 999
        end
    end
    
    -- No Recoil
    if Settings.NoRecoil then
        for _, obj in pairs(tool:GetDescendants()) do
            if obj.Name:lower():match("recoil") then
                obj:Destroy()
            end
        end
    end
end

-- Monitor equipped tools
LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            ModifyWeapon(child)
        end
    end)
end)

if LocalPlayer.Character then
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            ModifyWeapon(tool)
        end
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") then
        ModifyWeapon(tool)
    end
end)

-- ========================================
-- Rayfield UI
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "Arsenal Script Hub",
    LoadingTitle = "Loading Arsenal Script...",
    LoadingSubtitle = "by Your Name",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalScript",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- ========================================
-- Combat Tab
-- ========================================
local CombatTab = Window:CreateTab("⚔️ Combat", nil)

local AimbotSection = CombatTab:CreateSection("Aimbot")

local AimbotToggle = CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        Settings.Aimbot = Value
    end
})

local AimbotFOVSlider = CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "AimbotFOV",
    Callback = function(Value)
        Settings.AimbotFOV = Value
    end
})

local SilentAimToggle = CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(Value)
        Settings.SilentAim = Value
    end
})

local TeamCheckToggle = CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end
})

local WeaponSection = CombatTab:CreateSection("Weapon Mods")

local InfiniteAmmoToggle = CombatTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "InfiniteAmmo",
    Callback = function(Value)
        Settings.InfiniteAmmo = Value
    end
})

local NoRecoilToggle = CombatTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Flag = "NoRecoil",
    Callback = function(Value)
        Settings.NoRecoil = Value
    end
})

-- ========================================
-- Visuals Tab
-- ========================================
local VisualsTab = Window:CreateTab("👁️ Visuals", nil)

local ESPSection = VisualsTab:CreateSection("ESP")

local ESPToggle = VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        Settings.ESP = Value
        UpdateESP()
    end
})

-- ========================================
-- Misc Tab
-- ========================================
local MiscTab = Window:CreateTab("⚙️ Misc", nil)

local VoteSection = MiscTab:CreateSection("Auto Vote")

local AutoVoteToggle = MiscTab:CreateToggle({
    Name = "Enable Auto Vote",
    CurrentValue = false,
    Flag = "AutoVote",
    Callback = function(Value)
        Settings.AutoVote = Value
    end
})

-- Get available maps
local Maps = {}
local MapsFolder = workspace:FindFirstChild("Maps")
if MapsFolder then
    for _, map in pairs(MapsFolder:GetChildren()) do
        table.insert(Maps, map.Name)
    end
end

if #Maps > 0 then
    local MapDropdown = MiscTab:CreateDropdown({
        Name = "Select Map",
        Options = Maps,
        CurrentOption = Maps[1],
        Flag = "SelectedMap",
        Callback = function(Option)
            Settings.SelectedMap = Option
        end
    })
end

-- ========================================
-- Main Loop
-- ========================================
Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    -- Update ESP
    if Settings.ESP then
        UpdateESP()
    end
    
    -- Update Aimbot
    if Settings.Aimbot then
        UpdateAimbot()
    end
    
    -- Update weapon mods
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            ModifyWeapon(tool)
        end
    end
end)

-- ========================================
-- Cleanup
-- ========================================
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then
        for name, connection in pairs(Connections) do
            if connection then
                connection:Disconnect()
            end
        end
    end
end)

-- Notification
Rayfield:Notify({
    Title = "Arsenal Script Loaded",
    Content = "Script successfully loaded!",
    Duration = 5,
    Image = 4483362458,
    Actions = {
        Ignore = {
            Name = "OK",
            Callback = function()
            end
        }
    }
})
