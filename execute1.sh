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

# Function to perform email checks
scanner() {
    read -p $'\e[1;92m[\e[0m\e[1;77m?\e[0m\e[1;92m] Input Email Address:\e[0m ' email

    # Remove previous results if exist
    if [[ -e "$email.txt" ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Removing previous file:\e[0m\e[1;77m %s.txt\n" "$email"
        rm -f "$email.txt"
    fi

    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Checking email: %s\e[0m\n" "$email"

    # Define User-Agent to mimic a real browser
    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"

    # Function to perform individual service checks
    check_service() {
        local service_name="$1"
        local url="$2"
        local success_pattern="$3"
        local failure_pattern="$4"

        printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] %s: \e[0m" "$service_name"

        # Perform the curl request, capturing both response body and HTTP status code
        response=$(curl -s -A "$user_agent" -w "HTTPSTATUS:%{http_code}" "$url")

        # Extract the body and status
        body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
        status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

        # Determine if the account exists based on patterns and status code
        if [[ "$status" == "200" ]] && [[ "$body" != *"$failure_pattern"* ]]; then
            printf "\e[1;92mFound!\e[0m %s account associated with email: %s\n" "$service_name" "$email"
            printf "%s: Found account for %s\n" "$service_name" "$email" >> "$email.txt"
        else
            printf "\e[1;93mNot Found!\e[0m\n"
        fi

        # Optional: Sleep to prevent rate limiting (adjust as needed)
        sleep 1
    }

    ### Service Checks ###

    # Facebook
    check_service "Facebook" "https://www.facebook.com/recover/initiate/?email=$email" "account found" "Sorry, we couldn’t find an account"

    # Instagram
    check_service "Instagram" "https://www.instagram.com/accounts/password/reset/?email=$email" "password reset" "Please enter a valid email address."

    # Twitter
    check_service "Twitter" "https://api.twitter.com/account/begin_password_reset.json?email=$email" "password reset sent" "email is not associated"

    # LinkedIn
    check_service "LinkedIn" "https://www.linkedin.com/uas/request-password-reset?emailAddress=$email" "reset link sent" "email does not exist"

    # Have I Been Pwned
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Have I Been Pwned: \e[0m"
    check_pwned=$(curl -s -A "$user_agent" "https://haveibeenpwned.com/unifiedsearch/$email" | grep -o 'Breaches')
    if [[ -n "$check_pwned" ]]; then
        printf "\e[1;92mFound!\e[0m Breaches associated with email: %s\n" "$email"
        printf "HIBP: Found breaches for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNo breaches found!\e[0m\n"
    fi

    # Spotify
    check_service "Spotify" "https://www.spotify.com/password-reset/?email=$email" "password reset sent" "404"

    # Tumblr
    check_service "Tumblr" "https://www.tumblr.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Etsy
    check_service "Etsy" "https://www.etsy.com/recover/initiate/?email=$email" "password reset sent" "404"

    # CashMe
    check_service "CashMe" "https://cash.me/recover/initiate/?email=$email" "password reset sent" "404"

    # Flickr
    check_service "Flickr" "https://www.flickr.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Steam
    check_service "Steam" "https://steamcommunity.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Vimeo
    check_service "Vimeo" "https://vimeo.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Scribd
    check_service "Scribd" "https://www.scribd.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Badoo
    check_service "Badoo" "https://www.badoo.com/en/recover/initiate/?email=$email" "password reset sent" "404"

    # AllMyLinks
    check_service "AllMyLinks" "https://allmylinks.com/recover/initiate/?email=$email" "password reset sent" "Not Found"

    # Apple Developer
    check_service "Apple Developer" "https://developer.apple.com/forums/profile/recover/initiate/?email=$email" "password reset sent" "404"

    # Venmo
    check_service "Venmo" "https://venmo.com/recover/initiate/?email=$email" "password reset sent" "404"

    # CashApp
    check_service "CashApp" "https://cash.app/recover/initiate/?email=$email" "password reset sent" "404"

    # PayPal
    check_service "PayPal" "https://www.paypal.me/recover/initiate/?email=$email" "password reset sent" "404"

    # Pastebin
    check_service "Pastebin" "https://pastebin.com/recover/initiate/?email=$email" "password reset sent" "404"

    # BitBucket
    check_service "BitBucket" "https://bitbucket.org/recover/initiate/?email=$email" "password reset sent" "404"

    # Patreon
    check_service "Patreon" "https://www.patreon.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Discord
    check_service "Discord" "https://discord.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Snapchat
    check_service "Snapchat" "https://www.snapchat.com/recover/initiate/?email=$email" "password reset sent" "404"

    # TikTok
    check_service "TikTok" "https://www.tiktok.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Reddit
    check_service "Reddit" "https://www.reddit.com/recover/initiate/?email=$email" "password reset sent" "404"

    # GitHub
    check_service "GitHub" "https://github.com/recover/initiate/?email=$email" "password reset sent" "404"

    # Final message
    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Scanning complete.\e[0m\n"
    partial
}

# Display banner and start scanner
banner
scanner
