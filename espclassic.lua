lua
-- ============================================
-- ESP + GUI (Xeno / Roblox) — исправленный
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ============================================
-- Настройки
-- ============================================
local SETTINGS = {
    Enabled = true,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(0, 255, 0),
}

local ESPObjects = {}
local connections = {}

-- ============================================
-- Создание ESP
-- ============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = nil
    billboard.Parent = PlayerGui

    -- Бокс (рамка)
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.Size = UDim2.new(1, 0, 1, 0)
    box.Position = UDim2.new(0, 0, 0, 0)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = billboard

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Name = "BoxStroke"
    boxStroke.Color = SETTINGS.BoxColor
    boxStroke.Thickness = 1.5
    boxStroke.Parent = box

    -- Ник
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, -18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = ""
    nameLabel.Parent = billboard

    -- Фон ХП
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(0, 60, 0, 6)
    healthBg.Position = UDim2.new(0.5, -30, 0, 2)
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BorderSizePixel = 0
    healthBg.Parent = billboard

    -- Полоска ХП (привязана к левому краю фона, меняется ширина)
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0) -- изначально на весь фон
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBg

    -- Дистанция
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 0, 10)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.SourceSans
    distLabel.Text = ""
    distLabel.Parent = billboard

    ESPObjects[player] = {
        Billboard = billboard,
        Box = box,
        NameLabel = nameLabel,
        HealthBar = healthBar,
        HealthBg = healthBg,
        DistLabel = distLabel,
    }
end

-- ============================================
-- Удаление ESP
-- ============================================
local function RemoveESP(player)
    local data = ESPObjects[player]
    if not data then return end
    if data.Billboard then data.Billboard:Destroy() end
    ESPObjects[player] = nil
end

-- ============================================
-- Обновление ESP
-- ============================================
local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")

        if not SETTINGS.Enabled or not character or not humanoid or not rootPart or not head or humanoid.Health <= 0 then
            data.Billboard.Enabled = false
            continue
        end

        local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
        if distance > SETTINGS.MaxDistance then
            data.Billboard.Enabled = false
            continue
        end

        data.Billboard.Adornee = head
        data.Billboard.Enabled = true

        -- Бокс
        if SETTINGS.ShowBox then
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end

        -- Ник
        if SETTINGS.ShowName then
            data.NameLabel.Text = player.Name
            data.NameLabel.Visible = true
        else
            data.NameLabel.Visible = false
        end

        -- ХП
        if SETTINGS.ShowHealth then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            -- Меняем ширину от 0 до 100% относительно фона
            data.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
            data.HealthBar.Position = UDim2.new(0, 0, 0, 0)
            data.HealthBar.Visible = true
            data.HealthBg.Visible = true

            if healthPercent > 0.5 then
                data.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 0.25 then
                data.HealthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                data.HealthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
        else
            data.HealthBar.Visible = false
            data.HealthBg.Visible = false
        end

        -- Дистанция
        if SETTINGS.ShowDistance then
            data.DistLabel.Text = math.floor(distance) .. "m"
            data.DistLabel.Visible = true
        else
            data.DistLabel.Visible = false
        end
    end
end

-- ============================================
-- Инициализация
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end
connections[#connections + 1] = Players.PlayerAdded:Connect(CreateESP)
connections[#connections + 1] = Players.PlayerRemoving:Connect(RemoveESP)
connections[#connections + 1] = RunService.RenderStepped:Connect(UpdateESP)

-- ============================================
-- GUI
-- ============================================
local oldGui = PlayerGui:FindFirstChild("ESP_GUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- Главная кнопка (открыть меню)
local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0, 100)
openBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Text = "ESP"
openBtn.TextSize = 14
openBtn.Font = Enum.Font.SourceSansBold
openBtn.BorderSizePixel = 0
openBtn.Active = true
openBtn.Draggable = true
openBtn.Parent = screenGui

local openCorner = Instance.new("UICorner")
openCorner.CornerRadius = UDim.new(0, 8)
openCorner.Parent = openBtn

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 280)
mainFrame.Position = UDim2.new(0, 20, 0, 160)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Заголовок
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.BorderSizePixel = 0
title.Text = "ESP Menu (X — toggle)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 12
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = title

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- ============================================
-- Чекбокс
-- ============================================
local function CreateCheckbox(name, text, defaultValue, callback, order)
    local frame = Instance.new("Frame")
    frame.Name = name .. "_Frame"
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, 40 + order * 35)
    frame.BackgroundTransparency = 1
    frame.Parent = mainFrame

    local button = Instance.new("TextButton")
    button.Name = name .. "_Button"
    button.Size = UDim2.new(0, 20, 0, 20)
    button.Position = UDim2.new(0, 0, 0, 5)
    button.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local state = defaultValue
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(80, 80, 80)
        if callback then callback(state) end
    end)
end

CreateCheckbox("ESP", "Включить ESP", SETTINGS.Enabled, function(s) SETTINGS.Enabled = s end, 0)
CreateCheckbox("Box", "Показывать бокс", SETTINGS.ShowBox, function(s) SETTINGS.ShowBox = s end, 1)
CreateCheckbox("Name", "Показывать ник", SETTINGS.ShowName, function(s) SETTINGS.ShowName = s end, 2)
CreateCheckbox("Health", "Показывать ХП", SETTINGS.ShowHealth, function(s) SETTINGS.ShowHealth = s end, 3)
CreateCheckbox("Distance", "Показывать дистанцию", SETTINGS.ShowDistance, function(s) SETTINGS.ShowDistance = s end, 4)

-- ============================================
-- Открытие / закрытие
-- ============================================
openBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Горячая клавиша X
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

print("[ESP] Скрипт с GUI и хоткеем X загружен")
