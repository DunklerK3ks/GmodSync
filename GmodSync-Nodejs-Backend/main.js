// ============================================================
// Garry's Mod API Backend (Node.js)
// Version 2.2 - DarkRP Stats + Spieler-Management
// ============================================================

import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

const app = express();
app.use(cors()); // erlaubt externe Dashboard-Zugriffe
app.use(bodyParser.json({ limit: "2mb" })); // erlaubt größere JSONs

// === KONFIGURATION ===
const API_TOKEN = process.env.API_TOKEN || "supersecret";
const PORT = process.env.PORT || 5050;

// === Speicher für letzten Status ===
let latestStatus = {
  message: "Noch keine Daten empfangen."
};

// === Middleware: Token-Überprüfung ===
function checkAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.replace("Bearer ", "").trim();
  if (token !== API_TOKEN) {
    console.log(`[API] Ungültiger Token von ${req.ip}`);
    return res.status(403).json({ error: "invalid token" });
  }
  next();
}

// === POST: Update vom Garry's Mod Server ===
app.post("/gmod/update", checkAuth, (req, res) => {
  latestStatus = {
    ...req.body,
    lastUpdate: new Date().toISOString(),
    from: req.ip
  };

  console.log("--------------------------------------------------");
  console.log(`[API] Update erhalten von ${req.ip}`);
  console.log(`Hostname: ${latestStatus.hostname || "?"}`);
  console.log(`Map: ${latestStatus.map || "?"}`);
  console.log(`Gamemode: ${latestStatus.gamemode || "?"}`);
  console.log(
    `Spieler: ${Array.isArray(latestStatus.players) ? latestStatus.players.length : 0}`
  );
  console.log("--------------------------------------------------");

  res.json({ success: true });
});

// === GET: Aktuellen Status abrufen (ohne Spielerliste) ===
app.get("/gmod/status", (req, res) => {
  const { players, ...statusWithoutPlayers } = latestStatus;
  res.json(statusWithoutPlayers);
});

// === GET: Nur Spielerliste ===
app.get("/gmod/players", (req, res) => {
  res.json(latestStatus.players || []);
});

// === GET: Einzelner Spieler (nach SteamID / SteamID64) ===
app.get("/gmod/player/:id", (req, res) => {
  const id = req.params.id.toLowerCase();
  const players = latestStatus.players || [];
  const player = players.find(
    (p) =>
      (p.steamid && p.steamid.toLowerCase() === id) ||
      (p.steamid64 && p.steamid64 === id)
  );

  if (!player) {
    return res.status(404).json({ error: "player not found" });
  }

  res.json(player);
});

// === GET: DarkRP Statistiken (berechnet live oder aus Payload) ===
app.get("/gmod/darkrp/stats", (req, res) => {
  const players = latestStatus.players || [];
  const darkrp = latestStatus.darkrp;

  // Wenn GMod bereits DarkRP-Stats mitschickt → direkt nutzen
  if (darkrp && darkrp.playerCount !== undefined) {
    return res.json(darkrp);
  }

  // Sonst selbst berechnen
  if (players.length === 0) {
    return res.json({
      playerCount: 0,
      wantedCount: 0,
      totalMoney: 0,
      avgMoney: 0,
      richestPlayer: null,
      jobDistribution: {}
    });
  }

  let totalMoney = 0;
  let wantedCount = 0;
  let richest = null;
  const jobDistribution = {};

  for (const p of players) {
    const money = Number(p.money) || 0;
    totalMoney += money;
    if (p.wanted) wantedCount++;
    if (!richest || money > richest.money) richest = p;
    const job = p.job || "Unknown";
    jobDistribution[job] = (jobDistribution[job] || 0) + 1;
  }

  const avgMoney = totalMoney / players.length;

  const stats = {
    playerCount: players.length,
    wantedCount,
    totalMoney,
    avgMoney,
    richestPlayer: richest ? richest.name : null,
    jobDistribution
  };

  res.json(stats);
});

// === Start Server ===
app.listen(PORT, () => {
  console.log("--------------------------------------------------");
  console.log(`[API] Läuft auf Port ${PORT}`);
  console.log(`[API] Token: ${API_TOKEN}`);
  console.log(`[API] Endpunkte:`);
  console.log(` - POST /gmod/update          (Server → API)`);
  console.log(` - GET  /gmod/status          (Serverstatus ohne Spieler)`);
  console.log(` - GET  /gmod/players         (komplette Spielerliste)`);
  console.log(` - GET  /gmod/player/:id      (einzelner Spieler per SteamID)`);
  console.log(` - GET  /gmod/darkrp/stats    (DarkRP-Wirtschaftsstatistik)`);
  console.log("--------------------------------------------------");
});
