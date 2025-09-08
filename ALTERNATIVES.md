# Matrix Chat System Setup with Synapse Server, Element Client, and Bot

This guide outlines how to set up a simple, open-source chat system using **Matrix** with the **Synapse** server, **Element** desktop client, and a bot in a room. The setup is designed to run the server in Docker on a Mac M4 (Apple Silicon) and the GUI client on Raspberry Pi, Mac M4, and Windows 11. All components are open-source, and the bot uses `matrix-bot-sdk` for room interactions.

## Overview
- **Matrix**: An open-source, decentralized chat protocol for secure, real-time messaging (text, optional voice/video).
- **Synapse**: The reference Matrix homeserver, lightweight and Docker-friendly with ARM64 support.
- **Element**: A cross-platform GUI client (Electron-based) for Matrix, supporting Raspberry Pi, Mac M4, and Windows 11.
- **Bot**: A simple "echo bot" built with `matrix-bot-sdk` (JavaScript/TypeScript) that responds to messages in rooms.
- **License**: Synapse (Apache 2.0), Element (Apache 2.0), `matrix-bot-sdk` (MIT).
- **Requirements**: Docker on Mac M4, internet access, and ports 80/443/8448 open.

## Prerequisites
- **Mac M4 (Server)**:
  - Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (ARM64-native, free).
  - Ensure ports 80 (HTTP), 443 (HTTPS), and 8448 (Matrix federation) are free.
  - Optional: A domain (e.g., via [DuckDNS](https://www.duckdns.org)) for production; `localhost` works for testing.
- **Python**: Synapse requires Python 3.9+ (pre-installed on macOS). For non-Docker setups, install dependencies: `brew install jpeg libpq`.
- **Clients**:
  - Raspberry Pi: Raspbian/Ubuntu (ARM64/ARMv7).
  - Mac M4: macOS Ventura or later.
  - Windows 11: x64 architecture.
- **Network**: Clients need access to the server (e.g., via LAN IP like `192.168.1.x:8008` or a domain).

## Step 1: Deploy Synapse Server in Docker on Mac M4
Synapse runs in Docker with ARM64 support, using PostgreSQL or SQLite (default for simplicity).

1. **Create a project directory**:
   ```bash
   mkdir ~/matrix-synapse && cd ~/matrix-synapse
   ```

2. **Download the official Docker Compose file**:
   ```bash
   curl -o docker-compose.yml https://raw.githubusercontent.com/matrix-org/synapse/main/docker/conf/docker-compose.yml
   ```

3. **Generate a configuration file**:
   ```bash
   docker-compose run --rm -v $(pwd)/data:/data synapse new-config
   ```
   - Creates `homeserver.yaml` in `./data`.
   - Edit `homeserver.yaml` (e.g., with VS Code or `nano`):
     - Set `server_name: "localhost"` (or your domain, e.g., `yourdomain.com`).
     - Enable registration: `enable_registration: true` (set to `false` in production).
     - Disable stats: `report_stats: false`.

4. **Start the server**:
   ```bash
   docker-compose up -d
   ```
   - Pulls the ARM64 Synapse image and starts the server.
   - Access at `http://localhost:8008` (or `https://yourdomain.com` with a reverse proxy).
   - View logs: `docker-compose logs -f synapse`.
   - Stop: `docker-compose down`.

5. **(Optional) Add HTTPS**:
   - Use a reverse proxy like [Nginx](https://hub.docker.com/_/nginx) or [Caddy](https://hub.docker.com/_/caddy) with [Let's Encrypt](https://letsencrypt.org) for production.
   - For local testing, HTTP is sufficient.

**Resources**:
- Synapse Docker Docs: [matrix-org.github.io/synapse/latest/setup/installation](https://matrix-org.github.io/synapse/latest/setup/installation)
- GitHub: [matrix-org/synapse](https://github.com/matrix-org/synapse)

## Step 2: Install Element Desktop Client
Element is a cross-platform GUI client for Matrix, available for all target platforms.

### Raspberry Pi (Raspbian/Ubuntu, ARM)
1. **Via Snap** (simplest):
   ```bash
   sudo apt update && sudo apt install snapd
   sudo snap install element-desktop
   ```
2. **Via APT (alternative)**:
   ```bash
   echo 'deb https://packages.element.io/debian/ default main' | sudo tee /etc/apt/sources.list.d/element-io.list
   wget -qO - https://packages.element.io/debian/element-io-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/element-io-archive-keyring.gpg
   sudo apt update && sudo apt install element-desktop
   ```
3. Tested on Pi 3/4/5 (ARM64/ARMv7).

### Mac M4 (macOS, ARM64)
1. Download the `.dmg` from [element.io/download](https://element.io/download) (ARM64-native) or the App Store (search "Element").
2. Install and run.

### Windows 11 (x64)
1. Download the `.exe` from [element.io/download](https://element.io/download).
2. Install and run.

**Resources**:
- Element Docs: [element.io/help](https://element.io/help)
- GitHub: [element-hq/element-desktop](https://github.com/element-hq/element-desktop)

## Step 3: Connect Element to Synapse
1. Open Element on any device (RPi, Mac, Windows).
2. During setup or in Settings > "Help & About" > "Server", set the Homeserver to:
   - `http://<your-mac-ip>:8008` (find IP with `ifconfig` on Mac).
   - Or `https://yourdomain.com` if using a domain.
3. Register or log in with a user (e.g., `@user:localhost`).
4. Create/join a room (e.g., `#testroom:localhost`) to start chatting.

## Step 4: Create a Bot in a Room
Bots act as Matrix users and interact in rooms via the Client-Server API. This example uses `matrix-bot-sdk` (JavaScript/TypeScript) to create an "echo bot" that repeats messages.

### Create a Bot Account
1. Register a bot user on Synapse:
   ```bash
   docker-compose exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008
   ```
   - Create a user (e.g., `@mybot:localhost`) with a password.
2. Get an access token:
   ```bash
   curl -X POST "http://localhost:8008/_matrix/client/r0/login" -d '{"type":"m.login.password","user":"@mybot:localhost","password":"yourpassword"}'
   ```
   - Save the `access_token` (e.g., `syt_bXlidXNlcg_...`).

### Set Up the Bot
1. **Create a bot project**:
   ```bash
   mkdir matrix-bot && cd matrix-bot
   npm init -y
   npm install matrix-bot-sdk
   ```

2. **Write the bot code** (`index.js`):
   ```javascript
   const { MatrixClient, SimpleFsStorageProvider, AutojoinRoomsMixin } = require("matrix-bot-sdk");

   const homeserverUrl = "http://localhost:8008"; // Your Synapse server
   const accessToken = "your-bot-access-token"; // From login step
   const storage = new SimpleFsStorageProvider("bot.json");

   const client = new MatrixClient(homeserverUrl, accessToken, storage);
   AutojoinRoomsMixin.setupOnClient(client); // Auto-join invited rooms

   client.on("room.message", (roomId, event) => {
       if (!event.content || event.sender === client.getUserId()) return; // Ignore own messages
       const body = event.content.body;
       console.log(`${roomId}: ${event.sender} says '${body}'`);
       client.sendText(roomId, `Echo: ${body}`);
   });

   client.start().then(() => console.log("Bot started!"));
   ```

3. **Dockerize the bot** (for Mac M4 compatibility):
   Create a `Dockerfile`:
   ```dockerfile
   FROM node:18
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   CMD ["node", "index.js"]
   ```
   Create a `docker-compose.yml`:
   ```yaml
   version: '3'
   services:
     bot:
       build: .
       volumes:
         - ./bot.json:/app/bot.json
   ```
   Build and run:
   ```bash
   docker-compose up -d
   ```

### Invite and Test the Bot
1. In Element, create/join a room (e.g., `#testroom:localhost`).
2. Invite the bot: Send `!invite @mybot:localhost` or use room settings.
3. Send a message (e.g., "Hello!"). The bot replies with "Echo: Hello!".
4. Bot logs: `docker-compose logs -f bot`.

**Resources**:
- Matrix Bot SDK: [github.com/turt2live/matrix-bot-sdk](https://github.com/turt2live/matrix-bot-sdk)
- Matrix Client-Server API: [spec.matrix.org/latest/client-server-api](https://spec.matrix.org/latest/client-server-api)

## Step 5: Save Dependencies
For JavaScript-based bots, `package.json` (created by `npm init`) lists `matrix-bot-sdk`. Example `package.json`:
```json
{
  "name": "matrix-bot",
  "version": "1.0.0",
  "dependencies": {
    "matrix-bot-sdk": "^0.7.0"
  }
}
```

For Python-based bots (e.g., using `matrix-nio`):
1. Install: `pip3 install matrix-nio`
2. Generate `requirements.txt`:
   ```bash
   pip3 freeze > requirements.txt
   ```
   Example `requirements.txt`:
   ```
   matrix-nio
   ```

## Bot Capabilities
- **Commands**: Parse messages for commands (e.g., `!help`) in the `room.message` handler.
- **Moderation**: Kick/ban users or redact messages (requires room permissions).
- **Notifications**: Send automated messages (e.g., alerts via `client.sendText`).
- **Extensibility**: Add features like RSS feeds, webhooks, or bridges (e.g., [mautrix](https://github.com/mautrix)).
- **Alternative Framework**: [Maubot](https://github.com/maubot/maubot) (Python, plugin-based, Dockerized: `dock.mau.dev/maubot/maubot`).

## Compatibility Notes
- **Mac M4 (Server)**: Synapse and bot Docker images are ARM64-native. Uses ~200-500MB RAM (Synapse) + ~50-200MB (bot).
- **Clients (RPi, Mac M4, Windows 11)**: Element works seamlessly with bots. ~100-200MB RAM per client.
- **Raspberry Pi**: Element runs well on Pi 4/5; Pi 3 may be slower for heavy rooms.
- **Security**: Use E2EE rooms (bot needs E2EE support for encrypted rooms). Secure access tokens.
- **Network**: Clients connect via LAN IP (`192.168.1.x:8008`) or domain. Ensure firewall allows ports.

## Troubleshooting
- **Docker Issues**: Update Docker Desktop. Check logs: `docker-compose logs synapse`.
- **Bot Not Responding**: Verify access token, ensure room is unencrypted (or add E2EE support), check logs.
- **RPi Client**: If Snap fails, try Flatpak: `flatpak install flathub im.riot.Riot`.
- **Connection**: Test server with `curl http://localhost:8008/_matrix/client/versions`.

## References
- **Matrix Protocol**: [matrix.org](https://matrix.org)
- **Synapse**:
  - Docs: [matrix-org.github.io/synapse](https://matrix-org.github.io/synapse)
  - GitHub: [matrix-org/synapse](https://github.com/matrix-org/synapse)
- **Element**:
  - Download: [element.io/download](https://element.io/download)
  - Docs: [element.io/help](https://element.io/help)
  - GitHub: [element-hq/element-desktop](https://github.com/element-hq/element-desktop)
- **Matrix Bot SDK**:
  - GitHub: [github.com/turt2live/matrix-bot-sdk](https://github.com/turt2live/matrix-bot-sdk)
  - Docs: [matrix.org/docs/guides/usage-of-the-matrix-js-sdk](https://matrix.org/docs/guides/usage-of-the-matrix-js-sdk)
- **Maubot (Alternative Bot Framework)**: [github.com/maubot/maubot](https://github.com/maubot/maubot)
- **Matrix Community**: [matrix.to/#/#synapse:matrix.org](https://matrix.to/#/#synapse:matrix.org)