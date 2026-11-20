-- da_hood.lua
local Players, UIS, RS = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("RunService")
local lp, cam = Players.LocalPlayer, workspace.CurrentCamera

local cfg = {
    silent = true, noclip = false, wallbang = true,
    part = "HumanoidRootPart", fov = 250, range = 1e5,
}

local function aimPoint()
    if UIS.TouchEnabled and not UIS.MouseEnabled then return cam.ViewportSize / 2 end
    return UIS:GetMouseLocation()
end

local function getTarget()
    local best, bd, ap = nil, cfg.fov, aimPoint()
    for _, p in ipairs(Players:GetPlayers()) do
        local c = p ~= lp and p.Character
        local part = c and c:FindFirstChild(cfg.part)
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if part and hum and hum.Health > 0 then
            local sp, on = cam:WorldToViewportPoint(part.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - ap).Magnitude
                if d < bd then best, bd = part, d end
            end
        end
    end
    return best
end

local function enemyChars()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then t[#t + 1] = p.Character end
    end
    return t
end

local old
old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() then
        local a = { ... }
        if cfg.silent and method == "FireServer" and self.Name == "MainEvent" and a[1] == "UpdateMousePos" then
            local t = getTarget()
            if t then a[2] = t.Position; return old(self, unpack(a)) end
        end
        if cfg.wallbang and self == workspace and method == "Raycast" and typeof(a[2]) == "Vector3" and a[2].Magnitude > 0 then
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Include
            rp.FilterDescendantsInstances = enemyChars()
            return old(self, a[1], a[2].Unit * cfg.range, rp)
        end
    end
    return old(self, ...)
end))

RS.Stepped:Connect(function()
    if not cfg.noclip then return end
    local c = lp.Character
    if not c then return end
    for _, v in ipairs(c:GetDescendants()) do
        if v:IsA("BasePart") then v.CanCollide = false end
    end
end)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DHPanel"; gui.ResetOnSpawn = false; gui.DisplayOrder = 999
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok then gui.Parent = lp:WaitForChild("PlayerGui") end

local function corner(o, r) local c = Instance.new("UICorner", o); c.CornerRadius = UDim.new(0, r or 8) end

local function drag(handle, target)
    local dragging, start, origin
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, start, origin = true, i.Position, target.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
end

local open = Instance.new("TextButton", gui)
open.Size = UDim2.fromOffset(46, 46); open.Position = UDim2.new(0, 12, 0.5, -23)
open.Text = "≡"; open.TextSize = 26; open.Font = Enum.Font.GothamBold
open.TextColor3 = Color3.new(1, 1, 1); open.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
corner(open, 23); drag(open, open)

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(230, 262); main.Position = UDim2.new(0.5, -115, 0.5, -131)
main.BackgroundColor3 = Color3.fromRGB(22, 22, 28); main.Visible = false
corner(main, 10)

local head = Instance.new("TextLabel", main)
head.Size = UDim2.new(1, 0, 0, 36); head.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
head.Text = "Da Hood"; head.Font = Enum.Font.GothamBold; head.TextSize = 15
head.TextColor3 = Color3.new(1, 1, 1); corner(head, 10)
drag(head, main)

open.Activated:Connect(function() main.Visible = not main.Visible end)

local y = 44
local function row(h) local f = Instance.new("Frame", main); f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, -20, 0, h or 38); f.Position = UDim2.fromOffset(10, y); y = y + (h or 38) + 6; return f end

local function toggle(label, key)
    local b = Instance.new("TextButton", row())
    b.Size = UDim2.fromScale(1, 1); b.Font = Enum.Font.Gotham; b.TextSize = 14
    b.TextColor3 = Color3.new(1, 1, 1); corner(b, 8)
    local function paint()
        b.Text = label .. ": " .. (cfg[key] and "ON" or "OFF")
        b.BackgroundColor3 = cfg[key] and Color3.fromRGB(40, 140, 80) or Color3.fromRGB(60, 60, 72)
    end
    b.Activated:Connect(function() cfg[key] = not cfg[key]; paint() end)
    paint()
    return paint
end

local pSilent, pNoclip, pWall = toggle("Silent Aim", "silent"), toggle("Noclip", "noclip"), toggle("Wallbang", "wallbang")

local pb = Instance.new("TextButton", row())
pb.Size = UDim2.fromScale(1, 1); pb.Font = Enum.Font.Gotham; pb.TextSize = 14
pb.TextColor3 = Color3.new(1, 1, 1); pb.BackgroundColor3 = Color3.fromRGB(60, 60, 72); corner(pb, 8)
local function paintPart() pb.Text = "Target: " .. (cfg.part == "Head" and "Head" or "Torso") end
pb.Activated:Connect(function() cfg.part = cfg.part == "Head" and "HumanoidRootPart" or "Head"; paintPart() end)
paintPart()

local fr = row()
local fl = Instance.new("TextLabel", fr)
fl.Size = UDim2.new(1, -90, 1, 0); fl.BackgroundTransparency = 1; fl.Font = Enum.Font.Gotham
fl.TextSize = 14; fl.TextColor3 = Color3.new(1, 1, 1); fl.TextXAlignment = Enum.TextXAlignment.Left
local function paintFov() fl.Text = "FOV: " .. cfg.fov end
paintFov()
for i, d in ipairs({ -25, 25 }) do
    local b = Instance.new("TextButton", fr)
    b.Size = UDim2.fromOffset(38, 38); b.Position = UDim2.new(1, i == 1 and -84 or -42, 0, 0)
    b.Text = d < 0 and "-" or "+"; b.Font = Enum.Font.GothamBold; b.TextSize = 18
    b.TextColor3 = Color3.new(1, 1, 1); b.BackgroundColor3 = Color3.fromRGB(60, 60, 72); corner(b, 8)
    b.Activated:Connect(function() cfg.fov = math.clamp(cfg.fov + d, 25, 800); paintFov() end)
end

-- PC keybinds (optional)
UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then main.Visible = not main.Visible
    elseif i.KeyCode == Enum.KeyCode.Q then cfg.silent = not cfg.silent; pSilent()
    elseif i.KeyCode == Enum.KeyCode.N then cfg.noclip = not cfg.noclip; pNoclip()
    elseif i.KeyCode == Enum.KeyCode.B then cfg.wallbang = not cfg.wallbang; pWall() end
end)
