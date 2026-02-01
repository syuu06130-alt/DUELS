-- [[ UI Loader & Services ]]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ Variables & States ]]
local TargetPlayer = nil
local LockMode = "None" -- "Behind", "Above", "None"
local LockDistance = 5
local Toggles = {
    AutoKill = false,
    SilentAim = false,
    ESP = false,
    NoRecoil = false,
}

-- デコンパイルコードからの参照取得
local FireRemote = ReplicatedStorage:FindFirstChild("fire")
local KillRemote = ReplicatedStorage:FindFirstChild("kill")

-- [[ Functions ]]

-- 1. ターゲット選定 (最も近い敵)
local function GetClosestPlayer()
    local closest = nil
    local dist = math.huge
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

-- 2. TPロジック (追従システム)
RunService.Heartbeat:Connect(function()
    if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = TargetPlayer.Character.HumanoidRootPart
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if myHrp then
            if LockMode == "Behind" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, LockDistance)
            elseif LockMode == "Above" then
                myHrp.CFrame = hrp.CFrame * CFrame.new(0, LockDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            end
        end
        
        -- ターゲットが死んだらリセット
        if TargetPlayer.Character.Humanoid.Health <= 0 then
            TargetPlayer = nil
        end
    end
end)

-- 3. モバイル用TPボタン生成
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    local TPButton = Instance.new("TextButton", ScreenGui)
    
    TPButton.Name = "MobileTPButton"
    TPButton.Size = UDim2.new(0, 70, 0, 70)
    TPButton.Position = UDim2.new(0.5, 50, 0.5, 50) -- ジャンプボタン付近に調整
    TPButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TPButton.BackgroundTransparency = 0.5
    TPButton.Text = "TP"
    TPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    TPButton.Shape = Enum.FrameShape.Circle -- 円形（環境による）
    
    -- 長押し/ダブルタップロジックはUserInputServiceで別途実装
    TPButton.MouseButton1Click:Connect(function()
        TargetPlayer = GetClosestPlayer()
        Rayfield:Notify({Title = "Target Set", Content = "Locked onto: " .. (TargetPlayer.Name or "None")})
    end)
end

-- [[ UI Window Setup ]]
local Window = Rayfield:CreateWindow({
    Name = "Premium Combat & Movement Hub",
    LoadingTitle = "Initializing Systems...",
    LoadingSubtitle = "by Gemini Integration",
    ConfigurationSaving = { Enabled = true, Folder = "GeminiScripts" }
})

-- 【戦闘タブ】
local CombatTab = Window:CreateTab("⚔️ Combat")
CombatTab:CreateToggle({
    Name = "Auto Kill",
    CurrentValue = false,
    Callback = function(Value) Toggles.AutoKill = Value end
})

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value) Toggles.SilentAim = Value end
})

-- 【移動タブ】
local MoveTab = Window:CreateTab("🏃 Movement")
MoveTab:CreateSection("Target Lock TP")

local LockDropdown = MoveTab:CreateDropdown({
    Name = "Lock Mode",
    Options = {"None", "Behind", "Above"},
    CurrentOption = "None",
    Callback = function(Option)
        LockMode = Option
    end
})

MoveTab:CreateSlider({
    Name = "Lock Distance",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 5,
    Callback = function(Value) LockDistance = Value end
})

MoveTab:CreateButton({
    Name = "Select Target",
    Callback = function()
        TargetPlayer = GetClosestPlayer()
        if TargetPlayer then
            Rayfield:Notify({Title = "Target Locked", Content = "Target: " .. TargetPlayer.Name})
        end
    end
})

-- 【視覚/武器タブはここに追加...】
-- (コードが長くなるため主要な構造を優先しています)
