local Secret = require("secret")

Config = {}

-- API providers
Config.APIs = {
    OpenAI = {
        name = "OpenAI",
        url = "https://api.openai.com/v1/chat/completions",
        key = Secret.TOKEN,
        format = "openai"
    },

    OpenRouter = {
        name = "OpenRouter",
        url = "https://openrouter.ai/api/v1/chat/completions",
        key = Secret.TOKEN,
        format = "openai"
    },

    Local = {
        name = "Local Server",
        url = "http://127.0.0.1:1234/v1/chat/completions",
        key = Secret.TOKEN, -- usually unused for local
        format = "openai"
    }
}

-- Model presets
Config.Models = {

    -- Local models
    LocalQwen = {
        api = "Local",
        name = "qwen/qwen3-1.7b",
        MaxTokens = 32000
    },

    LocalLlama = {
        api = "Local",
        name = "llama3",
        MaxTokens = 32000
    },

    -- OpenAI models
    GPT4o = {
        api = "OpenAI",
        name = "gpt-4o",
        MaxTokens = 128000
    },

    GPT4oMini = {
        api = "OpenAI",
        name = "gpt-4o-mini",
        MaxTokens = 128000
    },

    -- OpenRouter
    Qwen72B = {
        api = "OpenRouter",
        name = "qwen/qwen-72b-chat",
        MaxTokens = 32000
    }
}

-- Select model here
Config.Model = Config.Models.LocalQwen

-- Resolve API
Config.API = Config.APIs[Config.Model.api]

-- Token limit
Config.MaxTokens = Config.Model.MaxTokens

return Config
