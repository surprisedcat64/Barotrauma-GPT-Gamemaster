JSON = require "json"
Actions = require "actions"
Helpers = require "helpers"
Secret = require "secret"
Config = require "config"

CallToFunction = {
    ["PlaceItem"] = Actions.PlaceItem,
    ["SendPrivateMessage"] = Actions.SendDM,
    ["Announce"] = Actions.Announce,
    ["SummonBeast"] = Actions.SpawnMonster,
    ["SabotageTool"] = Actions.SabotageTool,
    ["SabotageSuit"] = Actions.SabotageSuit,
    ["Revive"] = Actions.Revive,
    ["GrantInvulnerability"] = Actions.MakeInvincible,
    ["TeleportTo"] = Actions.TeleportCharacter,
    ["CureCharacter"] = Actions.CureCharacter,
    ["MakeIll"] = Actions.MakeIll,
    ["ReplaceHeldItem"] = Actions.ReplaceEquippedItem,
    ["SummonSwarm"] = Actions.SpawnSwarm
}

TokenBuffer = {}

MadPrompt = File.Read("/home/cat/.local/share/Steam/steamapps/common/Barotrauma/LocalMods/Barotrauma-AI-Gamemaster-master/Lua/resources/madGodPrompt.txt")
NormalPrompt = File.Read("/home/cat/.local/share/Steam/steamapps/common/Barotrauma/LocalMods/Barotrauma-AI-Gamemaster-master/Lua/resources/prompt.txt")
FunctionList = JSON.decode(File.Read("/home/cat/.local/share/Steam/steamapps/common/Barotrauma/LocalMods/Barotrauma-AI-Gamemaster-master/Lua/resources/functions.json"))

Prompt = NormalPrompt

-- Model now comes from config.lua
Model = Config.Model
Temperature = 1.4
MessageBuffer = {}
FunctionLen = 3260

Hook.Add("chatMessage", "admin commands", function(message, client) 
    if client.HasPermission(ClientPermissions.ManageSettings) then
        if message == "godswap" then
            if Prompt == NormalPrompt then
                Prompt = MadPrompt
                Temperature = 2
                Actions.Announce({message = "You swear you heard the water laughing at you"})
            else
                Temperature = 1
                Prompt = NormalPrompt
                Actions.Announce({message = "Things start to make a little more sense now"})
            end
            return true
        end
        if message == "stressTest" then
            print("stress test started")
            for i = 1, 2 * Model.MaxTokens do        
                Actions.Log(string.format("Stress Test Line Number %d", i))
            end
            return true
        end

    end
end)

local function appendTokens(tokens)
    if not next(TokenBuffer) then
        TokenBuffer = tokens
        return
    end
    local prev = TokenBuffer[#TokenBuffer]
    for token in tokens do
        table.insert(TokenBuffer, token+prev)
        prev = token
    end
end

function CleanMessage(response, message)
    local info = JSON.decode(response)
    if info.results[1].flagged then
        local flags = {}
        for key, val in pairs(info.results[1].categories) do
            if val then
                table.insert(flags,key)
            end
        end
        return string.format( "something flagged as: %s",table.concat(flags,", ") )
    end
    return message
end

-- local function addToBuffer(prompt, messages)
--     for message in messages do
--         local msg = {
--             role = "user",
--             content = message
--         }
--         table.insert( MessageBuffer , msg)
--     end
--     if (string.len(prompt) + FunctionLen)/4 >= Model.MaxTokens/2 then
--         if Model.name == Turbo.name then
--             Model = SixteenK
--         else
--             print("fatal error: context too damn big")
--         end
--     elseif Model.name == SixteenK.name and (string.len(prompt) + FunctionLen)/4 < Turbo.MaxTokens/2 then
--         Model = Turbo
--     end

--     while Helpers.TokenLength(MessageBuffer) >= Model.MaxTokens/2 do
--         table.remove(MessageBuffer,1)
--     end
    
-- end
local function propagate(value)
    for i = 1, #TokenBuffer do
        TokenBuffer[i] = TokenBuffer[i] - value
    end
end

local logPath = "/home/cat/.local/share/Steam/steamapps/common/Barotrauma/LocalMods/Barotrauma-AI-Gamemaster-master/Lua/resources/log.txt"
MessageBuffer = MessageBuffer or {}
local function addToBuffer(messages)
    -- Safety check: if messages is nil, don't try to loop
    if not messages then return { role = "user", content = "" } end

    for _, message in ipairs(messages) do
        table.insert(MessageBuffer, message)
    end

    local function getBufferLength()
        -- Another safety: ensure concat doesn't fail on empty table
        if #MessageBuffer == 0 then return 0 end
        return string.len(table.concat(MessageBuffer, "|"))
    end

    -- Prune until under 80k characters
    while getBufferLength() > 80000 and #MessageBuffer > 1 do
        table.remove(MessageBuffer, 1)
    end

    return {
        role = "user",
        content = table.concat(MessageBuffer, "|")
    }
end
        
-- Example of how you'd call this using your file:
function RefreshLogAndUpload()
    local logContent = File.Read(logPath)
    if logContent then
        -- Splitting the file into a table of lines
        local logLines = {}
        for line in logContent:gmatch("[^\r\n]+") do
            table.insert(logLines, line)
        end
        
        -- Clear old buffer and update with fresh file data
        MessageBuffer = {} 
        local msgPayload = addToBuffer(logLines)
        
        -- Now call your Upload function using this payload
        -- ...
    end
end


function Moderate(message, callback)
    local data = JSON.encode({input = message})
    Networking.HttpPost("https://api.openai.com/v1/moderations",callback, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
end

local function GeneratePrompt()

    local items = {
        name = {},
        description = {}
    }
    local characters = {
        name = {},
        info = {}
    }
    local prefabs = Helpers.GetRandomItems()
    for i = 1,10 do
        local prefab = prefabs[i]
        if not prefab then break end
        table.insert(items.name,tostring(prefab.Name))
        table.insert(items.description, string.format("%s: %s", tostring(prefab.Name),tostring(prefab.Description)))
    end
    for _,character in pairs(Character.CharacterList) do
        if character.IsPlayer then
            table.insert(characters.name, character.Name)
            table.insert(characters.info, Helpers.CharacterStatus(character))
        end
    end
    local itemString = string.format("Items (case sensitive): %s", table.concat( items.name, ", "))
    local itemDescriptions = string.format("Item Descriptions: %s", table.concat( items.description, ", "))
    local charString = string.format("Characters (case sensitive): %s\nCharacter Info: %s", Helpers.CharacterConcat(characters.name), table.concat( characters.info, ", "))
    return table.concat({Prompt, itemString,itemDescriptions, charString}, "\n")
end

-- function InitGPT()
--     local prompt = GeneratePrompt()
--     local functionFile = io.open("./resources/functions.json","r")
--     if not functionFile then
--         print("no functions found!!!!")
--         return
--     end
--     local functionList = JSON.decode(functionFile:read("*a"))
--     local data = JSON.encode({
--         model = "gpt-3.5-turbo",
--         messages = {
--             {
--                 role = "system",
--                 content = prompt
--             },
--             {
--                 role = "user",
--                 content = "You have awakened, Let the Characters know of your presence"
--             }
--         },
--         functions = functionList,
--         function_call = "auto"
--     })
--     print(data)
--     Networking.HttpPost("https://api.openai.com/v1/chat/completions",function (resolve)
--         print("GPT has awakened")
--         print(resolve)
--     end, data,"application/json",{["Authorization"] = string.format("Bearer %s", Secret.TOKEN)},nil)
-- end

local function execute(response)
    local data = JSON.decode(response)
    if not data or not data.choices then return end

    local message = data.choices[1].message
    
    -- Check for the 'tool_calls' array (LM Studio / Qwen 2.5 format)
    if message.tool_calls then
        for _, tool in ipairs(message.tool_calls) do
            local funcData = tool["function"]
            local funcName = funcData.name
            
            -- IMPORTANT: arguments is usually a JSON string, not a table.
            -- We decode it here so the functions in actions.lua receive a proper table.
            local ok, args = pcall(JSON.decode, funcData.arguments)
            
            if ok and CallToFunction[funcName] then
                print("GM AI Executing Action: " .. funcName)
                
                -- This calls the function in your actions.lua
                local success, err = pcall(function() CallToFunction[funcName](args) end)
                if not success then
                    print("Action failed to execute: " .. tostring(err))
                end
            else
                print("Action Error: Unknown function or malformed args -> " .. tostring(funcName))
            end
        end
    end
end

local function sendToGPT(data)
    Networking.HttpPost("http://127.0.0.1:1234/v1/chat/completions", function(resolve)
        -- Print the raw response from LM Studio so we can see any errors
        print("LM Studio Raw Response: " .. tostring(resolve))

        local ok, result = pcall(execute, resolve)
        if not ok then
            print("Execute function failed! Error: " .. tostring(result))
            -- Removed: Model = SixteenK (This was causing the nil crash!)
        end
    end, data, "application/json", {["Authorization"] = string.format("Bearer %s", Secret.TOKEN)}, nil)
end

function Upload(log, tokens)
    appendTokens(tokens)

    local prompt = {
        role = "system",
        content = GeneratePrompt()
    }

    local msg = addToBuffer(log)

    -- Wrap your existing functions into the new 'tools' format
    local toolsTable = {}
    for _, func in ipairs(FunctionList) do
        table.insert(toolsTable, {
            type = "function",
            ["function"] = func
        })
    end

    local data = JSON.encode({
        model = Model.name,
        messages = {
            prompt,
            msg
        },
        temperature = Temperature,
        -- LM Studio uses 'tools' instead of 'functions'
        tools = toolsTable,
        tool_choice = "auto"
    })

    sendToGPT(data)

    print("Request sent to LM Studio using Tools API")
    table.remove(MessageBuffer, 1)
end

return{
    Moderate = Moderate,
    CleanMessage = CleanMessage,
    Upload = Upload
}
