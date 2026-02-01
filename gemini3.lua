-- ■■■ UI Loader & Services ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ■■■ Remotes (From Decompiled Code) ■■■
local VoteRemote = ReplicatedStorage:WaitForChild("Vote")
local FireRemote = ReplicatedStorage:WaitForChild("fire")
local KillRemote = ReplicatedStorage:WaitForChild("kill")
local ShowBeamRemote = ReplicatedStorage:FindFirstChild("showBeam")

-- ■■■ Configuration & States ■■■
local TargetPlayer = nil
local LockMode = "None" -- "Behind", "Above", "None"
local LockDistance = 5
local Toggles = {
    AutoKill = false,
    AutoHeadshot = false,
    SilentAim = false,
    KillAura = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    WallBang = false,
    ESP = false,
    FullBright = false,
    InfAmmo = false,
    InstReload = false,
    AntiAFK = true,
    NoClip = false
}

-- ■■■ Utility Functions ■■■

-- 最も近い敵を取得
local function GetClosestPlayer()
    local closest = nil
    local dist = math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local pos = v.Character.HumanoidRootPart.Position
            local magnitude = (pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if magnitude < dist then
                dist = magnitude
                closest = v
            end
        end
    end
    return closest
end

-- ■■■ Mobile TP Button System ■■■
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local TPBtn = Instance.new("TextButton", ScreenGui)
    local UICorner = Instance.new("UICorner", TPBtn)
    
    TPBtn.Name = "MobileTPButton"
    TPBtn.Size = UDim2.new(0, 65, 0, 65)
    TPBtn.Position = UDim2.new(1, -150, 1, -250) -- ジャンプボタンの上
    TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TPBtn.BackgroundTransparency = 0.3
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Font = Enum.Font.GothamBold
    TPBtn.TextSize = 20
    UICorner.CornerRadius = UDim.new(1, 0)

    local lastTap = 0
    TPBtn.MouseButton1Down:Connect(function()
        local now = tick()
        if now - lastTap < 0.3 then -- ダブルタップ
            TargetPlayer = nil
            Rayfield:Notify({Title = "Target", Content = "Locked Target Cleared", Duration = 2})
        else
            if not TargetPlayer then
                -- 通常タップ：中央方向へTP
                LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.new(0, 0, -10)
            end
        end
        lastTap = now
        TPBtn:TweenSize(UDim2.new(0, 55, 0, 55), "Out", "Quad", 0.1, true)
    end)
    
    TPBtn.MouseButton1Up:Connect(function()
        TPBtn:TweenSize(UDim2.new(0, 65, 0, 65), "Out", "Quad", 0.1, true)
    end)
    
    -- 長押し検知用ループ
    task.spawn(function()
        while true do
            if TPBtn.IsPressed then
                wait(0.5)
                if TPBtn.IsPressed then
                    TargetPlayer = GetClosestPlayer()
                    Rayfield:Notify({Title = "Target", Content = "Locked onto: " .. (TargetPlayer and TargetPlayer.Name or "None")})
                end
            end
            wait(0.1)
        end
    end)
end

-- ■■■ Main Loop (Execution) ■■■
RunService.Heartbeat:Connect(function()
    -- TP追従ロジック
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = TargetPlayer.Character.HumanoidRootPart
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            if LockMode == "Behind" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, LockDistance)
            elseif LockMode == "Above" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, LockDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end
        if TargetPlayer.Character.Humanoid.Health <= 0 then TargetPlayer = nil end
    end

    -- 戦闘ロジック (Kill Aura / Auto Kill)
    if Toggles.KillAura or Toggles.AutoKill then
        local enemy = GetClosestPlayer()
        if enemy and (enemy.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 20 then
            KillRemote:FireServer(enemy.Character.Humanoid)
        end
    end
end)

-- ■■■ UI Window Setup ■■■
local Window = Rayfield:CreateWindow({
    Name = "Advanced Premium Hub",
    LoadingTitle = "Loading System...",
    LoadingSubtitle = "Integrated Edition",
    ConfigurationSaving = { Enabled = true, Folder = "MainConfig" }
})

-- 1. 戦闘タブ (Combat)
local CombatTab = Window:CreateTab("⚔️ Combat")
CombatTab:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Toggles.KillAura = v end})
CombatTab:CreateToggle({Name = "Silent Aim", CurrentValue = false, Callback = function(v) Toggles.SilentAim = v end})
CombatTab:CreateToggle({Name = "Auto Headshot", CurrentValue = false, Callback = function(v) Toggles.AutoHeadshot = v end})
CombatTab:CreateToggle({Name = "Rapid Fire", CurrentValue = false, Callback = function(v) Toggles.RapidFire = v end})
CombatTab:CreateToggle({Name = "Wall Bang", CurrentValue = false, Callback = function(v) Toggles.WallBang = v end})

-- 2. 移動タブ (Movement)
local MoveTab = Window:CreateTab("🏃 Movement")
MoveTab:CreateSection("Target Lock TP")
MoveTab:CreateDropdown({
    Name = "Lock Mode",
    Options = {"None", "Behind", "Above"},
    CurrentOption = "None",
    Callback = function(v) LockMode = v end
})
MoveTab:CreateSlider({
    Name = "Lock Distance",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v) LockDistance = v end
})
MoveTab:CreateButton({
    Name = "Select Target",
    Callback = function() 
        TargetPlayer = GetClosestPlayer() 
        if TargetPlayer then Rayfield:Notify({Title = "Target Locked", Content = TargetPlayer.Name}) end
    end
})
MoveTab:CreateSection("Physics")
MoveTab:CreateSlider({Name = "Speed Hack", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v end})
MoveTab:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) Toggles.NoClip = v end})

-- 3. 視覚タブ (Visuals)
local VisualTab = Window:CreateTab("👁️ Visuals")
VisualTab:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Toggles.ESP = v end})
VisualTab:CreateToggle({Name = "Full Bright", CurrentValue = false, Callback = function(v) 
    if v then game:GetService("Lighting").Brightness = 2; game:GetService("Lighting").ClockTime = 14
    else game:GetService("Lighting").Brightness = 1 end
end})

-- 4. 武器タブ (Weapon)
local WeaponTab = Window:CreateTab("🔫 Weapon")
WeaponTab:CreateToggle({Name = "Inf Ammo", CurrentValue = false, Callback = function(v) Toggles.InfAmmo = v end})
WeaponTab:CreateToggle({Name = "Instant Reload", CurrentValue = false, Callback = function(v) Toggles.InstReload = v end})
WeaponTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Callback = function(v) Toggles.NoRecoil = v end})

-- 5. ユーティリティタブ (Utility)
local UtilTab = Window:CreateTab("🛠️ Utility")
UtilTab:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) Toggles.AntiAFK = v end})
UtilTab:CreateButton({Name = "Force Vote Random", Callback = function() VoteRemote:InvokeServer(math.random(1,3)) end})

Rayfield:LoadConfiguration()
