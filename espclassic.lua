--[[
	ESP System with GUI toggle panel
	Место установки: StarterPlayer > StarterPlayerScripts (LocalScript)

	Функции:
	- Box ESP (обводка/Highlight персонажа)
	- Name ESP (ник над головой)
	- HP ESP (полоска/текст здоровья)
	- Distance ESP (расстояние до игрока)
	- Общий переключатель ESP (вкл/выкл всё разом)
	- Настройка макс. дистанции отображения
	- Опция "только другая команда / все"

	Использовать для своей игры: спектейтор-режим, командные индикаторы,
	accessibility, отладка и т.д.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

--======================================================
-- НАСТРОЙКИ (состояние)
--======================================================
local Settings = {
	EspEnabled = true,
	BoxEsp = true,
	NameEsp = true,
	HealthEsp = true,
	DistanceEsp = true,
	MaxDistance = 500,       -- studs
	BoxColor = Color3.fromRGB(0, 255, 0),
	TextColor = Color3.fromRGB(255, 255, 255),
}

-- Хранилище созданных ESP-элементов на каждого игрока
local EspObjects = {} -- [player] = { highlight = ..., billboard = ..., nameLabel = ..., hpLabel = ..., distLabel = ... }

--======================================================
-- СОЗДАНИЕ GUI
--======================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EspControlGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Кнопка открытия/закрытия панели
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "OpenPanelButton"
toggleButton.Size = UDim2.new(0, 90, 0, 36)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Text = "ESP: ON"
toggleButton.BorderSizePixel = 0
toggleButton.Parent = screenGui

local uicorner0 = Instance.new("UICorner")
uicorner0.CornerRadius = UDim.new(0, 6)
uicorner0.Parent = toggleButton

-- Основная панель настроек
local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Size = UDim2.new(0, 220, 0, 260)
panel.Position = UDim2.new(0, 10, 0, 54)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.Parent = panel

-- Функция создания строки-переключателя (чекбокс)
local function createToggleRow(labelText, settingKey, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local checkBtn = Instance.new("TextButton")
	checkBtn.Size = UDim2.new(0, 40, 0, 22)
	checkBtn.Position = UDim2.new(1, -40, 0, 3)
	checkBtn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(90, 30, 30)
	checkBtn.Text = Settings[settingKey] and "ON" or "OFF"
	checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	checkBtn.Font = Enum.Font.GothamBold
	checkBtn.TextSize = 12
	checkBtn.BorderSizePixel = 0
	checkBtn.Parent = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 5)
	btnCorner.Parent = checkBtn

	checkBtn.MouseButton1Click:Connect(function()
		Settings[settingKey] = not Settings[settingKey]
		checkBtn.Text = Settings[settingKey] and "ON" or "OFF"
		checkBtn.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(90, 30, 30)

		-- Если выключили конкретную опцию — сразу скрыть у всех
		if not Settings[settingKey] then
			for _, obj in pairs(EspObjects) do
				if settingKey == "BoxEsp" and obj.highlight then
					obj.highlight.Enabled = false
				elseif settingKey == "NameEsp" and obj.nameLabel then
					obj.nameLabel.Visible = false
				elseif settingKey == "HealthEsp" and obj.hpLabel then
					obj.hpLabel.Visible = false
				elseif settingKey == "DistanceEsp" and obj.distLabel then
					obj.distLabel.Visible = false
				end
			end
		end
	end)

	return row
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "Настройки ESP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.LayoutOrder = 0
title.Parent = panel

createToggleRow("Box ESP", "BoxEsp", 1)
createToggleRow("Name ESP", "NameEsp", 2)
createToggleRow("HP ESP", "HealthEsp", 3)
createToggleRow("Distance ESP", "DistanceEsp", 4)

-- Слайдер/поле максимальной дистанции
local distRow = Instance.new("Frame")
distRow.Size = UDim2.new(1, 0, 0, 28)
distRow.BackgroundTransparency = 1
distRow.LayoutOrder = 5
distRow.Parent = panel

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.6, 0, 1, 0)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Макс. дистанция"
distLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 13
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = distRow

local distBox = Instance.new("TextBox")
distBox.Size = UDim2.new(0, 60, 0, 22)
distBox.Position = UDim2.new(1, -60, 0, 3)
distBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
distBox.Text = tostring(Settings.MaxDistance)
distBox.TextColor3 = Color3.fromRGB(255, 255, 255)
distBox.Font = Enum.Font.Gotham
distBox.TextSize = 13
distBox.ClearTextOnFocus = false
distBox.Parent = distRow

local distBoxCorner = Instance.new("UICorner")
distBoxCorner.CornerRadius = UDim.new(0, 5)
distBoxCorner.Parent = distBox

distBox.FocusLost:Connect(function()
	local num = tonumber(distBox.Text)
	if num and num > 0 then
		Settings.MaxDistance = num
	else
		distBox.Text = tostring(Settings.MaxDistance)
	end
end)

-- Главный переключатель ESP
toggleButton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

local masterRow = Instance.new("Frame")
masterRow.Size = UDim2.new(1, 0, 0, 28)
masterRow.BackgroundTransparency = 1
masterRow.LayoutOrder = 6
masterRow.Parent = panel

local masterLabel = Instance.new("TextLabel")
masterLabel.Size = UDim2.new(0.7, 0, 1, 0)
masterLabel.BackgroundTransparency = 1
masterLabel.Text = "Вкл/выкл всё"
masterLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
masterLabel.Font = Enum.Font.Gotham
masterLabel.TextSize = 13
masterLabel.TextXAlignment = Enum.TextXAlignment.Left
masterLabel.Parent = masterRow

local masterBtn = Instance.new("TextButton")
masterBtn.Size = UDim2.new(0, 40, 0, 22)
masterBtn.Position = UDim2.new(1, -40, 0, 3)
masterBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
masterBtn.Text = "ON"
masterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
masterBtn.Font = Enum.Font.GothamBold
masterBtn.TextSize = 12
masterBtn.BorderSizePixel = 0
masterBtn.Parent = masterRow

local masterBtnCorner = Instance.new("UICorner")
masterBtnCorner.CornerRadius = UDim.new(0, 5)
masterBtnCorner.Parent = masterBtn

masterBtn.MouseButton1Click:Connect(function()
	Settings.EspEnabled = not Settings.EspEnabled
	masterBtn.Text = Settings.EspEnabled and "ON" or "OFF"
	masterBtn.BackgroundColor3 = Settings.EspEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(90, 30, 30)
	toggleButton.Text = Settings.EspEnabled and "ESP: ON" or "ESP: OFF"

	if not Settings.EspEnabled then
		for _, obj in pairs(EspObjects) do
			if obj.highlight then obj.highlight.Enabled = false end
			if obj.billboard then obj.billboard.Enabled = false end
		end
	end
end)

--======================================================
-- ЛОГИКА ESP
--======================================================

local function createEspForCharacter(player, character)
	if EspObjects[player] then
		-- уже есть — очищаем старое перед пересозданием
		if EspObjects[player].highlight then EspObjects[player].highlight:Destroy() end
		if EspObjects[player].billboard then EspObjects[player].billboard:Destroy() end
		EspObjects[player] = nil
	end

	local head = character:WaitForChild("Head", 5)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not head or not humanoid then return end

	-- Box ESP через Highlight (обводка модели)
	local highlight = Instance.new("Highlight")
	highlight.Name = "EspHighlight"
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.FillColor = Settings.BoxColor
	highlight.OutlineColor = Settings.BoxColor
	highlight.Adornee = character
	highlight.Parent = character
	highlight.Enabled = Settings.EspEnabled and Settings.BoxEsp

	-- BillboardGui для ника/HP/дистанции над головой
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EspBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 160, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character
	billboard.Enabled = Settings.EspEnabled

	local vLayout = Instance.new("UIListLayout")
	vLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Settings.TextColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.LayoutOrder = 1
	nameLabel.Visible = Settings.NameEsp
	nameLabel.Parent = billboard

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(1, 0, 0, 14)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = string.format("HP: %d/%d", humanoid.Health, humanoid.MaxHealth)
	hpLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextSize = 12
	hpLabel.TextStrokeTransparency = 0.5
	hpLabel.LayoutOrder = 2
	hpLabel.Visible = Settings.HealthEsp
	hpLabel.Parent = billboard

	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(1, 0, 0, 14)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "0 studs"
	distLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 12
	distLabel.TextStrokeTransparency = 0.5
	distLabel.LayoutOrder = 3
	distLabel.Visible = Settings.DistanceEsp
	distLabel.Parent = billboard

	EspObjects[player] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		hpLabel = hpLabel,
		distLabel = distLabel,
		humanoid = humanoid,
		head = head,
	}
end

local function cleanupPlayer(player)
	local obj = EspObjects[player]
	if obj then
		if obj.highlight then obj.highlight:Destroy() end
		if obj.billboard then obj.billboard:Destroy() end
		EspObjects[player] = nil
	end
end

local function setupPlayer(player)
	if player == LocalPlayer then return end -- на себя ESP не нужен

	if player.Character then
		createEspForCharacter(player, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		createEspForCharacter(player, character)
	end)

	player.CharacterRemoving:Connect(function()
		cleanupPlayer(player)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

--======================================================
-- ОБНОВЛЕНИЕ (дистанция, HP, видимость по дальности)
--======================================================
RunService.Heartbeat:Connect(function()
	local localChar = LocalPlayer.Character
	local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

	for player, obj in pairs(EspObjects) do
		if obj.head and obj.head.Parent and localRoot then
			local distance = (obj.head.Position - localRoot.Position).Magnitude
			local withinRange = distance <= Settings.MaxDistance
			local shouldShow = Settings.EspEnabled and withinRange

			-- Box
			if obj.highlight then
				obj.highlight.Enabled = shouldShow and Settings.BoxEsp
			end

			-- Billboard (общий контейнер)
			if obj.billboard then
				obj.billboard.Enabled = shouldShow
			end

			-- Name
			if obj.nameLabel then
				obj.nameLabel.Visible = Settings.NameEsp
			end

			-- HP
			if obj.hpLabel and obj.humanoid then
				obj.hpLabel.Visible = Settings.HealthEsp
				obj.hpLabel.Text = string.format("HP: %d/%d", math.max(0, math.floor(obj.humanoid.Health)), obj.humanoid.MaxHealth)

				local hpPercent = obj.humanoid.MaxHealth > 0 and (obj.humanoid.Health / obj.humanoid.MaxHealth) or 0
				obj.hpLabel.TextColor3 = Color3.fromRGB(
					math.floor(255 * (1 - hpPercent)),
					math.floor(255 * hpPercent),
					60
				)
			end

			-- Distance
			if obj.distLabel then
				obj.distLabel.Visible = Settings.DistanceEsp
				obj.distLabel.Text = string.format("%d studs", math.floor(distance))
			end
		end
	end
end)
