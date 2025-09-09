#!/usr/bin/env node

const http = require('http');
const https = require('https');
const fs = require('fs');

// Ignore self-signed TLS cert errors
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Read config to get server URL
const config = JSON.parse(fs.readFileSync('./config/config.json', 'utf8'));
const SERVER_URL = config.api.endpointPublic.replace('/api', '');

console.log(`🔧 Setting up users and bots on ${SERVER_URL}`);
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// Helper function for HTTP/HTTPS requests
function makeRequest(method, path, data = null, token = null) {
    return new Promise((resolve, reject) => {
        const url = new URL(`${SERVER_URL}${path}`);
        const options = {
            hostname: url.hostname,
            port: url.port || (url.protocol === 'https:' ? 443 : 80),
            path: url.pathname,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            rejectUnauthorized: false // Allow self-signed certs
        };

        if (token) {
            options.headers['Authorization'] = token;
        }

        const reqModule = url.protocol === 'https:' ? https : http;

        const req = reqModule.request(options, (res) => {
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
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(body);
                    } else {
                        reject({message: body, statusCode: res.statusCode});
                    }
                }
            });
        });

        req.on('error', reject);

        if (data) {
            const payload = JSON.stringify(data);
            req.write(payload);
        }
        req.end();
    });
}

// Create users
async function createUser(username, email, password) {
    try {
        const response = await makeRequest('POST', '/api/auth/register', {
            username,                 // minLength 2
            password,                 // minLength 1, maxLength 72
            consent: true,                      // required
            email,
            fingerprint: 'string',
            date_of_birth: '2000-01-01',
            promotional_email_opt_in: false,
            unique_username_registration: false,
            global_name: username
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
async function login(username, email, password) {
    console.log(`   Attempting to login as ${username}...`);

    try {
        const response = await makeRequest('POST', '/api/auth/login',{
            login: email,
            password,
            undelete: false,
             captcha_key: 'string',
            login_source:"string",
            gift_code_sku_id:"string"
        });
        console.log(`✅ Logged in as: ${username}`);
        return response.token;
    } catch (error) {
        const errorMsg = error.message || error.errors?.[0]?.message || 'Unknown error';
        console.log(`❌ Failed with error: ${errorMsg}`);
    }

    return null;
}

// Create a bot application
async function createBot(token, botName, description) {
    try {
        const response = await makeRequest('POST', '/api/applications', {
            name: botName,
            team_id: 'string'
            // description: description,
            // bot_public: true,
            // bot_require_code_grant: false
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
        const response = await makeRequest('POST', '/api/guilds', {name: guildName}, token);
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

    await createUser('admin', `admin@monkeygoboom.com`, 'AdminPass123!');
    await createUser('user1', `user1@monkeygoboom.com`, 'UserPass123!');
    await createUser('user2', `user2@monkeygoboom.com`, 'UserPass123!');
    await createUser('user3', `user3@monkeygoboom.com`, 'UserPass123!');

    console.log('\n🔐 Logging in as admin...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const adminToken = await login('admin', `admin@monkeygoboom.com`, 'AdminPass123!');

    if (!adminToken) {
        console.log('❌ Could not login as admin. Exiting...');
        return;
    }

    console.log('\n🤖 Creating Bots...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const bots = [];

    const botNames = ['WelcomeBot', 'ModeratorBot', 'MusicBot', 'GameBot'];
    for (let name of botNames) {
        const bot = await createBot(adminToken, name, `${name} description`);
        if (bot) bots.push(bot);
    }

    console.log('\n🏰 Creating Guild...');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    const guild = await createGuild(adminToken, 'My Spacebar Server');

    // Save credentials
    const credentials = {
        server: SERVER_URL,
        admin: {username: 'admin', email: `admin@monkeygoboom.com`, password: 'AdminPass123!', token: adminToken},
        users: [
            {username: 'user1', email: `user1@monkeygoboom.com`, password: 'UserPass123!'},
            {username: 'user2', email: `user2@monkeygoboom.com`, password: 'UserPass123!'},
            {username: 'user3', email: `user3@monkeygoboom.com`, password: 'UserPass123!'}
        ],
        bots: bots.map(bot => ({name: bot.name, id: bot.id, token: bot.bot?.token})).filter(b => b.token),
        guild: guild
    };

    fs.writeFileSync('credentials.json', JSON.stringify(credentials, null, 2));

    console.log('\n✅ Setup Complete!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📄 Credentials saved to: credentials.json');
    console.log(`🌐 Server URL: ${SERVER_URL}`);
}

// Wait a few seconds for server startup
console.log('⏳ Waiting for server to be ready...');
setTimeout(() => {
    setup().catch(console.error);
}, 3000);
