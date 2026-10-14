‎```lua
‎-- Roblox ESP + Auto-Aim + Auto-Headshot
‎-- Android Delta — zero keyboard, pure touch
‎-- Runtime: Delta Executor Android
‎
‎local Players = game:GetService("Players")
‎local RunService = game:GetService("RunService")
‎local UserInputService = game:GetService("UserInputService")
‎local Camera = workspace.CurrentCamera
‎local LocalPlayer = Players.LocalPlayer
‎
‎local CFG = {
‎    ESP = true,
‎    TeamCheck = true,
‎    Aimbot = true,
‎    FOV = 170,
‎    Smooth = 0.28,
‎    AutoHeadshot = true,
‎    BoxColor = Color3.fromRGB(255, 40, 40),
‎    TracerColor = Color3.fromRGB(255, 220, 0),
‎    NameColor = Color3.fromRGB(255, 255, 255),
‎}
‎
‎local drawings = {}
‎local aiming = false
‎local last_esp = 0
‎local buttons = {}
‎
‎local function safe(fn)
‎    local ok, err = pcall(fn)
‎    if not ok then warn("[KEEL]", err) end
‎end
‎
‎local function get_root(char)
‎    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
‎end
‎
‎local function get_head(char)
‎    return char and char:FindFirstChild("Head")
‎end
‎
‎local function is_alive(plr)
‎    local char = plr.Character
‎    if not char then return false end
‎    local hum = char:FindFirstChildOfClass("Humanoid")
‎    return hum and hum.Health > 0
‎end
‎
‎local function is_enemy(plr)
‎    if not CFG.TeamCheck then return true end
‎    if not LocalPlayer.Team or not plr.Team then return true end
‎    return LocalPlayer.Team ~= plr.Team
‎end
‎
‎local function world_to_screen(pos)
‎    local ok, screen, on = pcall(Camera.WorldToViewportPoint, Camera, pos)
‎    if not ok then return Vector2.zero, false end
‎    return Vector2.new(screen.X, screen.Y), on
‎end
‎
‎local function create_drawings(plr)
‎    safe(function()
‎        if drawings[plr] then return end
‎        local box = Drawing.new("Square")
‎        box.Visible = false
‎        box.Color = CFG.BoxColor
‎        box.Thickness = 1.4
‎        box.Filled = false
‎
‎        local tracer = Drawing.new("Line")
‎        tracer.Visible = false
‎        tracer.Color = CFG.TracerColor
‎        tracer.Thickness = 1
‎
‎        local name = Drawing.new("Text")
‎        name.Visible = false
‎        name.Color = CFG.NameColor
‎        name.Size = 15
‎        name.Center = true
‎        name.Outline = true
‎        name.Text = plr.Name
‎
‎        drawings[plr] = {box = box, tracer = tracer, name = name}
‎    end)
‎end
‎
‎local function remove_drawings(plr)
‎    safe(function()
‎        local d = drawings[plr]
‎        if d then
‎            d.box:Remove()
‎            d.tracer:Remove()
‎            d.name:Remove()
‎            drawings[plr] = nil
‎        end
‎    end)
‎end
‎
‎local function update_esp()
‎    for plr, d in pairs(drawings) do
‎        safe(function()
‎            if not is_alive(plr) or not is_enemy(plr) or plr == LocalPlayer then
‎                d.box.Visible = false
‎                d.tracer.Visible = false
‎                d.name.Visible = false
‎                return
‎            end
‎
‎            local char = plr.Character
‎            local root = get_root(char)
‎            local head = get_head(char)
‎            if not root or not head then
‎                d.box.Visible = false
‎                d.tracer.Visible = false
‎                d.name.Visible = false
‎                return
‎            end
‎
‎            local top_pos = (head.CFrame * CFrame.new(0, 0.9, 0)).Position
‎            local bot_pos = (root.CFrame * CFrame.new(0, -2.5, 0)).Position
‎            local top, on_top = world_to_screen(top_pos)
‎            local bot, on_bot = world_to_screen(bot_pos)
‎            local root_s = world_to_screen(root.Position)
‎
‎            if not on_top or not on_bot then
‎                d.box.Visible = false
‎                d.tracer.Visible = false
‎                d.name.Visible = false
‎                return
‎            end
‎
‎            local height = math.abs(top.Y - bot.Y)
‎            local width = height * 0.55
‎
‎            d.box.Size = Vector2.new(width, height)
‎            d.box.Position = Vector2.new(top.X - width / 2, top.Y)
‎            d.box.Visible = CFG.ESP
‎
‎            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
‎            d.tracer.To = root_s
‎            d.tracer.Visible = CFG.ESP
‎
‎            d.name.Position = Vector2.new(top.X, top.Y - 18)
‎            d.name.Visible = CFG.ESP
‎        end)
‎    end
‎end
‎
‎local function get_closest()
‎    local closest, dist = nil, CFG.FOV
‎    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
‎
‎    for _, plr in ipairs(Players:GetPlayers()) do
‎        if plr ~= LocalPlayer and is_alive(plr) and is_enemy(plr) then
‎            local head = get_head(plr.Character)
‎            if head then
‎                local screen, on = world_to_screen(head.Position)
‎                if on then
‎                    local d = (screen - center).Magnitude
‎                    if d < dist then
‎                        dist = d
‎                        closest = head
‎                    end
‎                end
‎            end
‎        end
‎    end
‎    return closest
‎end
‎
‎-- on-screen touch buttons (no keyboard)
‎local function make_button(text, pos, size, callback)
‎    local bg = Drawing.new("Square")
‎    bg.Filled = true
‎    bg.Color = Color3.fromRGB(30, 30, 30)
‎    bg.Transparency = 0.35
‎    bg.Size = size
‎    bg.Position = pos
‎    bg.Visible = true
‎
‎    local label = Drawing.new("Text")
‎    label.Text = text
‎    label.Size = 14
‎    label.Center = true
‎    label.Outline = true
‎    label.Color = Color3.fromRGB(255, 255, 255)
‎    label.Position = Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2 - 7)
‎    label.Visible = true
‎
‎    table.insert(buttons, {bg = bg, label = label, pos = pos, size = size, cb = callback})
‎end
‎
‎local screen = Camera.ViewportSize
‎local btn_w, btn_h = 90, 36
‎local gap = 8
‎local start_x = 12
‎local start_y = screen.Y - (btn_h + 12) * 4
‎
‎make_button("AIM", Vector2.new(start_x, start_y), Vector2.new(btn_w, btn_h), function()
‎    aiming = not aiming
‎end)
‎make_button("ESP", Vector2.new(start_x, start_y + (btn_h + gap)), Vector2.new(btn_w, btn_h), function()
‎    CFG.ESP = not CFG.ESP
‎end)
‎make_button("AIMBOT", Vector2.new(start_x, start_y + (btn_h + gap) * 2), Vector2.new(btn_w, btn_h), function()
‎    CFG.Aimbot = not CFG.Aimbot
‎end)
‎make_button("HEAD", Vector2.new(start_x, start_y + (btn_h + gap) * 3), Vector2.new(btn_w, btn_h), function()
‎    CFG.AutoHeadshot = not CFG.AutoHeadshot
‎end)
‎
‎UserInputService.InputBegan:Connect(function(input, gp)
‎    if gp then return end
‎    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
‎
‎    local pos = input.Position
‎    for _, b in ipairs(buttons) do
‎        if pos.X >= b.pos.X and pos.X <= b.pos.X + b.size.X and
‎           pos.Y >= b.pos.Y and pos.Y <= b.pos.Y + b.size.Y then
‎            b.cb()
‎            break
‎        end
‎    end
‎end)
‎
‎-- safer namecall
‎local old
‎old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
‎    local method = getnamecallmethod()
‎    local args = {...}
‎    if CFG.AutoHeadshot and method == "FireServer" then
‎        if typeof(args[1]) == "CFrame" or typeof(args[1]) == "Vector3" then
‎            local target = get_closest()
‎            if target then
‎                args[1] = target.CFrame
‎                return old(self, unpack(args))
‎            end
‎        end
‎    end
‎    return old(self, ...)
‎end))
‎
‎RunService.Heartbeat:Connect(function()
‎    local now = tick()
‎    if CFG.ESP and now - last_esp > 0.033 then
‎        last_esp = now
‎        update_esp()
‎    end
‎
‎    if CFG.Aimbot and aiming then
‎        local target = get_closest()
‎        if target then
‎            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
‎            Camera.CFrame = Camera.CFrame:Lerp(goal, CFG.Smooth)
‎        end
‎    end
‎end)
‎
‎for _, plr in ipairs(Players:GetPlayers()) do
‎    if plr ~= LocalPlayer then
‎        task.spawn(function()
‎            task.wait(1.2)
‎            create_drawings(plr)
‎        end)
‎        plr.CharacterAdded:Connect(function()
‎            task.wait(1.2)
‎            create_drawings(plr)
‎        end)
‎    end
‎end
‎
‎Players.PlayerAdded:Connect(function(plr)
‎    task.wait(1.2)
‎    create_drawings(plr)
‎    plr.CharacterAdded:Connect(function()
‎        task.wait(1.2)
‎        create_drawings(plr)
‎    end)
‎end)
‎
‎Players.PlayerRemoving:Connect(remove_drawings)
‎
‎print("[KEEL] pure-touch Android build | tap AIM / ESP / AIMBOT / HEAD buttons bottom-left")
‎```