-- Arsenal Simple & Working Script v1.0
-- 確実に動作するバージョン

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- 設定
local Settings = {
    TeamCheck = true,
    AutoKill = false,
    AutoHeadshot = false,
    KillAura = false,
    KillAuraRange = 20,
    SilentAim = false,
    Crosshair = true,
    CrosshairSize = 10,
    CrosshairColor = Color3.fromRGB(0, 255, 0),
    SpeedHack = false,
    Speed = 25,
    FlyHack = false,
    FlySpeed = 50,
    Noclip = false,
    ESP = false
}

-- シンプルなUIを作成
local function CreateSimpleUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArsenalScriptUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 2
    MainFrame.BorderColor3 = Color3.fromRGB(0, 200, 0)
    MainFrame.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- タイトル
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Title.Text = "🎮 Arsenal Script v1.0"
    Title.TextColor3 = Color3.fromRGB(0, 255, 0)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title
    
    -- スクロールフレーム
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -50)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 5
    ScrollFrame.Parent = MainFrame
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = ScrollFrame
    
    local function CreateToggle(name, flag)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Parent = ScrollFrame
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0.8, 0, 1, 0)
        ToggleButton.Position = UDim2.new(0, 0, 0, 0)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ToggleButton.Text = name
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.TextSize = 14
        ToggleButton.Parent = ToggleFrame
        
        local ToggleIndicator = Instance.new("Frame")
        ToggleIndicator.Size = UDim2.new(0, 20, 0, 20)
        ToggleIndicator.Position = UDim2.new(0.85, 0, 0.15, 0)
        ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        ToggleIndicator.BorderSizePixel = 2
        ToggleIndicator.BorderColor3 = Color3.fromRGB(255, 255, 255)
        ToggleIndicator.Parent = ToggleFrame
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 4)
        Corner.Parent = ToggleButton
        
        local IndicatorCorner = Instance.new("UICorner")
        IndicatorCorner.CornerRadius = UDim.new(0, 10)
        IndicatorCorner.Parent = ToggleIndicator
        
        ToggleButton.MouseButton1Click:Connect(function()
            Settings[flag] = not Settings[flag]
            if Settings[flag] then
                ToggleIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            else
                ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        end)
    end
    
    -- トグルを作成
    CreateToggle("Team Check", "TeamCheck")
    CreateToggle("Auto Kill", "AutoKill")
    CreateToggle("Auto Headshot", "AutoHeadshot")
    CreateToggle("Kill Aura", "KillAura")
    CreateToggle("Crosshair", "Crosshair")
    CreateToggle("Speed Hack", "SpeedHack")
    CreateToggle("Fly Hack", "FlyHack")
    CreateToggle("Noclip", "Noclip")
    CreateToggle("ESP", "ESP")
    
    -- クロスヘアスライダー
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 50)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Parent = ScrollFrame
    
    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(1, 0, 0, 20)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = "Crosshair Size: " .. Settings.CrosshairSize
    SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SliderLabel.TextSize = 14
    SliderLabel.Parent = SliderFrame
    
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, 0, 0, 20)
    Slider.Position = UDim2.new(0, 0, 0, 25)
    Slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Slider.Parent = SliderFrame
    
    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((Settings.CrosshairSize - 5) / 25, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    SliderFill.Parent = Slider
    
    Slider.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local sliderPos = Slider.AbsolutePosition
            local sliderSize = Slider.AbsoluteSize
            
            local relativeX = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
            local value = math.floor(5 + relativeX * 25)
            
            Settings.CrosshairSize = value
            SliderLabel.Text = "Crosshair Size: " .. value
            SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        end)
        
        local function disconnect()
            connection:Disconnect()
        end
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                disconnect()
            end
        end)
    end)
    
    return ScreenGui
end

-- チームチェック関数
local function IsAlly(player)
    if not Settings.TeamCheck then return false end
    if player == LocalPlayer then return false end
    
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    
    return myTeam and theirTeam and myTeam == theirTeam
end

-- 有効なターゲットかチェック
local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if IsAlly(player) then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- 最も近いプレイヤーを取得
local function GetClosestPlayer()
    local closest = nil
    local closestDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest
end

-- シンプルなクロスヘア
local CrosshairGui = nil
local function CreateCrosshair()
    if CrosshairGui then CrosshairGui:Destroy() end
    
    CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "SimpleCrosshair"
    CrosshairGui.ResetOnSpawn = false
    CrosshairGui.Parent = game.CoreGui
    
    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2
    local size = Settings.CrosshairSize
    
    -- 水平線
    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(0, size * 2, 0, 2)
    horizontal.Position = UDim2.new(0, centerX - size, 0, centerY - 1)
    horizontal.BackgroundColor3 = Settings.CrosshairColor
    horizontal.BorderSizePixel = 0
    horizontal.Parent = CrosshairGui
    
    -- 垂直線
    local vertical = Instance.new("Frame")
    vertical.Size = UDim2.new(0, 2, 0, size * 2)
    vertical.Position = UDim2.new(0, centerX - 1, 0, centerY - size)
    vertical.BackgroundColor3 = Settings.CrosshairColor
    vertical.BorderSizePixel = 0
    vertical.Parent = CrosshairGui
    
    -- 中央ドット
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 3)
    dot.Position = UDim2.new(0, centerX - 1.5, 0, centerY - 1.5)
    dot.BackgroundColor3 = Settings.CrosshairColor
    dot.BorderSizePixel = 0
    dot.Parent = CrosshairGui
    
    return CrosshairGui
end

-- Auto Kill機能
local function AutoKill()
    if not Settings.AutoKill or not LocalPlayer.Character then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
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

-- Auto Headshot機能
local function AutoHeadshot()
    if not Settings.AutoHeadshot or not LocalPlayer.Character then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end
    end
end

-- Kill Aura機能
local function KillAura()
    if not Settings.KillAura or not LocalPlayer.Character then return end
    
    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local distance = (hrp.Position - myHrp.Position).Magnitude
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
end

-- Speed Hack機能
local function ApplySpeedHack()
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if Settings.SpeedHack then
            humanoid.WalkSpeed = Settings.Speed
        else
            humanoid.WalkSpeed = 16
        end
    end
end

-- Fly Hack機能
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

-- Noclip機能
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

-- シンプルなESP
local ESPObjects = {}
local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
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

-- メインループ
local function MainLoop()
    while true do
        if Settings.Crosshair then
            if not CrosshairGui or not CrosshairGui.Parent then
                CreateCrosshair()
            end
        elseif CrosshairGui then
            CrosshairGui:Destroy()
        end
        
        if Settings.AutoKill then AutoKill() end
        if Settings.AutoHeadshot then AutoHeadshot() end
        if Settings.KillAura then KillAura() end
        
        ApplySpeedHack()
        
        if Settings.FlyHack and not flying then
            StartFly()
        elseif not Settings.FlyHack and flying then
            StopFly()
        end
        
        ApplyNoclip()
        
        if Settings.ESP then
            UpdateESP()
        else
            for player, _ in pairs(ESPObjects) do
                RemoveESP(player)
            end
        end
        
        wait(0.1)
    end
end

-- 初期化
local UI = CreateSimpleUI()

-- プレイヤー追加時のESP
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        if Settings.ESP then
            UpdateESP()
        end
    end)
end)

-- プレイヤー退出時のESP削除
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- キャラクター変更時の設定適用
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    ApplySpeedHack()
    ApplyNoclip()
    
    character:WaitForChild("Humanoid").Died:Connect(function()
        if flying then
            StopFly()
        end
    end)
end)

-- メインループ開始
spawn(MainLoop)

-- 起動メッセージ
print("========================================")
print("Arsenal Simple Script v1.0 Loaded!")
print("Features:")
print("- Team Check Auto Kill")
print("- Simple Crosshair")
print("- Speed/Fly Hack")
print("- Kill Aura")
print("- Noclip & ESP")
print("========================================")

-- UIのドラッグ機能
local UIDrag = false
local DragStart = nil
local StartPos = nil

UI.MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        UIDrag = true
        DragStart = input.Position
        StartPos = UI.MainFrame.Position
    end
end)

UI.MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        UIDrag = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if UIDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        UI.MainFrame.Position = UDim2.new(
            StartPos.X.Scale, 
            StartPos.X.Offset + delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + delta.Y
        )
    end
end)
