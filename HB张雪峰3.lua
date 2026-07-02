Tab({ Title = "⚔️ 迷你战争", Icon = "sword" }),
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
  
