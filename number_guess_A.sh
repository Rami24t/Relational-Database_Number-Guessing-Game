#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c";

# Function to generate a random number between $1 and $2
GENERATE_RANDOM_NUMBER() {
    echo $(($1 + RANDOM % $2))
}

# Function to check if a username exists in the database
USERNAME_EXISTS() {
    local USERNAME="$1"
    local EXISTS=$($PSQL "SELECT EXISTS (SELECT 1 FROM users WHERE USERNAME='$USERNAME')")
    if [[ $EXISTS == "t" ]]; then
        # Username exists
        return 0
    else
        # Username does not exist
        return 1
    fi
}


function LOGIN() {
    # Fetch user from database
    local USER="$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$1'")"
    local DB_USERNAME DB_GAMES_PLAYED DB_BEST_GAME
    IFS='|' read DB_USERNAME DB_GAMES_PLAYED DB_BEST_GAME <<< $USER

    # Check if username already exists    
        if [[ -z $DB_USERNAME ]]
        then
            # That username has not been used before
            # Echo the proper welcome message
            echo "Welcome, $1! It looks like this is your first time here."
            local DB_USERNAME=$1
            return 0
        else
            # That username has been used before
            # Update games_played
            local UPDATE_GAMES_RESULT="$($PSQL "UPDATE users SET games_played=(games_played + 1) WHERE username='$DB_USERNAME'")"
            # Echo the proper welcome message
            echo "Welcome back, $DB_USERNAME! You have played $(($DB_GAMES_PLAYED+1)) games, and your best game took $DB_BEST_GAME guesses."
            return 1
        fi
        return 99
}


function PLAYGAME() {
    
    GUESSED=0
    
    echo -e "Guess the secret number between 1 and 1000:"
    
    while [[ $GUESSED -eq 0 ]] && read INPUT
    do
        if [[ ! "$INPUT" =~ ^[0-9]+$ ]]
        then
            echo -e "That is not an integer, guess again:"
        else
            
            NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES+1))
            
            if [[ $SECRET_NUMBER -gt $INPUT ]]
            then
                echo -e "It's higher than that, guess again:"
            elif [[ $SECRET_NUMBER -lt $INPUT ]]
            then
                echo -e "It's lower than that, guess again:"
            elif [[ $INPUT -eq $SECRET_NUMBER ]]
            then
                GUESSED=1
            fi
        fi
    done
    
}

function MAIN() {
    
    # randomly generate a number between 1 and 1000 that the users have to guess
    SECRET_NUMBER=$(GENERATE_RANDOM_NUMBER 1 1000)
    
    # Prompt the user for a username with Enter your username and take a username as input.
    echo -e "Enter your username:";
    read USERNAME_INPUT
    # PS: The database allows usernames that are upto 22 characters long

    IS_NEW_USER=$(USERNAME_EXISTS "$USERNAME")
    echo $(LOGIN $USERNAME_INPUT)

    NUMBER_OF_GUESSES=0
    
    PLAYGAME
    
    if $IS_NEW_USER
    then
        INSERT_USER_RESULT="$($PSQL "INSERT INTO users(username) VALUES('$USERNAME_INPUT')")"
    fi
    SAVE_RESULT="$($PSQL "UPDATE users SET best_game=CASE WHEN best_game>$NUMBER_OF_GUESSES THEN $NUMBER_OF_GUESSES ELSE best_game END WHERE username='$USERNAME_INPUT'")"
    #    echo $SAVE_RESULT
    echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job! "
    
}

MAIN
