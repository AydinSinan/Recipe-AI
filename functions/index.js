const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const https = require("https");

admin.initializeApp();

const anthropicKey = defineSecret("ANTHROPIC_KEY");

// Bağlantıyı sıcak tutup TCP+TLS handshake'i tekrarlamamak için paylaşılan agent
const anthropicAgent = new https.Agent({ keepAlive: true, maxSockets: 10 });

// ── CORS ────────────────────────────────────────────────────────────────
function setCors(res) {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

// ── Anthropic API çağrısı ──────────────────────────────────────────────────
async function callAnthropic(prompt, apiKey, maxTokens = 4096) {
    const body = JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: maxTokens,
        messages: [{ role: "user", content: prompt }],
    });

    return new Promise((resolve, reject) => {
        const options = {
            hostname: "api.anthropic.com",
            path: "/v1/messages",
            method: "POST",
            agent: anthropicAgent,
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
                    reject(
                        new Error(
                            `Anthropic API hatası: ${res.statusCode} ${data}`,
                        ),
                    );
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

async function callAnthropicStream(prompt, apiKey, maxTokens, onText) {
    const body = JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: maxTokens,
        stream: true,
        messages: [{ role: "user", content: prompt }],
    });

    return new Promise((resolve, reject) => {
        const options = {
            hostname: "api.anthropic.com",
            path: "/v1/messages",
            method: "POST",
            agent: anthropicAgent,
            headers: {
                "Content-Type": "application/json",
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
                "Content-Length": Buffer.byteLength(body),
            },
        };

        const req = https.request(options, (res) => {
            if (res.statusCode !== 200) {
                let errData = "";
                res.on("data", (chunk) => (errData += chunk));
                res.on("end", () =>
                    reject(
                        new Error(
                            `Anthropic API hatası: ${res.statusCode} ${errData}`,
                        ),
                    ),
                );
                return;
            }

            let buffer = "";
            res.setEncoding("utf8");
            res.on("data", (chunk) => {
                buffer += chunk;
                let boundary;
                while ((boundary = buffer.indexOf("\n\n")) !== -1) {
                    const rawEvent = buffer.slice(0, boundary);
                    buffer = buffer.slice(boundary + 2);
                    for (const line of rawEvent.split("\n")) {
                        if (!line.startsWith("data:")) continue;
                        const jsonStr = line.slice(5).trim();
                        if (!jsonStr) continue;
                        try {
                            const evt = JSON.parse(jsonStr);
                            if (
                                evt.type === "content_block_delta" &&
                                evt.delta?.type === "text_delta"
                            ) {
                                onText(evt.delta.text);
                            } else if (evt.type === "error") {
                                reject(
                                    new Error(
                                        `Anthropic stream hatası: ${JSON.stringify(evt.error)}`,
                                    ),
                                );
                            }
                        } catch (_) {
                            // parse edilemeyen event'i yok say
                        }
                    }
                }
            });
            res.on("end", resolve);
            res.on("error", reject);
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

// ── FCM Topic Sender ──────────────────────────────────────────────────────
async function sendToTopic(topic, title, body) {
    await admin.messaging().send({
        topic,
        notification: { title, body },
        android: {
            notification: {
                channelId: "recipeai_channel",
                icon: "ic_launcher",
                sound: "default",
            },
        },
        apns: {
            payload: { aps: { badge: 1, sound: "default" } },
        },
    });
}

// ── Günlük Tarif Bildirimi — Her gün 09:00 Türkiye ────────────────────────
exports.dailyRecipeNotification = onSchedule(
    {
        schedule: "0 9 * * *",
        timeZone: "Europe/Istanbul",
        region: "europe-west1",
    },
    async () => {
        await Promise.all([
            sendToTopic(
                "daily_recipe_tr",
                "🍳 Bugün ne pişirelim?",
                "Elindeki malzemelerle harika tarifler seni bekliyor!",
            ),
            sendToTopic(
                "daily_recipe_en",
                "🍳 What to cook today?",
                "Amazing recipes with your ingredients are waiting!",
            ),
        ]);
        console.log("Günlük tarif bildirimi gönderildi.");
    },
);

// ── Haftalık Plan Hatırlatıcısı — Her Pazar 18:00 Türkiye ─────────────────
exports.weeklyMealPlanReminder = onSchedule(
    {
        schedule: "0 18 * * 0",
        timeZone: "Europe/Istanbul",
        region: "europe-west1",
    },
    async () => {
        await Promise.all([
            sendToTopic(
                "weekly_plan_tr",
                "📅 Bu haftanı planladın mı?",
                "Haftalık yemek planını oluştur, alışveriş listeni hazırla!",
            ),
            sendToTopic(
                "weekly_plan_en",
                "📅 Did you plan your week?",
                "Create your weekly meal plan and grocery list!",
            ),
        ]);
        console.log("Haftalık plan hatırlatıcısı gönderildi.");
    },
);

// ── Yeniden Katılım — Her gün 11:00 Türkiye (3 gün açmayanlara) ───────────
exports.reEngagementNotification = onSchedule(
    {
        schedule: "0 11 * * *",
        timeZone: "Europe/Istanbul",
        region: "europe-west1",
    },
    async () => {
        const db = admin.firestore();
        const threeDaysAgo = new Date();
        threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

        const snapshot = await db
            .collection("users")
            .where("lastLoginAt", "<=", threeDaysAgo)
            .where("isPremium", "==", true)
            .get();

        if (snapshot.empty) return;

        const tokens = snapshot.docs
            .map((doc) => doc.data().fcmToken)
            .filter(Boolean);

        if (tokens.length === 0) return;

        // 500'lük gruplara böl (FCM limiti)
        for (let i = 0; i < tokens.length; i += 500) {
            const chunk = tokens.slice(i, i + 500);
            await admin.messaging().sendEachForMulticast({
                tokens: chunk,
                notification: {
                    title: "🌮 Seni özledik!",
                    body: "Bugün ne pişireceğini bulmana yardım edelim.",
                },
                android: {
                    notification: {
                        channelId: "recipeai_channel",
                        icon: "ic_launcher",
                    },
                },
                apns: { payload: { aps: { badge: 1 } } },
            });
        }
        console.log(
            `Yeniden katılım bildirimi ${tokens.length} kullanıcıya gönderildi.`,
        );
    },
);

// ── generateRecipes endpoint ──────────────────────────────────────────────
exports.generateRecipes = onRequest(
    { region: "europe-west1", secrets: [anthropicKey], invoker: "public" },
    async (req, res) => {
        setCors(res);
        if (req.method === "OPTIONS") return res.status(204).send("");
        if (req.method !== "POST")
            return res.status(405).json({ error: "Sadece POST desteklenir" });

        const user = await verifyAuth(req, res);
        if (!user) return;

        const { prompt } = req.body;
        if (!prompt) return res.status(400).json({ error: "Prompt eksik" });

        let headersSent = false;
        try {
            await callAnthropicStream(
                prompt,
                anthropicKey.value(),
                8192,
                (text) => {
                    if (!headersSent) {
                        headersSent = true;
                        res.set("Content-Type", "text/plain; charset=utf-8");
                        res.set("X-Accel-Buffering", "no");
                        res.status(200);
                    }
                    res.write(text);
                },
            );
            if (!headersSent)
                return res.status(500).json({ error: "Boş yanıt" });
            res.end();
        } catch (e) {
            console.error("generateRecipes hatası:", e);
            if (!headersSent) return res.status(500).json({ error: e.message });
            res.end();
        }
    },
);

// ── getCalories endpoint ──────────────────────────────────────────────────
exports.getCalories = onRequest(
    { region: "europe-west1", secrets: [anthropicKey], invoker: "public" },
    async (req, res) => {
        setCors(res);
        if (req.method === "OPTIONS") return res.status(204).send("");
        if (req.method !== "POST")
            return res.status(405).json({ error: "Sadece POST desteklenir" });

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
    },
);
