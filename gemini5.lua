-- [[ 1. UI Loader & Services ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- [[ 2. Remotes (デコンパイルコードから抽出) ]]
local VoteRemote = ReplicatedStorage:FindFirstChild("Vote")
local FireRemote = ReplicatedStorage:FindFirstChild("fire")
local KillRemote = ReplicatedStorage:FindFirstChild("kill")
local ShowBeamRemote = ReplicatedStorage:FindFirstChild("showBeam")

-- [[ 3. State Management ]]
local State = {
    Target = nil,
    LockMode = "None", -- "Behind", "Above", "None"
    LockDistance = 5,
    Toggles = {
        AutoKill = false, AutoHeadshot = false, KillAura = false,
        SilentAim = false, RapidFire = false, NoRecoil = false,
        ESP = false, FullBright = false, InfAmmo = false,
        AntiAFK = true, NoClip = false, Fly = false, Speed = 16
    }
}

-- [[ 4. Helper Functions ]]

-- 最も近い敵を取得
local function GetClosestPlayer()
    local closest, dist = nil, math.huge
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

-- 安全なテレポート
local function SafeTP(cframe)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
    end
end

-- [[ 5. Mobile TP Button System (スマート配置) ]]
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    ScreenGui.Name = "MobileTPSystem"
    
    local TPBtn = Instance.new("TextButton", ScreenGui)
    local UICorner = Instance.new("UICorner", TPBtn)
    
    TPBtn.Name = "TPButton"
    TPBtn.Size = UDim2.new(0, 70, 0, 70)
    -- ジャンプボタンの少し上に配置
    TPBtn.Position = UDim2.new(1, -150, 1, -260) 
    TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TPBtn.BackgroundTransparency = 0.3
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Font = Enum.Font.GothamBold
    TPBtn.TextSize = 22
    UICorner.CornerRadius = UDim.new(1, 0)

    local lastTap = 0
    local pressStartTime = 0

    TPBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            pressStartTime = tick()
            TPBtn:TweenSize(UDim2.new(0, 60, 0, 60), "Out", "Quad", 0.1, true)
        end
    end)

    TPBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            local pressDuration = tick() - pressStartTime
            local timeSinceLastTap = tick() - lastTap
            
            if pressDuration > 0.5 then -- 長押し: ターゲット選択
                State.Target = GetClosestPlayer()
                Rayfield:Notify({Title = "Target Lock", Content = "Locked: " .. (State.Target and State.Target.Name or "None")})
            elseif timeSinceLastTap < 0.3 then -- ダブルタップ: 解除
                State.Target = nil
                Rayfield:Notify({Title = "Target Lock", Content = "Target Released"})
            else -- シングルタップ: 前方TP
                if not State.Target then
                    SafeTP(LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -15))
                end
            end
            lastTap = tick()
            TPBtn:TweenSize(UDim2.new(0, 70, 0, 70), "Out", "Quad", 0.1, true)
        end
    end)

    -- 点滅フィードバック
    task.spawn(function()
        while true do
            if State.Target then
                TPBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(0.3)
                TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
            task.wait(0.3)
        end
    end)
end

-- [[ 6. UI Creation (Rayfield) ]]
local Window = Rayfield:CreateWindow({
    Name = "Premium Integrated Hub",
    LoadingTitle = "Loading Luau Scripts...",
    LoadingSubtitle = "Combat & Movement v3",
    ConfigurationSaving = { Enabled = true, Folder = "RayfieldConfigs" }
})

-- ⚔️ 戦闘タブ
local CombatTab = Window:CreateTab("⚔️ Combat")
CombatTab:CreateToggle({
    Name = "Kill Aura (Closest)",
    CurrentValue = false,
    Callback = function(v) State.Toggles.KillAura = v end
})
CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(v) State.Toggles.SilentAim = v end
})
CombatTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(v) State.Toggles.NoRecoil = v end
})

-- 🏃 移動タブ (ターゲットTPシステム)
local MoveTab = Window:CreateTab("🏃 Movement")
MoveTab:CreateSection("Target Lock TP")

local LockDrop = MoveTab:CreateDropdown({
    Name = "Lock Mode (Exclusive)",
    Options = {"None", "Behind", "Above"},
    CurrentOption = "None",
    Callback = function(Option)
        State.LockMode = Option
    end
})

MoveTab:CreateSlider({
    Name = "Lock Distance",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value) State.LockDistance = Value end
})

MoveTab:CreateButton({
    Name = "🎯 Select Target (Manual)",
    Callback = function()
        State.Target = GetClosestPlayer()
        if State.Target then
            Rayfield:Notify({Title = "System", Content = "Locked onto: " .. State.Target.Name})
        end
    end
})

MoveTab:CreateSection("Movement Hacks")
MoveTab:CreateSlider({
    Name = "Speed Hack",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})

-- 👁️ 視覚タブ
local VisualTab = Window:CreateTab("👁️ Visuals")
VisualTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Callback = function(v)
        Lighting.Brightness = v and 2 or 1
        Lighting.ClockTime = v and 14 or 12
    end
})

-- 🛠️ ユーティリティタブ
local UtilTab = Window:CreateTab("🛠️ Utility")
UtilTab:CreateButton({
    Name = "Force Random Vote",
    Callback = function()
        if VoteRemote then VoteRemote:InvokeServer(math.random(1, 3)) end
    end
})
UtilTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Callback = function(v) State.Toggles.AntiAFK = v end
})

-- [[ 7. Main Loop (Heartbeat) ]]
RunService.Heartbeat:Connect(function()
    -- TP追従
    if State.Target and State.Target.Character and State.Target.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = State.Target.Character.HumanoidRootPart
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myHrp and State.Target.Character.Humanoid.Health > 0 then
            if State.LockMode == "Behind" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, State.LockDistance)
            elseif State.LockMode == "Above" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, State.LockDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        else
            -- ターゲット消失時、近くに誰かいれば自動更新
            State.Target = GetClosestPlayer()
        end
    end

    -- 戦闘 (Kill Aura)
    if State.Toggles.KillAura then
        local enemy = GetClosestPlayer()
        if enemy and (enemy.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < 15 then
            if KillRemote then KillRemote:FireServer(enemy.Character.Humanoid) end
        end
    end
end)

-- [[ 8. PC Input (Crosshair TP) ]]
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
        SafeTP(CFrame.new(Mouse.Hit.p + Vector3.new(0, 3, 0)))
    end
end)

-- AFK防止の実装
LocalPlayer.Idled:Connect(function()
    if State.Toggles.AntiAFK then
        game:GetService("VirtualUser"):Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(1)
        game:GetService("VirtualUser"):Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)

Rayfield:LoadConfiguration()
