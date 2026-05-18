/**
 * Sample web application for Kubernetes HPA demo.
 *
 * Endpoints:
 *   GET /          -> simple landing page (returns pod name)
 *   GET /healthz   -> liveness/readiness probe target
 *   GET /cpu       -> CPU-intensive endpoint (fibonacci) — used to trigger HPA on CPU
 *   GET /memory    -> allocates ~50 MB per call (held for 30s) — used to trigger HPA on memory
 *   GET /metrics   -> basic process stats (handy for debugging)
 *
 * The app is intentionally simple so the focus stays on Kubernetes behavior,
 * not application logic.
 */

const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 8080;
const POD_NAME = process.env.POD_NAME || os.hostname();

// Memory holder so allocations from /memory are not immediately GC'd
const memoryBallast = [];

// Recursive fibonacci — deliberately inefficient to burn CPU
function fib(n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}

app.get('/', (req, res) => {
  res.send(`
    <html>
      <head><title>HPA Demo App</title></head>
      <body style="font-family: system-ui, sans-serif; padding: 2rem;">
        <h1>Kubernetes HPA Demo</h1>
        <p>Served by pod: <strong>${POD_NAME}</strong></p>
        <p>Node: <strong>${os.hostname()}</strong></p>
        <ul>
          <li><a href="/cpu">/cpu</a> — burns CPU (fibonacci)</li>
          <li><a href="/memory">/memory</a> — allocates ~50MB for 30s</li>
          <li><a href="/healthz">/healthz</a> — health probe</li>
          <li><a href="/metrics">/metrics</a> — process stats</li>
        </ul>
      </body>
    </html>
  `);
});

app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'ok', pod: POD_NAME });
});

app.get('/cpu', (req, res) => {
  // n=35 takes roughly 200-400ms of CPU on most machines
  const n = parseInt(req.query.n, 10) || 35;
  const start = Date.now();
  const result = fib(n);
  const elapsed = Date.now() - start;
  res.json({ pod: POD_NAME, n, result, elapsed_ms: elapsed });
});

app.get('/memory', (req, res) => {
  // Allocate ~50 MB
  const chunk = Buffer.alloc(50 * 1024 * 1024, 'x');
  memoryBallast.push(chunk);

  // Release it after 30 seconds so the pod doesn't OOM permanently
  setTimeout(() => {
    const idx = memoryBallast.indexOf(chunk);
    if (idx !== -1) memoryBallast.splice(idx, 1);
  }, 30_000);

  res.json({
    pod: POD_NAME,
    allocated_mb: 50,
    held_chunks: memoryBallast.length,
    process_rss_mb: Math.round(process.memoryUsage().rss / 1024 / 1024),
  });
});

app.get('/metrics', (req, res) => {
  const mem = process.memoryUsage();
  res.json({
    pod: POD_NAME,
    uptime_s: Math.round(process.uptime()),
    memory_mb: {
      rss: Math.round(mem.rss / 1024 / 1024),
      heap_used: Math.round(mem.heapUsed / 1024 / 1024),
      heap_total: Math.round(mem.heapTotal / 1024 / 1024),
    },
    cpu_count: os.cpus().length,
    load_avg: os.loadavg(),
  });
});

app.listen(PORT, () => {
  console.log(`[${POD_NAME}] HPA demo app listening on :${PORT}`);
});
