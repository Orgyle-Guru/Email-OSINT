#!/bin/bash
# OSINT Email Finder v2.0
# Author: @Orgyle-Guru
# https://github.com/Orgyle-Guru/Email-OSINT/

trap 'printf "\n";partial;exit 1' 2

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
    if [[ -e $email.txt ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m %s.txt\n" $email
    fi
}

scanner() {
    read -p $'\e[1;92m[\e[0m\e[1;77m?\e[0m\e[1;92m] Input Email Address:\e[0m ' email

    if [[ -e $email.txt ]]; then
        printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Removing previous file:\e[0m\e[1;77m %s.txt\n" $email
        rm -rf $email.txt
    fi
    printf "\n"
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Checking email\e[0m\e[1;77m %s\e[0m\e[1;92m on: \e[0m\n" $email

    ## Facebook Email Check
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Facebook: \e[0m"
    check_facebook=$(curl -s "https://www.facebook.com/recover/initiate/?email=$email" -H "Accept-Language: en" | grep -o 'Sorry, we couldn’t find an account'; echo $?)
    if [[ $check_facebook == *'1'* ]]; then
        printf "\e[1;92m Found!\e[0m Facebook account associated with email: %s\n" $email
        printf "Facebook: Found account for %s\n" $email >> $email.txt
    else
        printf "\e[1;93m Not Found!\e[0m\n"
    fi

    ## Instagram Email Check
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Instagram: \e[0m"
    check_insta=$(curl -s "https://www.instagram.com/accounts/password/reset/?email=$email" -H "Accept-Language: en" | grep -o 'Please enter a valid email address.'; echo $?)
    if [[ $check_insta == *'1'* ]]; then
        printf "\e[1;92m Found!\e[0m Instagram account associated with email: %s\n" $email
        printf "Instagram: Found account for %s\n" $email >> $email.txt
    else
        printf "\e[1;93m Not Found!\e[0m\n"
    fi

    ## Twitter Email Check
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Twitter: \e[0m"
    check_twitter=$(curl -s "https://api.twitter.com/account/begin_password_reset.json?email=$email" -H "Accept-Language: en" | grep -o 'email is not associated'; echo $?)
    if [[ $check_twitter == *'1'* ]]; then
        printf "\e[1;92m Found!\e[0m Twitter account associated with email: %s\n" $email
        printf "Twitter: Found account for %s\n" $email >> $email.txt
    else
        printf "\e[1;93m Not Found!\e[0m\n"
    fi

    ## LinkedIn Email Check
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] LinkedIn: \e[0m"
    check_linkedin=$(curl -s "https://www.linkedin.com/uas/request-password-reset?emailAddress=$email" -H "Accept-Language: en" | grep -o 'email does not exist'; echo $?)
    if [[ $check_linkedin == *'1'* ]]; then
        printf "\e[1;92m Found!\e[0m LinkedIn account associated with email: %s\n" $email
        printf "LinkedIn: Found account for %s\n" $email >> $email.txt
    else
        printf "\e[1;93m Not Found!\e[0m\n"
    fi

    ## Have I Been Pwned Check
    printf "\e[1;77m[\e[0m\e[1;92m+\e[0m\e[1;77m] Have I Been Pwned: \e[0m"
    check_pwned=$(curl -s "https://haveibeenpwned.com/unifiedsearch/$email" -H "Accept-Language: en" | grep -o 'Breaches'; echo $?)
    if [[ $check_pwned == *'1'* ]]; then
        printf "\e[1;92m Found!\e[0m Breach associated with email: %s\n" $email
        printf "HIBP: Found breaches for %s\n" $email >> $email.txt
    else
        printf "\e[1;93m No breaches found!\e[0m\n"
    fi
}

banner
scanner
