local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

if not Drawing or not Drawing.new then
    warn("Drawing not supported")
    return
end

getgenv().HitboxExpander = {
    Enabled = true,
    Size = 8,
    Transparency = 0.5,
    TeamCheck = true,
    TargetPart = "HumanoidRootPart"
}

getgenv().GroundCFrameSpeed = {
    Enabled = true,
    Speed = 50
}

getgenv().InfiniteJump = {
    Enabled = true
}

getgenv().HybridESP = {
    Enabled = true,
    TeamCheck = false,
    UseNPCs = true,

    Boxes = true,
    Tracers = true,
    Chams = true,

    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),

    PlayerChamColor = Color3.fromRGB(120, 200, 255),
    NPCChamColor = Color3.fromRGB(255, 190, 120),
    ChamOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamFillTransparency = 0.6,
    ChamOutlineTransparency = 0.2,

    MaxDistance = 2500,
    Thickness = 1.5
}

local HitboxConfig = getgenv().HitboxExpander
local SpeedConfig = getgenv().GroundCFrameSpeed
local JumpConfig = getgenv().InfiniteJump
local ESPConfig = getgenv().HybridESP

local Character, Humanoid, Root
local DrawCache = {}
local ChamCache = {}
local DiscordInvite = ""

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "手枪竞技场翻译😔😔😔",
    Footer = "version: example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "home"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Info = Window:AddTab("Info", "info"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local MainGroup = Tabs.Main:AddLeftGroupbox("范围")

MainGroup:AddToggle("HitboxEnabled", {
    Text = "Enable 范围",
    Default = HitboxConfig.Enabled,
    Callback = function(Value)
        HitboxConfig.Enabled = Value
    end,
})

MainGroup:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = HitboxConfig.Size,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        HitboxConfig.Size = Value
    end,
})

MainGroup:AddToggle("HitboxTeamCheck", {
    Text = "团队检查",
    Default = HitboxConfig.TeamCheck,
    Callback = function(Value)
        HitboxConfig.TeamCheck = Value
    end,
})

local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("移动速度")

VisualsGroup:AddToggle("GroundSpeedEnabled", {
    Text = "Enable 移动速度",
    Default = SpeedConfig.Enabled,
    Callback = function(Value)
        SpeedConfig.Enabled = Value
    end,
})

VisualsGroup:AddSlider("GroundSpeedValue", {
    Text = "移动速度",
    Default = SpeedConfig.Speed,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        SpeedConfig.Speed = Value
    end,
})

VisualsGroup:AddToggle("InfiniteJumpEnabled", {
    Text = "无限跳",
    Default = JumpConfig.Enabled,
    Callback = function(Value)
        JumpConfig.Enabled = Value
    end,
})

local ESPGroup = Tabs.Visuals:AddRightGroupbox("ESP")

ESPGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = ESPConfig.Enabled,
    Callback = function(Value)
        ESPConfig.Enabled = Value
        if not Value then
            for _, entry in pairs(DrawCache) do
                entry.Box.Visible = false
                entry.Tracer.Visible = false
            end
            for _, hl in pairs(ChamCache) do
                hl:Destroy()
            end
            table.clear(ChamCache)
        end
    end,
})

ESPGroup:AddToggle("ESPBoxes", {
    Text = "Boxes",
    Default = ESPConfig.Boxes,
    Callback = function(Value)
        ESPConfig.Boxes = Value
    end,
})

ESPGroup:AddToggle("ESPTracers", {
    Text = "Tracers",
    Default = ESPConfig.Tracers,
    Callback = function(Value)
        ESPConfig.Tracers = Value
    end,
})

ESPGroup:AddToggle("ESPChams", {
    Text = "Chams",
    Default = ESPConfig.Chams,
    Callback = function(Value)
        ESPConfig.Chams = Value
        if not Value then
            for _, hl in pairs(ChamCache) do
                hl:Destroy()
            end
            table.clear(ChamCache)
        end
    end,
})

ESPGroup:AddToggle("ESPNPCs", {
    Text = "NPC ESP",
    Default = ESPConfig.UseNPCs,
    Callback = function(Value)
        ESPConfig.UseNPCs = Value
    end,
})

local InfoGroup = Tabs.Info:AddLeftGroupbox("")

InfoGroup:AddLabel("QQ群1040209982", true)
InfoGroup:AddLabel(DiscordInvite, true)

InfoGroup:AddButton({
    Text = "Copy Discord",
    Func = function()
        if setclipboard then
            setclipboard(DiscordInvite)
        elseif toclipboard then
            toclipboard(DiscordInvite)
        end

        Library:Notify({
            Title = "1040209982",
            Description = "Discord copied to clipboard",
            Time = 3,
        })
    end,
    DoubleClick = false,
})

local function bindCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 10)
    Root = char:WaitForChild("HumanoidRootPart", 10)

    if Humanoid then
        Humanoid.WalkSpeed = 16
    end
end

if LocalPlayer.Character then
    task.spawn(bindCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(bindCharacter)

UserInputService.JumpRequest:Connect(function()
    if not JumpConfig.Enabled then
        return
    end

    local character = LocalPlayer.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)

local function validPlayer(player)
    if player == LocalPlayer then
        return false
    end

    if HitboxConfig.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

local function resetPart(part)
    if not part then
        return
    end

    part.Size = Vector3.new(2, 2, 1)
    part.Transparency = 1
    part.CanCollide = false
end

local function expandPlayer(player)
    if not validPlayer(player) then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local part = character:FindFirstChild(HitboxConfig.TargetPart)

    if not humanoid or humanoid.Health <= 0 or not part then
        return
    end

    local size = math.clamp(tonumber(HitboxConfig.Size) or 8, 0, 100)

    part.Size = Vector3.new(size, size, size)
    part.Transparency = HitboxConfig.Transparency
    part.CanCollide = false
end

local function resetPlayer(player)
    local character = player.Character
    if not character then
        return
    end

    resetPart(character:FindFirstChild(HitboxConfig.TargetPart))
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(1)
            if HitboxConfig.Enabled then
                expandPlayer(player)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(1)
        if HitboxConfig.Enabled then
            expandPlayer(player)
        end
    end)
end)

local function isAlive(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getRoot(model)
    return model and (
        model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("Head")
        or model.PrimaryPart
    )
end

local function isPlayerModel(model)
    return Players:GetPlayerFromCharacter(model)
end

local function isValidESPPlayer(player)
    if player == LocalPlayer then
        return false
    end

    if ESPConfig.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

local function getBox(model)
    local cf, size = model:GetBoundingBox()
    local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2

    local corners = {
        cf * Vector3.new(-sx, sy, -sz),
        cf * Vector3.new(sx, sy, -sz),
        cf * Vector3.new(-sx, -sy, -sz),
        cf * Vector3.new(sx, -sy, -sz),
        cf * Vector3.new(-sx, sy, sz),
        cf * Vector3.new(sx, sy, sz),
        cf * Vector3.new(-sx, -sy, sz),
        cf * Vector3.new(sx, -sy, sz)
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local visible = false

    for _, point in ipairs(corners) do
        local screen, onScreen = Camera:WorldToViewportPoint(point)
        if onScreen and screen.Z > 0 then
            visible = true
            minX = math.min(minX, screen.X)
            minY = math.min(minY, screen.Y)
            maxX = math.max(maxX, screen.X)
            maxY = math.max(maxY, screen.Y)
        end
    end

    if not visible then
        return nil
    end

    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function getDraw(id)
    if DrawCache[id] then
        return DrawCache[id]
    end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Filled = false
    box.Thickness = ESPConfig.Thickness
    box.Transparency = 1

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = ESPConfig.Thickness
    tracer.Transparency = 1

    DrawCache[id] = {
        Box = box,
        Tracer = tracer
    }

    return DrawCache[id]
end

local function hideDraw(id)
    local entry = DrawCache[id]
    if not entry then
        return
    end

    entry.Box.Visible = false
    entry.Tracer.Visible = false
end

local function removeCham(id)
    local hl = ChamCache[id]
    if hl then
        hl:Destroy()
        ChamCache[id] = nil
    end
end

local function applyCham(id, model, isPlayer)
    if not ESPConfig.Chams then
        removeCham(id)
        return
    end

    local hl = ChamCache[id]
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "HybridESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
        ChamCache[id] = hl
    end

    hl.Adornee = model
    hl.FillTransparency = ESPConfig.ChamFillTransparency
    hl.OutlineTransparency = ESPConfig.ChamOutlineTransparency
    hl.OutlineColor = ESPConfig.ChamOutlineColor
    hl.FillColor = isPlayer and ESPConfig.PlayerChamColor or ESPConfig.NPCChamColor
end

local function updateModel(id, model, isPlayer)
    local draw = getDraw(id)
    local root = getRoot(model)

    if not ESPConfig.Enabled or not model or not root or not isAlive(model) then
        hideDraw(id)
        removeCham(id)
        return
    end

    local myRoot = LocalPlayer.Character and getRoot(LocalPlayer.Character)
    if myRoot and (myRoot.Position - root.Position).Magnitude > ESPConfig.MaxDistance then
        hideDraw(id)
        removeCham(id)
        return
    end

    local boxPos, boxSize = getBox(model)
    if not boxPos or boxSize.X <= 2 or boxSize.Y <= 2 then
        hideDraw(id)
        removeCham(id)
        return
    end

    applyCham(id, model, isPlayer)

    if ESPConfig.Boxes then
        draw.Box.Position = boxPos
        draw.Box.Size = boxSize
        draw.Box.Color = ESPConfig.BoxColor
        draw.Box.Thickness = ESPConfig.Thickness
        draw.Box.Visible = true
    else
        draw.Box.Visible = false
    end

    if ESPConfig.Tracers then
        draw.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 5)
        draw.Tracer.To = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y)
        draw.Tracer.Color = ESPConfig.TracerColor
        draw.Tracer.Thickness = ESPConfig.Thickness
        draw.Tracer.Visible = true
    else
        draw.Tracer.Visible = false
    end
end

RunService.Heartbeat:Connect(function(dt)
    if SpeedConfig.Enabled then
        if Character and Humanoid and Root and Character.Parent and Humanoid.Health > 0 then
            if Humanoid.WalkSpeed ~= 16 then
                Humanoid.WalkSpeed = 16
            end

            local moveDir = Humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                local floorCheck = workspace:Raycast(Root.Position, Vector3.new(0, -6, 0))

                if floorCheck then
                    local horizontal = Vector3.new(moveDir.X, 0, moveDir.Z)
                    if horizontal.Magnitude > 0 then
                        Root.CFrame = Root.CFrame + (horizontal.Unit * SpeedConfig.Speed * dt)
                    end
                end
            end
        end
    end

    if HitboxConfig.Enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            expandPlayer(player)
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            resetPlayer(player)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local seen = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if isValidESPPlayer(player) then
            local char = player.Character
            if char then
                local id = "P_" .. player.UserId
                seen[id] = true
                updateModel(id, char, true)
            end
        end
    end

    if ESPConfig.UseNPCs then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not isPlayerModel(obj) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hum then
                    local id = "N_" .. obj:GetDebugId()
                    seen[id] = true
                    updateModel(id, obj, false)
                end
            end
        end
    end

    for id, entry in pairs(DrawCache) do
        if not seen[id] then
            entry.Box.Visible = false
            entry.Tracer.Visible = false
            removeCham(id)
        end
    end
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind"
    })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    for _, entry in pairs(DrawCache) do
        entry.Box:Remove()
        entry.Tracer:Remove()
    end

    for _, hl in pairs(ChamCache) do
        hl:Destroy()
    end

    print("Unloaded!")
end)