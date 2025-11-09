GM_API_CONFIG = {
    api_url = "http://127.0.0.1:5050/gmod/update",
    api_token = "supersecret",
    update_interval = 60,
    debug = true,

    -- === Chat Broadcast Settings ===
    chat_broadcast = {
        enabled = true, -- disable = false
        interval = 600, -- every 10 minutes
        message = "Thank you for using GModSync! If you need help or support, please contact the server owner."
    }
}
