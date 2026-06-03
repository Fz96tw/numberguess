#!/usr/bin/env bash

MAX_GUESSES=10
SECRET=$(( RANDOM % 100 + 1 ))
guesses=0

echo "================================"
echo "  NUMBER GUESSING GAME"
echo "  Guess a number between 1 and 100"
echo "  You have $MAX_GUESSES guesses."
echo "================================"
echo ""

while [[ $guesses -lt $MAX_GUESSES ]]; do
    remaining=$(( MAX_GUESSES - guesses ))
    echo -n "Guess ($remaining left): "
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
        echo "You guessed $SECRET correctly in $guesses guess(es)!"
        exit 0
    fi
    echo ""
done

echo ""
echo "*** GAME OVER ***"
echo "Out of guesses! The number was $SECRET."
