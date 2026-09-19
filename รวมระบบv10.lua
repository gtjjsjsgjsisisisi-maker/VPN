-- ==================== EXC HUB (WITH TARGET FOLLOW & POSES) ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- Safe UI Parent for Mobile Executors
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
    espBoxEnabled = false,
    espTracerEnabled = false,
    fastEEnabled = false,
    -- Target Follow Variables
    targetFollowEnabled = false,
    targetPlayerName = nil,
    targetPose = "1. นั่งหัว"
}

local flyConnection, bodyVel, bodyGyro = nil, nil, nil
local flyGui = nil
local flyUpPressed = false
local flyDownPressed = false
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

local function SetInfJump(state) FeatureState.infJumpEnabled = state end

-- ==================== FLY CONTROL UI & LOGIC ====================
local function CreateFlyUI()
    if flyGui then flyGui:Destroy() end

    flyGui = Instance.new("ScreenGui")
    flyGui.Name = "EXC_FlyGui"
    flyGui.Parent = GetSafeParent()
    flyGui.ResetOnSpawn = false

    local frame = Instance.new("Frame", flyGui)
    frame.Size = UDim2.new(0, 110, 0, 145)
    frame.Position = UDim2.new(0.85, -60, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(120, 60, 220)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 24)
    title.Position = UDim2.new(0, 0, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "✈️ FLY CONTROL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 13

    local btnUp = Instance.new("TextButton", frame)
    btnUp.Size = UDim2.new(1, -16, 0, 30)
    btnUp.Position = UDim2.new(0, 8, 0, 30)
    btnUp.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btnUp.Text = "⬆️ ขึ้น"
    btnUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnUp.Font = Enum.Font.SourceSansBold
    btnUp.TextSize = 13
    btnUp.AutoButtonColor = true
    Instance.new("UICorner", btnUp).CornerRadius = UDim.new(0, 6)

    local btnDown = Instance.new("TextButton", frame)
    btnDown.Size = UDim2.new(1, -16, 0, 30)
    btnDown.Position = UDim2.new(0, 8, 0, 66)
    btnDown.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btnDown.Text = "⬇️ ลง"
    btnDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnDown.Font = Enum.Font.SourceSansBold
    btnDown.TextSize = 13
    btnDown.AutoButtonColor = true
    Instance.new("UICorner", btnDown).CornerRadius = UDim.new(0, 6)

    local btnStop = Instance.new("TextButton", frame)
    btnStop.Size = UDim2.new(1, -16, 0, 30)
    btnStop.Position = UDim2.new(0, 8, 0, 102)
    btnStop.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
    btnStop.Text = "❌ เลิกบิน"
    btnStop.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStop.Font = Enum.Font.SourceSansBold
    btnStop.TextSize = 13
    btnStop.AutoButtonColor = true
    Instance.new("UICorner", btnStop).CornerRadius = UDim.new(0, 6)

    btnUp.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            flyUpPressed = true
        end
    end)
    btnUp.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            flyUpPressed = false
        end
    end)

    btnDown.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            flyDownPressed = true
        end
    end)
    btnDown.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            flyDownPressed = false
        end
    end)

    btnStop.MouseButton1Click:Connect(function()
        SetFly(false)
        pcall(function()
            if Rayfield and Rayfield.Flags and Rayfield.Flags["FlyToggle"] then
                Rayfield.Flags["FlyToggle"]:Set(false)
            end
        end)
    end)
end

local function StopFlying()
    FeatureState.flyEnabled = false
    flyUpPressed = false
    flyDownPressed = false
    if flyGui then
        flyGui:Destroy()
        flyGui = nil
    end
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

    CreateFlyUI()

    flyConnection = RunService.RenderStepped:Connect(function()
        if not FeatureState.flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            StopFlying()
            return
        end
        local moveVec = hum.MoveDirection
        local camCF = camera.CFrame
        local vel = Vector3.zero

        if moveVec.Magnitude > 0 then
            local camLook, camRight = camCF.LookVector, camCF.RightVector
            local flyDir = (camLook * moveVec:Dot(Vector3.new(camLook.X, 0, camLook.Z).Unit)) + (camRight * moveVec:Dot(Vector3.new(camRight.X, 0, camRight.Z).Unit))
            vel = flyDir.Unit * FeatureState.flySpeed
        end

        if flyUpPressed then
            vel = vel + Vector3.new(0, FeatureState.flySpeed, 0)
        elseif flyDownPressed then
            vel = vel - Vector3.new(0, FeatureState.flySpeed, 0)
        end

        bodyVel.Velocity = vel
        bodyGyro.CFrame = camCF
    end)
end

function SetFly(state, speed)
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

local function SetTargetFollow(state)
    FeatureState.targetFollowEnabled = state
    if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

-- ==================== CUSTOM SERVER HOP UI ====================
local function CreateServerHopUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "EXC_ServerHopGui"
    sg.Parent = GetSafeParent()
    sg.ResetOnSpawn = false

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 400, 0, 220)
    main.Position = UDim2.new(0.5, -200, 0.5, -110)
    main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    main.BorderSizePixel = 0
    main.Parent = sg

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(120, 60, 220)
    stroke.Thickness = 2.5

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "EXC HUB"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local subtitle = Instance.new("TextLabel", main)
    subtitle.Size = UDim2.new(1, -40, 0, 20)
    subtitle.Position = UDim2.new(0, 20, 0, 42)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "ระบบสุ่มค้นหาเซิร์ฟเวอร์ 1 คน"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
    subtitle.TextSize = 13
    subtitle.Font = Enum.Font.SourceSans
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local statusBox = Instance.new("Frame", main)
    statusBox.Size = UDim2.new(1, -40, 0, 90)
    statusBox.Position = UDim2.new(0, 20, 0, 68)
    statusBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    statusBox.BorderSizePixel = 0

    local boxCorner = Instance.new("UICorner", statusBox)
    boxCorner.CornerRadius = UDim.new(0, 12)

    local statusText1 = Instance.new("TextLabel", statusBox)
    statusText1.Size = UDim2.new(1, 0, 0, 24)
    statusText1.Position = UDim2.new(0, 0, 0, 10)
    statusText1.BackgroundTransparency = 1
    statusText1.Text = "🔍 กำลังค้นหาเซิร์ฟเวอร์..."
    statusText1.TextColor3 = Color3.fromRGB(240, 240, 240)
    statusText1.TextSize = 14
    statusText1.Font = Enum.Font.SourceSansBold

    local statusText2 = Instance.new("TextLabel", statusBox)
    statusText2.Size = UDim2.new(1, 0, 0, 24)
    statusText2.Position = UDim2.new(0, 0, 0, 34)
    statusText2.BackgroundTransparency = 1
    statusText2.Text = "🎲 กำลังย้ายเซิร์ฟเวอร์..."
    statusText2.TextColor3 = Color3.fromRGB(240, 240, 240)
    statusText2.TextSize = 14
    statusText2.Font = Enum.Font.SourceSansBold

    local statusText3 = Instance.new("TextLabel", statusBox)
    statusText3.Size = UDim2.new(1, 0, 0, 24)
    statusText3.Position = UDim2.new(0, 0, 0, 58)
    statusText3.BackgroundTransparency = 1
    statusText3.Text = "✅ ตั้งค่ารันสคริปต์หลังย้ายแล้ว"
    statusText3.TextColor3 = Color3.fromRGB(240, 240, 240)
    statusText3.TextSize = 14
    statusText3.Font = Enum.Font.SourceSansBold

    local progressBarBg = Instance.new("Frame", main)
    progressBarBg.Size = UDim2.new(1, -40, 0, 6)
    progressBarBg.Position = UDim2.new(0, 20, 0, 168)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    progressBarBg.BorderSizePixel = 0

    local pBgCorner = Instance.new("UICorner", progressBarBg)
    pBgCorner.CornerRadius = UDim.new(1, 0)

    local progressBarFill = Instance.new("Frame", progressBarBg)
    progressBarFill.Size = UDim2.new(0, 0, 1, 0)
    progressBarFill.BackgroundColor3 = Color3.fromRGB(46, 213, 115)
    progressBarFill.BorderSizePixel = 0

    local pFillCorner = Instance.new("UICorner", progressBarFill)
    pFillCorner.CornerRadius = UDim.new(1, 0)

    local footer = Instance.new("TextLabel", main)
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 0, 185)
    footer.BackgroundTransparency = 1
    footer.Text = "สร้างโดย EXC HUB"
    footer.TextColor3 = Color3.fromRGB(110, 110, 120)
    footer.TextSize = 12
    footer.Font = Enum.Font.SourceSans

    return sg, statusText1, progressBarFill
end

local function ServerHopOnePlayer()
    task.spawn(function()
        local hopUI, txtFound, barFill = CreateServerHopUI()
        barFill:TweenSize(UDim2.new(0.4, 0, 1, 0), "Out", "Linear", 0.4, true)

        local placeId = game.PlaceId
        local foundServer = nil
        local cursor = ""
        local totalCount = 0

        while not foundServer do
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end

            local success, rawData = pcall(function() return game:HttpGet(url) end)
            if success and rawData then
                local parsed = HttpService:JSONDecode(rawData)
                if parsed and parsed.data then
                    for _, server in ipairs(parsed.data) do
                        if server.playing == 1 then
                            totalCount = totalCount + 1
                            if server.id ~= game.JobId and not foundServer then
                                foundServer = server.id
                            end
                        end
                    end
                    if parsed.nextPageCursor and not foundServer then cursor = parsed.nextPageCursor else break end
                else break end
            else break end
            task.wait(0.2)
        end

        if foundServer then
            txtFound.Text = "✅ พบเซิร์ฟเวอร์ 1 คน " .. tostring(totalCount > 0 and totalCount or 300) .. " เซิร์ฟ"
            barFill:TweenSize(UDim2.new(1, 0, 1, 0), "Out", "Linear", 0.5, true)
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(placeId, foundServer, LocalPlayer)
        else
            txtFound.Text = "❌ ไม่พบเซิร์ฟเวอร์ที่มีผู้เล่น 1 คน"
            task.wait(2)
            if hopUI then hopUI:Destroy() end
        end
    end)
end

-- ==================== EVENT LOOPS ====================
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

-- Target Follow Loop (4 ท่าทาง)
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        if FeatureState.targetFollowEnabled and FeatureState.targetPlayerName then
            local targetPlayer = Players:FindFirstChild(FeatureState.targetPlayerName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myHrp = LocalPlayer.Character.HumanoidRootPart
                local myHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                local targetHead = targetPlayer.Character.Head

                if myHum then 
                    myHum.PlatformStand = true 
                end

                for _, p in pairs(LocalPlayer.Character:GetChildren()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end

                local offset = CFrame.new(0, 1.8, 0)
                local pose = FeatureState.targetPose

                if pose:find("นั่งหัว") then
                    offset = CFrame.new(0, 1.8, 0)
                elseif pose:find("ยืนบนหัว") then
                    offset = CFrame.new(0, 2.5, 0)
                elseif pose:find("นั่งไหล่") then
                    offset = CFrame.new(1.2, 0.6, 0)
                elseif pose:find("ขี่คอ") then
                    offset = CFrame.new(0, 1.2, -0.4)
                end

                myHrp.CFrame = targetHead.CFrame * offset
                myHrp.Velocity = Vector3.zero
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

-- Hitbox Loop (ปรับเป็นสีแดง)
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                if FeatureState.hitboxEnabled then
                    hrp.Size = Vector3.new(FeatureState.hitboxSize, FeatureState.hitboxSize, FeatureState.hitboxSize)
                    hrp.Transparency = 0.7
                    hrp.BrickColor = BrickColor.new("Bright red")
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
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
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local boxEsp = hrp:FindFirstChild("EXC_BoxESP")
            if boxEsp then boxEsp:Destroy() end
        end
    end
end

Players.PlayerRemoving:Connect(cleanupPlayerESP)

-- ESP Loop
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        local viewportSize = camera.ViewportSize
        local bottomScreenPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
                    local hrp = char.HumanoidRootPart

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

-- ==================== RAYFIELD LIBRARY INITIALIZATION ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "EXC HUB | Clean UI",
    LoadingTitle = "EXC HUB",
    LoadingSubtitle = "by EXC",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

-- ==================== CUSTOM TRANSPARENCY & RIGHT SIDEBAR ====================
task.spawn(function()
    task.wait(0.5)
    local safeParent = GetSafeParent()
    
    local function applyCustomUI(container)
        for _, gui in pairs(container:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name:lower():find("rayfield") or gui:FindFirstChild("Main")) then
                local mainFrame = gui:FindFirstChild("Main") or gui:FindFirstChild("MainFrame") or gui:FindFirstChildOfClass("Frame")
                if mainFrame then
                    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    RunService.RenderStepped:Connect(function()
                        if mainFrame and mainFrame.Parent then
                            mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                        end
                    end)

                    mainFrame.BackgroundTransparency = 0.4
                    for _, desc in pairs(mainFrame:GetDescendants()) do
                        if desc:IsA("Frame") or desc:IsA("ScrollingFrame") or desc:IsA("CanvasGroup") then
                            if desc.BackgroundTransparency < 0.9 then
                                desc.BackgroundTransparency = 0.4
                            end
                        end
                        if desc:IsA("GuiObject") then
                            if desc.BackgroundColor3.R > 0.7 and desc.BackgroundColor3.G < 0.3 then
                                desc.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                            end
                        end
                    end

                    local tabHolder = mainFrame:FindFirstChild("TabHolder") or mainFrame:FindFirstChild("SideBar") or mainFrame:FindFirstChild("Navigation")
                    local elementsHolder = mainFrame:FindFirstChild("Elements") or mainFrame:FindFirstChild("Container") or mainFrame:FindFirstChild("Pages")

                    if tabHolder and elementsHolder then
                        tabHolder.Position = UDim2.new(1, -tabHolder.AbsoluteSize.X - 8, tabHolder.Position.Y.Scale, tabHolder.Position.Y.Offset)
                        elementsHolder.Position = UDim2.new(0, 8, elementsHolder.Position.Y.Scale, elementsHolder.Position.Y.Offset)
                    end
                end
            end
        end
    end

    applyCustomUI(safeParent)
    applyCustomUI(game:GetService("CoreGui"))
end)

-- Helper Function Get Player Names
local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "ไม่มีผู้เล่นอื่น") end
    return list
end

-- ==================== TABS & CONTROLS ====================
local PlayerTab = Window:CreateTab("ผู้เล่น", nil)
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

-- TAB: ติดตามผู้เล่น
local TargetTab = Window:CreateTab("ติดตามผู้เล่น", nil)
TargetTab:CreateSection("Target Follow System")

local PlayerDropdown = TargetTab:CreateDropdown({
    Name = "เลือกเป้าหมาย",
    Options = GetPlayerList(),
    CurrentOption = GetPlayerList()[1],
    MultipleOptions = false,
    Flag = "TargetPlayerDropdown",
    Callback = function(Option)
        local selected = typeof(Option) == "table" and Option[1] or Option
        FeatureState.targetPlayerName = selected
    end,
})

TargetTab:CreateButton({
    Name = "🔄 อัปเดตรายชื่อผู้เล่น",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerList())
    end,
})

TargetTab:CreateDropdown({
    Name = "เลือกท่าทาง",
    Options = {"1. นั่งหัว", "2. ยืนบนหัว", "3. นั่งไหล่", "4. ขี่คอ"},
    CurrentOption = "1. นั่งหัว",
    MultipleOptions = false,
    Flag = "TargetPoseDropdown",
    Callback = function(Option)
        local selected = typeof(Option) == "table" and Option[1] or Option
        FeatureState.targetPose = selected
    end,
})

TargetTab:CreateToggle({
    Name = "เปิดระบบติดตาม",
    CurrentValue = false,
    Flag = "TargetFollowToggle",
    Callback = function(Value) SetTargetFollow(Value) end,
})

-- Auto update player list when players join/leave
Players.PlayerAdded:Connect(function()
    pcall(function() PlayerDropdown:Refresh(GetPlayerList()) end)
end)
Players.PlayerRemoving:Connect(function()
    pcall(function() PlayerDropdown:Refresh(GetPlayerList()) end)
end)

local CombatTab = Window:CreateTab("ต่อสู้", nil)
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

local ESPTab = Window:CreateTab("มองทะลุ", nil)
ESPTab:CreateSection("EXC Visuals (ESP)")

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

local MiscTab = Window:CreateTab("ทั่วไป", nil)
MiscTab:CreateSection("EXC Tools & Misc")

MiscTab:CreateToggle({
    Name = "กด E ไวอัตโนมัติ (Fast E)",
    CurrentValue = false,
    Flag = "FastEToggle",
    Callback = function(Value) SetFastE(Value) end,
})

MiscTab:CreateButton({
    Name = "ปรับภาพต่ำแก้กระตุก",
    Callback = function() SetLowGraphics(true) end,
})

MiscTab:CreateButton({
    Name = "ย้ายไปเซิฟคนเดียว 1 คน",
    Callback = function() ServerHopOnePlayer() end,
})