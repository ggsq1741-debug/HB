-- ==================== WindUI 加载 ====================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ==================== 服务与变量 ====================
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local spinConnection = nil
local homePosition = nil
local globalExecCount = 0
local ToggleManager = {}

-- ==================== 计数 ====================
local function getGlobalExecCount()
    if getgenv and getgenv().GlobalExecCount then return getgenv().GlobalExecCount end
    local result = 0
    pcall(function()
        if syn and syn.crypt and syn.crypt.custom then
            local data = syn.crypt.custom("read", "black_script_exec_count.txt")
            if data then result = tonumber(data) or 0 end
        end
    end)
    if result == 0 then
        pcall(function()
            if readfile then
                local data = readfile("black_script_exec_count.txt")
                if data then result = tonumber(data) or 0 end
            end
        end)
    end
    if getgenv then getgenv().GlobalExecCount = result end
    return result
end

local function saveGlobalExecCount(count)
    if getgenv then getgenv().GlobalExecCount = count end
    pcall(function()
        if syn and syn.crypt and syn.crypt.custom then
            syn.crypt.custom("write", "black_script_exec_count.txt", tostring(count))
        end
    end)
    pcall(function()
        if writefile then writefile("black_script_exec_count.txt", tostring(count)) end
    end)
end

globalExecCount = getGlobalExecCount()
if globalExecCount == 0 then globalExecCount = 1 else globalExecCount = globalExecCount + 1 end
saveGlobalExecCount(globalExecCount)

-- ==================== 通知（保留原生，WindUI 也有自己的 Notify） ====================
local function Notify(Title1, Text1, Icon1, Time1)
    StarterGui:SetCore("SendNotification", {
        Title = Title1, Text = Text1, Icon = Icon1, Duration = Time1,
    })
end

-- ==================== 反挂机 ====================
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ==================== 工具函数 ====================
local function getHRP()
    local c = Players.LocalPlayer.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end
local function getHumanoid()
    local c = Players.LocalPlayer.Character
    if c then return c:FindFirstChildOfClass("Humanoid") end
    return nil
end

-- ==================== 时间 ====================
local function getTime()
    local now = os.date("*t")
    return now.year .. "年" .. now.month .. "月" .. now.day .. "日 " .. string.format("%02d", now.hour) .. ":" .. string.format("%02d", now.min) .. ":" .. string.format("%02d", now.sec)
end

task.spawn(function()
    task.wait(3)
    local hrp = getHRP()
    if hrp then homePosition = hrp.CFrame end
end)

-- ==================== 功能实现 ====================
ToggleManager.god = function(on)
    local c = Players.LocalPlayer.Character
    if not c then return end
    if on then
        local f = Instance.new("ForceField"); f.Name = "GodFF"; f.Parent = c
    else
        local f = c:FindFirstChild("GodFF"); if f then f:Destroy() end
    end
end
ToggleManager.superspeed = function(on)
    local h = getHumanoid(); if h then h.WalkSpeed = on and 1000 or 16 end
end
ToggleManager.infstamina = function(on) end
ToggleManager.infammo = function(on) end
ToggleManager.serverinfo = function(on)
    if on then
        local lines = {"服务器人数: " .. #Players:GetPlayers()}
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(lines, p.Name .. " | " .. math.floor(hrp.Position.X) .. "," .. math.floor(hrp.Position.Y) .. "," .. math.floor(hrp.Position.Z))
            end
        end
        Notify("服务器信息", table.concat(lines, "\n"), "", 5)
    end
end
ToggleManager.collect = function(on) end
ToggleManager.clicktp = function(on) end
ToggleManager.autoclick = function(on) end
ToggleManager.float = function(on) end
ToggleManager.antiafk = function(on) end
ToggleManager.speedhack = function(on) end
ToggleManager.noclip = function(on)
    local c = Players.LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = not on end
    end
end
ToggleManager.itemesp = function(on) end
ToggleManager.invisible = function(on) end
ToggleManager.deletepart = function(on) end
ToggleManager.clearfog = function(on)
    if on then Lighting.FogEnd = 100000; Lighting.FogStart = 100000
    else Lighting.FogEnd = 1000; Lighting.FogStart = 0 end
end
ToggleManager.infjump = function(on) end
ToggleManager.night = function(on) end
ToggleManager.fps = function(on) end
ToggleManager.esp = function(on) end
ToggleManager.teamglow = function(on) end
ToggleManager.enemyglow = function(on) end
ToggleManager.autoattack = function(on) end
ToggleManager.fulllight = function(on)
    Lighting.Brightness = on and 3 or 1
    if on then Lighting.ClockTime = 14 end
end
ToggleManager.suicide = function(on)
    if on then local h = getHumanoid(); if h then h.Health = 0 end end
end
ToggleManager.dance1 = function(on) end
ToggleManager.fire = function(on) end
ToggleManager.glow = function(on) end
ToggleManager.upsidedown = function(on) end
ToggleManager.bighead = function(on) end
ToggleManager.screenfx = function(on) end
ToggleManager.trail = function(on) end
ToggleManager.firetrail = function(on) end
ToggleManager.iceTrail = function(on) end
ToggleManager.rainbowname = function(on) end
ToggleManager.giant = function(on) end
ToggleManager.subtitle = function(on) end

-- ==================== 创建 WindUI 窗口 ====================
local Window = WindUI:CreateWindow({
    Title = "祈雪脚本中心",
    Icon = "sparkles",                -- Lucide 图标名
    Author = "祈雪",
    Folder = "QixueScript",
    Size = UDim2.fromOffset(600, 460),
    Transparent = true,
    Theme = "Dark",
    User = {
        Enabled = true,
        Anonymous = false,
    },
    SideBarWidth = 180,
    HasOutline = true,
})

-- ==================== 公告标签页 ====================
local AnnounceTab = Window:Tab({
    Title = "公告",
    Icon = "megaphone",
})

AnnounceTab:Section({ Title = "脚本信息" })

local AnnounceParagraph = AnnounceTab:Paragraph({
    Title = "欢迎使用 祈雪脚本",
    Desc = "⏰ " .. getTime() ..
        "\n\n👤 制作者 祈雪" ..
        "\n📅 创建日期：2026年10月1日" ..
        "\n🔄 此脚本一直更新" ..
        "\n\n📊 您目前已经执行了 " .. globalExecCount .. " 次，感谢您的支持！" ..
        "\n\n🎮 玩法：开启功能后在游戏中体验效果" ..
        "\n如果在游玩时遇到任何问题 请报告给我",
    Image = nil,
})

-- 尝试每秒更新一次公告的时间（部分 WindUI 版本支持 SetDesc）
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            if AnnounceParagraph and AnnounceParagraph.SetDesc then
                AnnounceParagraph:SetDesc(
                    "⏰ " .. getTime() ..
                    "\n\n👤 制作者 祈雪" ..
                    "\n📅 创建日期：2026年10月1日" ..
                    "\n🔄 此脚本一直更新" ..
                    "\n\n📊 您目前已经执行了 " .. globalExecCount .. " 次，感谢您的支持！" ..
                    "\n\n🎮 玩法：开启功能后在游戏中体验效果" ..
                    "\n如果在游玩时遇到任何问题 请报告给我"
                )
            end
        end)
    end
end)

-- ==================== 通用标签页 ====================
local GeneralTab = Window:Tab({
    Title = "通用",
    Icon = "settings",
})

-- 脚本加载按钮区
GeneralTab:Section({ Title = "脚本加载" })

local buttonItems = {
    {name = "飞行模式", desc = "远程加载飞行脚本", icon = "🕊️", url = "https://raw.githubusercontent.com/hgvuyguyg/jjjjjjjjj/refs/heads/main/%E9%A3%9E%E9%A5%BC"},
    {name = "通用自瞄fps", desc = "自动瞄准脚本", icon = "🎯", url = "https://raw.githubusercontent.com/hgvuyguyg/jjjjjjjjj/main/%E8%87%AA%E7%9E%84"},
    {name = "传送玩家", desc = "选择玩家传送到旁边", icon = "📬", url = "teleport"},
    {name = "跟随玩家", desc = "选择玩家自动跟随", icon = "🚶", url = "follow"},
    {name = "NTv3.3", desc = "多功能工具", icon = "🥚", url = "https://raw.githubusercontent.com/hgvuyguyg/jjjjjjjjj/main/nt"},
    {name = "无限罗宝", desc = "亲测可用", icon = "🌷", url = "https://raw.githubusercontent.com/hgvuyguyg/jjjjjjjjj/main/锁机"},
    {name = "Tx翻译", desc = "点击执行", icon = "⛽", url = "https://raw.githubusercontent.com/JsYb666/Item/refs/heads/main/Auto-language"},
    {name = "快速回家", desc = "传送到执行脚本时的位置", icon = "🏠", url = "home"},
}

for _, item in ipairs(buttonItems) do
    GeneralTab:Button({
        Title = item.icon .. " " .. item.name,
        Desc = item.desc,
        Callback = function()
            pcall(function()
                if item.url == "home" then
                    local hrp = getHRP()
                    if hrp and homePosition then hrp.CFrame = homePosition end
                elseif item.url == "teleport" or item.url == "follow" then
                    Notify("提示", "此功能需要选择玩家", "", 3)
                else
                    loadstring(game:HttpGet(item.url))()
                end
            end)
        end,
    })
end

-- 功能开关区
GeneralTab:Section({ Title = "功能开关" })

local toggleItems = {
    {name = "无敌模式", desc = "免疫伤害（客户端）", icon = "🛡️", code = "god"},
    {name = "千倍速度", desc = "移动速度1000", icon = "⚡", code = "superspeed"},
    {name = "无限体力", desc = "体力不会减少", icon = "💪", code = "infstamina"},
    {name = "无限弹药", desc = "弹药永远999", icon = "🔫", code = "infammo"},
    {name = "服务器信息", desc = "人数+坐标+附近玩家", icon = "📊", code = "serverinfo"},
    {name = "自动收集", desc = "自动吸附近物品", icon = "📦", code = "collect"},
    {name = "点击传送", desc = "鼠标点哪里传哪里", icon = "📍", code = "clicktp"},
    {name = "自动连点", desc = "自动点击屏幕准心", icon = "🖱️", code = "autoclick"},
    {name = "踏空", desc = "走到哪定到哪不往下掉", icon = "🦶", code = "float"},
    {name = "防挂机", desc = "自动防止被踢出游戏", icon = "⏰", code = "antiafk"},
    {name = "加速模式", desc = "游戏全局加速", icon = "⏩", code = "speedhack"},
    {name = "穿墙模式", desc = "可以穿过墙壁", icon = "👻", code = "noclip"},
    {name = "透视物品", desc = "高亮可拾取物品", icon = "✨", code = "itemesp"},
    {name = "隐身模式", desc = "别人看不到你", icon = "👻", code = "invisible"},
    {name = "删除建模", desc = "点击方块确认后删除", icon = "🗑️", code = "deletepart"},
    {name = "去雾功能", desc = "消除游戏中的雾气", icon = "🌫️", code = "clearfog"},
    {name = "无限跳跃", desc = "无限连续跳跃", icon = "⬆️", code = "infjump"},
    {name = "夜视功能", desc = "提高黑暗视野亮度", icon = "🔦", code = "night"},
    {name = "显示FPS", desc = "左上角帧率显示", icon = "📊", code = "fps"},
    {name = "ESP透视", desc = "红色描边+名字可穿墙", icon = "👁️", code = "esp"},
}

for _, item in ipairs(toggleItems) do
    GeneralTab:Toggle({
        Title = item.icon .. " " .. item.name,
        Desc = item.desc,
        Default = false,
        Callback = function(state)
            pcall(function() if ToggleManager[item.code] then ToggleManager[item.code](state) end end)
        end,
    })
end

-- 数值输入区
GeneralTab:Section({ Title = "数值设置" })

GeneralTab:Input({
    Title = "🔄 旋转速度",
    Desc = "角色自动旋转（0为关闭）",
    Value = "0",
    Callback = function(text)
        local v = tonumber(text)
        if not v then return end
        if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
        if v > 0 then
            local hrp = getHRP()
            if hrp then
                spinConnection = RunService.RenderStepped:Connect(function()
                    if hrp and hrp.Parent then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(v) / 60, 0)
                    end
                end)
            end
        end
    end,
})

GeneralTab:Input({
    Title = "🔭 广角",
    Desc = "摄像机视野 (默认70，最大120)",
    Value = "70",
    Callback = function(text)
        local v = tonumber(text)
        if v and v > 0 and v <= 120 then
            local cam = workspace.CurrentCamera
            if cam then cam.FieldOfView = v end
        end
    end,
})

GeneralTab:Input({
    Title = "⚡ 调速度",
    Desc = "移动速度",
    Value = "16",
    Callback = function(text)
        local v = tonumber(text)
        if v and v > 0 then
            local h = getHumanoid()
            if h then h.WalkSpeed = v end
        end
    end,
})

GeneralTab:Input({
    Title = "🦘 跳跃高度",
    Desc = "跳跃高度",
    Value = "50",
    Callback = function(text)
        local v = tonumber(text)
        if v and v > 0 then
            local h = getHumanoid()
            if h then h.JumpHeight = v end
        end
    end,
})

GeneralTab:Input({
    Title = "🌙 重力",
    Desc = "世界重力",
    Value = "196",
    Callback = function(text)
        local v = tonumber(text)
        if v and v > 0 then workspace.Gravity = v end
    end,
})

-- ==================== 战斗功能标签页 ====================
local CombatTab = Window:Tab({
    Title = "战斗功能",
    Icon = "swords",
})

local combatItems = {
    {name = "团队高亮", desc = "队友蓝色高亮", icon = "🔵", code = "teamglow"},
    {name = "敌对高亮", desc = "敌人红色高亮", icon = "🔴", code = "enemyglow"},
    {name = "自动攻击", desc = "自动追踪攻击敌人", icon = "⚔️", code = "autoattack"},
    {name = "全图点亮", desc = "消除所有阴影", icon = "💡", code = "fulllight"},
    {name = "一键自杀", desc = "立即重置角色", icon = "💀", code = "suicide"},
}

for _, item in ipairs(combatItems) do
    CombatTab:Toggle({
        Title = item.icon .. " " .. item.name,
        Desc = item.desc,
        Default = false,
        Callback = function(state)
            pcall(function() if ToggleManager[item.code] then ToggleManager[item.code](state) end end)
        end,
    })
end

-- ==================== 整活功能标签页 ====================
local FunTab = Window:Tab({
    Title = "整活功能",
    Icon = "party-popper",
})

local funItems = {
    {name = "跳舞-机械舞", desc = "机器人风格舞蹈", icon = "🤖", code = "dance1"},
    {name = "喷火模式", desc = "从角色身上喷火", icon = "🔥", code = "fire"},
    {name = "光环模式", desc = "角色发光环", icon = "✨", code = "glow"},
    {name = "倒立行走", desc = "角色倒过来", icon = "🙃", code = "upsidedown"},
    {name = "大头模式", desc = "头变得超大", icon = "🗿", code = "bighead"},
    {name = "全屏特效", desc = "屏幕加滤镜", icon = "🎨", code = "screenfx"},
    {name = "彩虹拖尾", desc = "移动时拖彩虹尾迹", icon = "🌈", code = "trail"},
    {name = "火焰拖尾", desc = "移动时拖火焰尾迹", icon = "🔥", code = "firetrail"},
    {name = "冰霜拖尾", desc = "移动时拖冰霜尾迹", icon = "❄️", code = "iceTrail"},
    {name = "管理员专属-彩虹名字", desc = "头顶名字变彩虹色", icon = "👑", code = "rainbowname"},
    {name = "巨大化", desc = "角色变得巨大", icon = "🦖", code = "giant"},
    {name = "字幕", desc = "屏幕显示字幕", icon = "💬", code = "subtitle"},
}

for _, item in ipairs(funItems) do
    FunTab:Toggle({
        Title = item.icon .. " " .. item.name,
        Desc = item.desc,
        Default = false,
        Callback = function(state)
            pcall(function() if ToggleManager[item.code] then ToggleManager[item.code](state) end end)
        end,
    })
end

-- ==================== 完成提示 ====================
WindUI:Notify({
    Title = "祈雪脚本中心",
    Content = "加载完成！已执行 " .. globalExecCount .. " 次",
    Duration = 5,
    Icon = "check-circle",
})
Notify("祈雪脚本中心", "加载完成！", "", 5)