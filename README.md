# Konah

Konah is a lightweight, TUI-based wallpaper manager. While built with **Hyprland** in mind, it works on any Desktop Environment (tested on KDE) as long as **swww/awww** is used for the wallpaper backend.

---

## TUI Preview

![TUI](Preview/TUI.png)

## Video Preview

  <a href="https://www.youtube.com/watch?v=j5b5qll0UoY" target="_blank" rel="noopener noreferrer">
    <img src="Preview/fakeyoutubebutton.png" width="500">
  </a>

---

## Features

- **Portability:** Self-healing script that manages its own execution permissions and work in whatever path its copied to. 
- **Dynamic Backend:** Automatically detects and supports both `swww` and the new `awww` (Codeberg) daemons.
- **Dynamic Fetching:** Pulls high-quality wallpapers directly from Konachan based on your tags.  
- **Animated:** Supports the tag `animated` because Swww/Awww supports GIFs.
- **TUI Interface:** Interactive menu to change tags, ratings, resolution, and transition settings on the fly.  
- **Hypridle Integration:** Automatically updates your `hypridle.conf` to rotate wallpapers after a set period of inactivity.  
- **Performance Optimized:** Built-in cleanup ensures `/tmp` doesn't get cluttered with old images.   

---

## Dependencies

Make sure you have the following installed:

- `curl` – To fetch images and API data  
- `jq` – To parse the JSON response from Konachan  
- `swww` – The wallpaper daemon used for transitions  
- `kitty` – The default terminal for the TUI pop-up  

---

## Installation

Download or clone the repository. Then run:
```bash
./konah.sh
```
or double click, it will work either way since portability was in mind


## My hyprland setup
```ini
windowrule {
name = konah
match:title = konah-tui
float = true
keep_aspect_ratio = true
move = 20 50
size = 500 500
opacity = 0.65
no_blur = true
}
```

make sure hyprland bind paths are correct not to mention the exec-once for a boot wallpaper
```bash
# Opens the TUI to change settings
bind = $mainMod SHIFT, W, exec, #~/path/to/konah/konah.sh

# Quickly grab a new wallpaper with current settings
bind = $mainMod, W, exec, #~/path/to/konah/konah-grabber.sh
```