local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local function getParent()
    local s, p = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if s and p then return p end
    return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "FullScreenImage"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getParent()

local img = Instance.new("ImageLabel")
img.Name = "ScaryImage"
img.Size = UDim2.new(1, 0, 1, 0)
img.Position = UDim2.new(0, 0, 0, 0)
img.BackgroundTransparency = 1
img.ScaleType = Enum.ScaleType.Crop
img.ZIndex = 999999
img.ImageTransparency = 1
img.Parent = gui

TweenService:Create(img, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()

local sound = Instance.new("Sound")
sound.Name = "ScarySound"
sound.SoundId = "rbxassetid://76280794937714"
sound.Volume = 10
sound.Looped = true
sound.Parent = SoundService
sound:Play()

local imageUrl = "https://i.postimg.cc/FzjyyS6b/1000055384.jpg"
local assetPath = "WindUI/Scary/assets/.scary-image.png"
local Request = http_request or (syn and syn.request) or request

if Request and writefile and getcustomasset then
    task.spawn(function()
        local success, response = pcall(function()
            return Request({
                Url = imageUrl,
                Method = "GET",
                Headers = {["User-Agent"] = "Roblox/Exploit"}
            })
        end)
        if success and response and response.Body and #response.Body > 100 then
            pcall(function()
                writefile(assetPath, response.Body)
                local ok, asset = pcall(getcustomasset, assetPath)
                if ok and asset then
                    img.Image = asset
                else
                    img.Image = imageUrl
                end
            end)
        else
            pcall(function()
                img.Image = imageUrl
            end)
        end
    end)
else
    pcall(function()
        img.Image = imageUrl
    end)
end

pcall(function()
    gui.DescendantRemoving:Connect(function(child)
        if child == img or child == gui then
            task.wait()
            if not gui.Parent then
                gui.Parent = getParent()
            end
            if not img.Parent then
                img.Parent = gui
            end
        end
    end)
end)
