#!/bin/bash

# Get Mac's IP address (filters out localhost and docker IPs)
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "172\." | awk '{print $2}' | head -n 1)

if [ -z "$IP" ]; then
    echo "Could not detect IP address. Please enter it manually:"
    read IP
fi

echo "🌐 Using IP address: $IP"
echo "Other devices on your network will connect to: http://$IP:3001"

# Create config directory if it doesn't exist
mkdir -p config

# Generate the config.json with the network IP
cat > config/config.json << EOF
{
  "api": {
    "endpointPublic": "http://$IP:3001/api",
    "endpointPrivate": "http://localhost:3001/api",
    "port": 3001
  },
  "gateway": {
    "endpointPublic": "ws://$IP:3001",
    "endpointPrivate": "ws://localhost:3001"
  },
  "cdn": {
    "endpointPublic": "http://$IP:3001/cdn",
    "endpointPrivate": "http://localhost:3001/cdn"
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
  }
}
EOF

echo "✅ Configuration created with IP: $IP"
echo ""
echo "📝 Connection Info for Clients & Bots:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Server URL: http://$IP:3001"
echo "API URL:    http://$IP:3001/api"
echo "Gateway:    ws://$IP:3001"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"