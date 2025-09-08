#!/bin/bash

echo "🚀 Starting Spacebar Server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if config exists
if [ ! -f "config/config.json" ]; then
    echo "⚠️  Config not found. Running setup first..."
    ./setup-network.sh
fi

# Stop any existing container
docker-compose down 2>/dev/null

# Start in detached mode
docker-compose up -d

# Wait for container to start
echo "⏳ Waiting for server to start..."
sleep 3

# Check if container is running
if docker ps | grep -q spacebar; then
    echo "✅ Spacebar is running!"
    echo ""
    
    # Get IP from config
    IP=$(grep -o '"endpointPublic": "http://[^:]*' config/config.json | head -1 | sed 's/.*http:\/\///')
    
    echo "📡 Connection URLs:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Local:   http://localhost:3001"
    echo "Network: http://$IP:3001"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Logs (Ctrl+C to exit, server keeps running):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Follow logs
    docker logs -f spacebar
else
    echo "❌ Failed to start Spacebar"
    echo "Checking docker-compose logs..."
    docker-compose logs
fi