-- Carrega Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Serviços
local Players, RunService, Workspace, Lighting, UserInputService = 
    game:GetService("Players"), game:GetService("RunService"), game:GetService("Workspace"), 
    game:GetService("Lighting"), game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Variáveis de controle
local Config = {
    esp = false,
    hitbox = false,
    hitboxSize = 10,
    aimbot = false,
    fly = false,
    flySpeed = 50,
    noclip = false,
    fullbright = false,
    autoCollectXP = false,
    autoCollectPumpkins = false,
    autoFarm = false,
    farmDistance = 25,
    skillDelay = 0.3
}

-- Variáveis de Fly
local flyBV, flyBG, flyConn = nil, nil, nil

-- Backup Lighting
local origLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd
}

-- ============================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================

local function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChild("Humanoid")
    return hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(model)
end

local function getClosestNPC()
    local hrp = getHRP()
    if not hrp then return nil end
    
    local closest, dist = nil, math.huge
    for _, area in pairs({Workspace, Workspace:FindFirstChild("Bosses")}) do
        if area then
            for _, obj in pairs(area:GetDescendants()) do
                if isNPC(obj) and obj:FindFirstChild("HumanoidRootPart") then
                    local d = (obj.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if d < dist then closest, dist = obj, d end
                end
            end
        end
    end
    return closest
end

local function pressKey(key)
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, key, false, game)
    task.wait(0.05)
    vim:SendKeyEvent(false, key, false, game)
end

local function clickMouse()
    local vim = game:GetService("VirtualInputManager")
    local c = Camera.ViewportSize / 2
    vim:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
    task.wait(0.05)
    vim:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
end

-- ============================================
-- FUNÇÕES PRINCIPAIS
-- ============================================

local function applyESP(npc)
    if npc:FindFirstChild("ESPHighlight") then return end
    local h = Instance.new("Highlight", npc)
    h.Name = "ESPHighlight"
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
end

local function setHitbox(npc, size)
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Size = Vector3.new(size, size, size)
        hrp.Transparency = size > 2 and 0.8 or 1
        hrp.CanCollide = false
    end
end

local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    
    flyBV = Instance.new("BodyVelocity", hrp)
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    flyBG = Instance.new("BodyGyro", hrp)
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyBV or not flyBG then return end
        LocalPlayer.Character.Humanoid.PlatformStand = true
        
        local dir = Vector3.new()
        local cam = Camera.CFrame
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        
        flyBV.Velocity = dir * Config.flySpeed
        flyBG.CFrame = cam
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.PlatformStand = false
    end
end

local function setFullbright(on)
    if on then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.FogEnd = 1e6
        for _, e in pairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then e.Enabled = false end
        end
    else
        Lighting.Brightness = origLighting.Brightness
        Lighting.Ambient = origLighting.Ambient
        Lighting.OutdoorAmbient = origLighting.OutdoorAmbient
        Lighting.FogEnd = origLighting.FogEnd
        for _, e in pairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then e.Enabled = true end
        end
    end
end

-- ============================================
-- UI RAYFIELD
-- ============================================

local Window = Rayfield:CreateWindow({
    Name = "Digimon Aurity | Hub v2",
    LoadingTitle = "Carregando...",
    LoadingSubtitle = "by Script Hub",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- COMBAT TAB
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("ESP & Hitbox")

CombatTab:CreateToggle({
    Name = "ESP (Vermelho)",
    CurrentValue = false,
    Callback = function(v) Config.esp = v end
})

CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(v) Config.hitbox = v end
})

CombatTab:CreateSlider({
    Name = "Tamanho Hitbox",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(v) Config.hitboxSize = v end
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot NPC",
    CurrentValue = false,
    Callback = function(v) Config.aimbot = v end
})

CombatTab:CreateSection("Auto Farm Boss")

CombatTab:CreateToggle({
    Name = "Auto Farm Boss",
    CurrentValue = false,
    Callback = function(v) Config.autoFarm = v end
})

CombatTab:CreateSlider({
    Name = "Distância do Boss",
    Range = {10, 50},
    Increment = 5,
    CurrentValue = 25,
    Callback = function(v) Config.farmDistance = v end
})

CombatTab:CreateSlider({
    Name = "Delay entre Skills (ms)",
    Range = {100, 1000},
    Increment = 50,
    CurrentValue = 300,
    Callback = function(v) Config.skillDelay = v / 1000 end
})

CombatTab:CreateSection("Auto Collect")

CombatTab:CreateToggle({
    Name = "Auto Collect XP",
    CurrentValue = false,
    Callback = function(v) Config.autoCollectXP = v end
})

CombatTab:CreateToggle({
    Name = "Auto Collect Pumpkins 🎃",
    CurrentValue = false,
    Callback = function(v) Config.autoCollectPumpkins = v end
})

-- MOVEMENT TAB
local MoveTab = Window:CreateTab("Movement", 4483362458)

MoveTab:CreateSection("Fly")

MoveTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(v)
        Config.fly = v
        if v then startFly() else stopFly() end
    end
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 10,
    CurrentValue = 50,
    Callback = function(v) Config.flySpeed = v end
})

MoveTab:CreateSection("Noclip")

MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Config.noclip = v end
})

-- VISUAL TAB
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateSection("Iluminação")

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        Config.fullbright = v
        setFullbright(v)
    end
})

-- ============================================
-- LOOPS PRINCIPAIS
-- ============================================

-- ESP, Hitbox, Aimbot
RunService.RenderStepped:Connect(function()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isNPC(obj) then
            -- ESP
            if Config.esp then applyESP(obj)
            elseif obj:FindFirstChild("ESPHighlight") then obj.ESPHighlight:Destroy() end
            
            -- Hitbox
            setHitbox(obj, Config.hitbox and Config.hitboxSize or 2)
        end
    end
    
    -- Aimbot
    if Config.aimbot then
        local npc = getClosestNPC()
        if npc and npc:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, npc.Head.Position)
        end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if Config.noclip and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Auto Farm Boss (MELHORADO)
spawn(function()
    while true do
        if Config.autoFarm then
            local hrp = getHRP()
            local boss = getClosestNPC()
            
            if hrp and boss and boss:FindFirstChild("HumanoidRootPart") then
                local bossHRP = boss.HumanoidRootPart
                
                -- Posiciona atrás do boss na distância configurada
                local behindPos = bossHRP.CFrame * CFrame.new(0, 0, Config.farmDistance)
                hrp.CFrame = CFrame.new(behindPos.Position, bossHRP.Position)
                
                -- Aplica hitbox aumentada no boss
                if Config.hitbox then
                    setHitbox(boss, Config.hitboxSize)
                end
                
                -- Usa todas as skills em sequência
                for _, key in pairs({Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}) do
                    pressKey(key)
                    task.wait(Config.skillDelay)
                    clickMouse()
                    task.wait(0.1)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Auto Collect XP
spawn(function()
    while true do
        if Config.autoCollectXP then
            local hrp = getHRP()
            if hrp then
                for _, obj in pairs(Workspace:GetChildren()) do
                    if obj:IsA("Part") and obj.Name:find("-") and obj.Size.Magnitude < 10 then
                        local d = (obj.Position - hrp.Position).Magnitude
                        if d > 3 and d < 100 then
                            hrp.CFrame = CFrame.new(obj.Position)
                            task.wait(0.08)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Auto Collect Pumpkins
spawn(function()
    while true do
        if Config.autoCollectPumpkins then
            local hrp = getHRP()
            if hrp then
                -- Procura na pasta Pumpkins
                local folder = Workspace:FindFirstChild("Pumpkins")
                if folder then
                    for _, item in pairs(folder:GetDescendants()) do
                        if item:IsA("BasePart") then
                            local d = (item.Position - hrp.Position).Magnitude
                            if d > 2 and d < 500 then
                                hrp.CFrame = CFrame.new(item.Position + Vector3.new(0, 1, 0))
                                task.wait(0.1)
                            end
                        end
                    end
                end
                
                -- Procura no Workspace
                for _, item in pairs(Workspace:GetChildren()) do
                    if (item:IsA("BasePart") or item:IsA("Model")) and item.Name:lower():find("pumpkin") then
                        local pos = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
                        if pos then
                            local d = (pos.Position - hrp.Position).Magnitude
                            if d > 2 and d < 500 then
                                hrp.CFrame = CFrame.new(pos.Position + Vector3.new(0, 1, 0))
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function()
    stopFly()
    task.wait(1)
    if Config.fly then startFly() end
end)

-- Notificação
Rayfield:Notify({
    Title = "Script Carregado! ✅",
    Content = "Hub v2 - Otimizado",
    Duration = 5
})

print("=== DIGIMON AURITY HUB v2 ===")
print("✅ Carregado com sucesso!")
