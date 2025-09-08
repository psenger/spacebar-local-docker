import discord
import PySimpleGUI as sg
import asyncio
from discord.ext import commands

# Replace with your Spacebar instance URL
SPACEBAR_API_URL = "http://192.168.0.101:3001/api"
BOT_TOKEN = "511e1e2ad1c6288ecfbf3bd5e5a316d4b3f1747434ca8af4a1acf7e5408618d5"  # Replace with your bot or user token

# Set up Discord client with custom API endpoint
intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
client = commands.Bot(command_prefix="!", intents=intents, api_endpoint=SPACEBAR_API_URL)

# GUI Layout
layout = [
    [sg.Text("Spacebar GUI Client", font=("Helvetica", 16))],
    [sg.Text("Guild:"), sg.Combo([], key="-GUILD-", size=(30, 1), readonly=True)],
    [sg.Text("Channel:"), sg.Combo([], key="-CHANNEL-", size=(30, 1), readonly=True)],
    [sg.Text("Messages:")],
    [sg.Multiline("", key="-MESSAGES-", size=(50, 20), disabled=True)],
    [sg.Text("Message:"), sg.InputText(key="-INPUT-", size=(40, 1)), sg.Button("Send")],
    [sg.Button("Refresh Channels"), sg.Button("Exit")]
]

window = sg.Window("Spacebar Client", layout, finalize=True)

# Global variables to track selected guild and channel
selected_guild = None
selected_channel = None

# Discord event: Bot ready
@client.event
async def on_ready():
    print(f"Logged in as {client.user}")
    guilds = [guild.name for guild in client.guilds]
    window["-GUILD-"].update(values=guilds)
    window["-MESSAGES-"].update(f"Bot is ready! Connected to {len(guilds)} guild(s).\n")

# Function to update channels for selected guild
def update_channels(guild_name):
    global selected_guild
    for guild in client.guilds:
        if guild.name == guild_name:
            selected_guild = guild
            channels = [channel.name for channel in guild.text_channels]
            window["-CHANNEL-"].update(values=channels)
            break

# Function to fetch and display messages
async def fetch_messages(channel_name):
    global selected_channel
    if selected_guild:
        for channel in selected_guild.text_channels:
            if channel.name == channel_name:
                selected_channel = channel
                messages = ""
                async for message in channel.history(limit=50):
                    messages += f"{message.author}: {message.content}\n"
                window["-MESSAGES-"].update(messages)
                break

# Main event loop
async def main():
    await client.start(BOT_TOKEN)

# Run Discord client in a separate thread
def run_discord():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(main())

import threading
threading.Thread(target=run_discord, daemon=True).start()

# GUI Event Loop
while True:
    event, values = window.read(timeout=100)
    if event == sg.WIN_CLOSED or event == "Exit":
        break
    elif event == "-GUILD-":
        if values["-GUILD-"]:
            update_channels(values["-GUILD-"])
    elif event == "-CHANNEL-":
        if values["-CHANNEL-"] and client.is_ready():
            asyncio.run_coroutine_threadsafe(fetch_messages(values["-CHANNEL-"]), client.loop)
    elif event == "Send" and values["-INPUT-"] and selected_channel:
        message = values["-INPUT-"]
        asyncio.run_coroutine_threadsafe(selected_channel.send(message), client.loop)
        window["-INPUT-"].update("")
        asyncio.run_coroutine_threadsafe(fetch_messages(selected_channel.name), client.loop)
    elif event == "Refresh Channels" and selected_guild:
        update_channels(selected_guild.name)

window.close()
client.close()