Config = {}

Config.Models = {

    Local = {
        name = "qwen/qwen3-4b-2507",
        MaxTokens = 80000
    }
}

-- Choose the model here
Config.Model = Config.Models.Local
Config.MaxTokens = Config.Model.MaxTokens

return Config
