-- ============================================
-- 增强版反作弊绕过系统 (AntiCheat Bypass Pro)
-- 纯净版 - 已完全移除 AntiAFK 和重生保护
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- 全局工具函数（供所有模块使用）
-- ============================================
local function log(msg)
    print("[AntiCheat] " .. msg)
end

local function safeDisconnect(conn)
    pcall(function() conn:Disconnect() end)
end

local function safeClear(tbl)
    for i = #tbl, 1, -1 do
        safeDisconnect(tbl[i])
        tbl[i] = nil
    end
end

-- ============================================
-- 配置
-- ============================================
local CONFIG = {
    AutoEnable = true,
    BlockKick = true,
    BlockBan = true,
    BlockTeleportKick = true,
    BlockRemoteFlags = true,
    BlockExploitDetected = true,
    ClearBanFlags = true,
    LogInterceptions = true,
}

local AntiCheat = {
    Active = false,
    Connections = {},
    InterceptCount = 0,
    LastIntercept = "",
}

-- ============================================
-- 1. 统一 __namecall Hook（合并 Kick + Remote 拦截）
-- ============================================
local function setupNamecallHook()
    local anticheatKeywords = {
        ["anticheat"] = true,
        ["121"] = true, ["14"] = true, ["429"] = true,
        ["46"] = true, ["772"] = true, ["267"] = true,
        ["91"] = true, ["42"] = true,
    }

    local invokeKeywords = {
        ["anticheatcheck"] = true,
    }

    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            -- === Kick 拦截 ===
            if method == "Kick" then
                if self == LocalPlayer or (typeof(self) == "Instance" and self:IsA("Player") and self == LocalPlayer) then
                    AntiCheat.InterceptCount = AntiCheat.InterceptCount + 1
                    AntiCheat.LastIntercept = "Kick via __namecall"
                    log("🛡️ 拦截 Kick")
                    return nil
                end
            end

            -- === Teleport 拦截 ===
            if CONFIG.BlockTeleportKick then
                if method == "Teleport" or method == "TeleportToPlaceInstance" or method == "TeleportToSpawnByName" then
                    if self == TeleportService then
                        AntiCheat.InterceptCount = AntiCheat.InterceptCount + 1
                        AntiCheat.LastIntercept = "Teleport kick"
                        log("🛡️ 拦截强制传送")
                        return nil
                    end
                end
            end

            -- === Remote 事件拦截 ===
            if method == "FireServer" or method == "InvokeServer" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local shouldBlock = false
                    local blockReason = ""

                    local maxArgs = math.min(#args, 3)
                    for i = 1, maxArgs do
                        local arg = args[i]
                        if type(arg) == "string" then
                            local lower = string.lower(arg)
                            if method == "FireServer" and anticheatKeywords[lower] then
                                shouldBlock = true
                                blockReason = "关键词: " .. arg
                                break
                            end
                            if method == "InvokeServer" and invokeKeywords[lower] then
                                shouldBlock = true
                                blockReason = "Invoke关键词: " .. arg
                                break
                            end
                        end
                        if type(arg) == "number" and (arg == 91 or arg == 42 or arg == 121 or arg == 14) then
                            shouldBlock = true
                            blockReason = "数字代码: " .. tostring(arg)
                            break
                        end
                    end

                    if not shouldBlock then
                        local nameLower = string.lower(self.Name)
                        if anticheatKeywords[nameLower] or invokeKeywords[nameLower] then
                            shouldBlock = true
                            blockReason = "事件名称: " .. self.Name
                        end
                    end

                    if shouldBlock then
                        AntiCheat.InterceptCount = AntiCheat.InterceptCount + 1
                        AntiCheat.LastIntercept = blockReason
                        log("🛡️ 拦截 " .. blockReason)
                        if method == "InvokeServer" then
                            return nil
                        end
                        return nil
                    end
                end
            end

            return oldNamecall(self, ...)
        end))
    end)
end

-- ============================================
-- 2. 直接函数 Hook
-- ============================================
local function setupDirectHooks()
    pcall(function()
        local oldKick = LocalPlayer.Kick
        LocalPlayer.Kick = function(self, reason)
            if self == LocalPlayer then
                AntiCheat.InterceptCount = AntiCheat.InterceptCount + 1
                AntiCheat.LastIntercept = "Direct Kick: " .. tostring(reason)
                log("🛡️ 拦截直接 Kick")
                return nil
            end
            return oldKick(self, reason)
        end
    end)

    pcall(function()
        local oldBanAsync = Players.BanAsync
        Players.BanAsync = function(self, options)
            log("🛡️ 拦截 BanAsync")
            AntiCheat.InterceptCount = AntiCheat.InterceptCount + 1
            return {Success = false}
        end
    end)

    pcall(function()
        local oldTeleport = TeleportService.Teleport
        TeleportService.Teleport = function(self, placeId, player, ...)
            if player == LocalPlayer then
                log("🛡️ 拦截 Teleport")
                return nil
            end
            return oldTeleport(self, placeId, player, ...)
        end

        local oldTeleportToPlace = TeleportService.TeleportToPlaceInstance
        TeleportService.TeleportToPlaceInstance = function(self, placeId, jobId, player, ...)
            if player == LocalPlayer then
                log("🛡️ 拦截 TeleportToPlaceInstance")
                return nil
            end
            return oldTeleportToPlace(self, placeId, jobId, player, ...)
        end
    end)
end

-- ============================================
-- 3. InGameExplorer 清理
-- ============================================
local function setupInGameExplorerCleanup()
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")

        local igeShared = rs:FindFirstChild("InGameExplorer_Shared")
        if igeShared then
            log("🔥 发现 InGameExplorer_Shared 文件夹，正在整个销毁...")
            pcall(function() igeShared:Destroy() end)
            log("🔥 InGameExplorer_Shared 已完全删除")
        end

        local conn = rs.DescendantAdded:Connect(function(child)
            pcall(function()
                if child.Name == "InGameExplorer_Shared" then
                    log("🔥 拦截新创建的 InGameExplorer_Shared，立即销毁")
                    pcall(function() child:Destroy() end)
                end
            end)
        end)
        table.insert(AntiCheat.Connections, conn)

        for _, obj in ipairs(rs:GetDescendants()) do
            local nameLower = string.lower(obj.Name)
            if string.find(nameLower, "ingameexplorer", 1, true) then
                log("🔥 全局扫描发现并销毁: " .. obj.Name)
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

-- ============================================
-- 4. exploitDetected Remote 拦截
-- ============================================
local function setupExploitDetectedHook()
    pcall(function()
        local exploitRemote = nil
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "exploitDetected") then
                local val = rawget(v, "exploitDetected")
                if typeof(val) == "Instance" and val:IsA("RemoteEvent") then
                    exploitRemote = val
                    break
                end
            end
        end
        if exploitRemote then
            log("🔍 发现 exploitDetected")
            exploitRemote.FireServer = function(self, ...)
                log("🛡️ 拦截 exploitDetected")
                return nil
            end
        end
    end)
end

-- ============================================
-- 5. 主开关
-- ============================================
function AntiCheat.Enable()
    if AntiCheat.Active then
        log("已经处于激活状态")
        return
    end

    AntiCheat.Active = true
    log("🚀 正在启动增强版反作弊绕过...")

    setupNamecallHook()
    setupDirectHooks()
    setupInGameExplorerCleanup()
    setupExploitDetectedHook()

    log("✅ 所有绕过模块已加载")
    log("📊 统计: 拦截次数 " .. AntiCheat.InterceptCount)
end

function AntiCheat.Disable()
    if not AntiCheat.Active then return end
    AntiCheat.Active = false
    safeClear(AntiCheat.Connections)
    log("⛔ 反作弊绕过已关闭")
end

function AntiCheat.Status()
    return {
        Active = AntiCheat.Active,
        InterceptCount = AntiCheat.InterceptCount,
        LastIntercept = AntiCheat.LastIntercept,
    }
end

-- ============================================
-- 6. 自动激活（只执行一次）
-- ============================================
if CONFIG.AutoEnable then
    local success, err = pcall(function()
        AntiCheat.Enable()
    end)
    if success then
        log("✅ 反作弊绕过系统已自动激活")
    else
        log("⚠️ 自动激活失败: " .. tostring(err))
        task.delay(0.5, function()
            pcall(function()
                if not AntiCheat.Active then
                    AntiCheat.Enable()
                    log("✅ 反作弊绕过系统延迟激活成功")
                end
            end)
        end)
    end
end

-- ============================================
-- 导出到全局环境
-- ============================================
_G.AntiCheat = AntiCheat
_G.ACBypass = AntiCheat
getgenv().AntiCheat = AntiCheat
getgenv().ACBypass = AntiCheat

if AntiCheat.Active then
    log("🛡️ 系统状态: 已激活 | 拦截器就绪")
else
    log("⚠️ 系统状态: 未激活 | 请手动执行 AntiCheat.Enable()")
end

-- ============================================
-- 移动端移动修复模块 (Mobile Movement Fix)
-- ============================================
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local MovementFix = {
    Active = true,
    Connection = nil,
    LastJumpTime = 0,
}

function MovementFix.Start()
    if MovementFix.Connection then return end

    MovementFix.Connection = RunService.Heartbeat:Connect(function()
        if not MovementFix.Active then return end

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            if humanoid.PlatformStand then
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end

            if humanoid.Sit then
                local seat = humanoid.SeatPart
                if not seat or not seat:IsDescendantOf(workspace) then
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end

            if humanoid.WalkSpeed <= 0 and not humanoid.Sit then
                humanoid.WalkSpeed = 16
            end
            if humanoid.JumpPower <= 0 then
                humanoid.JumpPower = 50
            end

            local currentState = humanoid:GetState()
            if currentState == Enum.HumanoidStateType.Physics or 
               currentState == Enum.HumanoidStateType.None or
               currentState == Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end)

    log("[MovementFix] 移动端移动修复已启动")
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.PlatformStanding or
           newState == Enum.HumanoidStateType.Physics then
            task.delay(0.1, function()
                pcall(function()
                    if humanoid and humanoid.PlatformStand then
                        humanoid.PlatformStand = false
                        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    end
                end)
            end)
        end
    end)

    if IsMobile then
        UserInputService.TouchEnded:Connect(function()
            task.delay(0.05, function()
                pcall(function()
                    if humanoid and humanoid.PlatformStand then
                        humanoid.PlatformStand = false
                    end
                end)
            end)
        end)
    end
end)

UserInputService.JumpRequest:Connect(function()
    MovementFix.LastJumpTime = tick()
    task.delay(0.3, function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            if humanoid.PlatformStand or (humanoid.Sit and not humanoid.SeatPart) then
                humanoid.PlatformStand = false
                humanoid.Sit = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                log("[MovementFix] 跳跃后修复了卡住的移动状态")
            end
        end)
    end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
        MovementFix.LastJumpTime = tick()
        task.delay(0.3, function()
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end

                if humanoid.PlatformStand or (humanoid.Sit and not humanoid.SeatPart) then
                    humanoid.PlatformStand = false
                    humanoid.Sit = false
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end
            end)
        end)
    end
end)

MovementFix.Start()

_G.MovementFix = MovementFix
getgenv().MovementFix = MovementFix

log("🦵 移动修复模块已加载 | 解决跳跃后腿瘸问题")

-- ============================================
-- 【后执行】零度网络 三角洲行动UI大厅
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/yuihghghg/RJ/refs/heads/main/ui.lua"))()

WindUI:Notify({
    Title = "作者飞机号",
    Content = "@you25801",
    Icon = "circle-user-round",
    Duration = 15,
})
WindUI:Notify({
    Title = "反作弊问题",
    Content = "玩家重生时角色会卡死，无法更换队伍，无法远程购买",
    Icon = "",
    Duration = 20,
})
WindUI:Notify({
    Title = "Hello, user",
    Content = "Ifyouhaveanyquestions,pleasesendthem bycable.",
    Icon = "circle-user-round",
    Duration = 10,
})
-- ==================== 自定义三角洲行动风格主题（精确覆盖所有文字） ====================
local techGreen = Color3.fromRGB(0, 255, 160)   -- 科技绿
local white = Color3.fromRGB(245, 248, 255)
local lightGray = Color3.fromRGB(175, 185, 200)
-- 创建新主题，明确指定每个文字属性
WindUI:AddTheme({
    Name = "DeltaForce",
    -- 大标题（窗口标题、作者、标签页标题）
    WindowTopbarTitle = techGreen,
    WindowTopbarAuthor = techGreen,
    TabTitle = techGreen,
    -- 小标题（控件标题、按钮文字、弹窗标题）
    ElementTitle = white,
    ButtonText = white,
    PopupTitle = white,
    DialogTitle = white,
    -- 描述文字（灰色）
    ElementDesc = lightGray,
    PopupContent = lightGray,
    DialogContent = lightGray,
    -- 占位符（科技绿，保持风格）
    PlaceholderText = techGreen,
    -- 图标（科技绿）
    Icon = techGreen,
    -- 其他（可选）
    TooltipText = white,
    TooltipSecondaryText = white,
})
WindUI:SetTheme("DeltaForce")
-- 获取服务
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
-- 创建主窗口
local Window = WindUI:CreateWindow({
    Title = "San Ao圣奥里",
     Author = "作者港猫",
    Folder = "MyHub",
    Transparent = true, 
    Theme = "DeltaForce",
    SideBarWidth = 130,
    HideSearchBar = false, -- 显示侧边栏搜索框
    ScrollBarEnabled = true,
    Background = "",
    BackgroundImageTransparency = 0.9,
    User = { Enabled = true },
    ToggleKey = Enum.KeyCode.F,
})
-- 输出确认
print("窗口标题应为绿色，控件标题应为白色")
local Tabs = {
    raogo = Window:Tab({ Title = "绕过反作弊", Icon = "rbxassetid://7733655755" }),
    zho = Window:Tab({ Title = "玩家", Icon = "rbxassetid://7743875962" }),
    sf = Window:Tab({ Title = "甩飞", Icon = "rbxassetid://7743871002" }),
    zy = Window:Tab({ Title = "ESP", Icon = "rbxassetid://97734789454128" }),
    xz = Window:Tab({ Title = "车辆设置亚洲车王", Icon = "rbxassetid://7733708835" }),
    wz = Window:Tab({ Title = "传送", Icon = "rbxassetid://7733992789" }),
    qq = Window:Tab({ Title = "黑市商店", Icon = "rbxassetid://74658309187754" }),
    qiang = Window:Tab({ Title = "枪店", Icon = "rbxassetid://74658309187754" }),
    zd = Window:Tab({ Title = "战斗", Icon = "rbxassetid://7733992469" }),
    bot = Window:Tab({ Title = "刷钱", Icon = "rbxassetid://7733770599" }),
    szx = Window:Tab({ Title = "其他的", Icon = "rbxassetid://7733938136" }),   
}

-- 工具函数
local function getCharacter()
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        return LocalPlayer.Character
    end
    return nil
end
-- ==================== 无限跳（JumpRequest 事件） ====================
local isInfiniteJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if isInfiniteJumpEnabled then
        local character = getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-----raogo----
Tabs.raogo:Button({
    Title = "绕过1",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/raogo/refs/heads/main/2ggui.lua"))()
    end
})
Tabs.raogo:Button({
    Title = "绕过2",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/raogo/refs/heads/main/3ggui.lua"))()
    end
})
Tabs.raogo:Button({
    Title = "绕过3",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/raogo/refs/heads/main/%E5%8F%8D%E7%BB%95%E8%BF%87UI%E3%80%82.lua"))()
    end
})

Tabs.raogo:Button({
    Title = "绕过4",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/raogo/refs/heads/main/sloa.lua"))()
    end
})
Tabs.qiang:Button({
    Title = "枪店",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-323.0765075683594, 3.3417789936065674, 45.167503356933594)
    end
})
Tabs.qq:Button({
    Title = "黑市传送购买功能",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1040.427001953125, -22.734272003173828, 901.8596801757812)
    end
})
-- ==================== 通用标签页 ====================
Tabs.zho:Slider({
    Title = "行走速度（默认16）",
    Desc = "调整角色的行走速度",
    Value = { Min = 1, Max = 400, Default = 16 },
    Step = 1,
    IsTextbox = true,
    Callback = function(value)
        local char = getCharacter()
        if char then char.Humanoid.WalkSpeed = value end
    end
})
Tabs.zho:Slider({
    Title = "设置缩放焦距(正常70)",
    Desc = "",
    Value = { Min = 0.1, Max = 250, Default = 70 },
    Step = 0.1,
    IsTextbox = true,
    Callback = function(fieldOfView)
        workspace.CurrentCamera.FieldOfView = fieldOfView
    end
})
-- 无限跳开关
Tabs.zho:Toggle({
    Title = "无限跳",
    Desc = "",
    Value = false,
    Callback = function(state)
        isInfiniteJumpEnabled = state
    end
})
local ProximityPromptService = game:GetService("ProximityPromptService")
local promptHoldFix = false
local promptConn = nil

local function PromptFixOn()
    promptHoldFix = true
    promptConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        if prompt and prompt:IsA("ProximityPrompt") then
            prompt.HoldDuration = 0
        end
    end)
end

local function PromptFixOff()
    promptHoldFix = false
    if promptConn then
        promptConn:Disconnect()
        promptConn = nil
    end
end

-- WindUI开关（直接粘贴到你的Tabs.zho分组内）
Tabs.zho:Toggle({
    Title = "快速互动",
    Default = false,
    Callback = function(state)
        if state then
            PromptFixOn()
        else
            PromptFixOff()
        end
    end
})
Tabs.zho:Toggle({
    Title = "锁定体力",
    Callback = function()
        local player = game.Players.LocalPlayer
local scripts = player.PlayerScripts:GetDescendants()
for _, obj in ipairs(scripts) do
    if obj:IsA("ModuleScript") and obj.Name == "Character" then
        local success, mod = pcall(require, obj)
        if success and type(mod) == "table" and mod.changeStamina then
            local old = mod.changeStamina
            mod.changeStamina = function(amount)
                if amount < 0 then return end
                return old(amount)
            end
            print("✅ Stamina hack installed!")
            break
        end
    end
end
    end
})
Tabs.zho:Button({
    Title = "锁定饥饿",
    Callback = function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("PlayerEvent")

local targetValue = 100  -- 想锁定的数值，改成0就是锁0

while true do
	local args = {"setStaminaOrFood", "food", targetValue}
	PlayerEvent:FireServer(unpack(args))
	task.wait(0.1)  
end
    end
})
Tabs.zho:Button({
    Title = "穿墙GUI",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sandakovandrej23-art/ROBLOXNOCLIPGUI/refs/heads/main/Noclipgui.lua"))()
    end
})
Tabs.zho:Button({
    Title = "快速互动",
    Callback = function()
        game.ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
            prompt.HoldDuration = 0
        end)
    end
})
Tabs.zho:Button({
    Title = "飞速度90",
    Callback = function()
        local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 90

local character
local root

local function loadCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	root = character:WaitForChild("HumanoidRootPart")
end

loadCharacter()

player.CharacterAdded:Connect(loadCharacter)


-- 创建GUI（加保护）
local gui = Instance.new("ScreenGui")
gui.Name = "FlyCarUI"
gui.Parent = player:WaitForChild("PlayerGui")  -- 改用WaitForChild确保存在
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling  -- 避免被覆盖

-- 检查GUI是否成功创建
if not gui.Parent then
	warn("GUI创建失败，尝试备用方案")
	gui.Parent = game:GetService("CoreGui")  -- 备用方案
end

local button = Instance.new("TextButton")
button.Size = UDim2.new(0,70,0,70)
button.Position = UDim2.new(0.5,-35,0.75,0)
button.Text = "飞开"
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
button.Parent = gui

-- 确保按钮可见
button.BackgroundTransparency = 0
button.TextTransparency = 0
button.Visible = true

local corner = Instance.new("UICorner")
corner.Parent = button

-- 加一个边框让按钮更明显
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 2
stroke.Parent = button

print("飞车UI已创建！位置在屏幕中央偏下")  -- 控制台提示


-- === 拖动功能 ===
local isDragging = false
local dragStartPos = nil
local startInputPos = nil
local currentDragInput = nil

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		
		isDragging = true
		dragStartPos = button.Position
		startInputPos = input.Position
		currentDragInput = input
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				isDragging = false
				currentDragInput = nil
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if isDragging and currentDragInput then
		if input.UserInputType == currentDragInput.UserInputType and
		   (input.UserInputType == Enum.UserInputType.MouseMovement or
		    input.UserInputType == Enum.UserInputType.Touch) then
			
			local delta = input.Position - startInputPos
			local newX = dragStartPos.X.Offset + delta.X
			local newY = dragStartPos.Y.Offset + delta.Y
			
			button.Position = UDim2.new(
				dragStartPos.X.Scale,
				newX,
				dragStartPos.Y.Scale,
				newY
			)
		end
	end
end)


local velocity

local clickStartTime = 0
local clickStartPos = nil

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		clickStartTime = tick()
		clickStartPos = input.Position
	end
end)

button.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or 
	   input.UserInputType == Enum.UserInputType.Touch then
		
		local elapsed = tick() - clickStartTime
		local distance = (input.Position - clickStartPos).Magnitude
		
		if elapsed < 0.3 and distance < 20 then
			flying = not flying

			if flying then
				button.Text = "停"
				button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)

				velocity = Instance.new("BodyVelocity")
				velocity.MaxForce = Vector3.new(
					math.huge,
					math.huge,
					math.huge
				)
				velocity.Parent = root
			else
				button.Text = "开始"
				button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

				if velocity then
					velocity:Destroy()
					velocity = nil
				end
			end
		end
	end
end)


RunService.RenderStepped:Connect(function()
	if flying and velocity and root then
		local direction = camera.CFrame.LookVector
		velocity.Velocity = direction * speed
	end
end)
    end
})
Tabs.zho:Button({
    Title = "定",
    Callback = function()
        -- 空中定住 + 可拖动GUI（缩小UI版本）
-- LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local freeze = false
local lockY = nil
local character
local root
local function LoadCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	root = character:WaitForChild("HumanoidRootPart")
end
LoadCharacter()
player.CharacterAdded:Connect(function()
	task.wait(1)
	LoadCharacter()
end)
-- 创建UI
local gui = Instance.new("ScreenGui")
gui.Name = "AirFreezeUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
-- 缩小窗口尺寸 原240,140 → 140,90
local main = Instance.new("Frame")
main.Size = UDim2.new(0,140,0,90)
main.Position = UDim2.new(0.5,-70,0.65,0)
main.BackgroundColor3 = Color3.fromRGB(25,25,30)
main.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = main
-- 标题字号缩小
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,26)
title.BackgroundTransparency = 1
title.Text = "定"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 16
title.Parent = main
-- 缩小开关按钮 原170,45 → 100,32，位置居中适配
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0,100,0,32)
toggle.Position = UDim2.new(0.5,-50,0.48,0)
toggle.BackgroundColor3 = Color3.fromRGB(0,170,255)
toggle.Text = "开启"
toggle.TextColor3 = Color3.new(1,1,1)
toggle.TextSize = 14
toggle.Parent = main
local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0,8)
tc.Parent = toggle
-- 拖动功能（逻辑未改动）
local dragging = false
local dragStart
local startPos
main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
main.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch then
		input.Changed:Connect(function()
			if dragging then
				local delta = input.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
	end
end)
-- 开关切换逻辑不变
toggle.MouseButton1Click:Connect(function()
	freeze = not freeze
	if freeze then
		toggle.Text = "关闭"
		toggle.BackgroundColor3 = Color3.fromRGB(255,70,70)
		if root then
			lockY = root.Position.Y
		end
	else
		toggle.Text = "开启"
		toggle.BackgroundColor3 = Color3.fromRGB(0,170,255)
		lockY = nil
	end
end)
-- 空中锁定逻辑不变
RunService.Heartbeat:Connect(function()
	if freeze and root and lockY then
		local pos = root.Position
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame =
			CFrame.new(
				pos.X,
				lockY,
				pos.Z
			)
			*
			root.CFrame.Rotation
	end
end)

    end
})
-- =================== 状态变量 ===================
local FlingLoop = false
local Flinging = false
local AlreadyNotified = {}
local TP_SelectedPlayer = nil  -- 选中的目标
local SelectedTarget = nil
-- =================== 甩飞核心函数 ===================
local function SkidFling(TargetPlayer)
    if not TargetPlayer or TargetPlayer == LocalPlayer then return end
    if Flinging then return end
    Flinging = true
    local Player = LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not (Character and Humanoid and RootPart and TCharacter) then
        Flinging = false
        return
    end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    local Camera = workspace.CurrentCamera
    -- 监听自身重生
    local Dead = false
    local DeadConn
    DeadConn = Player.CharacterAdded:Connect(function()
        Dead = true
        if DeadConn then
            DeadConn:Disconnect()
            DeadConn = nil
        end
    end)
    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    if Camera then
        if THead then
            Camera.CameraSubject = THead
        elseif Handle then
            Camera.CameraSubject = Handle
        elseif THumanoid then
            Camera.CameraSubject = THumanoid
        end
    end
    local function FPos(BasePart, Pos, Ang)
        if Dead then return end
        if not BasePart or not BasePart.Parent then return end
        if not RootPart or not RootPart.Parent then return end
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end
    local function SFBasePart(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if Dead then break end
            if not BasePart or not BasePart.Parent then break end
            if not RootPart or not RootPart.Parent then break end
            if not TRootPart or not TRootPart.Parent then break end
            if not THumanoid or THumanoid.Health <= 0 then break end
            if BasePart.Velocity.Magnitude > 1 then
                Angle = Angle + 100
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until BasePart.Velocity.Magnitude > 500
            or not BasePart.Parent
            or Dead
            or tick() > Time + TimeToWait
    end
    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8,9e8,9e8)
    BV.MaxForce = Vector3.new(1/0,1/0,1/0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
    if not Dead then
        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        end
    end
    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
    if Camera then
        local newChar = Player.Character
        local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
        if newHum then
            Camera.CameraSubject = newHum
        end
    end
    if not Dead and getgenv().OldPos then
        local newChar = Player.Character
        local newRoot = newChar and newChar:FindFirstChild("HumanoidRootPart")
        local newHum = newChar and newChar:FindFirstChildOfClass("Humanoid")
        if newRoot and newHum then
            repeat
                newRoot.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                newChar:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                newHum:ChangeState("GettingUp")
                for _, x in ipairs(newChar:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity = Vector3.zero
                        x.RotVelocity = Vector3.zero
                    end
                end
                task.wait()
            until (newRoot.Position - getgenv().OldPos.Position).Magnitude < 25
        end
    end
    if DeadConn then
        DeadConn:Disconnect()
        DeadConn = nil
    end
    Flinging = false
end
-- =================== 目标监控 ===================
local function MonitorTarget(target)
    if not target then return end
    if not FlingLoop then return end
    if not AlreadyNotified[target] then
        AlreadyNotified[target] = {
            dead = false,
            left = false
        }
    end
    local state = AlreadyNotified[target]
    task.spawn(function()
        while true do
            if not FlingLoop then break end
            if not target or not target.Parent then
                if not state.left then
                    state.left = true
                    if WindUI then
                        WindUI:Notify({
                            Title = "目标失效",
                            Content = "玩家已退出，无法继续甩飞",
                            Duration = 3,
                            Icon = "error"
                        })
                    end
                end
                break
            end
            local char = target.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hum or hum.Health <= 0 then
                if not state.dead then
                    state.dead = true
                    if WindUI then
                        WindUI:Notify({
                            Title = "目标失效",
                            Content = target.Name .. " 已死亡，无法继续甩飞",
                            Duration = 3,
                            Icon = "error"
                        })
                    end
                end
                repeat
                    task.wait(0.5)
                    char = target.Character
                    hum = char and char:FindFirstChildOfClass("Humanoid")
                until hum and hum.Health > 0 or not target.Parent
                if hum and hum.Health > 0 then
                    state.dead = false
                end
            end
            task.wait(0.5)
        end
    end)
end
-- =================== 循环甩飞 ===================
local function StartFlingLoop()
    if FlingLoop then return end
    FlingLoop = true
    AlreadyNotified = {}
    task.spawn(function()
        while FlingLoop do
            local selfChar = LocalPlayer.Character
            local selfHum = selfChar and selfChar:FindFirstChildOfClass("Humanoid")
            local selfRoot = selfChar and selfChar:FindFirstChild("HumanoidRootPart")
            if not selfChar or not selfHum or not selfRoot or selfHum.Health <= 0 then
                task.wait(0.5)
                continue
            end
            -- ================= 所有人模式 =================
            if TP_SelectedPlayer == "ALL" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if not FlingLoop then break end
                    local c = LocalPlayer.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if not c or not h or h.Health <= 0 then break end
                    if p ~= LocalPlayer then
                        local char = p.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if not AlreadyNotified[p] then
                                MonitorTarget(p)
                            end
                            local t1 = tick()
                            repeat task.wait() until not Flinging or tick() - t1 > 3
                            SkidFling(p)
                            local t2 = tick()
                            repeat task.wait() until not Flinging or tick() - t2 > 3
                            task.wait(0.1)
                        end
                    end
                end
            -- ================= 单人模式 =================
            else
                local target = TP_SelectedPlayer or SelectedTarget
                if target then
                    if not AlreadyNotified[target] then
                        MonitorTarget(target)
                    end
                    local t1 = tick()
                    repeat task.wait() until not Flinging or tick() - t1 > 3
                    SkidFling(target)
                    local t2 = tick()
                    repeat task.wait() until not Flinging or tick() - t2 > 3
                end
            end
            task.wait(0.2)
        end
    end)
end
local function StopFlingLoop()
    FlingLoop = false
end
local function CreateFlingUI()
    task.wait(0.3)
    if not Tabs or not Tabs.sf then return end
    local Tab = Tabs.sf

    Tab:Paragraph({
        Title = "警告",
        Desc = "不要在甩飞的时候重生可能报错"
    })

    local TP_PlayerList = {}
    local TP_Dropdown = nil

    local function CreateTPDropdown(lastSelectedName)
        TP_PlayerList = {"所有人"}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer then
                table.insert(TP_PlayerList, p.Name)
            end
        end
        if TP_Dropdown then
            TP_Dropdown:Refresh(TP_PlayerList, lastSelectedName)
        else
            TP_Dropdown = Tabs.sf:Dropdown({
                Title = "选择玩家",
                Values = TP_PlayerList,
                Default = lastSelectedName,
                Callback = function(v)
                    if typeof(v) == "table" then
                        v = v.Value or v[1]
                    end
                    if not v then return end
                    if v == "所有人" then
                        TP_SelectedPlayer = "ALL"
                        SelectedTarget = nil
                        return
                    end
                    local plr = game:GetService("Players"):FindFirstChild(v)
                    if plr then
                        TP_SelectedPlayer = plr
                        SelectedTarget = plr
                    end
                end
            })
        end
    end

    local function TP_RefreshPlayerList()
        local lastSelectedName = nil
        if typeof(TP_SelectedPlayer) == "Instance" then
            lastSelectedName = TP_SelectedPlayer.Name
        elseif TP_SelectedPlayer == "ALL" then
            lastSelectedName = "所有人"
        end
        CreateTPDropdown(lastSelectedName)
    end

    Tabs.sf:Button({
        Title = "刷新玩家列表",
        Callback = function()
            TP_RefreshPlayerList()
        end
    })

    Tabs.sf:Button({
        Title = "甩飞一次",
        Callback = function()
            if TP_SelectedPlayer == "ALL" then
                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                    if p ~= game:GetService("Players").LocalPlayer then
                        SkidFling(p)
                        repeat task.wait() until not Flinging
                        task.wait(0.1)
                    end
                end
            else
                local target = TP_SelectedPlayer or SelectedTarget
                if target then
                    SkidFling(target)
                end
            end
        end
    })

    local LoopToggle = Tabs.sf:Toggle({
        Title = "循环甩飞",
        Default = false,
        Callback = function(v)
            if v then
                StartFlingLoop()
            else
                StopFlingLoop()
            end
        end
    })

    task.delay(1, function()
        TP_RefreshPlayerList()
    end)

    game:GetService("Players").PlayerAdded:Connect(function()
        TP_RefreshPlayerList()
    end)
    game:GetService("Players").PlayerRemoving:Connect(function()
        TP_RefreshPlayerList()
    end)

    return {
        Toggle = LoopToggle,
        RefreshList = TP_RefreshPlayerList,
        SkidFling = SkidFling,
        StartLoop = StartFlingLoop,
        StopLoop = StopFlingLoop
    }
end

--延迟执行
task.wait(0.8)
CreateFlingUI()

----=======ESP=======-----
local zySec1 = Tabs.zy:Section({ Title = "ATM和玩家ESP1" })
zySec1:Button({
    Title = "玩家ESP",
    Callback = function()
        local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local ESP = {}

local function removeESP(player)
	if ESP[player] then
		for _, v in pairs(ESP[player]) do
			if v and v.Parent then
				v:Destroy()
			end
		end
		ESP[player] = nil
	end
end

local function createESP(player)
	if player == LocalPlayer then
		return
	end

	local function setup(character)
		removeESP(player)

		local humanoid = character:WaitForChild("Humanoid", 5)
		local root = character:WaitForChild("HumanoidRootPart", 5)
		local head = character:WaitForChild("Head", 5)

		if not humanoid or not root or not head then
			return
		end

		local objects = {}
		ESP[player] = objects

		-- 方框
		local highlight = Instance.new("Highlight")
		highlight.Name = "PlayerESP"
		highlight.Adornee = character
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillTransparency = 0.8
		highlight.OutlineTransparency = 0

		local teamColor = player.TeamColor.Color
		highlight.FillColor = teamColor
		highlight.OutlineColor = teamColor
		highlight.Parent = character

		table.insert(objects, highlight)

		-- 名字、距离、血量
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "ESPInfo"
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(180, 65)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		table.insert(objects, billboard)

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextColor3 = teamColor
		text.TextStrokeTransparency = 0
		text.Font = Enum.Font.GothamBold
		text.TextSize = 14
		text.Parent = billboard

		table.insert(objects, text)

		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not character.Parent then
				connection:Disconnect()
				return
			end

			local myCharacter = LocalPlayer.Character
			local myRoot = myCharacter and
				myCharacter:FindFirstChild("HumanoidRootPart")

			local distance = 0

			if myRoot then
				distance = (root.Position - myRoot.Position).Magnitude
			end

			local health = math.max(0, humanoid.Health)
			local maxHealth = math.max(1, humanoid.MaxHealth)

			text.Text = string.format(
				"%s\n距离: %dm\n血量: %d/%d",
				player.DisplayName,
				math.floor(distance),
				math.floor(health),
				math.floor(maxHealth)
			)
		end)

		table.insert(objects, {
			Destroy = function()
				if connection then
					connection:Disconnect()
				end
			end
		})
	end

	if player.Character then
		task.spawn(setup, player.Character)
	end

	player.CharacterAdded:Connect(function(character)
		task.spawn(setup, character)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	createESP(player)
end

Players.PlayerAdded:Connect(createESP)

Players.PlayerRemoving:Connect(removeESP)
    end
})
-----------ATM🏧----------
zySec1:Button({
    Title = "ATMESP",
    Callback = function()
        -- ====== 获取Interactive容器 ======
local world = workspace.World
local interactive = world and world:FindFirstChild("Interactive")

if not interactive then
    warn("Interactive不存在")
    return
end

-- ====== 创建ATM专属ESP（距离显示优化） ======
local function createATMESP(obj)
    -- 避免重复添加
    if obj:FindFirstChild("ESP_Highlight") then
        return
    end
    
    -- 高亮效果
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.new(0, 1, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.new(1, 0.8, 0)
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = obj
    
    -- ATM标签
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Tag"
    billboard.Size = UDim2.new(0, 150, 0, 50)              -- 高度增加容纳距离
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 800
    billboard.Parent = obj
    
    -- 名称（上半部分）
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)               -- 占一半高度
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = " " .. obj.Name
    textLabel.TextColor3 = Color3.new(0, 1, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.3
    textLabel.Parent = billboard
    
    -- 距离显示（下半部分，更大更醒目）
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)               -- 占一半高度
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)           -- 从中间开始
    distLabel.BackgroundTransparency = 1
    distLabel.Text = " --m"
    distLabel.TextColor3 = Color3.new(1, 1, 0)             -- 黄色更醒目
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.Parent = billboard
    
    -- 更新距离
    local player = game.Players.LocalPlayer
    if player and player.Character then
        game:GetService("RunService").Heartbeat:Connect(function()
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and obj.PrimaryPart then
                local dist = (root.Position - obj.PrimaryPart.Position).Magnitude
                distLabel.Text = string.format(" %.1fm", dist)
            elseif root then
                -- 如果没有PrimaryPart，尝试找任意部件
                local parts = obj:GetDescendants()
                for _, part in ipairs(parts) do
                    if part:IsA("BasePart") then
                        local dist = (root.Position - part.Position).Magnitude
                        distLabel.Text = string.format(" %.1fm", dist)
                        break
                    end
                end
            end
        end)
    end
    
    print("✅ ATM已标记: " .. obj.Name)
end

-- ====== 筛选ATM ======
local function scanForATM()
    for _, obj in ipairs(interactive:GetChildren()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if string.find(string.upper(obj.Name), "ATM") then
                createATMESP(obj)
            end
        end
    end
end

-- 执行扫描
scanForATM()

-- ====== 监听新增物体 ======
interactive.ChildAdded:Connect(function(newObj)
    task.wait(0.1)
    if newObj:IsA("Model") or newObj:IsA("BasePart") then
        if string.find(string.upper(newObj.Name), "ATM") then
            createATMESP(newObj)
        end
    end
end)

print("✅ ATM透视已启动（距离显示已优化）")
    end
})
local zySec2 = Tabs.zy:Section({ Title = "ESP2" })
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

ESP_Config = {
    EnableESP = false,
    ShowBox = true,
    ShowHealth = true,
    ShowName = true,
    ShowDistance = true,
    ShowTracer = false,
    ShowSkeleton = false,
    ShowWeapon = false,
    WallHack = false,
    TeamCheck = false,
    MaxDrawDistance = 350,
    BoxThickness = 1,
    TracerThickness = 1,
    SkeletonThickness = 2,
    EnemyColor = Color3.new(1, 0.3, 0.3),
    TeammateColor = Color3.new(0.3, 1, 0.3),
    NPCColor = Color3.new(1, 1, 0.2),
    BoxColor = Color3.new(1, 1, 1),
    TracerColor = Color3.new(1, 0, 0),
    SkeletonColor = Color3.new(0.2, 0.8, 1),
    HealthBarColor = Color3.new(0, 1, 0),
}

-- Drawing API ESP组件表
local ESPComponents = {}

-- 创建单个玩家的Drawing ESP
local function createESP(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = ESP_Config.BoxColor
    box.Thickness = ESP_Config.BoxThickness
    box.Filled = false

    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color = ESP_Config.HealthBarColor
    healthBar.Thickness = 1
    healthBar.Filled = true

    local healthBarBackground = Drawing.new("Square")
    healthBarBackground.Visible = false
    healthBarBackground.Color = Color3.new(0, 0, 0)
    healthBarBackground.Transparency = 0.5
    healthBarBackground.Thickness = 1
    healthBarBackground.Filled = true

    local healthBarBorder = Drawing.new("Square")
    healthBarBorder.Visible = false
    healthBarBorder.Color = Color3.new(1, 1, 1)
    healthBarBorder.Thickness = 1
    healthBarBorder.Filled = false

    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = Color3.new(1, 1, 1)
    healthText.Size = 14
    healthText.Font = Drawing.Fonts.Monospace
    healthText.Outline = true
    healthText.OutlineColor = Color3.new(0, 0, 0)

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.new(1, 1, 1)
    nameText.Size = 16
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)

    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Color = Color3.new(1, 1, 0)
    distanceText.Size = 14
    distanceText.Font = Drawing.Fonts.Monospace
    distanceText.Outline = true
    distanceText.OutlineColor = Color3.new(0, 0, 0)

    local weaponText = Drawing.new("Text")
    weaponText.Visible = false
    weaponText.Color = Color3.new(1, 0.5, 0)
    weaponText.Size = 14
    weaponText.Font = Drawing.Fonts.Monospace
    weaponText.Outline = true
    weaponText.OutlineColor = Color3.new(0, 0, 0)

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = ESP_Config.TracerColor
    tracer.Thickness = ESP_Config.TracerThickness

    -- 骨架线条与头部圆点
    local skeletonLines = {}
    local skeletonPoints = {}

    for i = 1, 15 do
        skeletonLines[i] = Drawing.new("Line")
        skeletonLines[i].Visible = false
        skeletonLines[i].Color = ESP_Config.SkeletonColor
        skeletonLines[i].Thickness = ESP_Config.SkeletonThickness
    end

    skeletonPoints["Head"] = Drawing.new("Circle")
    skeletonPoints["Head"].Visible = false
    skeletonPoints["Head"].Color = Color3.new(1, 0.5, 0)
    skeletonPoints["Head"].Thickness = 2
    skeletonPoints["Head"].Filled = true
    skeletonPoints["Head"].Radius = 4

    local lastHealth = 100
    local healthChangeTime = 0
    local smoothHealth = 100

    ESPComponents[player] = {
        box = box,
        healthBar = healthBar,
        healthBarBackground = healthBarBackground,
        healthBarBorder = healthBarBorder,
        healthText = healthText,
        nameText = nameText,
        distanceText = distanceText,
        weaponText = weaponText,
        tracer = tracer,
        skeletonLines = skeletonLines,
        skeletonPoints = skeletonPoints
    }

    local function hideAll()
        box.Visible = false
        healthBar.Visible = false
        healthBarBackground.Visible = false
        healthBarBorder.Visible = false
        healthText.Visible = false
        nameText.Visible = false
        distanceText.Visible = false
        weaponText.Visible = false
        tracer.Visible = false
        for _, line in pairs(skeletonLines) do
            line.Visible = false
        end
        for _, point in pairs(skeletonPoints) do
            point.Visible = false
        end
    end

    RunService.RenderStepped:Connect(function()
        if not ESP_Config.EnableESP then
            hideAll()
            return
        end
        if not player.Character
            or not player.Character:FindFirstChild("HumanoidRootPart")
            or not player.Character:FindFirstChild("Humanoid")
            or player == LocalPlayer then
            hideAll()
            return
        end

        -- 队友过滤
        if ESP_Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
            hideAll()
            return
        end

        local character = player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")

        if not rootPart or not humanoid or humanoid.Health <= 0 then
            hideAll()
            return
        end

        local dist = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if dist > ESP_Config.MaxDrawDistance then
            hideAll()
            return
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local headPos, _ = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
        local legPos, _ = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        -- 判断颜色 (队友/敌人)
        local color = ESP_Config.EnemyColor
        if ESP_Config.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
            color = ESP_Config.TeammateColor
        end

        -- 武器名称
        local weaponName = "无武器"
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                weaponName = tool.Name
                break
            end
        end

        -- 方框透视
        if ESP_Config.ShowBox and onScreen then
            box.Size = Vector2.new(1000 / rootPos.Z, headPos.Y - legPos.Y)
            box.Position = Vector2.new(rootPos.X - box.Size.X / 2, rootPos.Y - box.Size.Y / 2)
            box.Visible = true
            box.Color = ESP_Config.BoxColor
            box.Thickness = ESP_Config.BoxThickness
        else
            box.Visible = false
        end

        -- 血量条
        if ESP_Config.ShowHealth and onScreen then
            local healthPercentage = humanoid.Health / humanoid.MaxHealth
            local barWidth = 50
            local barHeight = 5
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

            -- 血量颜色渐变 (绿>80%, 黄>50%, 橙>20%, 红<20%)
            if smoothHP >= 0.8 then
                healthBar.Color = Color3.new(0, 1, 0)
            elseif smoothHP >= 0.5 then
                healthBar.Color = Color3.new(1, 1, 0)
            elseif smoothHP >= 0.2 then
                healthBar.Color = Color3.new(1, 0.5, 0)
            else
                healthBar.Color = Color3.new(1, 0, 0)
            end

            -- 受伤闪烁
            if humanoid.Health ~= lastHealth then
                healthChangeTime = tick()
                lastHealth = humanoid.Health
            end
            if tick() - healthChangeTime < 0.5 then
                healthBar.Color = Color3.new(1, 0, 0)
            end

            healthBar.Visible = true

            healthText.Position = Vector2.new(barX + barWidth + 5, barY - 5)
            healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
            healthText.Color = color
            healthText.Visible = true
        else
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarBorder.Visible = false
            healthText.Visible = false
        end

        -- 名称 & 距离 & 武器
        if ESP_Config.ShowName and onScreen then
            nameText.Position = Vector2.new(headPos.X, headPos.Y - 35)
            nameText.Text = player.Name
            nameText.Color = color
            nameText.Visible = true

            if ESP_Config.ShowDistance then
                distanceText.Position = Vector2.new(headPos.X, headPos.Y + 10)
                distanceText.Text = math.floor(dist) .. "m"
                distanceText.Visible = true
            else
                distanceText.Visible = false
            end

            if ESP_Config.ShowWeapon then
                weaponText.Position = Vector2.new(headPos.X, headPos.Y - 50)
                weaponText.Text = weaponName
                weaponText.Visible = true
            else
                weaponText.Visible = false
            end
        else
            nameText.Visible = false
            distanceText.Visible = false
            weaponText.Visible = false
        end

        -- 射线透视 (从屏幕底部中心到头部)
        if ESP_Config.ShowTracer then
            local head = character:FindFirstChild("Head")
            if head then
                local hPos, hOnScreen = Camera:WorldToViewportPoint(head.Position)
                if hOnScreen then
                    tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    tracer.To = Vector2.new(hPos.X, hPos.Y)
                    tracer.Visible = true
                    tracer.Color = ESP_Config.TracerColor
                    tracer.Thickness = ESP_Config.TracerThickness

                    -- 距离变色
                    if dist < 20 then
                        tracer.Color = Color3.new(0, 1, 0)
                    elseif dist < 50 then
                        tracer.Color = Color3.new(1, 1, 0)
                    else
                        tracer.Color = ESP_Config.TracerColor
                    end
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end

        -- 骨架透视
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

                -- 头->躯干
                skeletonLines[1].From = Vector2.new(hP.X, hP.Y)
                skeletonLines[1].To = Vector2.new(tP.X, tP.Y)
                skeletonLines[1].Visible = true
                -- 躯干->左臂
                skeletonLines[2].From = Vector2.new(tP.X, tP.Y)
                skeletonLines[2].To = Vector2.new(laP.X, laP.Y)
                skeletonLines[2].Visible = true
                -- 躯干->右臂
                skeletonLines[3].From = Vector2.new(tP.X, tP.Y)
                skeletonLines[3].To = Vector2.new(raP.X, raP.Y)
                skeletonLines[3].Visible = true
                -- 躯干->左腿
                skeletonLines[4].From = Vector2.new(tP.X, tP.Y)
                skeletonLines[4].To = Vector2.new(llP.X, llP.Y)
                skeletonLines[4].Visible = true
                -- 躯干->右腿
                skeletonLines[5].From = Vector2.new(tP.X, tP.Y)
                skeletonLines[5].To = Vector2.new(rlP.X, rlP.Y)
                skeletonLines[5].Visible = true

                -- 下臂/下腿 (6-9)
                if character:FindFirstChild("LeftLowerArm") then
                    local pos = Camera:WorldToViewportPoint(character.LeftLowerArm.Position)
                    skeletonLines[6].From = Vector2.new(laP.X, laP.Y)
                    skeletonLines[6].To = Vector2.new(pos.X, pos.Y)
                    skeletonLines[6].Visible = true
                end
                if character:FindFirstChild("RightLowerArm") then
                    local pos = Camera:WorldToViewportPoint(character.RightLowerArm.Position)
                    skeletonLines[7].From = Vector2.new(raP.X, raP.Y)
                    skeletonLines[7].To = Vector2.new(pos.X, pos.Y)
                    skeletonLines[7].Visible = true
                end
                if character:FindFirstChild("LeftLowerLeg") then
                    local pos = Camera:WorldToViewportPoint(character.LeftLowerLeg.Position)
                    skeletonLines[8].From = Vector2.new(llP.X, llP.Y)
                    skeletonLines[8].To = Vector2.new(pos.X, pos.Y)
                    skeletonLines[8].Visible = true
                end
                if character:FindFirstChild("RightLowerLeg") then
                    local pos = Camera:WorldToViewportPoint(character.RightLowerLeg.Position)
                    skeletonLines[9].From = Vector2.new(rlP.X, rlP.Y)
                    skeletonLines[9].To = Vector2.new(pos.X, pos.Y)
                    skeletonLines[9].Visible = true
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

-- 清理玩家ESP Drawing对象
local function cleanupESP(player)
    if ESPComponents[player] then
        local comps = ESPComponents[player]
        for key, component in pairs(comps) do
            if typeof(component) == "table" then
                for _, drawing in pairs(component) do
                    if typeof(drawing) == "userdata" then
                        pcall(function() drawing:Remove() end)
                    end
                end
            else
                if typeof(component) == "userdata" then
                    pcall(function() component:Remove() end)
                end
            end
        end
        ESPComponents[player] = nil
    end
end

-- 为现有玩家创建ESP
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

-- 新玩家加入时创建ESP
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

-- 玩家离开时清理ESP
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

-- ================= HB Tabs.zho UI控制面板 =================
zySec2:Paragraph({
    Title = "ESP透视设置",
    Desc = "Drawing API高性能透视",
    ImageSize = 22,
    ThumbnailSize = 0
})

-- ESP总开关
zySec2:Toggle({
    Title = "开启ESP总开关",
    Desc = "全局启用透视",
    Default = false,
    Callback = function(state)
        ESP_Config.EnableESP = state
        if not state then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    if ESPComponents[player] then
                        for key, component in pairs(ESPComponents[player]) do
                            if typeof(component) == "table" then
                                for _, drawing in pairs(component) do
                                    if typeof(drawing) == "userdata" then
                                        pcall(function() drawing.Visible = false end)
                                    end
                                end
                            else
                                if typeof(component) == "userdata" then
                                    pcall(function() component.Visible = false end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
})

-- 显示信息开关
zySec2:Toggle({
    Title = "显示头顶名称",
    Desc = "玩家ID",
    Default = true,
    Callback = function(v) ESP_Config.ShowName = v end
})
zySec2:Toggle({
    Title = "显示血量",
    Default = true,
    Callback = function(v) ESP_Config.ShowHealth = v end
})
zySec2:Toggle({
    Title = "显示距离",
    Default = true,
    Callback = function(v) ESP_Config.ShowDistance = v end
})

-- 功能开关
zySec2:Toggle({
    Title = "方框透视",
    Desc = "2D方框",
    Default = true,
    Callback = function(v) ESP_Config.ShowBox = v end
})
zySec2:Toggle({
    Title = "射线透视",
    Desc = "从屏幕底部到头部",
    Default = false,
    Callback = function(v) ESP_Config.ShowTracer = v end
})
zySec2:Toggle({
    Title = "骨架透视",
    Desc = "骨骼线条",
    Default = false,
    Callback = function(v) ESP_Config.ShowSkeleton = v end
})
zySec2:Toggle({
    Title = "武器显示",
    Desc = "显示手持武器名",
    Default = false,
    Callback = function(v) ESP_Config.ShowWeapon = v end
})
zySec2:Toggle({
    Title = "区分队友颜色",
    Desc = "队友绿/敌人红/NPC黄",
    Default = false,
    Callback = function(v) ESP_Config.TeamCheck = v end
})

-- 可视距离滑块
zySec2:Slider({
    Title = "ESP最大可视距离",
    Desc = "超出距离不渲染",
    Value = {Min=50, Max=1000, Default=350},
    Step = 10,
    IsTextbox = true,
    Callback = function(val) ESP_Config.MaxDrawDistance = val end
})

-- =================== 旋转模块（完全修复版） ===================

local SpinEnabled = false
local SpinSpeed = 5
local SpinConnection = nil

-- ⭐线程控制（核心修复）
local AnimationLockThread = nil
-- ================= 开始旋转 =================
local function StartSpin()

    if SpinConnection then return end

    local plr = game.Players.LocalPlayer

    SpinConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)

        if not SpinEnabled then return end

        local char = plr.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(SpinSpeed) * dt * 60, 0)

    end)

    ApplyAnimationLock(plr.Character)
end

-- ================= 停止旋转 =================
local function StopSpin()

    SpinEnabled = false -- ⭐必须

    if SpinConnection then
        SpinConnection:Disconnect()
        SpinConnection = nil
    end

    RemoveAnimationLock(game.Players.LocalPlayer.Character)
end

-- ================= 重生修复 =================
game.Players.LocalPlayer.CharacterAdded:Connect(function(char)

    if SpinEnabled then

        task.wait(0.5)

        ApplyAnimationLock(char)

        if not SpinConnection then
            StartSpin()
        end
    end
end)

Tabs.xz:Toggle({
    Title = "人物自转和车自转",
    Default = false,
    Callback = function(v)

        SpinEnabled = v

        if v then
            StartSpin()
            AddFeature("自转")
        else
            StopSpin()
            RemoveFeature("自转")
        end

    end
})

-- ⭐ Input → Slider（稳定）
Tabs.xz:Slider({
    Title = "旋转速度",
    Value = {
        Min = 1,
        Max = 200,
        Default = SpinSpeed,
    },
    Increment = 5,
    Callback = function(v)
        SpinSpeed = v
    end
})
Tabs.xz:Button({
    Title = "车辆速度120",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/feche/refs/heads/main/%E9%A3%9E%E8%BD%A6.lua"))()
    end
})
Tabs.xz:Button({
    Title = "车辆速度95",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/feche/refs/heads/main/%E9%A3%9Efe%E8%BD%A6.lua"))()
    end
})
Tabs.xz:Button({
    Title = "定住",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ggsq1741-debug/feche/refs/heads/main/%E5%AE%9A%E4%BD%8F.lua"))()
    end
})
--------==传送------===
Tabs.wz:Button({
    Title = "出生点",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3742.390380859375, 3.972581148147583, -438.38031005859375)
    end
})
local wzSec1 = Tabs.wz:Section({ Title = "队伍职业传送" })
wzSec1:Button({
    Title = "警察局",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3374.522705078125, -337.2044982910156, -485.5386962890625)
    end
})
wzSec1:Button({
    Title = "医院内部",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3904.382568359375, -336.75958251953125, -178.96585083007812)
    end
})
wzSec1:Button({
    Title = "消防局",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3578.7822265625, -323.8002624511719, 591.4299926757812)
    end
})
wzSec1:Button({
    Title = "道路服务",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(4260.125, -337.1921691894531, 1200.8883056640625)
    end
})
wzSec1:Button({
    Title = "送货服务",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(4407.6728515625, 2.8829991817474365, 1608.845703125)
    end
})
wzSec1:Button({
    Title = "出租车司机",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(4146.0556640625, -337.2187194824219, 931.5494995117188)
    end
})
wzSec1:Button({
    Title = "农场",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1269.2799072265625, 4.976277828216553, 2545.564208984375)
    end
})
local wzSec2 = Tabs.wz:Section({ Title = "ATM传送" })
wzSec2:Button({
    Title = "ATM1",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3693.36962890625, 3.2699239253997803, 691.41015625)
    end
})
wzSec2:Button({
    Title = "ATM2",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(2795.519775390625, 3.2705960273742676, 517.5686645507812)
    end
})
wzSec2:Button({
    Title = "ATM3",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3329.54443359375, 3.2705953121185303, 409.2603454589844)
    end
})
wzSec2:Button({
    Title = "ATM4",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(4350.13427734375, 3.270592212677002, 1020.272705078125)
    end
})
wzSec2:Button({
    Title = "ATM5",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(2719.40380859375, 3.2910029888153076, 1808.113037109375)
    end
})
wzSec2:Button({
    Title = "ATM6",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3699.785888671875, 3.270596981048584, -238.58123779296875)
    end
})
wzSec2:Button({
    Title = "ATM7",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(909.4918212890625, 3.289822578430176, 924.727783203125)
    end
})
wzSec2:Button({
    Title = "ATM8",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-371.0598449707031, 3.2918272018432617, -100.9500961303711)
    end
})
local wzSec3 = Tabs.wz:Section({ Title = "消⭐点位+杂项" })
wzSec3:Button({
    Title = "大楼消⭐",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3144.32861328125, 287.865478515625, -220.37112426757812)
    end
})
wzSec3:Button({
    Title = "监狱门口",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1620.2845458984375, 2.8830316066741943, 1263.7410888671875)
    end
})
wzSec3:Button({
    Title = "消⭐牛逼点位1",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(5515.333984375, -30.079524993896484, 2241.72802734375)
    end
})
wzSec3:Button({
    Title = "消⭐牛逼点位2",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(5987.05126953125, 2724.95654296875, 2404.273193359375)
    end
})
-------=====黑市商店=====---<
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunc = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("PlayerFunc")
local BlackMarketRoot = ReplicatedStorage:WaitForChild("Stuff"):WaitForChild("Black Market")

--黑市道具文件夹编号映射
local bmFolderId = {
    ["Decryption Circuit"] = "1",
    ["Lockpick Device"] = "2",
    ["Hacking Tool"] = "3",
    ["C4"] = "4",
    ["Green USB"] = "5",
    ["Crew Graffiti"] = "6"
}

--中英对照
local bmItemNames = {
    ["Decryption Circuit"] = "解密电路",
    ["Lockpick Device"] = "开锁工具",
    ["Hacking Tool"] = "黑客工具",
    ["C4"] = "C4炸药",
    ["Green USB"] = "绿色U盘",
    ["Crew Graffiti"] = "团队涂鸦"
}

local bmOptions = {}
local bmItemList = {}
for eng, cn in pairs(bmItemNames) do
    bmOptions[cn] = eng
    table.insert(bmItemList, cn)
end

local selectedBmItems = {}
local bmBuyDebounce = false

--多选下拉框
Tabs.qq:Dropdown({
    Title = "勾选黑市道具",
    zho = "勾选黑市道具",
    Desc = "多选黑市道具批量购买",
    Values = bmItemList,
    Value = {},
    Multi = true,
    Callback = function(selectCn)
        selectedBmItems = {}
        for _,nameCn in ipairs(selectCn) do
            local engName = bmOptions[nameCn]
            if engName then
                table.insert(selectedBmItems, engName)
            end
        end
    end
})

--确认购买按钮
Tabs.qq:Button({
    Title = "确认购买选中黑市道具",
    zho = "确认购买选中黑市道具",
    Desc = "逐个调用远程购买黑市物品",
    Callback = function()
        if bmBuyDebounce then
            WindUI:Notify({
                Title = "提示",
                zho = "提示",
                Text = "购买冷却中，稍后再试",
                Duration = 2
            })
            return
        end

        if #selectedBmItems == 0 then
            WindUI:Notify({
                Title = "提示",
                zho = "提示",
                Text = "未选择任何黑市道具",
                Duration = 2
            })
            return
        end

        bmBuyDebounce = true
        task.spawn(function()
            for _,engName in ipairs(selectedBmItems) do
                local fid = bmFolderId[engName]
                local targetItem = BlackMarketRoot:WaitForChild(fid):WaitForChild(engName)
                RemoteFunc:InvokeServer("purchase", {
                    isRestaurant = false,
                    item = targetItem
                })
                task.wait(0.2)
            end
            WindUI:Notify({
                Title = "完成",
                zho = "完成",
                Text = "选中黑市道具全部购买完成",
                Duration = 2.5
            })
            task.wait(1)
            bmBuyDebounce = false
        end)
    end
})
Tabs.qq:Button({
    Title = "黑市传送购买功能",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1040.427001953125, -22.734272003173828, 901.8596801757812)
    end
})
-- ========== 下面直接追加武器购买整套WindUI功能（移入本脚本内） ==========
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunc = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("PlayerFunc")
local WeaponRoot = ReplicatedStorage:WaitForChild("Stuff"):WaitForChild("Weapons")

-- 武器文件夹编号映射
local weaponFolderId = {
    ["Knife"] = "1",
    ["Battle Axe"] = "2",
    ["Bat"] = "3",
    ["Machete"] = "4",
    ["Glock 17"] = "5",
    ["M19"] = "6",
    ["Deagle 44"] = "7",
    ["MAC‑11"] = "8",
    ["MP5"] = "9",
    ["p90"] = "10",
    ["Galil"] = "11",
    ["Famas"] = "12",
    ["SLR36C"] = "13",
    ["Sawed‑Off"] = "14",
    ["MPX"] = "15",
    ["M4A1"] = "16",
    ["ACC Honey Badger"] = "17",
    ["AK‑47"] = "18"
}
-- 中英对照
local weaponNames = {
    ["Knife"] = "小刀",
    ["Battle Axe"] = "战斧",
    ["Bat"] = "棒球棍",
    ["Machete"] = "砍刀",
    ["Glock 17"] = "格洛克17",
    ["M19"] = "M19手枪",
    ["Deagle 44"] = "沙鹰44",
    ["MAC‑11"] = "MAC‑11",
    ["MP5"] = "MP5冲锋枪",
    ["p90"] = "P90",
    ["Galil"] = "加利尔",
    ["Famas"] = "法玛斯",
    ["SLR36C"] = "SLR36C",
    ["Sawed‑Off"] = "短管霰弹",
    ["MPX"] = "MPX",
    ["M4A1"] = "M4A1步枪",
    ["ACC Honey Badger"] = "蜜獾",
    ["AK‑47"] = "AK‑47"
}

local weaponOptions = {}
local weaponList = {}
for eng, cn in pairs(weaponNames) do
    weaponOptions[cn] = eng
    table.insert(weaponList, cn)
end

local selectedWeapons = {}
local buyDebounce = false

-- 多选下拉框 zho标签
Tabs.qiang:Dropdown({
    Title = "勾选需要购买的武器",
    zho = "勾选需要购买的武器",
    Desc = "多选武器批量购买",
    Values = weaponList,
    Value = {},
    Multi = true,
    Callback = function(selectCn)
        selectedWeapons = {}
        for _, nameCn in ipairs(selectCn) do
            local engName = weaponOptions[nameCn]
            if engName then
                table.insert(selectedWeapons, engName)
            end
        end
    end
})

-- 选中武器购买按钮
Tabs.qiang:Button({
    Title = "确认购买选中武器",
    zho = "确认购买选中武器",
    Desc = "逐个调用远程购买",
    Callback = function()
        if buyDebounce then
            WindUI:Notify({
                Title = "提示",
                zho = "提示",
                Text = "购买冷却中，稍后再试",
                Duration = 2
            })
            return
        end
        if #selectedWeapons == 0 then
            WindUI:Notify({
                Title = "提示",
                zho = "提示",
                Text = "未选择任何武器",
                Duration = 2
            })
            return
        end
        buyDebounce = true
        task.spawn(function()
            for _, engName in ipairs(selectedWeapons) do
                local fid = weaponFolderId[engName]
                local targetItem = WeaponRoot:WaitForChild(fid):WaitForChild(engName)
                RemoteFunc:InvokeServer("purchase", {
                    isRestaurant = false,
                    item = targetItem
                })
                task.wait(0.2)
            end
            WindUI:Notify({
                Title = "完成",
                zho = "完成",
                Text = "选中武器全部购买完成",
                Duration = 2.5
            })
            task.wait(1)
            buyDebounce = false
        end)
    end
})
Tabs.qiang:Button({
    Title = "枪店",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-323.0765075683594, 3.3417789936065674, 45.167503356933594)
    end
})
------战斗zd------
Tabs.zd:Toggle({
    Title = "无限子弹",
    Callback = function()
        -- ==========================================
-- 🔫 无限弹药 + 射速提升 - 通用版
-- ==========================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ==========================================
-- 获取手持武器
-- ==========================================
local function getHeldWeapon()
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
        if child:FindFirstChild("Config") then
            return child
        end
    end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then return tool end
    return nil
end

-- ==========================================
-- 设为999 + 射速提升
-- ==========================================
local function setInfinite(weapon)
    if not weapon or not weapon:FindFirstChild("Config") then 
        print("❌ 没找到武器")
        return 
    end
    
    local config = weapon.Config
    
    -- ===== 弹药无限 =====
    if config:FindFirstChild("Ammo") then
        config.Ammo.Value = 999
        config.Ammo.Changed:Connect(function()
            config.Ammo.Value = 999
        end)
        print("✅ " .. weapon.Name .. " 弹药: 999")
    end
    
    if config:FindFirstChild("TotalAmmo") then
        config.TotalAmmo.Value = 999
        config.TotalAmmo.Changed:Connect(function()
            config.TotalAmmo.Value = 999
        end)
        print("✅ " .. weapon.Name .. " 总弹药: 999")
    end
    
    -- ===== 射速提升 =====
    -- 方法1: 修改 FireRate / RateOfFire
    local fireRateProps = {"FireRate", "RateOfFire", "Firerate", "Rate"}
    for _, propName in ipairs(fireRateProps) do
        if config:FindFirstChild(propName) then
            local prop = config[propName]
            if prop:IsA("NumberValue") or prop:IsA("IntValue") then
                -- 原始值可能不同，这里设为0.01（极快）或根据需求调整
                local fastRate = 0.01
                prop.Value = fastRate
                prop.Changed:Connect(function()
                    prop.Value = fastRate
                end)
                print("✅ " .. weapon.Name .. " " .. propName .. " → 极速 (" .. fastRate .. ")")
            end
        end
    end
    
    -- 方法2: 如果武器有 Tool 属性 FireRate
    if weapon:FindFirstChild("FireRate") then
        local prop = weapon.FireRate
        if prop:IsA("NumberValue") or prop:IsA("IntValue") then
            prop.Value = 0.01
            prop.Changed:Connect(function()
                prop.Value = 0.01
            end)
            print("✅ " .. weapon.Name .. " FireRate → 极速")
        end
    end
    
end

-- ==========================================
-- 执行
-- ==========================================
local weapon = getHeldWeapon()
setInfinite(weapon)

-- 监控武器切换
local lastWeapon = nil
game:GetService("RunService").Heartbeat:Connect(function()
    if not player.Character then return end
    local current = getHeldWeapon()
    if current ~= lastWeapon then
        lastWeapon = current
        if current then
            print("\n🔄 切换武器: " .. current.Name)
            setInfinite(current)
        end
    end
end)

print("========================================")
print("✅ 无限弹药 + 极速射速已激活！")
print("💡 换武器自动生效")
print("⚡ 射速已提升至 0.01 (极快)")
    end
})

Tabs.zd:Button({
    Title = "无限子弹+射速",
    Callback = function()
        local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function ModifyWeaponStats()
    local garbage = getgc(true)
    for _, tbl in pairs(garbage) do
        if type(tbl) == "table" then
            if rawget(tbl, "SHOOT_MODE") then
                rawset(tbl, "SHOOT_MODE", 2)
            end
            if rawget(tbl, "RPM") then
                rawset(tbl, "RPM", math.huge)
            end
            if rawget(tbl, "DAMAGE") then
                rawset(tbl, "DAMAGE", math.huge)
            end
        end
    end
    print("1")
end

local function SetupCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")
 
    humanoid.Died:Connect(ModifyWeaponStats)
end

if LocalPlayer.Character then
    SetupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)

task.wait(0.2)
ModifyWeaponStats()
--下面的这个是无限子弹上面的是射速
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

task.spawn(function()
    while RunService.Heartbeat:Wait() do
        local characterFolder = workspace:FindFirstChild("Characters") and workspace.Characters:FindFirstChild(LocalPlayer.Name)
        if not characterFolder then continue end

        for _, gun in ipairs(characterFolder:GetChildren()) do
            local config = gun:FindFirstChild("Config")
            if not config then continue end
            
            local Ammo = config:FindFirstChild("Ammo")
            local TotalAmmo = config:FindFirstChild("TotalAmmo")

            if Ammo then
                Ammo.Value = math.huge
            end
            if TotalAmmo then
                TotalAmmo.Value = math.huge
            end
        end
    end
end)
print("1")
    end
})
------杀戮光环----
Tabs.zd:Button({
    Title = "刀杀戮光环",
    Callback = function()
        -- 刀改远程攻击脚本（保留刀的外观）

local Settings = {
    MaxDistance = 1500,      -- 最大攻击距离
    Damage = 100,            -- 伤害值
    BodyPart = "Head",      -- 攻击部位（Head/Torso）
    WeaponName = "刀",      -- 武器名称（显示为刀）
    AttackInterval = 0.0    -- 攻击间隔
}

local playerEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerEvent")
local playerFunc = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerFunc")

-- 获取目标
local function getNearestTarget()
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local character = localPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local nearest = nil
    local minDist = Settings.MaxDistance + 1
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local humanoid = targetChar:FindFirstChild("Humanoid")
                if targetRoot and humanoid and humanoid.Health > 0 then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance < minDist then
                        minDist = distance
                        nearest = player
                    end
                end
            end
        end
    end
    
    return nearest, minDist
end

-- 执行远程攻击（保留刀的外观）
local function performRangedAttack()
    local target, distance = getNearestTarget()
    if not target then
        -- print("没有目标")
        return false
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local targetChar = target.Character
    if not targetChar then return false end
    
    -- 获取目标部位
    local aimPart = targetChar:FindFirstChild(Settings.BodyPart) or targetChar:FindFirstChild("HumanoidRootPart")
    if not aimPart then return false end
    
    -- 计算攻击参数
    local attackOrigin = rootPart.Position + Vector3.new(0, 1.5, 0)
    local targetPos = aimPart.Position
    local direction = (targetPos - attackOrigin).Unit
    
    -- 1. 装备刀
    local knife = character:FindFirstChild("Knife")
    if knife then
        playerEvent:FireServer("equipItem", knife)
    end
    
    -- 2. 战斗模式
    playerEvent:FireServer("combatMode", true)
    
    -- 3. 播放音效（装备音效）
    local equipSound = rootPart:FindFirstChild("Equip")
    if equipSound then
        playerFunc:InvokeServer("selectiveObjReplicaSystem", "playSound", equipSound, true)
    end
    
    -- 4. 发送远程伤害（武器名显示为刀）
    playerEvent:FireServer("damage", {
        bodyParts = {{Settings.BodyPart, Settings.Damage}},
        target = target,
        shotCode = {attackOrigin, direction},
        pos = targetPos
    })
    
    -- 5. 发送子弹数据（武器名显示为刀）
    playerEvent:FireServer("bullet", {
        weaponName = Settings.WeaponName,  -- "刀"
        pos = targetPos,
        posDestroyX = targetPos.X
    })
    
    print("🗡️  远程刀击: " .. target.Name .. " | 部位: " .. Settings.BodyPart .. " | 伤害: " .. Settings.Damage .. " | 距离: " .. math.floor(distance))
    return true
end

-- ===== 主循环 =====
print("=== 刀改远程攻击 ===")
print("🗡️  保留刀的外观，但攻击距离变远")
print("🎯 目标部位: " .. Settings.BodyPart)
print("💥 伤害: " .. Settings.Damage)
print("📏 最大距离: " .. Settings.MaxDistance)

-- 先装备刀
local localPlayer = game:GetService("Players").LocalPlayer
local character = localPlayer.Character
if character then
    local knife = character:FindFirstChild("Knife")
    if knife then
        playerEvent:FireServer("equipItem", knife)
        print("✓ 已装备刀")
    else
        print("⚠️  找不到 Knife，请确保角色有刀")
    end
end

-- 战斗模式
playerEvent:FireServer("combatMode", true)
print("✓ 战斗模式已启用")

print("✅ 开始自动远程攻击...")

-- 自动攻击循环
while wait(Settings.AttackInterval) do
    performRangedAttack()
end
    end
})
Tabs.zd:Button({
    Title = "刀杀戮光环2",
    Callback = function()
        -- 极致精简：最细红色轨迹

local playerEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerEvent")
local playerFunc = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerFunc")

-- 创建极细轨迹
local function createUltraThinTrail(startPos, endPos)
    local dist = (startPos - endPos).Magnitude
    if dist < 1 then return end
    
    -- 极细线条（几乎看不见的细线）
    local trail = Instance.new("Part")
    trail.Anchored = true
    trail.CanCollide = false
    trail.Material = Enum.Material.Neon
    trail.Color = Color3.new(1, 0, 0)
    trail.Transparency = 0.2
    trail.Size = Vector3.new(0.03, 0.03, dist)  -- 非常细
    
    local mid = (startPos + endPos) / 2
    trail.CFrame = CFrame.lookAt(mid, endPos) * CFrame.new(0, 0, -dist / 2)
    trail.Parent = game:GetService("Workspace")
    game:GetService("Debris"):AddItem(trail, 0.2)
    
    -- 命中标记（极细十字）
    for _, dir in pairs({
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
    }) do
        local mark = Instance.new("Part")
        mark.Anchored = true
        mark.CanCollide = false
        mark.Material = Enum.Material.Neon
        mark.Color = Color3.new(1, 0, 0)
        mark.Transparency = 0.4
        mark.Size = Vector3.new(0.03, 0.03, 0.5)
        mark.CFrame = CFrame.lookAt(endPos + dir * 0.3, endPos)
        mark.Parent = game:GetService("Workspace")
        game:GetService("Debris"):AddItem(mark, 0.15)
    end
end

-- 攻击
local function attack()
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- 找最近目标
    local target = nil
    local minDist = 500
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = player
                end
            end
        end
    end
    
    if not target then return end
    
    local targetChar = target.Character
    local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not head then return end
    
    local origin = root.Position + Vector3.new(0, 1.5, 0)
    local targetPos = head.Position
    local direction = (targetPos - origin).Unit
    
    -- 极细轨迹
    createUltraThinTrail(origin, targetPos)
    
    -- 攻击
    local knife = character:FindFirstChild("Knife")
    if knife then
        playerEvent:FireServer("equipItem", knife)
    end
    
    playerEvent:FireServer("combatMode", true)
    
    local sound = root:FindFirstChild("Equip")
    if sound then
        playerFunc:InvokeServer("selectiveObjReplicaSystem", "playSound", sound, true)
    end
    
    playerEvent:FireServer("damage", {
        bodyParts = {{"Head", 100}},
        target = target,
        shotCode = {origin, direction},
        pos = targetPos
    })
    
    playerEvent:FireServer("bullet", {
        weaponName = "刀",
        pos = targetPos,
        posDestroyX = targetPos.X
    })
    
    print("🗡️  " .. target.Name)
end

-- 初始化
playerEvent:FireServer("combatMode", true)
print("🔴 超细红色轨迹已激活")

while wait(0.0) do
    attack()
end
    end
})
Tabs.zd:Button({
    Title = "刀杀戮光环3",
    Callback = function()
        -- 极致精简：最细红色轨迹

local playerEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerEvent")
local playerFunc = game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("PlayerFunc")

-- 创建极细轨迹
local function createUltraThinTrail(startPos, endPos)
    local dist = (startPos - endPos).Magnitude
    if dist < 1 then return end
    
    -- 极细线条（几乎看不见的细线）
    local trail = Instance.new("Part")
    trail.Anchored = true
    trail.CanCollide = false
    trail.Material = Enum.Material.Neon
    trail.Color = Color3.new(1, 0, 0)
    trail.Transparency = 0.2
    trail.Size = Vector3.new(0.03, 0.03, dist)  -- 非常细
    
    local mid = (startPos + endPos) / 2
    trail.CFrame = CFrame.lookAt(mid, endPos) * CFrame.new(0, 0, -dist / 2)
    trail.Parent = game:GetService("Workspace")
    game:GetService("Debris"):AddItem(trail, 0.2)
    
    -- 命中标记（极细十字）
    for _, dir in pairs({
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
    }) do
        local mark = Instance.new("Part")
        mark.Anchored = true
        mark.CanCollide = false
        mark.Material = Enum.Material.Neon
        mark.Color = Color3.new(1, 0, 0)
        mark.Transparency = 0.4
        mark.Size = Vector3.new(0.03, 0.03, 0.5)
        mark.CFrame = CFrame.lookAt(endPos + dir * 0.3, endPos)
        mark.Parent = game:GetService("Workspace")
        game:GetService("Debris"):AddItem(mark, 0.15)
    end
end

-- 攻击
local function attack()
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- 找最近目标
    local target = nil
    local minDist = 150
    
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    target = player
                end
            end
        end
    end
    
    if not target then return end
    
    local targetChar = target.Character
    local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
    if not head then return end
    
    local origin = root.Position + Vector3.new(0, 1.5, 0)
    local targetPos = head.Position
    local direction = (targetPos - origin).Unit
    
    -- 极细轨迹
    createUltraThinTrail(origin, targetPos)
    
    -- 攻击
    local knife = character:FindFirstChild("Knife")
    if knife then
        playerEvent:FireServer("equipItem", knife)
    end
    
    playerEvent:FireServer("combatMode", true)
    
    local sound = root:FindFirstChild("Equip")
    if sound then
        playerFunc:InvokeServer("selectiveObjReplicaSystem", "playSound", sound, true)
    end
    
    playerEvent:FireServer("damage", {
        bodyParts = {{"Head", 100}},
        target = target,
        shotCode = {origin, direction},
        pos = targetPos
    })
    
    playerEvent:FireServer("bullet", {
        weaponName = "刀",
        pos = targetPos,
        posDestroyX = targetPos.X
    })
    
    print("🗡️  " .. target.Name)
end

-- 初始化
playerEvent:FireServer("combatMode", true)
print("🔴 超细红色轨迹已激活")

while wait(0.0) do
    attack()
end
    end
})
Tabs.zd:Button({
    Title = "格洛克17杀戮光环",
    Callback = function()
        -- 完整自动攻击脚本（只攻击头部）

local Settings = {
    AttackInterval = 0.25,  -- 攻击间隔（秒）
    MaxDistance = 150,      -- 最大攻击距离
    AutoReload = true,      -- 是否自动补充弹药
    AmmoAmount = 15,        -- 每次补充的弹药数量
    WeaponName = "Glock 17", -- 武器名称
    PlaySound = true,       -- 是否播放枪声
    TargetMode = "Nearest", -- "Nearest" 或 "Random"
    HeadDamage = 10         -- 头部伤害值
}

-- 获取远程事件
local function getRemoteEvent()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remote")
    if remote then
        return remote:FindFirstChild("PlayerEvent"), remote:FindFirstChild("PlayerFunc")
    end
    return nil, nil
end

-- 切换战斗模式
local function enableCombatMode()
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        warn("找不到 PlayerEvent")
        return false
    end
    
    local args = {"combatMode", true}
    playerEvent:FireServer(unpack(args))
    print("✓ 战斗模式已启用")
    return true
end

-- 设置弹药
local function setAmmo(amount)
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        return false
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local backpack = playerGui:FindFirstChild("Backpack")
    if not backpack then return false end
    
    -- 查找武器配置
    local weaponConfig = nil
    for _, child in pairs(backpack:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            local config = child:FindFirstChild("Config")
            if config then
                local ammo = config:FindFirstChild("Ammo")
                if ammo then
                    weaponConfig = config
                    break
                end
            end
        end
    end
    
    if not weaponConfig then
        warn("找不到武器配置")
        return false
    end
    
    local ammo = weaponConfig:FindFirstChild("Ammo")
    if not ammo then return false end
    
    local args = {"propertyListener", ammo, amount or Settings.AmmoAmount}
    playerEvent:FireServer(unpack(args))
    print("✓ 弹药已设置: " .. (amount or Settings.AmmoAmount))
    return true
end

-- 播放枪声
local function playGunSound()
    if not Settings.PlaySound then return end
    
    local playerEvent, playerFunc = getRemoteEvent()
    if not playerFunc then
        return
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local soundObj = rootPart:FindFirstChild("HandgunFire")
    if not soundObj then
        return
    end
    
    local args = {
        "selectiveObjReplicaSystem",
        "playSound",
        soundObj,
        true
    }
    
    playerFunc:InvokeServer(unpack(args))
end

-- 发送子弹数据
local function sendBulletData(targetPos)
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        return false
    end
    
    local args = {
        "bullet",
        {
            weaponName = Settings.WeaponName,
            pos = targetPos,
            posDestroyX = targetPos.X
        }
    }
    
    playerEvent:FireServer(unpack(args))
    return true
end

-- 获取目标
local function getTarget(mode)
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local character = localPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local aliveTargets = {}
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local humanoid = targetChar:FindFirstChild("Humanoid")
                if targetRoot and humanoid and humanoid.Health > 0 then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance <= Settings.MaxDistance then
                        table.insert(aliveTargets, {
                            player = player,
                            distance = distance,
                            root = targetRoot,
                            character = targetChar
                        })
                    end
                end
            end
        end
    end
    
    if #aliveTargets == 0 then
        return nil
    end
    
    if mode == "Random" then
        return aliveTargets[math.random(#aliveTargets)]
    else
        table.sort(aliveTargets, function(a, b) return a.distance < b.distance end)
        return aliveTargets[1]
    end
end

-- 执行攻击（只攻击头部）
local function attack()
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        warn("找不到 PlayerEvent")
        return false
    end
    
    local targetData = getTarget(Settings.TargetMode)
    if not targetData then
        return false
    end
    
    local target = targetData.player
    local targetChar = targetData.character
    local distance = targetData.distance
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    -- 获取目标的头部
    local head = targetChar:FindFirstChild("Head")
    if not head then
        -- 如果没有头部，使用 HumanoidRootPart 作为替代
        head = targetChar:FindFirstChild("HumanoidRootPart")
        if not head then
            return false
        end
    end
    
    -- 计算攻击参数（瞄准头部）
    local attackOrigin = rootPart.Position + Vector3.new(0, 1.5, 0)
    local targetPos = head.Position
    local direction = (targetPos - attackOrigin).Unit
    
    -- 添加微小偏移（模拟真实瞄准，但始终瞄准头部区域）
    -- 如果希望100%精准爆头，可以设置 offset = Vector3.new(0, 0, 0)
    local offset = Vector3.new(
        math.random(-1, 1) * 0.1,  -- X轴微调
        math.random(-1, 1) * 0.1,  -- Y轴微调
        math.random(-1, 1) * 0.1   -- Z轴微调
    )
    targetPos = targetPos + offset
    
    -- 重新计算方向
    direction = (targetPos - attackOrigin).Unit
    
    -- 固定攻击头部（高伤害）
    local bodyPart = {"Head", Settings.HeadDamage}
    
    -- 1. 发送伤害事件（攻击头部）
    local damageArgs = {
        "damage",
        {
            bodyParts = {bodyPart},
            target = target,
            shotCode = {
                attackOrigin,
                direction
            },
            pos = targetPos
        }
    }
    playerEvent:FireServer(unpack(damageArgs))
    
    -- 2. 发送子弹数据
    sendBulletData(targetPos)
    
    -- 3. 播放枪声
    playGunSound()
    
    print("🎯 爆头! " .. target.Name .. " | 伤害: " .. Settings.HeadDamage .. 
          " | 距离: " .. math.floor(distance) .. " | 精准度: 100%")
    return true
end

-- ===== 初始化 =====
print("=== 自动爆头脚本启动 ===")
print("⚠️  只攻击头部，不攻击其他部位")
print("🎯 头部伤害: " .. Settings.HeadDamage)

local playerEvent, playerFunc = getRemoteEvent()
if not playerEvent then
    error("找不到 PlayerEvent，请检查游戏结构")
end

-- 1. 启用战斗模式
enableCombatMode()

-- 2. 设置弹药
if Settings.AutoReload then
    wait(0.2)
    setAmmo(Settings.AmmoAmount)
end

-- 3. 开始自动攻击循环
wait(0.3)
print("=== 开始自动爆头 ===")
print("武器: " .. Settings.WeaponName)
print("目标模式: " .. Settings.TargetMode)
print("攻击间隔: " .. Settings.AttackInterval .. "秒")
print("最大距离: " .. Settings.MaxDistance)

local attackCount = 0
local headshotCount = 0

while wait(Settings.AttackInterval) do
    local success = attack()
    if success then
        attackCount = attackCount + 1
        headshotCount = headshotCount + 1
        
        -- 每10次攻击显示统计
        if attackCount % 10 == 0 then
            print("📊 统计: 攻击 " .. attackCount .. " 次 | 爆头 " .. headshotCount .. " 次 | 爆头率: 100%")
        end
        
        -- 每30次攻击补充弹药
        if Settings.AutoReload and attackCount % 30 == 0 then
            wait(0.1)
            setAmmo(Settings.AmmoAmount)
        end
    end
end
    end
})
Tabs.zd:Button({
    Title = "格洛克17杀戮光环2",
    Callback = function()
        -- 完整自动攻击脚本（包含战斗模式、弹药、开枪、音效）

local Settings = {
    AttackInterval = 0.1,  -- 攻击间隔（秒）
    MaxDistance = 1500,      -- 最大攻击距离
    AutoReload = true,      -- 是否自动补充弹药
    AmmoAmount = 15,        -- 每次补充的弹药数量
    WeaponName = "Glock 17", -- 武器名称
    PlaySound = true,       -- 是否播放枪声
    TargetMode = "Nearest"  -- "Nearest" 或 "Random"
}

-- 获取远程事件
local function getRemoteEvent()
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remote")
    if remote then
        return remote:FindFirstChild("PlayerEvent"), remote:FindFirstChild("PlayerFunc")
    end
    return nil, nil
end

-- 切换战斗模式
local function enableCombatMode()
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        warn("找不到 PlayerEvent")
        return false
    end
    
    local args = {"combatMode", true}
    playerEvent:FireServer(unpack(args))
    print("✓ 战斗模式已启用")
    return true
end

-- 设置弹药
local function setAmmo(amount)
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        return false
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local backpack = playerGui:FindFirstChild("Backpack")
    if not backpack then return false end
    
    -- 查找武器配置
    local weaponConfig = nil
    for _, child in pairs(backpack:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            local config = child:FindFirstChild("Config")
            if config then
                local ammo = config:FindFirstChild("Ammo")
                if ammo then
                    weaponConfig = config
                    break
                end
            end
        end
    end
    
    if not weaponConfig then
        warn("找不到武器配置")
        return false
    end
    
    local ammo = weaponConfig:FindFirstChild("Ammo")
    if not ammo then return false end
    
    local args = {"propertyListener", ammo, amount or Settings.AmmoAmount}
    playerEvent:FireServer(unpack(args))
    print("✓ 弹药已设置: " .. (amount or Settings.AmmoAmount))
    return true
end

-- 播放枪声（通过 InvokeServer）
local function playGunSound()
    if not Settings.PlaySound then return end
    
    local playerEvent, playerFunc = getRemoteEvent()
    if not playerFunc then
        -- 如果找不到 PlayerFunc，跳过音效
        return
    end
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local soundObj = rootPart:FindFirstChild("HandgunFire")
    if not soundObj then
        -- 如果找不到 HandgunFire，尝试创建或忽略
        return
    end
    
    local args = {
        "selectiveObjReplicaSystem",
        "playSound",
        soundObj,
        true
    }
    
    -- 使用 InvokeServer（注意是 InvokeServer 不是 FireServer）
    playerFunc:InvokeServer(unpack(args))
end

-- 发送子弹数据
local function sendBulletData(targetPos)
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        return false
    end
    
    local args = {
        "bullet",
        {
            weaponName = Settings.WeaponName,
            pos = targetPos,
            posDestroyX = targetPos.X
        }
    }
    
    playerEvent:FireServer(unpack(args))
    return true
end

-- 获取目标
local function getTarget(mode)
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    local character = localPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local aliveTargets = {}
    
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                local humanoid = targetChar:FindFirstChild("Humanoid")
                if targetRoot and humanoid and humanoid.Health > 0 then
                    local distance = (targetRoot.Position - rootPart.Position).Magnitude
                    if distance <= Settings.MaxDistance then
                        table.insert(aliveTargets, {
                            player = player,
                            distance = distance,
                            root = targetRoot
                        })
                    end
                end
            end
        end
    end
    
    if #aliveTargets == 0 then
        return nil
    end
    
    if mode == "Random" then
        return aliveTargets[math.random(#aliveTargets)]
    else
        table.sort(aliveTargets, function(a, b) return a.distance < b.distance end)
        return aliveTargets[1]
    end
end

-- 执行攻击（完整流程）
local function attack()
    local playerEvent = getRemoteEvent()
    if not playerEvent then
        warn("找不到 PlayerEvent")
        return false
    end
    
    local targetData = getTarget(Settings.TargetMode)
    if not targetData then
        return false
    end
    
    local target = targetData.player
    local targetRoot = targetData.root
    local distance = targetData.distance
    
    local localPlayer = game:GetService("Players").LocalPlayer
    local character = localPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    -- 计算攻击参数
    local attackOrigin = rootPart.Position + Vector3.new(0, 1.5, 0)
    local targetPos = targetRoot.Position
    local direction = (targetPos - attackOrigin).Unit
    
    -- 随机选择命中部位
    local bodyPartsList = {
        {"Head", 10},
        {"Torso", 5},
        {"LeftArm", 2},
        {"RightArm", 2},
        {"LeftLeg", 2},
        {"RightLeg", 2}
    }
    local randomPart = bodyPartsList[math.random(#bodyPartsList)]
    
    -- 1. 发送伤害事件
    local damageArgs = {
        "damage",
        {
            bodyParts = {randomPart},
            target = target,
            shotCode = {
                attackOrigin,
                direction
            },
            pos = targetPos
        }
    }
    playerEvent:FireServer(unpack(damageArgs))
    
    -- 2. 发送子弹数据
    sendBulletData(targetPos)
    
    -- 3. 播放枪声
    playGunSound()
    
    print("🔫 攻击 " .. target.Name .. " | 部位: " .. randomPart[1] .. 
          " | 伤害: " .. randomPart[2] .. " | 距离: " .. math.floor(distance))
    return true
end

-- ===== 初始化 =====
print("=== 完整自动攻击脚本启动 ===")

local playerEvent, playerFunc = getRemoteEvent()
if not playerEvent then
    error("找不到 PlayerEvent，请检查游戏结构")
end

-- 1. 启用战斗模式
enableCombatMode()

-- 2. 设置弹药
if Settings.AutoReload then
    wait(0.2)
    setAmmo(Settings.AmmoAmount)
end

-- 3. 开始自动攻击循环
wait(0.3)
print("=== 开始自动攻击 ===")
print("武器: " .. Settings.WeaponName)
print("目标模式: " .. Settings.TargetMode)
print("攻击间隔: " .. Settings.AttackInterval .. "秒")
print("最大距离: " .. Settings.MaxDistance)

local attackCount = 0
local hitCount = 0

while wait(Settings.AttackInterval) do
    local success = attack()
    if success then
        attackCount = attackCount + 1
        hitCount = hitCount + 1
        
        -- 每10次攻击显示统计
        if attackCount % 10 == 0 then
            print("📊 统计: 攻击 " .. attackCount .. " 次 | 命中 " .. hitCount .. " 次")
        end
        
        -- 每30次攻击补充弹药
        if Settings.AutoReload and attackCount % 30 == 0 then
            wait(0.1)
            setAmmo(Settings.AmmoAmount)
        end
    end
end
    end
})
------=刷钱---===bot-
Tabs.bot:Button({
    Title = "ATM自动",
    Callback = function()       
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local AtmGui = Player.PlayerGui.ScreenGui.Center.Middle.HackingMinigames["ATM Hack"]
local BlockedColor = Color3.fromRGB(74, 75, 93)

local ClickedButtons = {}

local function GetCodes()
    local Codes = {}
    for Code in string.gmatch(AtmGui.Sequence1.Text, "([^%s]+)") do
        table.insert(Codes, Code)
    end
    return Codes
end

local function ClickButton(Button)
    local Pos = Button.AbsolutePosition
    local Size = Button.AbsoluteSize
    local X = Pos.X + Size.X/2
    local Y = Pos.Y + Size.Y/2
    VirtualInputManager:SendMouseButtonEvent(X, Y, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(X, Y, 0, false, game, 0)
end

while task.wait() do
    if AtmGui and AtmGui.Sequence1.Text ~= "" then
        local Codes = GetCodes()
        for _, Button in ipairs(AtmGui.List:GetDescendants()) do
            if Button:IsA("ImageButton") and not ClickedButtons[Button] and Button.ImageColor3 ~= BlockedColor then
                for _, Label in ipairs(Button:GetDescendants()) do
                    if Label:IsA("TextLabel") then
                        for _, Code in ipairs(Codes) do
                            if Label.Text == Code then
                                ClickButton(Button)
                                ClickedButtons[Button] = true
                                break
                            end
                        end
                    end
                    if ClickedButtons[Button] then break end
                end
            end
        end
    end
end
    end
})
Tabs.bot:Button({
    Title = "出租车",
    Callback = function()
        -- 自动出租车 无UI精简版

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer

local running = true

local orderCount = 0
local teleportCount = 0


-- 点击模拟
local function ClickAt(x, y)
    VirtualInputManager:SendMouseButtonEvent(
        x, y, 0, true, game, 0
    )

    task.wait(0.05)

    VirtualInputManager:SendMouseButtonEvent(
        x, y, 0, false, game, 0
    )
end


-- 自动接单
local function AcceptOrder()

    local camera = workspace.CurrentCamera
    local size = camera.ViewportSize

    local phoneX = size.X * 0.85
    local phoneY = size.Y * 0.35

    ClickAt(phoneX, phoneY)
    task.wait(0.3)

    ClickAt(phoneX, phoneY + 100)
    task.wait(0.3)

    ClickAt(phoneX, phoneY + 160)
    task.wait(0.3)

    ClickAt(phoneX, phoneY + 240)
    task.wait(0.3)

    orderCount += 1

    print("接单完成:", orderCount)

end



-- 查找目标位置
local function GetTargetPosition()

    local folder = workspace.Gameplay.Entities.ClientContent

    if not folder then
        return nil
    end


    for _, obj in ipairs(folder:GetDescendants()) do

        if obj:IsA("BasePart") then

            return obj.Position + Vector3.new(0,3,0)

        end

    end


    return nil
end



-- 移动角色
local function TeleportCharacter(pos)

    local char = Player.Character

    if not char then
        return false
    end


    local root = char:FindFirstChild("HumanoidRootPart")

    if not root then
        return false
    end


    root.CFrame = CFrame.new(pos)

    root.Velocity = Vector3.zero

    root.RotVelocity = Vector3.zero


    teleportCount += 1

    print("移动完成:", teleportCount)


    return true

end



-- 自动循环

task.spawn(function()

    print("自动出租车启动")


    while running do


        -- 接单

        print("正在接单")

        AcceptOrder()


        task.wait(1)



        -- 第一次移动

        local pos1 = GetTargetPosition()

        if pos1 then

            TeleportCharacter(pos1)

            print("第一次移动完成")

        else

            warn("未找到目标")

        end



        task.wait(2.5)



        -- 第二次移动

        local pos2 = GetTargetPosition()

        if pos2 then

            TeleportCharacter(pos2)

            print("第二次移动完成")

        else

            warn("未找到目标")

        end



        task.wait(2)

    end

end)
    end
})
-----====zx-----===
Tabs.szx:Button({
    Title = "删掉全图栅栏",
    Callback = function()
        local targetName = workspace.World.Important["Police Department"].Props:GetChildren()[7].Name

local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉全图路灯",
    Callback = function()
        local world = workspace:FindFirstChild("World")
if not world then
    warn("未找到 World")
    return
end

-- 1. 删除 workspace.World.Streetlights
local streetlights1 = world:FindFirstChild("Streetlights")
if streetlights1 then
    streetlights1:Destroy()
    print("已删除 World.Streetlights")
else
    warn("未找到 World.Streetlights")
end

-- 2. 删除 workspace.World.Season.Summer.Streetlights
local season = world:FindFirstChild("Season")
if season then
    local summer = season:FindFirstChild("Summer")
    if summer then
        local streetlights2 = summer:FindFirstChild("Streetlights")
        if streetlights2 then
            streetlights2:Destroy()
            print("已删除 World.Season.Summer.Streetlights")
        else
            warn("未找到 Summer.Streetlights")
        end
    else
        warn("未找到 Summer")
    end
else
    warn("未找到 Season")
end
    end
})
Tabs.szx:Button({
    Title = "删掉花坛",
    Callback = function()
        local props = workspace:FindFirstChild("World")
    and workspace.World:FindFirstChild("Props")

if not props then
    warn("未找到 World.Props")
    return
end

local children = props:GetChildren()
local target = children[480]

if not target then
    warn("未找到索引 [480] 的对象")
    return
end

local targetName = target.Name
print("目标物体名称: " .. targetName)

-- 删除服务器中所有同名的物体
local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉红绿灯罚款",
    Callback = function()
        local allTrafficLights = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == "Traffic Light" then
        table.insert(allTrafficLights, obj)
    end
end

for _, tl in pairs(allTrafficLights) do
    tl:Destroy()
end

print("已删除所有 Traffic Light，共 " .. #allTrafficLights .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉巴士站",
    Callback = function()
        -- 先获取 [73] 这个物体的名称
local props = workspace:FindFirstChild("World")
    and workspace.World:FindFirstChild("Season")
    and workspace.World.Season:FindFirstChild("Summer")
    and workspace.World.Season.Summer:FindFirstChild("Props")

if not props then
    warn("未找到 World.Season.Summer.Props")
    return
end

local children = props:GetChildren()
local target = children[73]

if not target then
    warn("未找到索引 [73] 的对象")
    return
end

local targetName = target.Name
print("目标物体名称: " .. targetName)

-- 删除服务器中所有同名的物体
local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉广告",
    Callback = function()
        local targetName = workspace.World.Props:GetChildren()[48].Name

local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉广告2",
    Callback = function()
        local targetName = workspace.World.Props["Ad Square"]:GetChildren()[12].Name

local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})
Tabs.szx:Button({
    Title = "删掉广告3",
    Callback = function()
        local targetName = workspace.World.Props:GetChildren()[56].Name

local toDelete = {}
for _, obj in pairs(workspace:GetDescendants()) do
    if obj.Name == targetName then
        table.insert(toDelete, obj)
    end
end

for _, obj in pairs(toDelete) do
    obj:Destroy()
end

print("已删除所有名为 '" .. targetName .. "' 的物体，共 " .. #toDelete .. " 个")
    end
})

Window:SelectTab(1)