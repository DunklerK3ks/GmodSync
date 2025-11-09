# 🔗 GModSync – Live Server API + Backend Integration

**GModSync** is a complete integration system for **Garry’s Mod** that connects your server directly to a real-time **Node.js backend**.  
It provides a powerful JSON API to monitor players, gamemode stats, and DarkRP economy data — perfect for dashboards, Discord bots, or analytics tools.

---

## 🚀 Features

- 🔄 Real-time data sync between GMod and Node.js backend  
- 👮 DarkRP and SAM rank integration  
- 🧠 Live server statistics (map, gamemode, uptime, FPS, players)  
- 💰 Full DarkRP economy overview (money, jobs, wanted players, richest player)  
- ⚙️ Configurable update interval and chat broadcast  
- 🧩 Easy installation with `config.lua`  
- 🌍 Open-source Node.js backend included  

---

## 🧱 Repository Structure

```
GmodSync/
├── backend/                # Node.js API server
│   ├── main.js
│   ├── package.json
│   └── README.md
└── garrysmod_addon/        # GMod Lua Addon
    └── lua/
        ├── config/
        │   └── config.lua
        └── autorun/
            └── server/
                └── gmodsync.lua
```

---

## 🧩 Garry’s Mod Addon Setup

### 1️⃣ Installation

Place the addon in your server’s addon folder:
```
garrysmod/addons/gmodsync/
```

Make sure you have the **reqwest** module installed:  
📦 [gmsv_reqwest (by timschumi)](https://github.com/timschumi/gmsv_reqwest/releases)

Copy the correct `.dll` or `.so` file into:
```
garrysmod/lua/bin/
```

---

### 2️⃣ Configuration

Create the file:

```
addons/gmodsync/lua/config/config.lua
```

Example config:

```lua
GM_API_CONFIG = {
    api_url = "http://your-server-ip:5050/gmod/update",
    api_token = "supersecret",
    update_interval = 60,
    debug = false,

    chat_broadcast = {
        enabled = true,
        interval = 600,
        message = "Thank you for using GModSync! Need help? Contact the server owner."
    }
}
```

| Key | Description |
|------|--------------|
| `api_url` | The backend endpoint where your GMod server sends data |
| `api_token` | Secret token for authentication |
| `update_interval` | Seconds between automatic status updates |
| `chat_broadcast.enabled` | Enables a global in-game message |
| `chat_broadcast.interval` | Time between messages (in seconds) |
| `chat_broadcast.message` | The broadcast text |

---

## ⚙️ Backend Setup (Node.js)

The backend receives live data and exposes public API endpoints.

### Requirements
- Node.js v18 or higher  
- Internet access (port 5050 open)

### Installation

```bash
cd backend
npm install
npm start
```

The backend will start on:
```
http://localhost:5050
```

You can change the port or token inside `main.js` if needed.

---

## 🌐 API Endpoints

| Method | Route | Description |
|---------|--------|-------------|
| `POST` | `/gmod/update` | Receives updates from your GMod server |
| `GET` | `/gmod/status` | Returns server status (no player list) |
| `GET` | `/gmod/players` | Returns all players currently online |
| `GET` | `/gmod/player/:id` | Returns data for one player (SteamID or SteamID64) |
| `GET` | `/gmod/darkrp/stats` | Returns global DarkRP job & money stats |

Example Response:
```json
{
  "hostname": "StarWarsRP Server",
  "map": "rp_coruscant",
  "gamemode": "starwarsrp (base: DarkRP)",
  "ip": "194.15.38.52",
  "uptime": 5321,
  "fps": 66,
  "maxplayers": 64,
  "darkrp": {
    "playerCount": 18,
    "wantedCount": 3,
    "avgMoney": 147444
  }
}
```

---

## 💬 Chat Broadcast

By default, GModSync sends a chat message every 10 minutes:

> “Thank you for using GModSync! If you need help or support, please contact the server owner.”

You can change or disable this message inside your `config.lua`.

---

## 🧠 Example Use Cases

- Live web dashboard for admins  
- Player & server monitoring panels  
- Discord bot integration for server stats  
- RP economy analytics (DarkRP / StarWarsRP)  
- Multi-server management with one backend  

---

## 🧾 License

This project is open source under the **MIT License**.  
You may freely use and modify it for your own servers or community projects.  
Attribution to **GModSync** is appreciated but not required.

---

## ❤️ Credits

- **Developer:** [DunklerK3ks](https://github.com/DunklerK3ks)  
- **HTTP Module:** [gmsv_reqwest by timschumi](https://github.com/timschumi/gmsv_reqwest)  
- **Contributors:** Open-source community  

---

## 🌍 Links

🔗 **Repository:** [https://github.com/DunklerK3ks/GmodSync](https://github.com/DunklerK3ks/GmodSync)  
⚙️ **Backend Folder:** [View on GitHub →](https://github.com/DunklerK3ks/GmodSync/tree/main/backend)  
📬 **Issues & Support:** [Open a Ticket](https://github.com/DunklerK3ks/GmodSync/issues)

---

### 🚀 GModSync – "Your Server, Connected."
