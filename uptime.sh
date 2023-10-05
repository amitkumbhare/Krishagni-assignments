#!/bin/bash 

# Defining variable.
website=("http://amit.com/" "https://www.google.com" "www.facebox.com" "http://amit.com/" "http://zoro.to" "netflix.com")
n_email="amit0linux@gmail.com"
e_subject="Website is down."

# creating a function which send an email with subject, body and recipient.
send_notification() {
	subject="$e_subject: $1"
	body="The website $1 is not working. Please check why $2 Error occurs."
	recipient="amit0linux@gmail.com"

	echo -e "Subject:$subject\n$body" | sendmail "$recipient"
}

# creating an associating array using declare comamnd with -A option
declare -A check_constantly

# Variable 
max_failure=5

# creating a for loop to check uptime of website.
for website in "${website[@]}";
do
	check_constantly["$website"]=0
	while true;
	do
		http_code=$(curl -s -o /dev/null -w "%{http_code}" "$website")
		if [ "$http_code" != "200" ]; then
			check_constantly["$website"]=$((check_constantly["$website"] + 1))

			if [ ${check_constantly["$website"]} -ge $max_failure ]; then
				send_notification "$website" "$http_code"
				break
			fi
			# Sleep for 10 min.
			sleep 300
		else
			check_constantly["$website"]=0
		fi
	done
done
