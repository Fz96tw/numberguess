#!/usr/bin/env bash

if [[ -t 1 ]] && tput colors &>/dev/null && [[ $(tput colors) -ge 8 ]]; then
    RED=$(tput setaf 1)
    BLUE=$(tput setaf 4)
    GREEN=$(tput setaf 2)
    DIM=$(tput dim 2>/dev/null || true)
    RESET=$(tput sgr0)
else
    RED=""; BLUE=""; GREEN=""; DIM=""; RESET=""
fi

MAX_GUESSES=10

get_stars() {
    local n=$1
    local count
    if   [[ $n -le 2 ]]; then count=5
    elif [[ $n -le 4 ]]; then count=4
    elif [[ $n -le 6 ]]; then count=3
    elif [[ $n -le 8 ]]; then count=2
    else                       count=1
    fi
    local filled="" empty=""
    local i
    for (( i=0; i<count; i++ ));      do filled+="★"; done
    for (( i=count; i<5; i++ ));      do empty+="☆";  done
    echo "$filled$empty ($count/5)"
}

echo "================================"
echo "  NUMBER GUESSING GAME"
echo "================================"
echo ""
echo -n "Enter your name: "
read -r PLAYER_NAME || true
PLAYER_NAME="${PLAYER_NAME//[[:space:]]/}"
PLAYER_NAME="${PLAYER_NAME:-Player}"
echo ""

echo "Select difficulty:"
echo "  1) Easy   (1 - 50)"
echo "  2) Medium (1 - 100)"
echo "  3) Hard   (1 - 200)"
echo ""

while true; do
    echo -n "Enter choice [1-3]: "
    if ! read -r choice; then
        echo ""
        exit 1
    fi
    case $choice in
        1) DIFFICULTY="Easy";   MAX_NUM=50;  break ;;
        2) DIFFICULTY="Medium"; MAX_NUM=100; break ;;
        3) DIFFICULTY="Hard";   MAX_NUM=200; break ;;
        *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
    esac
done

SECRET=$(( RANDOM % MAX_NUM + 1 ))
guesses=0

echo ""
echo "================================"
echo "  Difficulty: $DIFFICULTY (1 - $MAX_NUM)"
echo "  You have $MAX_GUESSES guesses."
echo "================================"
echo ""

while [[ $guesses -lt $MAX_GUESSES ]]; do
    remaining=$(( MAX_GUESSES - guesses ))
    echo -n "[$DIFFICULTY] Guess ($remaining left): "
    if ! read -r guess; then
        echo ""
        break
    fi

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
        exit 0
    fi
    echo "${DIM}  $remaining guess(es) remaining.${RESET}"
    echo ""
done

echo ""
echo "*** GAME OVER ***"
echo "Hard luck, $PLAYER_NAME! The number was $SECRET."
echo "Rating: ☆☆☆☆☆ (0/5)"
