-- 既存のコードの続きに追加・修正します

-- 新しい設定変数を追加
Settings.BackLockTP = false
Settings.HeadLockTP = false
Settings.LockDistance = 3
Settings.MobileTPButton = false

-- ロックTPのターゲット追跡用変数
local LockTarget = nil
local LockConnection = nil

-- 背後ロックTP機能
local function SetupBackLockTP()
    if Settings.BackLockTP and LockTarget then
        if LockConnection then
            LockConnection:Disconnect()
        end
        
        LockConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if not LockTarget or not LockTarget.Character or not LockTarget.Character:FindFirstChild("HumanoidRootPart") then
                LockTarget = nil
                LockConnection:Disconnect()
                LockConnection = nil
                return
            end
            
            -- ターゲットの背後にテレポート
            local targetRoot = LockTarget.Character.HumanoidRootPart
            local targetCFrame = targetRoot.CFrame
            local behindPosition = targetCFrame * CFrame.new(0, 0, Settings.LockDistance)
            
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(behindPosition.Position, targetRoot.Position)
        end)
    elseif LockConnection then
        LockConnection:Disconnect()
        LockConnection = nil
        LockTarget = nil
    end
end

-- 頭上ロックTP機能
local function SetupHeadLockTP()
    if Settings.HeadLockTP and LockTarget then
        if LockConnection then
            LockConnection:Disconnect()
        end
        
        LockConnection = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            if not LockTarget or not LockTarget.Character or not LockTarget.Character:FindFirstChild("HumanoidRootPart") then
                LockTarget = nil
                LockConnection:Disconnect()
                LockConnection = nil
                return
            end
            
            -- ターゲットの頭上にテレポート
            local targetRoot = LockTarget.Character.HumanoidRootPart
            local abovePosition = targetRoot.Position + Vector3.new(0, Settings.LockDistance + 5, 0)
            
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(abovePosition)
        end)
    elseif LockConnection then
        LockConnection:Disconnect()
        LockConnection = nil
        LockTarget = nil
    end
end

-- ターゲット選択関数
local function SelectTarget()
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
    
    if closestPlayer then
        LockTarget = closestPlayer
        Rayfield:Notify({
            Title = "ターゲットロック",
            Content = closestPlayer.Name .. " をターゲットに設定",
            Duration = 3,
            Image = 4483362458
        })
        return closestPlayer
    end
    
    return nil
end

-- ターゲット解除関数
local function ClearTarget()
    LockTarget = nil
    if LockConnection then
        LockConnection:Disconnect()
        LockConnection = nil
    end
    Rayfield:Notify({
        Title = "ターゲット解除",
        Content = "ターゲットロックを解除",
        Duration = 3,
        Image = 4483362458
    })
end

-- モバイル用TPボタン関連
local MobileTPButton = nil
local MobileTPButtonFrame = nil

-- モバイル用TPボタンを作成
local function CreateMobileTPButton()
    if not UserInputService.TouchEnabled then
        return
    end
    
    -- 既存のボタンを削除
    if MobileTPButton then
        MobileTPButton:Destroy()
        MobileTPButton = nil
    end
    if MobileTPButtonFrame then
        MobileTPButtonFrame:Destroy()
        MobileTPButtonFrame = nil
    end
    
    -- ボタンの親フレームを作成
    MobileTPButtonFrame = Instance.new("Frame")
    MobileTPButtonFrame.Name = "MobileTPButtonFrame"
    MobileTPButtonFrame.BackgroundTransparency = 1
    MobileTPButtonFrame.Size = UDim2.new(0, 100, 0, 100)
    MobileTPButtonFrame.Position = UDim2.new(1, -120, 1, -230) -- ジャンプボタンの上あたり
    MobileTPButtonFrame.ZIndex = 100
    
    -- ボタン本体を作成（Robloxのジャンプボタン風）
    MobileTPButton = Instance.new("ImageButton")
    MobileTPButton.Name = "MobileTPButton"
    MobileTPButton.Image = "rbxasset://textures/ui/TouchControlsSheet.png"
    MobileTPButton.ImageRectOffset = Vector2.new(52, 42)
    MobileTPButton.ImageRectSize = Vector2.new(44, 44)
    MobileTPButton.BackgroundTransparency = 1
    MobileTPButton.Size = UDim2.new(0, 80, 0, 80)
    MobileTPButton.Position = UDim2.new(0.5, -40, 0.5, -40)
    MobileTPButton.ZIndex = 101
    
    -- ボタンの効果を追加
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = MobileTPButton
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(255, 255, 255)
    UIStroke.Thickness = 3
    UIStroke.Parent = MobileTPButton
    
    -- アイコンを追加（TPのアイコン）
    local IconLabel = Instance.new("TextLabel")
    IconLabel.Name = "Icon"
    IconLabel.Text = "TP"
    IconLabel.Font = Enum.Font.GothamBold
    IconLabel.TextSize = 20
    IconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Size = UDim2.new(1, 0, 1, 0)
    IconLabel.Position = UDim2.new(0, 0, 0, 0)
    IconLabel.ZIndex = 102
    IconLabel.Parent = MobileTPButton
    
    -- フレームを親に追加
    MobileTPButton.Parent = MobileTPButtonFrame
    
    -- スクリーンギャに追加
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MobileTPGUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    MobileTPButtonFrame.Parent = ScreenGui
    
    -- ボタンイベント
    local isPressing = false
    local pressStartTime = 0
    
    MobileTPButton.MouseButton1Down:Connect(function()
        isPressing = true
        pressStartTime = tick()
        
        -- 押している間の視覚効果
        MobileTPButton.ImageTransparency = 0.3
        UIStroke.Transparency = 0.3
    end)
    
    MobileTPButton.MouseButton1Up:Connect(function()
        isPressing = false
        
        -- 視覚効果を戻す
        MobileTPButton.ImageTransparency = 0
        UIStroke.Transparency = 0
        
        -- 長押し判定
        local pressDuration = tick() - pressStartTime
        
        if pressDuration < 0.5 then
            -- 短押し：通常TP
            ExecuteMobileTP()
        else
            -- 長押し：ターゲット選択
            SelectTarget()
        end
    end)
    
    MobileTPButton.TouchLongPress:Connect(function()
        SelectTarget()
    end)
    
    -- ダブルタップ検知用
    local lastTapTime = 0
    MobileTPButton.MouseButton1Click:Connect(function()
        local currentTime = tick()
        if currentTime - lastTapTime < 0.3 then
            -- ダブルタップ：ターゲット解除
            ClearTarget()
        end
        lastTapTime = currentTime
    end)
    
    -- ボタンのアニメーション効果
    spawn(function()
        while MobileTPButton and MobileTPButton.Parent do
            -- ゆっくり点滅させる（ロック中のみ）
            if LockTarget then
                local alpha = 0.5 + math.sin(tick() * 3) * 0.3
                IconLabel.TextColor3 = Color3.fromRGB(255 * alpha, 100 * alpha, 100 * alpha)
                UIStroke.Color = Color3.fromRGB(255 * alpha, 100 * alpha, 100 * alpha)
            else
                IconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                UIStroke.Color = Color3.fromRGB(255, 255, 255)
            end
            wait(0.1)
        end
    end)
    
    -- デバイスの向きに応じて位置を調整
    local function UpdateButtonPosition()
        if not MobileTPButtonFrame then return end
        
        -- 画面サイズを取得
        local viewportSize = Workspace.CurrentCamera.ViewportSize
        
        -- 右側、ジャンプボタンの上あたりに配置
        -- Robloxのジャンプボタンは通常右下にあるので、その上に配置
        MobileTPButtonFrame.Position = UDim2.new(1, -120, 1, -230)
        
        -- 画面の向きが縦向きの場合
        if viewportSize.Y > viewportSize.X then
            MobileTPButtonFrame.Position = UDim2.new(1, -120, 1, -230)
        else
            MobileTPButtonFrame.Position = UDim2.new(1, -150, 1, -120)
        end
    end
    
    -- 初期位置設定
    UpdateButtonPosition()
    
    -- 画面サイズ変更時に位置を更新
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateButtonPosition)
end

-- モバイル用TP実行関数
local function ExecuteMobileTP()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- モバイル用：画面中央からレイを飛ばす
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    
    local ray = Workspace.CurrentCamera:ScreenPointToRay(centerX, centerY)
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
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safeRaycast.Position + Vector3.new(0, 3, 0))
            
            -- エフェクト表示
            if MobileTPButton then
                local originalSize = MobileTPButton.Size
                MobileTPButton.Size = UDim2.new(0, 70, 0, 70)
                
                spawn(function()
                    wait(0.1)
                    if MobileTPButton then
                        MobileTPButton.Size = originalSize
                    end
                end)
            end
            
            Rayfield:Notify({
                Title = "モバイルTP",
                Content = "テレポート成功",
                Duration = 2,
                Image = 4483362458
            })
        end
    else
        Rayfield:Notify({
            Title = "モバイルTP",
            Content = "テレポート先が見つかりません",
            Duration = 2,
            Image = 4483362458
        })
    end
end

-- モバイルTPボタンの表示/非表示
local function ToggleMobileTPButton(show)
    if not UserInputService.TouchEnabled then
        return
    end
    
    if show then
        CreateMobileTPButton()
        Settings.MobileTPButton = true
    else
        if MobileTPButtonFrame then
            MobileTPButtonFrame:Destroy()
            MobileTPButtonFrame = nil
        end
        Settings.MobileTPButton = false
    end
end

-- 既存のMovementTabに新しい機能を追加
-- 移動タブのテレポートセクションを拡張

-- まず既存のTeleportSectionの後に新しいセクションを追加
local LockTPSection = MovementTab:CreateSection("ターゲットロックTP")

-- ターゲット選択ボタン
local SelectTargetButton = MovementTab:CreateButton({
    Name = "🎯 ターゲット選択 (近くの敵)",
    Callback = function()
        SelectTarget()
    end
})

-- ターゲット解除ボタン
local ClearTargetButton = MovementTab:CreateButton({
    Name = "❌ ターゲット解除",
    Callback = function()
        ClearTarget()
    end
})

-- 現在のターゲット表示ラベル
local TargetInfoLabel = MovementTab:CreateLabel("ターゲット: なし")

-- ターゲット情報を更新する関数
local function UpdateTargetInfo()
    if LockTarget then
        TargetInfoLabel:Set("ターゲット: " .. LockTarget.Name)
    else
        TargetInfoLabel:Set("ターゲット: なし")
    end
end

-- 背後ロックTPトグル
local BackLockTPToggle = MovementTab:CreateToggle({
    Name = "👤 背後ロックTP",
    CurrentValue = false,
    Flag = "BackLockTP",
    Callback = function(Value)
        Settings.BackLockTP = Value
        
        if Value then
            -- 頭上ロックと競合しないようにする
            if Settings.HeadLockTP then
                HeadLockTPToggle:Set(false)
            end
            
            -- ターゲットがいなければ選択
            if not LockTarget then
                SelectTarget()
            end
            
            if LockTarget then
                SetupBackLockTP()
            end
        else
            SetupBackLockTP()
        end
        
        Rayfield:Notify({
            Title = "背後ロックTP",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 頭上ロックTPトグル
local HeadLockTPToggle = MovementTab:CreateToggle({
    Name = "☁️ 頭上ロックTP",
    CurrentValue = false,
    Flag = "HeadLockTP",
    Callback = function(Value)
        Settings.HeadLockTP = Value
        
        if Value then
            -- 背後ロックと競合しないようにする
            if Settings.BackLockTP then
                BackLockTPToggle:Set(false)
            end
            
            -- ターゲットがいなければ選択
            if not LockTarget then
                SelectTarget()
            end
            
            if LockTarget then
                SetupHeadLockTP()
            end
        else
            SetupHeadLockTP()
        end
        
        Rayfield:Notify({
            Title = "頭上ロックTP",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ロック距離スライダー
local LockDistanceSlider = MovementTab:CreateSlider({
    Name = "🔢 ロック距離",
    Range = {1, 20},
    Increment = 0.5,
    Suffix = "スタッド",
    CurrentValue = 3,
    Flag = "LockDistance",
    Callback = function(Value)
        Settings.LockDistance = Value
    end
})

-- 自動ターゲット更新トグル
local AutoUpdateTargetToggle = MovementTab:CreateToggle({
    Name = "🔄 自動ターゲット更新",
    CurrentValue = false,
    Flag = "AutoUpdateTarget",
    Callback = function(Value)
        if Value then
            spawn(function()
                while Settings.AutoUpdateTarget do
                    -- ターゲットが死んだり、遠くなったりしたら更新
                    if LockTarget then
                        if not LockTarget.Character or 
                           not LockTarget.Character:FindFirstChild("HumanoidRootPart") or
                           LockTarget.Character.Humanoid.Health <= 0 then
                            ClearTarget()
                            SelectTarget()
                        else
                            local distance = (LockTarget.Character.HumanoidRootPart.Position - 
                                            LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if distance > 100 then  -- 100スタッド以上離れたら更新
                                ClearTarget()
                                SelectTarget()
                            end
                        end
                    else
                        SelectTarget()
                    end
                    
                    UpdateTargetInfo()
                    wait(2)  -- 2秒ごとにチェック
                end
            end)
        end
    end
})

-- 新しいセクション：モバイルTP
local MobileTPSection = MovementTab:CreateSection("モバイルTP設定")

-- モバイルTPボタントグル
local MobileTPButtonToggle = MovementTab:CreateToggle({
    Name = "📱 モバイルTPボタン表示",
    CurrentValue = false,
    Flag = "MobileTPButton",
    Callback = function(Value)
        ToggleMobileTPButton(Value)
        
        Rayfield:Notify({
            Title = "モバイルTPボタン",
            Content = Value and "表示しました" or "非表示にしました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- モバイルTP感度スライダー
local MobileTPSensitivitySlider = MovementTab:CreateSlider({
    Name = "🎮 モバイルTP感度",
    Range = {1, 10},
    Increment = 1,
    Suffix = "",
    CurrentValue = 5,
    Flag = "MobileTPSensitivity",
    Callback = function(Value)
        -- 感度設定（今後の拡張用）
    end
})

-- モバイルTP説明ラベル
MovementTab:CreateLabel("モバイルTPボタン説明:")
MovementTab:CreateLabel("• タップ: 画面中央へTP")
MovementTab:CreateLabel("• 長押し: ターゲット選択")
MovementTab:CreateLabel("• ダブルタップ: ターゲット解除")

-- 既存のクロスヘアTP機能をスマホにも対応させる修正
local function SetupCrosshairTPEnhanced()
    if Settings.CrosshairTP then
        if UserInputService.TouchEnabled then
            -- スマホの場合はボタン経由で実行
            Rayfield:Notify({
                Title = "クロスヘアTP",
                Content = "スマホではモバイルTPボタンを使用してください",
                Duration = 3,
                Image = 4483362458
            })
        else
            -- PCの場合は右クリックで実行
            CrosshairTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    -- 既存のクロスヘアTPロジック
                    local ray = Workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local raycastResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                    
                    if raycastResult then
                        local teleportPos = raycastResult.Position + Vector3.new(0, 5, 0)
                        local safeRaycast = Workspace:Raycast(teleportPos, Vector3.new(0, -50, 0), raycastParams)
                        if safeRaycast then
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(safeRaycast.Position + Vector3.new(0, 3, 0))
                                print("クロスヘアTP: テレポート実行")
                            end
                        end
                    end
                end
            end)
        end
    else
        if CrosshairTPConnection then
            CrosshairTPConnection:Disconnect()
            CrosshairTPConnection = nil
        end
    end
end

-- 既存のCrosshairTPToggleのCallbackを更新
-- （既存のコードを修正）
local CrosshairTPToggle = MovementTab:CreateToggle({
    Name = "🎯 クロスヘアTP (PC:右クリック)",
    CurrentValue = false,
    Flag = "CrosshairTP",
    Callback = function(Value)
        Settings.CrosshairTP = Value
        SetupCrosshairTPEnhanced()
        
        Rayfield:Notify({
            Title = "クロスヘアTP",
            Content = Value and "有効になりました" or "無効になりました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ターゲット監視スレッド
spawn(function()
    while true do
        UpdateTargetInfo()
        
        -- ターゲットがロック中の場合、UIを更新
        if LockTarget then
            if not LockTarget.Character or 
               not LockTarget.Character:FindFirstChild("HumanoidRootPart") or
               (LockTarget.Character.Humanoid.Health <= 0) then
                ClearTarget()
            end
        end
        
        wait(1)
    end
end)

-- デバイスがタッチ対応か自動検出
spawn(function()
    wait(2) -- 初期化待機
    
    if UserInputService.TouchEnabled then
        Rayfield:Notify({
            Title = "モバイル検出",
            Content = "スマホ/タブレットを検出しました\nモバイルTPボタンを使用できます",
            Duration = 5,
            Image = 4483362458
        })
        
        -- 自動的にモバイルTPボタンを表示
        if Settings.MobileTPButton then
            ToggleMobileTPButton(true)
        end
    end
end)

-- ゲーム終了時のクリーンアップ
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer.Parent then
        -- ゲーム終了時にモバイルボタンを削除
        if MobileTPButtonFrame then
            MobileTPButtonFrame:Destroy()
        end
        
        -- 接続を解除
        if LockConnection then
            LockConnection:Disconnect()
        end
        if CrosshairTPConnection then
            CrosshairTPConnection:Disconnect()
        end
    end
end)

-- 初期化完了メッセージに情報を追加
Rayfield:Notify({
    Title = "拡張TP機能ロード完了",
    Content = "背後/頭上ロックTPと\nモバイルTPボタンが追加されました",
    Duration = 5,
    Image = 4483362458
})
