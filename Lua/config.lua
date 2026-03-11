Config = {}

Config.Models = {

    Local = {
        name = "qwen/qwen3-1.7b",
        MaxTokens = 80000
    }
}

-- Choose the model here
Config.Model = Config.Models.Local
Config.MaxTokens = Config.Model.MaxTokens

return Config
