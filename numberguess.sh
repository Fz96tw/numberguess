#!/usr/bin/env bash

MAX_GUESSES=10

echo "================================"
echo "  NUMBER GUESSING GAME"
echo "================================"
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

    if [[ $guess -lt $SECRET ]]; then
        echo "Too low! Try higher."
    elif [[ $guess -gt $SECRET ]]; then
        echo "Too high! Try lower."
    else
        echo ""
        echo "*** YOU WIN! ***"
        echo "You guessed $SECRET correctly in $guesses guess(es)! [$DIFFICULTY]"
        exit 0
    fi
    echo ""
done

echo ""
echo "*** GAME OVER ***"
echo "Out of guesses! The number was $SECRET."
