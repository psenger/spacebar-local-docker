#!/bin/bash

echo "🚀 Starting Spacebar Server..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect Docker Compose command
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose --version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "❌ Docker Compose is not installed!"
    echo "Please install Docker Compose to continue."
    exit 1
fi

echo "✓ Using: $DOCKER_COMPOSE"

# Check if config exists
if [ ! -f "config/config.json" ]; then
    echo "⚠️  Config not found. Running setup first..."
    ./setup-network.sh
fi

# Stop any existing container
$DOCKER_COMPOSE down 2>/dev/null

# Start in detached mode
$DOCKER_COMPOSE up -d

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
    $DOCKER_COMPOSE logs
fi