-- ============================================
-- 港猫的通缉Wanted (Airflow 版)
-- 严格移植「加载配置2.lua」全部功能
-- ============================================

-- ==================== 反作弊安全删除 (来自加载配置2) ====================
print = function() end
warn = function() end
printidentity = function() end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local deletedCount = 0

local function deleteIfExists(parent, ...)
    local obj = parent
    local parts = {...}
    for _, part in ipairs(parts) do
        if obj then
            obj = obj:FindFirstChild(part)
        else
            break
        end
    end
    if obj then
        pcall(function()
            obj:Destroy()
            deletedCount = deletedCount + 1
        end)
        return true
    end
    return false
end

deleteIfExists(ReplicatedStorage, "Shared", "Core", "RateLimiter")
deleteIfExists(ReplicatedStorage, "Vendor", "ReplicaService", "RateLimiter")
deleteIfExists(ReplicatedStorage, "Shared", "Core", "GetAsset")
deleteIfExists(ReplicatedStorage, "Client", "Core", "DebugTeleport")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "Modules", "ClientPlayerFlags")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "Objects", "DevvChassis", "Components", "Telemetry")
deleteIfExists(ReplicatedStorage, "CmdrClient")
deleteIfExists(ReplicatedStorage, "Vendor", "Cmdr")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "UI", "Screens", "PhoneScreen", "Apps", "ReportApp")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "UI", "Screens", "DialogScreen", "Dialogs", "ReportDialog")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "Modules", "ClientPlayerFlags", "Flags")
deleteIfExists(ReplicatedStorage, "Shared", "Wanted", "Indicies", "GameShopFlags")
deleteIfExists(ReplicatedStorage, "Client", "Wanted", "UI", "Screens", "SecurityCameraScreen")
deleteIfExists(ReplicatedStorage, "Client", "Assets", "Guis", "Screens", "SecurityCameraScreen")
deleteIfExists(ReplicatedStorage, "Shared", "Wanted", "Indicies", "FurnitureInteractions", "Interactions", "SecurityDesk")
deleteIfExists(ReplicatedStorage, "Shared", "Wanted", "Indicies", "Objects", "Props", "World", "SecurityDesk")
deleteIfExists(ReplicatedStorage, "Shared", "Wanted", "Indicies", "FurnitureInteractions", "Interactions", "SecurityCamera")
deleteIfExists(ReplicatedStorage, "Shared", "Wanted", "Indicies", "Objects", "Props", "World", "SecurityShutter")

do
    local keywords = {"anticheat", "exploit", "cheat", "hack", "detect", "ban", "flag", "violation"}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = string.lower(obj.Name)
            for _, kw in ipairs(keywords) do
                if string.find(name, kw, 1, true) then
                    pcall(function()
                        obj:Destroy()
                        deletedCount = deletedCount + 1
                    end)
                    break
                end
            end
        end
    end
end

_G.SafeDelete = {
    Run = function()
        deletedCount = 0
    end
}

-- ==================== 加载 Airflow UI ====================
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Window = Airflow:CreateWindow({
    Name = "港猫的通缉Wanted",
    LoadingSubtitle = "作者港猫",
    Icon = "wind",
    ToggleUIKeybind = "RightShift",
    Size = UDim2.fromOffset(700, 550),
    MinSize = Vector2.new(480, 360),
    MaxSize = Vector2.new(1000, 700),
    MaxNotifications = 4,
    KeepOnScreen = true,
    OpenButton = { Title = "港猫", Icon = "wind" },
    Loading = {
        Enabled = true,
        Title = "港猫的通缉Wanted",
        Text = "正在启动",
        Steps = { "准备界面", "加载图标", "即将完成" },
        Duration = 1.5,
    },
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GangMao-Wanted",
        FileName = "default",
    },
    Home = {
        Name = "首页",
        Welcome = "你好, ",
        Stats = { "FPS", "延迟", "执行器", "游戏", "地区", "时间" },
        TimeFormat = "%H:%M",
    },
})

-- ==================== 创建标签 ====================
local T = {}
T.wj   = Window:CreateTab({ Name = "玩家", Desc = "玩家功能", Icon = "users" })
T.jx   = Window:CreateTab({ Name = "远程击杀+雷达", Desc = "远程与雷达", Icon = "crown" })
T.bot  = Window:CreateTab({ Name = "瞄准", Desc = "自瞄设置", Icon = "target" })
T.ESP  = Window:CreateTab({ Name = "ESP", Desc = "透视", Icon = "eye" })
T.ESPP = Window:CreateTab({ Name = "ESP2", Desc = "透视2", Icon = "eye" })
T.wb   = Window:CreateTab({ Name = "ESP物品", Desc = "物品透视", Icon = "box" })
T.qq   = Window:CreateTab({ Name = "删除", Desc = "删除环境物", Icon = "trash-2" })
T.rsao = Window:CreateTab({ Name = "娱乐功能", Desc = "娱乐功能", Icon = "zap" })
T.gm   = Window:CreateTab({ Name = "购买", Desc = "购买功能", Icon = "shopping-cart" })

-- ==================== 通用工具 ====================
local function getCharacter()
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        return LocalPlayer.Character
    end
end

-- ==================== 玩家页：无限跳 ====================
local isInfiniteJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if isInfiniteJumpEnabled then
        local character = getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ==================== 玩家页：超级快跑 ====================
local speedConn, currentSpeed = nil, 1
local function updateChar()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if speedConn then speedConn:Disconnect() speedConn = nil end
    if not hum or currentSpeed <= 1 then return end
    speedConn = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character then
            speedConn:Disconnect() speedConn = nil
            return
        end
        local h = LocalPlayer.Character.Humanoid
        if h.MoveDirection.Magnitude > 0 then
            LocalPlayer.Character:TranslateBy(h.MoveDirection * currentSpeed / 10)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(updateChar)
task.spawn(updateChar)

T.wj:CreateInput({
    Name = "超级快跑 (输入1~200数字)",
    PlaceholderText = "1~200",
    CurrentValue = "1",
    Numeric = true,
    Flag = "SuperRunInput",
    Callback = function(val)
        local num = tonumber(val)
        if not num then return end
        currentSpeed = math.clamp(num, 1, 200)
        updateChar()
    end,
})

T.wj:CreateSlider({
    Name = "超级快跑(滑块)",
    Range = { 1, 200 },
    Increment = 1,
    CurrentValue = 1,
    Flag = "SuperRunSlider",
    Callback = function(val)
        currentSpeed = val
        updateChar()
    end,
})

-- ==================== 玩家页：灵魂飞行 ====================
local isWarpFlying, flySpeed = false, 50
local hrp, hum
local ControlModule
do
    local ok, result = pcall(function()
        return require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
    end)
    if ok then ControlModule = result end
end
local originalCanCollide = {}
local diedConn

local function clearFlyRes()
    pcall(function()
        for part, state in pairs(originalCanCollide) do
            if part and part.Parent then part.CanCollide = state end
        end
        table.clear(originalCanCollide)
        if diedConn then diedConn:Disconnect() end
        if hrp and hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
    end)
end

local function microStepLoop()
    local targetPos = hrp.Position
    local lastTime = tick()
    while isWarpFlying do
        local now = tick(); local dt = now - lastTime; lastTime = now
        local mv = ControlModule:GetMoveVector()
        local cf = Camera.CFrame
        local moveDir = (cf.LookVector * -mv.Z) + (cf.RightVector * mv.X)
        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = -1 end
        targetPos += (moveDir + Vector3.new(0, vertical, 0)) * flySpeed * dt
        local currentPos = hrp.Position
        local remaining = targetPos - currentPos
        local distance = remaining.Magnitude
        if distance > 0 then
            local steps = math.ceil(distance / 10)
            local stepVec = remaining / steps
            for i = 1, steps do
                if not isWarpFlying then break end
                currentPos += stepVec
                hrp.CFrame = CFrame.new(currentPos) * hrp.CFrame.Rotation
                hrp.Velocity = Vector3.zero
            end
        end
        hum:ChangeState(Enum.HumanoidStateType.Climbing)
        task.wait(0.001)
    end
end

local function healthLockLoop()
    while isWarpFlying do
        if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        RunService.Heartbeat:Wait()
    end
end

local function startWarpFly()
    if isWarpFlying then return end
    local char = LocalPlayer.Character
    if not char then return end
    hrp = char:FindFirstChild("HumanoidRootPart")
    hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or not ControlModule then
        Airflow:Notify({ Title = "灵魂飞行", Content = "ControlModule 加载失败", Type = "Error", Duration = 3 })
        return
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            originalCanCollide[part] = part.CanCollide
            part.CanCollide = false
        end
    end
    isWarpFlying = true
    hum:ChangeState(Enum.HumanoidStateType.Climbing)
    task.spawn(microStepLoop)
    task.spawn(healthLockLoop)
    diedConn = hum.Died:Connect(function()
        if hum and isWarpFlying then
            hum.Health = hum.MaxHealth
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
end

local function stopWarpFly()
    isWarpFlying = false
    clearFlyRes()
end

T.wj:CreateToggle({
    Name = "灵魂飞行 (思路来自AF作者秋辞❤️)",
    CurrentValue = false,
    Flag = "WarpFly",
    Callback = function(v)
        if v then startWarpFly() else stopWarpFly() end
    end,
})

T.wj:CreateSlider({
    Name = "飞行速度",
    Range = { 10, 130 },
    Increment = 1,
    CurrentValue = 50,
    Flag = "WarpFlySpeed",
    Callback = function(val) flySpeed = val end,
})

-- ==================== 玩家页：人物自转 ====================
local SpinEnabled, SpinSpeed = false, 5
local SpinConnection = nil
local function StartSpin()
    if SpinConnection then return end
    SpinConnection = RunService.RenderStepped:Connect(function(dt)
        if not SpinEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return end
        hrp2.CFrame = hrp2.CFrame * CFrame.Angles(0, math.rad(SpinSpeed) * dt * 60, 0)
    end)
end
local function StopSpin()
    SpinEnabled = false
    if SpinConnection then SpinConnection:Disconnect() SpinConnection = nil end
end
LocalPlayer.CharacterAdded:Connect(function()
    if SpinEnabled then task.wait(0.5) StartSpin() end
end)

T.wj:CreateToggle({
    Name = "人物自转",
    CurrentValue = false,
    Flag = "Spin",
    Callback = function(v)
        SpinEnabled = v
        if v then StartSpin() else StopSpin() end
    end,
})

T.wj:CreateSlider({
    Name = "旋转速度",
    Range = { 1, 200 },
    Increment = 5,
    CurrentValue = 5,
    Flag = "SpinSpeed",
    Callback = function(v) SpinSpeed = v end,
})

-- ==================== 玩家页：修改别人头部大小 ====================
local HeadScaler = {
    enabled = false, headSize = 1,
    heartbeatConn = nil, playerAddedConn = nil, charBindings = {},
}
function HeadScaler:UpdateAllHeads()
    local size = Vector3.new(self.headSize, self.headSize, self.headSize)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then pcall(function() head.Size = size; head.CanCollide = false end) end
        end
    end
end
function HeadScaler:BindPlayer(player)
    if self.charBindings[player] then return end
    self.charBindings[player] = player.CharacterAdded:Connect(function()
        task.wait(0.15); self:UpdateAllHeads()
    end)
end
function HeadScaler:ClearAll()
    if self.heartbeatConn then self.heartbeatConn:Disconnect() self.heartbeatConn = nil end
    if self.playerAddedConn then self.playerAddedConn:Disconnect() self.playerAddedConn = nil end
    for p, c in pairs(self.charBindings) do c:Disconnect(); self.charBindings[p] = nil end
end
function HeadScaler:SetEnabled(enable)
    if self.enabled == enable then return end
    self:ClearAll(); self.enabled = enable
    if not enable then return end
    self.heartbeatConn = RunService.Heartbeat:Connect(function() self:UpdateAllHeads() end)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then self:BindPlayer(p) end
    end
    self.playerAddedConn = Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then self:BindPlayer(p) end
    end)
    self:UpdateAllHeads()
end
function HeadScaler:SetSize(newSize)
    self.headSize = math.clamp(newSize, 1, 5000)
    if self.enabled then self:UpdateAllHeads() end
end
Players.PlayerRemoving:Connect(function(p)
    if HeadScaler.charBindings[p] then
        HeadScaler.charBindings[p]:Disconnect()
        HeadScaler.charBindings[p] = nil
    end
end)

T.wj:CreateToggle({
    Name = "修改别人头部大小(仅本地)",
    CurrentValue = false,
    Flag = "HeadScale",
    Callback = function(v) HeadScaler:SetEnabled(v) end,
})

T.wj:CreateInput({
    Name = "别人头部尺寸 (1-5000)",
    PlaceholderText = "1",
    CurrentValue = "1",
    Numeric = true,
    Flag = "HeadSize",
    Callback = function(v)
        local n = tonumber(v); if n then HeadScaler:SetSize(n) end
    end,
})

T.wj:CreateToggle({
    Name = "无限跳",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(s) isInfiniteJumpEnabled = s end,
})

-- ==================== 玩家页：穿墙 ====================
local clipConn = nil
T.wj:CreateToggle({
    Name = "穿墙",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(enabled)
        if clipConn then clipConn:Disconnect() clipConn = nil end
        if enabled then
            clipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
        else
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end,
})

T.wj:CreateButton({
    Name = "踏空行走",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float'))()
        end)
    end,
})

T.wj:CreateButton({
    Name = "定 (空中定住)",
    Callback = function()
        local player = LocalPlayer
        local freeze, lockY = false, nil
        local character, root
        local function LoadCharacter()
            character = player.Character or player.CharacterAdded:Wait()
            root = character:WaitForChild("HumanoidRootPart")
        end
        LoadCharacter()
        player.CharacterAdded:Connect(function() task.wait(1) LoadCharacter() end)
        local gui = Instance.new("ScreenGui")
        gui.Name = "AirFreezeUI"; gui.ResetOnSpawn = false
        gui.Parent = player:WaitForChild("PlayerGui")
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0,90,0,90); main.Position = UDim2.new(0.5,-70,0.65,0)
        main.BackgroundColor3 = Color3.fromRGB(25,25,30); main.Parent = gui
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = main
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,0,0,26); title.BackgroundTransparency = 1
        title.Text = "定"; title.TextColor3 = Color3.new(1,1,1); title.TextSize = 16; title.Parent = main
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,100,0,32); btn.Position = UDim2.new(0.5,-50,0.48,0)
        btn.BackgroundColor3 = Color3.fromRGB(0,170,255); btn.Text = "开启"
        btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 14; btn.Parent = main
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,8); tc.Parent = btn
        btn.MouseButton1Click:Connect(function()
            freeze = not freeze
            if freeze then btn.Text = "关闭"; btn.BackgroundColor3 = Color3.fromRGB(255,70,70)
                if root then lockY = root.Position.Y end
            else btn.Text = "开启"; btn.BackgroundColor3 = Color3.fromRGB(0,170,255); lockY = nil end
        end)
        RunService.Heartbeat:Connect(function()
            if freeze and root and lockY then
                local pos = root.Position
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = CFrame.new(pos.X, lockY, pos.Z) * root.CFrame.Rotation
            end
        end)
    end,
})

-- ==================== 远程击杀 + 雷达 ====================
T.jx:CreateButton({
    Name = "远程传送击杀",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/cQ/refs/heads/main/%E8%BF%9C%E7%A8%8B%E5%87%BB%E6%9D%80.lua"))()
        end)
    end,
})
T.jx:CreateButton({
    Name = "开启雷达扫描⚠️",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/cQ/refs/heads/main/%E9%9B%B7%E8%BE%BE%E6%89%AB%E6%8F%8F.lua"))()
        end)
    end,
})

-- ==================== 瞄准页 ====================
local AimConfig = {
    Enabled = false, BulletTrack = false, FOV = 200, Smoothness = 0.15,
    Prediction = 0.12, BulletSpeed = 1500, BulletDrop = 0, WallCheck = true,
    ShowFOV = false, ShowTracer = true, AimPart = "Head", TeamCheck = true, JumpPrediction = true,
}
local aimFOVCircle = Drawing.new("Circle")
aimFOVCircle.Visible = false
aimFOVCircle.Color = Color3.fromRGB(255, 50, 50)
aimFOVCircle.Thickness = 1.5
aimFOVCircle.Filled = false
aimFOVCircle.Transparency = 0.4
aimFOVCircle.NumSides = 64
aimFOVCircle.Radius = AimConfig.FOV
aimFOVCircle.Position = Camera.ViewportSize / 2

local aimTracer = Drawing.new("Line")
aimTracer.Visible = false
aimTracer.Color = Color3.fromRGB(255, 50, 50)
aimTracer.Thickness = 1.5
aimTracer.Transparency = 0.4
aimTracer.From = Camera.ViewportSize / 2
aimTracer.To = Camera.ViewportSize / 2

local aimTargetPart, mainConn = nil, nil

local function findClosestPlayer()
    local center = Camera.ViewportSize / 2
    local best, bestDist = nil, AimConfig.FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local hrpX = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrpX and humanoid.Health > 0 then
                if not (AimConfig.TeamCheck and player.Team and player.Team == LocalPlayer.Team) then
                    local part = player.Character:FindFirstChild(AimConfig.AimPart)
                        or player.Character:FindFirstChild("Head") or hrpX
                    if part then
                        local sp, vis = Camera:WorldToViewportPoint(part.Position)
                        if vis and sp.Z < 1000 then
                            local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(center.X, center.Y)).Magnitude
                            if sd < bestDist then best, bestDist = part, sd end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function isWallHit(part)
    if not AimConfig.WallCheck then return false end
    local origin = Camera.CFrame.Position
    local rayP = RaycastParams.new()
    rayP.FilterType = Enum.RaycastFilterType.Exclude
    rayP.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = workspace:Raycast(origin, part.Position - origin, rayP)
    if result and not result.Instance:IsDescendantOf(part.Parent) then return true end
    return false
end

local function doCameraAim()
    if not aimTargetPart or not aimTargetPart.Parent then return end
    local humX = aimTargetPart.Parent:FindFirstChildOfClass("Humanoid")
    if not humX or humX.Health <= 0 then return end
    if isWallHit(aimTargetPart) then return end
    local dist = (aimTargetPart.Position - Camera.CFrame.Position).Magnitude
    local time = dist / math.max(AimConfig.BulletSpeed, 100)
    local vel = Vector3.zero
    local tHrp = aimTargetPart.Parent:FindFirstChild("HumanoidRootPart")
    if tHrp then vel = tHrp.AssemblyLinearVelocity end
    local predictPos = aimTargetPart.Position + vel * AimConfig.Prediction
    local dropOffset = Vector3.new(0, -AimConfig.BulletDrop * time * time, 0)
    local jumpOff = Vector3.zero
    if AimConfig.JumpPrediction and tHrp and tHrp.AssemblyLinearVelocity.Y > 10 then
        jumpOff = Vector3.new(0, tHrp.AssemblyLinearVelocity.Y * AimConfig.Prediction * 0.5, 0)
    end
    local targetPos = predictPos + dropOffset + jumpOff
    local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
    if AimConfig.Smoothness >= 1 then Camera.CFrame = targetCF
    else Camera.CFrame = Camera.CFrame:Lerp(targetCF, AimConfig.Smoothness) end
end

T.bot:CreateToggle({
    Name = "🎯 自瞄总开关",
    CurrentValue = false,
    Flag = "AimOn",
    Callback = function(state)
        AimConfig.Enabled = state
        if state then
            if not mainConn then
                mainConn = RunService.RenderStepped:Connect(function()
                    if not AimConfig.Enabled then
                        aimTargetPart = nil
                        aimFOVCircle.Visible = false
                        aimTracer.Visible = false
                        return
                    end
                    aimFOVCircle.Position = Camera.ViewportSize / 2
                    aimFOVCircle.Radius = AimConfig.FOV
                    aimFOVCircle.Visible = AimConfig.ShowFOV
                    aimTargetPart = findClosestPlayer()
                    doCameraAim()
                    if aimTargetPart and aimTargetPart.Parent then
                        local sp, vis = Camera:WorldToViewportPoint(aimTargetPart.Position)
                        if vis then
                            aimTracer.Visible = AimConfig.ShowTracer
                            aimTracer.From = Camera.ViewportSize / 2
                            aimTracer.To = Vector2.new(sp.X, sp.Y)
                        else aimTracer.Visible = false end
                    else aimTracer.Visible = false end
                end)
            end
        else
            if mainConn then mainConn:Disconnect() mainConn = nil end
            aimTargetPart = nil
            aimFOVCircle.Visible = false
            aimTracer.Visible = false
        end
    end,
})

local btHbSize = 8
local btHbConn = nil
local function btExpandPlayer(player)
    if player == LocalPlayer then return end
    if AimConfig.TeamCheck and player.Team and player.Team == LocalPlayer.Team then return end
    local char = player.Character; if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local hrpX = char:FindFirstChild("HumanoidRootPart"); if not hrpX then return end
    local size = math.clamp(btHbSize, 0, 100)
    pcall(function()
        hrpX.Size = Vector3.new(size, size, size)
        hrpX.Transparency = 0.85
        hrpX.Color = Color3.fromRGB(190, 190, 190)
        hrpX.Material = Enum.Material.Neon
        hrpX.CanCollide = false
    end)
end
local function btResetPlayer(player)
    local char = player.Character; if not char then return end
    local hrpX = char:FindFirstChild("HumanoidRootPart"); if not hrpX then return end
    pcall(function()
        hrpX.Size = Vector3.new(2, 2, 1); hrpX.Transparency = 0
        hrpX.Color = Color3.fromRGB(163,162,165); hrpX.Material = Enum.Material.Plastic
        hrpX.CanCollide = true
    end)
end

T.bot:CreateToggle({
    Name = "💣 子弹追踪总开关",
    CurrentValue = false,
    Flag = "BulletTrack",
    Callback = function(state)
        AimConfig.BulletTrack = state
        if state then
            if not btHbConn then
                btHbConn = RunService.Heartbeat:Connect(function()
                    if AimConfig.BulletTrack then
                        for _, p in ipairs(Players:GetPlayers()) do btExpandPlayer(p) end
                    end
                end)
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    player.CharacterAdded:Connect(function()
                        task.wait(1)
                        if AimConfig.BulletTrack then btExpandPlayer(player) end
                    end)
                end
            end
        else
            if btHbConn then btHbConn:Disconnect() btHbConn = nil end
            for _, p in ipairs(Players:GetPlayers()) do btResetPlayer(p) end
        end
    end,
})

T.bot:CreateSlider({ Name = "📦 判定箱大小", Range = { 0, 100 }, Increment = 1, CurrentValue = 8, Flag = "HBSize", Callback = function(v) btHbSize = v end })
T.bot:CreateSlider({ Name = "🎯 自瞄FOV范围", Range = { 20, 1000 }, Increment = 10, CurrentValue = 200, Flag = "AimFOV", Callback = function(v) AimConfig.FOV = v; aimFOVCircle.Radius = v end })
T.bot:CreateSlider({ Name = "🔘 平滑系数", Range = { 0.01, 1 }, Increment = 0.01, CurrentValue = 0.15, Flag = "AimSm", Callback = function(v) AimConfig.Smoothness = v end })
T.bot:CreateSlider({ Name = "⚡ 预判强度", Range = { 0, 1 }, Increment = 0.01, CurrentValue = 0.12, Flag = "AimPr", Callback = function(v) AimConfig.Prediction = v end })
T.bot:CreateSlider({ Name = "🔫 子弹速度", Range = { 100, 5000 }, Increment = 50, CurrentValue = 1500, Flag = "AimBS", Callback = function(v) AimConfig.BulletSpeed = v end })
T.bot:CreateSlider({ Name = "📉 弹道下坠补偿", Range = { 0, 200 }, Increment = 1, CurrentValue = 0, Flag = "AimBD", Callback = function(v) AimConfig.BulletDrop = v end })

T.bot:CreateDropdown({ Name = "🎯 瞄准部位", Options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"}, CurrentOption = "Head", Flag = "AimPart", Callback = function(o) AimConfig.AimPart = o end })
T.bot:CreateToggle({ Name = "🧱 掩体判断", CurrentValue = true, Flag = "AimWall", Callback = function(s) AimConfig.WallCheck = s end })
T.bot:CreateToggle({ Name = "⭕ 显示FOV圆圈", CurrentValue = false, Flag = "AimFovV", Callback = function(s) AimConfig.ShowFOV = s end })
T.bot:CreateToggle({ Name = "📏 显示自瞄射线", CurrentValue = true, Flag = "AimTracer", Callback = function(s) AimConfig.ShowTracer = s end })
T.bot:CreateToggle({ Name = "👥 区分队友", CurrentValue = true, Flag = "AimTeam", Callback = function(s) AimConfig.TeamCheck = s end })
T.bot:CreateToggle({ Name = "🦘 跳跃预判", CurrentValue = true, Flag = "AimJump", Callback = function(s) AimConfig.JumpPrediction = s end })

-- ==================== ESP 页 ====================
ESP_Config = {
    EnableESP = false, ShowBox = true, ShowHealth = true, ShowName = true,
    ShowDistance = true, ShowTracer = false, ShowSkeleton = false, ShowWeapon = false,
    WallHack = false, TeamCheck = false, MaxDrawDistance = 350, BoxThickness = 1,
    TracerThickness = 1, SkeletonThickness = 2,
    EnemyColor = Color3.new(1, 0.3, 0.3), TeammateColor = Color3.new(0.3, 1, 0.3),
    NPCColor = Color3.new(1, 1, 0.2), BoxColor = Color3.new(1, 1, 1),
    TracerColor = Color3.new(1, 0, 0), SkeletonColor = Color3.new(0.2, 0.8, 1),
    HealthBarColor = Color3.new(0, 1, 0),
}

local ESPComponents = {}

local function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = ESP_Config.BoxColor
    box.Thickness = ESP_Config.BoxThickness
    box.Filled = false

    local healthBar = Drawing.new("Square"); healthBar.Visible = false; healthBar.Filled = true
    local healthBarBackground = Drawing.new("Square")
    healthBarBackground.Visible = false; healthBarBackground.Color = Color3.new(0, 0, 0)
    healthBarBackground.Transparency = 0.5; healthBarBackground.Filled = true
    local healthBarBorder = Drawing.new("Square")
    healthBarBorder.Visible = false; healthBarBorder.Color = Color3.new(1, 1, 1)
    healthBarBorder.Thickness = 1; healthBarBorder.Filled = false

    local healthText = Drawing.new("Text")
    healthText.Visible = false; healthText.Size = 14; healthText.Font = Drawing.Fonts.Monospace
    healthText.Outline = true; healthText.OutlineColor = Color3.new(0, 0, 0)

    local nameText = Drawing.new("Text")
    nameText.Visible = false; nameText.Size = 16; nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true; nameText.OutlineColor = Color3.new(0, 0, 0)

    local distanceText = Drawing.new("Text")
    distanceText.Visible = false; distanceText.Color = Color3.new(1, 1, 0); distanceText.Size = 14
    distanceText.Font = Drawing.Fonts.Monospace; distanceText.Outline = true
    distanceText.OutlineColor = Color3.new(0, 0, 0)

    local weaponText = Drawing.new("Text")
    weaponText.Visible = false; weaponText.Color = Color3.new(1, 0.5, 0); weaponText.Size = 14
    weaponText.Font = Drawing.Fonts.Monospace; weaponText.Outline = true
    weaponText.OutlineColor = Color3.new(0, 0, 0)

    local tracer = Drawing.new("Line")
    tracer.Visible = false; tracer.Color = ESP_Config.TracerColor
    tracer.Thickness = ESP_Config.TracerThickness

    local skeletonLines = {}
    for i = 1, 15 do
        skeletonLines[i] = Drawing.new("Line")
        skeletonLines[i].Visible = false
        skeletonLines[i].Color = ESP_Config.SkeletonColor
        skeletonLines[i].Thickness = ESP_Config.SkeletonThickness
    end
    local skeletonPoints = {}
    skeletonPoints["Head"] = Drawing.new("Circle")
    skeletonPoints["Head"].Visible = false
    skeletonPoints["Head"].Color = Color3.new(1, 0.5, 0)
    skeletonPoints["Head"].Thickness = 2
    skeletonPoints["Head"].Filled = true
    skeletonPoints["Head"].Radius = 4

    local lastHealth, healthChangeTime, smoothHealth = 100, 0, 100

    ESPComponents[player] = {
        box = box, healthBar = healthBar, healthBarBackground = healthBarBackground,
        healthBarBorder = healthBarBorder, healthText = healthText, nameText = nameText,
        distanceText = distanceText, weaponText = weaponText, tracer = tracer,
        skeletonLines = skeletonLines, skeletonPoints = skeletonPoints,
    }

    local function hideAll()
        for _, obj in pairs({box, healthBar, healthBarBackground, healthBarBorder,
            healthText, nameText, distanceText, weaponText, tracer}) do
            obj.Visible = false
        end
        for _, line in pairs(skeletonLines) do line.Visible = false end
        for _, point in pairs(skeletonPoints) do point.Visible = false end
    end

    RunService.RenderStepped:Connect(function()
        if not ESP_Config.EnableESP then hideAll() return end
        if not player.Character
            or not player.Character:FindFirstChild("HumanoidRootPart")
            or not player.Character:FindFirstChild("Humanoid")
            or player == LocalPlayer then hideAll() return end
        if ESP_Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team then hideAll() return end

        local character = player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not rootPart or not humanoid or humanoid.Health <= 0 then hideAll() return end

        local dist = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if dist > ESP_Config.MaxDrawDistance then hideAll() return end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
        local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        local color = ESP_Config.EnemyColor
        if ESP_Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
            color = ESP_Config.TeammateColor
        end

        local weaponName = "无武器"
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then weaponName = tool.Name break end
        end

        if ESP_Config.ShowBox and onScreen then
            box.Size = Vector2.new(1000 / rootPos.Z, headPos.Y - legPos.Y)
            box.Position = Vector2.new(rootPos.X - box.Size.X / 2, rootPos.Y - box.Size.Y / 2)
            box.Visible = true
            box.Color = ESP_Config.BoxColor
            box.Thickness = ESP_Config.BoxThickness
        else box.Visible = false end

        if ESP_Config.ShowHealth and onScreen then
            local barWidth, barHeight = 50, 5
            local barX = headPos.X - barWidth / 2
            local barY = headPos.Y - 20
            healthBarBackground.Size = Vector2.new(barWidth, barHeight)
            healthBarBackground.Position = Vector2.new(barX, barY)
            healthBarBackground.Visible = true
            healthBarBorder.Size = Vector2.new(barWidth, barHeight)
            healthBarBorder.Position = Vector2.new(barX, barY)
            healthBarBorder.Visible = true
            smoothHealth = smoothHealth + (humanoid.Health - smoothHealth) * 0.1
            local smoothHP = smoothHealth / humanoid.MaxHealth
            healthBar.Size = Vector2.new(barWidth * smoothHP, barHeight)
            healthBar.Position = Vector2.new(barX, barY)
            if smoothHP >= 0.8 then healthBar.Color = Color3.new(0, 1, 0)
            elseif smoothHP >= 0.5 then healthBar.Color = Color3.new(1, 1, 0)
            elseif smoothHP >= 0.2 then healthBar.Color = Color3.new(1, 0.5, 0)
            else healthBar.Color = Color3.new(1, 0, 0) end
            if humanoid.Health ~= lastHealth then healthChangeTime = tick(); lastHealth = humanoid.Health end
            if tick() - healthChangeTime < 0.5 then healthBar.Color = Color3.new(1, 0, 0) end
            healthBar.Visible = true
            healthText.Position = Vector2.new(barX + barWidth + 5, barY - 5)
            healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            healthText.Color = color
            healthText.Visible = true
        else
            healthBar.Visible = false; healthBarBackground.Visible = false
            healthBarBorder.Visible = false; healthText.Visible = false
        end

        if ESP_Config.ShowName and onScreen then
            nameText.Position = Vector2.new(headPos.X, headPos.Y - 35)
            nameText.Text = player.Name
            nameText.Color = color
            nameText.Visible = true
            if ESP_Config.ShowDistance then
                distanceText.Position = Vector2.new(headPos.X, headPos.Y + 10)
                distanceText.Text = math.floor(dist) .. "m"
                distanceText.Visible = true
            else distanceText.Visible = false end
            if ESP_Config.ShowWeapon then
                weaponText.Position = Vector2.new(headPos.X, headPos.Y - 50)
                weaponText.Text = weaponName
                weaponText.Visible = true
            else weaponText.Visible = false end
        else
            nameText.Visible = false; distanceText.Visible = false; weaponText.Visible = false
        end

        if ESP_Config.ShowTracer then
            local head = character:FindFirstChild("Head")
            if head then
                local hPos, hOnScreen = Camera:WorldToViewportPoint(head.Position)
                if hOnScreen then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    tracer.To = Vector2.new(hPos.X, hPos.Y)
                    tracer.Visible = true
                    tracer.Thickness = ESP_Config.TracerThickness
                    if dist < 20 then tracer.Color = Color3.new(0, 1, 0)
                    elseif dist < 50 then tracer.Color = Color3.new(1, 1, 0)
                    else tracer.Color = ESP_Config.TracerColor end
                else tracer.Visible = false end
            else tracer.Visible = false end
        else tracer.Visible = false end

        if ESP_Config.ShowSkeleton and onScreen then
            local head = character:FindFirstChild("Head")
            local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm")
            local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
            local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg")
            local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg")
            if head and torso and leftArm and rightArm and leftLeg and rightLeg then
                local hP = Camera:WorldToViewportPoint(head.Position)
                local tP = Camera:WorldToViewportPoint(torso.Position)
                local laP = Camera:WorldToViewportPoint(leftArm.Position)
                local raP = Camera:WorldToViewportPoint(rightArm.Position)
                local llP = Camera:WorldToViewportPoint(leftLeg.Position)
                local rlP = Camera:WorldToViewportPoint(rightLeg.Position)
                skeletonPoints["Head"].Position = Vector2.new(hP.X, hP.Y)
                skeletonPoints["Head"].Visible = true
                local pairsArr = {{hP, tP}, {tP, laP}, {tP, raP}, {tP, llP}, {tP, rlP}}
                for i, p in ipairs(pairsArr) do
                    skeletonLines[i].From = Vector2.new(p[1].X, p[1].Y)
                    skeletonLines[i].To = Vector2.new(p[2].X, p[2].Y)
                    skeletonLines[i].Visible = true
                end
            else
                for _, line in pairs(skeletonLines) do line.Visible = false end
                for _, point in pairs(skeletonPoints) do point.Visible = false end
            end
        else
            for _, line in pairs(skeletonLines) do line.Visible = false end
            for _, point in pairs(skeletonPoints) do point.Visible = false end
        end
    end)
end

local function cleanupESP(player)
    if ESPComponents[player] then
        local comps = ESPComponents[player]
        for _, component in pairs(comps) do
            if typeof(component) == "table" then
                for _, drawing in pairs(component) do
                    if typeof(drawing) == "userdata" then pcall(function() drawing:Remove() end) end
                end
            else
                if typeof(component) == "userdata" then pcall(function() component:Remove() end) end
            end
        end
        ESPComponents[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createESP(player) end
end)
Players.PlayerRemoving:Connect(function(player) cleanupESP(player) end)

T.ESP:CreateToggle({
    Name = "开启ESP总开关",
    CurrentValue = false,
    Flag = "ESPEnable",
    Callback = function(state)
        ESP_Config.EnableESP = state
        if not state then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and ESPComponents[player] then
                    for _, component in pairs(ESPComponents[player]) do
                        if typeof(component) == "table" then
                            for _, d in pairs(component) do
                                if typeof(d) == "userdata" then pcall(function() d.Visible = false end) end
                            end
                        else
                            if typeof(component) == "userdata" then pcall(function() component.Visible = false end) end
                        end
                    end
                end
            end
        end
    end,
})

T.ESP:CreateToggle({ Name = "显示头顶名称", CurrentValue = true, Flag = "ESPName", Callback = function(v) ESP_Config.ShowName = v end })
T.ESP:CreateToggle({ Name = "显示血量", CurrentValue = true, Flag = "ESPHealth", Callback = function(v) ESP_Config.ShowHealth = v end })
T.ESP:CreateToggle({ Name = "显示距离", CurrentValue = true, Flag = "ESPDist", Callback = function(v) ESP_Config.ShowDistance = v end })
T.ESP:CreateToggle({ Name = "方框透视", CurrentValue = true, Flag = "ESPBox", Callback = function(v) ESP_Config.ShowBox = v end })
T.ESP:CreateToggle({ Name = "射线透视 (从屏幕顶部)", CurrentValue = false, Flag = "ESPTracer", Callback = function(v) ESP_Config.ShowTracer = v end })
T.ESP:CreateToggle({ Name = "骨架透视", CurrentValue = false, Flag = "ESPSkeleton", Callback = function(v) ESP_Config.ShowSkeleton = v end })
T.ESP:CreateToggle({ Name = "武器显示", CurrentValue = false, Flag = "ESPWeapon", Callback = function(v) ESP_Config.ShowWeapon = v end })
T.ESP:CreateToggle({ Name = "穿墙ESP", CurrentValue = false, Flag = "ESPWall", Callback = function(v) ESP_Config.WallHack = v end })
T.ESP:CreateToggle({ Name = "区分队友颜色", CurrentValue = false, Flag = "ESPTeam", Callback = function(v) ESP_Config.TeamCheck = v end })

T.ESP:CreateSlider({ Name = "ESP最大可视距离", Range = { 50, 1000 }, Increment = 10, CurrentValue = 350, Flag = "ESPMaxD", Callback = function(val) ESP_Config.MaxDrawDistance = val end })
T.ESP:CreateSlider({ Name = "方框线条粗细", Range = { 1, 5 }, Increment = 1, CurrentValue = 1, Flag = "ESPBoxT", Callback = function(v) ESP_Config.BoxThickness = v end })
T.ESP:CreateSlider({ Name = "射线线条粗细", Range = { 1, 10 }, Increment = 1, CurrentValue = 1, Flag = "ESPTracerT", Callback = function(v) ESP_Config.TracerThickness = v end })

-- ==================== ESP2 页 ====================
local P_FONT_SIZE = 16
local P_FONT_NAME = Drawing.Fonts.Monospace
local P_MAX_DISTANCE = 1500
local P_BOX_THICKNESS = 1
local P_BOX_SCALE = 2.2

local P_Enabled = false
local P_DrawBox = false
local P_DrawDistance = false
local P_DrawName = false
local P_DrawTracer = false
local P_DrawHealth = false

local P_Objects = {}
local P_Initialized = false
local P_RenderConn = nil

local function P_WorldToScreen(worldPos)
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function P_GetCharData(player)
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local head = char:FindFirstChild("Head")
    if not humanoid or not root or not head then return nil end
    return char, humanoid, root, head
end

local function P_CreateObjects()
    local objs = {}
    objs.Box = Drawing.new("Square")
    objs.Box.Filled = false
    objs.Box.Transparency = 1
    objs.Name = Drawing.new("Text")
    objs.Name.Size = P_FONT_SIZE
    objs.Name.Center = true
    objs.Name.Outline = true
    objs.Name.Font = P_FONT_NAME
    objs.Distance = Drawing.new("Text")
    objs.Distance.Size = P_FONT_SIZE - 2
    objs.Distance.Center = true
    objs.Distance.Outline = true
    objs.Distance.Font = P_FONT_NAME
    objs.Health = Drawing.new("Text")
    objs.Health.Size = P_FONT_SIZE - 2
    objs.Health.Center = true
    objs.Health.Outline = true
    objs.Health.Font = P_FONT_NAME
    objs.Tracer = Drawing.new("Line")
    objs.Tracer.Thickness = 1
    objs.Tracer.Transparency = 0.5
    return objs
end

local function P_DestroyObjects(objs)
    if not objs then return end
    for _, obj in pairs(objs) do
        if obj and obj.Remove then pcall(function() obj:Remove() end) end
    end
end

local function P_UpdatePlayer(player, objs)
    if player == LocalPlayer then return end
    local char, humanoid, root, head = P_GetCharData(player)
    if not char or not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(objs) do obj.Visible = false end
        return
    end
    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > P_MAX_DISTANCE then
        for _, obj in pairs(objs) do obj.Visible = false end
        return
    end
    local headScreen = P_WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
    local rootScreen = P_WorldToScreen(root.Position)
    if not headScreen or not rootScreen then
        for _, obj in pairs(objs) do obj.Visible = false end
        return
    end
    local height = math.abs(headScreen.Y - rootScreen.Y) * P_BOX_SCALE
    local width = height * 0.65
    height = math.max(height, 15)
    width = math.max(width, 10)
    local topLeft = Vector2.new(headScreen.X - width / 2, headScreen.Y - height * 0.2)
    local bottomRight = Vector2.new(headScreen.X + width / 2, topLeft.Y + height)

    if P_DrawBox then
        objs.Box.Visible = true
        objs.Box.Size = bottomRight - topLeft
        objs.Box.Position = topLeft
        objs.Box.Thickness = P_BOX_THICKNESS
        local hp = humanoid.Health / humanoid.MaxHealth
        if hp > 0.5 then objs.Box.Color = Color3.fromRGB(0, 255, 0)
        elseif hp > 0.25 then objs.Box.Color = Color3.fromRGB(255, 165, 0)
        else objs.Box.Color = Color3.fromRGB(255, 0, 0) end
    else objs.Box.Visible = false end

    if P_DrawName then
        objs.Name.Visible = true
        objs.Name.Text = player.Name
        objs.Name.Color = Color3.fromRGB(255, 255, 255)
        objs.Name.Position = Vector2.new(headScreen.X, topLeft.Y - P_FONT_SIZE - 2)
    else objs.Name.Visible = false end

    if P_DrawDistance then
        objs.Distance.Visible = true
        objs.Distance.Text = string.format("[%d m]", math.floor(distance))
        objs.Distance.Color = Color3.fromRGB(200, 200, 200)
        objs.Distance.Position = Vector2.new(headScreen.X, bottomRight.Y + 2)
    else objs.Distance.Visible = false end

    if P_DrawHealth then
        objs.Health.Visible = true
        objs.Health.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        objs.Health.Color = Color3.fromRGB(0, 255, 0)
        objs.Health.Position = Vector2.new(headScreen.X, bottomRight.Y + P_FONT_SIZE + 2)
    else objs.Health.Visible = false end

    if P_DrawTracer then
        objs.Tracer.Visible = true
        objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
        objs.Tracer.To = Vector2.new(headScreen.X, bottomRight.Y)
        objs.Tracer.Color = Color3.fromRGB(255, 255, 255)
    else objs.Tracer.Visible = false end
end

local function P_InitPlayer(player)
    if player == LocalPlayer then return end
    if P_Objects[player] then P_DestroyObjects(P_Objects[player]) end
    P_Objects[player] = P_CreateObjects()
end

T.ESPP:CreateButton({
    Name = "🔧 初始化 ESP2 (必先点击)",
    Callback = function()
        if P_Initialized then return end
        P_Initialized = true
        for _, player in ipairs(Players:GetPlayers()) do P_InitPlayer(player) end
        Players.PlayerAdded:Connect(P_InitPlayer)
        Players.PlayerRemoving:Connect(function(player)
            if P_Objects[player] then
                P_DestroyObjects(P_Objects[player])
                P_Objects[player] = nil
            end
        end)
        P_RenderConn = RunService.RenderStepped:Connect(function()
            if not P_Enabled then return end
            for player, objs in pairs(P_Objects) do
                if player.Parent then
                    pcall(P_UpdatePlayer, player, objs)
                else
                    P_DestroyObjects(objs)
                    P_Objects[player] = nil
                end
            end
        end)
        Airflow:Notify({ Title = "ESP2", Content = "初始化完成", Type = "Success", Duration = 2 })
    end,
})

T.ESPP:CreateToggle({
    Name = "ESP2 总开关",
    CurrentValue = false,
    Flag = "ESP2Enable",
    Callback = function(s)
        P_Enabled = s
        if not s then
            for _, objs in pairs(P_Objects) do
                for _, obj in pairs(objs) do obj.Visible = false end
            end
        end
    end,
})
T.ESPP:CreateToggle({ Name = "玩家方框", CurrentValue = false, Flag = "ESP2Box", Callback = function(s) P_DrawBox = s end })
T.ESPP:CreateToggle({ Name = "玩家名字", CurrentValue = false, Flag = "ESP2Name", Callback = function(s) P_DrawName = s end })
T.ESPP:CreateToggle({ Name = "玩家距离", CurrentValue = false, Flag = "ESP2Dist", Callback = function(s) P_DrawDistance = s end })
T.ESPP:CreateToggle({ Name = "生命值", CurrentValue = false, Flag = "ESP2HP", Callback = function(s) P_DrawHealth = s end })
T.ESPP:CreateToggle({ Name = "射线 (从屏幕顶部)", CurrentValue = false, Flag = "ESP2Tracer", Callback = function(s) P_DrawTracer = s end })

T.ESPP:CreateSlider({ Name = "最大渲染距离", Range = { 500, 5000 }, Increment = 100, CurrentValue = 1500, Flag = "ESP2MaxD", Callback = function(value) P_MAX_DISTANCE = value end })
T.ESPP:CreateSlider({ Name = "方框大小倍数", Range = { 1.5, 3.0 }, Increment = 0.1, CurrentValue = 2.2, Flag = "ESP2Scale", Callback = function(value) P_BOX_SCALE = value end })
T.ESPP:CreateSlider({ Name = "方框线条粗细", Range = { 1, 5 }, Increment = 1, CurrentValue = 1, Flag = "ESP2Thick", Callback = function(value) P_BOX_THICKNESS = value end })

-- ==================== ESP物品页 ====================
local function addItemESP(targetName, color, label)
    T.wb:CreateToggle({
        Name = label,
        CurrentValue = false,
        Flag = "ItemESP_" .. targetName,
        Callback = function(state)
            if not state then return end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if (obj:IsA("BasePart") or obj:IsA("Model")) and obj.Name == targetName then
                    if not obj:FindFirstChild("ESP_Highlight") then
                        local h = Instance.new("Highlight")
                        h.Name = "ESP_Highlight"
                        h.FillColor = color
                        h.OutlineColor = color
                        h.FillTransparency = 0.2
                        h.OutlineTransparency = 0.05
                        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        h.Parent = obj

                        local attachPart
                        if obj:IsA("BasePart") then
                            attachPart = obj
                        elseif obj:IsA("Model") then
                            attachPart = obj.PrimaryPart
                            if not attachPart then
                                for _, d in ipairs(obj:GetDescendants()) do
                                    if d:IsA("BasePart") then
                                        attachPart = d
                                        break
                                    end
                                end
                            end
                        end

                        if attachPart then
                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = "ESP_Tag"
                            billboard.Size = UDim2.new(0, 200, 0, 40)
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                            billboard.AlwaysOnTop = true
                            billboard.MaxDistance = 0
                            billboard.Adornee = attachPart
                            billboard.Parent = attachPart

                            local nameLbl = Instance.new("TextLabel")
                            nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                            nameLbl.Position = UDim2.new(0, 0, 0, 0)
                            nameLbl.BackgroundTransparency = 1
                            nameLbl.Text = label
                            nameLbl.TextColor3 = color
                            nameLbl.TextScaled = true
                            nameLbl.Font = Enum.Font.GothamBold
                            nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                            nameLbl.TextStrokeTransparency = 0.3
                            nameLbl.Parent = billboard

                            local distLbl = Instance.new("TextLabel")
                            distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                            distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                            distLbl.BackgroundTransparency = 1
                            distLbl.Text = "--m"
                            distLbl.TextColor3 = Color3.new(1, 1, 1)
                            distLbl.TextScaled = true
                            distLbl.Font = Enum.Font.GothamBold
                            distLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
                            distLbl.TextStrokeTransparency = 0.3
                            distLbl.Parent = billboard

                            task.spawn(function()
                                while distLbl.Parent do
                                    local char = LocalPlayer.Character
                                    local root = char and char:FindFirstChild("HumanoidRootPart")
                                    if root and attachPart.Parent then
                                        local d = (root.Position - attachPart.Position).Magnitude
                                        distLbl.Text = string.format("%.1fm", d)
                                    end
                                    task.wait(0.2)
                                end
                            end)
                        end
                    end
                end
            end
        end,
    })
end

addItemESP("MoneyPrinter", Color3.new(0, 0.8, 0.2), "💰 印钞机检测")
addItemESP("Gold Bar", Color3.new(1, 0.8, 0), "🥇 金块")
addItemESP("Bitcoin", Color3.new(1, 0.6, 0), "₿ BTC")
addItemESP("Sapphire", Color3.new(0.6, 0, 1), "💎 紫宝石")
addItemESP("SafeDoor", Color3.new(1, 0.7, 0), "🔐 保险箱")
addItemESP("Ruby", Color3.new(1, 0, 0), "🔴 红宝石")
addItemESP("Ruby Ring", Color3.new(1, 0, 0), "💍 红宝石戒指")
addItemESP("GPU", Color3.new(0, 0.8, 1), "🖥 GPU")
addItemESP("MilitaryChest", Color3.new(0.3, 0.5, 0.2), "🎖 军需箱")
addItemESP("AK-47", Color3.new(1, 0.2, 0), "🔫 AK47")
addItemESP("AUG A1", Color3.new(0.6, 0.2, 1), "🔫 AUG A1")
addItemESP("AWM", Color3.new(0.3, 0.3, 0.3), "🎯 AWM")
addItemESP("M4A1", Color3.new(0, 0.5, 1), "🔫 M4A1")
addItemESP("RPG-7", Color3.new(1, 0.5, 0), "🚀 RPG")
addItemESP("ARX-160", Color3.new(0.2, 0.5, 1), "🔫 ARX-160")

T.wb:CreateToggle({
    Name = "💳 货物卡",
    CurrentValue = false,
    Flag = "CargoCard",
    Callback = function(state)
        if not state then return end
        local cc = workspace.Local and workspace.Local:FindFirstChild("Tools")
        cc = cc and cc:FindFirstChild("Cargo Card")
        if cc and not cc:FindFirstChild("ESP_Highlight") then
            local h = Instance.new("Highlight")
            h.Name = "ESP_Highlight"
            h.FillColor = Color3.new(0.2, 0.4, 1)
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = cc
        end
    end,
})

-- ==================== 删除页 ====================
T.qq:CreateButton({
    Name = "删除炮台",
    Callback = function()
        local l = workspace:FindFirstChild("Local")
        if l then
            local g = l:FindFirstChild("Gizmos")
            if g then
                local t = g:FindFirstChild("Turret")
                if t then t:Destroy() end
            end
        end
    end,
})
T.qq:CreateButton({
    Name = "删除红外线",
    Callback = function()
        local p = workspace:FindFirstChild("Props")
        if p then
            if p:FindFirstChild("Laser") then p.Laser:Destroy() end
            if p:FindFirstChild("LaserAssembly") then p.LaserAssembly:Destroy() end
        end
    end,
})
T.qq:CreateButton({
    Name = "删除红色屏障",
    Callback = function()
        local p = workspace:FindFirstChild("Props")
        if p and p:FindFirstChild("LaserForcefield") then p.LaserForcefield:Destroy() end
    end,
})

-- ==================== 娱乐功能 ====================
local burningActive = false
T.rsao:CreateToggle({
    Name = "🔥 烈焰战士",
    CurrentValue = false,
    Flag = "Burning",
    Callback = function(state)
        burningActive = state
        if burningActive then
            task.spawn(function()
                local Event = game:GetService("ReplicatedStorage").Shared.Core.Network:GetChildren()[75]
                while burningActive do Event:FireServer("burning", true); task.wait(0.2) end
            end)
        end
    end,
})
T.rsao:CreateButton({
    Name = "刷印钞机(踢自己)",
    Callback = function()
        LocalPlayer:Kick("给我重进吧，老弟")
    end,
})
T.rsao:CreateButton({
    Name = "天黑1",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        task.spawn(function()
            while task.wait(0.3) do
                Lighting.ClockTime = 2
                Lighting.Brightness = 0.45
                Lighting.Ambient = Color3.new(0.18,0.18,0.25)
                Lighting.OutdoorAmbient = Color3.new(0.16,0.16,0.22)
            end
        end)
    end,
})
T.rsao:CreateButton({
    Name = "天黑2",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        Lighting.ClockTime = 2; Lighting.Brightness = 0.35
        Lighting.Ambient = Color3.new(0.12,0.12,0.18)
        Lighting.OutdoorAmbient = Color3.new(0.10,0.10,0.15)
    end,
})

-- ==================== 购买页 ====================
T.gm:CreateButton({
    Name = "奥菲当铺循环售卖",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Shared.Core.Network:GetChildren()[144]
        task.spawn(function()
            while task.wait(0.2) do pcall(function() Event:InvokeServer("Ofy") end) end
        end)
    end,
})
T.gm:CreateButton({
    Name = "C4 - 250元",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Shared.Core.Network:GetChildren()[190]
        Event:InvokeServer({
            itemName = "C4", itemType = "Ammo", ammoToBuyIndex = 1,
            categoryName = "Explosives", shopName = "Guns"
        })
    end,
})
T.gm:CreateButton({
    Name = "循环补充弹药",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").Shared.Core.Network:GetChildren()[190]
        task.spawn(function()
            while task.wait(0.2) do pcall(function() Event:InvokeServer({ refillAll = true }) end) end
        end)
    end,
})

-- ==================== 启动通知 ====================
Airflow:Notify({
    Title = "加载完成",
    Content = "港猫的通缉Wanted 已加载！",
    Icon = "check",
    Type = "Success",
    Duration = 5,
})