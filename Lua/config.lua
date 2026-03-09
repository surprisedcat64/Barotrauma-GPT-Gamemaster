Config = {}

Config.Models = {
    SixteenK = {
        name = "gpt-3.5-turbo-16k-0613",
        MaxTokens = 16000
    },

    Turbo = {
        name = "gpt-3.5-turbo-0613",
        MaxTokens = 4000
    }
}

-- Choose the model here
Config.Model = Config.Models.Turbo

return Config
