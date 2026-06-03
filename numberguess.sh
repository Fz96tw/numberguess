#!/usr/bin/env bash

# ── Terminal capabilities ─────────────────────────────────────────────────────

if [[ -t 1 ]] && tput colors &>/dev/null && [[ $(tput colors) -ge 8 ]]; then
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    DIM=$(tput dim 2>/dev/null || true)
    RESET=$(tput sgr0)
else
    RED=""; BLUE=""; GREEN=""; YELLOW=""; CYAN=""; BOLD=""; DIM=""; RESET=""
fi

HAS_TPUT=0
if tput clear &>/dev/null && tput cup 0 0 &>/dev/null; then
    HAS_TPUT=1
fi

# ── Layout constants ──────────────────────────────────────────────────────────

HEADER_ROW=0
INFO_ROW=2
HISTORY_TOP=5
HISTORY_MAX=12   # max lines in history pane
INPUT_ROW=19
MSG_ROW=21

# ── Constants ─────────────────────────────────────────────────────────────────

MAX_GUESSES=10
SCORES_FILE="${HOME}/.numberguess_scores"

# ── Cleanup ───────────────────────────────────────────────────────────────────

cleanup() {
    if [[ $HAS_TPUT -eq 1 ]]; then
        tput cup 23 0
        tput el
        tput cnorm 2>/dev/null || true
    fi
    echo ""
}
trap cleanup EXIT INT TERM

# ── Win screen ───────────────────────────────────────────────────────────────

show_win_screen() {
    local player=$1 guesses=$2
    tput clear 2>/dev/null || printf '\033[2J\033[H'
    echo ""
    echo "${GREEN}${BOLD}"
    echo "  ██╗   ██╗ ██████╗ ██╗   ██╗    ██╗    ██╗██╗███╗   ██╗██╗"
    echo "  ╚██╗ ██╔╝██╔═══██╗██║   ██║    ██║    ██║██║████╗  ██║██║"
    echo "   ╚████╔╝ ██║   ██║██║   ██║    ██║ █╗ ██║██║██╔██╗ ██║██║"
    echo "    ╚██╔╝  ██║   ██║██║   ██║    ██║███╗██║██║██║╚██╗██║╚═╝"
    echo "     ██║   ╚██████╔╝╚██████╔╝    ╚███╔███╔╝██║██║ ╚████║██╗"
    echo "     ╚═╝    ╚═════╝  ╚═════╝      ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═╝"
    echo "${RESET}"
    echo ""
    echo "${GREEN}        🎉  Well done, ${BOLD}$player${RESET}${GREEN}!  🎉${RESET}"
    echo ""
    echo "${YELLOW}        Rating:  $(get_stars "$guesses")${RESET}"
    echo "${DIM}        Guessed the number in $guesses guess(es).${RESET}"
    echo ""
    sleep 2
}

# ── Helpers ───────────────────────────────────────────────────────────────────

get_stars() {
    local n=$1 count
    if   [[ $n -le 2 ]]; then count=5
    elif [[ $n -le 4 ]]; then count=4
    elif [[ $n -le 6 ]]; then count=3
    elif [[ $n -le 8 ]]; then count=2
    else                       count=1
    fi
    local filled="" empty="" i
    for (( i=0; i<count; i++ )); do filled+="★"; done
    for (( i=count; i<5; i++ )); do empty+="☆"; done
    echo "$filled$empty ($count/5)"
}

save_score() {
    local name=$1 diff=$2 score=$3
    local key="$name|$diff" tmp updated=0
    tmp=$(mktemp)
    if [[ -f "$SCORES_FILE" ]]; then
        while IFS='|' read -r n d s; do
            if [[ "$n|$d" == "$key" ]]; then
                [[ $score -lt $s ]] && echo "$n|$d|$score" || echo "$n|$d|$s"
                updated=1
            else
                echo "$n|$d|$s"
            fi
        done < "$SCORES_FILE" > "$tmp"
    fi
    [[ $updated -eq 0 ]] && echo "$name|$diff|$score" >> "$tmp"
    mv "$tmp" "$SCORES_FILE"
}

show_leaderboard() {
    echo ""
    echo "${YELLOW}${BOLD}================================${RESET}"
    echo "${YELLOW}${BOLD}        HIGH SCORES             ${RESET}"
    echo "${YELLOW}${BOLD}================================${RESET}"
    if [[ ! -f "$SCORES_FILE" ]] || [[ ! -s "$SCORES_FILE" ]]; then
        echo "  No scores yet. Play a game to get on the board!"
        echo "${YELLOW}================================${RESET}"
        echo ""
        return
    fi
    for diff in Easy Medium Hard; do
        local found=0
        while IFS='|' read -r name d score; do
            if [[ "$d" == "$diff" ]]; then
                if [[ $found -eq 0 ]]; then
                    echo ""; echo "  ${CYAN}${BOLD}[ $diff ]${RESET}"; found=1
                fi
                printf "  %-15s  %2s guess(es)  %s\n" "$name" "$score" "$(get_stars "$score")"
            fi
        done < "$SCORES_FILE"
    done
    echo ""; echo "${YELLOW}================================${RESET}"; echo ""
}

# ── tput board drawing ────────────────────────────────────────────────────────

# Print a string at (row, col)
at() { tput cup "$1" "$2"; printf "%s" "$3"; }

# Draw a horizontal rule across the full width
hline() {
    local row=$1 cols
    cols=$(tput cols)
    tput cup "$row" 0
    printf '%*s' "$cols" '' | tr ' ' '─'
}

draw_board() {
    local player=$1 diff=$2 max_num=$3 remaining=$4
    local cols
    cols=$(tput cols)

    tput clear
    tput civis 2>/dev/null || true   # hide cursor during draw

    # Header
    at $HEADER_ROW 0 "${CYAN}${BOLD}"
    printf "%-${cols}s" " 🎮  NUMBER GUESSING GAME  ·  Player: $player"
    printf "%s" "${RESET}"
    hline 1

    # Info panel
    at $INFO_ROW 2 "${BOLD}Difficulty:${RESET} ${YELLOW}$diff${RESET} (1–$max_num)"
    at $(( INFO_ROW + 1 )) 2 "${BOLD}Guesses left:${RESET} ${remaining}"
    hline 4

    # History pane header
    at $(( HISTORY_TOP - 1 )) 2 "${DIM}Guess history${RESET}"

    # Input area separator
    hline $((INPUT_ROW - 1))

    # Bottom border
    hline $((MSG_ROW + 1))

    tput cnorm 2>/dev/null || true   # restore cursor
}

update_info() {
    local remaining=$1
    tput cup $(( INFO_ROW + 1 )) 2
    tput el
    printf "%s" "${BOLD}Guesses left:${RESET} ${remaining}"
}

# history_lines holds the displayed guess log
history_lines=()

add_history() {
    local line=$1
    history_lines+=("$line")
    # Keep within pane
    local start=0
    if [[ ${#history_lines[@]} -gt $HISTORY_MAX ]]; then
        start=$(( ${#history_lines[@]} - HISTORY_MAX ))
    fi
    local row=$HISTORY_TOP
    for (( i=start; i<${#history_lines[@]}; i++ )); do
        tput cup "$row" 2; tput el
        printf "%s" "${history_lines[$i]}"
        (( row++ ))
    done
}

show_msg() {
    local msg=$1
    tput cup $MSG_ROW 2; tput el
    printf "%s" "$msg"
}

get_input() {
    local prompt=$1
    tput cup $INPUT_ROW 2; tput el
    printf "%s" "$prompt"
    local val
    read -r val
    echo "$val"
}

# ── Game ──────────────────────────────────────────────────────────────────────

play_game() {
    local PLAYER_NAME=$1

    # Difficulty selection (scrolling, before fullscreen)
    echo ""
    echo "Select difficulty:"
    echo "  1) Easy   (1–50)"
    echo "  2) Medium (1–100)"
    echo "  3) Hard   (1–200)"
    echo ""

    local DIFFICULTY MAX_NUM
    while true; do
        printf "Enter choice [1-3]: "
        if ! read -r choice; then echo ""; return; fi
        case $choice in
            1) DIFFICULTY="Easy";   MAX_NUM=50;  break ;;
            2) DIFFICULTY="Medium"; MAX_NUM=100; break ;;
            3) DIFFICULTY="Hard";   MAX_NUM=200; break ;;
            *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
        esac
    done

    local SECRET=$(( RANDOM % MAX_NUM + 1 ))
    local guesses=0
    history_lines=()

    if [[ $HAS_TPUT -eq 1 ]]; then
        # ── Full-screen game loop ─────────────────────────────────────────────
        local remaining=$MAX_GUESSES
        draw_board "$PLAYER_NAME" "$DIFFICULTY" "$MAX_NUM" "$remaining"

        while [[ $guesses -lt $MAX_GUESSES ]]; do
            remaining=$(( MAX_GUESSES - guesses ))
            update_info "$remaining"

            local guess
            guess=$(get_input "▶ Your guess: ")

            if ! [[ $guess =~ ^[0-9]+$ ]]; then
                show_msg "${RED}Please enter a valid number.${RESET}"
                continue
            fi

            (( guesses++ ))
            remaining=$(( MAX_GUESSES - guesses ))

            if [[ $guess -lt $SECRET ]]; then
                add_history "${BLUE}#$guesses${RESET}  $guess  →  Too low ↑${RESET}"
                show_msg "${DIM}$remaining guess(es) remaining.${RESET}"
            elif [[ $guess -gt $SECRET ]]; then
                add_history "${RED}#$guesses${RESET}  $guess  →  Too high ↓${RESET}"
                show_msg "${DIM}$remaining guess(es) remaining.${RESET}"
            else
                add_history "${GREEN}#$guesses${RESET}  $guess  →  ✓ Correct!${RESET}"
                update_info "0"
                show_msg "${GREEN}*** YOU WIN! ***  Press any key...${RESET}"
                tput cup $INPUT_ROW 2; tput el
                save_score "$PLAYER_NAME" "$DIFFICULTY" "$guesses"
                tput cup 23 0
                tput cnorm 2>/dev/null || true
                show_win_screen "$PLAYER_NAME" "$guesses"
                show_leaderboard
                return
            fi
        done

        # Loss
        show_msg "*** GAME OVER ***  The number was $SECRET."
        tput cup $INPUT_ROW 2; tput el
        tput cup 23 0
        tput cnorm 2>/dev/null || true
        echo ""
        echo "Hard luck, $PLAYER_NAME! The number was $SECRET."
        echo "Rating: ☆☆☆☆☆ (0/5)"
        show_leaderboard

    else
        # ── Fallback: plain scrolling ─────────────────────────────────────────
        echo ""
        echo "================================"
        echo "  Difficulty: $DIFFICULTY (1–$MAX_NUM)  |  $MAX_GUESSES guesses"
        echo "================================"
        echo ""

        while [[ $guesses -lt $MAX_GUESSES ]]; do
            local remaining=$(( MAX_GUESSES - guesses ))
            printf "[$DIFFICULTY] Guess ($remaining left): "
            if ! read -r guess; then echo ""; break; fi

            if ! [[ $guess =~ ^[0-9]+$ ]]; then
                echo "Please enter a valid number."; echo ""; continue
            fi

            (( guesses++ ))
            remaining=$(( MAX_GUESSES - guesses ))

            if [[ $guess -lt $SECRET ]]; then
                echo "${BLUE}Too low! Try higher.${RESET}"
            elif [[ $guess -gt $SECRET ]]; then
                echo "${RED}Too high! Try lower.${RESET}"
            else
                save_score "$PLAYER_NAME" "$DIFFICULTY" "$guesses"
                show_win_screen "$PLAYER_NAME" "$guesses"
                show_leaderboard; return
            fi
            echo "${DIM}  $remaining guess(es) remaining.${RESET}"; echo ""
        done

        echo ""; echo "*** GAME OVER ***"
        echo "Hard luck, $PLAYER_NAME! The number was $SECRET."
        echo "Rating: ☆☆☆☆☆ (0/5)"
        show_leaderboard
    fi
}

# ── Main menu ─────────────────────────────────────────────────────────────────

echo "${CYAN}${BOLD}"
echo "================================"
echo "  NUMBER GUESSING GAME"
echo "================================"
printf "%s" "${RESET}"
echo ""
printf "Enter your name: "
read -r PLAYER_NAME || true
PLAYER_NAME="${PLAYER_NAME//[[:space:]]/}"
PLAYER_NAME="${PLAYER_NAME:-Player}"

while true; do
    echo ""
    echo "${BOLD}--------------------------------${RESET}"
    echo "  Hello, ${CYAN}$PLAYER_NAME${RESET}!"
    echo "  1) Play game"
    echo "  2) View leaderboard"
    echo "  3) Quit"
    echo "${BOLD}--------------------------------${RESET}"
    printf "Choice [1-3]: "
    if ! read -r choice; then echo ""; break; fi
    case $choice in
        1) play_game "$PLAYER_NAME" ;;
        2) show_leaderboard ;;
        3) echo "Goodbye, ${CYAN}$PLAYER_NAME${RESET}!"; break ;;
        *) echo "Please enter 1, 2, or 3." ;;
    esac
done
