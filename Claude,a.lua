-- ■■■ Arsenal Advanced Script Hub v4.0 - Complete Fixed Version ■■■
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
    TPDuration = 1.0,
    TPOffset = Vector3.new(0, 0, 3),
    MaxTPTargets = 4,
    
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
    
    -- Crosshair Settings
    CrosshairEnabled = true,
    CrosshairColor = Color3.fromRGB(0, 255, 0),
    CrosshairSize = 20,
    CrosshairThickness = 2,
    CrosshairGap = 5,
    CrosshairRotation = 90,
    CrosshairOpacity = 1,
    CrosshairDot = false,
    CrosshairDotSize = 3,
    CrosshairOutline = true,
    CrosshairOutlineColor = Color3.fromRGB(0, 0, 0),
    CrosshairOutlineThickness = 1,
    CrosshairVerticalLength = 20,
    CrosshairHorizontalLength = 20,
    CrosshairVerticalThickness = 2,
    CrosshairHorizontalThickness = 2,
    CrosshairDynamic = false,
    CrosshairAnimation = false,
    CrosshairPreset = "Cross",
    CrosshairOffsetX = 0,
    CrosshairOffsetY = 0,
    
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
    TapCount = 0,
    TPKillChain = 0,
    TargetQueue = {},
    LastTPAttackTime = 0,
    TPAttackCooldown = 0.3,
    GameStartTime = 0,
    CanUseFeatures = false
}

local Connections = {}
local ESPObjects = {}
local OriginalValues = {
    WalkSpeed = 16,
    JumpPower = 50
}

local CrosshairGui = nil
local CrosshairElements = {}

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
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil, math.huge
    end
    
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
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

local function SafeTP(targetCFrame)
    if not LocalPlayer.Character then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp.CFrame = targetCFrame
    return true
end

-- ========================================
-- Crosshair System
-- ========================================
local function CreateCrosshair()
    if CrosshairGui then
        CrosshairGui:Destroy()
    end
    
    CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "AdvancedCrosshair"
    CrosshairGui.ResetOnSpawn = false
    CrosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    CrosshairGui.Parent = LocalPlayer.PlayerGui
    
    CrosshairElements = {}
    
    local function createLine(name, isVertical)
        local line = Instance.new("Frame")
        line.Name = name
        line.BackgroundColor3 = Settings.CrosshairColor
        line.BorderSizePixel = 0
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.ZIndex = 10
        
        if Settings.CrosshairOutline then
            local outline = Instance.new("UIStroke")
            outline.Color = Settings.CrosshairOutlineColor
            outline.Thickness = Settings.CrosshairOutlineThickness
            outline.Parent = line
        end
        
        line.Parent = CrosshairGui
        return line
    end
    
    if Settings.CrosshairPreset == "Cross" then
        CrosshairElements.Top = createLine("Top", true)
        CrosshairElements.Bottom = createLine("Bottom", true)
        CrosshairElements.Left = createLine("Left", false)
        CrosshairElements.Right = createLine("Right", false)
    elseif Settings.CrosshairPreset == "T" then
        CrosshairElements.Top = createLine("Top", true)
        CrosshairElements.Left = createLine("Left", false)
        CrosshairElements.Right = createLine("Right", false)
    elseif Settings.CrosshairPreset == "X" then
        CrosshairElements.Line1 = createLine("Line1", true)
        CrosshairElements.Line2 = createLine("Line2", true)
    elseif Settings.CrosshairPreset == "Circle" then
        local circle = Instance.new("Frame")
        circle.Name = "Circle"
        circle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        circle.BackgroundTransparency = 1
        circle.BorderSizePixel = 0
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Parent = CrosshairGui
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Settings.CrosshairColor
        stroke.Thickness = Settings.CrosshairThickness
        stroke.Parent = circle
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle
        
        CrosshairElements.Circle = circle
    end
    
    if Settings.CrosshairDot then
        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.BackgroundColor3 = Settings.CrosshairColor
        dot.BorderSizePixel = 0
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Size = UDim2.new(0, Settings.CrosshairDotSize, 0, Settings.CrosshairDotSize)
        dot.ZIndex = 11
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        
        if Settings.CrosshairOutline then
            local outline = Instance.new("UIStroke")
            outline.Color = Settings.CrosshairOutlineColor
            outline.Thickness = Settings.CrosshairOutlineThickness
            outline.Parent = dot
        end
        
        dot.Parent = CrosshairGui
        CrosshairElements.Dot = dot
    end
    
    UpdateCrosshair()
end

local function UpdateCrosshair()
    if not CrosshairGui or not Settings.CrosshairEnabled then
        if CrosshairGui then
            CrosshairGui.Enabled = false
        end
        return
    end
    
    CrosshairGui.Enabled = true
    
    local screenSize = Camera.ViewportSize
    local centerX = screenSize.X / 2 + Settings.CrosshairOffsetX
    local centerY = screenSize.Y / 2 + Settings.CrosshairOffsetY
    
    local opacity = Settings.CrosshairOpacity
    
    if Settings.CrosshairPreset == "Cross" then
        local vLength = Settings.CrosshairVerticalLength
        local hLength = Settings.CrosshairHorizontalLength
        local vThickness = Settings.CrosshairVerticalThickness
        local hThickness = Settings.CrosshairHorizontalThickness
        local gap = Settings.CrosshairGap
        
        if CrosshairElements.Top then
            CrosshairElements.Top.Size = UDim2.new(0, vThickness, 0, vLength)
            CrosshairElements.Top.Position = UDim2.new(0, centerX, 0, centerY - gap - vLength)
            CrosshairElements.Top.BackgroundTransparency = 1 - opacity
            CrosshairElements.Top.BackgroundColor3 = Settings.CrosshairColor
            CrosshairElements.Top.Rotation = Settings.CrosshairRotation
        end
        
        if CrosshairElements.Bottom then
            CrosshairElements.Bottom.Size = UDim2.new(0, vThickness, 0, vLength)
            CrosshairElements.Bottom.Position = UDim2.new(0, centerX, 0, centerY + gap)
            CrosshairElements.Bottom.BackgroundTransparency = 1 - opacity
            CrosshairElements.Bottom.BackgroundColor3 = Settings.CrosshairColor
            CrosshairElements.Bottom.Rotation = Settings.CrosshairRotation
        end
        
        if CrosshairElements.Left then
            CrosshairElements.Left.Size = UDim2.new(0, hLength, 0, hThickness)
            CrosshairElements.Left.Position = UDim2.new(0, centerX - gap - hLength, 0, centerY)
            CrosshairElements.Left.BackgroundTransparency = 1 - opacity
            CrosshairElements.Left.BackgroundColor3 = Settings.CrosshairColor
            CrosshairElements.Left.Rotation = Settings.CrosshairRotation
        end
        
        if CrosshairElements.Right then
            CrosshairElements.Right.Size = UDim2.new(0, hLength, 0, hThickness)
            CrosshairElements.Right.Position = UDim2.new(0, centerX + gap, 0, centerY)
            CrosshairElements.Right.BackgroundTransparency = 1 - opacity
            CrosshairElements.Right.BackgroundColor3 = Settings.CrosshairColor
            CrosshairElements.Right.Rotation = Settings.CrosshairRotation
        end
    elseif Settings.CrosshairPreset == "Circle" then
        if CrosshairElements.Circle then
            local size = Settings.CrosshairSize
            CrosshairElements.Circle.Size = UDim2.new(0, size, 0, size)
            CrosshairElements.Circle.Position = UDim2.new(0, centerX, 0, centerY)
            
            local stroke = CrosshairElements.Circle:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = Settings.CrosshairColor
                stroke.Thickness = Settings.CrosshairThickness
                stroke.Transparency = 1 - opacity
            end
        end
    end
    
    if CrosshairElements.Dot then
        CrosshairElements.Dot.Size = UDim2.new(0, Settings.CrosshairDotSize, 0, Settings.CrosshairDotSize)
        CrosshairElements.Dot.Position = UDim2.new(0, centerX, 0, centerY)
        CrosshairElements.Dot.BackgroundTransparency = 1 - opacity
        CrosshairElements.Dot.BackgroundColor3 = Settings.CrosshairColor
    end
end

local function AnimateCrosshairOnKill()
    if not Settings.CrosshairAnimation then return end
    
    task.spawn(function()
        local originalSize = Settings.CrosshairSize
        local originalColor = Settings.CrosshairColor
        
        Settings.CrosshairSize = originalSize * 1.5
        Settings.CrosshairColor = Color3.fromRGB(255, 0, 0)
        UpdateCrosshair()
        
        task.wait(0.1)
        
        Settings.CrosshairSize = originalSize
        Settings.CrosshairColor = originalColor
        UpdateCrosshair()
    end)
end

-- ========================================
-- TP Attack System
-- ========================================
local function GetBehindPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return nil end
    
    local targetPos = targetHRP.Position
    if targetPos.Y > 1000 or targetPos.Y < -500 then
        return nil
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local distance = (targetPos - myPos).Magnitude
        if distance > 500 then
            return nil
        end
    end
    
    local behindCFrame = targetHRP.CFrame * CFrame.new(0, Settings.TPOffset.Y, Settings.TPOffset.Z)
    return behindCFrame
end

local function BuildTargetQueue()
    State.TargetQueue = {}
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local targetList = {}
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            table.insert(targetList, {
                player = player,
                distance = distance
            })
        end
    end
    
    table.sort(targetList, function(a, b)
        return a.distance < b.distance
    end)
    
    for i = 1, math.min(#targetList, Settings.MaxTPTargets) do
        table.insert(State.TargetQueue, targetList[i].player)
    end
end

local function PerformSingleKill(targetPlayer, attackType)
    if not LocalPlayer.Character then return false end
    
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    local knife = LocalPlayer.Character:FindFirstChild("Knife")
    
    if attackType == "gun" and tool then
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            
            local killRemote = tool:FindFirstChild("kill")
            if killRemote then
                local direction = (head.Position - tool.Handle.Position).Unit
                killRemote:FireServer(targetPlayer, direction)
            end
            
            tool:Activate()
            
            local fireRemote = tool:FindFirstChild("fire")
            if fireRemote then
                fireRemote:FireServer()
            end
            
            return true
        end
    elseif attackType == "knife" and knife then
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            
            local slashRemote = knife:FindFirstChild("Slash")
            if slashRemote then
                slashRemote:FireServer()
                knife:Activate()
                return true
            end
        end
    elseif attackType == "throw" then
        local throwTool = tool or knife
        if throwTool then
            local head = targetPlayer.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                
                local throwRemote = throwTool:FindFirstChild("Throw")
                if throwRemote then
                    throwRemote:InvokeServer(head.Position)
                    return true
                end
            end
        end
    end
    
    return false
end

local function PerformChainTPAttack(attackType)
    if not State.CanUseFeatures then return end
    if tick() - State.LastTPAttackTime < State.TPAttackCooldown then return end
    if State.IsTPAttacking then return end
    if not LocalPlayer.Character then return end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    State.IsTPAttacking = true
    State.LastTPAttackTime = tick()
    State.OriginalPosition = hrp.CFrame
    State.TPKillChain = 0
    
    BuildTargetQueue()
    
    if #State.TargetQueue == 0 then
        State.IsTPAttacking = false
        return
    end
    
    task.spawn(function()
        pcall(function()
            for i, targetPlayer in ipairs(State.TargetQueue) do
                if not IsValidTarget(targetPlayer) then continue end
                
                local behindPos = GetBehindPosition(targetPlayer)
                if not behindPos then continue end
                
                SafeTP(behindPos)
                task.wait(0.05)
                
                if PerformSingleKill(targetPlayer, attackType) then
                    AnimateCrosshairOnKill()
                    State.TPKillChain = State.TPKillChain + 1
                end
                
                task.wait(Settings.TPDuration)
            end
            
            if State.OriginalPosition and LocalPlayer.Character then
                SafeTP(State.OriginalPosition)
            end
        end)
        
        task.wait(0.1)
        State.IsTPAttacking = false
        State.TargetQueue = {}
    end)
end

-- ========================================
-- Combat Functions
-- ========================================
local function AutoKill()
    if not State.CanUseFeatures then return end
    if not Settings.AutoKill or State.IsTPAttacking then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
        if Settings.TPAttackEnabled then
            local behindPos = GetBehindPosition(target)
            if behindPos then
                State.IsTPAttacking = true
                State.OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                
                SafeTP(behindPos)
                task.wait(0.05)
                
                PerformSingleKill(target, "gun")
                
                task.wait(Settings.TPDuration)
                if State.OriginalPosition then
                    SafeTP(State.OriginalPosition)
                end
                
                State.IsTPAttacking = false
            end
        else
            PerformSingleKill(target, "gun")
        end
    end
end

local function ApplyAutoHeadshot()
    if not State.CanUseFeatures then return end
    if not Settings.AutoHeadshot or State.IsTPAttacking then return end
    
    local target = GetClosestPlayerToCursor()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        end
    end
end

local function AutoThrow()
    if not State.CanUseFeatures then return end
    if not Settings.AutoThrow or State.IsTPAttacking then return end
    
    local target = GetClosestPlayer()
    if target and target.Character then
        if Settings.TPAttackEnabled then
            local behindPos = GetBehindPosition(target)
            if behindPos then
                State.IsTPAttacking = true
                State.OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                
                SafeTP(behindPos)
                task.wait(0.05)
                
                PerformSingleKill(target, "throw")
                
                task.wait(Settings.TPDuration)
                if State.OriginalPosition then
                    SafeTP(State.OriginalPosition)
                end
                
                State.IsTPAttacking = false
            end
        else
            PerformSingleKill(target, "throw")
        end
    end
end

local function KillAura()
    if not State.CanUseFeatures then return end
    if not Settings.KillAura or State.IsTPAttacking then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (player.Character.HumanoidRootPart.Position - myPos).Magnitude
            if distance <= Settings.KillAuraRange then
                PerformSingleKill(player, "gun")
            end
        end
    end
end

local function SilentAim()
    if not State.CanUseFeatures then return end
    if not Settings.SilentAim or State.IsTPAttacking then return end
    
    local target = GetClosestPlayerToCursor()
    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            Mouse.Hit = CFrame.new(head.Position)
        end
    end
end

local lastTriggerTime = 0
local function TriggerBot()
    if not State.CanUseFeatures then return end
    if not Settings.TriggerBot or State.IsTPAttacking then return end
    if tick() - lastTriggerTime < Settings.TriggerBotDelay then return end
    
    local mouseTarget = Mouse.Target
    if mouseTarget then
        local targetPlayer = Players:GetPlayerFromCharacter(mouseTarget.Parent)
        if targetPlayer and IsValidTarget(targetPlayer) then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
            lastTriggerTime = tick()
        end
    end
end

local function ApplyRapidFire(tool)
    if not Settings.RapidFire or not tool then return end
    
    local debounce = tool:FindFirstChild("Debounce")
    if debounce and debounce:IsA("NumberValue") then
        debounce.Value = Settings.RapidFireSpeed
    end
    
    for _, obj in pairs(tool:GetDescendants()) do
        if obj.Name:lower():match("firerate") or obj.Name:lower():match("fire_rate") then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                obj.Value = Settings.RapidFireSpeed
            end
        end
    end
end

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
local function CrosshairTP()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetPos = Mouse.Hit.Position
    SafeTP(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
end

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
    
    if Settings.InfiniteAmmo then
        for _, obj in pairs(tool:GetDescendants()) do
            if obj.Name:lower():match("ammo") and (obj:IsA("NumberValue") or obj:IsA("IntValue")) then
                obj.Value = 999
            end
        end
    end
    
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
local function AntiAFK()
    if Settings.AntiAFK then
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end

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
    TPBtn.Position = UDim2.new(1, -150, 1, -260)
    TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TPBtn.BorderSizePixel = 3
    TPBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Text = "TP"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.TextSize = 24
    TPBtn.Font = Enum.Font.GothamBold
    
    local corner = Instance.new("UICorner", TPBtn)
    corner.CornerRadius = UDim.new(0, 12)
    
    local pressStartTime = 0
    local pressDuration = 0
    
    TPBtn.MouseButton1Down:Connect(function()
        pressStartTime = tick()
    end)
    
    TPBtn.MouseButton1Up:Connect(function()
        pressDuration = tick() - pressStartTime
        local currentTime = tick()
        local timeSinceLastTap = currentTime - State.LastTapTime
        
        if pressDuration > 0.5 then
            State.Target = GetClosestPlayer()
            if State.Target then
                Rayfield:Notify({
                    Title = "Target Lock",
                    Content = "Locked: " .. State.Target.Name,
                    Duration = 2,
                    Image = 4483362458
                })
            end
        elseif timeSinceLastTap < 0.3 and State.TapCount == 1 then
            State.Target = nil
            State.TapCount = 0
            Rayfield:Notify({
                Title = "Target Lock",
                Content = "Target Released",
                Duration = 2,
                Image = 4483362458
            })
        else
            State.TapCount = 1
            State.LastTapTime = currentTime
            
            if not State.Target then
                if Settings.CrosshairEnabled and Settings.CrosshairTP then
                    CrosshairTP()
                elseif LocalPlayer.Character then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        SafeTP(hrp.CFrame * CFrame.new(0, 0, -15))
                    end
                end
            end
            
            task.delay(0.3, function()
                State.TapCount = 0
            end)
        end
    end)
    
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
    
    Connections.AutoFollow = RunService.Heartbeat:Connect(function()
        if State.Target and State.Target.Character and not State.IsTPAttacking then
            local targetHRP = State.Target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP and LocalPlayer.Character then
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local followPos = targetHRP.CFrame * CFrame.new(0, 5, 5)
                    SafeTP(followPos)
                end
            else
                State.Target = nil
            end
        end
    end)
end

-- ========================================
-- Rayfield UI
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "🎮 Arsenal Advanced Script Hub v4.0",
    LoadingTitle = "Arsenal Script Loading...",
    LoadingSubtitle = "Complete Fixed Version",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalAdvancedV4",
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
    Name = "Max TP Targets (Chain Kill)",
    Range = {1, 10},
    Increment = 1,
    Suffix = " enemies",
    CurrentValue = 4,
    Flag = "MaxTPTargets",
    Callback = function(Value)
        Settings.MaxTPTargets = Value
    end
})

CombatTab:CreateButton({
    Name = "🔥 Execute Chain TP Kill",
    Callback = function()
        PerformChainTPAttack("gun")
    end
})

local AutoKillSection = CombatTab:CreateSection("🔫 Auto Kill Features (Team Check ON)")

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

local KillAuraSection = CombatTab:CreateSection("🌀 Kill Aura (Team Check ON)")

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
    Range = {0, 500},
    Increment = 5,
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
    Name = "Aimbot FOV (pixels)",
    Range = {50, 500},
    Increment = 10,
    Suffix = " px",
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
    Name = "👥 Team Check (ALWAYS ON)",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Settings.TeamCheck = true
    end
})

-- ========================================
-- 🎯 Crosshair Tab
-- ========================================
local CrosshairTab = Window:CreateTab("🎯 Crosshair", 4483362458)

local CrosshairMainSection = CrosshairTab:CreateSection("⚙️ Main Settings")

CrosshairTab:CreateToggle({
    Name = "✅ Enable Crosshair",
    CurrentValue = true,
    Flag = "CrosshairEnabled",
    Callback = function(Value)
        Settings.CrosshairEnabled = Value
        if Value then
            CreateCrosshair()
        else
            UpdateCrosshair()
        end
    end
})

CrosshairTab:CreateDropdown({
    Name = "Crosshair Preset",
    Options = {"Cross", "T", "X", "Circle"},
    CurrentOption = "Cross",
    Flag = "CrosshairPreset",
    Callback = function(Value)
        Settings.CrosshairPreset = Value
        CreateCrosshair()
    end
})

CrosshairTab:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "CrosshairColor",
    Callback = function(Value)
        Settings.CrosshairColor = Value
        UpdateCrosshair()
    end
})

local CrosshairSizeSection = CrosshairTab:CreateSection("📏 Size & Dimensions")

CrosshairTab:CreateSlider({
    Name = "Vertical Line Length",
    Range = {5, 100},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 20,
    Flag = "CrosshairVerticalLength",
    Callback = function(Value)
        Settings.CrosshairVerticalLength = Value
        UpdateCrosshair()
    end
})

CrosshairTab:CreateSlider({
    Name = "Horizontal Line Length",
    Range = {5, 100},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 20,
    Flag = "CrosshairHorizontalLength",
    Callback = function(Value)
        Settings.CrosshairHorizontalLength = Value
        UpdateCrosshair()
    end
})

CrosshairTab:CreateSlider({
    Name = "Center Gap",
    Range = {0, 50},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 5,
    Flag = "CrosshairGap",
    Callback = function(Value)
        Settings.CrosshairGap = Value
        UpdateCrosshair()
    end
})

CrosshairTab:CreateSlider({
    Name = "Rotation (Angle)",
    Range = {0, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 90,
    Flag = "CrosshairRotation",
    Callback = function(Value)
        Settings.CrosshairRotation = Value
        UpdateCrosshair()
    end
})

CrosshairTab:CreateSlider({
    Name = "Opacity",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 1,
    Flag = "CrosshairOpacity",
    Callback = function(Value)
        Settings.CrosshairOpacity = Value
        UpdateCrosshair()
    end
})

CrosshairTab:CreateToggle({
    Name = "Center Dot",
    CurrentValue = false,
    Flag = "CrosshairDot",
    Callback = function(Value)
        Settings.CrosshairDot = Value
        CreateCrosshair()
    end
})

CrosshairTab:CreateToggle({
    Name = "Outline (Border)",
    CurrentValue = true,
    Flag = "CrosshairOutline",
    Callback = function(Value)
        Settings.CrosshairOutline = Value
        CreateCrosshair()
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

VisualsTab:CreateToggle({
    Name = "🧱 Wallhack",
    CurrentValue = false,
    Flag = "Wallhack",
    Callback = function(Value)
        Settings.Wallhack = Value
    end
})

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

UtilityTab:CreateToggle({
    Name = "⏰ Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        Settings.AntiAFK = Value
    end
})

UtilityTab:CreateToggle({
    Name = "👻 Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        Settings.Noclip = Value
        ApplyNoclip()
    end
})

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
-- Event Handlers
-- ========================================
LocalPlayer.CharacterAdded:Connect(function(character)
    -- 試合開始時にStateリセット
    State.IsTPAttacking = false
    State.TPKillChain = 0
    State.TargetQueue = {}
    State.LastTPAttackTime = 0
    State.Target = nil
    State.OriginalPosition = nil
    State.GameStartTime = tick()
    State.CanUseFeatures = false
    
    local humanoid = character:WaitForChild("Humanoid")
    OriginalValues.WalkSpeed = humanoid.WalkSpeed
    OriginalValues.JumpPower = humanoid.JumpPower
    
    -- 5秒待機後に機能を有効化
    task.spawn(function()
        task.wait(5)
        State.CanUseFeatures = true
        print("✅ Features enabled - Game started!")
    end)
    
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

Mouse.Button2Down:Connect(function()
    if Settings.CrosshairTP and not UserInputService.TouchEnabled then
        CrosshairTP()
    end
end)

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
    if Settings.AutoKill then AutoKill() end
    if Settings.AutoHeadshot then ApplyAutoHeadshot() end
    if Settings.AutoThrow then AutoThrow() end
    if Settings.KillAura then KillAura() end
    if Settings.SilentAim then SilentAim() end
    if Settings.TriggerBot then TriggerBot() end
    
    if Settings.Wallhack then ApplyWallhack() end
    
    if Settings.AntiAFK then AntiAFK() end
    
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            ApplyWeaponMods(tool)
        end
    end
end)

-- ========================================
-- Initialize Crosshair
-- ========================================
CreateCrosshair()

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
        
        if CrosshairGui then
            CrosshairGui:Destroy()
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
    Title = "🎮 Arsenal Advanced Script v4.0",
    Content = "✅ Complete Fixed Version\n✅ Team Check: ALWAYS ON\n✅ 5 Second Start Delay\n✅ All Auto Features Working\n✅ Kill Aura: 0-500 studs\n✅ FOV: Pixels",
    Duration = 6,
    Image = 4483362458,
    Actions = {
        Ignore = {
            Name = "Got it!",
            Callback = function()
            end
        }
    }
})

print("Arsenal Advanced Script v4.0 loaded successfully!")
print("✅ Team Check: ALWAYS ON")
print("✅ 5 Second Start Delay: ENABLED")
print("✅ All Auto Features: WORKING")
print("✅ Kill Aura Range: 0-500 studs")
print("✅ FOV: Measured in pixels")
