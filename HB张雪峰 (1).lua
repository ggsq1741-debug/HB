local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/KingScriptAE/No-sirve-nada./refs/heads/main/main.lua"))()
-- 注意：上述链接是您原始脚本中使用的 WindUI 加载地址，请确保它有效。
-- 如果无效，可替换为官方地址：https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua

-- 2. 创建主窗口（使用 WindUI）
local Window = WindUI:CreateWindow({
  Title = "HB整合脚本", -- 标题
  Author = "User", -- 作者
  Folder = "MyHub", -- 配置保存文件夹
  Transparent = true, -- 透明背景（毛玻璃）
  Theme = "Dark", -- 深色主题
  SideBarWidth = 130, -- 侧边栏宽度
  HideSearchBar = true, -- 隐藏搜索栏
  ScrollBarEnabled = true, -- 启用滚动条
  Background = "https://i.postimg.cc/QCmLqygD/Image-1781800826160-343.jpg", -- 背景图
  BackgroundImageTransparency = 0.3, -- 透明度
  User = {
    Enabled = false, -- 禁用用户信息
  },
})

-- 3. 窗口控制（Win11三键）—— 使用原生Frame覆盖
local function AddWindowControls()
  local screenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
  local mainFrame = Window.UIElements.Main -- WindUI 的主框架

  -- 创建标题栏（覆盖在顶部）
  local titleBar = Instance.new("Frame")
  titleBar.Size = UDim2.new(1, 0, 0, 32)
  titleBar.Position = UDim2.new(0, 0, 0, 0)
  titleBar.BackgroundTransparency = 1
  titleBar.Parent = mainFrame
  titleBar.ZIndex = 10

  -- 辅助：使标题栏可拖动（通过 WindUI 内置拖动可能已支持，但我们加强）
  -- 由于 WindUI 本身支持拖动，我们只需确保三键不干扰拖动即可。

  -- 创建三个按钮（仿Win11）
  local function createButton(text, xPos, hoverColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 26)
    btn.Position = UDim2.new(1, xPos, 0.5, -13)
    btn.BackgroundTransparency = 0
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 16
    btn.Font = Enum.Font.SourceSansBold
    btn.BorderSizePixel = 0
    btn.Parent = titleBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn
    btn.MouseEnter:Connect(function()
      btn.BackgroundColor3 = hoverColor or Color3.fromRGB(60, 60, 70)
    end)
    btn.MouseLeave:Connect(function()
      btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
  end

  local function minimize()
    -- 最小化：隐藏主窗口，显示小图标（这里简单隐藏）
    mainFrame.Visible = false
    -- 可添加小图标恢复功能（此处略）
  end

  local function maximize()
    -- 最大化/还原
    if mainFrame.Size == UDim2.new(1, 0, 1, 0) then
      mainFrame.Size = UDim2.new(0, 560, 0, 460)
      mainFrame.Position = UDim2.new(0.5, -280, 0.5, -230)
     else
      mainFrame.Size = UDim2.new(1, 0, 1, 0)
      mainFrame.Position = UDim2.new(0, 0, 0, 0)
    end
  end

  local function close()
    mainFrame:Destroy()
    screenGui:Destroy()
  end

  createButton("—", -0, nil, minimize)
  createButton("□", -0, nil, maximize)
  createButton("o", -0, Color3.fromRGB(0, 0, 0), close)
end

-- 等待窗口创建完成再添加控制
task.wait(0.5)
AddWindowControls()

-- 4. 创建标签页和功能（完全照搬原脚本）
local Tabs = {
  zho = Window:Tab({ Title = "通用", Icon = "zho" }),
  Lemon = Window:Tab({ Title = "🍋 柠檬脚本", Icon = "lemon" }),
  Lucky = Window:Tab({ Title = "🏆 踢幸运方块", Icon = "trophy" }),
  MiniWar = Window:Tab({ Title = "⚔️ 迷你战争", Icon = "sword" }),
  doors = Window:Tab({ Title = "d🚪oo🚪rs", Icon = "doors" }),
  dao = Window:Tab({ Title = "🗡️刀刃球🗡️", Icon = "dao" }),
}

--通用
local zhoSection = Tabs.zho:Section({ Title = "通用" })
zhoSection:Paragraph({
  Title = "通用:",
  Desc = "",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
zhoSection:Button({
  Title = "随机传送",
  Callback = function()
    -- line: [0, 0] id: 177
    local r0_177 = loadstring(game:HttpGet("https://gist.githubusercontent.com/skid123skidlol/cd0d2dce51b3f20ad1aac941da06a1a1/raw/f58b98cce7d51e53ade94e7bb460e4f24fb7e0ff/%257BFE%257D%2520Invisible%2520Tool%2520(can%2520hold%2520tools)", true))
    r0_177()
    return
  end
})
zhoSection:Button({
  Title = "飞行fly",
  Callback = function()
    -- line: [0, 0] id: 39
  local r0_38 = loadstring(game:HttpGet("https://raw.githubusercontent.com/rodan-demirali/RobloxUI/refs/heads/main/flyUIscript"))
  r0_38()
  return
  end
})
zhoSection:Button({
  Title = "esp",
  Callback = function()
    -- line: [0, 0] id: 38
  local r0_38 = loadstring(game:HttpGet("https://raw.githubusercontent.com/wa0101/Roblox-ESP/refs/heads/main/esp.lua"))
  r0_38()
  return 
  end
})
zhoSection:Button({
  Title = "穿墙",
  Callback = function()
    -- line: [0, 0] id: 37
  local r0_38 = loadstring(game:HttpGet("https://raw.githubusercontent.com/sandakovandrej23-art/ROBLOXNOCLIPGUI/refs/heads/main/Noclipgui.lua"))
  r0_38()
  return 
  end
})
zhoSection:Button({
  Title = "修改移速",
  Callback = function()
    -- line: [0, 0] id: 36
  local r0_38 = loadstring(game:HttpGet("https://raw.githubusercontent.com/tiger-v1/RobloxSpeedJump.GUI/refs/heads/main/SpeedJumpGUI.lua"))
  r0_38()
  return 
  end
})

-- 柠檬脚本标签页
local lemonSection = Tabs.Lemon:Section({ Title = "柠檬脚本" })
lemonSection:Paragraph({
  Title = "柠檬脚本:",
  Desc = "备注",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
lemonSection:Button({
  Title = "卖柠檬1",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Fluxyyy333/HoshiOnTop/main/loader.lua"))()
  end
})
lemonSection:Button({
  Title = "卖柠檬2",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Kenniel123/Sell-Lemons/refs/heads/main/Sell%20Lemons"))()
  end
})
lemonSection:Button({
  Title = "卖柠檬3",
  Callback = function()
    loadstring(game:HttpGet("https://rblxscripts.net/raw/axonic-hub-best-script-76ab7a48"))()
  end
})

-- 踢幸运方块标签页
local luckySection = Tabs.Lucky:Section({ Title = "🏆 踢一个幸运的方块" })
luckySection:Paragraph({
  Title = "[🏆] 踢一个幸运的方块:",
  Desc = "",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
luckySection:Button({
  Title = "[🏆] 踢一个幸运的方块1",
  Callback = function()
    loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/d130dee84ed1d9ccecfd6a91fc49665b.lua"))()
  end
})
luckySection:Button({
  Title = "[🏆] 踢一个幸运的方块2",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/gumanba/Scripts/main/KickaLuckyBlock"))()
  end
})

-- 迷你战争标签页
local miniSection = Tabs.MiniWar:Section({ Title = "迷你战争" })
miniSection:Paragraph({
  Title = "迷你战争:",
  Desc = "自动收集选定物品，按自定义市场价格条件出售，升级技能，根据优先级攻击敌人，并领取任务奖励。它还包括突袭追踪、可调节延迟、过滤销售、传送选项、商店工具、服务器功能、杂项工具以及可配置的设置标签页",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
miniSection:Button({
  Title = "迷你战争1",
  Callback = function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/LynX99-9/komtolmmek2script/refs/heads/main/CyraaHub.lua", true))()
  end
})

--doors标签页
local doorsSection = Tabs.doors:Section({ Title = "doors🚪" })
luckySection:Paragraph({
  Title = "doors:",
  Desc = "功能较多",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
doorsSection:Button({
  Title = "doors",
  Callback = function()loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/ef9b5a30ec84e201b585c3ef1850d264b216441eab77257f0e9184de826cc47e/download"))()

  end
})
doorsSection:Button({
  Title = "doors🚪",
  Callback = function()loadstring(game:HttpGet("https://raw.githubusercontent.com/ROSHANDVS2/ROSHAN-HUB-SCRIPTS/refs/heads/main/ROSHAN-DOORS-PAGUE-HUB.lua"))()

  end
})

--刀
local daoSection = Tabs.dao:Section({ Title = "dao" })
Tabs.dao:Paragraph({
  Title = "刀刃球:",
  Desc = "备注",
  Image = "https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ",
  ImageSize = 20,
  ThumbnailSize = 120
})
daoSection:Button({
  Title = "🗡️刀刃球1🗡️",
  Callback = function()loadstring(game:HttpGet('https://levi-hub-x.vercel.app/Loader.lua'))()

  end
})
daoSection:Button({
  Title = "刀刃球2",
  Callback = function()loadstring(game:HttpGet('https://levi-hub-x.vercel.app/Loader.lua'))()

  end
})