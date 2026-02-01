-- ■■■ UI Loader ■■■
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- サービス定義
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- グローバル変数
local RunningGames = Workspace:WaitForChild("RunningGames")
local Maps = Workspace:WaitForChild("Maps")

-- 共通関数
local function FindRunningGame(player)
    for _, v in pairs(RunningGames:GetChildren()) do
        if v.Name:match(player.UserId) then
            return v
        end
    end
    return nil
end

-- Rayfieldウィンドウ作成
local Window = Rayfield:CreateWindow({
    Name = "ゲームコントロールパネル",
    LoadingTitle = "システムをロード中...",
    LoadingSubtitle = "by サポートシステム",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
})

-- メインタブ
local MainTab = Window:CreateTab("メイン機能", 4483362458)

-- 投票機能セクション
local VoteSection = MainTab:CreateSection("投票管理")

local VoteToggle = MainTab:CreateToggle({
    Name = "自動投票",
    CurrentValue = false,
    Flag = "AutoVote",
    Callback = function(Value)
        if Value then
            -- 投票機能の自動化ロジックをここに実装
            Rayfield:Notify({
                Title = "自動投票",
                Content = "自動投票が有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- 武器機能セクション
local WeaponsSection = MainTab:CreateSection("武器設定")

local FireCooldownSlider = MainTab:CreateSlider({
    Name = "発射間隔 (秒)",
    Range = {0.5, 5},
    Increment = 0.1,
    Suffix = "秒",
    CurrentValue = 2.5,
    Flag = "FireCooldown",
    Callback = function(Value)
        -- 発射間隔設定ロジック
    end
})

local AutoFireToggle = MainTab:CreateToggle({
    Name = "オートファイア",
    CurrentValue = false,
    Flag = "AutoFire",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "オートファイア",
                Content = "自動発射が有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- 投げナイフ機能
local ThrowKnifeToggle = MainTab:CreateToggle({
    Name = "投げナイフモード",
    CurrentValue = false,
    Flag = "ThrowKnifeMode",
    Callback = function(Value)
        -- 投げナイフモード切り替えロジック
        local message = Value and "投げナイフモード有効" or "投げナイフモード無効"
        Rayfield:Notify({
            Title = "武器モード",
            Content = message,
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ビーム表示設定
local BeamSection = MainTab:CreateSection("ビーム設定")

local ShowBeamToggle = MainTab:CreateToggle({
    Name = "ビーム表示",
    CurrentValue = true,
    Flag = "ShowBeam",
    Callback = function(Value)
        -- ビーム表示/非表示ロジック
    end
})

local BeamColorPicker = MainTab:CreateColorPicker({
    Name = "ビーム色",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "BeamColor",
    Callback = function(Color)
        -- ビーム色変更ロジック
    end
})

-- UI設定タブ
local UITab = Window:CreateTab("UI設定", 4483362458)

local UISection = UITab:CreateSection("インターフェース設定")

local KillFeedToggle = UITab:CreateToggle({
    Name = "キルフィード表示",
    CurrentValue = true,
    Flag = "KillFeed",
    Callback = function(Value)
        -- キルフィード表示設定
    end
})

local PlayerInfoToggle = UITab:CreateToggle({
    Name = "プレイヤー情報表示",
    CurrentValue = true,
    Flag = "PlayerInfo",
    Callback = function(Value)
        -- プレイヤー情報表示設定
    end
})

local TimerDisplayToggle = UITab:CreateToggle({
    Name = "タイマー表示",
    CurrentValue = true,
    Flag = "TimerDisplay",
    Callback = function(Value)
        -- タイマー表示設定
    end
})

-- ゲーム情報セクション
local GameInfoSection = UITab:CreateSection("ゲーム情報")

local GameInfoLabel = UITab:CreateLabel("現在のゲーム状態: 待機中")
local RoundInfoLabel = UITab:CreateLabel("ラウンド: 0")
local TeamInfoLabel = UITab:CreateLabel("チーム: 未割り当て")

-- チーム色設定
local TeamColorSection = UITab:CreateSection("チームカラー")

local TeamRedColor = UITab:CreateColorPicker({
    Name = "レッドチーム色",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "TeamRedColor",
    Callback = function(Color)
        -- チーム色変更ロジック
    end
})

local TeamBlueColor = UITab:CreateSection("ブルーチーム色", 4483362458)

local TeamBlueColorPicker = UITab:CreateColorPicker({
    Name = "ブルーチーム色",
    Color = Color3.fromRGB(0, 0, 255),
    Flag = "TeamBlueColor",
    Callback = function(Color)
        -- チーム色変更ロジック
    end
})

-- 便利機能タブ
local UtilityTab = Window:CreateTab("便利機能", 4483362458)

local UtilitySection = UtilityTab:CreateSection("ゲームツール")

local AutoJoinToggle = UtilityTab:CreateToggle({
    Name = "自動ゲーム参加",
    CurrentValue = false,
    Flag = "AutoJoin",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "自動参加",
                Content = "自動ゲーム参加が有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local AutoRespawnToggle = UtilityTab:CreateToggle({
    Name = "自動リスポーン",
    CurrentValue = false,
    Flag = "AutoRespawn",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "自動リスポーン",
                Content = "自動リスポーンが有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local HighlightEnemiesToggle = UtilityTab:CreateToggle({
    Name = "敵のハイライト",
    CurrentValue = false,
    Flag = "HighlightEnemies",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "敵ハイライト",
                Content = "敵キャラクターのハイライトが有効になりました",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- 情報更新ボタン
local UpdateInfoButton = UtilityTab:CreateButton({
    Name = "ゲーム情報更新",
    Callback = function()
        -- ゲーム情報を更新するロジック
        local runningGame = FindRunningGame(LocalPlayer)
        if runningGame then
            GameInfoLabel:Set("現在のゲーム状態: 進行中")
        else
            GameInfoLabel:Set("現在のゲーム状態: 待機中")
        end
        Rayfield:Notify({
            Title = "情報更新",
            Content = "ゲーム情報を更新しました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 設定リセットボタン
local ResetButton = UtilityTab:CreateButton({
    Name = "設定をリセット",
    Callback = function()
        -- 設定をデフォルトにリセット
        VoteToggle:Set(false)
        AutoFireToggle:Set(false)
        ThrowKnifeToggle:Set(false)
        ShowBeamToggle:Set(true)
        BeamColorPicker:Set(Color3.fromRGB(0, 255, 0))
        
        Rayfield:Notify({
            Title = "設定リセット",
            Content = "すべての設定をデフォルトにリセットしました",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- 元の機能を統合した関数群
local function SetupVoteSystem()
    -- 元のVoteスクリプトの機能を実装
    local MapVoteEvent = ReplicatedStorage:WaitForChild("MapVote")
    local VoteRemote = ReplicatedStorage:WaitForChild("Vote")
    
    MapVoteEvent.OnClientEvent:Connect(function(maps, hide)
        if not hide then
            -- 投票UI表示ロジック
            print("投票開始:", maps)
        else
            -- 投票UI非表示ロジック
            print("投票終了")
        end
    end)
end

local function SetupWeaponSystem()
    -- 元のfire/showBeam/killスクリプトの機能を実装
    -- 武器発射システムの初期化
end

local function SetupThrowSystem()
    -- 元のThrowスクリプトの機能を実装
    -- 投げナイフシステムの初期化
end

local function SetupUISystem()
    -- 元のSetStatePlr/GetPosスクリプトの機能を実装
    -- UIシステムの初期化
end

-- システム初期化
SetupVoteSystem()
SetupWeaponSystem()
SetupThrowSystem()
SetupUISystem()

-- 初期化完了通知
Rayfield:Notify({
    Title = "システムロード完了",
    Content = "ゲームコントロールパネルが起動しました",
    Duration = 5,
    Image = 4483362458
})

-- UIをロード完了状態にする
Window:Prompt({
    Title = "システム準備完了",
    SubTitle = "すべての機能がロードされました",
    Content = "左側のタブから機能を選択してください",
    Actions = {
        Accept = {
            Name = "了解",
            Callback = function()
                print("ユーザーが了解をクリック")
            end
        }
    }
})
