-- ============================================================
-- GModSync – Garry's Mod → Node.js API Integration
-- Version 2.5 – DarkRP + SAM Rank + Config + Debug + Chat Broadcast
-- ============================================================

if SERVER then
    -- === Load Config ===
    if not file.Exists("config/config.lua", "LUA") then
        print("[GModSync] ERROR: Config file missing! Expected at lua/config/config.lua")
        return
    end

    include("config/config.lua")

    local CONFIG = GM_API_CONFIG or {}
    local API_URL = CONFIG.api_url or "http://127.0.0.1:5050/gmod/update"
    local API_TOKEN = CONFIG.api_token or "changeme"
    local UPDATE_INTERVAL = CONFIG.update_interval or 60
    local DEBUG = CONFIG.debug or false

    -- === Chat Broadcast Settings ===
    local CHAT_BROADCAST = CONFIG.chat_broadcast or {
        enabled = true,
        interval = 600, -- 10 minutes
        message = "Thank you for using GModSync! If you need help or support, please contact the server owner."
    }

    -- === Load reqwest module ===
    local ok, err = pcall(require, "reqwest")
    if not ok then
        print("[GModSync] Failed to load reqwest module:", err)
        return
    end

    -- === Utility Functions ===
    local function DebugPrint(...)
        if DEBUG then
            print("[GModSync DEBUG]", ...)
        end
    end

    local function GetServerIP()
        local ip = game.GetIPAddress() or "unknown"
        ip = string.Explode(":", ip)[1]
        return ip
    end

    local function GetCurrentGamemode()
        local folder = "unknown"
        local base = "unknown"
        if GAMEMODE then
            folder = GAMEMODE.FolderName or GAMEMODE.Folder or "unknown"
            if GAMEMODE.BaseClass and GAMEMODE.BaseClass.Name then
                base = GAMEMODE.BaseClass.Name
            elseif GAMEMODE.BaseClass and GAMEMODE.BaseClass.FolderName then
                base = GAMEMODE.BaseClass.FolderName
            end
        end
        if base ~= "unknown" and base:lower() ~= folder:lower() then
            return string.format("%s (base: %s)", folder, base)
        end
        return folder
    end

    -- === Collect player information (DarkRP + SAM support) ===
    local function GetPlayerData()
        local players = {}
        for _, ply in ipairs(player.GetAll()) do
            local job = ply.getDarkRPVar and ply:getDarkRPVar("job") or "N/A"
            local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
            local wanted = ply.getDarkRPVar and ply:getDarkRPVar("wanted") or false
            local sam_rank = "user"

            if SAM and SAM.GetRank then
                sam_rank = SAM.GetRank(ply:SteamID64()) or "user"
            elseif ply.GetUserGroup then
                sam_rank = ply:GetUserGroup()
            end

            table.insert(players, {
                name = ply:Nick(),
                steamid = ply:SteamID(),
                steamid64 = ply:SteamID64(),
                ping = ply:Ping(),
                job = job,
                money = money,
                wanted = wanted,
                health = ply:Health(),
                armor = ply:Armor(),
                team = team.GetName(ply:Team()) or ply:Team(),
                sam_rank = sam_rank
            })
        end
        return players
    end

    -- === Build DarkRP statistics ===
    local function GetDarkRPStats(players)
        if not players or #players == 0 then
            return {
                playerCount = 0,
                wantedCount = 0,
                totalMoney = 0,
                avgMoney = 0,
                richestPlayer = "none",
                jobDistribution = {}
            }
        end

        local totalMoney, wantedCount = 0, 0
        local richest = nil
        local jobDistribution = {}

        for _, p in ipairs(players) do
            local money = tonumber(p.money) or 0
            totalMoney = totalMoney + money
            if p.wanted then wantedCount = wantedCount + 1 end
            if not richest or money > (richest.money or 0) then richest = p end
            local job = p.job or "Unknown"
            jobDistribution[job] = (jobDistribution[job] or 0) + 1
        end

        return {
            playerCount = #players,
            wantedCount = wantedCount,
            totalMoney = totalMoney,
            avgMoney = math.floor(totalMoney / #players),
            richestPlayer = richest and richest.name or "none",
            jobDistribution = jobDistribution
        }
    end

    -- === Build full payload for API ===
    local function BuildPayload()
        local players = GetPlayerData()
        local darkrpStats = GetDarkRPStats(players)

        local payload = {
            hostname   = GetHostName(),
            map        = game.GetMap(),
            gamemode   = GetCurrentGamemode(),
            ip         = GetServerIP(),
            uptime     = math.floor(SysTime()),
            fps        = math.floor(1 / engine.TickInterval()),
            maxplayers = game.MaxPlayers(),
            players    = players,
            darkrp     = darkrpStats
        }

        DebugPrint("Payload created:", util.TableToJSON(payload))
        return payload
    end

    -- === Send status to Node.js API ===
    local function sendStatus()
        local payload = BuildPayload()

        reqwest({
            method = "POST",
            url = API_URL,
            type = "application/json",
            body = util.TableToJSON(payload),
            headers = {
                ["Authorization"] = "Bearer " .. API_TOKEN,
                ["User-Agent"] = "GMod-Server"
            },
            success = function(status)
                print(string.format("[GModSync] Update sent successfully (%d)", status))
            end,
            failed = function(err, errExt)
                print("[GModSync] Failed to send update:", err, "(", errExt, ")")
            end
        })
    end

    -- === Automatic updates ===
    timer.Create("GModSync_AutoUpdate", UPDATE_INTERVAL, 0, sendStatus)

    -- === Player events ===
    hook.Add("PlayerInitialSpawn", "GModSync_OnJoin", function(ply)
        timer.Simple(5, sendStatus)
    end)

    hook.Add("PlayerDisconnected", "GModSync_OnLeave", function(ply)
        timer.Simple(2, sendStatus)
    end)

    -- === Periodic chat broadcast ===
    if CHAT_BROADCAST.enabled then
        timer.Create("GModSync_ChatBroadcast", CHAT_BROADCAST.interval, 0, function()
            for _, ply in ipairs(player.GetAll()) do
                ply:ChatPrint(CHAT_BROADCAST.message)
            end
            print("[GModSync] Broadcast message sent to all players.")
        end)
    end

    -- === Manual command ===
    concommand.Add("gmapi_sendupdate", function(ply)
        if IsValid(ply) then
            ply:ChatPrint("[GModSync] Only the server console can execute this command.")
            return
        end
        print("[GModSync] Manual update triggered...")
        sendStatus()
    end)

    -- === Info output ===
    print(string.rep("-", 60))
    print("[GModSync] Player Management API active!")
    print("[GModSync] Configuration:")
    print("  URL:        " .. API_URL)
    print("  Token:      " .. API_TOKEN)
    print("  Interval:   " .. UPDATE_INTERVAL .. " seconds")
    print("  Debug:      " .. tostring(DEBUG))
    print("  Broadcast:  " .. tostring(CHAT_BROADCAST.enabled) .. " (every " .. CHAT_BROADCAST.interval .. "s)")
    print(string.rep("-", 60))
end
