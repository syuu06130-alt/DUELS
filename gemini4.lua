-- [[ UI Loader ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- [[ Services ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [[ Remotes (From Decompiled Code) ]]
local VoteRemote = ReplicatedStorage:FindFirstChild("Vote")
local FireRemote = ReplicatedStorage:FindFirstChild("fire")
local KillRemote = ReplicatedStorage:FindFirstChild("kill")
local ShowBeamRemote = ReplicatedStorage:FindFirstChild("showBeam")

-- [[ State Management ]]
local State = {
    Target = nil,
    LockMode = "None", -- "Behind", "Above", "None"
    LockDistance = 5,
    Toggles = {
        AutoKill = false, AutoHeadshot = false, AutoThrow = false,
        KillAura = false, SilentAim = false, Triggerbot = false,
        RapidFire = false, NoRecoil = false, NoSpread = false, WallBang = false,
        ESP = false, FullBright = false, InfAmmo = false, InstReload = false,
        AntiAFK = true, NoClip = false, Fly = false, Speed = 16, Jump = 50
    }
}

-- [[ Functions ]]

-- 最も近い敵を検索
local function GetClosestPlayer()
    local closest, dist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
            local magnitude = (v.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if magnitude < dist then
                dist = magnitude
                closest = v
            end
        end
    end
    return closest
end

-- 安全なTP処理
local function SafeTP(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end
end

-- [[ Mobile TP Button System ]]
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local TPBtn = Instance.new("TextButton", ScreenGui)
    local UICorner = Instance.new("UICorner", TPBtn)
    
    TPBtn.Name = "MobileTPButton"
    TPBtn.Size = UDim2.new(0, 65, 0, 65)
    TPBtn.Position = UDim2.new(1, -150, 1, -250) -- ジャンプボタンの上
    TPBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TPBtn.BackgroundTransparency = 0.4
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Font = Enum.Font.GothamBold
    TPBtn.TextSize = 20
    UICorner.CornerRadius = UDim.new(1, 0)

    local pressStart = 0
    local lastTap = 0
    
    TPBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressStart = tick()
            TPBtn:TweenSize(UDim2.new(0, 55, 0, 55), "Out", "Quad", 0.1, true)
        end
    end)

    TPBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local pressTime = tick() - pressStart
            local tapTime = tick() - lastTap
            
            if pressTime > 0.6 then -- 長押し: ターゲット選択
                State.Target = GetClosestPlayer()
                Rayfield:Notify({Title = "Target", Content = "Locked: "..(State.Target and State.Target.Name or "None")})
            elseif tapTime < 0.3 then -- ダブルタップ: 解除
                State.Target = nil
                State.LockMode = "None"
                Rayfield:Notify({Title = "Target", Content = "Unlocked"})
            else -- シングルタップ: 中央方向TP
                if not State.Target then
                    SafeTP(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -15))
                end
            end
            lastTap = tick()
            TPBtn:TweenSize(UDim2.new(0, 65, 0, 65), "Out", "Quad", 0.1, true)
        end
    end)
    
    -- ロック中の点滅ループ
    task.spawn(function()
        while true do
            if State.Target then
                TPBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(0.25)
                TPBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
            task.wait(0.25)
        end
    end)
end

-- [[ Main Runtime Loop ]]
RunService.Heartbeat:Connect(function()
    -- ターゲットロックTPシステム
    if State.Target and State.Target.Character and State.Target.Character:FindFirstChild("HumanoidRootPart") then
        local tHrp = State.Target.Character.HumanoidRootPart
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myHrp and State.Target.Character.Humanoid.Health > 0 then
            if State.LockMode == "Behind" then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, State.LockDistance)
            elseif State.LockMode == "Above" then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, State.LockDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        else
            State.Target = GetClosestPlayer() -- 自動ターゲット更新
        end
    end

    -- 戦闘ロジック
    if State.Toggles.KillAura or State.Toggles.AutoKill then
        local enemy = GetClosestPlayer()
        if enemy and (enemy.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 20 then
            if KillRemote then KillRemote:FireServer(enemy.Character.Humanoid) end
        end
    end
end)

-- [[ PC Crosshair TP ]]
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
        SafeTP(CFrame.new(Mouse.Hit.p + Vector3.new(0, 3, 0)))
    end
end)

-- [[ UI Window ]]
local Window = Rayfield:CreateWindow({
    Name = "Integrated Premium Hub v2",
    LoadingTitle = "System Initializing...",
    LoadingSubtitle = "by Gemini",
    ConfigurationSaving = { Enabled = true, Folder = "GeminiHub" }
})

-- ⚔️ 戦闘タブ
local CombatTab = Window:CreateTab("⚔️ Combat")
CombatTab:CreateToggle({Name = "Auto Kill", CurrentValue = false, Callback = function(v) State.Toggles.AutoKill = v end})
CombatTab:CreateToggle({Name = "Kill Aura", CurrentValue = false, Callback = function(v) State.Toggles.KillAura = v end})
CombatTab:CreateToggle({Name = "Silent Aim", CurrentValue = false, Callback = function(v) State.Toggles.SilentAim = v end})
CombatTab:CreateToggle({Name = "No Recoil", CurrentValue = false, Callback = function(v) State.Toggles.NoRecoil = v end})
CombatTab:CreateToggle({Name = "Wall Bang", CurrentValue = false, Callback = function(v) State.Toggles.WallBang = v end})

-- 🏃 移動タブ
local MoveTab = Window:CreateTab("🏃 Movement")
MoveTab:CreateSection("Target Lock TP")
local LockDrop = MoveTab:CreateDropdown({
    Name = "Lock Mode",
    Options = {"None", "Behind", "Above"},
    CurrentOption = "None",
    Callback = function(v) 
        if v == "Behind" then State.LockMode = "Behind"
        elseif v == "Above" then State.LockMode = "Above"
        else State.LockMode = "None" end
    end
})
MoveTab:CreateSlider({
    Name = "Lock Distance",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v) State.LockDistance = v end
})
MoveTab:CreateButton({Name = "Select Target", Callback = function() State.Target = GetClosestPlayer() end})

MoveTab:CreateSection("Speed & Jump")
MoveTab:CreateSlider({Name = "Speed Hack", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) LocalPlayer.Character.Humanoid.WalkSpeed = v end})
MoveTab:CreateSlider({Name = "Jump Power", Range = {50, 500}, Increment = 1, CurrentValue = 50, Callback = function(v) LocalPlayer.Character.Humanoid.JumpPower = v end})

-- 👁️ 視覚タブ
local VisualTab = Window:CreateTab("👁️ Visuals")
VisualTab:CreateToggle({Name = "Full Bright", CurrentValue = false, Callback = function(v) 
    Lighting.Brightness = v and 2 or 1
    Lighting.ClockTime = v and 14 or 12
end})
VisualTab:CreateButton({Name = "Enable ESP (Chams)", Callback = function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = Instance.new("Highlight", p.Character)
            h.FillColor = Color3.fromRGB(255, 0, 0)
        end
    end
end})

-- 🔫 武器タブ
local WeaponTab = Window:CreateTab("🔫 Weapon")
WeaponTab:CreateToggle({Name = "Inf Ammo", CurrentValue = false, Callback = function(v) State.Toggles.InfAmmo = v end})
WeaponTab:CreateToggle({Name = "Instant Reload", CurrentValue = false, Callback = function(v) State.Toggles.InstReload = v end})

-- 🛠️ ユーティリティタブ
local UtilTab = Window:CreateTab("🛠️ Utility")
UtilTab:CreateToggle({Name = "Anti AFK", CurrentValue = true, Callback = function(v)
    LocalPlayer.Idled:Connect(function()
        if State.Toggles.AntiAFK then
            game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            wait(1)
            game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end
    end)
end})

Rayfield:LoadConfiguration()
