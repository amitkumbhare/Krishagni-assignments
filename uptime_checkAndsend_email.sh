#!/bin/bash

# Defining variable.
websites=("facebook.com" "zoro.to" "https://akabit.framer.ai/" )
e_subject="Website is down."
max_email=5

# Number of consecutive failures before sending email notifications.
max_failures=5

# Initialize an associative array to keep track of consecutive "failures" and "emails sent" for each website.
declare -A failures

declare -A emails_sent

# creating a function which send an email with subject, body and recipient.
send_notification() {
        subject="$e_subject: $1"
        body="The website $1 is not working. Please check why $2 Error occurs."
        recipient="asta0linux@gmail.com"

        echo -e "Subject:$subject\n$body" | sendmail "$recipient"
}

while true; do
    # Initialize the local email max count for email.
    lmax_count=0
    # Set flag to track whether all websites have reached the "max_email" count in each iteration.
    all_website_reach_max_email=true
    for website in "${websites[@]}"; do
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$website")

        # If the website is down (HTTP status code is not 200 OK)
        if [ "$http_code" != "301" ] && [ "$http_code" != "200"  ]; then
		echo "$website is not up and giving $http_code"

		# Increment the failure count for this website
		failures["$website"]=$((failures["$website"] + 1))

		# If the failure count reaches the maximum allowed failures, send a notification
		if [ ${failures["$website"]:-0} -le "$max_failures" ]; then

		    # Send Email notification.
		    if [ ${emails_sent["$website"]:-0} -lt "$max_email" ]; then
                    send_notification "$website" "$http_code"
                    emails_sent["$website"]=$((emails_sent["$website"] + 1))
		    fi
		fi
  		# Check if the website reach the max_email count. 
		if [ ${emails_sent["$website"]:-0} -lt "$max_email" ]; then
		    all_website_reach_max_email=false
		fi
	else
		echo "$webiste is up with $2 code."
		if [ ${failures["$website"]:-0} -gt 0 ]; then
			echo "The Website $website was down before, but it came back online at `date`."
			# Reset the failure and email count for this website.
			failures["$website"]=0
			emails_sent["$website"]=0
			echo "Reset the value of $failure["$webiste"] and $emails_sent["$website"] to zero."
		fi
	fi
    done

    # Check if all websites have reached the max_email count for this iteration
    if $all_website_reach_max_email; then
	    echo "All website has reached the email count of $max_email. Exiting the loop."
	    exit 0
    fi

    # Sleep for 10 minutes before rechecking the websites
    sleep 600
done
