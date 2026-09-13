-- ============================================
-- ESP через BillboardGui (безопасный, не крашит)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки
local SETTINGS = {
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    BoxColor = Color3.fromRGB(0, 255, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    MaxDistance = 1000,
}

-- Хранилище
local ESPObjects = {}

-- ============================================
-- Создание ESP для игрока
-- ============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local drawings = {}
    
    -- Создаём BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = nil
    billboard.Parent = game:GetService("CoreGui")
    
    -- Имя
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = SETTINGS.TextColor
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = ""
    nameLabel.Parent = billboard
    
    -- ХП
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(0, 50, 0, 6)
    healthBar.Position = UDim2.new(0.5, -25, 0, 18)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = billboard
    
    local healthBg = Instance.new("Frame")
    healthBg.Name = "HealthBg"
    healthBg.Size = UDim2.new(0, 52, 0, 8)
    healthBg.Position = UDim2.new(0.5, -26, 0, 17)
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BorderSizePixel = 0
    healthBg.ZIndex = 0
    healthBg.Parent = billboard
    
    -- Дистанция
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 14)
    distLabel.Position = UDim2.new(0, 0, 0, 28)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.SourceSans
    distLabel.Text = ""
    distLabel.Parent = billboard
    
    ESPObjects[player] = {
        Billboard = billboard,
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
    
    if data.Billboard then
        data.Billboard:Destroy()
    end
    ESPObjects[player] = nil
end

-- ============================================
-- Обновление
-- ============================================
local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        
        if not character or not humanoid or not rootPart or not head or humanoid.Health <= 0 then
            if data.Billboard then
                data.Billboard.Enabled = false
            end
            continue
        end
        
        local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
        
        if distance > SETTINGS.MaxDistance then
            data.Billboard.Enabled = false
            continue
        end
        
        -- Привязываем к голове
        data.Billboard.Adornee = head
        data.Billboard.Enabled = true
        
        -- Имя
        if SETTINGS.ShowName then
            data.NameLabel.Text = player.Name
            data.NameLabel.Visible = true
        else
            data.NameLabel.Visible = false
        end
        
        -- ХП
        if SETTINGS.ShowHealth then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            data.HealthBar.Size = UDim2.new(healthPercent, 0, 0, 6)
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

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

RunService.RenderStepped:Connect(UpdateESP)

print("[ESP] Загружен. Игроков: " .. #Players:GetPlayers())
