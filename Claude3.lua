-- ■■■ Arsenal Advanced Script Hub with Rayfield UI ■■■
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
-- Settings
-- ========================================
local Settings = {
    -- Combat
    AutoKill = false,
    AutoHeadshot = false,
    AutoThrow = false,
    KillAura = false,
    KillAuraRange = 20,
    SilentAim = false,
    TriggerBot = false,
    TriggerBotDelay = 0.1,
    RapidFire = false,
    RapidFireSpeed = 0.1,
    NoRecoil = false,
    NoSpread = false,
    WallBang = false,
    AimbotFOV = 100,
    TeamCheck = true,
    
    -- TP Attack Settings
    TPAttackEnabled = true,
    TPDuration = 1.0,  -- TP滞在時間（秒）
    TPOffset = Vector3.new(0, 0, 3),  -- 背後のオフセット
    
    -- Movement
    CrosshairTP = false,
    SpeedHack = false,
    Speed = 16,
    FlyHack = false,
    FlySpeed = 50,
    
    -- Visuals
    ESP = false,
    Wallhack = false,
    Fullbright = false,
    ESPColor = Color3.fromRGB(255, 0, 0),
    
    -- Weapon
    InfiniteAmmo = false,
    InstantReload = false,
    
    -- Utility
    AntiAFK = false,
    Noclip = false,
    SuperJump = false,
    JumpPower = 50
}

local State = {
    Target = nil,
    OriginalPosition = nil,
    IsTPAttacking = false,
    LastTapTime = 0,
    TapCount = 0
}

local Connections = {}
local ESPObjects = {}
local OriginalValues = {
    WalkSpeed = 16,
    JumpPower = 50
}

-- ========================================
-- Utility Functions
-- ========================================
local function FindRunningGame(player)
    for _, v in pairs(Workspace:WaitForChild("RunningGames"):GetChildren()) do
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

local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if IsAlly(player) then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer, shortestDistance
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = Settings.AimbotFOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
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
    
    return closestPlayer
end

-- Safe TP function
local function SafeTP(targetCFrame)
    if not LocalPlayer.Character then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp.CFrame = targetCFrame
    return true
end

-- ========================================
-- TP Attack System
-- ========================================
local function GetBehindPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return nil end
    
    -- 相手の背後の位置を計算
    local behindOffset = targetHRP.CFrame.LookVector * -Settings.TPOffset.Z
    local behindCFrame = targetHRP.CFrame * CFrame.new(0, Settings.TPOffset.Y, Settings.TPOffset.Z)
    
    return behindCFrame
end

local function PerformTPAttack(targetPlayer, attackType)
    if State.IsTPAttacking then return end
    if not LocalPlayer.Character then return end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    State.IsTPAttacking = true
    State.OriginalPosition = hrp.CFrame
    
    -- 背後にTP
    local behindPos = GetBehindPosition(targetPlayer)
    if not behindPos then
        State.IsTPAttacking = false
        return
    end
    
    SafeTP(behindPos)
    
    -- 攻撃実行
    task.spawn(function()
        task.wait(0.05) -- TPが安定するまで少し待つ
        
        if attackType == "gun" then
            -- 銃でヘッドショット
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local head = targetPlayer.Character:FindFirstChild("Head")
                if head then
                    -- カメラを頭に向ける
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    
                    -- 発射
                    local killRemote = tool:FindFirstChild("kill")
                    local fireRemote = tool:FindFirstChild("fire")
                    
                    if killRemote then
                        local direction = (head.Position - tool.Handle.Position).Unit
                        killRemote:FireServer(targetPlayer, direction)
                    end
                    
                    if fireRemote then
                        fireRemote:FireServer()
                    end
                    
                    -- ツールをアクティベート
                    tool:Activate()
                end
            end
            
        elseif attackType == "knife" then
            -- ナイフで攻撃
            local knife = LocalPlayer.Character:FindFirstChild("Knife")
            if knife then
                local head = targetPlayer.Character:FindFirstChild("Head")
                if head then
                    -- カメラを頭に向ける
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    
                    -- Slash（振り回す）
                    local slashRemote = knife:FindFirstChild("Slash")
                    if slashRemote then
                        slashRemote:FireServer()
                        knife:Activate()
                    end
                    
                    -- Throw（投擲）も試す
                    if Settings.AutoThrow then
                        local throwRemote = knife:FindFirstChild("Throw")
                        if throwRemote then
                            throwRemote:InvokeServer(head.Position)
                        end
                    end
                end
            end
            
        elseif attackType == "throw" then
            -- 投擲専用
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local head = targetPlayer.Character:FindFirstChild("Head")
                if head then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    
                    local throwRemote = tool:FindFirstChild("Throw")
                    if throwRemote then
                        throwRemote:InvokeServer(head.Position)
                    end
                end
            end
        end
        
        -- TP滞在時間待機
        task.wait(Settings.TPDuration)
        
        -- 元の位置に戻る
        if State.OriginalPosition then
            SafeTP(State.OriginalPosition)
        end
        
        State.IsTPAttacking = false
    end)
end

-- ========================================
-- Combat Functions
-- ========================================

-- Auto Kill with TP Attack
local function AutoKill()
    if not Settings.AutoKill or State.IsTPAttacking then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
        if Settings.TPAttackEnabled then
            PerformTPAttack(target, "gun")
        else
            -- 通常の攻撃（TPなし）
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local killRemote = tool:FindFirstChild("kill")
                if killRemote then
                    local head = target.Character:FindFirstChild("Head")
                    if head then
                        local direction = (head.Position - tool.Handle.Position).Unit
                        killRemote:FireServer(target, direction)
                    end
                end
            end
        end
    end
end

-- Auto Headshot with TP Attack
local function ApplyAutoHeadshot()
    if not Settings.AutoHeadshot or State.IsTPAttacking then return end
    
    local target = GetClosestPlayerToCursor()
    if target and target.Character then
        if Settings.TPAttackEnabled then
            PerformTPAttack(target, "gun")
        else
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end

-- Auto Throw with TP Attack
local function AutoThrow()
    if not Settings.AutoThrow or State.IsTPAttacking then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
        if Settings.TPAttackEnabled then
            PerformTPAttack(target, "throw")
        else
            local knife = LocalPlayer.Character:FindFirstChild("Knife")
            if knife then
                local throwRemote = knife:FindFirstChild("Throw")
                if throwRemote then
                    throwRemote:InvokeServer(target.Character.Head.Position)
                end
            end
        end
    end
end

-- Kill Aura
local function KillAura()
    if not Settings.KillAura or State.IsTPAttacking then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if distance <= Settings.KillAuraRange then
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    local killRemote = tool:FindFirstChild("kill")
                    if killRemote then
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local direction = (head.Position - tool.Handle.Position).Unit
                            killRemote:FireServer(player, direction)
                        end
                    end
                end
            end
        end
    end
end

-- Silent Aim with TP Attack
local function SilentAim()
    if not Settings.SilentAim or State.IsTPAttacking then return end
    
    local target = GetClosestPlayerToCursor()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            if Settings.TPAttackEnabled then
                PerformTPAttack(target, "gun")
            else
                Mouse.Hit = CFrame.new(head.Position)
            end
        end
    end
end

-- Trigger Bot
local lastTriggerTime = 0
local function TriggerBot()
    if not Settings.TriggerBot or State.IsTPAttacking then return end
    if tick() - lastTriggerTime < Settings.TriggerBotDelay then return end
    
    local mouseTarget = Mouse.Target
    if mouseTarget then
        local targetPlayer = Players:GetPlayerFromCharacter(mouseTarget.Parent)
        if targetPlayer and IsValidTarget(targetPlayer) then
            if Settings.TPAttackEnabled then
                PerformTPAttack(targetPlayer, "gun")
            else
                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
            lastTriggerTime = tick()
        end
    end
end

-- Rapid Fire
local function ApplyRapidFire(tool)
    if not Settings.RapidFire or not tool then return end
    
    local debounce = tool:FindFirstChild("Debounce")
    if debounce and debounce:IsA("NumberValue") then
        debounce.Value = Settings.RapidFireSpeed
    end
    
    -- FireRateなども探す
    for _, obj in pairs(tool:GetDescendants()) do
        if obj.Name:lower():match("firerate") or obj.Name:lower():match("fire_rate") then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                obj.Value = Settings.RapidFireSpeed
            end
        end
    end
end

-- No Recoil
local function ApplyNoRecoil(tool)
    if not Settings.NoRecoil or not tool then return end
    
    for _, obj in pairs(tool:GetDescendants()) do
        if obj.Name:lower():match("recoil") then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                obj.Value = 0
            end
        end
    end
end

-- No Spread
local function ApplyNoSpread(tool)
    if not Settings.NoSpread or not tool then return end
    
    for _, obj in pairs(tool:GetDescendants()) do
        if obj.Name:lower():match("spread") or obj.Name:lower():match("accuracy") then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                obj.Value = 0
            end
        end
    end
end

-- ========================================
-- Movement Functions
-- ========================================

-- Crosshair TP (PC)
local function CrosshairTP()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetPos = Mouse.Hit.Position
    SafeTP(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
end

-- Speed Hack
local function ApplySpeedHack()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if Settings.SpeedHack then
        humanoid.WalkSpeed = Settings.Speed
    else
        humanoid.WalkSpeed = OriginalValues.WalkSpeed
    end
end

-- Fly Hack
local flying = false
local flyConnection = nil

local function StartFly()
    if flying then return end
    flying = true
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local bg = Instance.new("BodyGyro")
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not Settings.FlyHack or not LocalPlayer.Character then
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            if flyConnection then flyConnection:Disconnect() end
            flying = false
            return
        end
        
        local cam = Camera.CFrame
        bg.CFrame = cam
        
        local velocity = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            velocity = velocity + (cam.LookVector * Settings.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            velocity = velocity - (cam.LookVector * Settings.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            velocity = velocity - (cam.RightVector * Settings.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            velocity = velocity + (cam.RightVector * Settings.FlySpeed)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + Vector3.new(0, Settings.FlySpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            velocity = velocity - Vector3.new(0, Settings.FlySpeed, 0)
        end
        
        bv.Velocity = velocity
    end)
end

local function StopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    flying = false
    
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in pairs(hrp:GetChildren()) do
                if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
                    obj:Destroy()
                end
            end
        end
    end
end

-- ========================================
-- Visual Functions
-- ========================================

-- ESP
local function CreateESP(player)
    if ESPObjects[player] then return end
    if not player.Character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Settings.ESPColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    
    ESPObjects[player] = highlight
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if Settings.ESP and not IsAlly(player) then
                CreateESP(player)
            else
                RemoveESP(player)
            end
        end
    end
end

-- Wallhack
local function ApplyWallhack()
    if Settings.Wallhack then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end
        end
    end
end

-- Fullbright
local function ApplyFullbright()
    if Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end

-- ========================================
-- Weapon Functions
-- ========================================

local function ApplyWeaponMods(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Infinite Ammo
    if Settings.InfiniteAmmo then
        for _, obj in pairs(tool:GetDescendants()) do
            if obj.Name:lower():match("ammo") and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                obj.Value = 999
            end
        end
    end
    
    -- Instant Reload
    if Settings.InstantReload then
        for _, obj in pairs(tool:GetDescendants()) do
            if obj.Name:lower():match("reload") and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                obj.Value = 0
            end
        end
    end
    
    ApplyRapidFire(tool)
    ApplyNoRecoil(tool)
    ApplyNoSpread(tool)
end

-- ========================================
-- Utility Functions
-- ========================================

-- Anti AFK
local function AntiAFK()
    if Settings.AntiAFK then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end

-- Noclip
local noclipConnection = nil
local function ApplyNoclip()
    if Settings.Noclip then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

-- Super Jump
local function ApplySuperJump()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    if Settings.SuperJump then
        humanoid.JumpPower = Settings.JumpPower
    else
        humanoid.JumpPower = OriginalValues.JumpPower
    end
end

-- ========================================
-- Mobile TP Button System
-- ========================================
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    ScreenGui.Name = "MobileTPSystem"
    ScreenGui.ResetOnSpawn = false
    
    local TPBtn = Instance.new("TextButton", ScreenGui)
    TPBtn.Size = UDim2.new(0, 80, 0, 80)
    TPBtn.Position = UDim2.new(1, -150, 1, -260)  -- 画面右下、ジャンプボタンの少し上
    TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TPBtn.BorderSizePixel = 3
    TPBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.TextSize = 24
    TPBtn.Font = Enum.Font.GothamBold
    
    -- UICorner for rounded edges
    local corner = Instance.new("UICorner", TPBtn)
    corner.CornerRadius = UDim.new(0, 12)
    
    -- Touch handling variables
    local pressStartTime = 0
    local pressDuration = 0
    
    -- Button press handling
    TPBtn.MouseButton1Down:Connect(function()
        pressStartTime = tick()
    end)
    
    TPBtn.MouseButton1Up:Connect(function()
        pressDuration = tick() - pressStartTime
        local currentTime = tick()
        local timeSinceLastTap = currentTime - State.LastTapTime
        
        if pressDuration > 0.5 then
            -- 長押し：ターゲットロック
            State.Target = GetClosestPlayer()
            if State.Target then
                Rayfield:Notify({
                    Title = "Target Lock",
                    Content = "Locked: " .. State.Target.Name,
                    Duration = 2,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "Target Lock",
                    Content = "No target found",
                    Duration = 2,
                    Image = 4483362458
                })
            end
            
        elseif timeSinceLastTap < 0.3 and State.TapCount == 1 then
            -- ダブルタップ：ターゲット解除
            State.Target = nil
            State.TapCount = 0
            Rayfield:Notify({
                Title = "Target Lock",
                Content = "Target Released",
                Duration = 2,
                Image = 4483362458
            })
            
        else
            -- シングルタップ
            State.TapCount = 1
            State.LastTapTime = currentTime
            
            if not State.Target then
                -- 前方15スタッドにテレポート
                if LocalPlayer.Character then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.CFrame * CFrame.new(0, 0, -15))
                    end
                end
            end
            
            -- タップカウントをリセット
            task.delay(0.3, function()
                State.TapCount = 0
            end)
        end
    end)
    
    -- ターゲットロック中の点滅
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
    
    -- 自動追従（ターゲットロック時）
    Connections.AutoFollow = RunService.Heartbeat:Connect(function()
        if State.Target and State.Target.Character and not State.IsTPAttacking then
            local targetHRP = State.Target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- 背後または上空に追従
                    local followPos = targetHRP.CFrame * CFrame.new(0, 5, 5)  -- 少し上と後ろ
                    SafeTP(followPos)
                end
            else
                -- ターゲットが無効になったら解除
                State.Target = nil
            end
        end
    end)
end

-- ========================================
-- Rayfield UI
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "🎮 Arsenal Advanced Script Hub",
    LoadingTitle = "Arsenal Script Loading...",
    LoadingSubtitle = "by Advanced Scripter",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalAdvanced",
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
-- ⚔️ Combat Tab
-- ========================================
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

local TPAttackSection = CombatTab:CreateSection("📍 TP Attack Settings")

CombatTab:CreateToggle({
    Name = "📍 Enable TP Attack",
    CurrentValue = true,
    Flag = "TPAttackEnabled",
    Callback = function(Value)
        Settings.TPAttackEnabled = Value
    end
})

CombatTab:CreateSlider({
    Name = "TP Duration (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1.0,
    Flag = "TPDuration",
    Callback = function(Value)
        Settings.TPDuration = Value
    end
})

CombatTab:CreateSlider({
    Name = "TP Offset (studs)",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 3,
    Flag = "TPOffset",
    Callback = function(Value)
        Settings.TPOffset = Vector3.new(0, 0, Value)
    end
})

local AutoKillSection = CombatTab:CreateSection("🔫 Auto Kill Features")

CombatTab:CreateToggle({
    Name = "🔫 Auto Kill",
    CurrentValue = false,
    Flag = "AutoKill",
    Callback = function(Value)
        Settings.AutoKill = Value
    end
})

CombatTab:CreateToggle({
    Name = "🎯 Auto Headshot",
    CurrentValue = false,
    Flag = "AutoHeadshot",
    Callback = function(Value)
        Settings.AutoHeadshot = Value
    end
})

CombatTab:CreateToggle({
    Name = "🔪 Auto Throw",
    CurrentValue = false,
    Flag = "AutoThrow",
    Callback = function(Value)
        Settings.AutoThrow = Value
    end
})

local KillAuraSection = CombatTab:CreateSection("🌀 Kill Aura")

CombatTab:CreateToggle({
    Name = "🌀 Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        Settings.KillAura = Value
    end
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "KillAuraRange",
    Callback = function(Value)
        Settings.KillAuraRange = Value
    end
})

local AimSection = CombatTab:CreateSection("🎯 Aim Assistance")

CombatTab:CreateToggle({
    Name = "🎯 Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(Value)
        Settings.SilentAim = Value
    end
})

CombatTab:CreateToggle({
    Name = "🤖 Trigger Bot",
    CurrentValue = false,
    Flag = "TriggerBot",
    Callback = function(Value)
        Settings.TriggerBot = Value
    end
})

CombatTab:CreateSlider({
    Name = "Trigger Bot Delay",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "TriggerBotDelay",
    Callback = function(Value)
        Settings.TriggerBotDelay = Value
    end
})

CombatTab:CreateSlider({
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

local WeaponModsSection = CombatTab:CreateSection("🔧 Weapon Modifications")

CombatTab:CreateToggle({
    Name = "⚡ Rapid Fire",
    CurrentValue = false,
    Flag = "RapidFire",
    Callback = function(Value)
        Settings.RapidFire = Value
    end
})

CombatTab:CreateSlider({
    Name = "Fire Rate",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "RapidFireSpeed",
    Callback = function(Value)
        Settings.RapidFireSpeed = Value
    end
})

CombatTab:CreateToggle({
    Name = "📉 No Recoil",
    CurrentValue = false,
    Flag = "NoRecoil",
    Callback = function(Value)
        Settings.NoRecoil = Value
    end
})

CombatTab:CreateToggle({
    Name = "🎯 No Spread",
    CurrentValue = false,
    Flag = "NoSpread",
    Callback = function(Value)
        Settings.NoSpread = Value
    end
})

CombatTab:CreateToggle({
    Name = "🧱 Wall Bang",
    CurrentValue = false,
    Flag = "WallBang",
    Callback = function(Value)
        Settings.WallBang = Value
    end
})

CombatTab:CreateToggle({
    Name = "👥 Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end
})

-- ========================================
-- 🏃 Movement Tab
-- ========================================
local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)

local TPSection = MovementTab:CreateSection("🎯 Teleportation")

MovementTab:CreateToggle({
    Name = "🎯 Crosshair TP (Right Click) [PC]",
    CurrentValue = false,
    Flag = "CrosshairTP",
    Callback = function(Value)
        Settings.CrosshairTP = Value
    end
})

MovementTab:CreateParagraph({
    Title = "📱 Mobile TP Button",
    Content = "• Single Tap: TP forward 15 studs\n• Long Press (0.5s): Lock nearest enemy\n• Double Tap: Release lock\n• Auto-follow when locked"
})

local SpeedSection = MovementTab:CreateSection("⚡ Speed")

MovementTab:CreateToggle({
    Name = "⚡ Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(Value)
        Settings.SpeedHack = Value
        ApplySpeedHack()
    end
})

MovementTab:CreateSlider({
    Name = "Speed",
    Range = {16, 500},
    Increment = 1,
    Suffix = " speed",
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(Value)
        Settings.Speed = Value
        if Settings.SpeedHack then
            ApplySpeedHack()
        end
    end
})

local FlySection = MovementTab:CreateSection("✈️ Flight")

MovementTab:CreateToggle({
    Name = "✈️ Fly Hack",
    CurrentValue = false,
    Flag = "FlyHack",
    Callback = function(Value)
        Settings.FlyHack = Value
        if Value then
            StartFly()
        else
            StopFly()
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = " speed",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        Settings.FlySpeed = Value
    end
})

-- ========================================
-- 👁️ Visuals Tab
-- ========================================
local VisualsTab = Window:CreateTab("👁️ Visuals", 4483362458)

local ESPSection = VisualsTab:CreateSection("🎯 ESP")

VisualsTab:CreateToggle({
    Name = "🎯 Enable ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        Settings.ESP = Value
        UpdateESP()
    end
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Value)
        Settings.ESPColor = Value
        UpdateESP()
    end
})

local WallhackSection = VisualsTab:CreateSection("🧱 Wallhack")

VisualsTab:CreateToggle({
    Name = "🧱 Wallhack",
    CurrentValue = false,
    Flag = "Wallhack",
    Callback = function(Value)
        Settings.Wallhack = Value
    end
})

local BrightnessSection = VisualsTab:CreateSection("💡 Lighting")

VisualsTab:CreateToggle({
    Name = "💡 Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(Value)
        Settings.Fullbright = Value
        ApplyFullbright()
    end
})

-- ========================================
-- 🔫 Weapon Tab
-- ========================================
local WeaponTab = Window:CreateTab("🔫 Weapon", 4483362458)

local AmmoSection = WeaponTab:CreateSection("∞ Ammunition")

WeaponTab:CreateToggle({
    Name = "∞ Infinite Ammo",
    CurrentValue = false,
    Flag = "InfiniteAmmo",
    Callback = function(Value)
        Settings.InfiniteAmmo = Value
    end
})

WeaponTab:CreateToggle({
    Name = "⚡ Instant Reload",
    CurrentValue = false,
    Flag = "InstantReload",
    Callback = function(Value)
        Settings.InstantReload = Value
    end
})

-- ========================================
-- 🛠️ Utility Tab
-- ========================================
local UtilityTab = Window:CreateTab("🛠️ Utility", 4483362458)

local AFKSection = UtilityTab:CreateSection("⏰ Anti-AFK")

UtilityTab:CreateToggle({
    Name = "⏰ Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        Settings.AntiAFK = Value
    end
})

local PhysicsSection = UtilityTab:CreateSection("👻 Physics")

UtilityTab:CreateToggle({
    Name = "👻 Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        Settings.Noclip = Value
        ApplyNoclip()
    end
})

local JumpSection = UtilityTab:CreateSection("🦘 Jump")

UtilityTab:CreateToggle({
    Name = "🦘 Super Jump",
    CurrentValue = false,
    Flag = "SuperJump",
    Callback = function(Value)
        Settings.SuperJump = Value
        ApplySuperJump()
    end
})

UtilityTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 10,
    Suffix = " power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        Settings.JumpPower = Value
        if Settings.SuperJump then
            ApplySuperJump()
        end
    end
})

-- ========================================
-- ⚙️ Settings Tab
-- ========================================
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

local ConfigSection = SettingsTab:CreateSection("💾 Configuration")

SettingsTab:CreateButton({
    Name = "💾 Save Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Configuration Saved",
            Content = "Your settings have been saved!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateButton({
    Name = "📂 Load Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Configuration Loaded",
            Content = "Your settings have been loaded!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateButton({
    Name = "🔄 Reset to Default",
    Callback = function()
        for key, _ in pairs(Settings) do
            if type(Settings[key]) == "boolean" then
                Settings[key] = false
            elseif type(Settings[key]) == "number" then
                if key == "Speed" then Settings[key] = 16
                elseif key == "JumpPower" then Settings[key] = 50
                elseif key == "FlySpeed" then Settings[key] = 50
                elseif key == "KillAuraRange" then Settings[key] = 20
                elseif key == "AimbotFOV" then Settings[key] = 100
                elseif key == "TPDuration" then Settings[key] = 1.0
                end
            end
        end
        
        Rayfield:Notify({
            Title = "Settings Reset",
            Content = "All settings have been reset to default!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local InfoSection = SettingsTab:CreateSection("ℹ️ Information")

SettingsTab:CreateParagraph({
    Title = "Script Information",
    Content = "Arsenal Advanced Script Hub v2.5\n\nTP Attack System:\n• Auto TP behind enemy\n• Headshot + TP combo\n• Adjustable TP duration\n\nMobile Features:\n• Smart TP button\n• Target locking\n• Auto-follow"
})

-- ========================================
-- Event Handlers
-- ========================================

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    OriginalValues.WalkSpeed = humanoid.WalkSpeed
    OriginalValues.JumpPower = humanoid.JumpPower
    
    task.wait(1)
    ApplySpeedHack()
    ApplySuperJump()
    
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            ApplyWeaponMods(child)
        end
    end)
    
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            ApplyWeaponMods(tool)
        end
    end
end)

LocalPlayer.Backpack.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") then
        ApplyWeaponMods(tool)
    end
end)

-- PC Crosshair TP
Mouse.Button2Down:Connect(function()
    if Settings.CrosshairTP and not UserInputService.TouchEnabled then
        CrosshairTP()
    end
end)

-- Player ESP events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if Settings.ESP then
            UpdateESP()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ========================================
-- Main Loop
-- ========================================
Connections.MainLoop = RunService.Heartbeat:Connect(function()
    -- Combat (TP Attack統合版)
    if Settings.AutoKill then AutoKill() end
    if Settings.AutoHeadshot then ApplyAutoHeadshot() end
    if Settings.AutoThrow then AutoThrow() end
    if Settings.KillAura then KillAura() end
    if Settings.SilentAim then SilentAim() end
    if Settings.TriggerBot then TriggerBot() end
    
    -- Visuals
    if Settings.Wallhack then ApplyWallhack() end
    
    -- Utility
    if Settings.AntiAFK then AntiAFK() end
    
    -- Weapon mods
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            ApplyWeaponMods(tool)
        end
    end
end)

-- ========================================
-- Cleanup
-- ========================================
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then
        for _, connection in pairs(Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        for player, _ in pairs(ESPObjects) do
            RemoveESP(player)
        end
        
        StopFly()
        
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = OriginalValues.WalkSpeed
                humanoid.JumpPower = OriginalValues.JumpPower
            end
        end
        
        ApplyFullbright()
    end
end)

-- ========================================
-- Notification
-- ========================================
Rayfield:Notify({
    Title = "🎮 Arsenal Advanced Script",
    Content = "TP Attack System loaded!\n• Auto TP + Kill\n• Mobile TP Button\n• Target Locking",
    Duration = 5,
    Image = 4483362458,
    Actions = {
        Ignore = {
            Name = "Got it!",
            Callback = function()
            end
        }
    }
})

print("Arsenal Advanced Script v2.5 loaded successfully!")
print("TP Attack System: ENABLED")
print("Mobile TP Button: " .. (UserInputService.TouchEnabled and "ENABLED" or "DISABLED (PC)"))
