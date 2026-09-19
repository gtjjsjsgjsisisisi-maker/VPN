-- ==================== EXC HUB (RAYFIELD UI - DELTA MOBILE) ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- Safe UI Parent for Delta Mobile
local function GetSafeParent()
    if gethui then
        return gethui()
    elseif game:GetService("CoreGui") and pcall(function() local t = Instance.new("Folder", game:GetService("CoreGui")) t:Destroy() end) then
        return game:GetService("CoreGui")
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

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

-- ==================== ISOLATED BACKGROUND LOOPS ====================
task.spawn(function()
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
end)

task.spawn(function()
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
end)

task.spawn(function()
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
end)

-- FIXED FLING LOOP (SPIN FLING + VELOCITY LOCK)
task.spawn(function()
    RunService.Heartbeat:Connect(function()
        if FeatureState.flingEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            
            -- ล็อคความเร็วแกน Y ไม่ให้ตัวเราปลิวขึ้นฟ้า
            local currentVel = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)

            local targetNearby = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local targetHRP = p.Character.HumanoidRootPart
                    if (targetHRP.Position - hrp.Position).Magnitude <= 10 then
                        targetNearby = true
                    end
                end
            end

            -- หมุนตัวเราด้วยความเร็วสูงเมื่ออยู่ใกล้ศัตรูเพื่อผลักให้อีกฝ่ายกระเด็น
            if targetNearby then
                hrp.AssemblyAngularVelocity = Vector3.new(0, 999999, 0)
            else
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
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

task.spawn(function()
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
end)

-- ==================== RAYFIELD UI LIBRARY ====================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Swiftz/UI-Library/main/Libraries/Rayfield%20-%20Library.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "EXC HUB | Mobile",
    LoadingTitle = "EXC HUB Loading...",
    LoadingSubtitle = "by EXC",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "EXCHubConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvatelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- ปุ่มลอยหน้าจอมือถือสลับซ่อน/แสดง Rayfield UI
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
    local safeParent = GetSafeParent()
    local rfGui = safeParent:FindFirstChild("Rayfield") or game:GetService("CoreGui"):FindFirstChild("Rayfield")
    if rfGui then
        rfGui.Enabled = not rfGui.Enabled
    end
end)

-- ==================== TABS & CONTROLS ====================
local PlayerTab = Window:CreateTab("ผู้เล่น", 4483362458)
PlayerTab:CreateSection("EXC Player Options")

PlayerTab:CreateToggle({
    Name = "วิ่งเร็ว (WalkSpeed)",
    CurrentValue = false,
    Flag = "WalkSpeedToggle",
    Callback = function(Value) SetSpeed(Value) end,
})

PlayerTab:CreateSlider({
    Name = "ระดับความเร็ว",
    Range = {16, 200},
    Increment = 1,
    Suffix = " Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value) SetSpeed(FeatureState.speedEnabled, Value) end,
})

PlayerTab:CreateToggle({
    Name = "กระโดดไม่จำกัด (Inf Jump)",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(Value) SetInfJump(Value) end,
})

PlayerTab:CreateToggle({
    Name = "บิน (Fly)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value) SetFly(Value) end,
})

PlayerTab:CreateSlider({
    Name = "ความเร็วการบิน",
    Range = {10, 300},
    Increment = 5,
    Suffix = " Fly Speed",
    CurrentValue = 50,
    Flag = "FlySpeedSlider",
    Callback = function(Value) SetFly(FeatureState.flyEnabled, Value) end,
})

PlayerTab:CreateToggle({
    Name = "เดินทะลุ (Noclip)",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value) SetNoclip(Value) end,
})

PlayerTab:CreateToggle({
    Name = "คลิกวาร์ป (Click TP)",
    CurrentValue = false,
    Flag = "ClickTPToggle",
    Callback = function(Value) SetClickTP(Value) end,
})

PlayerTab:CreateToggle({
    Name = "ตัวล่องหน (Invisible)",
    CurrentValue = false,
    Flag = "InvisibleToggle",
    Callback = function(Value) SetInvisible(Value) end,
})

local CombatTab = Window:CreateTab("ต่อสู้", 4483362458)
CombatTab:CreateSection("EXC Combat Options")

CombatTab:CreateToggle({
    Name = "ล็อคเป้า (Aimbot)",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value) SetAimbot(Value) end,
})

CombatTab:CreateToggle({
    Name = "แสดงวงกลม FOV",
    CurrentValue = false,
    Flag = "FOVToggle",
    Callback = function(Value) SetFOVVisible(Value) end,
})

CombatTab:CreateSlider({
    Name = "รัศมี FOV",
    Range = {30, 500},
    Increment = 10,
    Suffix = " FOV",
    CurrentValue = 120,
    Flag = "FOVSlider",
    Callback = function(Value) SetFOVRadius(Value) end,
})

CombatTab:CreateToggle({
    Name = "ขยายตัวศัตรู (Hitbox)",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value) SetHitbox(Value) end,
})

CombatTab:CreateSlider({
    Name = "ขนาด Hitbox",
    Range = {2, 50},
    Increment = 1,
    Suffix = " Size",
    CurrentValue = 10,
    Flag = "HitboxSlider",
    Callback = function(Value) SetHitbox(FeatureState.hitboxEnabled, Value) end,
})

local ESPTab = Window:CreateTab("มองทะลุ", 4483362458)
ESPTab:CreateSection("EXC Visuals (ESP)")

ESPTab:CreateToggle({
    Name = "ESP ตัวแดง (Highlight)",
    CurrentValue = false,
    Flag = "ESPRedToggle",
    Callback = function(Value) SetESPRed(Value) end,
})

ESPTab:CreateToggle({
    Name = "ESP แสดงชื่อ",
    CurrentValue = false,
    Flag = "ESPNameToggle",
    Callback = function(Value) SetESPName(Value) end,
})

ESPTab:CreateToggle({
    Name = "ESP กรอบสี่เหลี่ยม",
    CurrentValue = false,
    Flag = "ESPBoxToggle",
    Callback = function(Value) SetESPBox(Value) end,
})

ESPTab:CreateToggle({
    Name = "ESP เส้นโยง (Tracer)",
    CurrentValue = false,
    Flag = "ESPTracerToggle",
    Callback = function(Value) SetESPTracer(Value) end,
})

local MiscTab = Window:CreateTab("ทั่วไป", 4483362458)
MiscTab:CreateSection("EXC Tools & Misc")

MiscTab:CreateToggle({
    Name = "กด E ไวอัตโนมัติ (Fast E)",
    CurrentValue = false,
    Flag = "FastEToggle",
    Callback = function(Value) SetFastE(Value) end,
})

MiscTab:CreateToggle({
    Name = "ผลักคนรอบข้าง (Fling)",
    CurrentValue = false,
    Flag = "FlingToggle",
    Callback = function(Value) SetFling(Value) end,
})

MiscTab:CreateButton({
    Name = "ปรับภาพต่ำแก้กระตุก",
    Callback = function() SetLowGraphics(true) end,
})

MiscTab:CreateButton({
    Name = "ย้ายไปเซิฟคนเดียว 1 คน",
    Callback = function() ServerHopOnePlayer() end,
})

-- ==================== LOAD NOTIFICATION ====================
Rayfield:Notify({
    Title = "EXC HUB",
    Content = "แก้ไขระบบ Fling เรียบร้อย!",
    Duration = 5,
    Image = 4483362458,
})