--[[
    Aimbot + ESP + Infinite Jump - Mod Menu blxscripts style
    - Aimbot com trava de alvo (não fica alternando no meio do tiro)
    - Logo personalizada
    - Tecla CTRL para minimizar/restaurar
    - Botão "-" para mobile
]]

--=====================================================================
-- SERVIÇOS
--=====================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

--=====================================================================
-- CONFIGURAÇÃO DA LOGO (COLOQUE O ID DA SUA IMAGEM AQUI)
--=====================================================================
local LOGO_ID = "rbxassetid://1234567890"

--=====================================================================
-- CONFIGURAÇÕES
--=====================================================================
local Config = {
    AimbotEnabled = true,
    TeamCheck     = false,
    AimPart       = "Head",
    Sensitivity   = 0,
    FOVRadius     = 80,
    FOVColor      = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 0.7,
    FOVVisible    = true,
    FOVFilled     = false,
    FOVThickness  = 0,
    FOVSides      = 64,
    Holding       = false,
    ESPEnabled    = false,
    ESPBox        = true,
    ESPName       = true,
    ESPTracer     = true,
    ESPTeamCheck  = false,
    ESPColor      = Color3.fromRGB(120, 90, 255),
    ESPNameColor  = Color3.fromRGB(255, 255, 255),
    ESPTracerColor= Color3.fromRGB(120, 90, 255),
    ESPMaxDist    = 2000,
    InfJumpEnabled= false,
}

-- Variável para travar o alvo atual
local LockedTarget = nil

--=====================================================================
-- FOV CIRCLE
--=====================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position     = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius       = Config.FOVRadius
FOVCircle.Filled       = Config.FOVFilled
FOVCircle.Color        = Config.FOVColor
FOVCircle.Visible      = Config.FOVVisible
FOVCircle.Transparency = Config.FOVTransparency
FOVCircle.NumSides     = Config.FOVSides
FOVCircle.Thickness    = Config.FOVThickness

--=====================================================================
-- AIMBOT
--=====================================================================
-- Função que verifica se um jogador é um alvo válido no momento
local function IsValidTarget(p)
    if not p or p == LocalPlayer or not p.Character then return false end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    local hum = p.Character:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return false end
    if Config.TeamCheck and p.Team == LocalPlayer.Team then return false end
    return true
end

-- Encontra o melhor alvo no FOV (usado apenas quando NÃO há alvo travado)
local function GetNewClosestPlayer()
    local maxDist = Config.FOVRadius
    local target = nil
    local shortestDist = maxDist
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, v in ipairs(Players:GetPlayers()) do
        if IsValidTarget(v) then
            local hrp = v.Character.HumanoidRootPart
            local sp = Camera:WorldToScreenPoint(hrp.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(sp.X, sp.Y)).Magnitude
                if d < shortestDist then
                    shortestDist = d
                    target = v
                end
            end
        end
    end
    return target
end

-- Verifica se o alvo travado ainda está dentro do FOV
local function IsTargetStillInFOV(p)
    if not IsValidTarget(p) then return false end
    local hrp = p.Character.HumanoidRootPart
    local sp = Camera:WorldToScreenPoint(hrp.Position)
    if sp.Z <= 0 then return false end
    local mousePos = UserInputService:GetMouseLocation()
    local d = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(sp.X, sp.Y)).Magnitude
    return d <= Config.FOVRadius
end

-- Monitora o botão direito
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.Holding = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Config.Holding = false
        LockedTarget = nil -- Solta o alvo quando solta o botão
    end
end)

--=====================================================================
-- INFINITE JUMP
--=====================================================================
local function SetupInfiniteJump()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    UserInputService.JumpRequest:Connect(function()
        if Config.InfJumpEnabled and hum and hum.Parent then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    SetupInfiniteJump()
end)
if LocalPlayer.Character then
    task.spawn(SetupInfiniteJump)
end

--=====================================================================
-- ESP
--=====================================================================
local ESP_Objects = {}
local function ClearESP()
    for _, obj in pairs(ESP_Objects) do
        if obj.highlight then obj.highlight:Destroy() end
        if obj.billboard then obj.billboard:Destroy() end
        if obj.tracer then obj.tracer:Remove() end
    end
    ESP_Objects = {}
end

local function CreateESPFor(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "blx_ESP_HL"
    highlight.Adornee = char
    highlight.FillColor = Config.ESPColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Config.ESPColor
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "blx_ESP_BB"
    billboard.Adornee = hrp
    billboard.Size = UDim2.new(0, 200, 0, 36)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = char

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.ESPNameColor
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 16)
    distLabel.Position = UDim2.new(0, 0, 0, 16)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize = 11
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = billboard

    local tracer = Drawing.new("Line")
    tracer.Color = Config.ESPTracerColor
    tracer.Thickness = 1.5
    tracer.Transparency = 0.8
    tracer.Visible = false

    ESP_Objects[player] = {
        highlight = highlight, billboard = billboard,
        nameLabel = nameLabel, distLabel = distLabel,
        tracer = tracer, hrp = hrp,
    }
end

local function UpdateESP()
    if Config.ESPEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and not ESP_Objects[p] then
                CreateESPFor(p)
            end
        end
    end
    for player, obj in pairs(ESP_Objects) do
        local shouldRemove = false
        if not Config.ESPEnabled then shouldRemove = true
        elseif not player.Character or not player.Character.Parent then shouldRemove = true
        elseif Config.ESPTeamCheck and player.Team == LocalPlayer.Team then shouldRemove = true
        end
        if shouldRemove then
            if obj.highlight then obj.highlight:Destroy() end
            if obj.billboard then obj.billboard:Destroy() end
            if obj.tracer then obj.tracer:Remove() end
            ESP_Objects[player] = nil
        else
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if obj.highlight then
                    obj.highlight.FillColor = Config.ESPColor
                    obj.highlight.OutlineColor = Config.ESPColor
                end
                if obj.billboard then obj.billboard.Enabled = Config.ESPName end
                if obj.nameLabel then obj.nameLabel.TextColor3 = Config.ESPNameColor end
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if obj.distLabel then obj.distLabel.Text = string.format("[%d studs]", math.floor(dist)) end
                if obj.tracer then
                    if Config.ESPTracer and dist <= Config.ESPMaxDist then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            obj.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            obj.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            obj.tracer.Color = Config.ESPTracerColor
                            obj.tracer.Visible = true
                        else
                            obj.tracer.Visible = false
                        end
                    else
                        obj.tracer.Visible = false
                    end
                end
            else
                if obj.tracer then obj.tracer.Visible = false end
            end
        end
    end
end

--=====================================================================
-- LOOP PRINCIPAL
--=====================================================================
RunService.RenderStepped:Connect(function()
    FOVCircle.Position     = UserInputService:GetMouseLocation()
    FOVCircle.Radius       = Config.FOVRadius
    FOVCircle.Filled       = Config.FOVFilled
    FOVCircle.Color        = Config.FOVColor
    FOVCircle.Visible      = Config.FOVVisible and Config.AimbotEnabled
    FOVCircle.Transparency = Config.FOVTransparency
    FOVCircle.NumSides     = Config.FOVSides
    FOVCircle.Thickness    = Config.FOVThickness

    if Config.Holding and Config.AimbotEnabled then
        -- 1. Se não tem alvo travado, procura um novo
        if not LockedTarget then
            LockedTarget = GetNewClosestPlayer()
        end

        -- 2. Se tem alvo travado, verifica se ele ainda é válido
        if LockedTarget then
            if not IsValidTarget(LockedTarget) or not IsTargetStillInFOV(LockedTarget) then
                -- Alvo morreu, saiu ou saiu do FOV: procura outro
                LockedTarget = GetNewClosestPlayer()
            end
        end

        -- 3. Aplica a mira no alvo (que agora está travado)
        if LockedTarget and LockedTarget.Character then
            local aimPart = LockedTarget.Character:FindFirstChild(Config.AimPart)
            if aimPart then
                TweenService:Create(
                    Camera,
                    TweenInfo.new(Config.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    { CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position) }
                ):Play()
            end
        end
    else
        -- Se não está segurando o botão, limpa o alvo
        LockedTarget = nil
    end

    pcall(UpdateESP)
end)

--=====================================================================
-- GUI
--=====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "blxscripts_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 340, 0, 580)
Main.Position = UDim2.new(0.5, -170, 0.5, -290)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local mainCorner = Instance.new("UICorner"); mainCorner.CornerRadius = UDim.new(0, 12); mainCorner.Parent = Main
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(45, 45, 55); mainStroke.Thickness = 1; mainStroke.Parent = Main

local glow = Instance.new("Frame")
glow.Size = UDim2.new(1, 0, 0, 2)
glow.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
glow.BorderSizePixel = 0
glow.Parent = Main
local glowGrad = Instance.new("UIGradient")
glowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 255)),
})
glowGrad.Parent = glow

-- LOGO
local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 12, 0, 10)
logo.BackgroundTransparency = 1
logo.Image = LOGO_ID
logo.Parent = Main
local logoCorner = Instance.new("UICorner"); logoCorner.CornerRadius = UDim.new(1, 0); logoCorner.Parent = logo

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 45)
title.Position = UDim2.new(0, 60, 0, 6)
title.BackgroundTransparency = 1
title.Text = "blxscripts | Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Main

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -120, 0, 14)
subtitle.Position = UDim2.new(0, 60, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Aimbot • ESP • Inf Jump"
subtitle.TextColor3 = Color3.fromRGB(120, 120, 130)
subtitle.TextSize = 11
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = Main

-- BOTÕES
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -90, 0, 10)
minBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
minBtn.Text = "─"
minBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = false
minBtn.Parent = Main
local minCorner = Instance.new("UICorner"); minCorner.CornerRadius = UDim.new(0, 6); minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -60, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = Main
local closeCorner = Instance.new("UICorner"); closeCorner.CornerRadius = UDim.new(0, 6); closeCorner.Parent = closeBtn

local shutdownBtn = Instance.new("TextButton")
shutdownBtn.Size = UDim2.new(0, 26, 0, 26)
shutdownBtn.Position = UDim2.new(1, -30, 0, 10)
shutdownBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
shutdownBtn.Text = "⏻"
shutdownBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
shutdownBtn.TextSize = 14
shutdownBtn.Font = Enum.Font.GothamBold
shutdownBtn.AutoButtonColor = false
shutdownBtn.Parent = Main
local shutCorner = Instance.new("UICorner"); shutCorner.CornerRadius = UDim.new(0, 6); shutCorner.Parent = shutdownBtn

local function addHover(btn, normal, hover)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
    end)
end
addHover(minBtn, Color3.fromRGB(35, 35, 42), Color3.fromRGB(60, 60, 70))
addHover(closeBtn, Color3.fromRGB(35, 35, 42), Color3.fromRGB(200, 50, 50))
addHover(shutdownBtn, Color3.fromRGB(80, 20, 20), Color3.fromRGB(200, 40, 40))

--=====================================================================
-- SHUTDOWN E MINIMIZAR
--=====================================================================
local function Shutdown()
    pcall(function() Config.AimbotEnabled = false end)
    pcall(function() Config.ESPEnabled = false end)
    pcall(function() Config.InfJumpEnabled = false end)
    pcall(ClearESP)
    pcall(function() FOVCircle:Remove() end)
    pcall(function() ScreenGui:Destroy() end)
    print("[blxscripts] Script encerrado.")
end

local isMinimized = false
local function ToggleMinimize()
    isMinimized = not isMinimized
    local targetSize = isMinimized and UDim2.new(0, 340, 0, 60) or UDim2.new(0, 340, 0, 580)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = targetSize
    }):Play()
    content.Visible = not isMinimized
end

closeBtn.MouseButton1Click:Connect(function() Main.Visible = false end)
shutdownBtn.MouseButton1Click:Connect(function() Shutdown() end)
minBtn.MouseButton1Click:Connect(ToggleMinimize)

--=====================================================================
-- CONTEÚDO DO MENU
--=====================================================================
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -75)
content.Position = UDim2.new(0, 10, 0, 60)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 100)
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = Main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function CreateSection(text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, 0, 0, 24)
    s.BackgroundTransparency = 1
    s.Text = text:upper()
    s.TextColor3 = Color3.fromRGB(120, 90, 255)
    s.TextSize = 11
    s.Font = Enum.Font.GothamBold
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Parent = content
    return s
end

local function CreateToggle(name, initial, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = content
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 38, 0, 20)
    pill.Position = UDim2.new(1, -50, 0.5, -10)
    pill.BackgroundColor3 = initial and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(50, 50, 60)
    pill.BorderSizePixel = 0
    pill.Parent = btn
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = initial and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(pill, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(0, 160, 90) or Color3.fromRGB(50, 50, 60)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if callback then callback(state) end
    end)
    return btn
end

local function CreateSlider(name, min, max, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    frame.BorderSizePixel = 0
    frame.Parent = content
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(0, 60, 0, 22)
    valueLbl.Position = UDim2.new(1, -70, 0, 6)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = tostring(initial)
    valueLbl.TextColor3 = Color3.fromRGB(120, 90, 255)
    valueLbl.TextSize = 13
    valueLbl.Font = Enum.Font.GothamBold
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right
    valueLbl.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -24, 0, 6)
    bar.Position = UDim2.new(0, 12, 0, 34)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    bar.BorderSizePixel = 0
    bar.Parent = frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    local rel = (initial - min) / (max - min)
    fill.Size = UDim2.new(rel, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(rel, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    knob.BorderSizePixel = 0
    knob.Parent = bar
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    local dragging = false
    local function updateFromX(x)
        local relX = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -7, 0.5, -7)
        local val = math.floor(min + (max - min) * relX + 0.5)
        valueLbl.Text = tostring(val)
        if callback then callback(val) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    return frame
end

local function CreateDropdown(name, options, initial, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = content
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 0, 38)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 60, 0, 38)
    val.Position = UDim2.new(1, -70, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = initial
    val.TextColor3 = Color3.fromRGB(120, 90, 255)
    val.TextSize = 13
    val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = frame

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, #options * 34 + 8)
    list.Position = UDim2.new(0, 0, 0, 38)
    list.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    list.BorderSizePixel = 0
    list.Parent = frame
    local lc = Instance.new("UIListLayout"); lc.Padding = UDim.new(0, 4); lc.Parent = list
    local lp = Instance.new("UIPadding"); lp.PaddingTop = UDim.new(0, 4); lp.Parent = list

    local open = false
    local function refresh()
        TweenService:Create(frame, TweenInfo.new(0.2), {
            Size = open and UDim2.new(1, 0, 0, 38 + #options * 34) or UDim2.new(1, 0, 0, 38)
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        refresh()
    end)

    for _, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, -8, 0, 30)
        ob.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        ob.Text = "  " .. opt
        ob.TextColor3 = Color3.fromRGB(220, 220, 220)
        ob.TextSize = 12
        ob.Font = Enum.Font.Gotham
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.AutoButtonColor = false
        ob.Parent = list
        local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 5); oc.Parent = ob

        ob.MouseEnter:Connect(function()
            TweenService:Create(ob, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(120, 90, 255)}):Play()
        end)
        ob.MouseLeave:Connect(function()
            TweenService:Create(ob, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 42)}):Play()
        end)
        ob.MouseButton1Click:Connect(function()
            val.Text = opt
            open = false
            refresh()
            if callback then callback(opt) end
        end)
    end
    return frame
end

--=====================================================================
-- CONTEÚDO DO MENU
--=====================================================================
CreateSection("Aimbot")
CreateToggle("Aimbot Enabled", Config.AimbotEnabled, function(v) Config.AimbotEnabled = v end)
CreateToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)
CreateDropdown("Aim Part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, Config.AimPart, function(v) Config.AimPart = v end)
CreateSlider("Sensitivity (x1000)", 0, 1000, 0, function(v) Config.Sensitivity = v / 1000 end)

CreateSection("FOV Circle")
CreateToggle("FOV Visible", Config.FOVVisible, function(v) Config.FOVVisible = v end)
CreateToggle("FOV Filled", Config.FOVFilled, function(v) Config.FOVFilled = v end)
CreateSlider("FOV Radius", 20, 400, Config.FOVRadius, function(v) Config.FOVRadius = v end)
CreateSlider("FOV Transparency (x100)", 0, 100, 70, function(v) Config.FOVTransparency = v / 100 end)
CreateSlider("FOV Thickness", 0, 10, 0, function(v) Config.FOVThickness = v end)

CreateSection("ESP")
CreateToggle("ESP Enabled", Config.ESPEnabled, function(v) Config.ESPEnabled = v end)
CreateToggle("ESP Team Check", Config.ESPTeamCheck, function(v) Config.ESPTeamCheck = v end)
CreateToggle("Mostrar Nome", Config.ESPName, function(v) Config.ESPName = v end)
CreateToggle("Mostrar Tracer (Linha)", Config.ESPTracer, function(v) Config.ESPTracer = v end)
CreateSlider("ESP Max Dist", 100, 5000, Config.ESPMaxDist, function(v) Config.ESPMaxDist = v end)

CreateSection("Movimento")
CreateToggle("Infinite Jump", Config.InfJumpEnabled, function(v) Config.InfJumpEnabled = v end)

-- Botão grande "Encerrar Script" no final do menu
local endBtn = Instance.new("TextButton")
endBtn.Size = UDim2.new(1, 0, 0, 42)
endBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
endBtn.BorderSizePixel = 0
endBtn.Text = "⏻  Encerrar Script"
endBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
endBtn.TextSize = 14
endBtn.Font = Enum.Font.GothamBold
endBtn.AutoButtonColor = false
endBtn.Parent = content
local endCorner = Instance.new("UICorner"); endCorner.CornerRadius = UDim.new(0, 8); endCorner.Parent = endBtn
endBtn.MouseEnter:Connect(function()
    TweenService:Create(endBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)
endBtn.MouseLeave:Connect(function()
    TweenService:Create(endBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(150, 30, 30)}):Play()
end)
endBtn.MouseButton1Click:Connect(function() Shutdown() end)

task.defer(function()
    local function upd()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
    upd()
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
end)

--=====================================================================
-- TECLA CTRL PARA MINIMIZAR
--=====================================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then
            ToggleMinimize()
        end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    pcall(ClearESP)
end)

print("[blxscripts] Menu carregado. CTRL para minimizar/restaurar.")