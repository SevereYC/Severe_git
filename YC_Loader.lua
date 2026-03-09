local Scripts = {
    [847722000] = "https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/The_Rake.lua",
    [2165551367] = "https://raw.githubusercontent.com/SevereYC/Severe_git/refs/heads/main/Granny.lua"
}

local url = Scripts[game.PlaceId]

if url then
    loadstring(game:HttpGet(url))()
end
