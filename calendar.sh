#!/bin/bash

logged_in="False"
logged_in_user=""

# account creation
function create() {
	printf "\n*** Acount Creation ***\n"
  
  	touch -a ./users
	correct_username="False"
	read -p "Enter username: " username
	while [ $correct_username == "False" ]; do
		if grep -E "^username:$username$" users; then
			read -p "Username already taken, please try again: " username
		else
			correct_username="True"
		fi	
	done

	correct_password="False"
	read -s -p "Enter password: " password
	while [ $correct_password == "False" ]; do
		if [[ $password =~ ^(.{0,7}|[^0-9]*|[^A-Z]*|[^a-z]*)$ ]]; then
			echo -e "\n"
			read -s -p "Password must be at least 8 characters long and contain a number, an uppercase letter, and a lowercase letter: " password
		else
			correct_password="True"
		fi
	done
	echo "username:$username" >> users
	echo "password:$password" >> users
	logged_in="True"
	logged_in_user=$username
	logged_in_main	
}

# account login
function login() {
  printf "\n*** Account Login ***\n" 

  read -p "Enter username: " username
  read -s -p "Enter password: " password
  password_compare=$(grep -A1 --no-group-separator -iE "^username:$username$" users | grep -v "^username:") 
  if [ $? -eq 0 ] && [[ $password_compare =~ ^password:$password$ ]]; then
	logged_in="True"
	logged_in_user=$username
	printf "\nSuccessfully logged in as $logged_in_user."
	logged_in_main
  else
	  echo -e "\nFailed to login, incorrect username or password"
  fi
}

# search database
function search() {
  printf "\n*** Search Calendar ***\n"
  printf "To search your calendar by event name and date, enter \"<event name>,<date>\".\n"
  printf "To search the database by event name or date alone, use the * in place of a search term.\n"
  printf "For example, \"*,05/15/2023\" will find all events on that date.\n"
  printf "Hit <Enter> to return to the main menu.\n\n" 

  printf "What events would you like to find? "
  read input
  while [ ! -z "$input" ]; do
	  event_name=$(echo $input | sed -r "s/(.*),.*/\1/") 
	  date=$(echo $input | sed -r "s/.*,(.*)/\1/")
	  if [[ $event_name == "*" ]] && [[ $date == "*" ]]; then
		  grep -iE "^user: $logged_in_user, .*" cal_db | sed -r "s/^user: $logged_in_user, (.*)/\1/"
	  elif [[ $event_name == "*" ]]; then
		  grep -iE "^user: $logged_in_user, .*, date: $date.*" cal_db | sed -r "s/^user: $logged_in_user, (.*)/\1/"
	  elif [[ $date == "*" ]]; then
		  grep -iE "^user: $logged_in_user, event: $event_name.*" cal_db | sed -r "s/^user: $logged_in_user, (.*)/\1/"
	  else 
		  grep -iE "^user: $logged_in_user, event: $event_name, date: $date, .*" cal_db | sed -r "s/^user: $logged_in_user, (.*)/\1/"
	  fi
	printf "\nWhat events would you like to find? "
	read input
  done
}

function add_to_cal() {

  printf "\n*** Add to calendar **\n"
  read -p "Enter the name of the event: " event_name
  read -p "Enter the date of the event (format: 05/15/23): " date
  read -p "Optionally, enter the time of the event (format: 2:00pm): " time
  read -p "Optionally, enter any flags to create repeated events (seperated by a space). -d for daily, -w for weekly, -m for monthly, -y for yearly: " -a flags

  repeat=0

  for flag in "${flags[@]}"; do
	if [[ $flag == "-d" ]]; then
		repeat=4
	elif [[ $flag == "-w" ]] && [[ repeat -lt 3 ]]; then
		repeat=3
	elif [[ $flag == "-m" ]] && [[ repeat -lt 2 ]]; then
		repeat=2
	elif [[ $flag == "-y" ]] && [[ repeat -lt 1 ]]; then
                repeat=1
	fi
  done

  if [[ repeat -gt 0 ]]; then
	  read -p "How long would you like to repeat this event until (format: 05/15/23). Please ensure that the entered date is after the original event date: " go_until
  fi

  go_until_date=$(date +%Y%m%d -d "$go_until")

  if [[ repeat -eq 0 ]]; then
	  echo "user: $logged_in_user, event: $event_name, date: $date, time: $time" >> cal_db
  elif [[ repeat -eq 1 ]]; then
	  next_date=$(date +%Y%m%d -d "$date") 
	  while [ $next_date -le $go_until_date ]; do	
		nd_form=$(date +%m/%d/%y -d "$next_date")
		echo "user: $logged_in_user, event: $event_name, date: $nd_form, time: $time" >> cal_db
		next_date=$(date +%Y%m%d -d "$next_date + 1 year")	
	  done 
  elif [[ repeat -eq 2 ]]; then
          next_date=$(date +%Y%m%d -d "$date")
          while [[ $next_date -le $go_until_date ]]; do
                nd_form=$(date +%m/%d/%y -d "$next_date")
                echo "user: $logged_in_user, event: $event_name, date: $nd_form, time: $time" >> cal_db
                next_date=$(date +%Y%m%d -d "$next_date + 1 month") 
          done
  elif [[ repeat -eq 3 ]]; then
          next_date=$(date +%Y%m%d -d "$date")
          while [[ $next_date -le $go_until_date ]]; do
                nd_form=$(date +%m/%d/%y -d "$next_date")
                echo "user: $logged_in_user, event: $event_name, date: $nd_form, time: $time" >> cal_db
                next_date=$(date +%Y%m%d -d "$next_date + 1 week")
          done
  elif [[ repeat -eq 4 ]]; then
          next_date=$(date +%Y%m%d -d "$date")
          while [[ $next_date -le $go_until_date ]]; do
                nd_form=$(date +%m/%d/%y -d "$next_date")
                echo "user: $logged_in_user, event: $event_name, date: $nd_form, time: $time" >> cal_db
                next_date=$(date +%Y%m%d -d "$next_date + 1 day")
          done
  fi
}

function upcoming_events() {
  printf "\n*** Upcoming events **\n"
  printf "\n*** Here are your events for the next week! **\n"
  for i in {0..7}; do
	date_form=$(date +%m/%d/%y -d "$DATE + $i day")
  	grep -iE "date: $date_form, " cal_db | sed -r "s/^user: $logged_in_user, (.*)/\1/"
  done
}

function delete_events() {
  printf "\n*** Delete Events ***\n"
  printf "To delete events from your calendar by event name and date, enter \"<event name>,<date>\".\n"
  printf "To delete from the database by event name or date alone, use the * in place of a search term.\n"
  printf "For example, \"*,05/15/2023\" will delete all events on that date.\n"
  printf "Hit <Enter> to return to the main menu.\n\n"

  printf "What events would you like to delete? "
  read input
  while [ ! -z "$input" ]; do
          event_name=$(echo $input | sed -r "s/(.*),.*/\1/")
          date=$(echo $input | sed -r "s/.*,(.*)/\1/")
          if [[ $event_name == "*" ]] && [[ $date == "*" ]]; then
                  sed -i -r "s|^user: $logged_in_user, .*||i" cal_db
          elif [[ $event_name == "*" ]]; then
                  sed -i -r "s|^user: $logged_in_user, .*, date: $date, .*||i" cal_db 
          elif [[ $date == "*" ]]; then
                  sed -i -r "s|^user: $logged_in_user, event: $event_name, .*||i" cal_db 
 	  else
                  sed -i -r "s|^user: $logged_in_user, event: $event_name, date: $date, .*||i" cal_db 
          fi
        printf "\nWhat events would you like to delete? "
        read input
  done
  sed -ir "/^$/d" cal_db
}
 
# not logged in main menu
function non_login_main() {
  printf "Welcome to the linux calendar program! What would you like to do?\n"
  printf "\t[1] Create account\n\t[2] Login\n\t[<Enter> or CTRL+D] Quit\n"
  read option
  while [ ! -z "$option" ]; do
    case "$option" in
      1)
        create 
        ;;
      2)
        login
        ;;
      *)
        printf "Invalid option.\n"
        ;;
    esac
    if [ $logged_in == "True" ]; then
	    return
	fi
    printf "\nWelcome to the linux calendar program! What would you like to do?\n"
    printf "\t[1] Create account\n\t[2] Login\n\t[<Enter> or CTRL+D] Quit\n"
    read option
  done
  printf "Shutting down...\n"
  exit 0
}

# logged in main menu
function logged_in_main() {
  printf "\nWelcome to the linux calendar program! You are logged in as $logged_in_user. What would you like to do?\n"
  cal -y
  printf "\t[1] Search calendar\n\t[2] Add to calendar\n\t[3] Upcoming events\n\t[4] Delete events\n\t[<Enter> or CTRL+D] Quit\n"
  read option
  while [ ! -z "$option" ]; do
    case "$option" in
      1) 
	search
        ;;
      2) 
	add_to_cal
        ;;
      3)
        upcoming_events
        ;;
      4) 
	delete_events
	;;
      *)
        printf "Invalid option.\n"
        ;;
    esac
    printf "\nWelcome to the linux calendar program! You are logged in as $logged_in_user. What would you like to do?\n"
    printf "\t[1] Search calendar\n\t[2] Add to calendar\n\t[3] Upcoming events\n\t[4] Delete events\n\t[<Enter> or CTRL+D] Quit\n" 
    read option
  done
  printf "Shutting down...\n"
  exit 0
}

non_login_main
