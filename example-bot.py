#!/usr/bin/env python3

import discord
from discord.ext import commands
import json
import sys
import asyncio

# Read credentials
with open('credentials.json', 'r') as f:
    credentials = json.load(f)

# Get bot info
bot_index = int(sys.argv[1]) if len(sys.argv) > 1 else 0
if bot_index >= len(credentials['bots']):
    print(f"❌ Bot index {bot_index} not found. Available: 0-{len(credentials['bots'])-1}")
    sys.exit(1)

bot_info = credentials['bots'][bot_index]
SERVER_URL = credentials['server']

print(f"🤖 Starting {bot_info['name']}...")
print(f"📡 Connecting to: {SERVER_URL}")

# Configure for custom server
class CustomClient(commands.Bot):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Override the HTTP route
        self.http.BASE = SERVER_URL + '/api'
        
# Create bot instance
intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = CustomClient(
    command_prefix='!',
    intents=intents
)

# Override gateway
discord.gateway.DiscordWebSocket.DEFAULT_GATEWAY = SERVER_URL.replace('http', 'ws')

@bot.event
async def on_ready():
    print(f'✅ {bot.user.name} is online!')
    print(f'📊 Connected to {len(bot.guilds)} guild(s)')
    
    # List guilds and channels
    for guild in bot.guilds:
        print(f'\n📍 Guild: {guild.name}')
        for channel in guild.text_channels:
            print(f'   #{channel.name} ({channel.id})')
    
    # Set status
    await bot.change_presence(activity=discord.Game(name="on Spacebar"))

@bot.event
async def on_message(message):
    # Ignore bot messages
    if message.author.bot:
        return
    
    print(f'💬 [{message.channel.name}] {message.author.name}: {message.content}')
    
    # Process commands
    await bot.process_commands(message)
    
    # Auto-respond to mentions
    if bot.user in message.mentions:
        await message.reply(f"You mentioned me! Try `!help` for commands.")

@bot.command(name='ping')
async def ping(ctx):
    """Check bot responsiveness"""
    latency = round(bot.latency * 1000)
    await ctx.send(f'🏓 Pong! Latency: {latency}ms')

@bot.command(name='hello')
async def hello(ctx):
    """Say hello"""
    await ctx.send(f'👋 Hello {ctx.author.mention}!')

@bot.command(name='info')
async def server_info(ctx):
    """Get server information"""
    guild = ctx.guild
    embed = discord.Embed(
        title="📊 Server Information",
        color=discord.Color.blue()
    )
    embed.add_field(name="Server", value=guild.name, inline=True)
    embed.add_field(name="Members", value=guild.member_count, inline=True)
    embed.add_field(name="Channels", value=len(guild.channels), inline=True)
    embed.add_field(name="Bot", value=bot.user.name, inline=True)
    await ctx.send(embed=embed)

@bot.command(name='echo')
async def echo(ctx, *, message):
    """Echo a message"""
    await ctx.send(f"📢 {message}")

@bot.command(name='roll')
async def roll_dice(ctx, dice: str = "1d6"):
    """Roll dice (e.g., !roll 2d6)"""
    try:
        rolls, limit = map(int, dice.split('d'))
        result = ', '.join(str(random.randint(1, limit)) for _ in range(rolls))
        total = sum(random.randint(1, limit) for _ in range(rolls))
        await ctx.send(f'🎲 Rolled {dice}: {result} (Total: {total})')
    except:
        await ctx.send('Format: !roll NdN (e.g., !roll 2d6)')

@bot.event
async def on_member_join(member):
    """Welcome new members"""
    channel = member.guild.system_channel
    if channel:
        await channel.send(f'Welcome {member.mention} to {member.guild.name}! 🎉')

@bot.event
async def on_error(event, *args, **kwargs):
    print(f'❌ Error in {event}: {sys.exc_info()}')

# Run the bot
if __name__ == '__main__':
    import random
    
    try:
        bot.run(bot_info['token'])
    except Exception as e:
        print(f'❌ Failed to start bot: {e}')
        print('Make sure the Spacebar server is running!')