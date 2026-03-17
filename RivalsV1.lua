-- ╔══════════════════════════════════════╗
-- ║   RIVALS V1  ·  Premium  ·  B0004   ║
-- ╚══════════════════════════════════════╝
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ══════════════════════════════════════════
-- KEYAUTH  (runs before main GUI)
-- ══════════════════════════════════════════
local KA = {
    Name    = "Roblox Universal",
    OwnerId = "P3x44Wdlvp",
    Secret  = "18b2b672e67410583f896e470d63c2d7b09c97531a7745903677835ef6db1208",
    Version = "1.0",
    BaseUrl = "https://keyauth.win/api/1.2/",
}
local KA_SessionId = nil

-- URL-encode a string for form body
local function UrlEncode(s)
    s = tostring(s)
    s = s:gsub("([^%w%-%.%_%~ ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return s:gsub(" ", "+")
end

local function KAPost(fields)
    local parts={}
    for k,v in pairs(fields) do
        table.insert(parts, UrlEncode(k).."="..UrlEncode(v))
    end
    local body=table.concat(parts,"&")
    local ok, res = pcall(function()
        return request({
            Url    = KA.BaseUrl,
            Method = "POST",
            Headers = {["Content-Type"]="application/x-www-form-urlencoded"},
            Body   = body,
        })
    end)
    if not ok or not res then return {success=false,message="Network error"} end
    local parsed
    pcall(function()
        parsed=game:GetService("HttpService"):JSONDecode(res.Body)
    end)
    return parsed or {success=false,message="Parse error"}
end

-- Generate a consistent HWID from the local player's UserId
local function GetHWID()
    local uid = tostring(LocalPlayer.UserId)
    -- simple deterministic hash → looks like a real hwid
    local h = 0
    for i=1,#uid do h = (h * 31 + string.byte(uid,i)) % 0xFFFFFFFF end
    return string.format("RBLX-%s-%08X", uid, h)
end

-- Step 1: init — gets a sessionid back
local function KAInit()
    local res = KAPost({
        type    = "init",
        ver     = KA.Version,
        name    = KA.Name,
        ownerid = KA.OwnerId,
        hwid    = GetHWID(),
    })
    if res and res.sessionid then
        KA_SessionId = res.sessionid
        return true
    end
    return false, (res and res.message) or "Init failed"
end

-- Step 2: license check — requires sessionid from init
local function KALicense(key)
    if not KA_SessionId then return {success=false,message="No session"} end
    return KAPost({
        type      = "license",
        key       = key,
        sessionid = KA_SessionId,
        hwid      = GetHWID(),
        name      = KA.Name,
        ownerid   = KA.OwnerId,
    })
end

-- Key GUI
local KeyGui=Instance.new("ScreenGui")
KeyGui.Name="RivalsKeyGui"; KeyGui.ResetOnSpawn=false; KeyGui.DisplayOrder=1000
KeyGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local kgOk=pcall(function()
    if gethui then KeyGui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(KeyGui); KeyGui.Parent=game.CoreGui
    else KeyGui.Parent=game.CoreGui end
end)
if not kgOk then pcall(function() KeyGui.Parent=LocalPlayer:WaitForChild("PlayerGui") end) end

local KGOverlay=Instance.new("Frame",KeyGui)
KGOverlay.BackgroundColor3=Color3.fromRGB(0,0,0); KGOverlay.BackgroundTransparency=0.4
KGOverlay.BorderSizePixel=0; KGOverlay.Size=UDim2.new(1,0,1,0)

local KWin=Instance.new("Frame",KeyGui)
KWin.BackgroundColor3=Color3.fromRGB(12,12,14); KWin.BorderSizePixel=0
KWin.Position=UDim2.new(0.5,-190,0.5,-140); KWin.Size=UDim2.new(0,380,0,280)
KWin.ZIndex=5; KWin.ClipsDescendants=true
Instance.new("UICorner",KWin).CornerRadius=UDim.new(0,14)

-- Key GUI particles
local KPHost=Instance.new("Frame",KWin)
KPHost.BackgroundTransparency=1; KPHost.BorderSizePixel=0
KPHost.Size=UDim2.new(1,0,1,0); KPHost.ZIndex=1; KPHost.ClipsDescendants=true
local KGOLDS={
    Color3.fromRGB(255,210,30),Color3.fromRGB(255,180,0),Color3.fromRGB(255,240,100),
    Color3.fromRGB(200,140,0),Color3.fromRGB(255,255,120),Color3.fromRGB(180,120,0),
}
local kpts={}
for i=1,22 do
    local d=Instance.new("Frame",KPHost); d.BorderSizePixel=0; d.ZIndex=2
    d.BackgroundColor3=KGOLDS[math.random(#KGOLDS)]
    local sz=math.random(2,4); d.Size=UDim2.new(0,sz,0,sz)
    local px=math.random(150,9850)/10000; local py=math.random(-2000,9800)/10000
    d.Position=UDim2.new(px,0,py,0)
    local base=math.random(25,70)/100; d.BackgroundTransparency=base
    Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
    kpts[i]={f=d,x=px,y=py,spd=math.random(60,220)/100000,
        a=base,aDir=math.random(2)==1 and 1 or -1,aSpd=math.random(1,5)/1200}
end
RunService.RenderStepped:Connect(function()
    if not KPHost or not KPHost.Parent then return end
    for _,p in ipairs(kpts) do
        p.y=p.y+p.spd
        if p.y>1.06 then
            p.y=math.random(-2000,-80)/10000; p.x=math.random(150,9850)/10000
            p.f.BackgroundColor3=KGOLDS[math.random(#KGOLDS)]
            local s=math.random(2,4); p.f.Size=UDim2.new(0,s,0,s)
        end
        p.a=p.a+p.aDir*p.aSpd
        if p.a>0.76 then p.a=0.76; p.aDir=-1 elseif p.a<0.12 then p.a=0.12; p.aDir=1 end
        p.f.Position=UDim2.new(p.x,0,p.y,0); p.f.BackgroundTransparency=p.a
    end
end)

local KGlow=Instance.new("ImageLabel",KWin)
KGlow.BackgroundTransparency=1; KGlow.ZIndex=0
KGlow.Position=UDim2.new(0,-18,0,-18); KGlow.Size=UDim2.new(1,36,1,36)
KGlow.Image="rbxassetid://5028857084"; KGlow.ImageColor3=Color3.fromRGB(255,210,30)
KGlow.ImageTransparency=0.42; KGlow.ScaleType=Enum.ScaleType.Slice; KGlow.SliceCenter=Rect.new(24,24,276,276)

local KBar=Instance.new("Frame",KWin)
KBar.BackgroundColor3=Color3.fromRGB(255,210,30); KBar.BorderSizePixel=0; KBar.Size=UDim2.new(1,0,0,6); KBar.ZIndex=8
local KBarG=Instance.new("UIGradient",KBar)
KBarG.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(160,110,0)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,255,100)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(160,110,0)),
}
task.spawn(function() while task.wait(0.04) do if KBarG then KBarG.Rotation=(KBarG.Rotation+3)%360 else break end end end)

local KHdr=Instance.new("Frame",KWin)
KHdr.BackgroundColor3=Color3.fromRGB(18,18,20); KHdr.BorderSizePixel=0
KHdr.Position=UDim2.new(0,0,0,6); KHdr.Size=UDim2.new(1,0,0,46); KHdr.ZIndex=8

local KPill=Instance.new("Frame",KHdr)
KPill.BackgroundColor3=Color3.fromRGB(255,210,30); KPill.BorderSizePixel=0
KPill.Position=UDim2.new(0,12,0.5,-12); KPill.Size=UDim2.new(0,24,0,24); KPill.ZIndex=9
Instance.new("UICorner",KPill).CornerRadius=UDim.new(0,6)
local KPL=Instance.new("TextLabel",KPill)
KPL.BackgroundTransparency=1; KPL.Size=UDim2.new(1,0,1,0)
KPL.Font=Enum.Font.GothamBold; KPL.Text="R"; KPL.TextColor3=Color3.fromRGB(10,10,14); KPL.TextSize=15; KPL.ZIndex=10

local KTitleL=Instance.new("TextLabel",KHdr)
KTitleL.BackgroundTransparency=1; KTitleL.Position=UDim2.new(0,44,0,5); KTitleL.Size=UDim2.new(0,200,0,17)
KTitleL.Font=Enum.Font.GothamBold; KTitleL.Text="RIVALS V1"; KTitleL.TextColor3=Color3.fromRGB(240,240,230)
KTitleL.TextSize=14; KTitleL.TextXAlignment=Enum.TextXAlignment.Left; KTitleL.ZIndex=9

local KSubL=Instance.new("TextLabel",KHdr)
KSubL.BackgroundTransparency=1; KSubL.Position=UDim2.new(0,44,0,23); KSubL.Size=UDim2.new(0,200,0,12)
KSubL.Font=Enum.Font.Gotham; KSubL.Text="Key Authentication"; KSubL.TextColor3=Color3.fromRGB(200,155,0)
KSubL.TextSize=10; KSubL.TextXAlignment=Enum.TextXAlignment.Left; KSubL.ZIndex=9

local KBody=Instance.new("Frame",KWin)
KBody.BackgroundTransparency=1; KBody.Position=UDim2.new(0,0,0,52); KBody.Size=UDim2.new(1,0,1,-52); KBody.ZIndex=5

local KIcon=Instance.new("TextLabel",KBody)
KIcon.BackgroundTransparency=1; KIcon.Position=UDim2.new(0.5,-16,0,12); KIcon.Size=UDim2.new(0,32,0,32)
KIcon.Font=Enum.Font.GothamBold; KIcon.Text="🔑"; KIcon.TextSize=26; KIcon.ZIndex=6

local KPrompt=Instance.new("TextLabel",KBody)
KPrompt.BackgroundTransparency=1; KPrompt.Position=UDim2.new(0,20,0,46); KPrompt.Size=UDim2.new(1,-40,0,16)
KPrompt.Font=Enum.Font.Gotham; KPrompt.Text="Enter your license key to continue"
KPrompt.TextColor3=Color3.fromRGB(155,142,90); KPrompt.TextSize=12; KPrompt.ZIndex=6

local KInputBG=Instance.new("Frame",KBody)
KInputBG.BackgroundColor3=Color3.fromRGB(22,22,25); KInputBG.BorderSizePixel=0
KInputBG.Position=UDim2.new(0,20,0,68); KInputBG.Size=UDim2.new(1,-40,0,36); KInputBG.ZIndex=6
Instance.new("UICorner",KInputBG).CornerRadius=UDim.new(0,8)
local KInputStroke=Instance.new("UIStroke",KInputBG)
KInputStroke.Color=Color3.fromRGB(255,210,30); KInputStroke.Thickness=1.5; KInputStroke.Transparency=0.7

local KInput=Instance.new("TextBox",KInputBG)
KInput.BackgroundTransparency=1; KInput.Size=UDim2.new(1,-12,1,0); KInput.Position=UDim2.new(0,10,0,0)
KInput.Font=Enum.Font.GothamSemibold; KInput.Text=""; KInput.PlaceholderText="xxxxxx-xxxxxx-xxxxxx"
KInput.TextColor3=Color3.fromRGB(240,240,230); KInput.PlaceholderColor3=Color3.fromRGB(90,82,50)
KInput.TextSize=12; KInput.ClearTextOnFocus=false; KInput.ZIndex=7; KInput.TextXAlignment=Enum.TextXAlignment.Left
KInput.Focused:Connect(function()
    TweenService:Create(KInputStroke,TweenInfo.new(0.15),{Transparency=0,Thickness=2}):Play()
end)
KInput.FocusLost:Connect(function()
    TweenService:Create(KInputStroke,TweenInfo.new(0.15),{Transparency=0.7,Thickness=1.5}):Play()
end)

local KStatus=Instance.new("TextLabel",KBody)
KStatus.BackgroundTransparency=1; KStatus.Position=UDim2.new(0,20,0,110); KStatus.Size=UDim2.new(1,-40,0,14)
KStatus.Font=Enum.Font.Gotham; KStatus.Text=""
KStatus.TextColor3=Color3.fromRGB(155,142,90); KStatus.TextSize=11; KStatus.ZIndex=6

local KVerify=Instance.new("TextButton",KBody)
KVerify.BackgroundColor3=Color3.fromRGB(255,210,30); KVerify.BorderSizePixel=0
KVerify.Position=UDim2.new(0,20,0,132); KVerify.Size=UDim2.new(1,-40,0,38)
KVerify.Font=Enum.Font.GothamBold; KVerify.Text="Verify Key"; KVerify.TextColor3=Color3.fromRGB(10,10,14)
KVerify.TextSize=14; KVerify.AutoButtonColor=false; KVerify.ZIndex=6
Instance.new("UICorner",KVerify).CornerRadius=UDim.new(0,8)
KVerify.MouseEnter:Connect(function() TweenService:Create(KVerify,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(255,230,80)}):Play() end)
KVerify.MouseLeave:Connect(function() TweenService:Create(KVerify,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(255,210,30)}):Play() end)

local KGetKey=Instance.new("TextButton",KBody)
KGetKey.BackgroundTransparency=1; KGetKey.BorderSizePixel=0
KGetKey.Position=UDim2.new(0,20,0,182); KGetKey.Size=UDim2.new(1,-40,0,16)
KGetKey.Font=Enum.Font.Gotham; KGetKey.Text="Don't have a key?  Get one here →"
KGetKey.TextColor3=Color3.fromRGB(200,155,0); KGetKey.TextSize=11; KGetKey.AutoButtonColor=false; KGetKey.ZIndex=6
KGetKey.MouseEnter:Connect(function() KGetKey.TextColor3=Color3.fromRGB(255,210,30) end)
KGetKey.MouseLeave:Connect(function() KGetKey.TextColor3=Color3.fromRGB(200,155,0) end)
KGetKey.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://keyauth.win/") end)
    KStatus.Text="Link copied!"; KStatus.TextColor3=Color3.fromRGB(255,210,30)
end)

KWin.Size=UDim2.new(0,0,0,0); KWin.Position=UDim2.new(0.5,0,0.5,0)
TweenService:Create(KWin,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
    {Size=UDim2.new(0,380,0,280),Position=UDim2.new(0.5,-190,0.5,-140)}):Play()

local _G_Authed=false
local function DoVerify()
    local key=KInput.Text
    if key=="" then
        KStatus.Text="⚠  Please enter a key"; KStatus.TextColor3=Color3.fromRGB(255,120,50); return
    end
    KVerify.Text="Checking..."; KVerify.BackgroundColor3=Color3.fromRGB(180,145,0)
    KStatus.Text="Initialising session..."; KStatus.TextColor3=Color3.fromRGB(155,142,90)
    task.spawn(function()
        -- Step 1: init to get sessionid
        local initOk, initErr = KAInit()
        if not initOk then
            KStatus.Text="✗  "..tostring(initErr); KStatus.TextColor3=Color3.fromRGB(255,80,70)
            KVerify.Text="Verify Key"; KVerify.BackgroundColor3=Color3.fromRGB(255,210,30)
            return
        end
        KStatus.Text="Verifying key..."; KStatus.TextColor3=Color3.fromRGB(155,142,90)
        -- Step 2: license check with session
        local res=KALicense(key)
        if res and res.success then
            KStatus.Text="✓  Access granted!"; KStatus.TextColor3=Color3.fromRGB(80,220,90)
            KVerify.Text="✓  Verified"; KVerify.BackgroundColor3=Color3.fromRGB(50,180,80)
            task.wait(0.7)
            TweenService:Create(KWin,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.In),
                {Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
            TweenService:Create(KGOverlay,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play()
            task.wait(0.32); KeyGui:Destroy(); _G_Authed=true
        else
            local msg=(res and res.message) or "Unknown error"
            KStatus.Text="✗  "..msg; KStatus.TextColor3=Color3.fromRGB(255,80,70)
            KVerify.Text="Verify Key"; KVerify.BackgroundColor3=Color3.fromRGB(255,210,30)
        end
    end)
end
KVerify.MouseButton1Click:Connect(DoVerify)
KInput.FocusLost:Connect(function(entered) if entered then DoVerify() end end)
repeat task.wait(0.05) until _G_Authed==true

-- ══════════════════════════════════════════
-- CONFIG  (yellow/gold accent)
-- ══════════════════════════════════════════
local Config = {
    -- ESP
    BoneESP       = true,
    BoxESP        = true,
    TracerESP     = true,
    NameESP       = true,
    DistanceESP   = true,
    HealthBarESP  = true,
    TeamCheck     = false,
    RainbowMode   = false,
    RainbowSpeed  = 5,
    MaxDistance   = 1000,
    BoneThickness   = 2,
    BoxThickness    = 1,
    TracerThickness = 1,
    TracerOrigin    = "Bottom",
    BoneColor     = Color3.fromRGB(255, 220,  50),
    BoxColor      = Color3.fromRGB(255, 220,  50),
    TracerColor   = Color3.fromRGB(255, 200,   0),
    NameColor     = Color3.fromRGB(255, 240, 120),
    DistanceColor = Color3.fromRGB(200, 180,  80),
    HealthBarColor= Color3.fromRGB(255, 220,  50),
    -- Aimbot
    AimbotEnabled    = false,
    AimbotKey        = Enum.KeyCode.Q,
    AimbotFOV        = 100,
    ShowFOV          = true,
    AimbotSmoothness = 5,
    AimbotPart       = "Head",
    WallCheck        = false,
    TeamCheckAimbot  = false,
    VisibleCheck     = true,
    PredictionEnabled= true,
    PredictionAmount = 0.165,
    FOVColor         = Color3.fromRGB(255, 220,  50),
    -- Movement
    NoclipEnabled = false,
    FlyEnabled    = false,
    FlySpeed      = 60,
    FlyBoost      = 160,
    FlyKey        = Enum.KeyCode.F,
    -- Menu palette (yellow/dark)
    MenuBG      = Color3.fromRGB(12,  12,  14 ),
    MenuHeader  = Color3.fromRGB(18,  18,  20 ),
    MenuAccent  = Color3.fromRGB(255, 210,  30),
    MenuAccent2 = Color3.fromRGB(200, 155,   0),
    MenuElement = Color3.fromRGB(22,  22,  25 ),
    MenuHover   = Color3.fromRGB(34,  31,  16 ),
    MenuText    = Color3.fromRGB(240, 240, 230),
    MenuSub     = Color3.fromRGB(155, 142,  90),
    MenuBG2     = Color3.fromRGB(10,  10,  12 ),
}

local AllConns  = {}
local FOVCircle = nil
local IsAimHeld = false

local R15Bones={
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"UpperTorso","LeftUpperArm" },{"LeftUpperArm","LeftLowerArm" },{"LeftLowerArm","LeftHand"   },
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    {"LowerTorso","LeftUpperLeg" },{"LeftUpperLeg","LeftLowerLeg"  },{"LeftLowerLeg","LeftFoot"  },
}
local R6Bones={
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}

local ESPCache={} ; local LinePool={} ; local TextPool={}

-- ══════════════════════════════════════════
-- GUI ROOT
-- ══════════════════════════════════════════
local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="RivalsV1"; ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ScreenGui.DisplayOrder=999

local ok=pcall(function()
    if gethui then ScreenGui.Parent=gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui); ScreenGui.Parent=game.CoreGui
    else ScreenGui.Parent=game.CoreGui end
end)
if not ok then pcall(function() ScreenGui.Parent=LocalPlayer:WaitForChild("PlayerGui") end) end

local Overlay=Instance.new("Frame",ScreenGui)
Overlay.BackgroundColor3=Color3.fromRGB(0,0,0); Overlay.BackgroundTransparency=0.48
Overlay.BorderSizePixel=0; Overlay.Size=UDim2.new(1,0,1,0)

-- Window  620 x 550
local Win=Instance.new("Frame",ScreenGui)
Win.Name="Win"; Win.BackgroundColor3=Config.MenuBG; Win.BorderSizePixel=0
Win.Position=UDim2.new(0.5,-310,0.5,-275); Win.Size=UDim2.new(0,620,0,550)
Win.ClipsDescendants=true; Win.ZIndex=5
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,14)

local Glow=Instance.new("ImageLabel",Win)
Glow.BackgroundTransparency=1; Glow.ZIndex=0
Glow.Position=UDim2.new(0,-20,0,-20); Glow.Size=UDim2.new(1,40,1,40)
Glow.Image="rbxassetid://5028857084"
Glow.ImageColor3=Config.MenuAccent; Glow.ImageTransparency=0.4
Glow.ScaleType=Enum.ScaleType.Slice; Glow.SliceCenter=Rect.new(24,24,276,276)

-- Particles
local PHost=Instance.new("Frame",Win)
PHost.BackgroundTransparency=1; PHost.BorderSizePixel=0
PHost.Size=UDim2.new(1,0,1,0); PHost.ZIndex=1; PHost.ClipsDescendants=true

local GOLDS={
    Color3.fromRGB(255,210,30),Color3.fromRGB(255,180,0),Color3.fromRGB(255,240,100),
    Color3.fromRGB(200,140,0),Color3.fromRGB(255,255,120),Color3.fromRGB(180,120,0),
    Color3.fromRGB(255,220,60),Color3.fromRGB(240,160,0),Color3.fromRGB(255,250,80),Color3.fromRGB(160,100,0),
}
local pts={}; math.randomseed(tick())
for i=1,36 do
    local d=Instance.new("Frame",PHost); d.BorderSizePixel=0; d.ZIndex=2
    d.BackgroundColor3=GOLDS[math.random(#GOLDS)]
    local sz=math.random(2,5); d.Size=UDim2.new(0,sz,0,sz)
    local px=math.random(150,9850)/10000; local py=math.random(-3000,9800)/10000
    d.Position=UDim2.new(px,0,py,0)
    local base=math.random(22,72)/100; d.BackgroundTransparency=base
    Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
    pts[i]={f=d,x=px,y=py,spd=math.random(55,230)/100000,
        a=base,aDir=math.random(2)==1 and 1 or -1,aSpd=math.random(1,6)/1200}
end
RunService.RenderStepped:Connect(function()
    for _,p in ipairs(pts) do
        p.y=p.y+p.spd
        if p.y>1.08 then
            p.y=math.random(-2500,-80)/10000; p.x=math.random(150,9850)/10000
            p.f.BackgroundColor3=GOLDS[math.random(#GOLDS)]
            local s=math.random(2,5); p.f.Size=UDim2.new(0,s,0,s)
        end
        p.a=p.a+p.aDir*p.aSpd
        if p.a>0.78 then p.a=0.78; p.aDir=-1 elseif p.a<0.10 then p.a=0.10; p.aDir=1 end
        p.f.Position=UDim2.new(p.x,0,p.y,0); p.f.BackgroundTransparency=p.a
    end
end)

-- Accent bar (animated yellow gradient)
local ABar=Instance.new("Frame",Win)
ABar.BackgroundColor3=Config.MenuAccent; ABar.BorderSizePixel=0
ABar.Size=UDim2.new(1,0,0,6); ABar.ZIndex=8
local ABGrad=Instance.new("UIGradient",ABar)
ABGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(160,110,0)),
    ColorSequenceKeypoint.new(0.3, Config.MenuAccent),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255,255,100)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(160,110,0)),
}
task.spawn(function() while task.wait(0.04) do if ABGrad then ABGrad.Rotation=(ABGrad.Rotation+3)%360 else break end end end)

-- ══════════════════════════════════════════
-- HEADER  (y=3, h=52)
-- ══════════════════════════════════════════
local Hdr=Instance.new("Frame",Win)
Hdr.BackgroundColor3=Config.MenuHeader; Hdr.BorderSizePixel=0
Hdr.Position=UDim2.new(0,0,0,6); Hdr.Size=UDim2.new(1,0,0,62); Hdr.ZIndex=8

local Pill=Instance.new("Frame",Hdr)
Pill.BackgroundColor3=Config.MenuAccent; Pill.BorderSizePixel=0
Pill.Position=UDim2.new(0,12,0,17); Pill.Size=UDim2.new(0,28,0,28); Pill.ZIndex=9
Instance.new("UICorner",Pill).CornerRadius=UDim.new(0,7)
local PL=Instance.new("TextLabel",Pill)
PL.BackgroundTransparency=1; PL.Size=UDim2.new(1,0,1,0)
PL.Font=Enum.Font.GothamBold; PL.Text="R"; PL.TextColor3=Color3.fromRGB(10,10,14); PL.TextSize=17; PL.ZIndex=10

local TitleL=Instance.new("TextLabel",Hdr)
TitleL.BackgroundTransparency=1; TitleL.Position=UDim2.new(0,48,0,6); TitleL.Size=UDim2.new(0,220,0,18)
TitleL.Font=Enum.Font.GothamBold; TitleL.Text="RIVALS V1"; TitleL.TextColor3=Config.MenuText; TitleL.TextSize=15
TitleL.TextXAlignment=Enum.TextXAlignment.Left; TitleL.ZIndex=9

local SubL=Instance.new("TextLabel",Hdr)
SubL.BackgroundTransparency=1; SubL.Position=UDim2.new(0,48,0,25); SubL.Size=UDim2.new(0,220,0,13)
SubL.Font=Enum.Font.Gotham; SubL.Text="Premium  ·  Build 0004"; SubL.TextColor3=Config.MenuAccent2; SubL.TextSize=10
SubL.TextXAlignment=Enum.TextXAlignment.Left; SubL.ZIndex=9

local MadeByL=Instance.new("TextLabel",Hdr)
MadeByL.BackgroundTransparency=1; MadeByL.Position=UDim2.new(0,48,0,39); MadeByL.Size=UDim2.new(0,220,0,11)
MadeByL.Font=Enum.Font.Gotham; MadeByL.Text="made by clue"; MadeByL.TextColor3=Color3.fromRGB(110,100,60)
MadeByL.TextSize=9; MadeByL.TextXAlignment=Enum.TextXAlignment.Left; MadeByL.ZIndex=9

local SDot=Instance.new("Frame",Hdr)
SDot.BackgroundColor3=Color3.fromRGB(80,220,90); SDot.BorderSizePixel=0
SDot.Position=UDim2.new(1,-118,0.5,-4); SDot.Size=UDim2.new(0,8,0,8); SDot.ZIndex=9
Instance.new("UICorner",SDot).CornerRadius=UDim.new(1,0)
task.spawn(function()
    while task.wait(1) do if SDot then
        TweenService:Create(SDot,TweenInfo.new(0.5),{Size=UDim2.new(0,10,0,10),Position=UDim2.new(1,-119,0.5,-5)}):Play()
        task.wait(0.5)
        TweenService:Create(SDot,TweenInfo.new(0.5),{Size=UDim2.new(0,8,0,8),Position=UDim2.new(1,-118,0.5,-4)}):Play()
    else break end end
end)
local SLbl=Instance.new("TextLabel",Hdr)
SLbl.BackgroundTransparency=1; SLbl.Position=UDim2.new(1,-107,0.5,-7); SLbl.Size=UDim2.new(0,55,0,14)
SLbl.Font=Enum.Font.GothamSemibold; SLbl.Text="ACTIVE"; SLbl.TextColor3=Color3.fromRGB(80,220,90)
SLbl.TextSize=11; SLbl.TextXAlignment=Enum.TextXAlignment.Left; SLbl.ZIndex=9

local CloseBtn=Instance.new("TextButton",Hdr)
CloseBtn.BackgroundColor3=Color3.fromRGB(220,55,55); CloseBtn.BorderSizePixel=0
CloseBtn.Position=UDim2.new(1,-36,0.5,-13); CloseBtn.Size=UDim2.new(0,24,0,24)
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.Text="×"; CloseBtn.TextColor3=Color3.fromRGB(255,255,255)
CloseBtn.TextSize=18; CloseBtn.AutoButtonColor=false; CloseBtn.ZIndex=9
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,6)
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(255,80,70)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(220,55,55)}):Play() end)

-- ══════════════════════════════════════════
-- TAB BAR  (y=55, h=43)  4 tabs × 135px + gaps
-- ══════════════════════════════════════════
local TabBar=Instance.new("Frame",Win)
TabBar.BackgroundColor3=Config.MenuHeader; TabBar.BorderSizePixel=0
TabBar.Position=UDim2.new(0,0,0,68); TabBar.Size=UDim2.new(1,0,0,43); TabBar.ZIndex=8

local TLL=Instance.new("UIListLayout",TabBar)
TLL.FillDirection=Enum.FillDirection.Horizontal
TLL.HorizontalAlignment=Enum.HorizontalAlignment.Center
TLL.VerticalAlignment=Enum.VerticalAlignment.Center
TLL.SortOrder=Enum.SortOrder.LayoutOrder
TLL.Padding=UDim.new(0,5)

local AllTabData={}

local function MakeTabBtn(name,icon,order)
    local Btn=Instance.new("TextButton",TabBar)
    Btn.LayoutOrder=order; Btn.BackgroundColor3=Config.MenuAccent; Btn.BackgroundTransparency=1
    Btn.BorderSizePixel=0; Btn.Size=UDim2.new(0,135,0,33); Btn.Text=""; Btn.AutoButtonColor=false; Btn.ZIndex=9
    Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,8)

    local UL=Instance.new("Frame",Btn)
    UL.BackgroundColor3=Config.MenuAccent; UL.BorderSizePixel=0
    UL.Position=UDim2.new(0.1,0,1,-3); UL.Size=UDim2.new(0.8,0,0,2)
    Instance.new("UICorner",UL).CornerRadius=UDim.new(1,0); UL.Visible=false; UL.ZIndex=10

    local IL=Instance.new("TextLabel",Btn)
    IL.BackgroundTransparency=1; IL.Position=UDim2.new(0,10,0,0); IL.Size=UDim2.new(0,18,1,0)
    IL.Font=Enum.Font.GothamBold; IL.Text=icon; IL.TextColor3=Config.MenuSub; IL.TextSize=13; IL.ZIndex=10

    local NL=Instance.new("TextLabel",Btn)
    NL.BackgroundTransparency=1; NL.Position=UDim2.new(0,30,0,0); NL.Size=UDim2.new(1,-30,1,0)
    NL.Font=Enum.Font.GothamSemibold; NL.Text=name; NL.TextColor3=Config.MenuSub; NL.TextSize=12
    NL.TextXAlignment=Enum.TextXAlignment.Left; NL.ZIndex=10

    Btn.MouseEnter:Connect(function()
        if not UL.Visible then TweenService:Create(Btn,TweenInfo.new(0.14),{BackgroundTransparency=0.82,BackgroundColor3=Config.MenuAccent}):Play() end
    end)
    Btn.MouseLeave:Connect(function()
        if not UL.Visible then TweenService:Create(Btn,TweenInfo.new(0.14),{BackgroundTransparency=1}):Play() end
    end)
    return Btn,IL,NL,UL
end

-- Content area  y=100
local CArea=Instance.new("Frame",Win)
CArea.BackgroundTransparency=1; CArea.BorderSizePixel=0
CArea.Position=UDim2.new(0,0,0,113); CArea.Size=UDim2.new(1,0,1,-117); CArea.ZIndex=5

local function MakePage(nm)
    local P=Instance.new("ScrollingFrame",CArea)
    P.Name=nm.."Page"; P.BackgroundTransparency=1; P.BorderSizePixel=0
    P.Size=UDim2.new(1,0,1,0); P.CanvasSize=UDim2.new(0,0,0,0); P.ScrollBarThickness=3
    P.ScrollBarImageColor3=Config.MenuAccent; P.ScrollingDirection=Enum.ScrollingDirection.Y
    P.Visible=false; P.ZIndex=5
    local L=Instance.new("UIListLayout",P); L.SortOrder=Enum.SortOrder.LayoutOrder; L.Padding=UDim.new(0,6)
    local Pad=Instance.new("UIPadding",P)
    Pad.PaddingLeft=UDim.new(0,18); Pad.PaddingRight=UDim.new(0,18)
    Pad.PaddingTop=UDim.new(0,12); Pad.PaddingBottom=UDim.new(0,14)
    L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        P.CanvasSize=UDim2.new(0,0,0,L.AbsoluteContentSize.Y+22)
    end)
    return P
end

local PgESP=MakePage("ESP")
local PgMov=MakePage("Mov")
local PgAim=MakePage("Aim")
local PgSet=MakePage("Set")
PgESP.Visible=true

local EB,EI,EL,EUL=MakeTabBtn("ESP",     "👁",1)
local MB,MI,ML,MUL=MakeTabBtn("Movement","🚀",2)
local AB,AI,AL,AUL=MakeTabBtn("Aimbot",  "🎯",3)
local SB,SI,SL,SUL=MakeTabBtn("Settings","⚙", 4)

AllTabData={
    {PgESP,EB,EI,EL,EUL},
    {PgMov,MB,MI,ML,MUL},
    {PgAim,AB,AI,AL,AUL},
    {PgSet,SB,SI,SL,SUL},
}

local function SwitchTab(idx)
    for _,d in ipairs(AllTabData) do
        d[1].Visible=false
        TweenService:Create(d[2],TweenInfo.new(0.14),{BackgroundTransparency=1}):Play()
        d[3].TextColor3=Config.MenuSub; d[4].TextColor3=Config.MenuSub; d[5].Visible=false
    end
    local d=AllTabData[idx]; d[1].Visible=true
    TweenService:Create(d[2],TweenInfo.new(0.14),{BackgroundTransparency=0.82,BackgroundColor3=Config.MenuAccent}):Play()
    d[3].TextColor3=Config.MenuText; d[4].TextColor3=Config.MenuText; d[5].Visible=true
end

EB.BackgroundTransparency=0.82; EB.BackgroundColor3=Config.MenuAccent
EI.TextColor3=Config.MenuText; EL.TextColor3=Config.MenuText; EUL.Visible=true

EB.MouseButton1Click:Connect(function() SwitchTab(1) end)
MB.MouseButton1Click:Connect(function() SwitchTab(2) end)
AB.MouseButton1Click:Connect(function() SwitchTab(3) end)
SB.MouseButton1Click:Connect(function() SwitchTab(4) end)

-- ══════════════════════════════════════════
-- UI BUILDERS
-- ══════════════════════════════════════════
local function Sec(pg,txt)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,28)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,6)
    local Pip=Instance.new("Frame",F); Pip.BackgroundColor3=Config.MenuAccent; Pip.BorderSizePixel=0
    Pip.Position=UDim2.new(0,0,0.15,0); Pip.Size=UDim2.new(0,3,0.7,0)
    Instance.new("UICorner",Pip).CornerRadius=UDim.new(1,0)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,12,0,0)
    L.Size=UDim2.new(1,-12,1,0); L.Font=Enum.Font.GothamBold; L.Text=txt
    L.TextColor3=Config.MenuText; L.TextSize=11; L.TextXAlignment=Enum.TextXAlignment.Left
    return F
end

local function Tog(pg,txt,def,cb)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,40)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,13,0,0)
    L.Size=UDim2.new(1,-68,1,0); L.Font=Enum.Font.Gotham; L.Text=txt; L.TextColor3=Config.MenuText; L.TextSize=12
    L.TextXAlignment=Enum.TextXAlignment.Left
    local Track=Instance.new("Frame",F); Track.BorderSizePixel=0
    Track.BackgroundColor3=def and Config.MenuAccent or Color3.fromRGB(38,34,18)
    Track.Position=UDim2.new(1,-54,0.5,-10); Track.Size=UDim2.new(0,42,0,20)
    Instance.new("UICorner",Track).CornerRadius=UDim.new(1,0)
    local Knob=Instance.new("Frame",Track); Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.BorderSizePixel=0
    Knob.Position=def and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); Knob.Size=UDim2.new(0,16,0,16)
    Instance.new("UICorner",Knob).CornerRadius=UDim.new(1,0)
    local en=def
    local HB=Instance.new("TextButton",F); HB.BackgroundTransparency=1; HB.Size=UDim2.new(1,0,1,0); HB.Text=""; HB.AutoButtonColor=false
    HB.MouseButton1Click:Connect(function()
        en=not en
        TweenService:Create(Track,TweenInfo.new(0.17),{BackgroundColor3=en and Config.MenuAccent or Color3.fromRGB(38,34,18)}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.17),{Position=en and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
        cb(en)
    end)
    F.MouseEnter:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuHover}):Play() end)
    F.MouseLeave:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuElement}):Play() end)
    return F
end

local function Sli(pg,txt,mn,mx,def,cb,isF)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,56)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,13,0,6)
    L.Size=UDim2.new(0.62,0,0,16); L.Font=Enum.Font.Gotham; L.Text=txt; L.TextColor3=Config.MenuText; L.TextSize=12
    L.TextXAlignment=Enum.TextXAlignment.Left
    local VP=Instance.new("Frame",F); VP.BackgroundColor3=Config.MenuBG2; VP.BorderSizePixel=0
    VP.Position=UDim2.new(1,-60,0,5); VP.Size=UDim2.new(0,46,0,20)
    Instance.new("UICorner",VP).CornerRadius=UDim.new(0,5)
    local VL=Instance.new("TextLabel",VP); VL.BackgroundTransparency=1; VL.Size=UDim2.new(1,0,1,0)
    VL.Font=Enum.Font.GothamBold; VL.Text=isF and string.format("%.2f",def) or tostring(def)
    VL.TextColor3=Config.MenuAccent; VL.TextSize=10
    local Tr=Instance.new("Frame",F); Tr.BackgroundColor3=Config.MenuBG2; Tr.BorderSizePixel=0
    Tr.Position=UDim2.new(0,13,0,36); Tr.Size=UDim2.new(1,-26,0,9)
    Instance.new("UICorner",Tr).CornerRadius=UDim.new(1,0)
    local Fill=Instance.new("Frame",Tr); Fill.BackgroundColor3=Config.MenuAccent; Fill.BorderSizePixel=0
    Fill.Size=UDim2.new(math.clamp((def-mn)/(mx-mn),0,1),0,1,0)
    Instance.new("UICorner",Fill).CornerRadius=UDim.new(1,0)
    local Knob2=Instance.new("Frame",Tr); Knob2.BackgroundColor3=Color3.fromRGB(255,248,180); Knob2.BorderSizePixel=0
    Knob2.AnchorPoint=Vector2.new(0.5,0.5); Knob2.Position=UDim2.new(math.clamp((def-mn)/(mx-mn),0,1),0,0.5,0); Knob2.Size=UDim2.new(0,13,0,13)
    Instance.new("UICorner",Knob2).CornerRadius=UDim.new(1,0)
    local drag=false
    local function upd(ix)
        local fr=math.clamp((ix-Tr.AbsolutePosition.X)/Tr.AbsoluteSize.X,0,1)
        local v=isF and (math.floor((mn+(mx-mn)*fr)*100+0.5)/100) or math.floor(mn+(mx-mn)*fr+0.5)
        TweenService:Create(Fill,TweenInfo.new(0.05),{Size=UDim2.new(fr,0,1,0)}):Play()
        TweenService:Create(Knob2,TweenInfo.new(0.05),{Position=UDim2.new(fr,0,0.5,0)}):Play()
        VL.Text=isF and string.format("%.2f",v) or tostring(v); cb(v)
    end
    Tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; upd(i.Position.X) end end)
    Tr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    local uc=UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end); table.insert(AllConns,uc)
    F.MouseEnter:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuHover}):Play() end)
    F.MouseLeave:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuElement}):Play() end)
    return F
end

local function Drop(pg,txt,opts,def,cb)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,40)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,13,0,0)
    L.Size=UDim2.new(0.5,0,1,0); L.Font=Enum.Font.Gotham; L.Text=txt; L.TextColor3=Config.MenuText; L.TextSize=12
    L.TextXAlignment=Enum.TextXAlignment.Left
    local Btn=Instance.new("TextButton",F); Btn.BackgroundColor3=Config.MenuBG2; Btn.BorderSizePixel=0
    Btn.Position=UDim2.new(0.5,0,0.5,-13); Btn.Size=UDim2.new(0.5,-14,0,26)
    Btn.Font=Enum.Font.GothamSemibold; Btn.Text=def; Btn.TextColor3=Config.MenuAccent; Btn.TextSize=11; Btn.AutoButtonColor=false
    Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,6)
    local idx=1; for i,o in ipairs(opts) do if o==def then idx=i break end end
    Btn.MouseButton1Click:Connect(function() idx=idx%#opts+1; Btn.Text=opts[idx]; cb(opts[idx]) end)
    F.MouseEnter:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuHover}):Play() end)
    F.MouseLeave:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuElement}):Play() end)
    return F
end

local function Bind(pg,txt,def,cb)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,40)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,13,0,0)
    L.Size=UDim2.new(1,-110,1,0); L.Font=Enum.Font.Gotham; L.Text=txt; L.TextColor3=Config.MenuText; L.TextSize=12
    L.TextXAlignment=Enum.TextXAlignment.Left
    local Btn=Instance.new("TextButton",F); Btn.BackgroundColor3=Config.MenuBG2; Btn.BorderSizePixel=0
    Btn.Position=UDim2.new(1,-90,0.5,-13); Btn.Size=UDim2.new(0,76,0,26)
    Btn.Font=Enum.Font.GothamBold; Btn.Text=def.Name; Btn.TextColor3=Config.MenuAccent; Btn.TextSize=11; Btn.AutoButtonColor=false
    Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,6)
    local binding=false
    Btn.MouseButton1Click:Connect(function()
        binding=true; Btn.Text="..."
        TweenService:Create(Btn,TweenInfo.new(0.14),{BackgroundColor3=Config.MenuAccent,TextColor3=Color3.fromRGB(10,10,14)}):Play()
    end)
    local c=UserInputService.InputBegan:Connect(function(i)
        if binding and i.UserInputType==Enum.UserInputType.Keyboard then
            Btn.Text=i.KeyCode.Name
            TweenService:Create(Btn,TweenInfo.new(0.14),{BackgroundColor3=Config.MenuBG2,TextColor3=Config.MenuAccent}):Play()
            binding=false; cb(i.KeyCode)
        end
    end); table.insert(AllConns,c)
    F.MouseEnter:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuHover}):Play() end)
    F.MouseLeave:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuElement}):Play() end)
    return F
end

-- ══════════════════════════════════════════
-- FULL HSV COLOR PICKER
-- ══════════════════════════════════════════
local CPWin=Instance.new("Frame",ScreenGui)
CPWin.BackgroundColor3=Color3.fromRGB(16,16,18); CPWin.BorderSizePixel=0
CPWin.Size=UDim2.new(0,280,0,330); CPWin.Position=UDim2.new(0.5,-140,0.5,-165)
CPWin.Visible=false; CPWin.ZIndex=200
Instance.new("UICorner",CPWin).CornerRadius=UDim.new(0,12)
local CPStroke=Instance.new("UIStroke",CPWin); CPStroke.Color=Config.MenuAccent; CPStroke.Thickness=2

local CPTitleL=Instance.new("TextLabel",CPWin)
CPTitleL.BackgroundTransparency=1; CPTitleL.Position=UDim2.new(0,14,0,8); CPTitleL.Size=UDim2.new(1,-50,0,22)
CPTitleL.Font=Enum.Font.GothamBold; CPTitleL.Text="Color Picker"; CPTitleL.TextColor3=Config.MenuText
CPTitleL.TextSize=14; CPTitleL.TextXAlignment=Enum.TextXAlignment.Left; CPTitleL.ZIndex=201

local CPX=Instance.new("TextButton",CPWin)
CPX.BackgroundColor3=Color3.fromRGB(200,50,50); CPX.BorderSizePixel=0
CPX.Position=UDim2.new(1,-34,0,8); CPX.Size=UDim2.new(0,22,0,22)
CPX.Font=Enum.Font.GothamBold; CPX.Text="×"; CPX.TextColor3=Color3.fromRGB(255,255,255)
CPX.TextSize=16; CPX.AutoButtonColor=false; CPX.ZIndex=201
Instance.new("UICorner",CPX).CornerRadius=UDim.new(0,6)

local SVFrame=Instance.new("Frame",CPWin)
SVFrame.Position=UDim2.new(0,14,0,38); SVFrame.Size=UDim2.new(1,-28,0,160); SVFrame.ZIndex=201
local SVImg=Instance.new("ImageLabel",SVFrame)
SVImg.Size=UDim2.new(1,0,1,0); SVImg.BackgroundColor3=Config.MenuAccent
SVImg.Image="rbxassetid://4155801252"; SVImg.ZIndex=202
Instance.new("UICorner",SVImg).CornerRadius=UDim.new(0,6)
local SVCur=Instance.new("Frame",SVFrame)
SVCur.Size=UDim2.new(0,12,0,12); SVCur.BackgroundColor3=Color3.fromRGB(255,255,255)
SVCur.BorderSizePixel=0; SVCur.ZIndex=203; SVCur.AnchorPoint=Vector2.new(0.5,0.5); SVCur.Position=UDim2.new(1,0,0,0)
Instance.new("UICorner",SVCur).CornerRadius=UDim.new(1,0)
Instance.new("UIStroke",SVCur).Color=Color3.fromRGB(0,0,0)

local HueFrame=Instance.new("Frame",CPWin)
HueFrame.Position=UDim2.new(0,14,0,208); HueFrame.Size=UDim2.new(1,-28,0,20); HueFrame.ZIndex=201
local HueImg=Instance.new("ImageLabel",HueFrame)
HueImg.Size=UDim2.new(1,0,1,0); HueImg.BackgroundTransparency=1; HueImg.Image="rbxassetid://698051305"; HueImg.ZIndex=202
Instance.new("UICorner",HueImg).CornerRadius=UDim.new(0,4)
local HueCur=Instance.new("Frame",HueFrame)
HueCur.Size=UDim2.new(0,6,1,4); HueCur.BackgroundColor3=Color3.fromRGB(255,255,255); HueCur.BorderSizePixel=0
HueCur.AnchorPoint=Vector2.new(0.5,0.5); HueCur.Position=UDim2.new(0,0,0.5,0); HueCur.ZIndex=203
Instance.new("UICorner",HueCur).CornerRadius=UDim.new(0,3)

local PrevRow=Instance.new("Frame",CPWin)
PrevRow.BackgroundTransparency=1; PrevRow.Position=UDim2.new(0,14,0,240); PrevRow.Size=UDim2.new(1,-28,0,32); PrevRow.ZIndex=201
local SwatchF=Instance.new("Frame",PrevRow)
SwatchF.Size=UDim2.new(0,48,1,0); SwatchF.BackgroundColor3=Config.MenuAccent; SwatchF.BorderSizePixel=0; SwatchF.ZIndex=202
Instance.new("UICorner",SwatchF).CornerRadius=UDim.new(0,6)
local HexLbl=Instance.new("TextLabel",PrevRow)
HexLbl.BackgroundTransparency=1; HexLbl.Position=UDim2.new(0,56,0,0); HexLbl.Size=UDim2.new(1,-56,1,0)
HexLbl.Font=Enum.Font.GothamBold; HexLbl.Text="#FFD21E"; HexLbl.TextColor3=Config.MenuAccent
HexLbl.TextSize=13; HexLbl.TextXAlignment=Enum.TextXAlignment.Left; HexLbl.ZIndex=202

local ApplyBtn=Instance.new("TextButton",CPWin)
ApplyBtn.Position=UDim2.new(0,14,0,284); ApplyBtn.Size=UDim2.new(1,-28,0,30)
ApplyBtn.BackgroundColor3=Config.MenuAccent; ApplyBtn.BorderSizePixel=0
ApplyBtn.Font=Enum.Font.GothamBold; ApplyBtn.Text="Apply"; ApplyBtn.TextColor3=Color3.fromRGB(10,10,14)
ApplyBtn.TextSize=13; ApplyBtn.AutoButtonColor=false; ApplyBtn.ZIndex=201
Instance.new("UICorner",ApplyBtn).CornerRadius=UDim.new(0,6)

local curH,curS,curV=0.135,1,1
local cpCB=nil

local function Hex(c)
    return string.format("#%02X%02X%02X",math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255))
end
local function RefCP()
    SVImg.BackgroundColor3=Color3.fromHSV(curH,1,1)
    local fin=Color3.fromHSV(curH,curS,curV)
    SwatchF.BackgroundColor3=fin; HexLbl.Text=Hex(fin)
    HueCur.Position=UDim2.new(curH,0,0.5,0); SVCur.Position=UDim2.new(curS,0,1-curV,0)
end

local dSV,dHue=false,false
SVImg.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dSV=true
        curS=math.clamp((i.Position.X-SVImg.AbsolutePosition.X)/SVImg.AbsoluteSize.X,0,1)
        curV=1-math.clamp((i.Position.Y-SVImg.AbsolutePosition.Y)/SVImg.AbsoluteSize.Y,0,1); RefCP()
    end
end)
SVImg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dSV=false end end)
HueImg.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dHue=true; curH=math.clamp((i.Position.X-HueImg.AbsolutePosition.X)/HueImg.AbsoluteSize.X,0,1); RefCP()
    end
end)
HueImg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dHue=false end end)
local cpMv=UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
    if dSV then
        curS=math.clamp((i.Position.X-SVImg.AbsolutePosition.X)/SVImg.AbsoluteSize.X,0,1)
        curV=1-math.clamp((i.Position.Y-SVImg.AbsolutePosition.Y)/SVImg.AbsoluteSize.Y,0,1); RefCP()
    elseif dHue then
        curH=math.clamp((i.Position.X-HueImg.AbsolutePosition.X)/HueImg.AbsoluteSize.X,0,1); RefCP()
    end
end); table.insert(AllConns,cpMv)
ApplyBtn.MouseButton1Click:Connect(function()
    if cpCB then cpCB(Color3.fromHSV(curH,curS,curV)) end; CPWin.Visible=false
end)
CPX.MouseButton1Click:Connect(function() CPWin.Visible=false end)
local function OpenCP(startCol,cb)
    local h,s,v=Color3.toHSV(startCol); curH=h; curS=s; curV=v; cpCB=cb; RefCP(); CPWin.Visible=true
end

local function ColorRow(pg,lbl,cfgKey)
    local F=Instance.new("Frame",pg); F.BackgroundColor3=Config.MenuElement; F.BorderSizePixel=0; F.Size=UDim2.new(1,0,0,40)
    Instance.new("UICorner",F).CornerRadius=UDim.new(0,8)
    local L=Instance.new("TextLabel",F); L.BackgroundTransparency=1; L.Position=UDim2.new(0,13,0,0)
    L.Size=UDim2.new(1,-80,1,0); L.Font=Enum.Font.Gotham; L.Text=lbl; L.TextColor3=Config.MenuText; L.TextSize=12
    L.TextXAlignment=Enum.TextXAlignment.Left
    local Sw=Instance.new("TextButton",F); Sw.BorderSizePixel=0
    Sw.Position=UDim2.new(1,-58,0.5,-13); Sw.Size=UDim2.new(0,44,0,26)
    Sw.BackgroundColor3=Config[cfgKey]; Sw.Text=""; Sw.AutoButtonColor=false
    Instance.new("UICorner",Sw).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",Sw).Color=Color3.fromRGB(80,70,20)
    Sw.MouseButton1Click:Connect(function()
        OpenCP(Config[cfgKey],function(c) Config[cfgKey]=c; Sw.BackgroundColor3=c end)
    end)
    F.MouseEnter:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuHover}):Play() end)
    F.MouseLeave:Connect(function() TweenService:Create(F,TweenInfo.new(0.13),{BackgroundColor3=Config.MenuElement}):Play() end)
    return F
end

-- ══════════════════════════════════════════
-- PAGE CONTENT
-- ══════════════════════════════════════════
-- ESP
Sec(PgESP,"⚙  GENERAL")
Tog(PgESP,"Team Check",      Config.TeamCheck,    function(v) Config.TeamCheck=v end)
Tog(PgESP,"Rainbow Mode",    Config.RainbowMode,  function(v) Config.RainbowMode=v end)
Sli(PgESP,"Max Distance",100,2000,Config.MaxDistance, function(v) Config.MaxDistance=v end,false)
Sli(PgESP,"Rainbow Speed", 1,  20,Config.RainbowSpeed,function(v) Config.RainbowSpeed=v end,false)

Sec(PgESP,"🦴  BONE ESP")
Tog(PgESP,"Bone ESP",        Config.BoneESP,      function(v) Config.BoneESP=v end)
Sli(PgESP,"Bone Thickness",1,5,Config.BoneThickness,function(v) Config.BoneThickness=v end,false)

Sec(PgESP,"📦  BOX ESP")
Tog(PgESP,"Box ESP",         Config.BoxESP,       function(v) Config.BoxESP=v end)
Sli(PgESP,"Box Thickness",1,5,Config.BoxThickness,function(v) Config.BoxThickness=v end,false)

Sec(PgESP,"➡  TRACER ESP")
Tog(PgESP,"Tracer ESP",      Config.TracerESP,    function(v) Config.TracerESP=v end)
Drop(PgESP,"Origin",{"Bottom","Center","Top"},Config.TracerOrigin,function(v) Config.TracerOrigin=v end)
Sli(PgESP,"Tracer Thickness",1,5,Config.TracerThickness,function(v) Config.TracerThickness=v end,false)

Sec(PgESP,"🏷  INFO ESP")
Tog(PgESP,"Name ESP",        Config.NameESP,      function(v) Config.NameESP=v end)
Tog(PgESP,"Distance ESP",    Config.DistanceESP,  function(v) Config.DistanceESP=v end)
Tog(PgESP,"Health Bar",      Config.HealthBarESP, function(v) Config.HealthBarESP=v end)

-- Movement
Sec(PgMov,"🚫  NOCLIP")
Tog(PgMov,"Noclip",Config.NoclipEnabled,function(v) Config.NoclipEnabled=v; if v then StartNoclip() else StopNoclip() end end)

Sec(PgMov,"✈  FLY")
Tog(PgMov,"Fly",Config.FlyEnabled,function(v) Config.FlyEnabled=v; if v then StartFly() else StopFly() end end)
Bind(PgMov,"Toggle Key",Config.FlyKey,function(k) Config.FlyKey=k end)
Sli(PgMov,"Fly Speed",10,300,Config.FlySpeed,function(v) Config.FlySpeed=v end,false)
Sli(PgMov,"Boost Speed",20,600,Config.FlyBoost,function(v) Config.FlyBoost=v end,false)

local HintF=Instance.new("Frame",PgMov); HintF.BackgroundColor3=Config.MenuElement; HintF.BorderSizePixel=0; HintF.Size=UDim2.new(1,0,0,90)
Instance.new("UICorner",HintF).CornerRadius=UDim.new(0,8)
local HintL=Instance.new("TextLabel",HintF); HintL.BackgroundTransparency=1
HintL.Position=UDim2.new(0,12,0,6); HintL.Size=UDim2.new(1,-14,1,-8)
HintL.Font=Enum.Font.Gotham; HintL.TextSize=11; HintL.TextColor3=Config.MenuSub
HintL.TextXAlignment=Enum.TextXAlignment.Left; HintL.TextYAlignment=Enum.TextYAlignment.Top
HintL.TextWrapped=true
HintL.Text="Controls while flying:\nW/A/S/D  →  move relative to camera\nSPACE  →  ascend    CTRL  →  descend\nL-SHIFT  →  boost speed"

-- Aimbot
Sec(PgAim,"🎯  AIMBOT")
Tog(PgAim,"Aimbot Enabled",Config.AimbotEnabled,function(v) Config.AimbotEnabled=v; if v then CreateFOV() else RemoveFOV() end end)
Bind(PgAim,"Aimbot Key",Config.AimbotKey,function(k) Config.AimbotKey=k end)
Tog(PgAim,"Show FOV Circle",Config.ShowFOV,function(v) Config.ShowFOV=v; if FOVCircle then FOVCircle.Visible=v end end)
Sli(PgAim,"FOV Size",10,500,Config.AimbotFOV,function(v) Config.AimbotFOV=v; if FOVCircle then FOVCircle.Radius=v end end,false)
Sli(PgAim,"Smoothness",1,20,Config.AimbotSmoothness,function(v) Config.AimbotSmoothness=v end,false)

Sec(PgAim,"🔮  PREDICTION")
Tog(PgAim,"Prediction",Config.PredictionEnabled,function(v) Config.PredictionEnabled=v end)
Sli(PgAim,"Prediction Amount",0.05,0.5,Config.PredictionAmount,function(v) Config.PredictionAmount=v end,true)

Sec(PgAim,"🎲  TARGET")
Drop(PgAim,"Aim Part",{"Head","UpperTorso","LowerTorso","HumanoidRootPart"},Config.AimbotPart,function(v) Config.AimbotPart=v end)
Tog(PgAim,"Team Check",Config.TeamCheckAimbot,function(v) Config.TeamCheckAimbot=v end)
Tog(PgAim,"Visible Check",Config.VisibleCheck,function(v) Config.VisibleCheck=v end)
Tog(PgAim,"Wall Check",Config.WallCheck,function(v) Config.WallCheck=v end)

-- Settings
Sec(PgSet,"🎨  ESP COLORS")
ColorRow(PgSet,"Bone Color",    "BoneColor")
ColorRow(PgSet,"Box Color",     "BoxColor")
ColorRow(PgSet,"Tracer Color",  "TracerColor")
ColorRow(PgSet,"Name Color",    "NameColor")
ColorRow(PgSet,"Distance Color","DistanceColor")
ColorRow(PgSet,"Health Bar",    "HealthBarColor")

Sec(PgSet,"🎯  AIMBOT COLORS")
ColorRow(PgSet,"FOV Circle","FOVColor")

Sec(PgSet,"🖥  MENU COLORS")
ColorRow(PgSet,"Background", "MenuBG")
ColorRow(PgSet,"Header",     "MenuHeader")
ColorRow(PgSet,"Accent",     "MenuAccent")
ColorRow(PgSet,"Elements",   "MenuElement")
ColorRow(PgSet,"Text",       "MenuText")

-- ══════════════════════════════════════════
-- DRAWING POOL
-- ══════════════════════════════════════════
local function GetLine()
    if #LinePool>0 then return table.remove(LinePool) end
    local l=Drawing.new("Line"); l.Thickness=1; l.Transparency=1; return l
end
local function FreeLine(l) l.Visible=false; table.insert(LinePool,l) end
local function GetTxt()
    if #TextPool>0 then return table.remove(TextPool) end
    local t=Drawing.new("Text"); t.Center=true; t.Outline=true; t.Size=14; t.Font=2; return t
end
local function FreeTxt(t) t.Visible=false; table.insert(TextPool,t) end

local function CharType(c)
    if c:FindFirstChild("UpperTorso") then return "R15"
    elseif c:FindFirstChild("Torso") then return "R6" end
end

-- ══════════════════════════════════════════
-- ESP  CREATE / REMOVE
-- ══════════════════════════════════════════
local function CreateESP(player)
    if player==LocalPlayer then return end
    local char=player.Character; if not char then return end
    local ct=CharType(char); if not ct then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local bones=ct=="R15" and R15Bones or R6Bones

    local d={
        Player=player,Character=char,Humanoid=hum,Type=ct,
        BoneLines={},BoxLines={},TracerLine=GetLine(),
        NameText=GetTxt(),DistText=GetTxt(),
        HpBg=GetLine(),HpFill=GetLine(),
        Alive=true
    }
    for _,c in ipairs(bones) do
        local b1=char:FindFirstChild(c[1]); local b2=char:FindFirstChild(c[2])
        if b1 and b2 then table.insert(d.BoneLines,{L=GetLine(),B1=b1,B2=b2}) end
    end
    for i=1,4 do table.insert(d.BoxLines,GetLine()) end

    local hc=hum:GetPropertyChangedSignal("Health"):Connect(function()
        if hum.Health<=0 then d.Alive=false; task.wait(0.1); RemoveESP(player) end
    end); table.insert(AllConns,hc); d.HealthConn=hc

    local ac=char.AncestryChanged:Connect(function(_,p)
        if not p then d.Alive=false; RemoveESP(player) end
    end); table.insert(AllConns,ac); d.AncConn=ac

    ESPCache[player]=d
end

function RemoveESP(player)
    local d=ESPCache[player]; if not d then return end
    pcall(function() if d.HealthConn then d.HealthConn:Disconnect() end end)
    pcall(function() if d.AncConn    then d.AncConn:Disconnect()    end end)
    for _,bd in ipairs(d.BoneLines) do FreeLine(bd.L) end
    for _,bl in ipairs(d.BoxLines)  do FreeLine(bl) end
    FreeLine(d.TracerLine); FreeTxt(d.NameText); FreeTxt(d.DistText)
    FreeLine(d.HpBg); FreeLine(d.HpFill)
    ESPCache[player]=nil
end

-- ══════════════════════════════════════════
-- ESP  UPDATE
-- ══════════════════════════════════════════
local rbHue=0
local function RbCol()
    rbHue=(rbHue+Config.RainbowSpeed*0.001)%1
    return Color3.fromHSV(rbHue,1,1)
end

local function UpdateESP()
    local rb=Config.RainbowMode and RbCol()
    local bCol=rb or Config.BoneColor
    local xCol=rb or Config.BoxColor
    local tCol=rb or Config.TracerColor

    local myChar=LocalPlayer.Character
    local myRoot=myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))

    for player,d in pairs(ESPCache) do
        if not d.Alive or not player.Character or player.Character~=d.Character
        or not d.Humanoid or d.Humanoid.Health<=0 or not d.Character.Parent then
            RemoveESP(player)
            if player.Character then
                local h=player.Character:FindFirstChildOfClass("Humanoid")
                if h and h.Health>0 then CreateESP(player) end
            end
            continue
        end

        local function HideAll()
            for _,bd in ipairs(d.BoneLines) do bd.L.Visible=false end
            for _,bl in ipairs(d.BoxLines)  do bl.Visible=false end
            d.TracerLine.Visible=false; d.NameText.Visible=false
            d.DistText.Visible=false; d.HpBg.Visible=false; d.HpFill.Visible=false
        end

        if Config.TeamCheck and player.Team==LocalPlayer.Team then HideAll(); continue end

        local root=d.Character:FindFirstChild("HumanoidRootPart") or d.Character:FindFirstChild("Torso")
        local head=d.Character:FindFirstChild("Head")
        if not root or not root.Parent then RemoveESP(player); continue end

        local dist=myRoot and (root.Position-myRoot.Position).Magnitude or 0
        if dist>Config.MaxDistance then HideAll(); continue end

        -- BONES
        if Config.BoneESP then
            for _,bd in ipairs(d.BoneLines) do
                local b1,b2=bd.B1,bd.B2
                if b1 and b2 and b1.Parent==d.Character and b2.Parent==d.Character then
                    local p1,on1=Camera:WorldToViewportPoint(b1.Position)
                    local p2,on2=Camera:WorldToViewportPoint(b2.Position)
                    if on1 and on2 and p1.Z>0 then
                        bd.L.From=Vector2.new(p1.X,p1.Y); bd.L.To=Vector2.new(p2.X,p2.Y)
                        bd.L.Color=bCol; bd.L.Thickness=Config.BoneThickness; bd.L.Visible=true
                    else bd.L.Visible=false end
                else bd.L.Visible=false end
            end
        else for _,bd in ipairs(d.BoneLines) do bd.L.Visible=false end end

        -- BOX
        if Config.BoxESP and head and root then
            local tp,tonS=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.7,0))
            local bp,bonS=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,2.8,0))
            if tonS and bonS and tp.Z>0 then
                local hh=math.abs(tp.Y-bp.Y); local hw=hh*0.55
                local cx=(tp.X+bp.X)/2
                local ty2=math.min(tp.Y,bp.Y); local by2=math.max(tp.Y,bp.Y)
                local lx=cx-hw; local rx=cx+hw
                local corners={
                    {Vector2.new(lx,ty2),Vector2.new(rx,ty2)},
                    {Vector2.new(lx,by2),Vector2.new(rx,by2)},
                    {Vector2.new(lx,ty2),Vector2.new(lx,by2)},
                    {Vector2.new(rx,ty2),Vector2.new(rx,by2)},
                }
                for i,bl in ipairs(d.BoxLines) do
                    bl.From=corners[i][1]; bl.To=corners[i][2]
                    bl.Color=xCol; bl.Thickness=Config.BoxThickness; bl.Visible=true
                end
            else for _,bl in ipairs(d.BoxLines) do bl.Visible=false end end
        else for _,bl in ipairs(d.BoxLines) do bl.Visible=false end end

        -- TRACER
        if Config.TracerESP and root then
            local rsp,ron=Camera:WorldToViewportPoint(root.Position)
            if ron and rsp.Z>0 then
                local vp=Camera.ViewportSize
                local oy=Config.TracerOrigin=="Bottom" and vp.Y or Config.TracerOrigin=="Top" and 0 or vp.Y/2
                d.TracerLine.From=Vector2.new(vp.X/2,oy); d.TracerLine.To=Vector2.new(rsp.X,rsp.Y)
                d.TracerLine.Color=tCol; d.TracerLine.Thickness=Config.TracerThickness; d.TracerLine.Visible=true
            else d.TracerLine.Visible=false end
        else d.TracerLine.Visible=false end

        -- NAME + DISTANCE
        if head and head.Parent then
            local nsp,non=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,1.4,0))
            if non and nsp.Z>0 then
                if Config.NameESP then
                    d.NameText.Position=Vector2.new(nsp.X,nsp.Y)
                    d.NameText.Text=player.DisplayName
                    d.NameText.Color=Config.NameColor; d.NameText.Visible=true
                else d.NameText.Visible=false end
                if Config.DistanceESP then
                    d.DistText.Position=Vector2.new(nsp.X,nsp.Y+(Config.NameESP and 16 or 0))
                    d.DistText.Text=math.floor(dist).."m"
                    d.DistText.Color=Config.DistanceColor; d.DistText.Visible=true
                else d.DistText.Visible=false end
            else d.NameText.Visible=false; d.DistText.Visible=false end
        end

        -- HEALTH BAR  (synced to box top/bottom)
        if Config.HealthBarESP and head and head.Parent and root and root.Parent then
            local hpPct=math.clamp(d.Humanoid.Health/math.max(d.Humanoid.MaxHealth,1),0,1)
            -- use same anchor points as box so bar stays flush
            local tsp,ton=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.7,0))
            local bsp,bon=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,2.8,0))
            if ton and bon and tsp.Z>0 then
                local cx=(tsp.X+bsp.X)/2
                local topY=math.min(tsp.Y,bsp.Y); local botY=math.max(tsp.Y,bsp.Y)
                local bh=botY-topY
                -- bar sits just left of the box
                local hh=bh*0.55  -- half-width same as box
                local bx=(cx - hh) - 5
                d.HpBg.From=Vector2.new(bx,topY); d.HpBg.To=Vector2.new(bx,botY)
                d.HpBg.Color=Color3.fromRGB(0,0,0); d.HpBg.Thickness=5; d.HpBg.Visible=true
                local fillTop=topY+bh*(1-hpPct)
                d.HpFill.From=Vector2.new(bx,fillTop); d.HpFill.To=Vector2.new(bx,botY)
                d.HpFill.Color=Color3.fromHSV(hpPct*0.33,1,1); d.HpFill.Thickness=3; d.HpFill.Visible=true
            else d.HpBg.Visible=false; d.HpFill.Visible=false end
        else d.HpBg.Visible=false; d.HpFill.Visible=false end
    end
end

-- ══════════════════════════════════════════
-- FOV + AIMBOT
-- ══════════════════════════════════════════
function CreateFOV()
    if FOVCircle then return end
    FOVCircle=Drawing.new("Circle")
    FOVCircle.Thickness=2; FOVCircle.NumSides=72; FOVCircle.Radius=Config.AimbotFOV
    FOVCircle.Color=Config.FOVColor; FOVCircle.Filled=false; FOVCircle.Transparency=1
    FOVCircle.Visible=Config.ShowFOV and Config.AimbotEnabled
end
function RemoveFOV()
    if FOVCircle then FOVCircle:Remove(); FOVCircle=nil end
end

local function IsVisible(part)
    if not Config.VisibleCheck then return true end
    local char=LocalPlayer.Character; if not char then return false end
    local head=char:FindFirstChild("Head"); if not head then return false end
    local ray=Ray.new(head.Position,(part.Position-head.Position).Unit*500)
    local hit=workspace:FindPartOnRayWithIgnoreList(ray,{char,Camera})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function GetClosest()
    local best,bd=nil,Config.AimbotFOV
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                if Config.TeamCheckAimbot and p.Team==LocalPlayer.Team then continue end
                local part=p.Character:FindFirstChild(Config.AimbotPart) or p.Character:FindFirstChild("Head")
                if part then
                    if Config.WallCheck and not IsVisible(part) then continue end
                    local sp,onS=Camera:WorldToViewportPoint(part.Position)
                    if onS and sp.Z>0 then
                        local mouse=UserInputService:GetMouseLocation()
                        local dist=(Vector2.new(sp.X,sp.Y)-mouse).Magnitude
                        if dist<bd then bd=dist; best=p end
                    end
                end
            end
        end
    end
    return best
end

local function UpdateAimbot()
    if not Config.AimbotEnabled then return end
    if FOVCircle then
        FOVCircle.Position=UserInputService:GetMouseLocation()
        FOVCircle.Radius=Config.AimbotFOV; FOVCircle.Color=Config.FOVColor; FOVCircle.Visible=Config.ShowFOV
    end
    if not IsAimHeld then return end
    local target=GetClosest()
    if target and target.Character then
        local part=target.Character:FindFirstChild(Config.AimbotPart) or target.Character:FindFirstChild("Head")
        if part then
            local pos=part.Position
            if Config.PredictionEnabled then
                local ok2,vel=pcall(function() return part.AssemblyLinearVelocity end)
                if ok2 then pos=pos+vel*Config.PredictionAmount end
            end
            local sp=Camera:WorldToViewportPoint(pos)
            local mouse=UserInputService:GetMouseLocation()
            mousemoverel((sp.X-mouse.X)/Config.AimbotSmoothness,(sp.Y-mouse.Y)/Config.AimbotSmoothness)
        end
    end
end

local kd=UserInputService.InputBegan:Connect(function(i,gp) if gp then return end if i.KeyCode==Config.AimbotKey then IsAimHeld=true end end); table.insert(AllConns,kd)
local ku=UserInputService.InputEnded:Connect(function(i) if i.KeyCode==Config.AimbotKey then IsAimHeld=false end end); table.insert(AllConns,ku)

-- ══════════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════════
local NoclipConn=nil
function StartNoclip()
    if NoclipConn then return end
    NoclipConn=RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then StopNoclip(); return end
        local char=LocalPlayer.Character; if not char then return end
        for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end); table.insert(AllConns,NoclipConn)
end
function StopNoclip()
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn=nil end
    local char=LocalPlayer.Character; if not char then return end
    for _,p in pairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=true end end
end

-- ══════════════════════════════════════════
-- FLY
-- ══════════════════════════════════════════
local FlyConn=nil; local FlyBV=nil; local FlyBG=nil
function StartFly()
    if FlyConn then return end
    local char=LocalPlayer.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.PlatformStand=true
    FlyBV=Instance.new("BodyVelocity",hrp); FlyBV.Velocity=Vector3.new(0,0,0); FlyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
    FlyBG=Instance.new("BodyGyro",hrp); FlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); FlyBG.D=100; FlyBG.P=1e4
    FlyConn=RunService.RenderStepped:Connect(function()
        if not Config.FlyEnabled then StopFly(); return end
        local char2=LocalPlayer.Character; if not char2 then return end
        local hrp2=char2:FindFirstChild("HumanoidRootPart"); if not hrp2 then return end
        local boost=UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        local spd=boost and Config.FlyBoost or Config.FlySpeed
        local dir=Vector3.new(0,0,0); local cf=Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then dir=dir.Unit end
        if FlyBV then FlyBV.Velocity=dir*spd end
        if FlyBG then FlyBG.CFrame=cf end
    end); table.insert(AllConns,FlyConn)
end
function StopFly()
    if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
    if FlyBV then FlyBV:Destroy(); FlyBV=nil end
    if FlyBG then FlyBG:Destroy(); FlyBG=nil end
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
end

local flyK=UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Config.FlyKey then Config.FlyEnabled=not Config.FlyEnabled; if Config.FlyEnabled then StartFly() else StopFly() end end
end); table.insert(AllConns,flyK)

-- ══════════════════════════════════════════
-- PLAYER MANAGEMENT
-- ══════════════════════════════════════════
local function OnPlayerAdded(p)
    if p==LocalPlayer then return end
    if p.Character then CreateESP(p) end
    local ca=p.CharacterAdded:Connect(function() task.wait(0.05); RemoveESP(p); CreateESP(p) end); table.insert(AllConns,ca)
    local cr=p.CharacterRemoving:Connect(function() RemoveESP(p) end); table.insert(AllConns,cr)
end
for _,p in ipairs(Players:GetPlayers()) do OnPlayerAdded(p) end
local pA=Players.PlayerAdded:Connect(OnPlayerAdded); table.insert(AllConns,pA)
local pR=Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end); table.insert(AllConns,pR)

-- ══════════════════════════════════════════
-- RENDER LOOP
-- ══════════════════════════════════════════
local rC=RunService.RenderStepped:Connect(function() UpdateESP(); UpdateAimbot() end); table.insert(AllConns,rC)

-- ══════════════════════════════════════════
-- DRAGGABLE
-- ══════════════════════════════════════════
local dragWin=false; local dragStart,winStart2
Hdr.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragWin=true; dragStart=i.Position; winStart2=Win.Position end
end)
Hdr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragWin=false end end)
local dC=UserInputService.InputChanged:Connect(function(i)
    if dragWin and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        Win.Position=UDim2.new(winStart2.X.Scale,winStart2.X.Offset+d.X,winStart2.Y.Scale,winStart2.Y.Offset+d.Y)
    end
end); table.insert(AllConns,dC)

-- ══════════════════════════════════════════
-- TOGGLE  [K]
-- ══════════════════════════════════════════
local function HideWin()
    TweenService:Create(Win,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.In),
        {Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
    TweenService:Create(Overlay,TweenInfo.new(0.28),{BackgroundTransparency=1}):Play()
    task.wait(0.3); Win.Visible=false; Overlay.Visible=false
end
local function ShowWin()
    Win.Visible=true; Overlay.Visible=true
    Win.Size=UDim2.new(0,0,0,0); Win.Position=UDim2.new(0.5,0,0.5,0)
    TweenService:Create(Win,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,620,0,550),Position=UDim2.new(0.5,-310,0.5,-275)}):Play()
    TweenService:Create(Overlay,TweenInfo.new(0.28),{BackgroundTransparency=0.48}):Play()
end
CloseBtn.MouseButton1Click:Connect(HideWin)
local tK=UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end; if i.KeyCode==Enum.KeyCode.K then if Win.Visible then HideWin() else ShowWin() end end
end); table.insert(AllConns,tK)

-- ══════════════════════════════════════════
-- DONE
-- ══════════════════════════════════════════
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="RIVALS V1",Text="✓ Loaded  |  [K] to toggle",Duration=5
    })
end)
print("Rivals V1 B0004 — [K] to toggle GUI")
