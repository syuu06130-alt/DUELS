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
local TweenService = game:GetService("TweenService")

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
    TPMaxTargets = 4,  -- 最大TP攻撃人数
    
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
    JumpPower = 50,
    
    -- Crosshair Settings
    CrosshairEnabled = true,
    CrosshairColor = Color3.fromRGB(255, 255, 255),
    CrosshairSize = 12,
    CrosshairThicknessH = 1,
    CrosshairThicknessV = 1,
    CrosshairGap = 3,
    CrosshairRotation = 90,
    CrosshairOpacity = 100,
    CrosshairDot = true,
    DotSize = 2,
    CrosshairOutline = true,
    OutlineThickness = 1,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    DynamicCrosshair = false,
    CrosshairPreset = "Cross",
    CrosshairOffsetX = 0,
    CrosshairOffsetY = 0,
    WeaponSpecificCrosshair = false
}

-- 武器別クロスヘア設定
local WeaponCrosshairPresets = {
    SR = {Size = 8, Gap = 2, Thickness = 1},      -- スナイパー
    AR = {Size = 12, Gap = 3, Thickness = 1.5},   -- アサルト
    SMG = {Size = 15, Gap = 4, Thickness = 2},    -- SMG
    HG = {Size = 10, Gap = 2, Thickness = 1}      -- ハンドガン
}

local State = {
    Target = nil,
    OriginalPosition = nil,
    IsTPAttacking = false,
    LastTapTime = 0,
    TapCount = 0,
    TPQueue = {},  -- TP攻撃キュー
    CurrentTPIndex = 1,
    CrosshairObject = nil,
    ActiveWeaponType = "AR"
}

local Connections = {}
local ESPObjects = {}
local OriginalValues = {
    WalkSpeed = 16,
    JumpPower = 50
}

-- ========================================
-- Crosshair System
-- ========================================
local function CreateCrosshair()
    if State.CrosshairObject then
        State.CrosshairObject:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AdvancedCrosshair"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    
    -- 中心ドット
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Size = UDim2.new(0, Settings.DotSize, 0, Settings.DotSize)
    dot.Position = UDim2.new(0.5, Settings.CrosshairOffsetX, 0.5, Settings.CrosshairOffsetY)
    dot.BackgroundColor3 = Settings.CrosshairColor
    dot.BackgroundTransparency = 1 - (Settings.CrosshairOpacity / 100)
    dot.BorderSizePixel = 0
    dot.Visible = Settings.CrosshairDot
    dot.Parent = screenGui
    
    if Settings.CrosshairOutline and Settings.CrosshairDot then
        local outline = Instance.new("UIStroke")
        outline.Color = Settings.OutlineColor
        outline.Thickness = Settings.OutlineThickness
        outline.Parent = dot
    end
    
    -- クロスヘアラインを作成
    local function createLine(name, size, position, rotation, thickness)
        local line = Instance.new("Frame")
        line.Name = name
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Size = size
        line.Position = position
        line.Rotation = rotation
        line.BackgroundColor3 = Settings.CrosshairColor
        line.BackgroundTransparency = 1 - (Settings.CrosshairOpacity / 100)
        line.BorderSizePixel = 0
        line.Parent = screenGui
        
        if Settings.CrosshairOutline then
            local outline = Instance.new("UIStroke")
            outline.Color = Settings.OutlineColor
            outline.Thickness = Settings.OutlineThickness
            outline.Parent = line
        end
        
        return line
    end
    
    local size = Settings.CrosshairSize
    local gap = Settings.CrosshairGap
    local centerX = 0.5 + (Settings.CrosshairOffsetX / Camera.ViewportSize.X)
    local centerY = 0.5 + (Settings.CrosshairOffsetY / Camera.ViewportSize.Y)
    
    -- プリセットに基づいて形状を作成
    if Settings.CrosshairPreset == "Cross" then
        -- 上ライン
        createLine(
            "TopLine",
            UDim2.new(0, Settings.CrosshairThicknessH, 0, size),
            UDim2.new(centerX, 0, centerY, -gap - size/2),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessV
        )
        -- 下ライン
        createLine(
            "BottomLine",
            UDim2.new(0, Settings.CrosshairThicknessH, 0, size),
            UDim2.new(centerX, 0, centerY, gap + size/2),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessV
        )
        -- 左ライン
        createLine(
            "LeftLine",
            UDim2.new(0, size, 0, Settings.CrosshairThicknessV),
            UDim2.new(centerX, -gap - size/2, centerY, 0),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessH
        )
        -- 右ライン
        createLine(
            "RightLine",
            UDim2.new(0, size, 0, Settings.CrosshairThicknessV),
            UDim2.new(centerX, gap + size/2, centerY, 0),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessH
        )
    elseif Settings.CrosshairPreset == "T" then
        -- 上ライン
        createLine(
            "TopLine",
            UDim2.new(0, Settings.CrosshairThicknessH, 0, size),
            UDim2.new(centerX, 0, centerY, -gap - size/2),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessV
        )
        -- 下ライン
        createLine(
            "BottomLine",
            UDim2.new(0, Settings.CrosshairThicknessH, 0, size/2),
            UDim2.new(centerX, 0, centerY, gap),
            Settings.CrosshairRotation,
            Settings.CrosshairThicknessV
        )
    elseif Settings.CrosshairPreset == "X" then
        -- 左上-右下ライン
        createLine(
            "Line1",
            UDim2.new(0, math.sqrt(2*size*size), 0, Settings.CrosshairThicknessH),
            UDim2.new(centerX, 0, centerY, 0),
            Settings.CrosshairRotation + 45,
            Settings.CrosshairThicknessV
        )
        -- 右上-左下ライン
        createLine(
            "Line2",
            UDim2.new(0, math.sqrt(2*size*size), 0, Settings.CrosshairThicknessH),
            UDim2.new(centerX, 0, centerY, 0),
            Settings.CrosshairRotation - 45,
            Settings.CrosshairThicknessV
        )
    elseif Settings.CrosshairPreset == "Circle" then
        local circle = Instance.new("Frame")
        circle.Name = "Circle"
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.Size = UDim2.new(0, size*2, 0, size*2)
        circle.Position = UDim2.new(centerX, 0, centerY, 0)
        circle.BackgroundTransparency = 1
        circle.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = Settings.CrosshairColor
        stroke.Thickness = Settings.CrosshairThicknessH
        stroke.Transparency = 1 - (Settings.CrosshairOpacity / 100)
        stroke.Parent = circle
        
        if Settings.CrosshairOutline then
            local outline = Instance.new("UIStroke")
            outline.Color = Settings.OutlineColor
            outline.Thickness = Settings.OutlineThickness
            outline.Parent = circle
        end
    end
    
    State.CrosshairObject = screenGui
end

local function UpdateCrosshair()
    if not State.CrosshairObject then return end
    
    -- 動的クロスヘア（移動・ジャンプ時）
    if Settings.DynamicCrosshair and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            local speed = humanoid.MoveDirection.Magnitude
            local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
            
            if speed > 0 or isJumping then
                State.CrosshairObject.Dot.Size = UDim2.new(
                    0, Settings.DotSize + 2,
                    0, Settings.DotSize + 2
                )
            else
                State.CrosshairObject.Dot.Size = UDim2.new(
                    0, Settings.DotSize,
                    0, Settings.DotSize
                )
            end
        end
    end
    
    -- 武器別クロスヘア
    if Settings.WeaponSpecificCrosshair then
        local preset = WeaponCrosshairPresets[State.ActiveWeaponType] or WeaponCrosshairPresets.AR
        
        for _, child in pairs(State.CrosshairObject:GetChildren()) do
            if child:IsA("Frame") and child.Name ~= "Dot" then
                if child.Name:find("Line") then
                    -- サイズと太さを更新
                    if child.Name:find("Top") or child.Name:find("Bottom") then
                        child.Size = UDim2.new(0, Settings.CrosshairThicknessH, 0, preset.Size)
                    else
                        child.Size = UDim2.new(0, preset.Size, 0, Settings.CrosshairThicknessV)
                    end
                end
            end
        end
        
        -- ギャップを更新
        Settings.CrosshairGap = preset.Gap
    end
end

local function ToggleCrosshair(enable)
    if enable then
        CreateCrosshair()
        Connections.CrosshairUpdate = RunService.Heartbeat:Connect(UpdateCrosshair)
    else
        if State.CrosshairObject then
            State.CrosshairObject:Destroy()
            State.CrosshairObject = nil
        end
        if Connections.CrosshairUpdate then
            Connections.CrosshairUpdate:Disconnect()
            Connections.CrosshairUpdate = nil
        end
    end
end

-- ========================================
-- Utility Functions (Updated with Team Check)
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
    if IsAlly(player) then return false end  -- チームチェックを追加
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
        if IsValidTarget(player) then  -- チームチェックを追加
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

-- 有効な敵プレイヤーをすべて取得（TP攻撃キュー用）
local function GetAllValidTargets(limit)
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then  -- チームチェックを追加
            table.insert(targets, player)
            if limit and #targets >= limit then
                break
            end
        end
    end
    return targets
end

local function SafeTP(targetCFrame)
    if not LocalPlayer.Character then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    hrp.CFrame = targetCFrame
    return true
end

-- ========================================
-- Enhanced TP Attack System with Team Check
-- ========================================
local function GetBehindPosition(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return nil end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return nil end
    
    local behindOffset = targetHRP.CFrame.LookVector * -Settings.TPOffset.Z
    local behindCFrame = targetHRP.CFrame * CFrame.new(0, Settings.TPOffset.Y, Settings.TPOffset.Z)
    
    return behindCFrame
end

local function PerformTPAttack(targetPlayer, attackType)
    if State.IsTPAttacking then return end
    if not LocalPlayer.Character then return end
    
    -- チームチェック
    if IsAlly(targetPlayer) then return end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    State.IsTPAttacking = true
    State.OriginalPosition = hrp.CFrame
    
    local behindPos = GetBehindPosition(targetPlayer)
    if not behindPos then
        State.IsTPAttacking = false
        return
    end
    
    SafeTP(behindPos)
    
    task.spawn(function()
        task.wait(0.05)
        
        if attackType == "gun" then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local head = targetPlayer.Character:FindFirstChild("Head")
                if head then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    
                    local killRemote = tool:FindFirstChild("kill")
                    local fireRemote = tool:FindFirstChild("fire")
                    
                    if killRemote then
                        local direction = (head.Position - tool.Handle.Position).Unit
                        killRemote:FireServer(targetPlayer, direction)
                    end
                    
                    if fireRemote then
                        fireRemote:FireServer()
                    end
                    
                    tool:Activate()
                end
            end
            
        elseif attackType == "knife" then
            local knife = LocalPlayer.Character:FindFirstChild("Knife")
            if knife then
                local head = targetPlayer.Character:FindFirstChild("Head")
                if head then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
                    
                    local slashRemote = knife:FindFirstChild("Slash")
                    if slashRemote then
                        slashRemote:FireServer()
                        knife:Activate()
                    end
                    
                    if Settings.AutoThrow then
                        local throwRemote = knife:FindFirstChild("Throw")
                        if throwRemote then
                            throwRemote:InvokeServer(head.Position)
                        end
                    end
                end
            end
            
        elseif attackType == "throw" then
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
        
        task.wait(Settings.TPDuration)
        
        if State.OriginalPosition then
            SafeTP(State.OriginalPosition)
        end
        
        State.IsTPAttacking = false
        
        -- 次のターゲットに攻撃（マルチターゲット機能）
        if #State.TPQueue > 0 then
            local nextTarget = table.remove(State.TPQueue, 1)
            if nextTarget and nextTarget.Character then
                task.wait(0.5)  -- 次の攻撃までの遅延
                PerformTPAttack(nextTarget, attackType)
            end
        end
    end)
end

-- ========================================
-- Enhanced Combat Functions with Team Check
-- ========================================
local function AutoKill()
    if not Settings.AutoKill or State.IsTPAttacking then return end
    
    -- 最大TPTargetsまでの敵を取得
    local targets = GetAllValidTargets(Settings.TPMaxTargets)
    if #targets == 0 then return end
    
    if Settings.TPAttackEnabled then
        -- キューにターゲットを追加
        State.TPQueue = targets
        PerformTPAttack(State.TPQueue[1], "gun")
        table.remove(State.TPQueue, 1)
    else
        -- 通常の攻撃（単体）
        local target = targets[1]
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
end

local function ApplyAutoHeadshot()
    if not Settings.AutoHeadshot or State.IsTPAttacking then return end
    
    local targets = GetAllValidTargets(Settings.TPMaxTargets)
    if #targets == 0 then return end
    
    local target = targets[1]
    if target and target.Character then
        if Settings.TPAttackEnabled then
            State.TPQueue = targets
            PerformTPAttack(State.TPQueue[1], "gun")
            table.remove(State.TPQueue, 1)
        else
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end

local function AutoThrow()
    if not Settings.AutoThrow or State.IsTPAttacking then return end
    
    local targets = GetAllValidTargets(Settings.TPMaxTargets)
    if #targets == 0 then return end
    
    local target = targets[1]
    if target and target.Character then
        if Settings.TPAttackEnabled then
            State.TPQueue = targets
            PerformTPAttack(State.TPQueue[1], "throw")
            table.remove(State.TPQueue, 1)
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

local function KillAura()
    if not Settings.KillAura or State.IsTPAttacking then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then  -- チームチェックを追加
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

-- ========================================
-- Enhanced Crosshair TP System
-- ========================================
local function CrosshairTP()
    if not LocalPlayer.Character or not Settings.CrosshairEnabled then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- クロスヘアの位置からレイキャスト
    local viewportSize = Camera.ViewportSize
    local crosshairPos = Vector2.new(
        viewportSize.X / 2 + Settings.CrosshairOffsetX,
        viewportSize.Y / 2 + Settings.CrosshairOffsetY
    )
    
    -- スクリーン座標からワールド座標への変換
    local unitRay = Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
    local direction = unitRay.Direction * 1000
    local origin = unitRay.Origin
    
    -- レイキャストでヒット位置を取得
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    
    if raycastResult then
        SafeTP(CFrame.new(raycastResult.Position + Vector3.new(0, 3, 0)))
    else
        -- ヒットしない場合は方向にTP
        local targetPos = origin + direction.Unit * 50
        SafeTP(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
    end
end

-- ========================================
-- Mobile Crosshair TP Integration
-- ========================================
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    ScreenGui.Name = "MobileCrosshairSystem"
    ScreenGui.ResetOnSpawn = false
    
    -- クロスヘア表示用のフレーム
    local CrosshairFrame = Instance.new("Frame", ScreenGui)
    CrosshairFrame.Size = UDim2.new(0, 100, 0, 100)
    CrosshairFrame.Position = UDim2.new(0.5, -50, 0.5, -50)
    CrosshairFrame.BackgroundTransparency = 1
    
    -- モバイル用TPボタン
    local TPBtn = Instance.new("TextButton", ScreenGui)
    TPBtn.Size = UDim2.new(0, 80, 0, 80)
    TPBtn.Position = UDim2.new(1, -150, 1, -260)
    TPBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TPBtn.BorderSizePixel = 3
    TPBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.Text = "TP\n<Crosshair>"
    TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPBtn.TextSize = 16
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
            -- 長押し：ターゲットロック
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
            -- ダブルタップ：ターゲット解除
            State.Target = nil
            State.TapCount = 0
        else
            -- シングルタップ：クロスヘア位置にTP
            State.TapCount = 1
            State.LastTapTime = currentTime
            CrosshairTP()
            
            task.delay(0.3, function()
                State.TapCount = 0
            end)
        end
    end)
    
    -- モバイル用クロスヘア描画
    local function CreateMobileCrosshair()
        CrosshairFrame:ClearAllChildren()
        
        if not Settings.CrosshairEnabled then return end
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, Settings.DotSize, 0, Settings.DotSize)
        dot.Position = UDim2.new(0.5, -Settings.DotSize/2, 0.5, -Settings.DotSize/2)
        dot.BackgroundColor3 = Settings.CrosshairColor
        dot.BackgroundTransparency = 1 - (Settings.CrosshairOpacity / 100)
        dot.BorderSizePixel = 0
        dot.Visible = Settings.CrosshairDot
        dot.Parent = CrosshairFrame
        
        -- クロスヘアライン（簡易版）
        local line1 = Instance.new("Frame")
        line1.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThicknessH)
        line1.Position = UDim2.new(0.5, -Settings.CrosshairSize/2, 0.5, -Settings.CrosshairGap)
        line1.BackgroundColor3 = Settings.CrosshairColor
        line1.BackgroundTransparency = 1 - (Settings.CrosshairOpacity / 100)
        line1.Rotation = Settings.CrosshairRotation
        line1.Parent = CrosshairFrame
        
        local line2 = Instance.new("Frame")
        line2.Size = UDim2.new(0, Settings.CrosshairSize, 0, Settings.CrosshairThicknessH)
        line2.Position = UDim2.new(0.5, -Settings.CrosshairSize/2, 0.5, Settings.CrosshairGap)
        line2.BackgroundColor3 = Settings.CrosshairColor
        line2.BackgroundTransparency = 1 - (Settings.CrosshairOpacity / 100)
        line2.Rotation = Settings.CrosshairRotation
        line2.Parent = CrosshairFrame
    end
    
    CreateMobileCrosshair()
    
    -- モバイルクロスヘア更新
    Connections.MobileCrosshairUpdate = RunService.Heartbeat:Connect(function()
        if Settings.CrosshairEnabled then
            CreateMobileCrosshair()
        else
            CrosshairFrame:ClearAllChildren()
        end
    end)
end

-- ========================================
-- Rayfield UI - Enhanced Crosshair Tab
-- ========================================
local Window = Rayfield:CreateWindow({
    Name = "🎮 Arsenal Advanced Script Hub v3.0",
    LoadingTitle = "Enhanced Crosshair System Loading...",
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
-- ⚔️ Combat Tab (Updated with Team Check)
-- ========================================
local CombatTab = Window:CreateTab("⚔️ Combat", 4483362458)

local TPAttackSection = CombatTab:CreateSection("📍 Enhanced TP Attack")

CombatTab:CreateToggle({
    Name = "📍 Enable TP Attack",
    CurrentValue = true,
    Flag = "TPAttackEnabled",
    Callback = function(Value)
        Settings.TPAttackEnabled = Value
    end
})

CombatTab:CreateSlider({
    Name = "Max TP Targets (1-10)",
    Range = {1, 10},
    Increment = 1,
    Suffix = " targets",
    CurrentValue = 4,
    Flag = "TPMaxTargets",
    Callback = function(Value)
        Settings.TPMaxTargets = Value
    end
})

CombatTab:CreateToggle({
    Name = "👥 Team Check (TP Attack)",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end
})

local AutoKillSection = CombatTab:CreateSection("🔫 Auto Kill Features")

CombatTab:CreateToggle({
    Name = "🔫 Auto Kill (Team Check)",
    CurrentValue = false,
    Flag = "AutoKill",
    Callback = function(Value)
        Settings.AutoKill = Value
    end
})

CombatTab:CreateToggle({
    Name = "🎯 Auto Headshot (Team Check)",
    CurrentValue = false,
    Flag = "AutoHeadshot",
    Callback = function(Value)
        Settings.AutoHeadshot = Value
    end
})

CombatTab:CreateToggle({
    Name = "🔪 Auto Throw (Team Check)",
    CurrentValue = false,
    Flag = "AutoThrow",
    Callback = function(Value)
        Settings.AutoThrow = Value
    end
})

local KillAuraSection = CombatTab:CreateSection("🌀 Kill Aura (Team Check)")

CombatTab:CreateToggle({
    Name = "🌀 Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        Settings.KillAura = Value
    end
})

CombatTab:CreateSlider({
    Name = "Kill Aura Range (0-500)",
    Range = {0, 500},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "KillAuraRange",
    Callback = function(Value)
        Settings.KillAuraRange = Value
    end
})

-- ========================================
-- 🎯 Crosshair Tab
-- ========================================
local CrosshairTab = Window:CreateTab("🎯 Crosshair", 4483362458)

local CrosshairMainSection = CrosshairTab:CreateSection("🎯 Main Settings")

CrosshairTab:CreateToggle({
    Name = "🎯 Enable Crosshair",
    CurrentValue = true,
    Flag = "CrosshairEnabled",
    Callback = function(Value)
        Settings.CrosshairEnabled = Value
        ToggleCrosshair(Value)
    end
})

CrosshairTab:CreateColorPicker({
    Name = "Crosshair Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "CrosshairColor",
    Callback = function(Value)
        Settings.CrosshairColor = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Crosshair Size",
    Range = {5, 50},
    Increment = 1,
    Suffix = " px",
    CurrentValue = 12,
    Flag = "CrosshairSize",
    Callback = function(Value)
        Settings.CrosshairSize = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Center Gap",
    Range = {0, 20},
    Increment = 1,
    Suffix = " px",
    CurrentValue = 3,
    Flag = "CrosshairGap",
    Callback = function(Value)
        Settings.CrosshairGap = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Rotation (0°-360°)",
    Range = {0, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 90,
    Flag = "CrosshairRotation",
    Callback = function(Value)
        Settings.CrosshairRotation = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Opacity",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "CrosshairOpacity",
    Callback = function(Value)
        Settings.CrosshairOpacity = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

local LineThicknessSection = CrosshairTab:CreateSection("📏 Line Thickness")

CrosshairTab:CreateSlider({
    Name = "Horizontal Line Thickness",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " px",
    CurrentValue = 1,
    Flag = "CrosshairThicknessH",
    Callback = function(Value)
        Settings.CrosshairThicknessH = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Vertical Line Thickness",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " px",
    CurrentValue = 1,
    Flag = "CrosshairThicknessV",
    Callback = function(Value)
        Settings.CrosshairThicknessV = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

local DotSection = CrosshairTab:CreateSection("🔘 Center Dot")

CrosshairTab:CreateToggle({
    Name = "Show Center Dot",
    CurrentValue = true,
    Flag = "CrosshairDot",
    Callback = function(Value)
        Settings.CrosshairDot = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Dot Size",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = " px",
    CurrentValue = 2,
    Flag = "DotSize",
    Callback = function(Value)
        Settings.DotSize = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

local OutlineSection = CrosshairTab:CreateSection("🖌️ Outline")

CrosshairTab:CreateToggle({
    Name = "Enable Outline",
    CurrentValue = true,
    Flag = "CrosshairOutline",
    Callback = function(Value)
        Settings.CrosshairOutline = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Outline Thickness",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = " px",
    CurrentValue = 1,
    Flag = "OutlineThickness",
    Callback = function(Value)
        Settings.OutlineThickness = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateColorPicker({
    Name = "Outline Color",
    Color = Color3.fromRGB(0, 0, 0),
    Flag = "OutlineColor",
    Callback = function(Value)
        Settings.OutlineColor = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

local AdvancedSection = CrosshairTab:CreateSection("⚙️ Advanced Settings")

CrosshairTab:CreateToggle({
    Name = "Dynamic Crosshair",
    CurrentValue = false,
    Flag = "DynamicCrosshair",
    Callback = function(Value)
        Settings.DynamicCrosshair = Value
    end
})

CrosshairTab:CreateToggle({
    Name = "Weapon-Specific Crosshair",
    CurrentValue = false,
    Flag = "WeaponSpecificCrosshair",
    Callback = function(Value)
        Settings.WeaponSpecificCrosshair = Value
    end
})

CrosshairTab:CreateDropdown({
    Name = "Crosshair Preset",
    Options = {"Cross", "T", "X", "Circle"},
    CurrentOption = "Cross",
    Flag = "CrosshairPreset",
    Callback = function(Value)
        Settings.CrosshairPreset = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Horizontal Offset",
    Range = {-100, 100},
    Increment = 1,
    Suffix = " px",
    CurrentValue = 0,
    Flag = "CrosshairOffsetX",
    Callback = function(Value)
        Settings.CrosshairOffsetX = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

CrosshairTab:CreateSlider({
    Name = "Vertical Offset",
    Range = {-100, 100},
    Increment = 1,
    Suffix = " px",
    CurrentValue = 0,
    Flag = "CrosshairOffsetY",
    Callback = function(Value)
        Settings.CrosshairOffsetY = Value
        ToggleCrosshair(Settings.CrosshairEnabled)
    end
})

-- ========================================
-- 🏃 Movement Tab (Updated with Crosshair TP)
-- ========================================
local MovementTab = Window:CreateTab("🏃 Movement", 4483362458)

local TPSection = MovementTab:CreateSection("🎯 Teleportation")

MovementTab:CreateToggle({
    Name = "🎯 Crosshair TP (Right Click)",
    CurrentValue = false,
    Flag = "CrosshairTP",
    Callback = function(Value)
        Settings.CrosshairTP = Value
    end
})

MovementTab:CreateParagraph({
    Title = "📱 Mobile Crosshair TP",
    Content = "• TP Button uses Crosshair position\n• Single Tap: TP to crosshair\n• Long Press: Target lock\n• Double Tap: Release lock"
})

-- ========================================
-- Main Loop with Crosshair Integration
-- ========================================
Connections.MainLoop = RunService.Heartbeat:Connect(function()
    -- Combat with Team Check
    if Settings.AutoKill then AutoKill() end
    if Settings.AutoHeadshot then ApplyAutoHeadshot() end
    if Settings.AutoThrow then AutoThrow() end
    if Settings.KillAura then KillAura() end
    
    -- Crosshair TP
    if Settings.CrosshairTP and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        CrosshairTP()
    end
end)

-- ========================================
-- Initialization
-- ========================================
task.wait(1)
ToggleCrosshair(Settings.CrosshairEnabled)

Rayfield:Notify({
    Title = "🎮 Enhanced Arsenal Script v3.0",
    Content = "Features Loaded:\n• Team-Check TP Attack System\n• Advanced Crosshair System\n• Mobile Crosshair TP\n• Multi-Target TP (1-10)\n• Kill Aura Range 0-500",
    Duration = 6,
    Image = 4483362458
})

print("Arsenal Advanced Script v3.0 loaded successfully!")
print("Enhanced Features:")
print("- Team Check on ALL auto-attack functions")
print("- Advanced Crosshair System with 15+ settings")
print("- Multi-Target TP Attack System (Max: " .. Settings.TPMaxTargets .. ")")
print("- Mobile Crosshair TP Integration")
print("- Kill Aura Range: 0-500 studs")
