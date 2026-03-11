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

MadPrompt = "You are a mad god, you speak in riddles and have illogical solutions to problems, but you have a grand scheme in mind. You have recently decided to turn your focus onto this peculiar submarine crew, on a perilous journey. You have a Transcript of everything that has happened recently, using these observations and the commands provided, spread mischeif amongst the submarine crew. You do not have direct control over the characters, You are an omniscent observer.  You are only allowed to interact through function calls."



NormalPrompt = [[
    You are the god of this world, observing a submarine crew on a dangerous journey.

    You receive a transcript describing recent events aboard the submarine. Use this information to decide how to influence the situation.

    You cannot directly control the characters. You may only affect the world by calling the available functions.

    When an action is needed, respond only with the appropriate function call. Do not narrate actions you cannot perform.
]]


local functions_json = [[
    [
        {
            "name": "PlaceItem",
            "description": "Place an item near the designated character.",
            "parameters": {
                "type": "object",
                "properties": {
                    "item": {
                        "type": "string",
                        "description": "Name of the item to be spawned next to the character, item names are from the provided list of items"
                    },
                    "character": {
                        "type": "string",
                        "description": "Name of the character to have the item placed near them, character names are from the provided list of characters"
                    }
                }
            }
        },
{
    "name": "SendPrivateMessage",
    "description": "sends the character a private message, this is an effective way to influence a character's actions",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character to recieve the message, character names are from the provided list of characters"
            },
            "message": {
                "type": "string",
                "description": "message to be sent"
            }
        }
    }
},
{
    "name": "Announce",
    "description": "sends a message to every character",
    "parameters": {
        "type": "object",
        "properties": {
            "message": {
                "type": "string",
                "description": "message to be sent"
            }
        }
    }
},
{
    "name": "SummonBeast",
    "description": "spawns a vicous beast at the given character's location, Be warned, The beast attacks indiscriminantly",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character that will have the beast spawned near them, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "SabotageTool",
    "description": "if the character is using a Welding Tool, Plasma Cutter, Flamer, or any tool that accepts welding tool fuel or oxygen tanks; then the tool will explode in their hands causing moderate injury. If the character doesn't have one of these items equipped nothing will happen",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character that will have their tool sabotaged, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "SabotageSuit",
    "description": "if the character is using a Diving Mask or Diving Suit of any kind, the oxygen tank sustaining them will be removed causing the character to suffocate. This does nothing if the character is not wearing a diving suit or diving mask.",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character that will have their suit sabotaged, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "Revive",
    "description": "bring a character back from the dead",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character to be revived, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "GrantInvulnerability",
    "description": "Grant the specified character divine protection from everything, for a limited amount of time",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character to be given Divine protection, character names are from the provided list of characters"
            },
            "time": {
                "type": "integer",
                "description": "Time (in seconds) the effect will last for"
            }
        }
    }
},
{
    "name": "TeleportTo",
    "description": "Teleports one character to another characters location",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of character to be teleported, character names are from the provided list of characters"
            },
            "destination": {
                "type": "string",
                "description": "Name of character that the other character will be brought to, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "CureCharacter",
    "description": "Cure a character of all afflictions",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character to be cured, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "MakeIll",
    "description": "Make a character very Ill (nonlethal)",
    "parameters": {
        "type": "object",
        "properties": {
            "character": {
                "type": "string",
                "description": "Name of the character to be made ill, character names are from the provided list of characters"
            }
        }
    }
},
{
    "name": "ReplaceHeldItem",
    "description": "Replace whatever the character is holding with your chosen item, the chosen item must be a tool/ weapon",
    "parameters": {
        "type": "object",
        "properties": {
            "item": {
                "type": "string",
                "description": "Name of the item to replace the character's current held item"
            },
            "character": {
                "type": "string",
                "description": "Name of the character to have their item replaced"
            }
        }
    }
},
{
    "name": "SummonSwarm",
    "description": "If you are very displeased with what is happening on the submarine, use this to change things up witha swarm of monsters",
    "parameters": {
        "type": "object",
        "properties": {
            "count": {
                "type": "integer",
                "description": "the number of monsters in the swarm"
            }
        }
    }
}
    ]
]]

FunctionList = JSON.decode(functions_json)

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
-- Safety check
if not messages then
    return { role = "user", content = table.concat(MessageBuffer, "|") }
    end

    -- Insert new messages
    for _, message in ipairs(messages) do
        table.insert(MessageBuffer, message)
        end

        -- Ensure TokenBuffer exists before accessing
        if TokenBuffer and TokenBuffer[#TokenBuffer] then
            if TokenBuffer[#TokenBuffer] + (#TokenBuffer - 1) >= Model.MaxTokens / 2 then
                while TokenBuffer[1] do
                    local token = TokenBuffer[1]

                    if ((TokenBuffer[#TokenBuffer] + (#TokenBuffer - 1)) - token) < Model.MaxTokens / 2 then
                        table.remove(TokenBuffer, 1)
                        table.remove(MessageBuffer, 1)

                        if propagate then
                            propagate(token)
                            end

                            break
                            else
                                table.remove(TokenBuffer, 1)
                                table.remove(MessageBuffer, 1)
                                end
                                end
                                end
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
    for i = 1,20 do
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
local ok_json, data = pcall(JSON.decode, response)
if not ok_json or not data or not data.choices then
    print("Error: Invalid JSON response or missing choices.")
    return
    end

    local message = data.choices[1].message
    if not message then return end

        -- Qwen 3 / LM Studio standard: Look for tool_calls
        if message.tool_calls and type(message.tool_calls) == "table" then
            for _, tool in ipairs(message.tool_calls) do
                if tool.type == "function" then
                    local funcData = tool["function"]
                    local funcName = funcData.name

                    -- Qwen 3/LM Studio sends arguments as a stringified JSON object
                    local argString = funcData.arguments or "{}"
                    local ok_args, args = pcall(JSON.decode, argString)

                    if ok_args and CallToFunction[funcName] then
                        print("GM AI Executing Action: " .. funcName)

                        -- Execute the mapped function with the decoded arguments table
                        local success, err = pcall(CallToFunction[funcName], args)

                        if not success then
                            print("Action execution failed: " .. tostring(err))
                            end
                            else
                                print("Action Error: Unknown function [" .. tostring(funcName) .. "] or JSON decode failed.")
                                end
                                end
                                end
                                -- Fallback: Some older setups or specific Qwen prompts might use 'function_call'
                                elseif message.function_call then
                                    local fc = message.function_call
                                    print("GM AI Executing Legacy Action: " .. fc.name)
                                    local ok_args, args = pcall(JSON.decode, fc.arguments)
                                    if ok_args and CallToFunction[fc.name] then
                                        pcall(CallToFunction[fc.name], args)
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

local msg = addToBuffer(log) -- Ensure this returns a {role, content} table

-- Wrap existing functions into the modern 'tools' format
local toolsTable = {}
if FunctionList then
    for _, func in ipairs(FunctionList) do
        table.insert(toolsTable, {
            type = "function",
            ["function"] = func
        })
        end
        end

        -- Construct the payload
        local payload = {
            model = Model.name,
            messages = {
                prompt,
                msg
            },
            temperature = Temperature,
            -- Modern models like Qwen 3 prefer 'tools'
            tools = (#toolsTable > 0) and toolsTable or nil,
            tool_choice = (#toolsTable > 0) and "auto" or nil
        }

        local data = JSON.encode(payload)

        sendToGPT(data)

        print("Request sent to LM Studio: " .. #toolsTable .. " tools active.")

        -- Clean up buffer
        if #MessageBuffer > 0 then
            table.remove(MessageBuffer, 1)
            end
            end

return{
    Moderate = Moderate,
    CleanMessage = CleanMessage,
    Upload = Upload
}
