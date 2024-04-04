#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Function to generate a random number between $1 and $2
GENERATE_RANDOM_NUMBER() {
    echo $(($1 + RANDOM % $2))
}

# Function to check if a username exists in the database
USERNAME_EXISTS() {
    local USERNAME=$1
    local EXISTS
    EXISTS=$($PSQL "SELECT EXISTS (SELECT 1 FROM users WHERE USERNAME='$USERNAME')")
    if [[ "$EXISTS" == "t" ]]; then
        return 1
        # Username exists
    else
        return 0
        # Username does not exist
    fi
}

# function to "login" a saved user
function LOGIN() {
    # Retrieve user's info (from database)
    local USERNAME=$1
    local USER
    USER="$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$1'")"
    local DB_USERNAME DB_GAMES_PLAYED DB_BEST_GAME
    IFS='|' read -r DB_USERNAME DB_GAMES_PLAYED DB_BEST_GAME <<<"$USER"
    # Update user's info(games_played)
    local UPDATE_USER_RESULT
    UPDATE_USER_RESULT="$($PSQL "UPDATE users SET games_played=(games_played + 1) WHERE username='$DB_USERNAME'")"
    # Echo the proper welcome message
    # print the welcome back message showing the total number of played games
    # and the best game i.e the fewest number of guesses it took to win a game
    echo "Welcome back, $DB_USERNAME! You have played $((DB_GAMES_PLAYED + 1)) games, and your best game took $DB_BEST_GAME guesses."
}

# Function to (print the) welcome (message for) new users
PRINT_FIRST_WELCOME() {
    local USERNAME=$1
    echo "Welcome, $USERNAME! It looks like this is your first time here."
}

# function to play the main guessing game
function PLAYGAME() {
    local SECRET=$1
    local GUESSED=0
    local ATTEMPTS=0
    echo -e "Guess the secret number between 1 and 1000:"
    local INPUT
    # loops while updating the global variables appropriately
    # exits only if the user has guessed the secret
    while [[ $GUESSED -eq 0 ]] && read -r INPUT; do
        if [[ ! "$INPUT" =~ ^[0-9]+$ ]]; then
            echo -e "That is not an integer, guess again:"
        else
            ATTEMPTS=$((ATTEMPTS + 1))
            if [[ $SECRET -gt $INPUT ]]; then
                echo -e "It's higher than that, guess again:"
            elif [[ $SECRET -lt $INPUT ]]; then
                echo -e "It's lower than that, guess again:"
            elif [[ $INPUT -eq $SECRET ]]; then
                GUESSED=1
                return $ATTEMPTS
            fi
        fi
    done
}

# Function to save game results to database
SAVE_GAME_RESULTS() {
    local IS_NEW_USER=$1
    local USERNAME_INPUT=$2
    local NUMBER_OF_GUESSES=$3
    if [[ $IS_NEW_USER -eq 1 ]]; then
        local INSERT_RESULT
        INSERT_RESULT="$($PSQL "INSERT INTO users(username) VALUES('$USERNAME_INPUT')")"
    fi
    local UPDATE_RESULT
    UPDATE_RESULT="$($PSQL "UPDATE users SET best_game=CASE WHEN best_game>$NUMBER_OF_GUESSES THEN $NUMBER_OF_GUESSES ELSE best_game END WHERE username='$USERNAME_INPUT'")"
}

# Function to print the game result
PRINT_GAME_RESULTS() {
    local NUMBER_OF_GUESSES
    NUMBER_OF_GUESSES=$1
    local SECRET_NUMBER=$2
    echo "You guessed it in $1 tries. The secret number was $2. Nice job!"
}

function MAIN() {
    # randomly generate a number between 1 and 1000 that the users have to guess
    local SECRET_NUMBER
    SECRET_NUMBER=$(GENERATE_RANDOM_NUMBER 1 1000)

    # Prompt the user for a username with Enter your username and take a username as input.
    echo -e "Enter your username:"
    local USERNAME_INPUT
    read -r USERNAME_INPUT
    # PS: The database allows usernames up to 40 characters long.

    # Check if the username has been used before
    USERNAME_EXISTS "$USERNAME_INPUT"
    # USERNAME_EXISTS returns 0 if the username has NOT been used before (i.e. new user)
    IS_NEW_USER=$(($? == 0))

    # Note: In bash 1 is true and 0 is false
    if [[ $IS_NEW_USER -eq 1 ]]; then
        # That username has not been used before
        # If new username
        # Print new user/username welcome message
        PRINT_FIRST_WELCOME "$USERNAME_INPUT"
    else
        # If username has been used before
        # Login user & echo the proper welcome message
        LOGIN "$USERNAME_INPUT"
    fi

    # declare and initialize the number of guesses as a local variable
    local NUMBER_OF_GUESSES=0
    # play the main number-guessing game (and update the number of guesses)
    PLAYGAME "$SECRET_NUMBER"
    NUMBER_OF_GUESSES=$?

    # user has guessed the secret number

    # save game results to database
    SAVE_GAME_RESULTS "$IS_NEW_USER" "$USERNAME_INPUT" "$NUMBER_OF_GUESSES"

    # print goodbye/outro message
    PRINT_GAME_RESULTS "$NUMBER_OF_GUESSES" "$SECRET_NUMBER"
}

# Run the main function
MAIN
