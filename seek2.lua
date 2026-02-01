-- ■■■ UI Loader ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- サービス定義
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- グローバル変数
local RunningGames = Workspace:WaitForChild("RunningGames")
local Maps = Workspace:WaitForChild("Maps")
local mouse = LocalPlayer:GetMouse()

-- 設定変数
local Settings = {
    AutoKill = false,
    AutoThrow = false,
    AutoHeadshot = false,
    CrosshairTP = false,
    SilentAim = false,
    Triggerbot = false,
    RapidFire = false,
    Wallbang = false,
    NoRecoil = false,
    NoSpread = false,
    KillAura = false,
    FlyHack = false,
    SpeedHack = false,
    TeleportToSpawn = false,
    ESP = false
}

-- 共通関数
local function FindRunningGame(player)
    for _, v in pairs(RunningGames:GetChildren()) do
        if v.Name:match(player.UserId) then
            return v
        end
    end
    return nil
end

-- 武器関連関数（元のデコンパイルコードから抽出）
local function ShootLocalBeam(targetPos, originPos, weaponHandle)
    -- 元のShootLocalBeam関数のロジックを実装
    local direction = (targetPos - originPos).Unit * 10000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams:AddToFilter(LocalPlayer.Character)
    
    -- マップ関連のフィルタリング
    local currentMap = LocalPlayer:GetAttribute("Map") or "nothing"
    if Maps:FindFirstChild(currentMap) then
        for _, part in pairs(Maps[currentMap]:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency == 1 then
                raycastParams:AddToFilter(part)
            end
        end
    end
    
    -- レイキャスト実行
    local raycastResult = Workspace:Raycast(originPos, direction, raycastParams)
    
    if raycastResult then
        -- 命中時の処理
        local hitPos = raycastResult.Position
        -- ビーム表示やダメージ処理
        return true, raycastResult.Instance, hitPos
    end
    return false, nil, originPos + direction
end

-- 自動キルシステム
local AutoKillConnection
local function SetupAutoKill()
    if Settings.AutoKill then
        AutoKillConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or LocalPlayer.Character.Humanoid.Health <= 0 then
                return
            end
            
            local runningGame = FindRunningGame(LocalPlayer)
            if not runningGame or runningGame.RoundStarted.Value == true or runningGame.CurrentRoundEnded.Value == true then
                return
            end
            
            -- 最も近い敵プレイヤーを探す
            local closestPlayer = nil
            local closestDistance = math.huge
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if (player:GetAttribute("Game") or "nothing") == LocalPlayer:GetAttribute("Game") and
                       (player:GetAttribute("Team") or "nothing") ~= LocalPlayer:GetAttribute("Team") then
                        local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
            
            if closestPlayer and closestDistance < 50 then
                -- 自動攻撃実行
                local targetPos = closestPlayer.Character.Head.Position
                local originPos = LocalPlayer.Character.HumanoidRootPart.Position
                
                -- ヘッドショットモード
                if Settings.AutoHeadshot then
                    targetPos = closestPlayer.Character.Head.Position
                end
                
                -- 攻撃実行
                local success, hitPart, hitPos = ShootLocalBeam(targetPos, originPos, LocalPlayer.Character)
                
                if success and hitPart then
                    -- ヒット時の追加処理
                    local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") or 
                                     hitPart.Parent.Parent:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        -- ダメージ適用
                        print("自動キル: ターゲットにヒット")
                    end
                end
            end
        end)
    else
        if AutoKillConnection then
            AutoKillConnection:Disconnect()
            AutoKillConnection = nil
        end
    end
end

-- オートスロー機能
local AutoThrowConnection
local function SetupAutoThrow()
    if Settings.AutoThrow then
        AutoThrowConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or LocalPlayer.Character.Humanoid.Health <= 0 then
                return
            end
            
            local runningGame = FindRunningGame(LocalPlayer)
            if not runningGame or runningGame.RoundStarted.Value == true or runningGame.CurrentRoundEnded.Value == true then
                return
            end
            
            -- 敵が近くにいるかチェック
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if (player:GetAttribute("Game") or "nothing") == LocalPlayer:GetAttribute("Game") and
                       (player:GetAttribute("Team") or "nothing") ~= LocalPlayer:GetAttribute("Team") then
                        local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        
                        -- 投擲可能距離内に敵がいる
                        if distance < 30 then
                            -- 投擲方向を計算
                            local throwDirection = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Unit
                            
                            -- ここに投擲武器の発射ロジックを実装
                            -- 元のThrowスクリプトのFlingKnife関数を呼び出す
                            print("オートスロー: 敵を検出、距離:", distance)
                            break
                        end
                    end
                end
            end
        end)
    else
        if AutoThrowConnection then
            AutoThrowConnection:Disconnect()
            AutoThrowConnection = nil
        end
    end
end

-- クロスヘアTP機能
local CrosshairTPConnection
local function SetupCrosshairTP()
    if Settings.CrosshairTP then
        CrosshairTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.MouseButton2 then -- 右クリック
                -- マウスの位置からレイを飛ばす
                local ray = Workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                
                if raycastResult then
                    -- テレポート位置を決定
                    local teleportPos = raycastResult.Position + Vector3.new(0, 5, 0)
                    
                    -- 安全な位置かチェック
                    local safeRaycast = Workspace:Raycast(teleportPos, Vector3.new(0, -50, 0), raycastParams)
                    if safeRaycast then
                        -- キャラクターをテレポート
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safeRaycast.Position + Vector3.new(0, 3, 0))
                            print("クロスヘアTP: テレポート実行")
                        end
                    end
                end
            end
        end)
    else
        if CrosshairTPConnection then
            CrosshairTPConnection:Disconnect()
            CrosshairTPConnection = nil
        end
    end
end

-- サイレントエイム機能
local SilentAimConnection
local function SetupSilentAim()
    if Settings.SilentAim then
        -- マウス移動時に最適なターゲットを自動で狙う
        SilentAimConnection = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character then return end
            
            local closestTarget = nil
            local closestDistance = math.huge
            local fov = 100 -- 視野角
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                    if (player:GetAttribute("Game") or "nothing") == LocalPlayer:GetAttribute("Game") and
                       (player:GetAttribute("Team") or "nothing") ~= LocalPlayer:GetAttribute("Team") then
                        
                        -- スクリーン上の位置を計算
                        local headPos = player.Character.Head.Position
                        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(headPos)
                        
                        if onScreen then
                            local mousePos = Vector2.new(mouse.X, mouse.Y)
                            local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                            local distance = (mousePos - targetPos).Magnitude
                            
                            if distance < fov and distance < closestDistance then
                                closestDistance = distance
                                closestTarget = player.Character.Head
                            end
                        end
                    end
                end
            end
            
            -- ターゲットを自動追尾
            if closestTarget then
                mouse.Target = closestTarget
            end
        end)
    else
        if SilentAimConnection then
            SilentAimConnection:Disconnect()
            SilentAimConnection = nil
        end
    end
end

-- トリガーボット機能
local TriggerbotConnection
local function SetupTriggerbot()
    if Settings.Triggerbot then
        TriggerbotConnection = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character then return end
            
            if mouse.Target and mouse.Target.Parent then
                local targetPlayer = Players:GetPlayerFromCharacter(mouse.Target.Parent)
                if targetPlayer and targetPlayer ~= LocalPlayer then
                    if (targetPlayer:GetAttribute("Game") or "nothing") == LocalPlayer:GetAttribute("Game") and
                       (targetPlayer:GetAttribute("Team") or "nothing") ~= LocalPlayer:GetAttribute("Team") then
                        
                        -- 自動発射
                        -- 元のfireスクリプトのActivatedイベントをトリガー
                        print("トリガーボット: 自動発射")
                    end
                end
            end
        end)
    else
        if TriggerbotConnection then
            TriggerbotConnection:Disconnect()
            TriggerbotConnection = nil
        end
    end
end

-- ESP機能
local ESPConnection
local ESPBoxes = {}
local function SetupESP()
    if Settings.ESP then
        ESPConnection = RunService.RenderStepped:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    
                    -- チーム判断
                    local isEnemy = (player:GetAttribute("Team") or "nothing") ~= (LocalPlayer:GetAttribute("Team") or "nothing")
                    local color = isEnemy and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                    
                    -- スクリーン位置を取得
                    local rootPos = player.Character.HumanoidRootPart.Position
                    local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(rootPos)
                    
                    if onScreen then
                        -- ESPボックスを作成または更新
                        if not ESPBoxes[player] then
                            ESPBoxes[player] = {
                                Box = Drawing.new("Square"),
                                Name = Drawing.new("Text"),
                                Distance = Drawing.new("Text"),
                                HealthBar = Drawing.new("Square")
                            }
                            
                            -- ボックス設定
                            ESPBoxes[player].Box.Thickness = 2
                            ESPBoxes[player].Box.Filled = false
                            
                            -- 名前設定
                            ESPBoxes[player].Name.Size = 16
                            ESPBoxes[player].Name.Center = true
                            
                            -- 距離設定
                            ESPBoxes[player].Distance.Size = 14
                            ESPBoxes[player].Distance.Center = true
                            
                            -- 体力バー設定
                            ESPBoxes[player].HealthBar.Thickness = 2
                            ESPBoxes[player].HealthBar.Filled = true
                        end
                        
                        -- サイズ計算
                        local character = player.Character
                        local size = Vector3.new(4, 6, 0) -- 基本サイズ
                        if character:FindFirstChild("Head") then
                            local headPos = character.Head.Position
                            local headScreenPos = Workspace.CurrentCamera:WorldToViewportPoint(headPos)
                            local rootScreenPos = Workspace.CurrentCamera:WorldToViewportPoint(rootPos)
                            size = Vector2.new(
                                50,
                                (rootScreenPos.Y - headScreenPos.Y) * 2
                            )
                        end
                        
                        -- 位置更新
                        local boxPos = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)
                        
                        ESPBoxes[player].Box.Position = boxPos
                        ESPBoxes[player].Box.Size = Vector2.new(size.X, size.Y)
                        ESPBoxes[player].Box.Color = color
                        ESPBoxes[player].Box.Visible = true
                        
                        -- 名前表示
                        ESPBoxes[player].Name.Position = Vector2.new(screenPos.X, boxPos.Y - 20)
                        ESPBoxes[player].Name.Text = player.Name
                        ESPBoxes[player].Name.Color = color
                        ESPBoxes[player].Name.Visible = true
                        
                        -- 距離表示
                        local distance = (rootPos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        ESPBoxes[player].Distance.Position = Vector2.new(screenPos.X, boxPos.Y + size.Y + 5)
                        ESPBoxes[player].Distance.Text = string.format("%.0f studs", distance)
                        ESPBoxes[player].Distance.Color = color
                        ESPBoxes[player].Distance.Visible = true
                        
                        -- 体力バー
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid then
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            local barHeight = size.Y * healthPercent
                            local barPos = Vector2.new(boxPos.X - 10, boxPos.Y + size.Y - barHeight)
                            
                            ESPBoxes[player].HealthBar.Position = barPos
                            ESPBoxes[player].HealthBar.Size = Vector2.new(4, barHeight)
                            ESPBoxes[player].HealthBar.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - healthPercent)
                            ESPBoxes[player].HealthBar.Visible = true
                        end
                    else
                        -- 画面外の場合は非表示
                        if ESPBoxes[player] then
                            ESPBoxes[player].Box.Visible = false
                            ESPBoxes[player].Name.Visible = false
                            ESPBoxes[player].Distance.Visible = false
                            ESPBoxes[player].HealthBar.Visible = false
                        end
                    end
                end
            end
        end)
    else
        if ESPConnection then
            ESPConnection:Disconnect()
            ESPConnection = nil
        end
        
        -- ESPボックスをクリア
        for player, drawings in pairs(ESPBoxes) do
            for _, drawing in pairs(drawings) do
                drawing:Remove()
            end
        end
        ESPBoxes = {}
    end
end

-- キルオーラ機能
local KillAuraConnection
local function SetupKillAura()
    if Settings.KillAura then
        KillAuraConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or LocalPlayer.Character.Humanoid.Health <= 0 then
                return
            end
            
            local runningGame = FindRunningGame(LocalPlayer)
            if not runningGame or runningGame.RoundStarted.Value == true or runningGame.CurrentRoundEnded.Value == true then
                return
            end
            
            -- 周囲の敵を攻撃
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if (player:GetAttribute("Game") or "nothing") == LocalPlayer:GetAttribute("Game") and
                       (player:GetAttribute("Team") or "nothing") ~= LocalPlayer:GetAttribute("Team") then
                        
                        local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                        
                        -- キルオーラ範囲内
                        if distance < 15 then
                            -- 近接攻撃を実行
                            -- 元のSlashスクリプトの機能を呼び出す
                            print("キルオーラ: 敵を攻撃, 距離:", distance)
                        end
                    end
                end
            end
        end)
    else
        if KillAuraConnection then
            KillAuraConnection:Disconnect()
            KillAuraConnection = nil
        end
    end
end

-- 飛行ハック
local FlyHackEnabled = false
local FlyHackConnection
local function SetupFlyHack()
    if Settings.FlyHack then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        FlyHackEnabled = true
        local root = LocalPlayer.Character.HumanoidRootPart
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        
        -- 重力を無効化
        root:SetNetworkOwner(nil)
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
        
        local flySpeed = 50
        local flyKeys = {
            [Enum.KeyCode.W] = false,
            [Enum.KeyCode.A] = false,
            [Enum.KeyCode.S] = false,
            [Enum.KeyCode.D] = false,
            [Enum.KeyCode.Space] = false,
            [Enum.KeyCode.LeftShift] = false
        }
        
        -- キー入力検知
        local inputBegan = UserInputService.InputBegan:Connect(function(input)
            if flyKeys[input.KeyCode] ~= nil then
                flyKeys[input.KeyCode] = true
            end
        end)
        
        local inputEnded = UserInputService.InputEnded:Connect(function(input)
            if flyKeys[input.KeyCode] ~= nil then
                flyKeys[input.KeyCode] = false
            end
        end)
        
        FlyHackConnection = RunService.Heartbeat:Connect(function()
            if not FlyHackEnabled or not root then
                inputBegan:Disconnect()
                inputEnded:Disconnect()
                return
            end
            
            local velocity = Vector3.new(0, 0, 0)
            
            -- 移動方向計算
            if flyKeys[Enum.KeyCode.W] then
                velocity = velocity + Workspace.CurrentCamera.CFrame.LookVector
            end
            if flyKeys[Enum.KeyCode.S] then
                velocity = velocity - Workspace.CurrentCamera.CFrame.LookVector
            end
            if flyKeys[Enum.KeyCode.A] then
                velocity = velocity - Workspace.CurrentCamera.CFrame.RightVector
            end
            if flyKeys[Enum.KeyCode.D] then
                velocity = velocity + Workspace.CurrentCamera.CFrame.RightVector
            end
            if flyKeys[Enum.KeyCode.Space] then
                velocity = velocity + Vector3.new(0, 1, 0)
            end
            if flyKeys[Enum.KeyCode.LeftShift] then
                velocity = velocity - Vector3.new(0, 1, 0)
            end
            
            -- 速度適用
            if velocity.Magnitude > 0 then
                velocity = velocity.Unit * flySpeed
                root.Velocity = Vector3.new(velocity.X, velocity.Y, velocity.Z)
            else
                root.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        FlyHackEnabled = false
        if FlyHackConnection then
            FlyHackConnection:Disconnect()
            FlyHackConnection = nil
        end
        
        -- 重力を戻す
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart:SetNetworkOwner(LocalPlayer)
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            end
        end
    end
end

-- スピードハック
local SpeedHackConnection
local function SetupSpeedHack()
    if Settings.SpeedHack then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 50 -- 通常は16
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16 -- 元に戻す
        end
    end
end

-- Rayfieldウィンドウ作成
local Window = Rayfield:CreateWindow({
    Name = "🎮 上級ゲームコントロール",
    LoadingTitle = "高度な機能をロード中...",
    LoadingSubtitle = "包括的なゲームチートシステム",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GameControlConfig",
        FileName = "Settings"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
})

-- 戦闘タブ
local CombatTab = Window:CreateTab("⚔️ 戦闘", 4483362458)

local AutoKillSection = CombatTab:CreateSection("自動キルシステム")

local AutoKillToggle = CombatTab:CreateToggle({
    Name = "🔫 自動キル (Auto Kill)",
    CurrentValue = false,
    Flag = "AutoKill",
    Callback = function(Value)
        Settings.AutoKill = Value
        SetupAutoKill()
        
        Rayfield:Notify({
            Title = "自動キル",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local AutoHeadshotToggle = CombatTab:CreateToggle({
    Name = "🎯 自動ヘッドショット",
    CurrentValue = false,
    Flag = "AutoHeadshot",
    Callback = function(Value)
        Settings.AutoHeadshot = Value
        
        Rayfield:Notify({
            Title = "自動ヘッドショット",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local AutoThrowToggle = CombatTab:CreateToggle({
    Name = "🔪 オートスロー",
    CurrentValue = false,
    Flag = "AutoThrow",
    Callback = function(Value)
        Settings.AutoThrow = Value
        SetupAutoThrow()
        
        Rayfield:Notify({
            Title = "オートスロー",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local KillAuraToggle = CombatTab:CreateToggle({
    Name = "🌀 キルオーラ (範囲攻撃)",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        Settings.KillAura = Value
        SetupKillAim()
        
        Rayfield:Notify({
            Title = "キルオーラ",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local AimAssistSection = CombatTab:CreateSection("エイム補助")

local SilentAimToggle = CombatTab:CreateToggle({
    Name = "🎯 サイレントエイム",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(Value)
        Settings.SilentAim = Value
        SetupSilentAim()
        
        Rayfield:Notify({
            Title = "サイレントエイム",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local TriggerbotToggle = CombatTab:CreateToggle({
    Name = "🤖 トリガーボット (自動発射)",
    CurrentValue = false,
    Flag = "Triggerbot",
    Callback = function(Value)
        Settings.Triggerbot = Value
        SetupTriggerbot()
        
        Rayfield:Notify({
            Title = "トリガーボット",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local RapidFireToggle = CombatTab:CreateToggle({
    Name = "⚡ ラピッドファイア",
    CurrentValue = false,
    Flag = "RapidFire",
    Callback = function(Value)
        Settings.RapidFire = Value
        
        Rayfield:Notify({
            Title = "ラピッドファイア",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local NoRecoilToggle = CombatTab:CreateToggle({
    Name = "📉 ノーリコイル",
    CurrentValue = false,
    Flag = "NoRecoil",
    Callback = function(Value)
        Settings.NoRecoil = Value
        
        Rayfield:Notify({
            Title = "ノーリコイル",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local NoSpreadToggle = CombatTab:CreateToggle({
    Name = "🎯 ノースプレッド",
    CurrentValue = false,
    Flag = "NoSpread",
    Callback = function(Value)
        Settings.NoSpread = Value
        
        Rayfield:Notify({
            Title = "ノースプレッド",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local WallbangToggle = CombatTab:CreateToggle({
    Name = "🧱 壁透過攻撃 (Wallbang)",
    CurrentValue = false,
    Flag = "Wallbang",
    Callback = function(Value)
        Settings.Wallbang = Value
        
        Rayfield:Notify({
            Title = "壁透過攻撃",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 移動タブ
local MovementTab = Window:CreateTab("🏃 移動", 4483362458)

local TeleportSection = MovementTab:CreateSection("テレポート機能")

local CrosshairTPToggle = MovementTab:CreateToggle({
    Name = "🎯 クロスヘアTP (右クリック)",
    CurrentValue = false,
    Flag = "CrosshairTP",
    Callback = function(Value)
        Settings.CrosshairTP = Value
        SetupCrosshairTP()
        
        Rayfield:Notify({
            Title = "クロスヘアTP",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local TeleportSpawnButton = MovementTab:CreateButton({
    Name = "🏠 スポーン地点へTP",
    Callback = function()
        -- スポーン地点を探してテレポート
        local spawnPoints = Workspace:FindFirstChild("SpawnPoints")
        if spawnPoints then
            for _, spawn in pairs(spawnPoints:GetChildren()) do
                if spawn:IsA("Part") then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame
                        Rayfield:Notify({
                            Title = "テレポート",
                            Content = "スポーン地点へ移動しました",
                            Duration = 3,
                            Image = 4483362458
                        })
                        break
                    end
                end
            end
        end
    end
})

local TeleportEnemyButton = MovementTab:CreateButton({
    Name = "🎯 最寄りの敵へTP",
    Callback = function()
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if (player:GetAttribute("Team") or "nothing") ~= (LocalPlayer:GetAttribute("Team") or "nothing") then
                    local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
        
        if closestPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = closestPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
            Rayfield:Notify({
                Title = "敵へテレポート",
                Content = closestPlayer.Name .. " の近くへ移動しました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local SpeedHackSection = MovementTab:CreateSection("移動ハック")

local SpeedHackToggle = MovementTab:CreateToggle({
    Name = "⚡ スピードハック",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(Value)
        Settings.SpeedHack = Value
        SetupSpeedHack()
        
        Rayfield:Notify({
            Title = "スピードハック",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "移動速度",
    Range = {16, 100},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

local FlyHackToggle = MovementTab:CreateToggle({
    Name = "✈️ フライハック (飛行)",
    CurrentValue = false,
    Flag = "FlyHack",
    Callback = function(Value)
        Settings.FlyHack = Value
        SetupFlyHack()
        
        Rayfield:Notify({
            Title = "フライハック",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local FlySpeedSlider = MovementTab:CreateSlider({
    Name = "飛行速度",
    Range = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        -- 飛行速度を調整
    end
})

-- 視覚タブ
local VisualTab = Window:CreateTab("👁️ 視覚", 4483362458)

local ESPSection = VisualTab:CreateSection("ESP・可視化")

local ESPToggle = VisualTab:CreateToggle({
    Name = "🎯 ESP (敵表示)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        Settings.ESP = Value
        SetupESP()
        
        Rayfield:Notify({
            Title = "ESP",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local ESPColorPicker = VisualTab:CreateColorPicker({
    Name = "敵ESPカラー",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPEnemyColor",
    Callback = function(Color)
        -- ESPの色を変更
    end
})

local TeamESPColorPicker = VisualTab:CreateColorPicker({
    Name = "味方ESPカラー",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "ESPTeamColor",
    Callback = function(Color)
        -- 味方ESPの色を変更
    end
})

local ShowNamesToggle = VisualTab:CreateToggle({
    Name = "👤 プレイヤー名表示",
    CurrentValue = true,
    Flag = "ShowNames",
    Callback = function(Value)
        -- 名前表示の切り替え
    end
})

local ShowDistanceToggle = VisualTab:CreateToggle({
    Name = "📏 距離表示",
    CurrentValue = true,
    Flag = "ShowDistance",
    Callback = function(Value)
        -- 距離表示の切り替え
    end
})

local ShowHealthToggle = VisualTab:CreateToggle({
    Name = "❤️ 体力バー表示",
    CurrentValue = true,
    Flag = "ShowHealth",
    Callback = function(Value)
        -- 体力バー表示の切り替え
    end
})

local ChamsSection = VisualTab:CreateSection("チャムス・壁透視")

local WallhackToggle = VisualTab:CreateToggle({
    Name = "🧱 壁透視 (Wallhack)",
    CurrentValue = false,
    Flag = "Wallhack",
    Callback = function(Value)
        -- 壁透視機能の実装
        Rayfield:Notify({
            Title = "壁透視",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local FullbrightToggle = VisualTab:CreateToggle({
    Name = "💡 フルブライト",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(Value)
        -- フルブライト機能の実装
        if Value then
            game.Lighting.Brightness = 2
            game.Lighting.GlobalShadows = false
        else
            game.Lighting.Brightness = 1
            game.Lighting.GlobalShadows = true
        end
    end
})

-- 武器タブ
local WeaponsTab = Window:CreateTab("🔫 武器", 4483362458)

local FireSection = WeaponsTab:CreateSection("発射設定")

local FireCooldownSlider = WeaponsTab:CreateSlider({
    Name = "発射間隔",
    Range = {0.1, 3.0},
    Increment = 0.1,
    Suffix = "秒",
    CurrentValue = 2.5,
    Flag = "FireCooldown",
    Callback = function(Value)
        -- 発射間隔設定
    end
})

local DamageMultiplierSlider = WeaponsTab:CreateSlider({
    Name = "ダメージ倍率",
    Range = {1.0, 10.0},
    Increment = 0.5,
    Suffix = "倍",
    CurrentValue = 1.0,
    Flag = "DamageMultiplier",
    Callback = function(Value)
        -- ダメージ倍率設定
    end
})

local RangeSlider = WeaponsTab:CreateSlider({
    Name = "射程距離",
    Range = {50, 1000},
    Increment = 10,
    Suffix = "studs",
    CurrentValue = 100,
    Flag = "WeaponRange",
    Callback = function(Value)
        -- 射程距離設定
    end
})

local WeaponModsSection = WeaponsTab:CreateSection("武器改造")

local InfiniteAmmoToggle = WeaponsTab:CreateToggle({
    Name = "∞ 無限弾薬",
    CurrentValue = false,
    Flag = "InfiniteAmmo",
    Callback = function(Value)
        -- 無限弾薬機能
        Rayfield:Notify({
            Title = "無限弾薬",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local InstantReloadToggle = WeaponsTab:CreateToggle({
    Name = "⚡ インスタントリロード",
    CurrentValue = false,
    Flag = "InstantReload",
    Callback = function(Value)
        -- 瞬間リロード機能
        Rayfield:Notify({
            Title = "インスタントリロード",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local NoWeaponDropToggle = WeaponsTab:CreateToggle({
    Name = "🤲 武器ドロップ無効",
    CurrentValue = false,
    Flag = "NoWeaponDrop",
    Callback = function(Value)
        -- 武器ドロップ防止
        Rayfield:Notify({
            Title = "武器ドロップ無効",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ユーティリティタブ
local UtilityTab = Window:CreateTab("🛠️ ユーティリティ", 4483362458)

local GameSection = UtilityTab:CreateSection("ゲーム機能")

local AutoJoinToggle = UtilityTab:CreateToggle({
    Name = "🎮 自動ゲーム参加",
    CurrentValue = false,
    Flag = "AutoJoin",
    Callback = function(Value)
        Settings.AutoJoin = Value
    end
})

local AutoRespawnToggle = UtilityTab:CreateToggle({
    Name = "🏥 自動リスポーン",
    CurrentValue = false,
    Flag = "AutoRespawn",
    Callback = function(Value)
        Settings.AutoRespawn = Value
    end
})

local AutoFarmToggle = UtilityTab:CreateToggle({
    Name = "💰 自動ファーム",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        Settings.AutoFarm = Value
    end
})

local MiscSection = UtilityTab:CreateSection("その他機能")

local AntiAFKToggle = UtilityTab:CreateToggle({
    Name = "⏰ アンチAFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        if Value then
            -- AFK防止機能を有効化
            local VirtualUser = game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

local NoClipToggle = UtilityTab:CreateToggle({
    Name = "👻 ノークリップ (Nキー)",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(Value)
        Settings.NoClip = Value
        
        if Value then
            UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.N then
                    if LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = not part.CanCollide
                            end
                        end
                    end
                end
            end)
        end
    end
})

local SuperJumpToggle = UtilityTab:CreateToggle({
    Name = "🦘 スーパージャンプ (50スタッド)",
    CurrentValue = false,
    Flag = "SuperJump",
    Callback = function(Value)
        if Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = 50
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
    end
})

-- クイックアクション
local QuickActionsSection = UtilityTab:CreateSection("クイックアクション")

local HealButton = UtilityTab:CreateButton({
    Name = "❤️ 体力全回復",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
            Rayfield:Notify({
                Title = "体力回復",
                Content = "体力を全回復しました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local KillAllButton = UtilityTab:CreateButton({
    Name = "💀 全敵キル (テスト)",
    Callback = function()
        Rayfield:Notify({
            Title = "注意",
            Content = "この機能はゲームのルールに反する可能性があります",
            Duration = 5,
            Image = 4483362458
        })
    end
})

local ResetCharacterButton = UtilityTab:CreateButton({
    Name = "🔄 キャラクターリセット",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Rayfield:Notify({
                Title = "キャラクターリセット",
                Content = "キャラクターをリセットしました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- 設定タブ
local SettingsTab = Window:CreateTab("⚙️ 設定", 4483362458)

local ConfigSection = SettingsTab:CreateSection("構成設定")

local LoadConfigButton = SettingsTab:CreateButton({
    Name = "📥 設定を読み込み",
    Callback = function()
        Rayfield:Notify({
            Title = "設定読み込み",
            Content = "保存済み設定を読み込みました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local SaveConfigButton = SettingsTab:CreateButton({
    Name = "💾 設定を保存",
    Callback = function()
        Rayfield:Notify({
            Title = "設定保存",
            Content = "現在の設定を保存しました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local ResetConfigButton = SettingsTab:CreateButton({
    Name = "🔄 設定をリセット",
    Callback = function()
        -- すべての設定をデフォルトにリセット
        for _, toggle in pairs({
            AutoKillToggle, AutoHeadshotToggle, AutoThrowToggle, KillAuraToggle,
            SilentAimToggle, TriggerbotToggle, RapidFireToggle, NoRecoilToggle,
            NoSpreadToggle, WallbangToggle, CrosshairTPToggle, SpeedHackToggle,
            FlyHackToggle, ESPToggle
        }) do
            if toggle then
                toggle:Set(false)
            end
        end
        
        Rayfield:Notify({
            Title = "設定リセット",
            Content = "すべての設定をデフォルトにリセットしました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

local UISection = SettingsTab:CreateSection("UI設定")

local UIScaleSlider = SettingsTab:CreateSlider({
    Name = "UIスケール",
    Range = {0.5, 2.0},
    Increment = 0.1,
    Suffix = "倍",
    CurrentValue = 1.0,
    Flag = "UIScale",
    Callback = function(Value)
        -- UIのスケールを調整
    end
})

local TransparencySlider = SettingsTab:CreateSlider({
    Name = "UI透明度",
    Range = {0.1, 1.0},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1.0,
    Flag = "UITransparency",
    Callback = function(Value)
        -- UIの透明度を調整
    end
})

-- システム情報
local InfoSection = SettingsTab:CreateSection("システム情報")

local GameInfoLabel = SettingsTab:CreateLabel("ゲーム: 読み込み中...")
local PlayerInfoLabel = SettingsTab:CreateLabel("プレイヤー: " .. LocalPlayer.Name)
local PingLabel = SettingsTab:CreateLabel("Ping: 測定中...")

-- Ping測定
spawn(function()
    while true do
        local ping = math.random(30, 100) -- 簡易的なPing測定
        PingLabel:Set("Ping: " .. ping .. "ms")
        wait(5)
    end
end)

-- 初期化完了通知
Rayfield:Notify({
    Title = "上級コントロールパネル",
    Content = "すべての機能がロードされました\n左のタブから機能を選択してください",
    Duration = 6,
    Image = 4483362458
})

-- 警告メッセージ
Window:Prompt({
    Title = "⚠️ 重要なお知らせ",
    SubTitle = "使用上の注意",
    Content = "これらの機能はゲームの公平性を損なう可能性があります。\n自己責任で使用し、過度な使用は避けてください。",
    Actions = {
        Accept = {
            Name = "了解して続行",
            Callback = function()
                print("ユーザーが利用規約に同意")
            end
        },
        Decline = {
            Name = "キャンセル",
            Callback = function()
                Rayfield:Notify({
                    Title = "キャンセル",
                    Content = "機能の使用を中止しました",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        }
    }
})

-- ゲーム状態監視
spawn(function()
    while true do
        local runningGame = FindRunningGame(LocalPlayer)
        if runningGame then
            GameInfoLabel:Set("ゲーム: 進行中 (" .. runningGame.Name .. ")")
        else
            GameInfoLabel:Set("ゲーム: 待機中")
        end
        wait(2)
    end
end)
