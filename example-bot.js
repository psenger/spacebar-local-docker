const { Client, GatewayIntentBits } = require('discord.js');
const fs = require('fs');

// Read credentials
const credentials = JSON.parse(fs.readFileSync('./credentials.json', 'utf8'));
const SERVER_URL = credentials.server;

// Get bot token from command line or use first bot
const botIndex = process.argv[2] || 0;
const botInfo = credentials.bots[botIndex];

if (!botInfo || !botInfo.token) {
    console.error('❌ No bot token found. Run setup-users-and-bots.js first!');
    process.exit(1);
}

console.log(`🤖 Starting ${botInfo.name}...`);
console.log(`📡 Connecting to: ${SERVER_URL}`);

// Create client with custom endpoint
const client = new Client({
    intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers
    ],
    rest: {
        api: `${SERVER_URL}/api`
    },
    ws: {
        gateway: SERVER_URL.replace('http', 'ws')
    }
});

// Bot ready event
client.once('ready', () => {
    console.log(`✅ ${client.user.tag} is online!`);
    console.log(`📊 Connected to ${client.guilds.cache.size} guild(s)`);
    
    // Set bot status
    client.user.setActivity('on Spacebar', { type: 'PLAYING' });
    
    // List available channels
    client.guilds.cache.forEach(guild => {
        console.log(`\n📍 Guild: ${guild.name}`);
        guild.channels.cache
            .filter(channel => channel.type === 0) // Text channels
            .forEach(channel => {
                console.log(`   #${channel.name} (${channel.id})`);
            });
    });
});

// Message handler
client.on('messageCreate', async (message) => {
    // Ignore bot messages
    if (message.author.bot) return;
    
    console.log(`💬 [${message.channel.name}] ${message.author.username}: ${message.content}`);
    
    // Simple command handler
    if (message.content.startsWith('!')) {
        const command = message.content.slice(1).toLowerCase().split(' ')[0];
        
        switch(command) {
            case 'ping':
                message.reply('🏓 Pong!');
                break;
                
            case 'hello':
                message.reply(`👋 Hello ${message.author.username}!`);
                break;
                
            case 'info':
                message.reply(`
📊 **Server Info**
Server: ${message.guild.name}
Members: ${message.guild.memberCount}
Channels: ${message.guild.channels.cache.size}
Bot: ${client.user.username}
                `);
                break;
                
            case 'time':
                message.reply(`🕐 Current time: ${new Date().toLocaleString()}`);
                break;
                
            case 'help':
                message.reply(`
**Available Commands:**
\`!ping\` - Check if bot is responsive
\`!hello\` - Get a greeting
\`!info\` - Server information
\`!time\` - Current time
\`!help\` - This help message
                `);
                break;
        }
    }
    
    // Auto-respond to mentions
    if (message.mentions.has(client.user)) {
        message.reply(`You mentioned me! Try \`!help\` for commands.`);
    }
});

// Error handling
client.on('error', (error) => {
    console.error('❌ Client error:', error);
});

client.on('warn', (warning) => {
    console.warn('⚠️ Warning:', warning);
});

// Reconnection handling
client.on('disconnect', () => {
    console.log('📡 Disconnected. Attempting to reconnect...');
});

client.on('reconnecting', () => {
    console.log('🔄 Reconnecting...');
});

// Login
client.login(botInfo.token).catch(error => {
    console.error('❌ Failed to login:', error.message);
    console.log('Make sure the Spacebar server is running!');
});