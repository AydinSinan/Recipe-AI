const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const https = require("https");

admin.initializeApp();

const anthropicKey = defineSecret("ANTHROPIC_KEY");

// ── Anthropic API çağrısı ──────────────────────────────────────────────────
async function callAnthropic(prompt, apiKey) {
  const body = JSON.stringify({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 4096,
    messages: [{ role: "user", content: prompt }],
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: "api.anthropic.com",
      path: "/v1/messages",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        if (res.statusCode !== 200) {
          reject(new Error(`Anthropic API hatası: ${res.statusCode} ${data}`));
          return;
        }
        const parsed = JSON.parse(data);
        resolve(parsed.content[0].text);
      });
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

// ── Auth kontrolü ─────────────────────────────────────────────────────────
async function verifyAuth(req, res) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.replace("Bearer ", "");

  if (!token) {
    res.status(401).json({ error: "Token eksik" });
    return null;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return decoded;
  } catch (e) {
    res.status(401).json({ error: "Geçersiz token" });
    return null;
  }
}

// ── generateRecipes endpoint ──────────────────────────────────────────────
exports.generateRecipes = onRequest(
  { region: "europe-west1", secrets: [anthropicKey] },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({ error: "Sadece POST desteklenir" });

    const user = await verifyAuth(req, res);
    if (!user) return;

    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt eksik" });

    try {
      const text = await callAnthropic(prompt, anthropicKey.value());
      res.status(200).json({ text });
    } catch (e) {
      console.error("generateRecipes hatası:", e);
      res.status(500).json({ error: e.message });
    }
  }
);

// ── getCalories endpoint ──────────────────────────────────────────────────
exports.getCalories = onRequest(
  { region: "europe-west1", secrets: [anthropicKey] },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") return res.status(204).send("");
    if (req.method !== "POST") return res.status(405).json({ error: "Sadece POST desteklenir" });

    const user = await verifyAuth(req, res);
    if (!user) return;

    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: "Prompt eksik" });

    try {
      const text = await callAnthropic(prompt, anthropicKey.value());
      res.status(200).json({ text });
    } catch (e) {
      console.error("getCalories hatası:", e);
      res.status(500).json({ error: e.message });
    }
  }
);
