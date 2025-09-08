# Spacebar Server - Network Setup Guide

## 🚀 Quick Start

### 1. First Time Setup
```bash
# Make scripts executable
chmod +x *.sh

# Install Node.js dependencies
npm install

# Run the master control panel
./spacebar-control.sh
```

### 2. Using the Control Panel
From the control panel menu:
1. **Option 1**: Configure network (sets up config with your Mac's IP)
2. **Option 2**: Start server and watch logs
3. **Option 6**: Create users and bots (after server is running)
4. **Option 8/9**: Start example bots

### 3. Manual Commands

#### Start Everything
```bash
# Setup network config
./setup-network.sh

# Start server with logs
./run-spacebar.sh

# In new terminal - Setup users/bots
node setup-users-and-bots.js

# Start a bot
node example-bot.js 0  # Starts first bot
```

#### Stop Server
```bash
docker-compose down
```

## 📱 Connecting Clients

### From Other Devices on Your Network

After running `./setup-network.sh`, you'll see your connection info:
```
Server URL: http://192.168.1.XXX:3001
```

Share this URL with:
- **Web Browsers**: Direct connection to `http://192.168.1.XXX:3001`
- **Discord Clients**: Set custom instance to your server URL
- **Mobile Apps**: Use the server URL in app settings

### Default Credentials
- **Admin**: `admin` / `AdminPass123!`
- **Users**: `user1`, `user2`, `user3` / `UserPass123!`
- **Bot Tokens**: Check `credentials.json` after setup

## 🤖 Bot Development

### Node.js Bot
```javascript
const { Client } = require('discord.js');
const credentials = require('./credentials.json');

const client = new Client({
    // ... intents
    rest: { api: `${credentials.server}/api` },
    ws: { gateway: credentials.server.replace('http', 'ws') }
});

client.login(credentials.bots[0].token);
```

### Python Bot
```python
import discord
import json

with open('credentials.json') as f:
    creds = json.load(f)

# Configure for custom server
bot = discord.Client()
bot.http.BASE = creds['server'] + '/api'
discord.gateway.DiscordWebSocket.DEFAULT_GATEWAY = creds['server'].replace('http', 'ws')

bot.run(creds['bots'][0]['token'])
```

## 📁 File Structure
```
SpaceBar/
├── docker-compose.yml          # Docker configuration
├── config/
│   └── config.json            # Server configuration
├── data/                      # SQLite database
├── files/                     # Uploaded files
├── credentials.json           # Generated after setup
├── setup-network.sh           # Network configuration
├── run-spacebar.sh           # Start server with logs
├── setup-users-and-bots.js   # Create users/bots
├── example-bot.js            # Node.js bot example
├── example-bot.py            # Python bot example
├── spacebar-control.sh       # Master control panel
└── package.json              # Node dependencies
```

## 🔧 Troubleshooting

### Server Won't Start
```bash
# Check Docker is running
docker ps

# Check ports
lsof -i :3001

# View logs
docker logs spacebar
```

### Can't Connect from Other Devices
1. Check firewall settings on Mac
2. Ensure devices are on same network
3. Verify IP address: `ifconfig | grep inet`
4. Try disabling Mac firewall temporarily

### Bot Won't Connect
1. Ensure server is running: `docker ps`
2. Check credentials.json has bot tokens
3. Verify network URLs in config.json
4. Look at server logs: `docker logs -f spacebar`

## 🛡️ Security Notes

⚠️ **For Development/Testing Only**
- Default passwords should be changed for production
- CORS is set to `*` (accepts all origins)
- Rate limiting is disabled
- No HTTPS configured

For production use:
1. Change all default passwords
2. Enable rate limiting in config
3. Setup HTTPS with nginx
4. Restrict CORS origins
5. Enable captcha for registration

## 📊 Monitoring

Check server status:
```bash
# Container status
docker ps

# Resource usage
docker stats spacebar

# Logs
docker logs -f spacebar --tail 100
```

## 🔄 Updates

To update Spacebar:
```bash
docker-compose pull
docker-compose up -d
```

## 💡 Tips

1. **Multiple Bots**: Each bot needs its own token from `credentials.json`
2. **Voice Channels**: Require additional setup for voice support
3. **File Uploads**: Limited to 8MB by default (configurable)
4. **Database**: SQLite file is in `./data/` - backup regularly
5. **Scaling**: For >100 users, consider switching to PostgreSQL

---

# 🚀 Ultra-Lightweight Client Downloads

Connect to your Spacebar server from any device using these lightweight clients. After starting your server, use the IP address shown (e.g., `http://192.168.1.XXX:3001`).

## 📊 Client Comparison (RAM Usage)
| Client | RAM Usage | Type | Best For |
|--------|-----------|------|----------|
| **Web Browser** | 0 MB extra | Web | All platforms - uses existing browser |
| **Discordo** | ~20 MB | Terminal | Pi 5 - Absolute minimum resources |
| **Abaddon** | ~50 MB | Native GUI | Best lightweight desktop experience |
| **WebCord** | ~150 MB | Electron | Full-featured Discord-like experience |

---

## 🍓 Raspberry Pi 5 (4GB RAM) - Terminal & GUI Options

### Terminal Option: Discordo (~20MB RAM)
**Download:** https://github.com/ayn2op/discordo/releases/latest

1. Download the ARM64 binary:
```bash
wget https://github.com/ayn2op/discordo/releases/latest/download/discordo-linux-arm64.tar.gz
tar -xzf discordo-linux-arm64.tar.gz
chmod +x discordo
```

2. Create config file:
```bash
mkdir -p ~/.config/discordo
nano ~/.config/discordo/config.yml
```

3. Add your server (replace YOUR_SERVER_IP):
```yaml
api_url: "http://YOUR_SERVER_IP:3001/api"
gateway_url: "ws://YOUR_SERVER_IP:3001"
```

4. Run:
```bash
./discordo
```

**Controls:** Use arrow keys to navigate, Enter to select, Esc for menu

### GUI Option 1: Abaddon Native (~50MB RAM) - RECOMMENDED
**Download:** https://github.com/uowuo/abaddon/releases/latest

1. Download ARM64 version:
```bash
wget https://github.com/uowuo/abaddon/releases/latest/download/abaddon-linux-aarch64.tar.gz
tar -xzf abaddon-linux-aarch64.tar.gz
chmod +x abaddon
```

2. Install minimal dependencies:
```bash
sudo apt install libgtk-3-0 libcurl4 libopus0 --no-install-recommends
```

3. Run:
```bash
./abaddon
```

4. Configure: File → Settings → Set Instance URL to `http://YOUR_SERVER_IP:3001`

### GUI Option 2: WebCord (~150MB RAM)
**Download:** https://github.com/SpacingBat3/WebCord/releases/latest

1. Download ARM64 AppImage:
```bash
wget https://github.com/SpacingBat3/WebCord/releases/latest/download/WebCord-4.9.2-arm64.AppImage
chmod +x WebCord-*.AppImage
```

2. Run:
```bash
./WebCord-4.9.2-arm64.AppImage
```

3. Configure: Settings → Set custom instance to `http://YOUR_SERVER_IP:3001`

### GUI Option 3: Web Browser (No Install)
```bash
# Full browser
chromium-browser http://YOUR_SERVER_IP:3001

# App mode (cleaner UI)
chromium-browser --app=http://YOUR_SERVER_IP:3001
```

---

## 🍎 Mac M4 (Apple Silicon) - GUI Only

### Option 1: Abaddon Native (Best Performance)
**Download:** https://github.com/uowuo/abaddon/releases/latest

1. Download the macOS DMG:
   - Direct link: https://github.com/uowuo/abaddon/releases/latest/download/abaddon-macos-arm64.dmg
   
2. Install:
   - Open the DMG file
   - Drag Abaddon to Applications folder
   - First time: Right-click → Open (to bypass Gatekeeper)

3. Configure:
   - Open Abaddon
   - Go to File → Preferences
   - Set Instance URL to `http://YOUR_SERVER_IP:3001`
   - Click Save and restart the app

### Option 2: WebCord (Full Featured)
**Download:** https://github.com/SpacingBat3/WebCord/releases/latest

1. Download for Apple Silicon:
   - Direct link: https://github.com/SpacingBat3/WebCord/releases/latest/download/WebCord-4.9.2-arm64.dmg

2. Install:
   - Open the DMG
   - Drag to Applications
   - First launch: Right-click → Open

3. Configure:
   - Settings → Advanced → Custom Discord instance
   - Enter: `http://YOUR_SERVER_IP:3001`

### Option 3: Safari Web App
```bash
# Open in Safari (most efficient on M4)
open -a Safari http://YOUR_SERVER_IP:3001
```
Then: File → Add to Dock (creates standalone app)

---

## 🪟 Windows 11 - GUI Only

### Option 1: Abaddon Native (Lightest)
**Download:** https://github.com/uowuo/abaddon/releases/latest

1. Download Windows x64:
   - Direct link: https://github.com/uowuo/abaddon/releases/latest/download/abaddon-windows-x64.zip

2. Install:
   - Extract ZIP to `C:\Program Files\Abaddon\`
   - Create desktop shortcut to `abaddon.exe`

3. Configure:
   - Run Abaddon
   - File → Preferences
   - Set Instance URL to `http://YOUR_SERVER_IP:3001`

### Option 2: WebCord (Full Featured)
**Download:** https://github.com/SpacingBat3/WebCord/releases/latest

1. Download installer:
   - Direct link: https://github.com/SpacingBat3/WebCord/releases/latest/download/WebCord-Setup-4.9.2-x64.exe

2. Install:
   - Run the installer
   - Follow setup wizard

3. Configure:
   - Open WebCord
   - Settings → Advanced settings
   - Set Discord instance: `http://YOUR_SERVER_IP:3001`

### Option 3: ArmCord (Alternative)
**Download:** https://github.com/ArmCord/ArmCord/releases/latest

1. Download:
   - Direct link: https://github.com/ArmCord/ArmCord/releases/latest/download/ArmCord-Setup-3.2.8.exe

2. Install and configure:
   - Run installer
   - On first launch, select "Custom Instance"
   - Enter: `http://YOUR_SERVER_IP:3001`

### Option 4: Edge Web App
1. Open Edge browser
2. Navigate to `http://YOUR_SERVER_IP:3001`
3. Click ⋯ menu → Apps → Install this site as an app
4. Creates standalone window without browser UI

---

## 🔧 Quick Configuration Tips

### Finding Your Server IP
After running `./setup-network.sh`, your server IP is shown. You can also find it:
```bash
# On Mac (server host)
ifconfig | grep "inet " | grep -v 127.0.0.1

# Shows something like: inet 192.168.1.123
```

### Default Login Credentials
- **Username:** `admin` or `user1`
- **Password:** `AdminPass123!` or `UserPass123!`

### Connection Settings for All Clients
- **Server URL:** `http://YOUR_SERVER_IP:3001`
- **API Endpoint:** `http://YOUR_SERVER_IP:3001/api`
- **Gateway/WebSocket:** `ws://YOUR_SERVER_IP:3001`

### Troubleshooting Connections
1. Ensure all devices are on the same network
2. Check Mac firewall isn't blocking port 3001
3. Verify server is running: `docker ps | grep spacebar`
4. Test from server machine first: `curl http://localhost:3001`