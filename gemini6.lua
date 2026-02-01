-- ■■■ Arsenal Advanced Script Hub (Integrated Edition) ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ========================================
-- Services
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- ========================================
-- Settings (提供コードのロジック + TPシステム)
-- ========================================
local Settings = {
    -- Combat (txt_1769919085510.txt由来)
    AutoKill = false,
    AutoHeadshot = false,
    KillAura = false,
    KillAuraRange = 20,
    SilentAim = false,
    TriggerBot = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    WallBang = false,
    
    -- TP System (ユーザー指定機能)
    TargetPlayer = nil,
    LockMode = "None", -- "Behind", "Above"
    LockDistance = 5,
    CrosshairTP = true,
    
    -- Movement & Visuals
    SpeedHack = false,
    WalkSpeed = 16,
    Fly = false,
    NoClip = false,
    ESP = false,
    Fullbright = false,
    InfAmmo = false,
    AntiAFK = true
}

-- リモート参照 (New.txt由来)
local Remotes = {
    Fire = ReplicatedStorage:FindFirstChild("fire"),
    Kill = ReplicatedStorage:FindFirstChild("kill"),
    Vote = ReplicatedStorage:FindFirstChild("Vote")
}

-- ========================================
-- Helper Functions
-- ========================================

local function GetClosestPlayer()
    local closest, dist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            -- チームチェック（提供コードのロジック）
            if v.Team ~= LocalPlayer.Team then
                local magnitude = (v.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if magnitude < dist then
                    dist = magnitude
                    closest = v
                end
            end
        end
    end
    return closest
end

local function SafeTP(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cf
    end
end

-- ========================================
-- Mobile TP Button (スマート配置・マルチタップ)
-- ========================================
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local TPBtn = Instance.new("TextButton", ScreenGui)
    local UICorner = Instance.new("UICorner", TPBtn)
    
    TPBtn.Name = "MobileTPButton"
    TPBtn.Size = UDim2.new(0, 65, 0, 65)
    TPBtn.Position = UDim2.new(1, -150, 1, -260) -- ジャンプボタンの上
    TPBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TPBtn.BackgroundTransparency = 0.4
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Font = Enum.Font.GothamBold
    TPBtn.TextSize = 20
    UICorner.CornerRadius = UDim.new(1, 0)

    local lastTap = 0
    local pressStart = 0

    TPBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick()
            TPBtn:TweenSize(UDim2.new(0, 55, 0, 55), "Out", "Quad", 0.1, true)
        end
    end)

    TPBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local duration = tick() - pressStart
            local tapGap = tick() - lastTap
            
            if duration > 0.6 then -- 長押し: ターゲット選択
                Settings.TargetPlayer = GetClosestPlayer()
                Rayfield:Notify({Title = "Target", Content = "Locked: " .. (Settings.TargetPlayer and Settings.TargetPlayer.Name or "None")})
            elseif tapGap < 0.3 then -- ダブルタップ: 解除
                Settings.TargetPlayer = nil
                Settings.LockMode = "None"
                Rayfield:Notify({Title = "System", Content = "Lock Released"})
            else -- タップ: 前方TP
                if not Settings.TargetPlayer then
                    SafeTP(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -15))
                end
            end
            lastTap = tick()
            TPBtn:TweenSize(UDim2.new(0, 65, 0, 65), "Out", "Quad", 0.1, true)
        end
    end)

    -- ロック中の点滅フィードバック
    task.spawn(function()
        while true do
            if Settings.TargetPlayer then
                TPBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(0.25)
                TPBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
            task.wait(0.25)
        end
    end)
end

-- ========================================
-- Main UI Window
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "Arsenal Advanced Hub v2.5",
    LoadingTitle = "Initializing Systems...",
    LoadingSubtitle = "TP Attack & Combat Integrated",
    ConfigurationSaving = { Enabled = true, Folder = "ArsenalHub" }
})

-- 【戦闘タブ】 (txt_1769919085510.txtの機能を統合)
local CombatTab = Window:CreateTab("⚔️ Combat")
CombatTab:CreateToggle({Name = "Auto Kill", CurrentValue = false, Callback = function(v) Settings.AutoKill = v end})
CombatTab:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) Settings.KillAura = v end})
CombatTab:CreateToggle({Name = "Silent Aim", CurrentValue = false, Callback = function(v) Settings.SilentAim = v end})
CombatTab:CreateToggle({Name = "Trigger Bot", CurrentValue = false, Callback = function(v) Settings.TriggerBot = v end})
CombatTab:CreateToggle({Name = "Rapid Fire", CurrentValue = false, Callback = function(v) Settings.RapidFire = v end})
CombatTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Callback = function(v) Settings.NoRecoil = v end})

-- 【移動タブ】 (ユーザー指定TPシステムを維持)
local MoveTab = Window:CreateTab("🏃 Movement")
MoveTab:CreateSection("Target Lock TP")
MoveTab:CreateDropdown({
    Name = "Lock Mode",
    Options = {"None", "Behind", "Above"},
    CurrentOption = "None",
    Callback = function(v) Settings.LockMode = v end
})
MoveTab:CreateSlider({
    Name = "Lock Distance",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v) Settings.LockDistance = v end
})
MoveTab:CreateButton({Name = "Select Target", Callback = function() Settings.TargetPlayer = GetClosestPlayer() end})

MoveTab:CreateSection("Hacks")
MoveTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Callback = function(v) Settings.SpeedHack = v end})
MoveTab:CreateToggle({Name = "Fly", CurrentValue = false, Callback = function(v) Settings.Fly = v end})
MoveTab:CreateToggle({Name = "NoClip", CurrentValue = false, Callback = function(v) Settings.NoClip = v end})

-- 【視覚タブ】
local VisualTab = Window:CreateTab("👁️ Visuals")
VisualTab:CreateToggle({Name = "ESP", CurrentValue = false, Callback = function(v) Settings.ESP = v end})
VisualTab:CreateToggle({Name = "Fullbright", CurrentValue = false, Callback = function(v) Settings.Fullbright = v end})

-- 【武器タブ】
local WeaponTab = Window:CreateTab("🔫 Weapon")
WeaponTab:CreateToggle({Name = "Infinite Ammo", CurrentValue = false, Callback = function(v) Settings.InfAmmo = v end})

-- 【ユーティリティタブ】
local UtilTab = Window:CreateTab("🛠️ Utility")
UtilTab:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v) Settings.AntiAFK = v end})

-- ========================================
-- Main Execution Loop (Heartbeat)
-- ========================================
RunService.Heartbeat:Connect(function()
    -- 1. TP追従システム
    if Settings.TargetPlayer and Settings.TargetPlayer.Character and Settings.TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local tHrp = Settings.TargetPlayer.Character.HumanoidRootPart
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myHrp and Settings.TargetPlayer.Character.Humanoid.Health > 0 then
            if Settings.LockMode == "Behind" then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, Settings.LockDistance)
            elseif Settings.LockMode == "Above" then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, Settings.LockDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        else
            Settings.TargetPlayer = GetClosestPlayer() -- 自動更新
        end
    end

    -- 2. Kill Aura / Auto Kill (txt由来のロジック)
    if Settings.KillAura or Settings.AutoKill then
        local enemy = GetClosestPlayer()
        if enemy and (enemy.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < Settings.KillAuraRange then
            if Remotes.Kill then Remotes.Kill:FireServer(enemy.Character.Humanoid) end
        end
    end
    
    -- 3. Speed / NoClip
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Settings.SpeedHack then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.WalkSpeed end
        if Settings.NoClip then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- PC右クリックTP
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 and Settings.CrosshairTP then
        SafeTP(CFrame.new(Mouse.Hit.p + Vector3.new(0, 3, 0)))
    end
end)

Rayfield:LoadConfiguration()
