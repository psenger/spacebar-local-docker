#!/bin/bash

# Get Mac's IP address (filters out localhost and docker IPs)
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "172\." | awk '{print $2}' | head -n 1)

if [ -z "$IP" ]; then
    echo "Could not detect IP address. Please enter it manually:"
    read IP
fi

echo "🌐 Using IP address: $IP"
echo "Other devices on your network will connect to: https://$IP:443"

# Create config and certs directories if they don't exist
mkdir -p config certs

# Generate self-signed certificate for Spacebar server
CERT_FILE="./certs/fullchain.pem"
KEY_FILE="./certs/privkey.pem"
 
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "🔐 Generating self-signed TLS certificate..."
    openssl req -x509 -newkey rsa:4096 -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 -nodes -subj "/CN=$IP"
    echo "✅ Certificate generated at $CERT_FILE"
fi

# Generate the config.json with the network IP, using HTTPS/WSS
cat > config/config.json << EOF
{
  "api": {
    "endpointPublic": "https://$IP:443/api",
    "endpointPrivate": "https://localhost:443/api",
    "port": 443
  },
  "gateway": {
    "endpointPublic": "wss://$IP:443",
    "endpointPrivate": "wss://localhost:443"
  },
  "cdn": {
    "endpointPublic": "https://$IP:443/cdn",
    "endpointPrivate": "https://localhost:443/cdn"
  },
  "register": {
    "email": false,
    "dateOfBirth": false,
    "password": true,
    "disabled": false,
    "requireCaptcha": false,
    "requireInvite": false,
    "allowNewRegistration": true,
    "allowMultipleAccounts": true,
    "defaultRights": "875069521787904"
  },
  "limits": {
    "user": {
      "maxGuilds": 100,
      "maxUsername": 32,
      "maxFriends": 1000
    },
    "guild": {
      "maxRoles": 250,
      "maxEmojis": 100,
      "maxMembers": 250000,
      "maxChannels": 500,
      "maxChannelsInCategory": 50
    },
    "message": {
      "maxCharacters": 2000,
      "maxReactions": 20,
      "maxAttachmentSize": 8388608,
      "maxBulkDelete": 100
    },
    "rate": {
      "enabled": false,
      "ip": {
        "count": 500,
        "window": 5
      },
      "global": {
        "count": 20,
        "window": 5
      },
      "error": {
        "count": 10,
        "window": 5
      },
      "routes": {
        "auth": {
          "login": {
            "count": 5,
            "window": 60
          },
          "register": {
            "count": 2,
            "window": 43200
          }
        }
      }
    }
  },
  "security": {
    "captcha": {
      "enabled": false
    },
    "twoFactor": {
      "generateBackupCodes": true
    },
    "autoUpdate": false,
    "requestSignature": false,
    "jwtSecret": "$(openssl rand -hex 32)"
  },
  "login": {
    "requireCaptcha": false
  },
  "cors": {
    "origins": "*",
    "credentials": true,
    "methods": "*",
    "headers": "*",
    "exposedHeaders": "*",
    "maxAge": 86400,
    "optionsSuccessStatus": 200
  },
  "tls": {
    "cert": "$CERT_FILE",
    "key": "$KEY_FILE"
  }
}
EOF

echo "✅ Configuration created with IP: $IP"
echo ""
echo "📝 Connection Info for Clients & Bots:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Server URL: https://$IP:443"
echo "API URL:    https://$IP:443/api"
echo "Gateway:    wss://$IP:443"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

