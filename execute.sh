#!/bin/bash
# OSINT Email Finder v2.0
# Author: @Orgyle-Guru
# https://github.com/Orgyle-Guru/Email-OSINT/

trap 'printf "\n"; partial; exit 1' SIGINT

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

partial() {
    if [[ -e "$email.txt" ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m %s.txt\n" "$email"
    fi
}

scanner() {
    read -p $'\e[1;92m[\e[0m\e[1;77m?\e[0m\e[1;92m] Input Email Address:\e[0m ' email

    if [[ -e "$email.txt" ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Removing previous file:\e[0m\e[1;77m %s.txt\n" "$email"
        rm -rf "$email.txt"
    fi
    printf "\n"
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Checking email\e[0m\e[1;77m %s\e[0m\e[1;92m on: \e[0m\n" "$email"

    ### Facebook Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Facebook: \e[0m"
    check_facebook=$(curl -s "https://www.facebook.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o 'Sorry, we couldn’t find an account')
    if [[ -z "$check_facebook" ]]; then
        printf "\e[1;92mFound!\e[0m Facebook account associated with email: %s\n" "$email"
        printf "Facebook: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Instagram Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Instagram: \e[0m"
    check_insta=$(curl -s "https://www.instagram.com/accounts/password/reset/?email=$email" -H "Accept-Language: en" | grep -o 'Please enter a valid email address')
    if [[ -z "$check_insta" ]]; then
        printf "\e[1;92mFound!\e[0m Instagram account associated with email: %s\n" "$email"
        printf "Instagram: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Twitter Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Twitter: \e[0m"
    check_twitter=$(curl -s "https://api.twitter.com/account/begin_password_reset.json?email=$email" -H "Accept-Language: en" | grep -o 'email is not associated')
    if [[ -z "$check_twitter" ]]; then
        printf "\e[1;92mFound!\e[0m Twitter account associated with email: %s\n" "$email"
        printf "Twitter: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### LinkedIn Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] LinkedIn: \e[0m"
    check_linkedin=$(curl -s "https://www.linkedin.com/uas/request-password-reset?emailAddress=$email" -H "Accept-Language: en" | grep -o 'email does not exist')
    if [[ -z "$check_linkedin" ]]; then
        printf "\e[1;92mFound!\e[0m LinkedIn account associated with email: %s\n" "$email"
        printf "LinkedIn: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Have I Been Pwned Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Have I Been Pwned: \e[0m"
    check_pwned=$(curl -s "https://haveibeenpwned.com/unifiedsearch/$email" -H "Accept-Language: en" | grep -o 'Breaches')
    if [[ -n "$check_pwned" ]]; then
        printf "\e[1;92mFound!\e[0m Breach associated with email: %s\n" "$email"
        printf "HIBP: Found breaches for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNo breaches found!\e[0m\n"
    fi

    ### Spotify Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Spotify: \e[0m"
    check_spotify=$(curl -s "https://www.spotify.com/password-reset/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_spotify" ]]; then
        printf "\e[1;92mFound!\e[0m Spotify account associated with email: %s\n" "$email"
        printf "Spotify: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Tumblr Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Tumblr: \e[0m"
    check_tumblr=$(curl -s "https://www.tumblr.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_tumblr" ]]; then
        printf "\e[1;92mFound!\e[0m Tumblr account associated with email: %s\n" "$email"
        printf "Tumblr: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Etsy Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Etsy: \e[0m"
    check_etsy=$(curl -s "https://www.etsy.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_etsy" ]]; then
        printf "\e[1;92mFound!\e[0m Etsy account associated with email: %s\n" "$email"
        printf "Etsy: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### CashMe Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] CashMe: \e[0m"
    check_cashme=$(curl -s "https://cash.me/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_cashme" ]]; then
        printf "\e[1;92mFound!\e[0m CashMe account associated with email: %s\n" "$email"
        printf "CashMe: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Flickr Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Flickr: \e[0m"
    check_flickr=$(curl -s "https://www.flickr.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_flickr" ]]; then
        printf "\e[1;92mFound!\e[0m Flickr account associated with email: %s\n" "$email"
        printf "Flickr: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Steam Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Steam: \e[0m"
    check_steam=$(curl -s "https://steamcommunity.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_steam" ]]; then
        printf "\e[1;92mFound!\e[0m Steam account associated with email: %s\n" "$email"
        printf "Steam: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Vimeo Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Vimeo: \e[0m"
    check_vimeo=$(curl -s "https://vimeo.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_vimeo" ]]; then
        printf "\e[1;92mFound!\e[0m Vimeo account associated with email: %s\n" "$email"
        printf "Vimeo: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Scribd Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Scribd: \e[0m"
    check_scribd=$(curl -s "https://www.scribd.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_scribd" ]]; then
        printf "\e[1;92mFound!\e[0m Scribd account associated with email: %s\n" "$email"
        printf "Scribd: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Badoo Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Badoo: \e[0m"
    check_badoo=$(curl -s "https://www.badoo.com/en/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_badoo" ]]; then
        printf "\e[1;92mFound!\e[0m Badoo account associated with email: %s\n" "$email"
        printf "Badoo: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### AllMyLinks Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] AllMyLinks: \e[0m"
    check_allmylinks=$(curl -s "https://allmylinks.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o 'Not Found')
    if [[ -z "$check_allmylinks" ]]; then
        printf "\e[1;92mFound!\e[0m AllMyLinks account associated with email: %s\n" "$email"
        printf "AllMyLinks: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Apple Developer Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Apple Developer: \e[0m"
    check_appledev=$(curl -s "https://developer.apple.com/forums/profile/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_appledev" ]]; then
        printf "\e[1;92mFound!\e[0m Apple Developer account associated with email: %s\n" "$email"
        printf "Apple Developer: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Venmo Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Venmo: \e[0m"
    check_venmo=$(curl -s "https://venmo.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_venmo" ]]; then
        printf "\e[1;92mFound!\e[0m Venmo account associated with email: %s\n" "$email"
        printf "Venmo: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### CashApp Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] CashApp: \e[0m"
    check_cashapp=$(curl -s "https://cash.app/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_cashapp" ]]; then
        printf "\e[1;92mFound!\e[0m CashApp account associated with email: %s\n" "$email"
        printf "CashApp: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### PayPal Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] PayPal: \e[0m"
    check_paypal=$(curl -s "https://www.paypal.me/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_paypal" ]]; then
        printf "\e[1;92mFound!\e[0m PayPal account associated with email: %s\n" "$email"
        printf "PayPal: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Archive.org Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Archive.org: \e[0m"
    check_archiveorg=$(curl -s "https://archive.org/details/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_archiveorg" ]]; then
        printf "\e[1;92mFound!\e[0m Archive.org account associated with email: %s\n" "$email"
        printf "Archive.org: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Pastebin Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Pastebin: \e[0m"
    check_pastebin=$(curl -s "https://pastebin.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_pastebin" ]]; then
        printf "\e[1;92mFound!\e[0m Pastebin account associated with email: %s\n" "$email"
        printf "Pastebin: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### BitBucket Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] BitBucket: \e[0m"
    check_bitbucket=$(curl -s "https://bitbucket.org/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_bitbucket" ]]; then
        printf "\e[1;92mFound!\e[0m BitBucket account associated with email: %s\n" "$email"
        printf "BitBucket: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Patreon Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Patreon: \e[0m"
    check_patreon=$(curl -s "https://www.patreon.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_patreon" ]]; then
        printf "\e[1;92mFound!\e[0m Patreon account associated with email: %s\n" "$email"
        printf "Patreon: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Discord Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Discord: \e[0m"
    check_discord=$(curl -s "https://discord.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_discord" ]]; then
        printf "\e[1;92mFound!\e[0m Discord account associated with email: %s\n" "$email"
        printf "Discord: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Snapchat Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Snapchat: \e[0m"
    check_snapchat=$(curl -s "https://www.snapchat.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_snapchat" ]]; then
        printf "\e[1;92mFound!\e[0m Snapchat account associated with email: %s\n" "$email"
        printf "Snapchat: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### TikTok Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] TikTok: \e[0m"
    check_tiktok=$(curl -s "https://www.tiktok.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_tiktok" ]]; then
        printf "\e[1;92mFound!\e[0m TikTok account associated with email: %s\n" "$email"
        printf "TikTok: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### Reddit Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Reddit: \e[0m"
    check_reddit=$(curl -s "https://www.reddit.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_reddit" ]]; then
        printf "\e[1;92mFound!\e[0m Reddit account associated with email: %s\n" "$email"
        printf "Reddit: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### GitHub Email Check ###
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] GitHub: \e[0m"
    check_github=$(curl -s "https://github.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o '404')
    if [[ -z "$check_github" ]]; then
        printf "\e[1;92mFound!\e[0m GitHub account associated with email: %s\n" "$email"
        printf "GitHub: Found account for %s\n" "$email" >> "$email.txt"
    else
        printf "\e[1;93mNot Found!\e[0m\n"
    fi

    ### End of Checks ###

    printf "\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Scanning complete.\e[0m\n"
    partial
}

banner
scanner
