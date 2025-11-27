const express = require("express");
const crypto = require("crypto");
const fs = require("fs");
const app = express();

let memoryLeakArray = [];
let dbConnections = [];
let fileDescriptors = [];

function log(level, msg, extra = {}) {
  console.log(JSON.stringify({
    level,
    app: "app2",
    message: msg,
    timestamp: new Date().toISOString(),
    ...extra
  }));
}

// Request logger
app.use((req, res, next) => {
  req.id = crypto.randomUUID();
  req.start = Date.now();

  log("info", "request started", { route: req.path, reqId: req.id });

  res.on("finish", () => {
    const latency = Date.now() - req.start;
    log("info", "request completed", {
      route: req.path,
      status: res.statusCode,
      durationMs: latency,
      reqId: req.id
    });

    if (latency > 2000) {
      log("warn", "unusual request latency", {
        route: req.path,
        durationMs: latency,
        reqId: req.id
      });
    }
  });

  next();
});

// ----------------------
// NORMAL ROUTES
// ----------------------
app.get("/", (req, res) => {
  res.send({ status: "faulty-service" });
});

app.get("/ping", (req, res) => {
  res.send("pong-from-app2");
});

// ----------------------
// 1. CPU SPIKE (realistic logging)
// ----------------------
app.get("/cpu", (req, res) => {
  log("warn", "CPU intensive operation detected", { reqId: req.id });

  const end = Date.now() + 5000;
  while (Date.now() < end) {}

  log("info", "CPU operation completed", { reqId: req.id });
  res.send("CPU spike completed");
});

// ----------------------
// 2. Slow response
// ----------------------
app.get("/slow", async (req, res) => {
  log("warn", "slow operation started", { reqId: req.id });
  await new Promise(r => setTimeout(r, 3000));
  log("info", "slow operation completed", { reqId: req.id });
  res.send("slow response");
});

// ----------------------
// 3. Memory leak (realistic monitoring)
// ----------------------
app.get("/leak", (req, res) => {
  memoryLeakArray.push(Buffer.alloc(2 * 1024 * 1024)); // 2MB
  log("warn", "memory usage increasing", {
    leakSize: memoryLeakArray.length,
    approximateMB: memoryLeakArray.length * 2,
    reqId: req.id
  });

  res.send("memory increased");
});

// ----------------------
// 4. Controlled crash
// ----------------------
app.get("/crash", (req, res) => {
  log("error", "service crash triggered", { reqId: req.id });
  res.send("crashing...");
  setTimeout(() => process.exit(1), 200);
});

// ----------------------
// 5. Random crash
// ----------------------
app.get("/random-crash", (req, res) => {
  if (Math.random() < 0.2) {
    log("error", "unexpected fatal error", {
      reqId: req.id,
      error: "Random failure injected"
    });
    process.exit(1);
  }
  res.send("ok");
});

// ----------------------
// 6. Intentional 500 error
// ----------------------
app.get("/error", (req, res) => {
  try {
    throw new Error("Intentional error triggered");
  } catch (err) {
    log("error", "request failed", {
      reqId: req.id,
      stack: err.stack
    });
    res.status(500).send("Something went wrong");
  }
});

// ----------------------
// 7. Disk I/O stress
// ----------------------
app.get("/disk", (req, res) => {
  log("warn", "high disk activity", { reqId: req.id });

  fs.writeFileSync("/tmp/disk-test", "X".repeat(5_000_000)); // 5MB

  log("info", "disk write completed", { reqId: req.id });
  res.send("disk stress done");
});

// ----------------------
// 8. Network latency simulated
// ----------------------
app.get("/simulate-network-lag", async (req, res) => {
  log("warn", "artificial network delay", { delayMs: 800, reqId: req.id });
  await new Promise(r => setTimeout(r, 800));
  res.send("network lag simulated");
});

// ----------------------
// 9. File descriptor leak
// ----------------------
app.get("/fd", (req, res) => {
  log("warn", "file handle usage rising", { reqId: req.id });

  for (let i = 0; i < 100; i++) {
    try {
      const fd = fs.openSync("/tmp/fdtest", "w");
      fileDescriptors.push(fd);
    } catch (err) {
      log("error", "file descriptor exhaustion", {
        reqId: req.id,
        stack: err.stack
      });
      break;
    }
  }

  res.send("fd leak expanded");
});

// ----------------------
// 10. DB connection leak
// ----------------------
app.get("/dbleak", (req, res) => {
  dbConnections.push({ createdAt: Date.now() });

  log("warn", "database connection leak", {
    activeConnections: dbConnections.length,
    reqId: req.id
  });

  res.send("db connection leaked");
});

// ----------------------
// 11. OOM simulator
// ----------------------
app.get("/oom", (req, res) => {
  log("error", "large allocation requested", { reqId: req.id });
  let block = Buffer.alloc(300 * 1024 * 1024); // 300MB
  res.send("allocated");
});

// ----------------------
// 12. Chaos mode
// ----------------------
app.get("/chaos", (req, res) => {
  log("warn", "chaos mode started", { reqId: req.id });

  // Short CPU block
  const end = Date.now() + 1000;
  while (Date.now() < end) {}

  // small memory bump
  memoryLeakArray.push(Buffer.alloc(5 * 1024 * 1024));

  if (Math.random() < 0.1) {
    log("error", "chaos fatal crash", { reqId: req.id });
    process.exit(1);
  }

  log("info", "chaos mode completed", { reqId: req.id });

  res.send("chaos done");
});

// ----------------------
// START SERVER
// ----------------------
const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  log("info", "App2 started", { port: PORT });
});
