#!/usr/bin/env node

const http = require('http');
const fs = require('fs');

// Read config to get server URL
const config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));
const SERVER_URL = config.api.endpointPublic.replace('/api', '');

console.log(`🔧 Setting up users and bots on ${SERVER_URL}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// Helper function for HTTP requests
function makeRequest(method, path, data = null, token = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(`${SERVER_URL}${path}`);
        const options = {
            hostname: url.hostname,
            port: url.port,
            path: url.pathname,
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        
        if (token) {
            options.headers['Authorization'] = token;
        }
        
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(response);
                    } else {
                        reject(response);
                    }
                } catch (e) {
                    resolve(body);
                }
            });
        });
        
        req.on('error', reject);
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

// Create users
async function createUser(username, password) {
    try {
        const response = await makeRequest('POST', '/api/auth/register', {
            username: username,
            password: password,
            consent: true,
            date_of_birth: '2000-01-01'
        });
        console.log(`✅ Created user: ${username}`);
        return response;
    } catch (error) {
        if (error.message && error.message.includes('already')) {
            console.log(`ℹ️  User ${username} already exists`);
        } else {
            console.log(`❌ Failed to create user ${username}:`, error.message || error);
        }
        return null;
    }
}

// Login to get token
async function login(username, password) {
    try {
        const response = await makeRequest('POST', '/api/auth/login', {
            login: username,
            password: password
        });
        console.log(`✅ Logged in as: ${username}`);
        return response.token;
    } catch (error) {
        console.log(`❌ Failed to login ${username}:`, error.message || error);
        return null;
    }
}

// Create a bot application
async function createBot(token, botName, description) {
    try {
        const response = await makeRequest('POST', '/api/applications', {
            name: botName,
            description: description,
            bot_public: true,
            bot_require_code_grant: false
        }, token);
        
        console.log(`✅ Created bot: ${botName}`);
        console.log(`   Token: ${response.bot?.token || 'Check response'}`);
        return response;
    } catch (error) {
        console.log(`❌ Failed to create bot ${botName}:`, error.message || error);
        return null;
    }
}

// Create a guild (server)
async function createGuild(token, guildName) {
    try {
        const response = await makeRequest('POST', '/api/guilds', {
            name: guildName
        }, token);
        console.log(`✅ Created guild: ${guildName}`);
        return response;
    } catch (error) {
        console.log(`ℹ️  Guild creation issue:`, error.message || error);
        return null;
    }
}

// Main setup function
async function setup() {
    console.log('\n📝 Creating Users...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Create admin user
    await createUser('admin', 'AdminPass123!');
    
    // Create regular users
    await createUser('user1', 'UserPass123!');
    await createUser('user2', 'UserPass123!');
    await createUser('user3', 'UserPass123!');
    
    // Login as admin
    console.log('\n🔐 Logging in as admin...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const adminToken = await login('admin', 'AdminPass123!');
    
    if (!adminToken) {
        console.log('❌ Could not login as admin. Exiting...');
        return;
    }
    
    // Create bots
    console.log('\n🤖 Creating Bots...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const bots = [];
    
    const bot1 = await createBot(adminToken, 'WelcomeBot', 'Welcomes new users');
    if (bot1) bots.push(bot1);
    
    const bot2 = await createBot(adminToken, 'ModeratorBot', 'Helps with moderation');
    if (bot2) bots.push(bot2);
    
    const bot3 = await createBot(adminToken, 'MusicBot', 'Plays music in voice channels');
    if (bot3) bots.push(bot3);
    
    const bot4 = await createBot(adminToken, 'GameBot', 'Provides games and fun activities');
    if (bot4) bots.push(bot4);
    
    // Create a guild
    console.log('\n🏰 Creating Guild...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const guild = await createGuild(adminToken, 'My Spacebar Server');
    
    // Save credentials to file
    const credentials = {
        server: SERVER_URL,
        admin: {
            username: 'admin',
            password: 'AdminPass123!',
            token: adminToken
        },
        users: [
            { username: 'user1', password: 'UserPass123!' },
            { username: 'user2', password: 'UserPass123!' },
            { username: 'user3', password: 'UserPass123!' }
        ],
        bots: bots.map(bot => ({
            name: bot.name,
            id: bot.id,
            token: bot.bot?.token
        })).filter(b => b.token),
        guild: guild
    };
    
    fs.writeFileSync('credentials.json', JSON.stringify(credentials, null, 2));
    
    console.log('\n✅ Setup Complete!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📄 Credentials saved to: credentials.json');
    console.log(`🌐 Server URL: ${SERVER_URL}`);
    console.log(`👤 Admin: admin / AdminPass123!`);
    console.log(`👥 Users: user1, user2, user3 (password: UserPass123!)`);
    console.log(`🤖 Bots: ${bots.length} bots created`);
    console.log('\nClients can connect to:', SERVER_URL);
}

// Wait for server to be ready
console.log('⏳ Waiting for server to be ready...');
setTimeout(() => {
    setup().catch(console.error);
}, 3000);