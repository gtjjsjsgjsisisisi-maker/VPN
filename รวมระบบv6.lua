-- ==================== LOAD UI LIBRARY ====================
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({
    Name = "KING SHOP - รวมระบบ v4", 
    HidePremium = false, 
    SaveConfig = false, 
    IntroText = "กำลังโหลดระบบ..."
})

-- ==================== SERVICES & VARIABLES ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- ==================== STATE VARIABLES ====================
local FeatureState = {
    -- Player
    speedEnabled = false,
    fastSpeed = 64,
    defaultSpeed = 16,
    infJumpEnabled = false,
    flyEnabled = false,
    flySpeed = 50,
    clickTpEnabled = false,
    noclipEnabled = false,
    invisibleEnabled = false,
    
    -- Combat
    aimbotEnabled = false,
    fovVisible = false,
    fovRadius = 120,
    hitboxEnabled = false,
    hitboxSize = 10,
    
    -- ESP
    espRedEnabled = false,
    espNameEnabled = false,
    espBoxEnabled = false,
    espTracerEnabled = false,
    
    -- Tools
    fastEEnabled = false,
    flingEnabled = false
}

local flyConnection, bodyVel, bodyGyro = nil, nil, nil
local tracerLines = {}
local fovCircle = nil

pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1
        fovCircle.NumSides = 40
        fovCircle.Radius = FeatureState.fovRadius
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end)

-- ==================== CORE FUNCTIONS ====================

local function SetSpeed(state, speed)
    FeatureState.speedEnabled = state
    if speed then FeatureState.fastSpeed = speed end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = FeatureState.speedEnabled and FeatureState.fastSpeed or FeatureState.defaultSpeed
    end
end

local function SetInfJump(state)
    FeatureState.infJumpEnabled = state
end

local function StopFlying()
    FeatureState.flyEnabled = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

local function StartFlying()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    FeatureState.flyEnabled = true
    hum.PlatformStand = true
    bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)

    flyConnection = RunService.RenderStepped:Connect(function()
        if not FeatureState.flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            StopFlying()
            return
        end
        local moveVec = hum.MoveDirection
        local camCF = camera.CFrame
        if moveVec.Magnitude > 0 then
            local camLook, camRight = camCF.LookVector, camCF.RightVector
            local flyDir = (camLook * moveVec:Dot(Vector3.new(camLook.X, 0, camLook.Z).Unit)) + (camRight * moveVec:Dot(Vector3.new(camRight.X, 0, camRight.Z).Unit))
            bodyVel.Velocity = flyDir.Unit * FeatureState.flySpeed
        else
            bodyVel.Velocity = Vector3.zero
        end
        bodyGyro.CFrame = camCF
    end)
end

local function SetFly(state, speed)
    if speed then FeatureState.flySpeed = speed end
    if state then StartFlying() else StopFlying() end
end

local function SetClickTP(state) FeatureState.clickTpEnabled = state end
local function SetNoclip(state) FeatureState.noclipEnabled = state end

local function SetInvisible(state)
    FeatureState.invisibleEnabled = state
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = state and 1 or 0
            end
        end
    end
end

local function SetAimbot(state) FeatureState.aimbotEnabled = state end
local function SetFOVVisible(state) FeatureState.fovVisible = state end
local function SetFOVRadius(radius) 
    FeatureState.fovRadius = radius 
    if fovCircle then fovCircle.Radius = radius end
end
local function SetHitbox(state, size)
    FeatureState.hitboxEnabled = state
    if size then FeatureState.hitboxSize = size end
end

local function SetESPRed(state) FeatureState.espRedEnabled = state end
local function SetESPName(state) FeatureState.espNameEnabled = state end
local function SetESPBox(state) FeatureState.espBoxEnabled = state end
local function SetESPTracer(state) FeatureState.espTracerEnabled = state end

local function SetLowGraphics(state)
    if state then
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then 
                part.Material = Enum.Material.SmoothPlastic
            elseif part:IsA("Decal") or part:IsA("Texture") then 
                part.Transparency = 1 
            end
        end
    end
end

local function SetFastE(state) FeatureState.fastEEnabled = state end
local function SetFling(state) FeatureState.flingEnabled = state end

local function ServerHopOnePlayer()
    task.spawn(function()
        local placeId = game.PlaceId
        local foundServer = nil
        local cursor = ""

        while not foundServer do
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end

            local success, rawData = pcall(function() return game:HttpGet(url) end)
            if success and rawData then
                local parsed = HttpService:JSONDecode(rawData)
                if parsed and parsed.data then
                    for _, server in ipairs(parsed.data) do
                        if server.id ~= game.JobId and server.playing == 1 then
                            foundServer = server.id
                            break
                        end
                    end
                    if parsed.nextPageCursor and not foundServer then 
                        cursor = parsed.nextPageCursor 
                    else 
                        break 
                    end
                else break end
            else break end
            task.wait(0.2)
        end

        if foundServer then
            TeleportService:TeleportToPlaceInstance(placeId, foundServer, LocalPlayer)
        end
    end)
end

-- ==================== BACKGROUND EVENT LOOPS ====================

UserInputService.JumpRequest:Connect(function()
    if FeatureState.infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

mouse.Button1Down:Connect(function()
    if FeatureState.clickTpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and mouse.Hit then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if FeatureState.fastEEnabled then pcall(function() fireproximityprompt(prompt) end) end
end)

RunService.Stepped:Connect(function()
    if FeatureState.noclipEnabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fovCircle.Visible = FeatureState.fovVisible and FeatureState.aimbotEnabled
    end
    if FeatureState.aimbotEnabled then
        local target = nil
        local shortestDist = FeatureState.fovRadius
        local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChildOfClass("Humanoid") then
                if p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            target = p
                        end
                    end
                end
            end
        end
        if target and target.Character and target.Character:FindFirstChild("Head") then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            if FeatureState.hitboxEnabled then
                hrp.Size = Vector3.new(FeatureState.hitboxSize, FeatureState.hitboxSize, FeatureState.hitboxSize)
                hrp.Transparency = 0.8
                hrp.BrickColor = BrickColor.new("Dark stone grey")
                hrp.CanCollide = false
            else
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if FeatureState.flingEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.AssemblyAngularVelocity = Vector3.zero
        if math.abs(hrp.AssemblyLinearVelocity.Y) > 25 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = p.Character.HumanoidRootPart
                if (targetHRP.Position - hrp.Position).Magnitude <= 8 then
                    pcall(function()
                        targetHRP.AssemblyLinearVelocity = Vector3.new(
                            math.random(-25000, 25000),
                            250000,
                            math.random(-25000, 25000)
                        )
                    end)
                end
            end
        end
    end
end)

local function cleanupPlayerESP(player)
    if tracerLines[player] then
        pcall(function() tracerLines[player]:Remove() end)
        tracerLines[player] = nil
    end
    if player.Character then
        local red = player.Character:FindFirstChild("EXC_RedESP")
        if red then red:Destroy() end
        
        local head = player.Character:FindFirstChild("Head")
        if head then
            local nameEsp = head:FindFirstChild("EXC_NameESP")
            if nameEsp then nameEsp:Destroy() end
        end

        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local boxEsp = hrp:FindFirstChild("EXC_BoxESP")
            if boxEsp then boxEsp:Destroy() end
        end
    end
end

Players.PlayerRemoving:Connect(cleanupPlayerESP)

RunService.RenderStepped:Connect(function()
    local viewportSize = camera.ViewportSize
    local bottomScreenPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
                local hrp = char.HumanoidRootPart
                local head = char:FindFirstChild("Head")

                local redHighlight = char:FindFirstChild("EXC_RedESP")
                if FeatureState.espRedEnabled then
                    if not redHighlight then
                        redHighlight = Instance.new("Highlight")
                        redHighlight.Name = "EXC_RedESP"
                        redHighlight.FillColor = Color3.fromRGB(255, 30, 30)
                        redHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        redHighlight.FillTransparency = 0.35
                        redHighlight.OutlineTransparency = 0
                        redHighlight.Parent = char
                    end
                elseif redHighlight then
                    redHighlight:Destroy()
                end

                if head then
                    local nameEsp = head:FindFirstChild("EXC_NameESP")
                    if FeatureState.espNameEnabled then
                        if not nameEsp then
                            nameEsp = Instance.new("BillboardGui")
                            nameEsp.Name = "EXC_NameESP"
                            nameEsp.Size = UDim2.new(0, 200, 0, 30)
                            nameEsp.StudsOffset = Vector3.new(0, 2.5, 0)
                            nameEsp.AlwaysOnTop = true
                            nameEsp.Parent = head

                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                            label.TextColor3 = Color3.fromRGB(255, 255, 255)
                            label.TextStrokeTransparency = 0
                            label.Font = Enum.Font.SourceSansBold
                            label.TextSize = 13
                            label.Parent = nameEsp
                        end
                    elseif nameEsp then
                        nameEsp:Destroy()
                    end
                end

                local boxEsp = hrp:FindFirstChild("EXC_BoxESP")
                if FeatureState.espBoxEnabled then
                    if not boxEsp then
                        boxEsp = Instance.new("BillboardGui")
                        boxEsp.Name = "EXC_BoxESP"
                        boxEsp.Size = UDim2.new(4.5, 0, 6, 0)
                        boxEsp.AlwaysOnTop = true
                        boxEsp.Parent = hrp

                        local boxFrame = Instance.new("Frame")
                        boxFrame.Size = UDim2.new(1, 0, 1, 0)
                        boxFrame.BackgroundTransparency = 1
                        boxFrame.Parent = boxEsp

                        local boxStroke = Instance.new("UIStroke")
                        boxStroke.Color = Color3.fromRGB(255, 255, 255)
                        boxStroke.Thickness = 1.5
                        boxStroke.Parent = boxFrame
                    end
                elseif boxEsp then
                    boxEsp:Destroy()
                end

                local line = tracerLines[p]
                if not line and Drawing then
                    pcall(function()
                        line = Drawing.new("Line")
                        line.Thickness = 1.5
                        line.Color = Color3.fromRGB(255, 255, 255)
                        line.Transparency = 1
                        line.Visible = false
                        tracerLines[p] = line
                    end)
                end

                if line then
                    if FeatureState.espTracerEnabled then
                        local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            line.From = bottomScreenPos
                            line.To = Vector2.new(screenPos.X, screenPos.Y)
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    else
                        line.Visible = false
                    end
                end
            else
                cleanupPlayerESP(p)
            end
        end
    end
end)

-- ==================== CREATE UI TABS & CONTROLS ====================

local PlayerTab = Window:MakeTab({Name = "ผู้เล่น (Player)", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local CombatTab = Window:MakeTab({Name = "ต่อสู้ (Combat)", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local ESPTab = Window:MakeTab({Name = "มองทะลุ (ESP)", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MiscTab = Window:MakeTab({Name = "ทั่วไป (Misc)", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- 1. Player Tab
PlayerTab:AddToggle({
    Name = "วิ่งเร็ว (WalkSpeed)",
    Default = false,
    Callback = function(Value) SetSpeed(Value) end    
})

PlayerTab:AddSlider({
    Name = "ตั้งค่าความเร็ววิ่ง",
    Min = 16,
    Max = 200,
    Default = 64,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value) SetSpeed(FeatureState.speedEnabled, Value) end    
})

PlayerTab:AddToggle({
    Name = "กระโดดไม่จำกัด (Inf Jump)",
    Default = false,
    Callback = function(Value) SetInfJump(Value) end    
})

PlayerTab:AddToggle({
    Name = "บิน (Fly)",
    Default = false,
    Callback = function(Value) SetFly(Value) end    
})

PlayerTab:AddSlider({
    Name = "ความเร็วในการบิน",
    Min = 10,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "Speed",
    Callback = function(Value) SetFly(FeatureState.flyEnabled, Value) end    
})

PlayerTab:AddToggle({
    Name = "เดินทะลุสิ่งขวางกั้น (Noclip)",
    Default = false,
    Callback = function(Value) SetNoclip(Value) end    
})

PlayerTab:AddToggle({
    Name = "คลิกวาร์ป (Click TP)",
    Default = false,
    Callback = function(Value) SetClickTP(Value) end    
})

PlayerTab:AddToggle({
    Name = "ตัวล่องหน (Invisible)",
    Default = false,
    Callback = function(Value) SetInvisible(Value) end    
})

-- 2. Combat Tab
CombatTab:AddToggle({
    Name = "ล็อคเป้าอัตโนมัติ (Aimbot)",
    Default = false,
    Callback = function(Value) SetAimbot(Value) end    
})

CombatTab:AddToggle({
    Name = "แสดงวงกลม FOV",
    Default = false,
    Callback = function(Value) SetFOVVisible(Value) end    
})

CombatTab:AddSlider({
    Name = "ขนาดรัศมี FOV",
    Min = 30,
    Max = 500,
    Default = 120,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 5,
    ValueName = "Radius",
    Callback = function(Value) SetFOVRadius(Value) end    
})

CombatTab:AddToggle({
    Name = "ขยายขนาดตัวศัตรู (Hitbox)",
    Default = false,
    Callback = function(Value) SetHitbox(Value) end    
})

CombatTab:AddSlider({
    Name = "ขนาด Hitbox",
    Min = 2,
    Max = 50,
    Default = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Size",
    Callback = function(Value) SetHitbox(FeatureState.hitboxEnabled, Value) end    
})

-- 3. ESP Tab
ESPTab:AddToggle({
    Name = "ESP ตัวแดง (Highlight)",
    Default = false,
    Callback = function(Value) SetESPRed(Value) end    
})

ESPTab:AddToggle({
    Name = "ESP แสดงชื่อผู้เล่น",
    Default = false,
    Callback = function(Value) SetESPName(Value) end    
})

ESPTab:AddToggle({
    Name = "ESP กรอบสี่เหลี่ยมขาว",
    Default = false,
    Callback = function(Value) SetESPBox(Value) end    
})

ESPTab:AddToggle({
    Name = "ESP เส้นโยงไปยังเป้าหมาย (Tracer)",
    Default = false,
    Callback = function(Value) SetESPTracer(Value) end    
})

-- 4. Misc Tab
MiscTab:AddToggle({
    Name = "กด E ไวอัตโนมัติ (Fast E)",
    Default = false,
    Callback = function(Value) SetFastE(Value) end    
})

MiscTab:AddToggle({
    Name = "ผลักคนรอบข้างกระเด็น (Fling)",
    Default = false,
    Callback = function(Value) SetFling(Value) end    
})

MiscTab:AddButton({
    Name = "ปรับภาพต่ำแก้กระตุก (Low Graphics)",
    Callback = function() SetLowGraphics(true) end    
})

MiscTab:AddButton({
    Name = "ย้ายไปห้องที่มีผู้เล่น 1 คน (Server Hop 1 Player)",
    Callback = function() ServerHopOnePlayer() end    
})

OrionLib:Init()