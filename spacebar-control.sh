#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "       SPACEBAR SERVER CONTROL PANEL"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Server Management:${NC}"
    echo "  1) Initial Setup (Configure Network)"
    echo "  2) Start Server & Watch Logs"
    echo "  3) Stop Server"
    echo "  4) Restart Server"
    echo "  5) View Logs"
    echo ""
    echo -e "${YELLOW}User & Bot Management:${NC}"
    echo "  6) Setup Users and Bots"
    echo "  7) Show Credentials"
    echo "  8) Start Example Bot (Node.js)"
    echo "  9) Start Example Bot (Python)"
    echo ""
    echo -e "${BLUE}Utilities:${NC}"
    echo "  10) Check Server Status"
    echo "  11) Show Network Info"
    echo "  12) Clean All Data (Reset)"
    echo "  13) Install Dependencies"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if server is running
check_status() {
    if docker ps | grep -q spacebar; then
        echo -e "${GREEN}✅ Server is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Server is not running${NC}"
        return 1
    fi
}

# Get IP address
get_ip() {
    ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "172\." | awk '{print $2}' | head -n 1
}

# Main loop
while true; do
    show_menu
    read -p "Select an option: " choice
    
    case $choice in
        1)
            echo -e "\n${YELLOW}Setting up network configuration...${NC}"
            chmod +x setup-network.sh
            ./setup-network.sh
            read -p "Press Enter to continue..."
            ;;
            
        2)
            echo -e "\n${GREEN}Starting Spacebar server...${NC}"
            chmod +x run-spacebar.sh
            ./run-spacebar.sh
            ;;
            
        3)
            echo -e "\n${YELLOW}Stopping server...${NC}"
            docker-compose down
            echo -e "${GREEN}✅ Server stopped${NC}"
            read -p "Press Enter to continue..."
            ;;
            
        4)
            echo -e "\n${YELLOW}Restarting server...${NC}"
            docker-compose restart
            echo -e "${GREEN}✅ Server restarted${NC}"
            read -p "Press Enter to continue..."
            ;;
            
        5)
            echo -e "\n${BLUE}Server Logs (Ctrl+C to exit):${NC}"
            docker logs -f spacebar --tail 50
            ;;
            
        6)
            echo -e "\n${YELLOW}Setting up users and bots...${NC}"
            if check_status; then
                node setup-users-and-bots.js
            else
                echo -e "${RED}Server must be running first!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
            
        7)
            echo -e "\n${BLUE}Credentials:${NC}"
            if [ -f credentials.json ]; then
                cat credentials.json | python3 -m json.tool
            else
                echo -e "${RED}No credentials found. Run setup first!${NC}"
            fi
            read -p "Press Enter to continue..."
            ;;
            
        8)
            echo -e "\n${GREEN}Starting Node.js bot...${NC}"
            if [ -f credentials.json ]; then
                echo "Available bots:"
                cat credentials.json | python3 -c "import json,sys; d=json.load(sys.stdin); [print(f'{i}: {b[\"name\"]}') for i,b in enumerate(d['bots'])]"
                read -p "Select bot number: " bot_num
                node example-bot.js $bot_num
            else
                echo -e "${RED}No credentials found. Run setup first!${NC}"
                read -p "Press Enter to continue..."
            fi
            ;;
            
        9)
            echo -e "\n${GREEN}Starting Python bot...${NC}"
            if [ -f credentials.json ]; then
                echo "Available bots:"
                cat credentials.json | python3 -c "import json,sys; d=json.load(sys.stdin); [print(f'{i}: {b[\"name\"]}') for i,b in enumerate(d['bots'])]"
                read -p "Select bot number: " bot_num
                python3 example-bot.py $bot_num
            else
                echo -e "${RED}No credentials found. Run setup first!${NC}"
                read -p "Press Enter to continue..."
            fi
            ;;
            
        10)
            echo -e "\n${BLUE}Server Status:${NC}"
            check_status
            if check_status > /dev/null 2>&1; then
                echo -e "\n${BLUE}Container Info:${NC}"
                docker ps --filter name=spacebar --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                echo -e "\n${BLUE}Resource Usage:${NC}"
                docker stats --no-stream spacebar
            fi
            read -p "Press Enter to continue..."
            ;;
            
        11)
            echo -e "\n${BLUE}Network Information:${NC}"
            IP=$(get_ip)
            echo -e "Local IP: ${GREEN}$IP${NC}"
            echo -e "Server URL: ${GREEN}http://$IP:3001${NC}"
            echo -e "API Endpoint: ${GREEN}http://$IP:3001/api${NC}"
            echo -e "WebSocket: ${GREEN}ws://$IP:3001${NC}"
            echo ""
            echo -e "${YELLOW}Share these URLs with other devices on your network${NC}"
            read -p "Press Enter to continue..."
            ;;
            
        12)
            echo -e "\n${RED}⚠️  WARNING: This will delete all data!${NC}"
            read -p "Are you sure? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                $DOCKER_COMPOSE down -v
                rm -rf data/ files/ credentials.json
                echo -e "${GREEN}✅ All data cleaned${NC}"
            else
                echo "Cancelled"
            fi
            read -p "Press Enter to continue..."
            ;;
            
        13)
            echo -e "\n${YELLOW}Installing dependencies...${NC}"
            echo "Installing Node.js dependencies..."
            npm install discord.js
            echo ""
            echo "Installing Python dependencies..."
            pip3 install discord.py
            echo -e "${GREEN}✅ Dependencies installed${NC}"
            read -p "Press Enter to continue..."
            ;;
            
        0)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
            
        *)
            echo -e "${RED}Invalid option${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done