#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c";

# Function to generate a random number between 1 and 1000
GENERATE_RANDOM_NUMBER() {
    echo $((1 + RANDOM % 1000))
}

# Function to check if a username exists in the database
USERNAME_EXISTS() {
    local USERNAME="$1"
    local RESULT=$($PSQL "SELECT EXISTS (SELECT 1 FROM users WHERE USERNAME='$USERNAME')")
    if [[ $RESULT == "t" ]]; then
        return 0 # Username exists
    else
        return 1 # Username does not exist
    fi
}

# Function to get the total number of games played by a user
GET_TOTAL_GAMES_PLAYED() {
    local USERNAME="$1"
    local TOTAL_GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE USERNAME='$USERNAME'")
    echo $TOTAL_GAMES_PLAYED
}

# Function to get the best game of a user
GET_BEST_GAME() {
    local USERNAME="$1"
    local BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE USERNAME='$USERNAME'")
    echo $BEST_GAME
}

# Function to welcome the user
WELCOME_USER() {
    local USERNAME="$1"
    local GAMES_PLAYED=$(GET_TOTAL_GAMES_PLAYED "$USERNAME")
    local BEST_GAME=$(GET_BEST_GAME "$USERNAME")

    if USERNAME_EXISTS "$USERNAME"; then
        echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    else
        echo "Welcome, $USERNAME! It looks like this is your first time here."
    fi
}

# Main function
MAIN() {
    echo -e "Enter your username:"
    read USERNAME
    WELCOME_USER "$USERNAME"
    SECRET_NUMBER=$(GENERATE_RANDOM_NUMBER)
    NUMBER_OF_GUESSES=0

    while true; do
        echo -e "Guess the secret number between 1 and 1000:"
        read GUESS

        if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
            echo "That is not an integer, guess again:"
            continue
        fi

        ((NUMBER_OF_GUESSES++))

        if (( GUESS < SECRET_NUMBER )); then
            echo "It's higher than that, guess again:"
        elif (( GUESS > SECRET_NUMBER )); then
            echo "It's lower than that, guess again:"
        else
            echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
            # Save game stats to database
            if USERNAME_EXISTS "$USERNAME"; then
                $PSQL "UPDATE users SET best_game=CASE WHEN best_game>$NUMBER_OF_GUESSES THEN $NUMBER_OF_GUESSES ELSE best_game END WHERE username='$USERNAME'"
                $PSQL "UPDATE users SET games_played=games_played+1 WHERE username='$USERNAME'"
            else
                RESULT=$($PSQL "INSERT INTO users(username, best_game, games_played) VALUES('$USERNAME', $NUMBER_OF_GUESSES, 1)")
            fi
            break
        fi
    done
}

# Call the main function
MAIN
