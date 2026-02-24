#!/usr/bin/env python3
import json
import sys
import subprocess
import os
import shutil
import urllib.request

ALBUM_ART_PATH = "/tmp/waybar_album_art.jpg"
DEFAULT_ART_PATH = "/usr/share/icons/Adwaita/symbolic/status/audio-x-generic-symbolic.svg" # Placeholder

def get_player_status():
    try:
        output = subprocess.check_output(
            ["playerctl", "status"], 
            stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
        if not output: return "Stopped"
        return output.split("\n")[0]
    except subprocess.CalledProcessError:
        return "Stopped"

def get_metadata(key):
    try:
        output = subprocess.check_output(
            ["playerctl", "metadata", key],
            stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
        return output
    except subprocess.CalledProcessError:
        return ""

def update_album_art():
    art_url = get_metadata("mpris:artUrl")
    if not art_url:
        if os.path.exists(ALBUM_ART_PATH):
            os.remove(ALBUM_ART_PATH)
        return

    try:
        if art_url.startswith("file://"):
            local_path = art_url[7:]
            shutil.copy(local_path, ALBUM_ART_PATH)
        elif art_url.startswith("http"):
            urllib.request.urlretrieve(art_url, ALBUM_ART_PATH)
    except Exception:
        pass

def main():
    status = get_player_status()
    update_album_art()
    
    data = {
        "text": "",
        "alt": "default",
        "tooltip": "",
        "class": status.lower(),
        "percentage": 0
    }

    if status == "Stopped":
        data["text"] = "No Media"
        data["tooltip"] = "No media playing"
        data["class"] = "stopped"
    else:
        artist = get_metadata("artist")
        title = get_metadata("title")
        album = get_metadata("album")
        
        if title:
            text = f"{artist} - {title}" if artist else title
            data["text"] = text
            data["tooltip"] = f"{text}\nAlbum: {album}"
        else:
            data["text"] = "No Media"
            data["tooltip"] = "No media info"
            
        if status == "Playing":
            data["class"] = "playing"
            data["alt"] = "playing"
        elif status == "Paused":
            data["class"] = "paused"
            data["alt"] = "paused"

    print(json.dumps(data), flush=True)

if __name__ == "__main__":
    main()
