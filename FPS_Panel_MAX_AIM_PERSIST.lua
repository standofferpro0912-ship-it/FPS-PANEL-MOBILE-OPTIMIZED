--========================================================
-- FPS PANEL - Enhanced UI/UX
-- Only keyboard shortcut: O = Open / Close
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
pcall(function()
    local old = PlayerGui:FindFirstChild("FPSPanel")
    if old then old:Destroy() end
end)

local Config = {
    Aimbot = false,
    ESP = false,
    Speed = false,
    NoClip = false,
    Invisibility = false,
    AimFOV = 180,
    MaxAimDistance = 150,
    SpeedValue = 32,

    -- Extra client-only features
    FOV = 80,
    FullBright = false,
    NoFog = false,
    Crosshair = true,
    CrosshairSize = 8,
    CrosshairGap = 4,
    CrosshairThickness = 2,
    InfiniteJump = false,
    ThirdPerson = false,
    CameraBob = true,
    FPSCounter = true,
    PingCounter = true,
    Coordinates = false,
    LowGraphics = false,
    TeamCheck = false,
    AimSmooth = false,
    AimSmoothness = 8,
    AimPrediction = false,
    AimPredictionAmount = 0.08,
    AimSticky = false,
    AimDeadzone = 0,
    AimTargetPart = "Head",
    AimTargetMode = "ClosestToCursor",
    PersistenceEnabled = true,
    PersistenceFile = "FPSPanel_profiles.json",
    ActiveProfile = "Default",

    ESPBoxes = true,
    ESPTracers = true,
    ESPNames = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPTeamColor = true,
    ESPMaxDistance = 500,
    ESPUpdateRate = 0.08,

    AutoSprint = false,
    FOVKick = false,
    FOVKickAmount = 8,
    CameraShake = false,
    CameraShakeAmount = 0.15,
    ReduceParticles = false,
    DisablePostFX = false,
    Saturation = 0,
    Contrast = 0,
    ColorBoost = 0,
    LocalTime = false,
    PanelKey = Enum.KeyCode.O,

}

--========================================================
-- SAVED PROFILES / PERSISTENCE
--========================================================
-- Re-execution persistence:
-- 1) Uses executor file APIs when available (readfile/writefile/isfile).
-- 2) Falls back to getgenv() / _G for same-runtime persistence.
-- Multiple named profiles are supported.

local HttpService = game:GetService("HttpService")
local Env = _G

pcall(function()
    if type(getgenv) == "function" then
        Env = getgenv()
    end
end)

Env.FPSPanelProfiles = Env.FPSPanelProfiles or {}

local function ConfigSnapshot()
    local snapshot = {}
    for key, value in pairs(Config) do
        local kind = typeof(value)
        if kind == "boolean" or kind == "number" or kind == "string" then
            snapshot[key] = value
        end
    end
    return snapshot
end

local function ApplySnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return
    end

    for key, value in pairs(snapshot) do
        if Config[key] ~= nil then
            local expected = typeof(Config[key])
            local actual = typeof(value)
            if expected == actual then
                Config[key] = value
            end
        end
    end
end

local function SaveProfilesToDisk()
    if not Config.PersistenceEnabled then
        return false
    end

    if type(writefile) ~= "function" then
        return false
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Env.FPSPanelProfiles)
    end)

    if not ok then
        return false
    end

    return pcall(function()
        writefile(Config.PersistenceFile, encoded)
    end)
end

local function LoadProfilesFromDisk()
    if not Config.PersistenceEnabled then
        return false
    end

    if type(readfile) ~= "function"
        or type(isfile) ~= "function"
        or not isfile(Config.PersistenceFile) then
        return false
    end

    local ok, raw = pcall(function()
        return readfile(Config.PersistenceFile)
    end)

    if not ok or type(raw) ~= "string" or raw == "" then
        return false
    end

    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not decodedOk or type(decoded) ~= "table" then
        return false
    end

    Env.FPSPanelProfiles = decoded
    return true
end

local function SaveProfile(name)
    name = tostring(name or Config.ActiveProfile or "Default")
    Env.FPSPanelProfiles = Env.FPSPanelProfiles or {}
    Env.FPSPanelProfiles[name] = ConfigSnapshot()
    Config.ActiveProfile = name
    Env.FPSPanelLastActiveProfile = name
    local ok = SaveProfilesToDisk()
    return ok
end

local function LoadProfile(name)
    name = tostring(name or "Default")
    local snapshot = Env.FPSPanelProfiles[name]
    if type(snapshot) ~= "table" then
        return false
    end

    ApplySnapshot(snapshot)
    Config.ActiveProfile = name
    return true
end

local function GetProfileNames()
    local names = {}
    for name in pairs(Env.FPSPanelProfiles) do
        table.insert(names, tostring(name))
    end
    table.sort(names)
    return names
end

-- Default profile behavior: load the last active profile on every re-execution.
if Config.PersistenceEnabled then
    LoadProfilesFromDisk()

    local savedActive = Env.FPSPanelLastActiveProfile or Config.ActiveProfile or "Default"

    if not LoadProfile(savedActive) then
        if Env.FPSPanelProfiles.Default then
            LoadProfile("Default")
        else
            SaveProfile("Default")
        end
    end
end

local C = {
    Bg = Color3.fromRGB(9,10,13),
    Surface = Color3.fromRGB(16,17,22),
    Surface2 = Color3.fromRGB(22,23,29),
    Surface3 = Color3.fromRGB(29,30,38),
    Border = Color3.fromRGB(46,48,58),
    Text = Color3.fromRGB(245,245,248),
    Sub = Color3.fromRGB(150,153,163),
    Muted = Color3.fromRGB(94,97,107),
    Accent = Color3.fromRGB(130,92,255),
    Accent2 = Color3.fromRGB(93,63,190),
    Good = Color3.fromRGB(67,204,126),
    Bad = Color3.fromRGB(232,82,88),
}

local function New(class, props, parent)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end
local function Corner(x,r) New("UICorner",{CornerRadius=UDim.new(0,r or 10)},x) end
local function Outline(x,color,thick,trans) New("UIStroke",{Color=color or C.Border,Thickness=thick or 1,Transparency=trans or 0},x) end
local function T(x,props,time)
    TweenService:Create(x,TweenInfo.new(time or .16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play()
end

--========================================================
-- ROOT + RESPONSIVE SCALE
--========================================================
local Gui = New("ScreenGui",{
    Name="FPSPanel",ResetOnSpawn=false,IgnoreGuiInset=true,
    DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
},PlayerGui)
local Scale = New("UIScale",{},Gui)
local function Resize()
    local cam=workspace.CurrentCamera
    if cam then
        local s=math.min(cam.ViewportSize.X,cam.ViewportSize.Y)
        Scale.Scale=math.clamp(s/700,.62,1)
    end
end
Resize()
local camConn
local function BindCamera()
    if camConn then camConn:Disconnect() end
    local cam=workspace.CurrentCamera
    if not cam then return end
    Resize()
    camConn=cam:GetPropertyChangedSignal("ViewportSize"):Connect(Resize)
end
BindCamera()
local currentCamConn=workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.defer(BindCamera) end)

--========================================================
-- FLOATING OPEN/CLOSE BUTTON
--========================================================
local Open = New("TextButton",{
    Size=UDim2.fromOffset(100,42),Position=UDim2.new(0,15,.5,-21),
    BackgroundColor3=C.Surface,Text="",AutoButtonColor=false,BorderSizePixel=0,
},Gui)
Corner(Open,12); Outline(Open,C.Border)
local Dot=New("Frame",{Size=UDim2.fromOffset(7,7),Position=UDim2.new(0,13,.5,-3),BackgroundColor3=C.Accent,BorderSizePixel=0},Open); Corner(Dot,8)
local OpenLabel=New("TextLabel",{Size=UDim2.new(1,-32,1,0),Position=UDim2.fromOffset(27,0),BackgroundTransparency=1,Text="OPEN  [O]",TextColor3=C.Text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Open)

--========================================================
-- WINDOW
--========================================================
local Main=New("Frame",{
    Size=UDim2.fromOffset(470,545),Position=UDim2.new(.5,-235,.5,-272.5),
    BackgroundColor3=C.Bg,BorderSizePixel=0,ClipsDescendants=true,
},Gui)
Corner(Main,18); Outline(Main,C.Border)

local Header=New("Frame",{Size=UDim2.new(1,0,0,70),BackgroundColor3=C.Surface,BorderSizePixel=0},Main)
New("Frame",{Size=UDim2.fromOffset(3,50),Position=UDim2.fromOffset(10,10),BackgroundColor3=C.Accent,BorderSizePixel=0},Header); Corner(Header:FindFirstChildOfClass("Frame"),4)
New("TextLabel",{Size=UDim2.new(1,-145,0,26),Position=UDim2.fromOffset(25,10),BackgroundTransparency=1,Text="FPS PANEL",TextColor3=C.Text,TextSize=20,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Header)
New("TextLabel",{Size=UDim2.new(1,-145,0,17),Position=UDim2.fromOffset(26,37),BackgroundTransparency=1,Text="ADVANCED CONTROL CENTER",TextColor3=C.Sub,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Header)
New("TextLabel",{Size=UDim2.fromOffset(78,18),Position=UDim2.new(1,-122,0,11),BackgroundTransparency=1,Text="O  MENU",TextColor3=C.Sub,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},Header)
local Close=New("TextButton",{Size=UDim2.fromOffset(32,32),Position=UDim2.new(1,-43,.5,-2),BackgroundColor3=C.Surface3,Text="×",TextColor3=C.Sub,TextSize=21,Font=Enum.Font.Gotham,AutoButtonColor=false,BorderSizePixel=0},Header); Corner(Close,9)

-- draggable header
local dragging=false; local dragStart; local startPos
Header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)

--========================================================
-- SIDEBAR + PAGES
--========================================================
local Sidebar=New("Frame",{Size=UDim2.new(0,132,1,-82),Position=UDim2.fromOffset(10,76),BackgroundColor3=C.Surface,BorderSizePixel=0},Main); Corner(Sidebar,14); Outline(Sidebar,C.Border)
New("TextLabel",{Size=UDim2.new(1,-20,0,22),Position=UDim2.fromOffset(10,10),BackgroundTransparency=1,Text="SECTIONS",TextColor3=C.Muted,TextSize=9,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Sidebar)
local TabList=New("Frame",{Size=UDim2.new(1,-14,1,-40),Position=UDim2.fromOffset(7,36),BackgroundTransparency=1},Sidebar)
New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},TabList)
local Area=New("Frame",{Size=UDim2.new(1,-152,1,-82),Position=UDim2.fromOffset(145,76),BackgroundTransparency=1,ClipsDescendants=true},Main)

local tabDefs={
    {id="Combat",label="Combat",icon="⊙",desc="Targeting"},
    {id="Visuals",label="Visuals",icon="◉",desc="ESP"},
    {id="Movement",label="Movement",icon="↗",desc="Speed"},
    {id="Player",label="Player",icon="●",desc="Character"},
    {id="Client",label="Client",icon="◇",desc="Local only"},
    {id="Performance",label="Performance",icon="≋",desc="FPS"},
    {id="Camera",label="Camera",icon="◌",desc="View"},
    {id="Interface",label="Interface",icon="▦",desc="HUD"},
    {id="Graphics",label="Graphics",icon="◈",desc="Visuals"},
    {id="Utility",label="Utility",icon="◆",desc="Quality of life"},
    {id="Settings",label="Settings",icon="⚙",desc="Interface"},
}
local Tabs={}; local Pages={}; local CurrentTab="Combat"; local Refreshers={}

local function Page(id,title,desc)
    local p=New("ScrollingFrame",{Name=id.."Page",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.Accent,ScrollBarImageTransparency=.25,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),Visible=false},Area)
    New("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,7),PaddingBottom=UDim.new(0,10)},p)
    New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},p)
    local h=New("Frame",{Size=UDim2.new(1,0,0,52),BackgroundTransparency=1},p)
    New("TextLabel",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=20,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},h)
    New("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.fromOffset(0,29),BackgroundTransparency=1,Text=desc,TextColor3=C.Sub,TextSize=9,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},h)
    Pages[id]=p; return p
end
for n,d in ipairs(tabDefs) do
    local b=New("TextButton",{Size=UDim2.new(1,0,0,43),BackgroundColor3=C.Surface,Text="",AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=n},TabList); Corner(b,10)
    local bar=New("Frame",{Size=UDim2.fromOffset(3,24),Position=UDim2.new(0,0,.5,-12),BackgroundColor3=C.Accent,BackgroundTransparency=1,BorderSizePixel=0},b); Corner(bar,4)
    local icon=New("TextLabel",{Size=UDim2.fromOffset(26,43),Position=UDim2.fromOffset(9,0),BackgroundTransparency=1,Text=d.icon,TextColor3=C.Sub,TextSize=15,Font=Enum.Font.GothamBold},b)
    local lab=New("TextLabel",{Size=UDim2.new(1,-41,1,0),Position=UDim2.fromOffset(38,0),BackgroundTransparency=1,Text=d.label,TextColor3=C.Sub,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},b)
    Tabs[d.id]={b=b,bar=bar,icon=icon,lab=lab}
end
for _,d in ipairs(tabDefs) do Page(d.id,d.label,d.desc) end

local function SelectTab(id)
    CurrentTab=id
    for k,t in pairs(Tabs) do
        local active=k==id
        T(t.b,{BackgroundColor3=active and C.Surface3 or C.Surface},.12)
        T(t.icon,{TextColor3=active and C.Text or C.Sub},.12)
        T(t.lab,{TextColor3=active and C.Text or C.Sub},.12)
        T(t.bar,{BackgroundTransparency=active and 0 or 1},.12)
    end
    for k,p in pairs(Pages) do p.Visible=(k==id) end
end
for id,t in pairs(Tabs) do
    t.b.Activated:Connect(function() SelectTab(id) end)
    t.b.MouseEnter:Connect(function() if CurrentTab~=id then T(t.b,{BackgroundColor3=C.Surface2},.1) end end)
    t.b.MouseLeave:Connect(function() if CurrentTab~=id then T(t.b,{BackgroundColor3=C.Surface},.1) end end)
end

--========================================================
-- COMPONENTS
--========================================================
local function Section(p,title,sub)
    local f=New("Frame",{Size=UDim2.new(1,0,0,45),BackgroundColor3=C.Surface,BorderSizePixel=0},p); Corner(f,11); Outline(f,C.Border)
    New("TextLabel",{Size=UDim2.new(1,-18,0,19),Position=UDim2.fromOffset(10,6),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},f)
    New("TextLabel",{Size=UDim2.new(1,-18,0,14),Position=UDim2.fromOffset(10,25),BackgroundTransparency=1,Text=sub or "",TextColor3=C.Muted,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},f)
    return f
end
local function Toggle(p,title,desc,get,set)
    local r=New("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.Surface,BorderSizePixel=0},p); Corner(r,11); Outline(r,C.Border)
    New("TextLabel",{Size=UDim2.new(1,-85,0,21),Position=UDim2.fromOffset(12,8),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},r)
    New("TextLabel",{Size=UDim2.new(1,-85,0,19),Position=UDim2.fromOffset(12,31),BackgroundTransparency=1,Text=desc,TextColor3=C.Sub,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},r)
    local sw=New("TextButton",{Size=UDim2.fromOffset(48,26),Position=UDim2.new(1,-60,.5,-13),BackgroundColor3=C.Surface3,Text="",AutoButtonColor=false,BorderSizePixel=0},r); Corner(sw,14)
    local knob=New("Frame",{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(3,3),BackgroundColor3=C.Sub,BorderSizePixel=0},sw); Corner(knob,10)
    local function refresh()
        local on=get()
        T(sw,{BackgroundColor3=on and C.Accent or C.Surface3},.12)
        T(knob,{Position=on and UDim2.new(1,-23,0,3) or UDim2.fromOffset(3,3),BackgroundColor3=on and Color3.new(1,1,1) or C.Sub},.12)
    end
    sw.Activated:Connect(function() set(not get()); refresh(); SaveProfile(Config.ActiveProfile) end)
    refresh(); table.insert(Refreshers,refresh); return refresh
end
local function Slider(p,title,desc,min,max,step,get,set)
    local r=New("Frame",{Size=UDim2.new(1,0,0,87),BackgroundColor3=C.Surface,BorderSizePixel=0},p); Corner(r,11); Outline(r,C.Border)
    New("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.fromOffset(12,8),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},r)
    local val=New("TextLabel",{Size=UDim2.fromOffset(58,20),Position=UDim2.new(1,-70,0,8),BackgroundTransparency=1,TextColor3=C.Accent,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},r)
    New("TextLabel",{Size=UDim2.new(1,-24,0,16),Position=UDim2.fromOffset(12,29),BackgroundTransparency=1,Text=desc,TextColor3=C.Sub,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},r)
    local tr=New("Frame",{Size=UDim2.new(1,-24,0,7),Position=UDim2.new(0,12,1,-20),BackgroundColor3=C.Surface3,BorderSizePixel=0},r); Corner(tr,6)
    local fill=New("Frame",{Size=UDim2.new(),BackgroundColor3=C.Accent,BorderSizePixel=0},tr); Corner(fill,6)
    local knob=New("TextButton",{Size=UDim2.fromOffset(18,18),Position=UDim2.new(0,-9,.5,-9),BackgroundColor3=Color3.new(1,1,1),Text="",AutoButtonColor=false,BorderSizePixel=0},tr); Corner(knob,9); Outline(knob,C.Accent)
    local slide=false
    local function setX(x)
        local a=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        local v=math.floor(((min+(max-min)*a)/step)+.5)*step
        set(math.clamp(v,min,max))
    end
    local function refresh()
        local v=get(); local a=(v-min)/(max-min)
        val.Text=tostring(v); fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,-9,.5,-9)
    end
    tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then slide=true; setX(i.Position.X); refresh() end end)
    UserInputService.InputChanged:Connect(function(i) if slide and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setX(i.Position.X); refresh() end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then slide=false; SaveProfile(Config.ActiveProfile) end end)
    refresh(); table.insert(Refreshers,refresh); return refresh
end
local function Info(p,title,desc,accent)
    local r=New("Frame",{Size=UDim2.new(1,0,0,57),BackgroundColor3=C.Surface,BorderSizePixel=0},p); Corner(r,11); Outline(r,C.Border)
    local line=New("Frame",{Size=UDim2.fromOffset(3,31),Position=UDim2.fromOffset(10,13),BackgroundColor3=accent or C.Accent,BorderSizePixel=0},r); Corner(line,3)
    New("TextLabel",{Size=UDim2.new(1,-38),Position=UDim2.fromOffset(20,8),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},r)
    New("TextLabel",{Size=UDim2.new(1,-38),Position=UDim2.fromOffset(20,28),BackgroundTransparency=1,Text=desc,TextColor3=C.Sub,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},r)
    return r
end
local function Action(p,title,desc,callback,color)
    local b=New("TextButton",{Size=UDim2.new(1,0,0,57),BackgroundColor3=C.Surface,Text="",AutoButtonColor=false,BorderSizePixel=0,Active=true},p); Corner(b,11); Outline(b,C.Border)
    local line=New("Frame",{Size=UDim2.fromOffset(3,31),Position=UDim2.fromOffset(10,13),BackgroundColor3=color or C.Accent,BorderSizePixel=0},b); Corner(line,3)
    New("TextLabel",{Size=UDim2.new(1,-55,0,21),Position=UDim2.fromOffset(20,8),BackgroundTransparency=1,Text=title,TextColor3=C.Text,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Active=false},b)
    local descLabel=New("TextLabel",{Size=UDim2.new(1,-55,0,19),Position=UDim2.fromOffset(20,28),BackgroundTransparency=1,Text="",TextColor3=C.Sub,TextSize=8,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Active=false},b)
    local function refresh()
        local value = type(desc)=="function" and desc() or desc
        descLabel.Text=tostring(value or "")
    end
    refresh()
    local a=New("TextLabel",{Size=UDim2.fromOffset(24,57),Position=UDim2.new(1,-31,0,0),BackgroundTransparency=1,Text="›",TextColor3=C.Muted,TextSize=22,Font=Enum.Font.Gotham,Active=false},b)
    b.Activated:Connect(function()
        callback()
        refresh()
    end)
    b.MouseEnter:Connect(function() T(b,{BackgroundColor3=C.Surface2},.1); T(a,{TextColor3=C.Text},.1) end)
    b.MouseLeave:Connect(function() T(b,{BackgroundColor3=C.Surface},.1); T(a,{TextColor3=C.Muted},.1) end)
    table.insert(Refreshers,refresh)
    return b,refresh
end

--========================================================
-- BUILD TABS
--========================================================
Section(Pages.Combat,"TARGETING","Aim behaviour and target selection")
Toggle(Pages.Combat,"Aimbot","Tracks the closest visible target inside your FOV.",function() return Config.Aimbot end,function(v) Config.Aimbot=v end)
Slider(Pages.Combat,"Aim FOV","Screen-space target radius.",50,500,10,function() return Config.AimFOV end,function(v) Config.AimFOV=v end)
Slider(Pages.Combat,"Max Distance","Maximum target distance.",25,500,5,function() return Config.MaxAimDistance end,function(v) Config.MaxAimDistance=v end)
Toggle(Pages.Combat,"Team Check","Prevents aimbot from selecting teammates using team/faction checks.",function() return Config.TeamCheck end,function(v) Config.TeamCheck=v end)
Action(Pages.Combat,"Aim Body Part",function()
    return "Target: "..tostring(Config.AimTargetPart).." • tap to cycle."
end,function()
    local parts={"Head","UpperTorso","Torso","LowerTorso","LeftArm","RightArm","LeftLeg","RightLeg","HumanoidRootPart"}
    local i=table.find(parts,Config.AimTargetPart) or 1
    Config.AimTargetPart=parts[(i % #parts)+1]
    SaveProfile(Config.ActiveProfile)
end,C.Accent)
Action(Pages.Combat,"Target Priority",function()
    return "Mode: "..tostring(Config.AimTargetMode).." • tap to cycle."
end,function()
    local modes={"ClosestToCursor","ClosestToPlayer","LowestHealth"}
    local i=table.find(modes,Config.AimTargetMode) or 1
    Config.AimTargetMode=modes[(i % #modes)+1]
    SaveProfile(Config.ActiveProfile)
end,C.Accent)
Toggle(Pages.Combat,"Smooth Aim","Moves the camera toward the target instead of snapping instantly.",function() return Config.AimSmooth end,function(v) Config.AimSmooth=v end)
Slider(Pages.Combat,"Aim Smoothness","Higher values feel faster and more responsive.",1,20,1,function() return Config.AimSmoothness end,function(v) Config.AimSmoothness=v end)
Info(Pages.Combat,"Target validation","Requires a live, visible and on-screen player.",C.Good)

Section(Pages.Visuals,"PLAYER ESP","Complete local player overlay system")
Toggle(Pages.Visuals,"ESP","Master switch for the local ESP system.",function() return Config.ESP end,function(v) Config.ESP=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Boxes","Draw a box around players.",function() return Config.ESPBoxes end,function(v) Config.ESPBoxes=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Tracers","Draw lines from the bottom of the screen.",function() return Config.ESPTracers end,function(v) Config.ESPTracers=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Names","Show player names.",function() return Config.ESPNames end,function(v) Config.ESPNames=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Distance","Show distance in studs.",function() return Config.ESPDistance end,function(v) Config.ESPDistance=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Health","Show HP bar and values.",function() return Config.ESPHealth end,function(v) Config.ESPHealth=v; task.defer(UpdateESP) end)
Toggle(Pages.Visuals,"Team Colors","Use team color when available.",function() return Config.ESPTeamColor end,function(v) Config.ESPTeamColor=v; task.defer(UpdateESP) end)
Slider(Pages.Visuals,"Max Distance","Do not render ESP beyond this distance.",50,1000,10,function() return Config.ESPMaxDistance end,function(v) Config.ESPMaxDistance=v; task.defer(UpdateESP) end)
Info(Pages.Visuals,"Performance","ESP is throttled and only creates overlays for active targets.",C.Accent)

Section(Pages.Movement,"MOVEMENT","Movement and collision controls")
Toggle(Pages.Movement,"Speed","Changes Humanoid WalkSpeed while enabled.",function() return Config.Speed end,function(v) Config.Speed=v end)
Slider(Pages.Movement,"WalkSpeed","Movement speed value.",1,150,1,function() return Config.SpeedValue end,function(v) Config.SpeedValue=v end)
Toggle(Pages.Movement,"NoClip","Disables character collision while enabled.",function() return Config.NoClip end,function(v) Config.NoClip=v end)
Toggle(Pages.Movement,"Infinite Jump","Allows jump requests while airborne on the local client.",function() return Config.InfiniteJump end,function(v) Config.InfiniteJump=v end)

Section(Pages.Player,"CHARACTER","Character presentation")
Toggle(Pages.Player,"Invisibility","Makes your character locally transparent on this client.",function() return Config.Invisibility end,function(v) Config.Invisibility=v end)
Info(Pages.Player,"Client-side","Invisibility uses local transparency and is not server-authoritative.",C.Accent)

Section(Pages.Client,"CAMERA","Local camera controls")
Slider(Pages.Client,"Field of View","Local camera field of view.",40,120,1,function() return Config.FOV end,function(v) Config.FOV=v end)
Toggle(Pages.Client,"Third Person","Switches the local camera to a simple third-person view.",function() return Config.ThirdPerson end,function(v) Config.ThirdPerson=v end)
Toggle(Pages.Client,"Camera Bob","Keeps normal first-person camera movement enabled.",function() return Config.CameraBob end,function(v) Config.CameraBob=v end)

Section(Pages.Client,"CROSSHAIR","Custom local crosshair")
Toggle(Pages.Client,"Crosshair","Shows a clean custom crosshair in the center of the screen.",function() return Config.Crosshair end,function(v) Config.Crosshair=v end)
Slider(Pages.Client,"Crosshair Size","Length of each crosshair arm.",4,20,1,function() return Config.CrosshairSize end,function(v) Config.CrosshairSize=v end)
Slider(Pages.Client,"Crosshair Gap","Center gap size.",0,14,1,function() return Config.CrosshairGap end,function(v) Config.CrosshairGap=v end)
Slider(Pages.Client,"Crosshair Thickness","Line thickness.",1,5,1,function() return Config.CrosshairThickness end,function(v) Config.CrosshairThickness=v end)

Section(Pages.Client,"LOCAL VISUALS","Client-only lighting and world presentation")
Toggle(Pages.Client,"Full Bright","Removes local darkness by increasing client lighting.",function() return Config.FullBright end,function(v) Config.FullBright=v end)
Toggle(Pages.Client,"No Fog","Extends local fog distance to make the map clearer.",function() return Config.NoFog end,function(v) Config.NoFog=v end)

Section(Pages.Performance,"MONITOR","Live client performance information")
Toggle(Pages.Performance,"FPS Counter","Shows your current client FPS.",function() return Config.FPSCounter end,function(v) Config.FPSCounter=v end)
Toggle(Pages.Performance,"Ping Counter","Shows the local player's reported ping.",function() return Config.PingCounter end,function(v) Config.PingCounter=v end)
Toggle(Pages.Performance,"Coordinates","Shows your current character coordinates.",function() return Config.Coordinates end,function(v) Config.Coordinates=v end)
Toggle(Pages.Performance,"Low Graphics","Applies a client-side low-detail rendering profile.",function() return Config.LowGraphics end,function(v) Config.LowGraphics=v end)
Info(Pages.Performance,"Performance first","All options in this tab are designed to affect the local client only.",C.Good)

Section(Pages.Settings,"INTERFACE","Quality-of-life controls")
Info(Pages.Settings,"Keyboard shortcut","O is the ONLY keyboard shortcut: open / close the panel.",C.Accent)
Action(Pages.Settings,"Center panel","Restore the window to the center of the screen.",function() Main.Position=UDim2.new(.5,-235,.5,-272.5) end,C.Good)
Action(Pages.Settings,"Reset features","Turn every gameplay feature off and restore movement state.",function()
    Config.Aimbot=false; Config.ESP=false; Config.Speed=false; Config.NoClip=false; Config.Invisibility=false
    for _,refresh in ipairs(Refreshers) do refresh() end
    SaveProfile(Config.ActiveProfile)
end,C.Bad)
Section(Pages.Settings,"PROFILES","Keep your preferred panel setup between re-executions")
Action(Pages.Settings,"Save Profile",function()
    return "Save the current configuration as "..tostring(Config.ActiveProfile).."."
end,function()
    SaveProfile(Config.ActiveProfile)
end,C.Good)
Action(Pages.Settings,"Load Profile",function()
    return "Load the saved "..tostring(Config.ActiveProfile).." configuration."
end,function()
    if LoadProfile(Config.ActiveProfile) then
        Env.FPSPanelLastActiveProfile=Config.ActiveProfile
        for _,refresh in ipairs(Refreshers) do refresh() end
        task.defer(UpdateESP)
    end
end,C.Accent)
Action(Pages.Settings,"New Profile","Switch profile name by editing ActiveProfile in the Config block, then save.",function()
    SaveProfile(Config.ActiveProfile)
end,C.Accent)
Info(Pages.Settings,"Persistence","Uses file APIs when available; otherwise uses the current runtime environment.",C.Good)
Action(Pages.Settings,"Mobile optimized","Responsive scaling, touch toggles, sliders, scrolling and drag support.",function() Resize() end,C.Good)


--========================================================
-- ADDITIONAL CLIENT FEATURES
--========================================================

Section(Pages.Combat,"AIM ADVANCED","More precise local target handling")
Toggle(Pages.Combat,"Sticky Aim","Keeps the selected target while it remains valid.",function() return Config.AimSticky end,function(v) Config.AimSticky=v end)
Toggle(Pages.Combat,"Prediction","Uses target velocity for a small local lead.",function() return Config.AimPrediction end,function(v) Config.AimPrediction=v end)
Slider(Pages.Combat,"Prediction","Prediction amount.",0,0.30,0.01,function() return Config.AimPredictionAmount end,function(v) Config.AimPredictionAmount=v end)
Slider(Pages.Combat,"Deadzone","Ignore tiny aim corrections.",0,30,1,function() return Config.AimDeadzone end,function(v) Config.AimDeadzone=v end)
Info(Pages.Combat,"Smoothness fixed","Smoothing is now frame-rate independent.",C.Good)

Section(Pages.Movement,"MOVEMENT EXTRAS","More local quality-of-life controls")
Toggle(Pages.Movement,"Auto Sprint","Marks the client as sprint-ready while moving.",function() return Config.AutoSprint end,function(v) Config.AutoSprint=v end)

Section(Pages.Client,"CAMERA FEEL","Extra local camera effects")
Toggle(Pages.Client,"FOV Kick","Adds a small movement-based FOV pulse.",function() return Config.FOVKick end,function(v) Config.FOVKick=v end)
Slider(Pages.Client,"FOV Kick Amount","Maximum extra FOV.",0,20,1,function() return Config.FOVKickAmount end,function(v) Config.FOVKickAmount=v end)
Toggle(Pages.Client,"Camera Shake","Adds subtle local camera feedback.",function() return Config.CameraShake end,function(v) Config.CameraShake=v end)
Slider(Pages.Client,"Shake Amount","Camera shake strength.",0,1,0.01,function() return Config.CameraShakeAmount end,function(v) Config.CameraShakeAmount=v end)

Section(Pages.Camera,"CAMERA","Dedicated camera controls")
Slider(Pages.Camera,"Field of View","Local camera FOV.",40,120,1,function() return Config.FOV end,function(v) Config.FOV=v end)
Toggle(Pages.Camera,"Third Person","Use a local third-person view.",function() return Config.ThirdPerson end,function(v) Config.ThirdPerson=v end)
Toggle(Pages.Camera,"Camera Bob","Add subtle movement bob.",function() return Config.CameraBob end,function(v) Config.CameraBob=v end)
Info(Pages.Camera,"Smooth aim","Uses frame-rate independent interpolation.",C.Good)

Section(Pages.Interface,"CROSSHAIR","Local reticle and HUD")
Toggle(Pages.Interface,"Crosshair","Show a custom local crosshair.",function() return Config.Crosshair end,function(v) Config.Crosshair=v end)
Slider(Pages.Interface,"Size","Crosshair arm length.",4,24,1,function() return Config.CrosshairSize end,function(v) Config.CrosshairSize=v end)
Slider(Pages.Interface,"Gap","Crosshair center gap.",0,20,1,function() return Config.CrosshairGap end,function(v) Config.CrosshairGap=v end)
Slider(Pages.Interface,"Thickness","Crosshair thickness.",1,6,1,function() return Config.CrosshairThickness end,function(v) Config.CrosshairThickness=v end)
Toggle(Pages.Interface,"FPS Counter","Show live client FPS.",function() return Config.FPSCounter end,function(v) Config.FPSCounter=v end)
Toggle(Pages.Interface,"Ping Counter","Show local network ping.",function() return Config.PingCounter end,function(v) Config.PingCounter=v end)
Toggle(Pages.Interface,"Coordinates","Show character coordinates.",function() return Config.Coordinates end,function(v) Config.Coordinates=v end)
Toggle(Pages.Interface,"Local Time","Show local time.",function() return Config.LocalTime end,function(v) Config.LocalTime=v end)

Section(Pages.Graphics,"LIGHTING","Client-side visual improvements")
Toggle(Pages.Graphics,"Full Bright","Brighten local lighting.",function() return Config.FullBright end,function(v) Config.FullBright=v end)
Toggle(Pages.Graphics,"No Fog","Extend local fog distance.",function() return Config.NoFog end,function(v) Config.NoFog=v end)
Toggle(Pages.Graphics,"Reduce Particles","Disable common local particles, beams and trails.",function() return Config.ReduceParticles end,function(v) Config.ReduceParticles=v end)
Toggle(Pages.Graphics,"Disable Post FX","Disable common local post-processing.",function() return Config.DisablePostFX end,function(v) Config.DisablePostFX=v end)
Slider(Pages.Graphics,"Saturation","Local saturation.",-1,1,0.05,function() return Config.Saturation end,function(v) Config.Saturation=v end)
Slider(Pages.Graphics,"Contrast","Local contrast.",-1,1,0.05,function() return Config.Contrast end,function(v) Config.Contrast=v end)
Slider(Pages.Graphics,"Color Boost","Local brightness boost.",-0.5,0.5,0.05,function() return Config.ColorBoost end,function(v) Config.ColorBoost=v end)

Section(Pages.Utility,"UTILITY","Small client-only quality-of-life tools")
Toggle(Pages.Utility,"Infinite Jump","Allow repeated local jump requests.",function() return Config.InfiniteJump end,function(v) Config.InfiniteJump=v end)
Toggle(Pages.Utility,"Auto Sprint","Keep the player sprint-ready locally.",function() return Config.AutoSprint end,function(v) Config.AutoSprint=v end)
Info(Pages.Utility,"Client-only","These controls are designed for local presentation and convenience.",C.Accent)

SelectTab("Combat")

--========================================================
-- OPEN / CLOSE
--========================================================
local visible=true
local openPos=Main.Position
local closedPos=UDim2.new(openPos.X.Scale,openPos.X.Offset,openPos.Y.Scale,openPos.Y.Offset+14)
local function SetVisible(v)
    visible=v
    if v then
        Main.Visible=true; Main.Position=closedPos; Main.BackgroundTransparency=1
        T(Main,{Position=openPos,BackgroundTransparency=0},.19)
        OpenLabel.Text="CLOSE  [O]"; Dot.BackgroundColor3=C.Good
    else
        local tw=TweenService:Create(Main,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=closedPos,BackgroundTransparency=1})
        tw.Completed:Connect(function() if not visible then Main.Visible=false end end); tw:Play()
        OpenLabel.Text="OPEN  [O]"; Dot.BackgroundColor3=C.Accent
    end
end
Open.Activated:Connect(function() SetVisible(not visible) end)
Close.Activated:Connect(function() SetVisible(false) end)
Open.MouseEnter:Connect(function() T(Open,{BackgroundColor3=C.Surface2},.1) end); Open.MouseLeave:Connect(function() T(Open,{BackgroundColor3=C.Surface},.1) end)
Close.MouseEnter:Connect(function() T(Close,{BackgroundColor3=C.Bad,TextColor3=Color3.new(1,1,1)},.1) end); Close.MouseLeave:Connect(function() T(Close,{BackgroundColor3=C.Surface3,TextColor3=C.Sub},.1) end)

-- ONLY hotkey: O
ContextActionService:BindActionAtPriority("FPSPanel_OpenClose",function(_,state)
    if state==Enum.UserInputState.Begin then SetVisible(not visible) end
    return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,Config.PanelKey)


--========================================================
-- CLIENT HUD
--========================================================
local ClientHUD=New("ScreenGui",{Name="FPSClientHUD",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=101,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PlayerGui)

local Crosshair=New("Frame",{Name="Crosshair",Size=UDim2.fromOffset(1,1),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1},ClientHUD)
local ChTop=New("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},Crosshair); local ChBottom=New("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},Crosshair)
local ChLeft=New("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},Crosshair); local ChRight=New("Frame",{BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},Crosshair)
local Status=New("TextLabel",{Size=UDim2.fromOffset(210,58),Position=UDim2.new(1,-225,0,14),BackgroundTransparency=.35,BackgroundColor3=C.Surface,TextColor3=C.Text,TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,Text=""},ClientHUD); Corner(Status,10); Outline(Status,C.Border)
New("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,7),PaddingRight=UDim.new(0,6)},Status)

local function UpdateCrosshair()
    Crosshair.Visible=Config.Crosshair
    local size=Config.CrosshairSize; local gap=Config.CrosshairGap; local thick=Config.CrosshairThickness
    ChTop.Size=UDim2.fromOffset(thick,size); ChTop.Position=UDim2.new(.5,-thick/2,0,-gap-size)
    ChBottom.Size=UDim2.fromOffset(thick,size); ChBottom.Position=UDim2.new(.5,-thick/2,0,gap)
    ChLeft.Size=UDim2.fromOffset(size,thick); ChLeft.Position=UDim2.new(0,-gap-size,.5,-thick/2)
    ChRight.Size=UDim2.fromOffset(size,thick); ChRight.Position=UDim2.new(0,gap,.5,-thick/2)
end
UpdateCrosshair()

local LightBackup={Ambient=nil,Brightness=nil,ClockTime=nil,FogEnd=nil,FogStart=nil,GlobalShadows=nil}
local TerrainBackup={WaveSize=nil,WaveSpeed=nil,Reflectance=nil,Transparency=nil}
local ParticleBackup={}
local Lighting=game:GetService("Lighting")
local function ApplyLocalVisuals()
    if Config.FullBright then
        if LightBackup.Ambient==nil then
            LightBackup.Ambient=Lighting.Ambient; LightBackup.Brightness=Lighting.Brightness; LightBackup.ClockTime=Lighting.ClockTime; LightBackup.GlobalShadows=Lighting.GlobalShadows
        end
        Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=2; Lighting.ClockTime=14; Lighting.GlobalShadows=false
    elseif LightBackup.Ambient~=nil then
        Lighting.Ambient=LightBackup.Ambient; Lighting.Brightness=LightBackup.Brightness; Lighting.ClockTime=LightBackup.ClockTime; Lighting.GlobalShadows=LightBackup.GlobalShadows
        LightBackup.Ambient=nil
    end
    if Config.NoFog then
        if LightBackup.FogEnd==nil then LightBackup.FogEnd=Lighting.FogEnd; LightBackup.FogStart=Lighting.FogStart end
        Lighting.FogStart=0; Lighting.FogEnd=100000
    elseif LightBackup.FogEnd~=nil then
        Lighting.FogEnd=LightBackup.FogEnd; Lighting.FogStart=LightBackup.FogStart; LightBackup.FogEnd=nil
    end
end

local bobTime=0
local function ApplyCameraSettings(dt)
    local cam=workspace.CurrentCamera
    if not cam then return end
    cam.FieldOfView=Config.FOV

    local h=Humanoid()
    if h then
        if Config.CameraBob and not Config.ThirdPerson and h.MoveDirection.Magnitude>0.05 then
            bobTime+=dt or 0.016
            local speed=math.max(h.WalkSpeed,1)
            local amount=math.clamp(speed/32,0.65,1.8)
            h.CameraOffset=Vector3.new(0,math.sin(bobTime*10)*0.035*amount,0)
        else
            h.CameraOffset=Vector3.new(0,0,0)
        end
    end

    if Config.ThirdPerson then
        local c=Character(); local root=c and c:FindFirstChild("HumanoidRootPart")
        if root then
            local target=root.Position-root.CFrame.LookVector*8+Vector3.new(0,3,0)
            cam.CFrame=CFrame.lookAt(target,root.Position+Vector3.new(0,1.5,0))
        end
    end
end

local function ApplyLowGraphics()
    local terrain=workspace:FindFirstChildOfClass("Terrain")

    if Config.LowGraphics then
        if terrain and TerrainBackup.WaveSize==nil then
            TerrainBackup.WaveSize=terrain.WaterWaveSize
            TerrainBackup.WaveSpeed=terrain.WaterWaveSpeed
            TerrainBackup.Reflectance=terrain.WaterReflectance
            TerrainBackup.Transparency=terrain.WaterTransparency
        end

        if terrain then
            terrain.WaterWaveSize=0
            terrain.WaterWaveSpeed=0
            terrain.WaterReflectance=0
            terrain.WaterTransparency=.5
        end

        for _,object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
                if ParticleBackup[object]==nil then
                    ParticleBackup[object]=object.Enabled
                end
                object.Enabled=false
            end
        end
    else
        if terrain and TerrainBackup.WaveSize~=nil then
            terrain.WaterWaveSize=TerrainBackup.WaveSize
            terrain.WaterWaveSpeed=TerrainBackup.WaveSpeed
            terrain.WaterReflectance=TerrainBackup.Reflectance
            terrain.WaterTransparency=TerrainBackup.Transparency
            TerrainBackup.WaveSize=nil
        end

        for object,enabled in pairs(ParticleBackup) do
            if object and object.Parent then
                object.Enabled=enabled
            end
        end
        table.clear(ParticleBackup)
    end
end

--========================================================
-- ADVANCED LOCAL GRAPHICS
--========================================================

local LocalColor = New("ColorCorrectionEffect",{
    Name="FPSPanelLocalColor",
    Enabled=false,
    Saturation=0,
    Contrast=0,
    Brightness=0,
},Lighting)

local PostFXBackup={}

local function ApplyAdvancedGraphics()
    LocalColor.Enabled =
        Config.Saturation ~= 0
        or Config.Contrast ~= 0
        or Config.ColorBoost ~= 0

    LocalColor.Saturation=Config.Saturation
    LocalColor.Contrast=Config.Contrast
    LocalColor.Brightness=Config.ColorBoost

    if Config.DisablePostFX then
        for _,effect in ipairs(Lighting:GetChildren()) do
            if effect ~= LocalColor and (
                effect:IsA("BloomEffect")
                or effect:IsA("BlurEffect")
                or effect:IsA("ColorCorrectionEffect")
                or effect:IsA("DepthOfFieldEffect")
                or effect:IsA("SunRaysEffect")
            ) then
                if PostFXBackup[effect]==nil then
                    PostFXBackup[effect]=effect.Enabled
                end
                effect.Enabled=false
            end
        end
    else
        for effect,enabled in pairs(PostFXBackup) do
            if effect and effect.Parent then
                effect.Enabled=enabled
            end
        end
        table.clear(PostFXBackup)
    end
end

local ParticleBackupExtra={}

local function ApplyParticleReduction()
    if Config.ReduceParticles then
        for _,object in ipairs(workspace:GetDescendants()) do
            if object:IsA("ParticleEmitter")
                or object:IsA("Trail")
                or object:IsA("Beam") then

                if ParticleBackupExtra[object]==nil then
                    ParticleBackupExtra[object]=object.Enabled
                end

                object.Enabled=false
            end
        end
    elseif next(ParticleBackupExtra)~=nil then
        for object,enabled in pairs(ParticleBackupExtra) do
            if object and object.Parent then
                object.Enabled=enabled
            end
        end
        table.clear(ParticleBackupExtra)
    end
end

--========================================================
-- GAMEPLAY FEATURES
--========================================================
local savedSpeed=nil
local savedCollision={}

--========================================================
-- ESP SYSTEM (stable screen-space implementation)
--========================================================
local espOverlay=New("Frame",{
    Name="ESPOverlay",
    Size=UDim2.fromScale(1,1),
    Position=UDim2.fromScale(0,0),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    Active=false,
},Gui)
espOverlay.ZIndex=50

local espObjects={}

local function GetESPColor(player)
    if not Config.ESPTeamColor then
        return C.Accent
    end
    local ok, color = pcall(function()
        return player.TeamColor and player.TeamColor.Color
    end)
    if ok and color then
        return color
    end
    return C.Accent
end

local function MakeCornerSegment(parent, position, size)
    return New("Frame",{
        Position=position,
        Size=size,
        BackgroundColor3=C.Accent,
        BorderSizePixel=0,
        ZIndex=53,
    },parent)
end

local function RemoveESP(player)
    local e=espObjects[player]
    if not e then return end
    if e.container then e.container:Destroy() end
    if e.highlight then e.highlight:Destroy() end
    espObjects[player]=nil
end

local function CreateESP(player)
    if player==LocalPlayer then return end
    local char=player.Character
    if not char then return end

    RemoveESP(player)

    local container=New("Frame",{
        Name="ESP_"..tostring(player.UserId),
        Size=UDim2.fromScale(1,1),
        Position=UDim2.fromScale(0,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        Active=false,
    },espOverlay)
    container.ZIndex=51

    local highlight=New("Highlight",{
        Name="ESPHighlight",
        Adornee=char,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        FillTransparency=.90,
        OutlineTransparency=0,
        FillColor=GetESPColor(player),
        OutlineColor=GetESPColor(player),
    },Gui)

    local segments={
        MakeCornerSegment(container,UDim2.fromOffset(0,0),UDim2.fromOffset(28,2)),
        MakeCornerSegment(container,UDim2.fromOffset(0,0),UDim2.fromOffset(2,28)),
        MakeCornerSegment(container,UDim2.new(1,-28,0,0),UDim2.fromOffset(28,2)),
        MakeCornerSegment(container,UDim2.new(1,-2,0,0),UDim2.fromOffset(2,28)),
        MakeCornerSegment(container,UDim2.new(0,0,1,-2),UDim2.fromOffset(28,2)),
        MakeCornerSegment(container,UDim2.new(0,0,1,-28),UDim2.fromOffset(2,28)),
        MakeCornerSegment(container,UDim2.new(1,-28,1,-2),UDim2.fromOffset(28,2)),
        MakeCornerSegment(container,UDim2.new(1,-2,1,-28),UDim2.fromOffset(2,28)),
    }

    local name=New("TextLabel",{
        Size=UDim2.fromOffset(220,18),
        BackgroundTransparency=1,
        Text=player.DisplayName,
        TextColor3=Color3.new(1,1,1),
        TextStrokeTransparency=.25,
        TextSize=12,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=54,
    },container)

    local distance=New("TextLabel",{
        Size=UDim2.fromOffset(220,15),
        BackgroundTransparency=1,
        TextColor3=C.Sub,
        TextStrokeTransparency=.35,
        TextSize=9,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=54,
    },container)

    local hpText=New("TextLabel",{
        Size=UDim2.fromOffset(220,15),
        BackgroundTransparency=1,
        TextColor3=Color3.new(1,1,1),
        TextStrokeTransparency=.35,
        TextSize=9,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=54,
    },container)

    local hpBack=New("Frame",{
        Size=UDim2.fromOffset(90,5),
        BackgroundColor3=Color3.fromRGB(35,35,40),
        BorderSizePixel=0,
        ZIndex=54,
    },container)
    Corner(hpBack,3)
    local hpFill=New("Frame",{
        Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.Good,
        BorderSizePixel=0,
        ZIndex=55,
    },hpBack)
    Corner(hpFill,3)

    local tracer=New("Frame",{
        Name="Tracer",
        AnchorPoint=Vector2.new(.5,.5),
        BackgroundColor3=GetESPColor(player),
        BorderSizePixel=0,
        Visible=false,
        Size=UDim2.fromOffset(2,20),
        ZIndex=49,
    },espOverlay)

    espObjects[player]={
        container=container,
        highlight=highlight,
        segments=segments,
        name=name,
        distance=distance,
        hpText=hpText,
        hpBack=hpBack,
        hpFill=hpFill,
        tracer=tracer,
    }
end

local function GetScreenBounds(camera, character)
    local ok, cf, size = pcall(function()
        return character:GetBoundingBox()
    end)
    if not ok or typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then return nil end

    local half=size*.5
    local corners={
        cf*CFrame.new(-half.X,-half.Y,-half.Z),
        cf*CFrame.new(-half.X,-half.Y, half.Z),
        cf*CFrame.new(-half.X, half.Y,-half.Z),
        cf*CFrame.new(-half.X, half.Y, half.Z),
        cf*CFrame.new( half.X,-half.Y,-half.Z),
        cf*CFrame.new( half.X,-half.Y, half.Z),
        cf*CFrame.new( half.X, half.Y,-half.Z),
        cf*CFrame.new( half.X, half.Y, half.Z),
    }

    local minX, minY=math.huge, math.huge
    local maxX, maxY=-math.huge, -math.huge
    local anyFront=false
    for _,cornerCF in ipairs(corners) do
        local point=cornerCF.Position
        local screen,onScreen=camera:WorldToViewportPoint(point)
        if screen.Z>0 then
            anyFront=true
            minX=math.min(minX,screen.X); maxX=math.max(maxX,screen.X)
            minY=math.min(minY,screen.Y); maxY=math.max(maxY,screen.Y)
        end
        if onScreen and screen.Z>0 then
            anyFront=true
        end
    end

    if not anyFront or minX==math.huge then return nil end

    local view=camera.ViewportSize
    minX=math.clamp(minX,0,view.X); maxX=math.clamp(maxX,0,view.X)
    minY=math.clamp(minY,0,view.Y); maxY=math.clamp(maxY,0,view.Y)
    if maxX-minX<4 or maxY-minY<6 then return nil end
    return minX,minY,maxX,maxY
end

local function UpdateTracer(tracer,point)
    local cam=workspace.CurrentCamera
    if not cam or not tracer then return end
    local from=Vector2.new(cam.ViewportSize.X*.5,cam.ViewportSize.Y)
    local to=Vector2.new(point.X,point.Y)
    local d=to-from
    local len=d.Magnitude
    if len<3 then tracer.Visible=false return end
    tracer.Visible=true
    tracer.Position=UDim2.fromOffset((from.X+to.X)*.5,(from.Y+to.Y)*.5)
    tracer.Size=UDim2.fromOffset(2,len)
    tracer.Rotation=math.deg(math.atan2(d.Y,d.X))+90
end

local function UpdateESP()
    if not Config.ESP then
        for plr in pairs(espObjects) do RemoveESP(plr) end
        return
    end

    local cam=workspace.CurrentCamera
    local mine=Character()
    local myRoot=mine and mine:FindFirstChild("HumanoidRootPart")
    if not cam or not myRoot then return end

    local seen={}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then
            local char=plr.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            local root=char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and root and hum.Health>0 then
                local dist=(root.Position-myRoot.Position).Magnitude
                if dist<=Config.ESPMaxDistance then
                    local bounds=GetScreenBounds(cam,char)
                    if bounds then
                        if not espObjects[plr] or not espObjects[plr].container.Parent then
                            CreateESP(plr)
                        end
                        local e=espObjects[plr]
                        if e then
                            seen[plr]=true
                            local minX,minY,maxX,maxY=table.unpack(bounds)
                            local width=maxX-minX
                            local height=maxY-minY
                            local color=GetESPColor(plr)
                            e.highlight.Adornee=char
                            e.highlight.FillColor=color
                            e.highlight.OutlineColor=color
                            e.highlight.Enabled=true
                            e.container.Visible=true

                            e.container.Position=UDim2.fromOffset(minX,minY)
                            e.container.Size=UDim2.fromOffset(width,height)

                            local cornerW=math.clamp(width*.28,12,34)
                            local cornerH=math.clamp(height*.22,12,34)
                            local seg=e.segments
                            seg[1].Position=UDim2.fromOffset(0,0); seg[1].Size=UDim2.fromOffset(cornerW,2)
                            seg[2].Position=UDim2.fromOffset(0,0); seg[2].Size=UDim2.fromOffset(2,cornerH)
                            seg[3].Position=UDim2.new(1,0,0,0); seg[3].AnchorPoint=Vector2.new(1,0); seg[3].Size=UDim2.fromOffset(cornerW,2)
                            seg[4].Position=UDim2.new(1,0,0,0); seg[4].AnchorPoint=Vector2.new(1,0); seg[4].Size=UDim2.fromOffset(2,cornerH)
                            seg[5].Position=UDim2.new(0,0,1,0); seg[5].AnchorPoint=Vector2.new(0,1); seg[5].Size=UDim2.fromOffset(cornerW,2)
                            seg[6].Position=UDim2.new(0,0,1,0); seg[6].AnchorPoint=Vector2.new(0,1); seg[6].Size=UDim2.fromOffset(2,cornerH)
                            seg[7].Position=UDim2.new(1,0,1,0); seg[7].AnchorPoint=Vector2.new(1,1); seg[7].Size=UDim2.fromOffset(cornerW,2)
                            seg[8].Position=UDim2.new(1,0,1,0); seg[8].AnchorPoint=Vector2.new(1,1); seg[8].Size=UDim2.fromOffset(2,cornerH)
                            for _,v in ipairs(seg) do
                                v.BackgroundColor3=color
                                v.Visible=Config.ESPBoxes
                            end

                            e.name.Visible=Config.ESPNames
                            e.name.Position=UDim2.new(.5,-110,0,-20)
                            e.name.Text=plr.DisplayName

                            e.distance.Visible=Config.ESPDistance
                            e.distance.Position=UDim2.new(.5,-110,1,2)
                            e.distance.Text=string.format("%d studs",math.floor(dist+.5))

                            e.hpText.Visible=Config.ESPHealth
                            e.hpText.Position=UDim2.new(.5,-110,1,17)
                            local ratio=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                            e.hpText.Text=string.format("HP  %d / %d",math.floor(hum.Health+.5),math.floor(hum.MaxHealth+.5))
                            e.hpFill.Size=UDim2.new(ratio,0,1,0)
                            e.hpFill.BackgroundColor3=Color3.new(1-ratio,ratio,0)
                            e.hpBack.Visible=Config.ESPHealth
                            e.hpBack.Position=UDim2.new(.5,-45,1,34)

                            local head=char:FindFirstChild("Head")
                            if Config.ESPTracers and head then
                                local point,onScreen=cam:WorldToViewportPoint(head.Position)
                                if onScreen and point.Z>0 then
                                    e.tracer.BackgroundColor3=color
                                    UpdateTracer(e.tracer,point)
                                else
                                    e.tracer.Visible=false
                                end
                            else
                                e.tracer.Visible=false
                            end
                        end
                    end
                end
            end
        end
    end

    for plr in pairs(espObjects) do
        if not seen[plr] then
            local e=espObjects[plr]
            if e then
                e.tracer.Visible=false
                if e.highlight then e.highlight.Enabled=false end
                if e.container then e.container.Visible=false end
            end
        end
    end
end

local function HookPlayer(player)
    if player==LocalPlayer then return end
    player.CharacterAdded:Connect(function()
        task.wait(.1)
        if Config.ESP then
            CreateESP(player)
        end
    end)
    player.CharacterRemoving:Connect(function()
        RemoveESP(player)
    end)
    if player.Character and Config.ESP then
        CreateESP(player)
    end
end

for _,player in ipairs(Players:GetPlayers()) do
    HookPlayer(player)
end
Players.PlayerAdded:Connect(HookPlayer)

Players.PlayerRemoving:Connect(RemoveESP)
LocalPlayer.CharacterAdded:Connect(function()
    savedSpeed=nil; table.clear(savedCollision); task.wait(.5)
    if Config.Speed then UpdateSpeed() end
    if Config.Invisibility then Invisibility(true) end
end)


local fpsValue=60
local fpsAccum=0
local fpsFrames=0
local function UpdateStatus(dt)
    fpsAccum+=dt; fpsFrames+=1
    if fpsAccum>=.5 then fpsValue=math.floor(fpsFrames/fpsAccum+.5); fpsAccum=0; fpsFrames=0 end
    local lines={}
    if Config.FPSCounter then table.insert(lines,"FPS   ") ; lines[#lines]=lines[#lines]..tostring(fpsValue) end
    if Config.PingCounter then
        local ok,ping=pcall(function() return LocalPlayer:GetNetworkPing()*1000 end)
        if ok then table.insert(lines,"PING  "..tostring(math.floor(ping+0.5)).." ms") end
    end
    if Config.Coordinates then
        local c=Character(); local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then table.insert(lines,string.format("POS   %d, %d, %d",r.Position.X,r.Position.Y,r.Position.Z)) end
    end
    if Config.LocalTime then
        table.insert(lines,"TIME  "..os.date("%H:%M:%S"))
    end
    Status.Text=table.concat(lines,"\n")
    Status.Visible=#lines>0
end

local function ApplyClientSettings(dt)
    UpdateCrosshair()
    ApplyLocalVisuals()
    ApplyLowGraphics()
    ApplyCameraSettings(dt)
end

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local h=Humanoid()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

--========================================================
-- LIGHTWEIGHT LOOP
--========================================================
local espT=0; local speedT=0; local noclipT=0; local invisT=0
task.defer(function() if Config.ESP then UpdateESP() end end)
RunService.RenderStepped:Connect(function(dt)
    ApplyClientSettings(dt)
    UpdateStatus(dt)
    if Config.AutoSprint then
        pcall(function()
            LocalPlayer:SetAttribute("FPSPanelSprint", true)
        end)
    else
        pcall(function()
            LocalPlayer:SetAttribute("FPSPanelSprint", false)
        end)
    end

    if Config.Aimbot then Aimbot(dt) end
    espT+=dt; if espT>=Config.ESPUpdateRate then espT=0; if Config.ESP or next(espObjects) then UpdateESP() end end
    speedT+=dt; if speedT>=.08 then speedT=0; if Config.Speed or savedSpeed~=nil then UpdateSpeed() end end
    noclipT+=dt; if noclipT>=.05 then noclipT=0; if Config.NoClip or next(savedCollision) then UpdateNoClip() end end
    invisT+=dt; if invisT>=.20 then invisT=0; if Config.Invisibility then Invisibility(true) end end
end)

print("FPS PANEL loaded | Only hotkey: O | Tabs: Combat / Visuals / Movement / Player / Settings")


-- Remember the active profile for the next execution in the same environment.
Env.FPSPanelLastActiveProfile = Config.ActiveProfile
SaveProfile(Config.ActiveProfile)
