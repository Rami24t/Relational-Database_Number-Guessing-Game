#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c";

function MAIN {

# randomly generate a number that users have to guess
 RANDOM_NUMBER=$((1 + $RANDOM % 1000));
# echo $RANDOM_NUMBER;

echo -e "Enter your username:";
read USERNAME_INPUT

LOGIN_RES=$(LOGIN $USERNAME_INPUT)

echo -e "$LOGIN_RES" | {
read -r MSG; 
read -r USERNAME; 
echo -e "$MSG"
GAME_RES=$(PLAYGAME "username $USERNAME")
}

}

function LOGIN {
USER="$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME_INPUT'")"
echo $USER | while IFS='|' read USERNAME GAMES_PLAYED BEST_GAME
do

if [[ -z $USERNAME ]]
then
INSERT_USER_RESULT="$($PSQL "INSERT INTO users(username) VALUES('$1')")"
echo -e "Welcome, $1! It looks like this is your first time here."
else
echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
NEW_GAME_RESULT="$($PSQL "UPDATE users SET games_played=(games_played + 1) WHERE username='$USERNAME'")"
fi
echo -e "$USERNAME"
done
# return 0
}

function PLAYGAME {
echo -e "$1"
GUESSED=0
echo -e "Guess the secret number between 1 and 1000:"
while [[ $GUESSED -eq 0 ]] && read INPUT
do

if [[ $RANDOM_NUMBER -gt $INPUT ]]
then 
echo -e "gt"
else

echo -e "lte"

if [[ $INPUT -eq $RANDOM_NUMBER ]]
then
GUESSED=1
fi

fi

done

}

MAIN
