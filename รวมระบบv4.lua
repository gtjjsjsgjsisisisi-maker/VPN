-- ==================== SERVICES & VARIABLES ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

-- สถานะฟังก์ชัน
local speedEnabled, fastSpeed, defaultSpeed = false, 64, 16
local infJumpEnabled = false
local flyEnabled, flySpeed, flyConnection, bodyVel, bodyGyro = false, 50, nil, nil, nil
local clickTpEnabled, noclipEnabled, invisibleEnabled = false, false, false
local fastEEnabled, flingEnabled = false, false
local aimbotEnabled, fovVisible, fovRadius, hitboxEnabled, hitboxSize = false, false, 120, false, 10

-- สถานะฟังก์ชัน มอง ESP (4 ปุ่ม)
local espRedEnabled = false
local espNameEnabled = false
local espBoxEnabled = false
local espTracerEnabled = false

-- ==================== HELPER: DRAGGABLE UI ====================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==================== SCREEN GUI CREATION ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EXC_Hub_CustomUI"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ==================== TOGGLE FLOATING BUTTON (ไอคอน + ชื่อสคริปต์) ====================
local ToggleBtn = Instance.new("Frame")
ToggleBtn.Name = "ToggleFloatingBtn"
ToggleBtn.Size = UDim2.new(0, 145, 0, 42)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ToggleBtn.BackgroundTransparency = 0.2
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Active = true
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(0, 10)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Transparency = 0.3
ToggleStroke.Thickness = 1.2

local ToggleIcon = Instance.new("ImageLabel")
ToggleIcon.Name = "Icon"
ToggleIcon.Size = UDim2.new(0, 26, 0, 26)
ToggleIcon.Position = UDim2.new(0, 8, 0.5, -13)
ToggleIcon.Image = "rbxassetid://559906823"
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.ScaleType = Enum.ScaleType.Fit
ToggleIcon.Parent = ToggleBtn

local ToggleTitle = Instance.new("TextLabel")
ToggleTitle.Name = "Title"
ToggleTitle.Size = UDim2.new(1, -42, 1, 0)
ToggleTitle.Position = UDim2.new(0, 38, 0, 0)
ToggleTitle.Text = "EXC HUB"
ToggleTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleTitle.TextSize = 13
ToggleTitle.Font = Enum.Font.SourceSansBold
ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
ToggleTitle.BackgroundTransparency = 1
ToggleTitle.Parent = ToggleBtn

local ToggleClickBtn = Instance.new("TextButton")
ToggleClickBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleClickBtn.BackgroundTransparency = 1
ToggleClickBtn.Text = ""
ToggleClickBtn.Parent = ToggleBtn

makeDraggable(ToggleBtn, ToggleBtn)

-- ==================== MAIN WINDOW ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 660, 0, 410)
MainFrame.Position = UDim2.new(0.5, -330, 0.5, -205)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MainFrame.BackgroundTransparency = 0.2 -- ใสๆนิดนึง
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Transparency = 0.7
MainStroke.Thickness = 1

local DragHeader = Instance.new("Frame")
DragHeader.Name = "DragHeader"
DragHeader.Size = UDim2.new(1, 0, 0, 40)
DragHeader.BackgroundTransparency = 1
DragHeader.Parent = MainFrame

makeDraggable(MainFrame, DragHeader)

ToggleClickBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==================== HEADER TITLE & CLOSE BUTTON ====================
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Name = "HeaderTitle"
HeaderTitle.Size = UDim2.new(1, -270, 0, 25)
HeaderTitle.Position = UDim2.new(0, 220, 0, 10)
HeaderTitle.Text = "EXC HUB X | DELTA EDITION"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.TextSize = 13
HeaderTitle.Font = Enum.Font.SourceSansBold
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame

local CloseBtnCorner = Instance.new("UICorner", CloseBtn)
CloseBtnCorner.CornerRadius = UDim.new(0, 6)

local CloseBtnStroke = Instance.new("UIStroke", CloseBtn)
CloseBtnStroke.Color = Color3.fromRGB(80, 80, 80)
CloseBtnStroke.Thickness = 1

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- ==================== LEFT SIDEBAR ====================
local LeftCard = Instance.new("Frame")
LeftCard.Name = "LeftCard"
LeftCard.Size = UDim2.new(0, 200, 1, -20)
LeftCard.Position = UDim2.new(0, 10, 0, 10)
LeftCard.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
LeftCard.BackgroundTransparency = 0.3
LeftCard.BorderSizePixel = 0
LeftCard.Parent = MainFrame

local LeftCorner = Instance.new("UICorner", LeftCard)
LeftCorner.CornerRadius = UDim.new(0, 10)

local LeftStroke = Instance.new("UIStroke", LeftCard)
LeftStroke.Color = Color3.fromRGB(255, 255, 255)
LeftStroke.Transparency = 0.85
LeftStroke.Thickness = 1

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.Position = UDim2.new(0.5, -35, 0, 15)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AvatarImg.BorderSizePixel = 0
AvatarImg.Parent = LeftCard

local AvatarCorner = Instance.new("UICorner", AvatarImg)
AvatarCorner.CornerRadius = UDim.new(1, 0)

local AvatarStroke = Instance.new("UIStroke", AvatarImg)
AvatarStroke.Color = Color3.fromRGB(255, 255, 255)
AvatarStroke.Thickness = 1.5

local PlayerName = Instance.new("TextLabel")
PlayerName.Size = UDim2.new(1, -20, 0, 20)
PlayerName.Position = UDim2.new(0, 10, 0, 92)
PlayerName.Text = LocalPlayer.DisplayName
PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerName.TextSize = 14
PlayerName.Font = Enum.Font.SourceSansBold
PlayerName.BackgroundTransparency = 1
PlayerName.Parent = LeftCard

local PlayerUser = Instance.new("TextLabel")
PlayerUser.Size = UDim2.new(1, -20, 0, 15)
PlayerUser.Position = UDim2.new(0, 10, 0, 110)
PlayerUser.Text = "@" .. LocalPlayer.Name
PlayerUser.TextColor3 = Color3.fromRGB(150, 150, 150)
PlayerUser.TextSize = 11
PlayerUser.Font = Enum.Font.SourceSans
PlayerUser.BackgroundTransparency = 1
PlayerUser.Parent = LeftCard

local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, -30, 0, 1)
Line.Position = UDim2.new(0, 15, 0, 135)
Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Line.BorderSizePixel = 0
Line.Parent = LeftCard

local StatsList = Instance.new("Frame")
StatsList.Size = UDim2.new(1, -20, 0, 220)
StatsList.Position = UDim2.new(0, 10, 0, 145)
StatsList.BackgroundTransparency = 1
StatsList.Parent = LeftCard

local StatsLayout = Instance.new("UIListLayout", StatsList)
StatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatsLayout.Padding = UDim.new(0, 10)

local FpsLabel = Instance.new("TextLabel")
FpsLabel.Size = UDim2.new(1, 0, 0, 20)
FpsLabel.Text = "FPS: --"
FpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
FpsLabel.TextSize = 13
FpsLabel.Font = Enum.Font.SourceSansBold
FpsLabel.BackgroundTransparency = 1
FpsLabel.Parent = StatsList

local HpTitle = Instance.new("TextLabel")
HpTitle.Size = UDim2.new(1, 0, 0, 15)
HpTitle.Text = "HP: 100 / 100"
HpTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
HpTitle.TextXAlignment = Enum.TextXAlignment.Left
HpTitle.TextSize = 12
HpTitle.Font = Enum.Font.SourceSans
HpTitle.BackgroundTransparency = 1
HpTitle.Parent = StatsList

local HpBarBack = Instance.new("Frame")
HpBarBack.Size = UDim2.new(1, 0, 0, 8)
HpBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
HpBarBack.BorderSizePixel = 0
HpBarBack.Parent = StatsList

local HpBarCorner = Instance.new("UICorner", HpBarBack)
HpBarCorner.CornerRadius = UDim.new(1, 0)

local HpBarFill = Instance.new("Frame")
HpBarFill.Size = UDim2.new(1, 0, 1, 0)
HpBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HpBarFill.BorderSizePixel = 0
HpBarFill.Parent = HpBarBack

local HpFillCorner = Instance.new("UICorner", HpBarFill)
HpFillCorner.CornerRadius = UDim.new(1, 0)

local MapTitle = Instance.new("TextLabel")
MapTitle.Size = UDim2.new(1, 0, 0, 15)
MapTitle.Text = "MAP INFO:"
MapTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
MapTitle.TextXAlignment = Enum.TextXAlignment.Left
MapTitle.TextSize = 11
MapTitle.Font = Enum.Font.SourceSansBold
MapTitle.BackgroundTransparency = 1
MapTitle.Parent = StatsList

local MapNameLabel = Instance.new("TextLabel")
MapNameLabel.Size = UDim2.new(1, 0, 0, 35)
MapNameLabel.Text = "Loading Map..."
MapNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MapNameLabel.TextXAlignment = Enum.TextXAlignment.Left
MapNameLabel.TextYAlignment = Enum.TextYAlignment.Top
MapNameLabel.TextWrapped = true
MapNameLabel.TextSize = 12
MapNameLabel.Font = Enum.Font.SourceSans
MapNameLabel.BackgroundTransparency = 1
MapNameLabel.Parent = StatsList

-- ==================== RIGHT CONTENT & TABS ====================
local RightFrame = Instance.new("Frame")
RightFrame.Name = "RightFrame"
RightFrame.Size = UDim2.new(1, -230, 1, -50)
RightFrame.Position = UDim2.new(0, 220, 0, 40)
RightFrame.BackgroundTransparency = 1
RightFrame.Parent = MainFrame

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 35)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TabBar.BackgroundTransparency = 0.3
TabBar.BorderSizePixel = 0
TabBar.Parent = RightFrame

local TabBarCorner = Instance.new("UICorner", TabBar)
TabBarCorner.CornerRadius = UDim.new(0, 8)

local TabBarLayout = Instance.new("UIListLayout", TabBar)
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
TabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabBarLayout.Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -45)
ContentContainer.Position = UDim2.new(0, 0, 0, 45)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = RightFrame

local Tabs, ScrollFrames = {}, {}

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 98, 1, 0)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    TabBtn.TextSize = 13
    TabBtn.Font = Enum.Font.SourceSansBold
    TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    TabBtn.BackgroundTransparency = 0.4
    TabBtn.BorderSizePixel = 0
    TabBtn.Parent = TabBar

    local BtnCorner = Instance.new("UICorner", TabBtn)
    BtnCorner.CornerRadius = UDim.new(0, 6)

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    Scroll.Visible = false
    Scroll.Parent = ContentContainer

    local List = Instance.new("UIListLayout", Scroll)
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)

    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 10)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do t.TextColor3 = Color3.fromRGB(150, 150, 150) t.BackgroundColor3 = Color3.fromRGB(20, 20, 25) end
        for _, s in pairs(ScrollFrames) do s.Visible = false end
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Scroll.Visible = true
    end)

    table.insert(Tabs, TabBtn)
    table.insert(ScrollFrames, Scroll)
    return Scroll
end

local PlayerScroll = CreateTab("ตัวละคร")
local CombatScroll = CreateTab("ต่อสู้")
local ESPScroll = CreateTab("มอง ESP")
local ToolsScroll = CreateTab("เครื่องมือ")

Tabs[1].TextColor3 = Color3.fromRGB(255, 255, 255)
Tabs[1].BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ScrollFrames[1].Visible = true

-- ==================== UI BUILDER HELPERS ====================
local function AddToggle(parent, text, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -8, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    Frame.BackgroundTransparency = 0.3
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -50, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 13
    Label.Font = Enum.Font.SourceSansBold
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 24, 0, 24)
    Switch.Position = UDim2.new(1, -34, 0.5, -12)
    Switch.Text = ""
    Switch.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 45, 45)
    Switch.BorderSizePixel = 0
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner", Switch)
    SwitchCorner.CornerRadius = UDim.new(0, 4)

    local state = default
    Switch.MouseButton1Click:Connect(function()
        state = not state
        Switch.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 45, 45)
        callback(state)
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -8, 0, 48)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    Frame.BackgroundTransparency = 0.3
    Frame.BorderSizePixel = 0
    Frame.Parent = parent

    local Corner = Instance.new("UICorner", Frame)
    Corner.CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.Text = text .. " : " .. default
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextSize = 13
    Label.Font = Enum.Font.SourceSansBold
    Label.BackgroundTransparency = 1
    Label.Parent = Frame

    local SliderBack = Instance.new("TextButton")
    SliderBack.Size = UDim2.new(1, -24, 0, 8)
    SliderBack.Position = UDim2.new(0, 12, 0, 30)
    SliderBack.Text = ""
    SliderBack.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    SliderBack.BorderSizePixel = 0
    SliderBack.Parent = Frame

    local SliderCorner = Instance.new("UICorner", SliderBack)
    SliderCorner.CornerRadius = UDim.new(1, 0)

    local SliderFill = Instance.new("Frame")
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderBack

    local FillCorner = Instance.new("UICorner", SliderFill)
    FillCorner.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        SliderFill.Size = UDim2.new(pos, 0, 1, 0)
        Label.Text = text .. " : " .. val
        callback(val)
    end

    SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function AddButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -8, 0, 36)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 13
    Btn.Font = Enum.Font.SourceSansBold
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Btn.BackgroundTransparency = 0.3
    Btn.BorderSizePixel = 0
    Btn.Parent = parent

    local Corner = Instance.new("UICorner", Btn)
    Corner.CornerRadius = UDim.new(0, 6)

    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Color = Color3.fromRGB(70, 70, 70)
    Stroke.Thickness = 1

    Btn.MouseButton1Click:Connect(callback)
end

-- ==================== SERVER SCANNER POPUP ====================
local function CreateServerScannerUI()
    local existing = ScreenGui:FindFirstChild("ScanPopUp")
    if existing then existing:Destroy() end

    local ScanFrame = Instance.new("Frame")
    ScanFrame.Name = "ScanPopUp"
    ScanFrame.Size = UDim2.new(0, 360, 0, 230)
    ScanFrame.Position = UDim2.new(0.5, -180, 0.5, -115)
    ScanFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    ScanFrame.BackgroundTransparency = 0.15
    ScanFrame.BorderSizePixel = 0
    ScanFrame.ZIndex = 20
    ScanFrame.Parent = ScreenGui

    local Corner = Instance.new("UICorner", ScanFrame)
    Corner.CornerRadius = UDim.new(0, 14)

    local Stroke = Instance.new("UIStroke", ScanFrame)
    Stroke.Color = Color3.fromRGB(60, 60, 65)
    Stroke.Thickness = 1.5

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -30, 0, 28)
    Title.Position = UDim2.new(0, 20, 0, 15)
    Title.Text = "EXC HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextSize = 22
    Title.Font = Enum.Font.SourceSansBold
    Title.BackgroundTransparency = 1
    Title.ZIndex = 21
    Title.Parent = ScanFrame

    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -30, 0, 18)
    Subtitle.Position = UDim2.new(0, 20, 0, 43)
    Subtitle.Text = "ระบบสุ่มค้นหาเซิร์ฟเวอร์ 1 คน"
    Subtitle.TextColor3 = Color3.fromRGB(160, 160, 160)
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.TextSize = 13
    Subtitle.Font = Enum.Font.SourceSans
    Subtitle.BackgroundTransparency = 1
    Subtitle.ZIndex = 21
    Subtitle.Parent = ScanFrame

    local StatusBox = Instance.new("Frame")
    StatusBox.Size = UDim2.new(1, -40, 0, 95)
    StatusBox.Position = UDim2.new(0, 20, 0, 68)
    StatusBox.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    StatusBox.BackgroundTransparency = 0.3
    StatusBox.BorderSizePixel = 0
    StatusBox.ZIndex = 21
    StatusBox.Parent = ScanFrame

    local BoxCorner = Instance.new("UICorner", StatusBox)
    BoxCorner.CornerRadius = UDim.new(0, 10)

    local BoxStroke = Instance.new("UIStroke", StatusBox)
    BoxStroke.Color = Color3.fromRGB(38, 38, 45)
    BoxStroke.Thickness = 1

    local StatusLayout = Instance.new("UIListLayout", StatusBox)
    StatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    StatusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    StatusLayout.Padding = UDim.new(0, 4)

    local Step1 = Instance.new("TextLabel")
    Step1.Size = UDim2.new(1, -20, 0, 20)
    Step1.Text = "🔍 กำลังสแกนหาเซิร์ฟเวอร์..."
    Step1.TextColor3 = Color3.fromRGB(220, 220, 220)
    Step1.TextSize = 13
    Step1.Font = Enum.Font.SourceSansBold
    Step1.BackgroundTransparency = 1
    Step1.ZIndex = 22
    Step1.Parent = StatusBox

    local Step2 = Instance.new("TextLabel")
    Step2.Size = UDim2.new(1, -20, 0, 20)
    Step2.Text = "🎲 กำลังย้ายเซิร์ฟเวอร์..."
    Step2.TextColor3 = Color3.fromRGB(180, 180, 180)
    Step2.TextSize = 13
    Step2.Font = Enum.Font.SourceSans
    Step2.BackgroundTransparency = 1
    Step2.ZIndex = 22
    Step2.Visible = false
    Step2.Parent = StatusBox

    local Step3 = Instance.new("TextLabel")
    Step3.Size = UDim2.new(1, -20, 0, 20)
    Step3.Text = "✅ ตั้งค่ารันสคริปต์หลังย้ายแล้ว"
    Step3.TextColor3 = Color3.fromRGB(180, 180, 180)
    Step3.TextSize = 13
    Step3.Font = Enum.Font.SourceSans
    Step3.BackgroundTransparency = 1
    Step3.ZIndex = 22
    Step3.Visible = false
    Step3.Parent = StatusBox

    local ProgressBarBack = Instance.new("Frame")
    ProgressBarBack.Size = UDim2.new(1, -40, 0, 6)
    ProgressBarBack.Position = UDim2.new(0, 20, 0, 172)
    ProgressBarBack.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ProgressBarBack.BorderSizePixel = 0
    ProgressBarBack.ZIndex = 21
    ProgressBarBack.Parent = ScanFrame

    local BarCorner = Instance.new("UICorner", ProgressBarBack)
    BarCorner.CornerRadius = UDim.new(1, 0)

    local ProgressBarFill = Instance.new("Frame")
    ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressBarFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    ProgressBarFill.BorderSizePixel = 0
    ProgressBarFill.ZIndex = 22
    ProgressBarFill.Parent = ProgressBarBack

    local FillCorner = Instance.new("UICorner", ProgressBarFill)
    FillCorner.CornerRadius = UDim.new(1, 0)

    local Footer = Instance.new("TextLabel")
    Footer.Size = UDim2.new(1, 0, 0, 18)
    Footer.Position = UDim2.new(0, 0, 0, 195)
    Footer.Text = "สร้างโดย EXC HUB"
    Footer.TextColor3 = Color3.fromRGB(120, 120, 130)
    Footer.TextSize = 11
    Footer.Font = Enum.Font.SourceSans
    Footer.BackgroundTransparency = 1
    Footer.ZIndex = 21
    Footer.Parent = ScanFrame

    return ScanFrame, Step1, Step2, Step3, ProgressBarFill
end

-- ==================== POPULATE TABS ====================
-- Tab: ตัวละคร
AddToggle(PlayerScroll, "วิ่งเร็ว (WalkSpeed)", false, function(v)
    speedEnabled = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = speedEnabled and fastSpeed or defaultSpeed
    end
end)

AddSlider(PlayerScroll, "ระดับความเร็ว", 16, 200, 64, function(v)
    fastSpeed = v
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = fastSpeed
    end
end)

AddToggle(PlayerScroll, "กระโดดไม่จำกัด (Inf Jump)", false, function(v) infJumpEnabled = v end)

local function stopFlying()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVel then bodyVel:Destroy() bodyVel = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

local function startFlying()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    flyEnabled = true
    hum.PlatformStand = true
    bodyVel = Instance.new("BodyVelocity", hrp)
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            stopFlying()
            return
        end
        local moveVec = hum.MoveDirection
        local camCF = camera.CFrame
        if moveVec.Magnitude > 0 then
            local camLook, camRight = camCF.LookVector, camCF.RightVector
            local flyDir = (camLook * moveVec:Dot(Vector3.new(camLook.X, 0, camLook.Z).Unit)) + (camRight * moveVec:Dot(Vector3.new(camRight.X, 0, camRight.Z).Unit))
            bodyVel.Velocity = flyDir.Unit * flySpeed
        else
            bodyVel.Velocity = Vector3.zero
        end
        bodyGyro.CFrame = camCF
    end)
end

AddToggle(PlayerScroll, "บิน (Fly Camera)", false, function(v)
    if v then startFlying() else stopFlying() end
end)

AddSlider(PlayerScroll, "ความเร็วบิน", 10, 300, 50, function(v) flySpeed = v end)
AddToggle(PlayerScroll, "วาร์ปตามจุดที่กด (Click TP)", false, function(v) clickTpEnabled = v end)
AddToggle(PlayerScroll, "เดินทะลุกำแพง (Noclip)", false, function(v) noclipEnabled = v end)
AddToggle(PlayerScroll, "หายตัว (Invisible)", false, function(v)
    invisibleEnabled = v
    if LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = v and 1 or 0
            end
        end
    end
end)

-- Tab: ต่อสู้
local fovCircle = nil
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1
        fovCircle.NumSides = 40
        fovCircle.Radius = fovRadius
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
    end
end)

AddToggle(CombatScroll, "ล็อคเป้า (Aimbot)", false, function(v) aimbotEnabled = v end)
AddToggle(CombatScroll, "แสดงวงกลม FOV", false, function(v) fovVisible = v end)
AddSlider(CombatScroll, "ขนาดขอบเขต FOV", 30, 500, 120, function(v) fovRadius = v end)
AddToggle(CombatScroll, "ขยาย Hitbox ศัตรู", false, function(v) hitboxEnabled = v end)
AddSlider(CombatScroll, "ขนาด Hitbox", 2, 50, 10, function(v) hitboxSize = v end)

-- Tab: มอง ESP (สวิตช์เปิด-ปิด 4 ปุ่ม)
AddToggle(ESPScroll, "มองทะลุสีแดง", false, function(v) espRedEnabled = v end)
AddToggle(ESPScroll, "มองทะลุชื่อ", false, function(v) espNameEnabled = v end)
AddToggle(ESPScroll, "มองแบบกรอบสีขาว", false, function(v) espBoxEnabled = v end)
AddToggle(ESPScroll, "มองแบบเส้น (เส้นอยู่ข้างล่าง)", false, function(v) espTracerEnabled = v end)

-- Tab: เครื่องมือ
AddToggle(ToolsScroll, "ลดกราฟิก เพิ่ม FPS", false, function(v)
    if v then
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then part.Material = Enum.Material.SmoothPlastic
            elseif part:IsA("Decal") or part:IsA("Texture") then part.Transparency = 1 end
        end
    end
end)

AddToggle(ToolsScroll, "หยิบของเร็ว (Fast E)", false, function(v) fastEEnabled = v end)

AddButton(ToolsScroll, "ย้ายเข้าเซิฟ 1 คน (Scan 1 Player)", function()
    task.spawn(function()
        local popUp, step1, step2, step3, progressFill = CreateServerScannerUI()
        
        progressFill.Size = UDim2.new(0.2, 0, 1, 0)
        
        local placeId = game.PlaceId
        local foundServer = nil
        local cursor = ""
        local scannedCount = 0

        while not foundServer do
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end

            local success, rawData = pcall(function() return game:HttpGet(url) end)
            if success and rawData then
                local parsed = HttpService:JSONDecode(rawData)
                if parsed and parsed.data then
                    scannedCount = scannedCount + #parsed.data
                    step1.Text = "✅ พบเซิร์ฟเวอร์ 1 คน " .. scannedCount .. " เซิร์ฟ"
                    
                    for _, server in ipairs(parsed.data) do
                        if server.id ~= game.JobId and server.playing == 1 then
                            foundServer = server.id
                            break
                        end
                    end
                    if parsed.nextPageCursor and not foundServer then 
                        cursor = parsed.nextPageCursor 
                        progressFill.Size = UDim2.new(0.5, 0, 1, 0)
                    else 
                        break 
                    end
                else break end
            else break end
            task.wait(0.2)
        end

        if foundServer then
            progressFill.Size = UDim2.new(0.8, 0, 1, 0)
            step2.Visible = true
            step3.Visible = true
            task.wait(0.5)
            progressFill.Size = UDim2.new(1, 0, 1, 0)
            task.wait(0.3)
            TeleportService:TeleportToPlaceInstance(placeId, foundServer, LocalPlayer)
        else
            step1.Text = "❌ ไม่พบเซิร์ฟเวอร์ที่มีผู้เล่น 1 คน"
            task.wait(2)
            popUp:Destroy()
        end
    end)
end)

AddToggle(ToolsScroll, "ชนคนกระเด็น (ไม่หมุนตัว + ไม่กระเด็นเอง)", false, function(v) flingEnabled = v end)

-- ==================== ESP SYSTEM LOGIC ====================
local tracerLines = {}

local function getTracerLine(player)
    if not tracerLines[player] then
        pcall(function()
            if Drawing then
                local line = Drawing.new("Line")
                line.Thickness = 1.5
                line.Color = Color3.fromRGB(255, 255, 255)
                line.Transparency = 1
                line.Visible = false
                tracerLines[player] = line
            end
        end)
    end
    return tracerLines[player]
end

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

                -- 1. มองทะลุสีแดง
                local redHighlight = char:FindFirstChild("EXC_RedESP")
                if espRedEnabled then
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

                -- 2. มองทะลุชื่อ
                if head then
                    local nameEsp = head:FindFirstChild("EXC_NameESP")
                    if espNameEnabled then
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
                            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            label.Font = Enum.Font.SourceSansBold
                            label.TextSize = 13
                            label.Parent = nameEsp
                        end
                    elseif nameEsp then
                        nameEsp:Destroy()
                    end
                end

                -- 3. มองแบบกรอบสีขาว
                local boxEsp = hrp:FindFirstChild("EXC_BoxESP")
                if espBoxEnabled then
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

                -- 4. มองแบบเส้น (เส้นอยู่ข้างล่าง)
                local line = getTracerLine(p)
                if line then
                    if espTracerEnabled then
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

-- ==================== SYSTEM STATS & LOOPS ====================
local frameTimes = {}
RunService.RenderStepped:Connect(function()
    local now = tick()
    table.insert(frameTimes, now)
    while frameTimes[1] and frameTimes[1] < now - 1 do
        table.remove(frameTimes, 1)
    end
    FpsLabel.Text = "FPS: " .. #frameTimes

    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            HpTitle.Text = "HP: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
            HpBarFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
        end
    end
end)

task.spawn(function()
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then
            MapNameLabel.Text = info.Name .. "\n(ID: " .. game.PlaceId .. ")"
        end
    end)
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

mouse.Button1Down:Connect(function()
    if clickTpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and mouse.Hit then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if fastEEnabled then pcall(function() fireproximityprompt(prompt) end) end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fovCircle.Radius = fovRadius
        fovCircle.Visible = fovVisible and aimbotEnabled
    end
    if aimbotEnabled then
        local target = nil
        local shortestDist = fovRadius
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
            if hitboxEnabled then
                hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
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
    if flingEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.AssemblyAngularVelocity = Vector3.zero
        if math.abs(hrp.AssemblyLinearVelocity.Y) > 25 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = p.Character.HumanoidRootPart
                local dist = (targetHRP.Position - hrp.Position).Magnitude
                if dist <= 8 then
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