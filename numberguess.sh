#!/usr/bin/env bash

if [[ -t 1 ]] && tput colors &>/dev/null && [[ $(tput colors) -ge 8 ]]; then
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    DIM=$(tput dim 2>/dev/null || true)
    RESET=$(tput sgr0)
else
    RED=""; BLUE=""; GREEN=""; YELLOW=""; DIM=""; RESET=""
fi

MAX_GUESSES=10
SCORES_FILE="${HOME}/.numberguess_scores"

get_stars() {
    local n=$1
    local count
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
    local key="$name|$diff"
    local tmp updated=0
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
    echo "${YELLOW}================================${RESET}"
    echo "${YELLOW}        HIGH SCORES${RESET}"
    echo "${YELLOW}================================${RESET}"
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
                    echo ""
                    echo "  ${YELLOW}[ $diff ]${RESET}"
                    found=1
                fi
                printf "  %-15s  %2s guess(es)  %s\n" "$name" "$score" "$(get_stars "$score")"
            fi
        done < "$SCORES_FILE"
    done
    echo ""
    echo "${YELLOW}================================${RESET}"
    echo ""
}

play_game() {
    local PLAYER_NAME=$1

    echo ""
    echo "Select difficulty:"
    echo "  1) Easy   (1 - 50)"
    echo "  2) Medium (1 - 100)"
    echo "  3) Hard   (1 - 200)"
    echo ""

    local DIFFICULTY MAX_NUM
    while true; do
        echo -n "Enter choice [1-3]: "
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

    echo ""
    echo "================================"
    echo "  Difficulty: $DIFFICULTY (1 - $MAX_NUM)"
    echo "  You have $MAX_GUESSES guesses."
    echo "================================"
    echo ""

    while [[ $guesses -lt $MAX_GUESSES ]]; do
        local remaining=$(( MAX_GUESSES - guesses ))
        echo -n "[$DIFFICULTY] Guess ($remaining left): "
        if ! read -r guess; then echo ""; break; fi

        if ! [[ $guess =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid number."
            echo ""
            continue
        fi

        (( guesses++ ))
        remaining=$(( MAX_GUESSES - guesses ))

        if [[ $guess -lt $SECRET ]]; then
            echo "${BLUE}Too low! Try higher.${RESET}"
        elif [[ $guess -gt $SECRET ]]; then
            echo "${RED}Too high! Try lower.${RESET}"
        else
            echo ""
            echo "${GREEN}*** YOU WIN! ***${RESET}"
            echo "${GREEN}Well done, $PLAYER_NAME! You guessed $SECRET in $guesses guess(es)! [$DIFFICULTY]${RESET}"
            echo "${GREEN}Rating: $(get_stars "$guesses")${RESET}"
            save_score "$PLAYER_NAME" "$DIFFICULTY" "$guesses"
            show_leaderboard
            return
        fi
        echo "${DIM}  $remaining guess(es) remaining.${RESET}"
        echo ""
    done

    echo ""
    echo "*** GAME OVER ***"
    echo "Hard luck, $PLAYER_NAME! The number was $SECRET."
    echo "Rating: ☆☆☆☆☆ (0/5)"
    show_leaderboard
}

# ── Main ──────────────────────────────────────────────────────────────────────

echo "================================"
echo "  NUMBER GUESSING GAME"
echo "================================"
echo ""
echo -n "Enter your name: "
read -r PLAYER_NAME || true
PLAYER_NAME="${PLAYER_NAME//[[:space:]]/}"
PLAYER_NAME="${PLAYER_NAME:-Player}"

while true; do
    echo ""
    echo "--------------------------------"
    echo "  Hello, $PLAYER_NAME!"
    echo "  1) Play game"
    echo "  2) View leaderboard"
    echo "  3) Quit"
    echo "--------------------------------"
    echo -n "Choice [1-3]: "
    if ! read -r choice; then echo ""; break; fi
    case $choice in
        1) play_game "$PLAYER_NAME" ;;
        2) show_leaderboard ;;
        3) echo "Goodbye, $PLAYER_NAME!"; break ;;
        *) echo "Please enter 1, 2, or 3." ;;
    esac
done
