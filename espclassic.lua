-- ============================================
-- Свой ESP для Xeno
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
    HealthColor = Color3.fromRGB(0, 255, 0),
    MaxDistance = 1000, -- не показывать дальше этого
}

-- Хранилище для drawing-объектов каждого игрока
local ESPObjects = {}

-- ============================================
-- Создание объектов Drawing
-- ============================================
local function CreateESP(player)
    if player == LocalPlayer then return end

    local drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBg = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
    }

    -- Настройка бокса
    drawings.Box.Thickness = 1
    drawings.Box.Filled = false
    drawings.Box.Color = SETTINGS.BoxColor
    drawings.Box.Transparency = 1

    -- Настройка имени
    drawings.Name.Size = 14
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Color = SETTINGS.TextColor
    drawings.Name.Font = 2 -- 0 = UI, 1 = System, 2 = Plex, 3 = Monospace

    -- Настройка фона ХП
    drawings.HealthBg.Filled = true
    drawings.HealthBg.Color = Color3.fromRGB(0, 0, 0)
    drawings.HealthBg.Transparency = 0.5

    -- Настройка полоски ХП
    drawings.HealthBar.Filled = true
    drawings.HealthBar.Color = SETTINGS.HealthColor
    drawings.HealthBar.Transparency = 1

    -- Настройка дистанции
    drawings.Distance.Size = 12
    drawings.Distance.Center = true
    drawings.Distance.Outline = true
    drawings.Distance.Color = Color3.fromRGB(200, 200, 200)
    drawings.Distance.Font = 2

    ESPObjects[player] = drawings
end

-- ============================================
-- Удаление объектов при выходе игрока
-- ============================================
local function RemoveESP(player)
    local drawings = ESPObjects[player]
    if not drawings then return end

    for _, obj in pairs(drawings) do
        obj:Remove()
    end
    ESPObjects[player] = nil
end

-- ============================================
-- Основной цикл обновления
-- ============================================
local function UpdateESP()
    for player, drawings in pairs(ESPObjects) do
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        -- Если персонажа нет или он мёртв — скрываем
        if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            continue
        end

        -- Позиция на экране
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude

        -- Если далеко или за экраном — скрываем
        if not onScreen or distance > SETTINGS.MaxDistance then
            for _, obj in pairs(drawings) do
                obj.Visible = false
            end
            continue
        end

        -- ============================================
        -- Рассчёт размеров бокса
        -- ============================================
        local head = character:FindFirstChild("Head")
        local humanoidRootPart = rootPart

        if head then
            -- Верх и низ персонажа в мировых координатах
            local topPos = head.Position + Vector3.new(0, 1, 0)
            local bottomPos = humanoidRootPart.Position - Vector3.new(0, 3, 0)

            local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
            local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

            if topOnScreen and bottomOnScreen then
                local height = math.abs(topScreen.Y - bottomScreen.Y)
                local width = height * 0.6 -- соотношение сторон
                local x = screenPos.X - width / 2
                local y = topScreen.Y
                local centerX = screenPos.X
                local centerY = topScreen.Y

                -- Бокс
                if SETTINGS.ShowBox then
                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(x, y)
                    drawings.Box.Visible = true
                end

                -- Имя
                if SETTINGS.ShowName then
                    drawings.Name.Text = player.Name .. " [" .. math.floor(distance) .. "m]"
                    drawings.Name.Position = Vector2.new(centerX, y - 16)
                    drawings.Name.Visible = true
                end

                -- Полоска ХП
                if SETTINGS.ShowHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height
                    local barWidth = 4

                    -- Фон
                    drawings.HealthBg.Size = Vector2.new(barWidth + 2, barHeight + 2)
                    drawings.HealthBg.Position = Vector2.new(x - barWidth - 4, y - 1)
                    drawings.HealthBg.Visible = true

                    -- Заполнение
                    local filledHeight = barHeight * healthPercent
                    drawings.HealthBar.Size = Vector2.new(barWidth, filledHeight)
                    drawings.HealthBar.Position = Vector2.new(
                        x - barWidth - 3,
                        y + (barHeight - filledHeight)
                    )

                    -- Цвет в зависимости от ХП
                    if healthPercent > 0.5 then
                        drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.25 then
                        drawings.HealthBar.Color = Color3.fromRGB(255, 255, 0)
                    else
                        drawings.HealthBar.Color = Color3.fromRGB(255, 0, 0)
                    end
                    drawings.HealthBar.Visible = true
                end

                -- Дистанция
                if SETTINGS.ShowDistance then
                    drawings.Distance.Text = math.floor(distance) .. "m"
                    drawings.Distance.Position = Vector2.new(centerX, y + height + 4)
                    drawings.Distance.Visible = true
                end
            end
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

-- Обновление каждый кадр
RunService.RenderStepped:Connect(UpdateESP)

print("[ESP] Загружен. Игроков: " .. #Players:GetPlayers())
