-- ==================== DELTA MOBILE COMPATIBILITY LAYER ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- ระบบดึง UI Parent ป้องกัน Delta Mobile บล็อก
local function GetSafeParent()
    if gethui then
        return gethui()
    elseif game:GetService("CoreGui") and pcall(function() local t = Instance.new("Folder", game:GetService("CoreGui")) t:Destroy() end) then
        return game:GetService("CoreGui")
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- ==================== UI LIBRARY (EXC HUB) ====================
local Kavo = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Kavo.CreateLib("EXC HUB | Mobile", "Midnight")

-- ปุ่มลอยบนหน้าจอมือถือ (Toggle Button)
local ToggleGui = Instance.new("ScreenGui")
local ToggleBtn = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ToggleGui.Name = "EXCHub_ToggleGui"
ToggleGui.Parent = GetSafeParent()

ToggleBtn.Name = "EXCToggleBtn"
ToggleBtn.Parent = ToggleGui
ToggleBtn.Size = UDim2.new(0, 60, 0, 50)
ToggleBtn.Position = UDim2.new(0, 15, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.Text = "EXC"
ToggleBtn.TextSize = 16
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Active = true
ToggleBtn.Draggable = true

UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleBtn

UIStroke.Color = Color3.fromRGB(255, 50, 50)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
    Kavo:ToggleUI()
end)

-- ==================== STATE VARIABLES ====================
local FeatureState = {
    speedEnabled = false,
    fastSpeed = 64,
    defaultSpeed = 16,
    infJumpEnabled = false,
    flyEnabled = false,
    flySpeed = 50,
    clickTpEnabled = false,
    noclipEnabled = false,
    invisibleEnabled = false,
    aimbotEnabled = false,
    fovVisible = false,
    fovRadius = 120,
    hitboxEnabled = false,
    hitboxSize = 10,
    espRedEnabled = false,
    espNameEnabled = false,
    espBoxEnabled = false,
    espTracerEnabled = false,
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
        fovCircle.Color = Color3.fromRGB(255, 50, 50)
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

local function SetInfJump(state) FeatureState.infJumpEnabled = state end

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
                    if parsed.nextPageCursor and not foundServer then cursor = parsed.nextPageCursor else break end
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

-- ==================== CREATE TABS & CONTROLS ====================
local PlayerTab = Window:NewTab("ผู้เล่น")
local PlayerSection = PlayerTab:NewSection("EXC Player Options")

PlayerSection:NewToggle("วิ่งเร็ว (WalkSpeed)", "เปิด/ปิด การวิ่งเร็ว", function(state) SetSpeed(state) end)
PlayerSection:NewSlider("ระดับความเร็ว", "ปรับความเร็ววิ่ง", 200, 16, function(s) SetSpeed(FeatureState.speedEnabled, s) end)
PlayerSection:NewToggle("กระโดดไม่จำกัด (Inf Jump)", "กระโดดได้เรื่อยๆ", function(state) SetInfJump(state) end)
PlayerSection:NewToggle("บิน (Fly)", "เปิด/ปิด การบิน", function(state) SetFly(state) end)
PlayerSection:NewSlider("ความเร็วการบิน", "ปรับความเร็วบิน", 300, 10, function(s) SetFly(FeatureState.flyEnabled, s) end)
PlayerSection:NewToggle("เดินทะลุ (Noclip)", "เดินทะลุกำแพง", function(state) SetNoclip(state) end)
PlayerSection:NewToggle("คลิกวาร์ป (Click TP)", "กดหน้าจอเพื่อวาร์ป", function(state) SetClickTP(state) end)
PlayerSection:NewToggle("ตัวล่องหน (Invisible)", "ล่องหนซ่อนตัว", function(state) SetInvisible(state) end)

local CombatTab = Window:NewTab("ต่อสู้")
local CombatSection = CombatTab:NewSection("EXC Combat Options")

CombatSection:NewToggle("ล็อคเป้า (Aimbot)", "ล็อคเป้าอัตโนมัติ", function(state) SetAimbot(state) end)
CombatSection:NewToggle("แสดงวงกลม FOV", "แสดงวงกลมระยะล็อค", function(state) SetFOVVisible(state) end)
CombatSection:NewSlider("รัศมี FOV", "ปรับขนาดวงกลม", 500, 30, function(s) SetFOVRadius(s) end)
CombatSection:NewToggle("ขยายตัวศัตรู (Hitbox)", "ทำให้ยิงง่ายขึ้น", function(state) SetHitbox(state) end)
CombatSection:NewSlider("ขนาด Hitbox", "ปรับขนาดตัวศัตรู", 50, 2, function(s) SetHitbox(FeatureState.hitboxEnabled, s) end)

local ESPTab = Window:NewTab("มองทะลุ")
local ESPSection = ESPTab:NewSection("EXC Visuals (ESP)")

ESPSection:NewToggle("ESP ตัวแดง (Highlight)", "แสดงออร่าสีแดง", function(state) SetESPRed(state) end)
ESPSection:NewToggle("ESP แสดงชื่อ", "มองเห็นชื่อทะลุกำแพง", function(state) SetESPName(state) end)
ESPSection:NewToggle("ESP กรอบสี่เหลี่ยม", "แสดงกรอบรอบตัว", function(state) SetESPBox(state) end)
ESPSection:NewToggle("ESP เส้นโยง (Tracer)", "ลากเส้นไปยังศัตรู", function(state) SetESPTracer(state) end)

local MiscTab = Window:NewTab("ทั่วไป")
local MiscSection = MiscTab:NewSection("EXC Tools & Misc")

MiscSection:NewToggle("กด E ไวอัตโนมัติ (Fast E)", "กดปุ่มปฏิสัมพันธ์ทันที", function(state) SetFastE(state) end)
MiscSection:NewToggle("ผลักคนรอบข้าง (Fling)", "ทำให้คนที่เข้าใกล้กระเด็น", function(state) SetFling(state) end)
MiscSection:Button("ปรับภาพต่ำแก้กระตุก", function() SetLowGraphics(true) end)
MiscSection:Button("ย้ายไปเซิฟคนเดียว 1 คน", function() ServerHopOnePlayer() end)