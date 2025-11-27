const express = require("express");
const crypto = require("crypto");
const app = express();

function log(level, msg, extra = {}) {
  console.log(JSON.stringify({
    level,
    app: "app1",
    message: msg,
    timestamp: new Date().toISOString(),
    ...extra
  }));
}

// Request logger with request ID
app.use((req, res, next) => {
  req.id = crypto.randomUUID();
  req.start = Date.now();

  log("info", "incoming request", { route: req.path, reqId: req.id });

  res.on("finish", () => {
    const duration = Date.now() - req.start;
    log("info", "request completed", {
      route: req.path,
      status: res.statusCode,
      durationMs: duration,
      reqId: req.id
    });
  });

  next();
});

app.get("/", (req, res) => {
  res.send({ status: "ok", service: "app1" });
});

app.get("/ping", (req, res) => {
  res.send("pong");
});

app.get("/data", async (req, res) => {
  await new Promise(r => setTimeout(r, 50)); // simulate DB latency
  res.send({ data: "normal-data" });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  log("info", "App1 started", { port: PORT });
});
