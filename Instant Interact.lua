local ok, res = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/Robloxmemory.json")
end)

local offset
if ok then
    local HttpService = game:GetService("HttpService")
    local data = HttpService:JSONDecode(res)
    offset = data and data.ProximityPromptHoldDuraction and tonumber(data.ProximityPromptHoldDuraction, 16)
end

if offset then
    notify("Offset loaded: " .. tostring(offset), "Instant Interact", 3)
    
    task.spawn(function()
        while true do
            for _, prompt in ipairs(game:GetDescendants()) do
                if prompt.ClassName == "ProximityPrompt" then
                    pcall(function()
                        local promptAddress = prompt.Address
                        local targetAddress = promptAddress + offset
                        memory_write("float", targetAddress, 0)
                    end)
                end
            end
            task.wait(0.1)
        end
    end)
    
    notify("Instant Interact loaded!", "Success", 3)
else
    notify("Failed to load offset!", "Error", 5)
end
