#!/usr/bin/env bash
. "$HOME/.config/konah/konah.conf"

# --- CONFIG FILES ---
LAST_WALLPAPER_FILE="$HOME/.config/konah/path"

# Build the query
QUERY_TAGS=$(echo "$TAGS width:$WIDTH.. height:$HEIGHT.. rating:$RATING order:random" | sed 's/ /+/g')
API="https://konachan.net/post.json?limit=1&tags=$QUERY_TAGS"

echo "Fetching from Konachan..."
RESPONSE=$(curl -s -L "$API")

# Extract the URL
URL=$(echo "$RESPONSE" | jq -r '.[0].file_url')

# Validate URL
if [ "$URL" = "null" ] || [ -z "$URL" ]; then
    echo "Could not find image. Site might be down or tags are too specific."
    exit 1
fi

# Save the link for your menu script
mkdir -p $HOME/.config/konah
printf 'LINK="%s"\n' "$URL" > $HOME/.config/konah/link

# --- DYNAMIC FILENAME LOGIC ---
FILENAME=$(basename "$URL")
FILEPATH="/tmp/$FILENAME"

echo "Downloading:"

# Download to the specific path
curl -s -L "$URL" -o "$FILEPATH"

# Check if download succeeded
if [ -s "$FILEPATH" ]; then

    #Ensure the daemon is running
    if ! pgrep -x "swww-daemon" > /dev/null; then
        echo "Starting swww-daemon..."
        swww-daemon &
        sleep 0.5
    fi

    #Set the wallpaper
    swww img "$FILEPATH" \
        --transition-type "$TRANSITION" \
        --transition-step "$STEP" \
        --transition-fps "$FPS"

    echo "Wallpaper updated!"

    #CLEANUP: Delete the PREVIOUS wallpaper if it exists
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        OLD_FILE=$(cat "$LAST_WALLPAPER_FILE")
        # Check if it's a valid file and NOT the same as the new one (just in case)
        if [ -f "$OLD_FILE" ] && [ "$OLD_FILE" != "$FILEPATH" ]; then
            echo "Removing old wallpaper"
            sleep 1
            rm "$OLD_FILE"
        fi
    fi

    #Record the current wallpaper path for next time
    echo "$FILEPATH" > "$LAST_WALLPAPER_FILE"

else
    echo "Download failed."
    sleep 2
    exit 1
fi
