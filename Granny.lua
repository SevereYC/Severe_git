-- Item ESP | Auto-scan + safe cleanup + rescan on new round
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local workspace, Drawing, WorldToScreen, ipairs, pairs, task = workspace, Drawing, WorldToScreen, ipairs, pairs, task

local toggle  = { esp = true }
local keyHeld = { f1  = false }
local FONT    = Drawing.Fonts.System
local STUDS_TO_METERS = 1 / 3.5714285714
local DEFAULT_COLOR   = Color3.fromHex("#85e2ff")

local function newDrawText(props)
    local t = Drawing.new("Text")
    t.Font    = FONT
    t.Outline = true
    for k, v in pairs(props) do t[k] = v end
    return t
end

local tList          = {}
local tracked        = {}
local scannedFolders = {}
local folderConns    = {}

-- Snapshot of Tools folder instances from the last scan
-- Used to detect if the map has been replaced with a new instance
local knownToolsFolders = {}

local function resetAll()
    for _, v in ipairs(tList) do
        pcall(function() v.nameLabel:Remove() end)
        pcall(function() v.distLabel:Remove() end)
    end
    for _, conn in pairs(folderConns) do
        pcall(function() conn:Disconnect() end)
    end
    tList          = {}
    tracked        = {}
    scannedFolders = {}
    folderConns    = {}
    knownToolsFolders = {}
end

local function addTool(tool)
    if not tool or not tool.Parent then return end
    local addr = tostring(tool)
    if tracked[addr] then return end

    local anchor
    if tool:IsA("Model") then
        anchor = tool.PrimaryPart or tool:FindFirstChildWhichIsA("BasePart", true)
    elseif tool:IsA("BasePart") then
        anchor = tool
    end
    if not anchor then return end

    tracked[addr] = true
    tList[#tList + 1] = {
        rootObj   = tool,
        object    = anchor,
        nameLabel = newDrawText{ Text = tool.Name, Color = DEFAULT_COLOR,             Center = true, Size = 14, Visible = false },
        distLabel = newDrawText{ Text = "[0m]",    Color = Color3.fromHex("#cacaca"), Center = true, Size = 12, Visible = false },
        address   = addr,
    }
end

local function scanToolsFolder(folder)
    local faddr = tostring(folder)
    if scannedFolders[faddr] then return end
    scannedFolders[faddr] = true

    for _, tool in pairs(folder:GetChildren()) do
        addTool(tool)
    end

    local ok, conn = pcall(function()
        return folder.ChildAdded:Connect(function(tool)
            task.wait(0.05)
            addTool(tool)
        end)
    end)
    if ok and conn then folderConns[faddr] = conn end
end

local function collectToolsFolders()
    local found = {}
    local mapRoot = workspace:FindFirstChild("Map")
    if not mapRoot then return found end
    for _, mapFolder in pairs(mapRoot:GetChildren()) do
        if mapFolder:IsA("Folder") or mapFolder:IsA("Model") then
            local tools = mapFolder:FindFirstChild("Tools")
            if tools then
                found[tostring(tools)] = tools
            end
        end
    end
    return found
end

local function scanAllMaps()
    local current = collectToolsFolders()

    -- Check if Tools folders changed (new round loaded)
    local changed = false
    for addr in pairs(current) do
        if not knownToolsFolders[addr] then changed = true; break end
    end
    if not changed then
        for addr in pairs(knownToolsFolders) do
            if not current[addr] then changed = true; break end
        end
    end

    if changed then
        resetAll()
        knownToolsFolders = current
    end

    for _, folder in pairs(current) do
        scanToolsFolder(folder)
    end
end

local function updatePositions()
    if not toggle.esp then
        for _, v in ipairs(tList) do
            v.nameLabel.Visible = false
            v.distLabel.Visible = false
        end
        return
    end

    local rx, ry, rz
    local ch = lp.Character
    if ch then
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            local p = hrp.Position
            rx, ry, rz = p.X, p.Y, p.Z
        end
    end

    for i = #tList, 1, -1 do
        local v = tList[i]

        local ok, pos = pcall(function()
            return v.rootObj.Parent
               and v.object.Parent
               and v.object.Position
        end)

        if not ok or not pos or pos == true then
            pcall(function() v.nameLabel:Remove() end)
            pcall(function() v.distLabel:Remove() end)
            tracked[v.address] = nil
            tList[i] = tList[#tList]
            tList[#tList] = nil
        else
            local screenPos, onScreen = WorldToScreen(pos)
            if onScreen then
                local studs  = rx and (((pos.X-rx)^2+(pos.Y-ry)^2+(pos.Z-rz)^2)^0.5) or 0
                local meters = math.floor(studs * STUDS_TO_METERS)
                v.nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - 13)
                v.distLabel.Position = Vector2.new(screenPos.X, screenPos.Y + 1)
                v.distLabel.Text     = "[" .. meters .. "m]"
                v.nameLabel.Visible  = true
                v.distLabel.Visible  = true
            else
                v.nameLabel.Visible = false
                v.distLabel.Visible = false
            end
        end
    end
end

spawn(function()
    while true do
        scanAllMaps()
        task.wait(1)
    end
end)

spawn(function()
    while true do
        updatePositions()

        if iskeypressed(0x70) then
            if not keyHeld.f1 then
                keyHeld.f1 = true
                toggle.esp = not toggle.esp
                if not toggle.esp then
                    for _, v in ipairs(tList) do
                        v.nameLabel.Visible = false
                        v.distLabel.Visible = false
                    end
                end
            end
        else
            keyHeld.f1 = false
        end

        task.wait()
    end
end)

print("Item ESP loaded | F1 = toggle ESP")
notify("Loaded","Granny",4)
