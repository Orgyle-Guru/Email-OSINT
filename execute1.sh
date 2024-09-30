#!/bin/bash
# OSINT Email Finder v2.0
# Author: @Orgyle-Guru
# https://github.com/Orgyle-Guru/Email-OSINT/

# Trap SIGINT (Ctrl+C) to execute partial and exit gracefully
trap 'printf "\n"; partial; exit 1' SIGINT

# Global variable to store email
email=""

# Function to display the banner
banner() {
    printf "\e[32m   ███████╗███╗   ███╗ █████╗ ██╗██╗         ██████╗   ███████╗ ██╗███╗   ██╗████████╗ \e[0m\n"
    printf "\e[32m   ██╔════╝████╗ ████║██╔══██╗██║██║        ██║   ██║  ██╔════╝ ██║████╗  ██║╚══██╔══╝ \e[0m\n"
    printf "\e[32m   █████╗  ██╔████╔██║███████║██║██║        ██║   ██║  ███████╗ ██║██╔██╗ ██║   ██║    \e[0m\n"
    printf "\e[32m   ██╔══╝  ██║╚██╔╝██║██╔══██║██║██║        ██║   ██║  ╚════██║ ██║██║╚██╗██║   ██║    \e[0m\n"
    printf "\e[32m   ███████╗██║ ╚═╝ ██║██║  ██║██║███████╗   ╚██████╔╝  ███████║ ██║██║ ╚████║   ██║    \e[0m\n"
    printf "\e[32m   ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝    ╚═════╝   ╚══════╝ ╚═╝╚═╝  ╚═══╝   ╚═╝    \e[0m\n"
    printf "\e[1;90m ORGYLE Proactive Security Solutions \e[0m\n"
    printf "\e[1;90m Author: James Crabb, CTO \e[0m\n"
}

# Function to display partial results
partial() {
    if [[ -e "$email.txt" ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m %s.txt\n" "$email"
    else
        printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] No accounts found for %s.\e[0m\n" "$email"
    fi
}

# Function to perform individual service checks
check_service() {
    local service_name="$1"
    local url="$2"
    local success_pattern="$3"
    local failure_pattern="$4"
    local sleep_time="$5"

    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] %s: \e[0m" "$service_name"

    # Perform the curl request, capturing both response body and HTTP status code
    response=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -w "HTTPSTATUS:%{http_code}" "$url")

    # Extract the body and status
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    # Determine if the account exists based on patterns and status code
    if [[ "$status" == "200" ]]; then
        if [[ "$body" == *"$failure_pattern"* ]]; then
            printf "\e[1;93mNot Found!\e[0m\n"
        else
            printf "\e[1;92mFound!\e[0m %s account associated with email: %s\n" "$service_name" "$email"
            printf "%s: Found account for %s\n" "$service_name" "$email" >> "$email.txt"
        fi
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    # Optional: Sleep to prevent rate limiting (default 1 second if not specified)
    sleep "${sleep_time:-1}"
}

# Function to perform email checks
scanner() {
    read -p $'\e[1;92m[\e[0m\e[1;77m?\e[0m\e[1;92m] Input Email Address:\e[0m ' email

    # Validate email format
    if ! [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        printf "\e[1;93mInvalid email format. Please try again.\e[0m\n"
        scanner
        return
    fi

    # Remove previous results if exist
    if [[ -e "$email.txt" ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Removing previous file:\e[0m\e[1;77m %s.txt\n" "$email"
        rm -f "$email.txt"
    fi

    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Checking email: %s\e[0m\n" "$email"

    # Define services with their respective URLs and patterns
    declare -A services=(
        # Top 20 Dating Sites
        ["Tinder"]="https://www.tinder.com/recover/initiate/?email=$email|password reset sent|Sorry, we couldn’t find an account|1"
        ["Bumble"]="https://bumble.com/reset-password?email=$email|password reset sent|No account found|1"
        ["OkCupid"]="https://www.okcupid.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Match.com"]="https://www.match.com/reset_password?email=$email|password reset sent|No account found|1"
        ["eHarmony"]="https://www.eharmony.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Plenty of Fish"]="https://www.pof.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Hinge"]="https://hinge.co/reset_password?email=$email|password reset sent|No account found|1"
        ["Zoosk"]="https://www.zoosk.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Elite Singles"]="https://www.elitesingles.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Christian Mingle"]="https://www.christianmingle.com/reset_password?email=$email|password reset sent|No account found|1"
        ["JDate"]="https://www.jdate.com/reset_password?email=$email|password reset sent|No account found|1"
        ["OurTime"]="https://www.ourtime.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Coffee Meets Bagel"]="https://coffeemeetsbagel.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Happn"]="https://www.happn.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Grindr"]="https://www.grindr.com/reset_password?email=$email|password reset sent|No account found|1"
        ["HER"]="https://www.weareher.com/reset_password?email=$email|password reset sent|No account found|1"
        ["Raya"]="https://raya.co/reset_password?email=$email|password reset sent|No account found|1"
        ["The League"]="https://www.theleague.com/reset_password?email=$email|password reset sent|No account found|1"
        ["SilverSingles"]="https://www.silversingles.com/reset_password?email=$email|password reset sent|No account found|1"
        ["BlackPeopleMeet"]="https://www.blackpeoplemeet.com/reset_password?email=$email|password reset sent|No account found|1"

        # Other Frequently Used Sites
        ["Facebook"]="https://www.facebook.com/recover/initiate/?email=$email|password reset sent|Sorry, we couldn’t find an account|1"
        ["Instagram"]="https://www.instagram.com/accounts/password/reset/?email=$email|password reset sent|Please enter a valid email address.|1"
        ["Twitter"]="https://api.twitter.com/account/begin_password_reset.json?email=$email|password reset sent|email is not associated|1"
        ["LinkedIn"]="https://www.linkedin.com/uas/request-password-reset?emailAddress=$email|reset link sent|email does not exist|1"
        ["Google"]="https://accounts.google.com/signin/recovery?email=$email|password reset sent|Couldn't find your Google Account|1"
        ["Microsoft"]="https://account.live.com/ResetPassword.aspx?mkt=en-US&email=$email|We have sent a code|We couldn't find an account|1"
        ["Apple"]="https://iforgot.apple.com/password/verify/appleid?appleid=$email|We’ve emailed you|We can’t find an Apple ID|1"
        ["Amazon"]="https://www.amazon.com/ap/forgotpassword?email=$email|We have emailed you|There is no account|1"
        ["Reddit"]="https://www.reddit.com/recover/initiate/?email=$email|reset link sent|account not found|1"
        ["Pinterest"]="https://www.pinterest.com/password_reset/?email=$email|password reset sent|email not found|1"
        ["Quora"]="https://www.quora.com/password_reset|password reset sent|No account found|1"
        ["Slack"]="https://slack.com/forgot-password?email=$email|password reset sent|We couldn’t find your workspace|1"
        ["Zoom"]="https://zoom.us/signin?returnurl=https%3A%2F%2Fzoom.us%2Fforgot_password&email=$email|We have sent you a reset link|Account not found|1"
        ["Dropbox"]="https://www.dropbox.com/reset_password?email=$email|We have sent you a password reset link|No account found|1"
        ["GitHub"]="https://github.com/recover/initiate/?email=$email|password reset sent|We couldn't find your account|1"
        ["PayPal"]="https://www.paypal.com/signin/recovery?email=$email|password reset sent|Account not found|1"
        ["eBay"]="https://signin.ebay.com/ws/eBayISAPI.dll?ResetPwd&email=$email|password reset sent|We cannot find your eBay account|1"
        ["Netflix"]="https://www.netflix.com/PasswordReset|password reset email sent|We cannot find an account with that email|1"
        ["Spotify"]="https://www.spotify.com/password-reset/?email=$email|password reset sent|404|1"
        ["TikTok"]="https://www.tiktok.com/recover/initiate/?email=$email|password reset sent|404|1"
    )

    # Iterate over each service and perform the check
    for service in "${!services[@]}"; do
        IFS='|' read -r url success_pattern failure_pattern sleep_time <<< "${services[$service]}"
        check_service "$service" "$url" "$success_pattern" "$failure_pattern" "$sleep_time"
    done

    ### Have I Been Pwned Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Have I Been Pwned: \e[0m"
    # HIBP requires specific headers and may have API restrictions
    response_pwned=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "https://haveibeenpwned.com/unifiedsearch/$email")
    if [[ "$response_pwned" == *"Breaches"* ]]; then
        printf "\e[1;92mFound!\e[0m Breaches associated with email: %s\n" "$email"
        printf "HIBP: Found breaches for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNo breaches found!\e[0m\n"
    fi

    # Final message
    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Scanning complete.\e[0m\n"
    partial
}

# Display banner and start scanner
banner
scanner
