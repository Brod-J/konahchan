#!/usr/bin/env bash
[ -t 1 ] || exec kitty --title konah-tui bash "$0"
. "$HOME/.config/konah/link"

if command -v awww >/dev/null 2>&1; then
    DAEMON="Awww"
elif command -v swww >/dev/null 2>&1; then
    DAEMON="Swww"
else
    echo "Error: Neither awww nor swww found."
    sleep 2
    exit 1
fi

# If konahchan exists but isn't executable
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
if [ -f "$SCRIPT_DIR/konah-grabber.sh" ] && [ ! -x "$SCRIPT_DIR/konah-grabber.sh" ]; then
    chmod +x "$SCRIPT_DIR/konah-grabber.sh"
fi

if [ -f "$SCRIPT_DIR/konah.sh" ] && [ ! -x "$SCRIPT_DIR/konah.sh" ]; then
    chmod +x "$SCRIPT_DIR/konah.sh"
fi

CONF="$HOME/.config/konah/konah.conf"

mkdir -p $HOME/.config/konah
touch "$CONF"
touch $HOME/.config/konah/hypridle_snippet.conf

# --- PATHS ---
HYPR_CONF="$HOME/.config/hypr/hypridle.conf"
SNIPPET_CONF="$HOME/.config/konah/hypridle_snippet.conf"

touch "$SNIPPET_CONF"

# --- AUTO-INJECT INTO HYPRIDLE ---
if [ -f "$HYPR_CONF" ]; then
    SOURCE_LINE="source = $SNIPPET_CONF"
    if ! grep -qF "$SOURCE_LINE" "$HYPR_CONF"; then
        echo "Adding Konahchan source to hypridle.conf..."
        echo "" >> "$HYPR_CONF"
        echo "# --- Konahchan Auto-Config ---" >> "$HYPR_CONF"
        echo "$SOURCE_LINE" >> "$HYPR_CONF"
        echo "Injection successful."
    fi
fi

defaults() {
    TAGS=""
    RATING="safe"
    WIDTH=0
    HEIGHT=0
    DURATION=0
    TRANSITION="grow"
    FPS=60
    STEP=2
}

load() { . "$CONF" 2>/dev/null; }

save() {
cat > "$CONF" <<EOF
TAGS="$TAGS"
RATING="$RATING"
WIDTH="${WIDTH:-0}"
HEIGHT="${HEIGHT:-0}"
DURATION="$DURATION"
TRANSITION="$TRANSITION"
FPS="$FPS"
STEP="$STEP"
EOF
}

defaults
load

# Menu items
items=("Change" "Tags" "Rating" "Resolution" "Duration" "$DAEMON" "Download" "Exit")
idx=0

draw() {
clear
echo "Konah TUI"
echo

for i in "${!items[@]}"; do
    case $i in
     0) val="" ;;
     1) val="$TAGS" ;;
     2) val="$RATING" ;;
     3) val="${WIDTH}x${HEIGHT}" ;;
     4) val="$DURATION" ;;
     5) val="" ;;
     6) val="" ;;
     7) val="" ;;
    esac

    if [ "$i" -eq "$idx" ]; then
        printf "> %s: %s\n" "${items[$i]}" "$val"
    else
        printf "  %s: %s\n" "${items[$i]}" "$val"
    fi
done

echo
echo "↑↓ move   Enter select"
}

while true; do
draw
read -rsn1 key

case "$key" in
  $'\x1b')  # arrow keys
    read -rsn2 key
    case "$key" in
      '[A') ((idx--)) ;;
      '[B') ((idx++)) ;;
    esac
    ;;
  "")  # Enter
    case $idx in
      0)  # Apply Wallpaper
          # This finds the actual folder where THIS menu script is sitting
          GRABBER="$SCRIPT_DIR/konah-grabber.sh"

          if [ -f "$GRABBER" ]; then
              # We use 'bash' so we don't need chmod +x
              bash "$GRABBER"
          else
              echo "Error: $GRABBER not found in $SCRIPT_DIR"
              read -rp "Press Enter to continue..."
          fi
          ;;
      1) read -rp "Tags: " TAGS ;;
      2)  # Cycle Rating
         case "$RATING" in
             safe) RATING="explicit" ;;
             explicit) RATING="random" ;;
             random|"") RATING="safe" ;;
         esac
         ;;
      3)  # Resolution submenu
    ridx=0
    ritems=("Width" "Height" "Back")
    while true; do
        clear
        echo "Resolution: bigger than"
        echo
        for i in "${!ritems[@]}"; do
            case $i in
                0) val="$WIDTH" ;;
                1) val="$HEIGHT" ;;
                *) val="" ;;
            esac
            if [ "$i" -eq "$ridx" ]; then
                printf "> %s: %s\n" "${ritems[$i]}" "$val"
            else
                printf "  %s: %s\n" "${ritems[$i]}" "$val"
            fi
        done

        echo
        echo "↑↓ move   Enter edit   Esc to return"

        read -rsn1 rkey
        case "$rkey" in
            $'\x1b')
                read -rsn2 rkey
                case "$rkey" in
                    '[A') ((ridx--)) ;;
                    '[B') ((ridx++)) ;;
                esac
                ;;
            "")
                case $ridx in
                    0) read -rp "Width: " WIDTH ;;
                    1) read -rp "Height: " HEIGHT ;;
                    2) break ;;
                esac
                ;;
        esac

        ((ridx<0)) && ridx=$((${#ritems[@]}-1))
        ((ridx>=${#ritems[@]})) && ridx=0
        save
    done
    ;;
      4)  # Duration / Hypridle logic
          SCRIPT_DIR="$(dirname "$(readlink -f "$0")")" # Get the path
          read -rp "Duration (minutes, 0/empty = disable): " DURATION

          if [[ -n "$DURATION" && "$DURATION" -gt 0 ]]; then
              cat > "$HOME/.config/konah/hypridle_snippet.conf" <<EOF
listener {
    timeout = $(($DURATION * 60))
    on-resume = bash $SCRIPT_DIR/konah-grabber.sh
}
EOF
          else
              echo "" > "$HOME/.config/konah/hypridle_snippet.conf"
          fi
          systemctl --user restart hypridle
          ;;
      5)  # Awww/Swww submenu
          sidx=0
          sitems=("Transition" "FPS" "Step" "Back")
          while true; do
              clear
              echo "$DAEMON Settings"
              echo
              for i in "${!sitems[@]}"; do
                  case $i in
                      0) val="$TRANSITION" ;;
                      1) val="$FPS" ;;
                      2) val="$STEP" ;;
                      *) val="" ;;
                  esac
                  if [ "$i" -eq "$sidx" ]; then
                      printf "> %s: %s\n" "${sitems[$i]}" "$val"
                  else
                      printf "  %s: %s\n" "${sitems[$i]}" "$val"
                  fi
              done
              echo
              echo "↑↓ move   Enter edit   Esc to return"

              read -rsn1 skey
              case "$skey" in
                  $'\x1b')  # arrow keys
                      read -rsn2 skey
                      case "$skey" in
                          '[A') ((sidx--)) ;;
                          '[B') ((sidx++)) ;;
                      esac
                      ;;
                  "")  # Enter
                      case $sidx in
                          0) read -rp "Transition: " TRANSITION ;;
                          1) read -rp "FPS: " FPS ;;
                          2) read -rp "Step: " STEP ;;
                          3) break ;; # Back to main menu
                      esac
                      ;;
              esac
              ((sidx<0)) && sidx=$((${#sitems[@]}-1))
              ((sidx>=${#sitems[@]})) && sidx=0
              save
          done
          ;;
      6)  # Open current link
    if [ -f $HOME/.config/konah/link ]; then
        . $HOME/.config/konah/link  # reload the latest link
    fi
    [ -n "$LINK" ] && xdg-open "$LINK" >/dev/null 2>&1 &
    ;;
      7) save; exit ;;
    esac
    ;;
esac

((idx<0)) && idx=$((${#items[@]}-1))
((idx>=${#items[@]})) && idx=0

save
done
