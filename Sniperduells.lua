-- ESP + SILENT AIM COMBO
-- 500 Meter Reichweite | Smooth Updates | Auto-Refresh jede Sekunde

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ============ ORIGINAL SILENT AIM (UNVERAENDERT) ============
local target = nil
local IsPlayerFriendly = filtergc("function", {Name = "IsPlayerFriendly"}, true)

local function isVisible(targetPart)
    local origin = workspace.CurrentCamera.CFrame
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true

    local direction = (targetPart.Position - origin.Position)
    local result = workspace:Raycast(origin.Position, direction, params)

    if result then
        return Players:GetPlayerFromCharacter(result.Instance:FindFirstAncestorOfClass("Model")) ~= nil
    else
        return true
    end
end

local function GetClosestPlayer()
    local closestDistance = math.huge
    local closest = nil
    local camera = workspace.CurrentCamera

    for _, v in pairs(Players:GetPlayers()) do
        if v == LocalPlayer then continue end
        if IsPlayerFriendly(v) then continue end
        
        local char = v.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local head = char:FindFirstChild("Head")
        if not head then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - camera.ViewportSize / 2).Magnitude
            if distance < closestDistance then
                if not isVisible(head) then continue end
                closestDistance = distance
                closest = head
            end
        end
    end

    return closest
end

RunService.RenderStepped:Connect(function()
    target = GetClosestPlayer()
end)

local MultiRaycast = require(ReplicatedStorage.Modules.Misc.MultiRaycast)
local old
old = hookfunction(MultiRaycast, function(p1,p2,p3,p4,p5,p6)
    if target then
        p2 = target.Position - p1
    end
    return old(p1,p2,p3,p4,p5,p6)
end)

-- ============ ESP (500 METER) ============
local ESP_CONFIG = {
    RenderRange = 500,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowBox = true,
    ShowTeam = true,
    SelfESP = false,
}

local EspGui = Instance.new("ScreenGui")
EspGui.Name = "Esp_Overlay"
EspGui.Parent = CoreGui
EspGui.IgnoreGuiInset = true
EspGui.ResetOnSpawn = false

local ESP_Data = {}

local function createLabel()
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Size = UDim2.new(0, 120, 0, 14)
    label.Parent = EspGui
    label.Visible = false
    return label
end

local function createLine()
    local line = Instance.new("Frame")
    line.BackgroundColor3 = Color3.new(1, 1, 1)
    line.BorderSizePixel = 0
    line.ZIndex = 4
    line.Visible = false
    line.Parent = EspGui
    return line
end

local function getTeamName(player)
    if player.Team then return player.Team.Name end
    return nil
end

local function setupPlayer(player)
    if ESP_Data[player] then return end
    
    local elements = {
        Lines = {
            TLH = createLine(), TLV = createLine(), TRH = createLine(), TRV = createLine(),
            BLH = createLine(), BLV = createLine(), BRH = createLine(), BRV = createLine()
        },
        NameTag = createLabel(),
        TeamTag = createLabel(),
        DistanceTag = createLabel(),
        HealthBg = Instance.new("Frame"),
        HealthBar = Instance.new("Frame"),
        CharConn = nil,
    }
    
    elements.HealthBg.BackgroundColor3 = Color3.new(0, 0, 0)
    elements.HealthBg.BackgroundTransparency = 0.5
    elements.HealthBg.BorderSizePixel = 0
    elements.HealthBg.Visible = false
    elements.HealthBg.Parent = EspGui
    
    elements.HealthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    elements.HealthBar.BorderSizePixel = 0
    elements.HealthBar.Parent = elements.HealthBg
    
    elements.CharConn = player.CharacterAdded:Connect(function()
        for _, line in pairs(elements.Lines) do line.Visible = false end
        elements.NameTag.Visible = false
        elements.TeamTag.Visible = false
        elements.DistanceTag.Visible = false
        elements.HealthBg.Visible = false
    end)
    
    ESP_Data[player] = elements
end

local function removeESP(player)
    local data = ESP_Data[player]
    if data then
        if data.CharConn then data.CharConn:Disconnect() end
        for _, v in pairs(data.Lines) do v:Destroy() end
        data.NameTag:Destroy()
        data.TeamTag:Destroy()
        data.DistanceTag:Destroy()
        data.HealthBg:Destroy()
        ESP_Data[player] = nil
    end
end

local function updateESP()
    for player, e in pairs(ESP_Data) do
        if not player or not player.Parent then
            for _, line in pairs(e.Lines) do line.Visible = false end
            e.NameTag.Visible = false
            e.TeamTag.Visible = false
            e.DistanceTag.Visible = false
            e.HealthBg.Visible = false
            continue
        end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if player == LocalPlayer and not ESP_CONFIG.SelfESP then
            for _, line in pairs(e.Lines) do line.Visible = false end
            e.NameTag.Visible = false
            e.TeamTag.Visible = false
            e.DistanceTag.Visible = false
            e.HealthBg.Visible = false
            continue
        end
        
        if not hrp or not hum or not hum.Health or hum.Health <= 0 then
            for _, line in pairs(e.Lines) do line.Visible = false end
            e.NameTag.Visible = false
            e.TeamTag.Visible = false
            e.DistanceTag.Visible = false
            e.HealthBg.Visible = false
            continue
        end
        
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        
        if distance > ESP_CONFIG.RenderRange then
            for _, line in pairs(e.Lines) do line.Visible = false end
            e.NameTag.Visible = false
            e.TeamTag.Visible = false
            e.DistanceTag.Visible = false
            e.HealthBg.Visible = false
            continue
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            for _, line in pairs(e.Lines) do line.Visible = false end
            e.NameTag.Visible = false
            e.TeamTag.Visible = false
            e.DistanceTag.Visible = false
            e.HealthBg.Visible = false
            continue
        end
        
        local statusColor = Color3.new(1, 1, 1)
        local teamColor = nil
        
        if ESP_CONFIG.ShowTeam and player.Team then
            teamColor = player.TeamColor.Color
        end
        local displayColor = teamColor or statusColor
        
        local factor = 1 / (distance * (Camera.FieldOfView / 70)) * 1000
        local w = math.clamp(4 * factor, 20, 200)
        local h = math.clamp(6 * factor, 30, 300)
        local x, y = pos.X, pos.Y
        local nameSize = math.clamp(factor * 0.4, 9, 14)
        local thick = math.clamp(factor * 0.15, 1, 2)
        
        local currentTopOffset = h / 2 + 2
        
        if ESP_CONFIG.ShowTeam then
            local teamName = getTeamName(player)
            if teamName then
                e.TeamTag.Visible = true
                e.TeamTag.Text = teamName
                e.TeamTag.TextColor3 = teamColor or statusColor
                e.TeamTag.TextSize = nameSize
                e.TeamTag.Size = UDim2.new(0, 120, 0, nameSize)
                e.TeamTag.Position = UDim2.new(0, x - 60, 0, y - currentTopOffset - nameSize)
                currentTopOffset = currentTopOffset + nameSize + 1
            else
                e.TeamTag.Visible = false
            end
        else
            e.TeamTag.Visible = false
        end
        
        if ESP_CONFIG.ShowName then
            e.NameTag.Visible = true
            e.NameTag.Text = player.Name
            e.NameTag.TextColor3 = displayColor
            e.NameTag.TextSize = nameSize
            e.NameTag.Size = UDim2.new(0, 120, 0, nameSize)
            e.NameTag.Position = UDim2.new(0, x - 60, 0, y - currentTopOffset - nameSize)
            currentTopOffset = currentTopOffset + nameSize + 1
        else
            e.NameTag.Visible = false
        end
        
        if ESP_CONFIG.ShowDistance then
            local distRounded = math.floor(distance + 0.5)
            e.DistanceTag.Visible = true
            e.DistanceTag.Text = distRounded .. "m"
            e.DistanceTag.TextColor3 = Color3.fromRGB(180, 180, 255)
            e.DistanceTag.TextSize = nameSize - 1
            e.DistanceTag.Size = UDim2.new(0, 120, 0, nameSize)
            e.DistanceTag.Position = UDim2.new(0, x - 60, 0, y + h / 2 + 2)
        else
            e.DistanceTag.Visible = false
        end
        
        if ESP_CONFIG.ShowBox then
            local edge = w / 4
            
            local function setLine(line, px, py, sx, sy)
                line.Position = UDim2.new(0, px, 0, py)
                line.Size = UDim2.new(0, sx, 0, sy)
                line.BackgroundColor3 = displayColor
                line.Visible = true
            end
            
            setLine(e.Lines.TLH, x - w/2,        y - h/2,        edge,  thick)
            setLine(e.Lines.TLV, x - w/2,        y - h/2,        thick, edge)
            setLine(e.Lines.TRH, x + w/2 - edge, y - h/2,        edge,  thick)
            setLine(e.Lines.TRV, x + w/2,        y - h/2,        thick, edge)
            setLine(e.Lines.BLH, x - w/2,        y + h/2,        edge,  thick)
            setLine(e.Lines.BLV, x - w/2,        y + h/2 - edge, thick, edge)
            setLine(e.Lines.BRH, x + w/2 - edge, y + h/2,        edge,  thick)
            setLine(e.Lines.BRV, x + w/2,        y + h/2 - edge, thick, edge)
        else
            for _, line in pairs(e.Lines) do line.Visible = false end
        end
        
        if ESP_CONFIG.ShowHealth then
            local barW = math.clamp(factor * 0.1, 2, 4)
            local maxHp = hum.MaxHealth or 100
            local curHp = hum.Health or 0
            local hp = math.clamp(curHp / math.max(maxHp, 1), 0, 1)
            
            e.HealthBg.Position = UDim2.new(0, x - w/2 - (barW + 4), 0, y - h/2)
            e.HealthBg.Size = UDim2.new(0, barW, 0, h)
            e.HealthBar.Size = UDim2.new(1, 0, hp, 0)
            e.HealthBar.Position = UDim2.new(0, 0, 1 - hp, 0)
            e.HealthBar.BackgroundColor3 = Color3.fromHSV(hp * 0.3, 1, 1)
            e.HealthBg.Visible = true
        else
            e.HealthBg.Visible = false
        end
    end
end

-- ============ MAIN LOOP (JEDE SEKUNDE) ============
local function mainLoop()
    while task.wait(1) do
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and player.Character:FindFirstChild("Humanoid") and 
                   player.Character.Humanoid.Health > 0 then
                    setupPlayer(player)
                else
                    removeESP(player)
                end
            end
        end
        updateESP()
    end
end

RunService.RenderStepped:Connect(function()
    updateESP()
end)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        setupPlayer(p)
    end
end

Players.PlayerRemoving:Connect(removeESP)
Players.PlayerAdded:Connect(setupPlayer)

task.spawn(mainLoop)

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(0, 255, 0)
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.Text = "Silent Aim + ESP (500m)"
status.Position = UDim2.new(0.02, 0, 0.02, 0)
status.Size = UDim2.new(0, 200, 0, 25)
status.TextStrokeTransparency = 0
status.TextStrokeColor3 = Color3.new(0, 0, 0)
status.Parent = EspGui

task.spawn(function()
    while true do
        if target then
            status.Text = "Target: " .. (target.Parent and target.Parent.Name or "Unknown")
            status.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            status.Text = "No target in range"
            status.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
        task.wait(1)
    end
end)
