#!/bin/bash 

# Defining variable.
website=("https://www.google.com" "www.facebox.com" "http://amit.com/" "http://zoro.to" "netflix.com")
n_email="asta0linux@gmail.com"
e_subject="Website is down."

# creating a function which send an email with subject, body and recipient.
send_notification() {
        subject="$e_subject: $1"
        body="The website $1 is not working. Please check why $2 Error occurs."
        recipient="asta0linux@gmail.com"

        echo -e "Subject:$subject\n$body" | sendmail "$recipient"
}


# creating a for loop to check uptime of website.
for website in "${website[@]}"
do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$website")
        if [ "$http_code" != "200" ]; then
                send_notification "$website" "$http_code"
        fi
done
