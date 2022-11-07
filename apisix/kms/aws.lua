local aws = require("resty.aws")

local _M = {}

function _M.get(key)
    local config = require("resty.aws.config").global

    local aws = aws(config)
    --[[
        accessKeyId := "AKIAT7ACIDIIXMBOHHZQ"
	SecretKey := "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"
    ]]
    local my_creds = aws:Credentials {
        accessKeyId = "AKIAT7ACIDIIXMBOHHZQ",
        secretAccessKey = "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",
        sessionToken = "",
    }

    aws.config.credentials = my_creds

    local sm = aws:SecretsManager {
        region = "us-east-1",
    }

    local results, err = sm:getSecretValue {
        SecretId = key,
    }
    return results, err
end

return  _M