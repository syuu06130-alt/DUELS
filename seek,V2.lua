-- ■■■ Arsenal Advanced Script Hub v4.0 (Ultimate Edition) ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ========================================
-- Services
-- ========================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- ========================================
-- Advanced Settings with Presets
-- ========================================
local Settings = {
    -- Combat Core
    TeamCheck = true,
    
    -- TP Attack System
    TPAttackEnabled = true,
    TPAutoChain = true,
    TPChainTargets = 4,
    TPDuration = 0.8,
    TPOffset = Vector3.new(0, 2, 3),
    TPCooldown = 0.3,
    
    -- Auto Attack Features
    AutoKill = false,
    AutoHeadshot = false,
    AutoThrow = false,
    KillAura = false,
    KillAuraRange = 20,
    
    -- Aim Assistance
    SilentAim = false,
    AimbotFOV = 100,
    TriggerBot = false,
    TriggerBotDelay = 0.1,
    
    -- Weapon Mods
    RapidFire = false,
    RapidFireSpeed = 0.1,
    NoRecoil = false,
    NoSpread = false,
    InfiniteAmmo = false,
    InstantReload = false,
    
    -- Movement
    CrosshairTP = false,
    SpeedHack = false,
    Speed = 25,
    FlyHack = false,
    FlySpeed = 60,
    
    -- Visuals
    ESP = false,
    ESPColor = Color3.fromRGB(255, 50, 50),
    Wallhack = false,
    Fullbright = false,
    
    -- Advanced Crosshair System
    CrosshairEnabled = true,
    CrosshairPreset = "Cross",
    CrosshairColor = Color3.fromRGB(0, 255, 0),
    CrosshairSize = 18,
    CrosshairThickness = 2,
    CrosshairGap = 4,
    CrosshairRotation = 90,
    CrosshairOpacity = 0.95,
    CrosshairDot = true,
    DotSize = 3,
    CrosshairOutline = true,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    OutlineThickness = 1,
    CrosshairDynamic = true,
    CrosshairAnimation = true,
    CrosshairOffsetX = 0,
    CrosshairOffsetY = 0,
    
    -- Utility
    AntiAFK = false,
    Noclip = false,
    SuperJump = false,
    JumpPower = 75
}

local State = {
    -- TP Attack State
    IsTPAttacking = false,
    TPKillChain = 0,
    TargetQueue = {},
    LastTPAttackTime = 0,
    OriginalPosition = nil,
    
    -- Crosshair State
    CrosshairGui = nil,
    CrosshairParts = {},
    
    -- Mobile State
    MobileUI = nil,
    TouchInputs = {},
    
    -- General State
    Connections = {},
    ESPObjects = {},
    
    -- Performance
    LastUpdate = tick(),
    UpdateInterval = 0.016
}

local OriginalValues = {
    WalkSpeed = 16,
    JumpPower = 50,
    FlyState = nil
}

-- ========================================
-- Advanced Team Check System
-- ========================================
local TeamSystem = {
    TeamCache = {},
    LastUpdate = 0,
    UpdateCooldown = 1
}

function TeamSystem:IsAlly(player)
    if not Settings.TeamCheck then return false end
    if player == LocalPlayer then return false end
    
    -- キャッシュ更新
    if tick() - self.LastUpdate > self.UpdateCooldown then
        self:UpdateTeamCache()
    end
    
    -- チーム比較
    local myTeam = self.TeamCache[LocalPlayer]
    local theirTeam = self.TeamCache[player]
    
    return myTeam and theirTeam and myTeam == theirTeam
end

function TeamSystem:UpdateTeamCache()
    self.TeamCache = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local team = player:GetAttribute("Team") or 
                    (player.Team and player.Team.Name) or 
                    "Neutral"
        self.TeamCache[player] = team
    end
    self.LastUpdate = tick()
end

-- 拡張されたバリデーション関数
function IsValidTarget(player, ignoreTeam)
    if not player or player == LocalPlayer then 
        return false, "Self"
    end
    
    if not ignoreTeam and TeamSystem:IsAlly(player) then
        return false, "Ally"
    end
    
    if not player.Character then
        return false, "No Character"
    end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, "Dead"
    end
    
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false, "No HRP"
    end
    
    return true, "Valid"
end

-- ========================================
-- Target Acquisition System
-- ========================================
local TargetSystem = {
    LastScan = 0,
    ScanCooldown = 0.2,
    TargetCache = {}
}

function TargetSystem:GetClosestToPosition(position, maxDistance)
    local closest = nil
    local closestDist = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, reason = IsValidTarget(player)
        if valid and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - position).Magnitude
                if dist < closestDist and dist <= (maxDistance or math.huge) then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest, closestDist
end

function TargetSystem:GetClosestToCursor(maxFOV)
    local closest = nil
    local closestDist = maxFOV or Settings.AimbotFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, reason = IsValidTarget(player)
        if valid and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    return closest
end

function TargetSystem:GetAllValidTargets(limit, maxDistance)
    local targets = {}
    local myPos = LocalPlayer.Character and 
                  LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                  LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, reason = IsValidTarget(player)
        if valid then
            if maxDistance and myPos then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - myPos).Magnitude > maxDistance then
                    continue
                end
            end
            table.insert(targets, player)
            
            if limit and #targets >= limit then
                break
            end
        end
    end
    
    -- 距離順にソート
    if myPos then
        table.sort(targets, function(a, b)
            local aPos = a.Character.HumanoidRootPart.Position
            local bPos = b.Character.HumanoidRootPart.Position
            return (aPos - myPos).Magnitude < (bPos - myPos).Magnitude
        end)
    end
    
    return targets
end

-- ========================================
-- Advanced Crosshair System v4.0
-- ========================================
local CrosshairSystem = {}

function CrosshairSystem:Initialize()
    if State.CrosshairGui then
        State.CrosshairGui:Destroy()
        State.CrosshairParts = {}
    end
    
    State.CrosshairGui = Instance.new("ScreenGui")
    State.CrosshairGui.Name = "UltimateCrosshair"
    State.CrosshairGui.ResetOnSpawn = false
    State.CrosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    State.CrosshairGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    self:CreateCrosshair()
end

function CrosshairSystem:CreateCrosshair()
    -- 中央ドット
    if Settings.CrosshairDot then
        local dot = Instance.new("Frame")
        dot.Name = "CenterDot"
        dot.Size = UDim2.new(0, Settings.DotSize, 0, Settings.DotSize)
        dot.BackgroundColor3 = Settings.CrosshairColor
        dot.BackgroundTransparency = 1 - Settings.CrosshairOpacity
        dot.BorderSizePixel = 0
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.ZIndex = 10
        
        if Settings.CrosshairOutline then
            local stroke = Instance.new("UIStroke")
            stroke.Color = Settings.OutlineColor
            stroke.Thickness = Settings.OutlineThickness
            stroke.Parent = dot
        end
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
        
        dot.Parent = State.CrosshairGui
        State.CrosshairParts.Dot = dot
    end
    
    -- クロスヘア形状の作成
    local centerX = 0.5
    local centerY = 0.5
    local gap = Settings.CrosshairGap / 1000  -- スケーリング
    
    if Settings.CrosshairPreset == "Cross" then
        -- 上線
        local top = self:CreateLine("Top", centerX, centerY - gap)
        top.Size = UDim2.new(0, Settings.CrosshairThickness, 0, Settings.CrosshairSize)
        
        -- 下線
        local bottom = self:CreateLine("Bottom", centerX, centerY + gap)
        bottom.Size = UDim2.new(0, Settings.CrosshairThickness, 0, Settings.CrosshairSize)
        
        -- 左線
        local left = self:CreateLine("Left", centerX - gap, centerY)
        left.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThickness)
        
        -- 右線
        local right = self:CreateLine("Right", centerX + gap, centerY)
        right.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThickness)
        
    elseif Settings.CrosshairPreset == "T" then
        local top = self:CreateLine("Top", centerX, centerY - gap)
        top.Size = UDim2.new(0, Settings.CrosshairThickness, 0, Settings.CrosshairSize)
        
        local left = self:CreateLine("Left", centerX - gap, centerY)
        left.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThickness)
        
        local right = self:CreateLine("Right", centerX + gap, centerY)
        right.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThickness)
        
    elseif Settings.CrosshairPreset == "X" then
        local line1 = self:CreateLine("Line1", centerX, centerY)
        line1.Size = UDim2.new(0, Settings.CrosshairThickness, 0, Settings.CrosshairSize * 1.414)
        line1.Rotation = 45
        
        local line2 = self:CreateLine("Line2", centerX, centerY)
        line2.Size = UDim2.new(0, Settings.CrosshairThickness, 0, Settings.CrosshairSize * 1.414)
        line2.Rotation = -45
        
    elseif Settings.CrosshairPreset == "Circle" then
        local circle = Instance.new("Frame")
        circle.Name = "Circle"
        circle.Size = UDim2.new(0, Settings.CrosshairSize * 2, 0, Settings.CrosshairSize * 2)
        circle.BackgroundTransparency = 1
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Position = UDim2.new(centerX, 0, centerY, 0)
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Settings.CrosshairColor
        stroke.Thickness = Settings.CrosshairThickness
        stroke.Transparency = 1 - Settings.CrosshairOpacity
        stroke.Parent = circle
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle
        
        circle.Parent = State.CrosshairGui
        State.CrosshairParts.Circle = circle
    end
    
    self:UpdateCrosshair()
end

function CrosshairSystem:CreateLine(name, posX, posY)
    local line = Instance.new("Frame")
    line.Name = name
    line.BackgroundColor3 = Settings.CrosshairColor
    line.BackgroundTransparency = 1 - Settings.CrosshairOpacity
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Position = UDim2.new(posX, 0, posY, 0)
    line.Rotation = Settings.CrosshairRotation
    line.ZIndex = 9
    
    if Settings.CrosshairOutline then
        local stroke = Instance.new("UIStroke")
        stroke.Color = Settings.OutlineColor
        stroke.Thickness = Settings.OutlineThickness
        stroke.Parent = line
    end
    
    line.Parent = State.CrosshairGui
    State.CrosshairParts[name] = line
    
    return line
end

function CrosshairSystem:UpdateCrosshair()
    if not State.CrosshairGui or not Settings.CrosshairEnabled then
        if State.CrosshairGui then
            State.CrosshairGui.Enabled = false
        end
        return
    end
    
    State.CrosshairGui.Enabled = true
    
    local screenSize = Camera.ViewportSize
    local centerX = screenSize.X / 2 + Settings.CrosshairOffsetX
    local centerY = screenSize.Y / 2 + Settings.CrosshairOffsetY
    
    -- ドット更新
    if State.CrosshairParts.Dot then
        State.CrosshairParts.Dot.Position = UDim2.new(0, centerX, 0, centerY)
        State.CrosshairParts.Dot.BackgroundTransparency = 1 - Settings.CrosshairOpacity
        State.CrosshairParts.Dot.BackgroundColor3 = Settings.CrosshairColor
        State.CrosshairParts.Dot.Size = UDim2.new(0, Settings.DotSize, 0, Settings.DotSize)
    end
    
    -- 動的クロスヘア
    if Settings.CrosshairDynamic and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local speed = humanoid.MoveDirection.Magnitude
            local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
            
            if speed > 0 or isJumping then
                local spreadMulti = 1.2
                if State.CrosshairParts.Top then
                    State.CrosshairParts.Top.Position = UDim2.new(0, centerX, 0, centerY - Settings.CrosshairGap * spreadMulti)
                end
                if State.CrosshairParts.Bottom then
                    State.CrosshairParts.Bottom.Position = UDim2.new(0, centerX, 0, centerY + Settings.CrosshairGap * spreadMulti)
                end
                return
            end
        end
    end
    
    -- 通常位置
    if State.CrosshairParts.Top then
        State.CrosshairParts.Top.Position = UDim2.new(0, centerX, 0, centerY - Settings.CrosshairGap)
    end
    if State.CrosshairParts.Bottom then
        State.CrosshairParts.Bottom.Position = UDim2.new(0, centerX, 0, centerY + Settings.CrosshairGap)
    end
    if State.CrosshairParts.Left then
        State.CrosshairParts.Left.Position = UDim2.new(0, centerX - Settings.CrosshairGap, 0, centerY)
    end
    if State.CrosshairParts.Right then
        State.CrosshairParts.Right.Position = UDim2.new(0, centerX + Settings.CrosshairGap, 0, centerY)
    end
    
    -- 円形クロスヘア
    if State.CrosshairParts.Circle then
        State.CrosshairParts.Circle.Position = UDim2.new(0, centerX, 0, centerY)
        local stroke = State.CrosshairParts.Circle:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Transparency = 1 - Settings.CrosshairOpacity
            stroke.Color = Settings.CrosshairColor
        end
    end
end

function CrosshairSystem:TriggerKillAnimation()
    if not Settings.CrosshairAnimation then return end
    
    task.spawn(function()
        local originalColor = Settings.CrosshairColor
        Settings.CrosshairColor = Color3.fromRGB(255, 0, 0)
        self:UpdateCrosshair()
        
        task.wait(0.08)
        
        Settings.CrosshairColor = originalColor
        self:UpdateCrosshair()
    end)
end

-- ========================================
-- Advanced TP Attack System v4.0
-- ========================================
local TPAttackSystem = {}

function TPAttackSystem:CanAttack()
    if State.IsTPAttacking then return false end
    if tick() - State.LastTPAttackTime < Settings.TPCooldown then return false end
    if not LocalPlayer.Character then return false end
    if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    if not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then return false end
    
    return true
end

function TPAttackSystem:CalculateSafePosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return nil end
    
    -- 安全チェック
    local targetPos = targetHRP.Position
    if targetPos.Y < -100 or targetPos.Y > 500 then
        return nil
    end
    
    -- 背後位置計算
    local lookVector = targetHRP.CFrame.LookVector
    local rightVector = targetHRP.CFrame.RightVector
    local upVector = targetHRP.CFrame.UpVector
    
    -- オフセット適用
    local offset = Settings.TPOffset
    local behindPos = targetPos - (lookVector * offset.Z) + (upVector * offset.Y) + (rightVector * offset.X)
    
    -- レイキャストで壁チェック
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPlayer.Character}
    
    local raycastResult = Workspace:Raycast(targetPos, (behindPos - targetPos).Unit * offset.Z, raycastParams)
    
    if raycastResult then
        behindPos = raycastResult.Position + raycastResult.Normal * 2
    end
    
    return CFrame.new(behindPos, targetPos)
end

function TPAttackSystem:TeleportToPosition(cframe)
    if not LocalPlayer.Character then return false end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- スムーズなテレポート
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = cframe})
    tween:Play()
    
    return true
end

function TPAttackSystem:ExecuteAttack(targetPlayer, attackType)
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    local success = false
    
    if attackType == "gun" then
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            -- カメラをターゲットに向ける
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            
            -- 攻撃実行
            local killRemote = tool:FindFirstChild("kill")
            if killRemote then
                local direction = (head.Position - tool.Handle.Position).Unit
                killRemote:FireServer(targetPlayer, direction)
                success = true
            end
            
            tool:Activate()
        end
        
    elseif attackType == "knife" then
        local knife = LocalPlayer.Character:FindFirstChild("Knife") or tool
        if knife then
            local head = targetPlayer.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                
                local slashRemote = knife:FindFirstChild("Slash")
                if slashRemote then
                    slashRemote:FireServer()
                    knife:Activate()
                    success = true
                end
            end
        end
    end
    
    if success then
        CrosshairSystem:TriggerKillAnimation()
        State.TPKillChain = State.TPKillChain + 1
    end
    
    return success
end

function TPAttackSystem:PerformSingleAttack(targetPlayer, attackType)
    if not self:CanAttack() then return false end
    if not IsValidTarget(targetPlayer) then return false end
    
    State.IsTPAttacking = true
    State.LastTPAttackTime = tick()
    State.OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    
    -- 安全位置を計算
    local safePosition = self:CalculateSafePosition(targetPlayer)
    if not safePosition then
        State.IsTPAttacking = false
        return false
    end
    
    -- テレポート実行
    self:TeleportToPosition(safePosition)
    task.wait(0.1)
    
    -- 攻撃実行
    local attackSuccess = self:ExecuteAttack(targetPlayer, attackType)
    
    -- 元の位置に戻る
    task.wait(Settings.TPDuration)
    if State.OriginalPosition then
        self:TeleportToPosition(State.OriginalPosition)
    end
    
    State.IsTPAttacking = false
    return attackSuccess
end

function TPAttackSystem:PerformChainAttack(attackType)
    if not self:CanAttack() then return false end
    
    -- ターゲットキューを構築
    State.TargetQueue = TargetSystem:GetAllValidTargets(Settings.TPChainTargets, 500)
    if #State.TargetQueue == 0 then
        Rayfield:Notify({
            Title = "Chain Attack",
            Content = "No valid targets found!",
            Duration = 2,
            Image = 4483362458
        })
        return false
    end
    
    State.IsTPAttacking = true
    State.LastTPAttackTime = tick()
    State.OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    State.TPKillChain = 0
    
    task.spawn(function()
        for i, target in ipairs(State.TargetQueue) do
            if not self:CanAttack() then break end
            if not IsValidTarget(target) then continue end
            
            -- TP + 攻撃
            local safePosition = self:CalculateSafePosition(target)
            if safePosition then
                self:TeleportToPosition(safePosition)
                task.wait(0.1)
                self:ExecuteAttack(target, attackType)
                task.wait(Settings.TPDuration)
            end
        end
        
        -- 元の位置に戻る
        if State.OriginalPosition then
            self:TeleportToPosition(State.OriginalPosition)
        end
        
        -- 結果通知
        if State.TPKillChain > 0 then
            Rayfield:Notify({
                Title = "Chain Attack Complete",
                Content = string.format("Eliminated %d enemies!", State.TPKillChain),
                Duration = 3,
                Image = 4483362458
            })
        end
        
        State.IsTPAttacking = false
        State.TargetQueue = {}
    end)
    
    return true
end

-- ========================================
-- Mobile Integration System
-- ========================================
local MobileSystem = {}

function MobileSystem:Initialize()
    if not UserInputService.TouchEnabled then return end
    
    -- モバイルUI作成
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileArsenalUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- TPボタン
    local tpButton = Instance.new("TextButton")
    tpButton.Name = "TPButton"
    tpButton.Size = UDim2.new(0, 80, 0, 80)
    tpButton.Position = UDim2.new(1, -90, 1, -90)
    tpButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpButton.BorderSizePixel = 2
    tpButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
    tpButton.Text = "TP\nAttack"
    tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpButton.TextSize = 16
    tpButton.Font = Enum.Font.GothamBold
    tpButton.ZIndex = 100
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = tpButton
    
    -- クロスヘアTPボタン
    local crosshairButton = Instance.new("TextButton")
    crosshairButton.Name = "CrosshairTP"
    crosshairButton.Size = UDim2.new(0, 80, 0, 40)
    crosshairButton.Position = UDim2.new(1, -90, 1, -180)
    crosshairButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    crosshairButton.Text = "TP to\nCrosshair"
    crosshairButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    crosshairButton.TextSize = 12
    crosshairButton.Font = Enum.Font.Gotham
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0.2, 0)
    corner2.Parent = crosshairButton
    
    -- ボタン配置
    tpButton.Parent = screenGui
    crosshairButton.Parent = screenGui
    
    -- イベント設定
    local pressTime = 0
    local tapCount = 0
    local lastTap = 0
    
    tpButton.MouseButton1Down:Connect(function()
        pressTime = tick()
    end)
    
    tpButton.MouseButton1Up:Connect(function()
        local duration = tick() - pressTime
        local currentTime = tick()
        local timeSinceLast = currentTime - lastTap
        
        if duration > 0.5 then
            -- 長押し: チェーンアタック
            TPAttackSystem:PerformChainAttack("gun")
        elseif timeSinceLast < 0.3 and tapCount == 1 then
            -- ダブルタップ: ターゲット解除
            tapCount = 0
            Rayfield:Notify({
                Title = "Mobile",
                Content = "Target lock released",
                Duration = 1,
                Image = 4483362458
            })
        else
            -- シングルタップ: シングルアタック
            tapCount = 1
            local target = TargetSystem:GetClosestToPosition(
                LocalPlayer.Character.HumanoidRootPart.Position, 
                100
            )
            if target then
                TPAttackSystem:PerformSingleAttack(target, "gun")
            else
                -- 前方にTP
                if LocalPlayer.Character then
                    local hrp = LocalPlayer.Character.HumanoidRootPart
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -15)
                end
            end
        end
        
        lastTap = currentTime
        task.delay(0.3, function() tapCount = 0 end)
    end)
    
    crosshairButton.MouseButton1Click:Connect(function()
        if Settings.CrosshairEnabled then
            MobileSystem:TeleportToCrosshair()
        end
    end)
    
    State.MobileUI = screenGui
end

function MobileSystem:TeleportToCrosshair()
    if not LocalPlayer.Character then return end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- クロスヘア位置を計算
    local viewportSize = Camera.ViewportSize
    local screenPos = Vector2.new(
        viewportSize.X / 2 + Settings.CrosshairOffsetX,
        viewportSize.Y / 2 + Settings.CrosshairOffsetY
    )
    
    -- レイキャスト
    local unitRay = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
    
    if raycastResult then
        hrp.CFrame = CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0))
    else
        hrp.CFrame = CFrame.new(unitRay.Origin + unitRay.Direction * 50)
    end
end

-- ========================================
-- Combat Functions with Team Check
-- ========================================
local CombatSystem = {}

function CombatSystem:AutoKill()
    if not Settings.AutoKill or State.IsTPAttacking then return end
    
    local target = TargetSystem:GetClosestToPosition(
        LocalPlayer.Character.HumanoidRootPart.Position,
        500
    )
    
    if target then
        if Settings.TPAttackEnabled then
            TPAttackSystem:PerformSingleAttack(target, "gun")
        else
            -- 通常攻撃
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

function CombatSystem:AutoHeadshot()
    if not Settings.AutoHeadshot or State.IsTPAttacking then return end
    
    local target = TargetSystem:GetClosestToCursor(Settings.AimbotFOV)
    if target then
        if Settings.TPAttackEnabled then
            TPAttackSystem:PerformSingleAttack(target, "gun")
        else
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end

function CombatSystem:KillAura()
    if not Settings.KillAura or State.IsTPAttacking then return end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local auraRange = Settings.KillAuraRange
    
    for _, player in ipairs(Players:GetPlayers()) do
        local valid, reason = IsValidTarget(player)
        if valid and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - myPos).Magnitude <= auraRange then
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

-- ========================================
-- Rayfield UI Creation
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "⚡ Arsenal Ultimate v4.0",
    LoadingTitle = "Loading Ultimate Arsenal System...",
    LoadingSubtitle = "Advanced TP + Crosshair Integration",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ArsenalUltimate",
        FileName = "UltimateConfig"
    },
    KeySystem = false
})

-- TP Attack Tab
local TPTab = Window:CreateTab("📍 TP Attack", 4483362458)

TPTab:CreateToggle({
    Name = "📍 Enable TP Attack System",
    CurrentValue = Settings.TPAttackEnabled,
    Flag = "TPAttackEnabled",
    Callback = function(value)
        Settings.TPAttackEnabled = value
    end
})

TPTab:CreateToggle({
    Name = "⚡ Auto Chain Kill",
    CurrentValue = Settings.TPAutoChain,
    Flag = "TPAutoChain",
    Callback = function(value)
        Settings.TPAutoChain = value
    end
})

TPTab:CreateSlider({
    Name = "Chain Targets (1-10)",
    Range = {1, 10},
    Increment = 1,
    Suffix = " enemies",
    CurrentValue = Settings.TPChainTargets,
    Flag = "TPChainTargets",
    Callback = function(value)
        Settings.TPChainTargets = value
    end
})

TPTab:CreateButton({
    Name = "🔥 Execute Chain TP Attack",
    Callback = function()
        TPAttackSystem:PerformChainAttack("gun")
    end
})

-- Crosshair Tab
local CrosshairTab = Window:CreateTab("🎯 Crosshair", 4483362458)

CrosshairTab:CreateToggle({
    Name = "✅ Enable Advanced Crosshair",
    CurrentValue = Settings.CrosshairEnabled,
    Flag = "CrosshairEnabled",
    Callback = function(value)
        Settings.CrosshairEnabled = value
        CrosshairSystem:UpdateCrosshair()
    end
})

CrosshairTab:CreateDropdown({
    Name = "Crosshair Preset",
    Options = {"Cross", "T", "X", "Circle"},
    CurrentOption = Settings.CrosshairPreset,
    Flag = "CrosshairPreset",
    Callback = function(value)
        Settings.CrosshairPreset = value
        CrosshairSystem:Initialize()
    end
})

CrosshairTab:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Settings.CrosshairColor,
    Flag = "CrosshairColor",
    Callback = function(value)
        Settings.CrosshairColor = value
        CrosshairSystem:UpdateCrosshair()
    end
})

CrosshairTab:CreateSlider({
    Name = "Crosshair Size",
    Range = {5, 50},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.CrosshairSize,
    Flag = "CrosshairSize",
    Callback = function(value)
        Settings.CrosshairSize = value
        CrosshairSystem:Initialize()
    end
})

CrosshairTab:CreateSlider({
    Name = "Center Gap",
    Range = {0, 30},
    Increment = 1,
    Suffix = "px",
    CurrentValue = Settings.CrosshairGap,
    Flag = "CrosshairGap",
    Callback = function(value)
        Settings.CrosshairGap = value
        CrosshairSystem:UpdateCrosshair()
    end
})

-- Combat Tab
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

CombatTab:CreateToggle({
    Name = "🔫 Auto Kill (Team Check)",
    CurrentValue = Settings.AutoKill,
    Flag = "AutoKill",
    Callback = function(value)
        Settings.AutoKill = value
    end
})

CombatTab:CreateToggle({
    Name = "🎯 Auto Headshot (Team Check)",
    CurrentValue = Settings.AutoHeadshot,
    Flag = "AutoHeadshot",
    Callback = function(value)
        Settings.AutoHeadshot = value
    end
})

CombatTab:CreateToggle({
    Name = "🌀 Kill Aura (Team Check)",
    CurrentValue = Settings.KillAura,
    Flag = "KillAura",
    Callback = function(value)
        Settings.KillAura = value
    end
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range (0-500)",
    Range = {0, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Settings.KillAuraRange,
    Flag = "KillAuraRange",
    Callback = function(value)
        Settings.KillAuraRange = value
    end
})

-- Movement Tab
local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)

MovementTab:CreateToggle({
    Name = "🎯 Crosshair TP",
    CurrentValue = Settings.CrosshairTP,
    Flag = "CrosshairTP",
    Callback = function(value)
        Settings.CrosshairTP = value
    end
})

MovementTab:CreateParagraph({
    Title = "📱 Mobile Controls",
    Content = "• Single Tap: TP Attack nearest enemy\n• Long Press (0.5s): Chain TP Attack\n• Double Tap: Cancel target\n• Crosshair Button: TP to crosshair"
})

-- ========================================
-- Initialization
-- ========================================
-- クロスヘア初期化
task.wait(1)
CrosshairSystem:Initialize()

-- モバイルシステム初期化
if UserInputService.TouchEnabled then
    MobileSystem:Initialize()
end

-- チームキャッシュ更新
TeamSystem:UpdateTeamCache()

-- ========================================
-- Main Loop
-- ========================================
RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- パフォーマンス制御
    if now - State.LastUpdate < State.UpdateInterval then
        return
    end
    State.LastUpdate = now
    
    -- クロスヘア更新
    if Settings.CrosshairEnabled then
        CrosshairSystem:UpdateCrosshair()
    end
    
    -- オート機能
    if Settings.AutoKill then
        CombatSystem:AutoKill()
    end
    
    if Settings.AutoHeadshot then
        CombatSystem:AutoHeadshot()
    end
    
    if Settings.KillAura then
        CombatSystem:KillAura()
    end
    
    -- クロスヘアTP
    if Settings.CrosshairTP and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if not UserInputService.TouchEnabled then
            -- PC用クロスヘアTP
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local unitRay = Camera:ScreenPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local raycastResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 500)
                if raycastResult then
                    hrp.CFrame = CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0))
                end
            end
        end
    end
end)

-- ========================================
-- Cleanup
-- ========================================
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then
        -- 全ての接続を切断
        for _, conn in pairs(State.Connections) do
            if conn then
                conn:Disconnect()
            end
        end
        
        -- GUIを削除
        if State.CrosshairGui then
            State.CrosshairGui:Destroy()
        end
        
        if State.MobileUI then
            State.MobileUI:Destroy()
        end
        
        -- 状態をリセット
        State.IsTPAttacking = false
        State.TargetQueue = {}
    end
end)

-- ========================================
-- Final Notification
-- ========================================
Rayfield:Notify({
    Title = "⚡ Arsenal Ultimate v4.0",
    Content = "System Loaded Successfully!\n• Advanced TP Attack System\n• Ultimate Crosshair System\n• Mobile Integration Ready\n• Team Check: ALWAYS ACTIVE",
    Duration = 6,
    Image = 4483362458
})

print("╔══════════════════════════════════════╗")
print("║   ARSENAL ULTIMATE v4.0 LOADED       ║")
print("╠══════════════════════════════════════╣")
print("║ • Advanced TP Attack System          ║")
print("║ • Ultimate Crosshair System          ║")
print("║ • Mobile Integration                 ║")
print("║ • Team Check: ALWAYS ACTIVE          ║")
print("║ • Chain Kill: " targets max          ║")
print("╚══════════════════════════════════════╝")
