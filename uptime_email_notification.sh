#!/bin/bash

# Defining variable.
websites=("facebook.com" "zoro.to" "amit.in" "anaya.com")
e_subject="Website is down."
gmax_count=0
max_email=5

# Number of consecutive failures before sending email notifications.
max_failures=5

# Initialize an associative array to keep track of consecutive failures for each website.
declare -A failures

declare -A emails_sent

# creating a function which send an email with subject, body and recipient.
send_notification() {
        subject="$e_subject: $1"
        body="The website $1 is not working. Please check why $2 Error occurs."
        recipient="amitOlinux@gmail.com"

        echo -e "Subject:$subject\n$body" | sendmail "$recipient"
}

while true; do
    # Initialize the local email max count for email.
    lmax_count=0

    for website in "${websites[@]}"; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$website")

        # If the website is down (HTTP status code is not 200 OK)
        if [ "$http_code" != "301" ] && [ "$http_code" != "200"  ]; then

            # Increment the failure count for this website
            failures["$website"]=$((failures["$website"] + 1))

	    if [ ${emails_sent["$website"]:-0} -le "$max_email" ]; then
                    send_notification "$website" "$http_code"
                    emails_sent["$website"]=$((emails_sent["$website"] + 1))
            fi

            # If the failure count reaches the maximum allowed failures, send a notification
            if [ ${failures["$website"]:-0} -ge "$max_failures" ]; then
                # Reset the failure count for this website
                failures["$website"]=0
            fi
        else

            # If the website is up, reset the failure count for this website
            failures["$website"]=0
        fi

	# Check if 'emails_sent' has reached the max count then exit.
	if [ ${emails_sent["$website"]:-0} -gt "$lmax_count" ]; then
		lmax_count=${emails_sent["$website"]}
	fi
    done

    # Check if 'emails_sent' has reached the max count then exit.
    if [ "$lmax_count" -gt "$gmax_count" ]; then
	    gmax_count=$lmax_count
    fi

    #Check if the global maximum email count has reached the desired count
    if [ "$gmax_count" -ge "$max_email" ]; then
	    echo "Sent $gmax_count emails (greater than or equal to $max_email). Exiting the loop"
	    exit 0
    fi

    # Sleep for 10 minutes before rechecking the websites
    sleep 600
done
