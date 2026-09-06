--==================================================
-- FPS PANEL
-- Clean rebuild for your own Roblox FPS game
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local Settings = {
    Aimbot = false,
    ESP = false,
    Speed = false,
    NoClip = false,
    Invisibility = false,

    AimFOV = 300,
    MaxAimDistance = 150,
    SpeedValue = 32,

    -- Rare letter keys. No WASD / E / Q / F / I.
    PanelKey = Enum.KeyCode.O,
    AimbotKey = Enum.KeyCode.J,
    ESPKey = Enum.KeyCode.K,
    SpeedKey = Enum.KeyCode.L,
    NoClipKey = Enum.KeyCode.U,
    InvisibilityKey = Enum.KeyCode.Y,
}

--==================================================
-- GUI ROOT
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--==================================================
-- MOBILE SCALING
--==================================================

local UIScale = Instance.new("UIScale")
UIScale.Parent = ScreenGui

local function UpdateUIScale()
    local Camera = workspace.CurrentCamera
    if not Camera then
        return
    end

    local viewport = Camera.ViewportSize
    local shortest = math.min(viewport.X, viewport.Y)

    -- PC: 1.0
    -- Small phone: down to 0.65
    local scale = math.clamp(shortest / 650, 0.65, 1)
    UIScale.Scale = scale
end

local function ConnectCameraViewport()
    local Camera = workspace.CurrentCamera
    if not Camera then
        return
    end

    UpdateUIScale()

    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateUIScale)
end

ConnectCameraViewport()

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    task.defer(ConnectCameraViewport)
end)

--==================================================
-- OPEN BUTTON
--==================================================

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(88, 46)
OpenButton.Position = UDim2.new(0, 14, 0.5, -23)
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
OpenButton.TextColor3 = Color3.new(1, 1, 1)
OpenButton.Text = "OPEN [O]"
OpenButton.TextSize = 14
OpenButton.Font = Enum.Font.GothamBold
OpenButton.AutoButtonColor = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenButton

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(70, 70, 85)
OpenStroke.Thickness = 1
OpenStroke.Parent = OpenButton

--==================================================
-- MAIN PANEL
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(285, 475)
Main.Position = UDim2.new(0.5, -142.5, 0.5, -237.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Visible = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 70, 85)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--==================================================
-- TITLE / DRAG
--==================================================

local Title = Instance.new("TextButton")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 48)
Title.BackgroundTransparency = 1
Title.Text = "FPS PANEL"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.AutoButtonColor = false
Title.Parent = Main

local dragging = false
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

--==================================================
-- SCROLLING CONTENT
--==================================================

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -18, 1, -58)
Content.Position = UDim2.new(0, 9, 0, 50)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollingDirection = Enum.ScrollingDirection.Y
Content.ScrollBarImageTransparency = 0.35
Content.Parent = Main

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 3)
Padding.PaddingRight = UDim.new(0, 3)
Padding.PaddingTop = UDim.new(0, 2)
Padding.PaddingBottom = UDim.new(0, 8)
Padding.Parent = Content

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

--==================================================
-- TOGGLES
--==================================================

local ToggleButtons = {}

local function CreateToggle(name, setting, hotkey)
    local Button = Instance.new("TextButton")
    Button.Name = name .. "Toggle"
    Button.Size = UDim2.new(1, -6, 0, 40)
    Button.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold
    Button.AutoButtonColor = true
    Button.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button

    local function Refresh()
        local state = Settings[setting]

        Button.Text = string.format(
            "%s: %s   [%s]",
            name,
            state and "ON" or "OFF",
            hotkey
        )

        Button.BackgroundColor3 = state
            and Color3.fromRGB(50, 115, 70)
            or Color3.fromRGB(28, 28, 35)
    end

    Button.Activated:Connect(function()
        Settings[setting] = not Settings[setting]
        Refresh()
    end)

    ToggleButtons[setting] = Refresh
    Refresh()
end

CreateToggle("Aimbot", "Aimbot", "J")
CreateToggle("ESP", "ESP", "K")
CreateToggle("Speed", "Speed", "L")
CreateToggle("NoClip", "NoClip", "U")
CreateToggle("Invisibility", "Invisibility", "Y")

--==================================================
-- SPEED CONTROLLER
--==================================================

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -6, 0, 22)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
SpeedLabel.TextSize = 14
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.Text = "Speed: " .. Settings.SpeedValue
SpeedLabel.Parent = Content

local SpeedBox = Instance.new("Frame")
SpeedBox.Size = UDim2.new(1, -6, 0, 42)
SpeedBox.BackgroundTransparency = 1
SpeedBox.Parent = Content

local Minus = Instance.new("TextButton")
Minus.Size = UDim2.fromOffset(42, 42)
Minus.Position = UDim2.new(0, 0, 0, 0)
Minus.Text = "-"
Minus.TextSize = 22
Minus.Font = Enum.Font.GothamBold
Minus.TextColor3 = Color3.new(1, 1, 1)
Minus.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Minus.Parent = SpeedBox

local MinusCorner = Instance.new("UICorner")
MinusCorner.CornerRadius = UDim.new(0, 10)
MinusCorner.Parent = Minus

local SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Size = UDim2.new(1, -100, 1, 0)
SpeedValueLabel.Position = UDim2.new(0, 50, 0, 0)
SpeedValueLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
SpeedValueLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedValueLabel.TextSize = 16
SpeedValueLabel.Font = Enum.Font.GothamBold
SpeedValueLabel.Text = tostring(Settings.SpeedValue)
SpeedValueLabel.Parent = SpeedBox

local SpeedValueCorner = Instance.new("UICorner")
SpeedValueCorner.CornerRadius = UDim.new(0, 10)
SpeedValueCorner.Parent = SpeedValueLabel

local Plus = Instance.new("TextButton")
Plus.Size = UDim2.fromOffset(42, 42)
Plus.Position = UDim2.new(1, -42, 0, 0)
Plus.Text = "+"
Plus.TextSize = 22
Plus.Font = Enum.Font.GothamBold
Plus.TextColor3 = Color3.new(1, 1, 1)
Plus.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Plus.Parent = SpeedBox

local PlusCorner = Instance.new("UICorner")
PlusCorner.CornerRadius = UDim.new(0, 10)
PlusCorner.Parent = Plus

local function RefreshSpeedUI()
    SpeedLabel.Text = "Speed: " .. Settings.SpeedValue
    SpeedValueLabel.Text = tostring(Settings.SpeedValue)
end

Minus.Activated:Connect(function()
    Settings.SpeedValue = math.max(1, Settings.SpeedValue - 1)
    RefreshSpeedUI()
end)

Plus.Activated:Connect(function()
    Settings.SpeedValue = math.min(250, Settings.SpeedValue + 1)
    RefreshSpeedUI()
end)

--==================================================
-- HOTKEY INFO
--==================================================

local HotkeyInfo = Instance.new("TextLabel")
HotkeyInfo.Size = UDim2.new(1, -6, 0, 70)
HotkeyInfo.BackgroundTransparency = 1
HotkeyInfo.TextColor3 = Color3.fromRGB(155, 155, 165)
HotkeyInfo.TextSize = 12
HotkeyInfo.Font = Enum.Font.Gotham
HotkeyInfo.TextWrapped = true
HotkeyInfo.TextXAlignment = Enum.TextXAlignment.Left
HotkeyInfo.TextYAlignment = Enum.TextYAlignment.Top
HotkeyInfo.Text =
    "HOTKEYS\n" ..
    "O = Panel   |   J = Aimbot   |   K = ESP\n" ..
    "L = Speed   |   U = NoClip   |   Y = Invisibility"
HotkeyInfo.Parent = Content

--==================================================
-- CHARACTER HELPERS
--==================================================

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local Character = GetCharacter()
    if not Character then
        return nil
    end

    return Character:FindFirstChildOfClass("Humanoid")
end

--==================================================
-- OPEN / CLOSE
--==================================================

local function TogglePanel()
    Main.Visible = not Main.Visible
    OpenButton.Text = Main.Visible and "CLOSE [O]" or "OPEN [O]"
end

OpenButton.Activated:Connect(TogglePanel)

--==================================================
-- SPEED
--==================================================

local OriginalWalkSpeed = 16
local SavedWalkSpeed = false

local function UpdateSpeed()
    local Humanoid = GetHumanoid()
    if not Humanoid then
        return
    end

    if Settings.Speed then
        if not SavedWalkSpeed then
            OriginalWalkSpeed = Humanoid.WalkSpeed
            SavedWalkSpeed = true
        end

        Humanoid.WalkSpeed = Settings.SpeedValue
    elseif SavedWalkSpeed then
        Humanoid.WalkSpeed = OriginalWalkSpeed
        SavedWalkSpeed = false
    end
end

--==================================================
-- NOCLIP
--==================================================

local SavedCollision = {}

local function UpdateNoClip()
    local Character = GetCharacter()
    if not Character then
        return
    end

    for _, Object in ipairs(Character:GetDescendants()) do
        if Object:IsA("BasePart") then
            if SavedCollision[Object] == nil then
                SavedCollision[Object] = Object.CanCollide
            end

            if Settings.NoClip then
                Object.CanCollide = false
            else
                Object.CanCollide = SavedCollision[Object]
            end
        end
    end

    if not Settings.NoClip then
        table.clear(SavedCollision)
    end
end

--==================================================
-- LOCAL INVISIBILITY
--==================================================

local function SetLocalInvisibility(enabled)
    local Character = GetCharacter()
    if not Character then
        return
    end

    for _, Object in ipairs(Character:GetDescendants()) do
        if Object:IsA("BasePart") then
            Object.LocalTransparencyModifier = enabled and 1 or 0
        elseif Object:IsA("Decal") or Object:IsA("Texture") then
            Object.Transparency = enabled and 1 or 0
        end
    end
end

--==================================================
-- AIMBOT VISIBILITY
--==================================================

local function IsVisible(TargetPart)
    local Character = GetCharacter()
    if not Character or not TargetPart then
        return false
    end

    local Camera = workspace.CurrentCamera
    if not Camera then
        return false
    end

    local Origin = Camera.CFrame.Position
    local Direction = TargetPart.Position - Origin

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { Character }
    Params.IgnoreWater = true

    local Result = workspace:Raycast(Origin, Direction, Params)

    if not Result then
        return true
    end

    return Result.Instance:IsDescendantOf(TargetPart.Parent)
end

--==================================================
-- CLOSEST TARGET
--==================================================

local function GetClosestTarget()
    local Character = GetCharacter()
    if not Character then
        return nil
    end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then
        return nil
    end

    local Camera = workspace.CurrentCamera
    if not Camera then
        return nil
    end

    local Center = Camera.ViewportSize / 2
    local BestHead = nil
    local BestWorldDistance = Settings.MaxAimDistance

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local TargetCharacter = Player.Character
            local Humanoid = TargetCharacter:FindFirstChildOfClass("Humanoid")
            local Head = TargetCharacter:FindFirstChild("Head")
            local TargetRoot = TargetCharacter:FindFirstChild("HumanoidRootPart")

            if Humanoid and Humanoid.Health > 0 and Head and TargetRoot then
                local WorldDistance =
                    (TargetRoot.Position - Root.Position).Magnitude

                if WorldDistance <= Settings.MaxAimDistance then
                    local ScreenPos, OnScreen =
                        Camera:WorldToViewportPoint(Head.Position)

                    if OnScreen and ScreenPos.Z > 0 then
                        local ScreenDistance = (
                            Vector2.new(ScreenPos.X, ScreenPos.Y) - Center
                        ).Magnitude

                        if ScreenDistance <= Settings.AimFOV
                            and WorldDistance < BestWorldDistance
                            and IsVisible(Head) then

                            BestWorldDistance = WorldDistance
                            BestHead = Head
                        end
                    end
                end
            end
        end
    end

    return BestHead
end

--==================================================
-- AIMBOT
--==================================================

local function UpdateAimbot()
    if not Settings.Aimbot then
        return
    end

    local TargetHead = GetClosestTarget()
    if not TargetHead then
        return
    end

    local Camera = workspace.CurrentCamera
    if not Camera then
        return
    end

    Camera.CFrame = CFrame.lookAt(
        Camera.CFrame.Position,
        TargetHead.Position
    )
end

--==================================================
-- ESP
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "FPSESP"
ESPFolder.Parent = ScreenGui

local ESPObjects = {}

local function RemoveESP(Player)
    if ESPObjects[Player] then
        ESPObjects[Player]:Destroy()
        ESPObjects[Player] = nil
    end
end

local function CreateESP(Player)
    if Player == LocalPlayer then
        return
    end

    local Character = Player.Character
    if not Character then
        return
    end

    RemoveESP(Player)

    local Highlight = Instance.new("Highlight")
    Highlight.Name = "FPSESPHighlight"
    Highlight.Adornee = Character
    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Highlight.FillTransparency = 0.75
    Highlight.OutlineTransparency = 0
    Highlight.Parent = ESPFolder

    ESPObjects[Player] = Highlight
end

local function UpdateESP()
    if not Settings.ESP then
        for Player in pairs(ESPObjects) do
            RemoveESP(Player)
        end

        return
    end

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            if not ESPObjects[Player] then
                CreateESP(Player)
            else
                ESPObjects[Player].Adornee = Player.Character
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(Player)
    RemoveESP(Player)
end)

--==================================================
-- HOTKEYS
--==================================================
-- IMPORTANT:
-- One key is handled by ONE system only.
-- No duplicate InputBegan fallback, so one press = one toggle.

local function RefreshToggle(setting)
    local Refresh = ToggleButtons[setting]
    if Refresh then
        Refresh()
    end
end

local function ToggleSetting(setting)
    Settings[setting] = not Settings[setting]
    RefreshToggle(setting)
end

local function ActionHandler(actionName, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    if actionName == "FPSPanel_Toggle" then
        TogglePanel()

    elseif actionName == "FPSPanel_Aimbot" then
        ToggleSetting("Aimbot")

    elseif actionName == "FPSPanel_ESP" then
        ToggleSetting("ESP")

    elseif actionName == "FPSPanel_Speed" then
        ToggleSetting("Speed")
        UpdateSpeed()

    elseif actionName == "FPSPanel_NoClip" then
        ToggleSetting("NoClip")

    elseif actionName == "FPSPanel_Invisibility" then
        ToggleSetting("Invisibility")
        SetLocalInvisibility(Settings.Invisibility)
    end

    return Enum.ContextActionResult.Sink
end

local HOTKEY_PRIORITY = Enum.ContextActionPriority.High.Value

ContextActionService:BindActionAtPriority(
    "FPSPanel_Toggle",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.PanelKey
)

ContextActionService:BindActionAtPriority(
    "FPSPanel_Aimbot",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.AimbotKey
)

ContextActionService:BindActionAtPriority(
    "FPSPanel_ESP",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.ESPKey
)

ContextActionService:BindActionAtPriority(
    "FPSPanel_Speed",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.SpeedKey
)

ContextActionService:BindActionAtPriority(
    "FPSPanel_NoClip",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.NoClipKey
)

ContextActionService:BindActionAtPriority(
    "FPSPanel_Invisibility",
    ActionHandler,
    false,
    HOTKEY_PRIORITY,
    Settings.InvisibilityKey
)

--==================================================
-- RESPAWN
--==================================================

LocalPlayer.CharacterAdded:Connect(function()
    table.clear(SavedCollision)
    SavedWalkSpeed = false

    task.wait(0.5)

    UpdateSpeed()
    SetLocalInvisibility(Settings.Invisibility)
end)

--==================================================
-- OPTIMIZED UPDATE LOOP
--==================================================

local EspTimer = 0
local SpeedTimer = 0
local NoClipTimer = 0
local InvisibilityTimer = 0

RunService.RenderStepped:Connect(function(dt)
    -- Aimbot needs responsive camera updates.
    if Settings.Aimbot then
        UpdateAimbot()
    end

    -- ESP: 8-9 updates/sec instead of every frame.
    EspTimer += dt
    if EspTimer >= 0.12 then
        EspTimer = 0
        if Settings.ESP then
            UpdateESP()
        end
    end

    -- Speed: update only while active or restoring.
    SpeedTimer += dt
    if SpeedTimer >= 0.08 then
        SpeedTimer = 0

        if Settings.Speed or SavedWalkSpeed then
            UpdateSpeed()
        end
    end

    -- NoClip: update only while active or restoring.
    NoClipTimer += dt
    if NoClipTimer >= 0.05 then
        NoClipTimer = 0

        if Settings.NoClip or next(SavedCollision) ~= nil then
            UpdateNoClip()
        end
    end

    -- Local invisibility is refreshed periodically for newly-created parts/accessories.
    InvisibilityTimer += dt
    if InvisibilityTimer >= 0.20 then
        InvisibilityTimer = 0

        if Settings.Invisibility then
            SetLocalInvisibility(true)
        end
    end
end)

print(
    "FPS Panel loaded | O Panel | J Aimbot | K ESP | " ..
    "L Speed | U NoClip | Y Invisibility"
)
