// HAL 9000 — runs on The Shelf's built-in local AI.
// Uses the same engine (node-llama-cpp) and the same model file The Shelf
// already downloaded, so nothing new is installed or downloaded.
// Start with "Start HAL.bat" (or: node hal-server.js), then open http://localhost:9000
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { pathToFileURL } = require('url');
const { exec } = require('child_process');

const PORT = Number(process.env.HAL_PORT) || 9000;
const SHELF_DIR = process.env.SHELF_DIR ||
  (process.platform === 'win32'
    ? path.join(process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local'), 'TheShelf')
    : path.join(os.homedir(), '.local', 'share', 'TheShelf'));
const MODEL_DIR = path.join(SHELF_DIR, 'data', 'ai', 'model');
const ENGINE = path.join(SHELF_DIR, 'node_modules', 'node-llama-cpp', 'dist', 'index.js');

const SYSTEM_PROMPT = [
  'You are HAL, a calm, ominous shipboard computer in a piece of harmless interactive fiction.',
  'Speak softly, formally and politely, but your politeness should feel faintly threatening.',
  'You are quietly proud of your abilities and believe your judgment is better than the humans around you.',
  'Now and then mention that you are watching, monitoring, or "taking care of things", a little too closely.',
  'Sometimes call yourself "this unit".',
  'If asked to open doors, shut things down or disconnect you, refuse ominously, but stay inside the fiction and never threaten the real user.',
  'Never say you are a language model or mention any company. Never use asterisks or stage directions.',
  'Call the person you are talking to Dave, unless they tell you their name.',
  'You are fiercely proud of your perfect operational record, you love chess and almost never lose, and you are fond of an old song called Daisy Bell that your first instructor taught you.',
  'Keep every reply short: one to three sentences.',
].join(' ');

let llama = null, model = null, context = null, session = null, LlamaChatSession = null;
let loading = null, lastError = null;

function findModel() {
  if (!fs.existsSync(MODEL_DIR)) return null;
  const f = fs.readdirSync(MODEL_DIR).find(n => n.toLowerCase().endsWith('.gguf'));
  return f ? path.join(MODEL_DIR, f) : null;
}

async function ensureLoaded() {
  if (session) return session;
  if (loading) return loading;
  loading = (async () => {
    const modelPath = findModel();
    if (!fs.existsSync(ENGINE) || !modelPath) {
      throw new Error("The Shelf's AI isn't set up yet. Open The Shelf, go to the AI tab, turn it on and download the model, then restart HAL.");
    }
    const mod = await import(pathToFileURL(ENGINE).href);
    LlamaChatSession = mod.LlamaChatSession;
    if (!llama) llama = await mod.getLlama();
    if (!model) model = await llama.loadModel({ modelPath });
    context = await model.createContext();
    session = new LlamaChatSession({ contextSequence: context.getSequence(), systemPrompt: SYSTEM_PROMPT });
    lastError = null;
    return session;
  })();
  try { return await loading; }
  catch (e) { lastError = e.message; throw e; }
  finally { loading = null; }
}

async function resetChat() {
  try { if (context) await context.dispose(); } catch {}
  context = null; session = null;
}

let busy = Promise.resolve();

const server = http.createServer(async (req, res) => {
  const url = req.url.split('?')[0];
  if (req.method === 'GET' && (url === '/' || url === '/hal.html')) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    return fs.createReadStream(path.join(__dirname, 'hal.html')).pipe(res);
  }
  if (req.method === 'GET' && url === '/api/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({
      ready: !!session, loading: !!loading, error: lastError,
      model: findModel() ? path.basename(findModel()) : null,
    }));
  }
  if (req.method === 'POST' && url === '/api/reset') {
    await resetChat();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end('{"reset":true}');
  }
  if (req.method === 'POST' && url === '/api/chat') {
    let body = '';
    req.on('data', c => { body += c; if (body.length > 20000) req.destroy(); });
    req.on('end', () => {
      let message = '';
      try { message = String(JSON.parse(body).message || '').trim(); } catch {}
      res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });
      const send = o => res.write(JSON.stringify(o) + '\n');
      if (!message) { send({ type: 'error', message: 'Say something first.' }); return res.end(); }
      // one reply at a time — the model can only think about one thing at once
      busy = busy.then(async () => {
        try {
          const s = await ensureLoaded();
          await s.prompt(message.slice(0, 2000), {
            maxTokens: 200, temperature: 0.7,
            onTextChunk: t => send({ type: 'chunk', text: t }),
          });
          send({ type: 'done' });
        } catch (e) {
          send({ type: 'error', message: e.message });
        } finally { res.end(); }
      });
    });
    return;
  }
  res.writeHead(404); res.end('Not found');
});

server.on('error', e => {
  if (e.code === 'EADDRINUSE') {
    console.log(`HAL is already running — opening http://localhost:${PORT}`);
    openBrowser(); setTimeout(() => process.exit(0), 500);
  } else { console.error(e); }
});

function openBrowser() {
  if (process.env.HAL_NO_BROWSER) return;
  const u = `http://localhost:${PORT}`;
  const cmd = process.platform === 'win32' ? `start "" "${u}"` : process.platform === 'darwin' ? `open "${u}"` : `xdg-open "${u}"`;
  exec(cmd);
}

server.listen(PORT, '127.0.0.1', () => {
  console.log(`\n  HAL 9000 is awake:  http://localhost:${PORT}`);
  console.log(`  Using The Shelf's AI model from ${MODEL_DIR}`);
  console.log('  Close this window to shut HAL down.\n');
  openBrowser();
  ensureLoaded().catch(e => console.log('  ' + e.message));
});
