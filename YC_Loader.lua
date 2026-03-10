print("Script Loader Started")

local Scripts = {
    [847722000] = "https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/The_Rake.lua",
    [2165551367] = "https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/Granny.lua",
    [7008097940] = "https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/InkGame.lua"
}

local GameId = game.GameId
print("Current GameId:", GameId)

local url = Scripts[GameId]

if url then
    print("found game")
    print("Loading script...")

    local success, err = pcall(function()
        loadstring(game:HttpGet(url))()
    end)

    if not success then
        warn("Script execution failed:", err)
    end
else
    warn("No script configured for this GameId.")
end
