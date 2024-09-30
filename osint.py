#!/usr/bin/env python3
import requests
import re
import sys
import time
import random
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from urllib.parse import urlencode
import smtplib
import dns.resolver

# Configure logging
logging.basicConfig(filename='osint_email_finder.log', level=logging.DEBUG,
                    format='%(asctime)s - %(levelname)s - %(message)s')

# Define User-Agents
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko)",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)"
    # Add more as needed
]

# Define Proxies (optional)
PROXIES = [
    # Example proxies
    # "http://proxy1.example.com:8080",
    # "http://proxy2.example.com:8080",
    # "http://proxy3.example.com:8080"
    # Add more proxies as needed
]

# Function to get random User-Agent
def get_random_user_agent():
    return random.choice(USER_AGENTS)

# Function to get random Proxy
def get_random_proxy():
    if PROXIES:
        proxy = random.choice(PROXIES)
        return {"http": proxy, "https": proxy}
    return None

# Function to validate email format
def validate_email(email):
    pattern = r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    return re.match(pattern, email) is not None

# Function to perform service check
def check_service(service_name, service_info, email):
    url = service_info.get("url")
    method = service_info.get("method", "GET").upper()
    data = service_info.get("data", {})
    headers = {
        'User-Agent': get_random_user_agent(),
        'Accept-Language': 'en'
    }
    proxies = get_random_proxy()
    
    try:
        if method == "POST":
            response = requests.post(url, headers=headers, data=data, proxies=proxies, timeout=10)
        else:
            response = requests.get(url, headers=headers, proxies=proxies, timeout=10)
        
        body = response.text
        status = response.status_code
        
        logging.debug(f"Service: {service_name}")
        logging.debug(f"URL: {url}")
        logging.debug(f"Method: {method}")
        logging.debug(f"Status Code: {status}")
        logging.debug(f"Response Body: {body[:200]}...")  # Log first 200 characters
        
        if status == 200:
            # Check failure patterns
            found_failure = any(re.search(pattern, body, re.IGNORECASE) for pattern in service_info.get("failure_patterns", []))
            if found_failure:
                print(f"[+] {service_name}: Not Found!")
                return
            
            # Check success patterns
            found_success = any(re.search(pattern, body, re.IGNORECASE) for pattern in service_info.get("success_patterns", []))
            if found_success:
                print(f"[+] {service_name}: Found!")
                with open(f"{email}.txt", "a") as f:
                    f.write(f"{service_name}: Found account for {email}\n")
                return
            
            # If neither patterns matched
            print(f"[+] {service_name}: Not Found!")
        else:
            print(f"[+] {service_name}: HTTP {status} - Not Found!")
    
    except requests.RequestException as e:
        print(f"[!] {service_name}: Error - {e}")
        logging.error(f"{service_name} Error: {e}")

    # Random sleep between 1-3 seconds to mimic human behavior
    time.sleep(random.randint(1, 3))

# Function to perform Google Search (cautious usage)
def search_google(email):
    headers = {
        'User-Agent': get_random_user_agent()
    }
    query = f'"{email}"'
    params = {'q': query}
    url = f'https://www.google.com/search?{urlencode(params)}'
    proxies = get_random_proxy()
    
    try:
        response = requests.get(url, headers=headers, proxies=proxies, timeout=10)
        body = response.text
        if re.search(re.escape(email), body, re.IGNORECASE):
            print(f"[+] Google Search: Found mention for {email}")
            with open(f"{email}.txt", "a") as f:
                f.write(f"Google Search: Found mention for {email}\n")
        else:
            print(f"[+] Google Search: No mention found for {email}")
    except requests.RequestException as e:
        print(f"[!] Google Search: Error - {e}")
        logging.error(f"Google Search Error: {e}")
    
    time.sleep(random.randint(1,3))

# Function to perform Reddit Search
def search_reddit(email):
    headers = {
        'User-Agent': get_random_user_agent()
    }
    query = f'"{email}"'
    url = f'https://www.reddit.com/search.json?q={query}'
    proxies = get_random_proxy()
    
    try:
        response = requests.get(url, headers=headers, proxies=proxies, timeout=10)
        data = response.json()
        found = False
        for post in data.get('data', {}).get('children', []):
            if email.lower() in post['data'].get('selftext', '').lower():
                print(f"[+] Reddit: Found mention for {email}")
                with open(f"{email}.txt", "a") as f:
                    f.write(f"Reddit: Found mention for {email}\n")
                found = True
                break
        if not found:
            print(f"[+] Reddit: No mention found for {email}")
    except requests.RequestException as e:
        print(f"[!] Reddit Search: Error - {e}")
        logging.error(f"Reddit Search Error: {e}")
    except ValueError as e:
        print(f"[!] Reddit Search: Invalid JSON response")
        logging.error(f"Reddit Search JSON Error: {e}")
    
    time.sleep(random.randint(1,3))

# Function to perform SMTP verification (simplified)
def smtp_verify(email):
    domain = email.split('@')[-1]
    try:
        answers = dns.resolver.resolve(domain, 'MX')
        mx_records = sorted([(r.preference, r.exchange.to_text()) for r in answers], key=lambda x: x[0])
        for preference, exchange in mx_records:
            try:
                server = exchange.rstrip('.')
                with smtplib.SMTP(server, 25, timeout=10) as smtp:
                    smtp.helo('localhost')
                    smtp.mail('no-reply@localhost')
                    code, message = smtp.rcpt(email)
                    if code == 250:
                        print(f"[+] SMTP Verification: Email {email} exists on {server}")
                        with open(f"{email}.txt", "a") as f:
                            f.write(f"SMTP Verification: Found account for {email} on {server}\n")
                        return
            except smtplib.SMTPServerDisconnected:
                continue
            except smtplib.SMTPConnectError:
                continue
            except smtplib.SMTPException as e:
                logging.error(f"SMTP Verification Error for {exchange}: {e}")
                continue
        print(f"[+] SMTP Verification: Unable to verify email {email} via SMTP")
    except dns.resolver.NoAnswer:
        print(f"SMTP Verification: No MX records found for {domain}")
    except dns.resolver.NXDOMAIN:
        print(f"SMTP Verification: Domain {domain} does not exist")
    except Exception as e:
        print(f"SMTP Verification: Error retrieving MX records for {domain}")
        logging.error(f"SMTP Verification Error: {e}")
    
    time.sleep(random.randint(1,3))

# Function to perform TheHarvester searches (optional)
def use_theharvester(domain, email):
    try:
        import subprocess
        result_file = 'temp_results.html'
        subprocess.run(['theharvester', '-d', domain, '-l', '100', '-b', 'all', '-f', result_file], check=True)
        with open(result_file, 'r') as f:
            content = f.read()
            if email.lower() in content.lower():
                print(f"[+] TheHarvester: Found {email} in {domain}")
                with open(f"{email}.txt", "a") as out_file:
                    out_file.write(f"TheHarvester: Found account for {email} in {domain}\n")
            else:
                print(f"[+] TheHarvester: No account found for {email} in {domain}")
        # Clean up
        subprocess.run(['rm', result_file])
    except subprocess.CalledProcessError as e:
        print(f"[!] TheHarvester: Error - {e}")
        logging.error(f"TheHarvester Error: {e}")
    except FileNotFoundError:
        print("[!] TheHarvester: Not installed or not found in PATH.")
        logging.error("TheHarvester not installed or not found in PATH.")

# Main function
def main():
    email = input("[?] Input Email Address: ").strip()

    # Validate email format
    if not validate_email(email):
        print("\e[1;93mInvalid email format. Please try again.\e[0m")
        sys.exit(1)

    # Remove previous results if exist
    try:
        open(f"{email}.txt", "w").close()
    except IOError as e:
        print(f"[!] Error removing previous file: {e}")
        logging.error(f"File Removal Error: {e}")

    print(f"\n[\e[1;92m*\e[0m] Checking email: {email}\n")

    # Define services with their respective URLs, methods, and patterns
    services = {
        # Top 20 Dating Sites
        "Tinder": {
            "url": f"https://www.tinder.com/recover/initiate/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["Sorry, we couldn’t find an account"]
        },
        "Bumble": {
            "url": f"https://bumble.com/reset-password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "OkCupid": {
            "url": f"https://www.okcupid.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Match.com": {
            "url": f"https://www.match.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "eHarmony": {
            "url": f"https://www.eharmony.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Plenty of Fish": {
            "url": f"https://www.pof.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Hinge": {
            "url": f"https://hinge.co/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Zoosk": {
            "url": f"https://www.zoosk.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Elite Singles": {
            "url": f"https://www.elitesingles.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Christian Mingle": {
            "url": f"https://www.christianmingle.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "JDate": {
            "url": f"https://www.jdate.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "OurTime": {
            "url": f"https://www.ourtime.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Coffee Meets Bagel": {
            "url": f"https://coffeemeetsbagel.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Happn": {
            "url": f"https://www.happn.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Grindr": {
            "url": f"https://www.grindr.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "HER": {
            "url": f"https://www.weareher.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Raya": {
            "url": f"https://raya.co/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "The League": {
            "url": f"https://www.theleague.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "SilverSingles": {
            "url": f"https://www.silversingles.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "BlackPeopleMeet": {
            "url": f"https://www.blackpeoplemeet.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        
        # Other Frequently Used Sites
        "Facebook": {
            "url": f"https://www.facebook.com/recover/initiate/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["Sorry, we couldn’t find an account"]
        },
        "Instagram": {
            "url": f"https://www.instagram.com/accounts/password/reset/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["Please enter a valid email address."]
        },
        "Twitter": {
            "url": f"https://api.twitter.com/account/begin_password_reset.json?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["email is not associated"]
        },
        "LinkedIn": {
            "url": f"https://www.linkedin.com/uas/request-password-reset?emailAddress={email}",
            "method": "GET",
            "success_patterns": ["reset link sent"],
            "failure_patterns": ["email does not exist"]
        },
        "Google": {
            "url": f"https://accounts.google.com/signin/recovery?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["Couldn't find your Google Account"]
        },
        "Microsoft": {
            "url": f"https://account.live.com/ResetPassword.aspx?mkt=en-US&email={email}",
            "method": "GET",
            "success_patterns": ["We have sent a code"],
            "failure_patterns": ["We couldn't find an account"]
        },
        "Apple": {
            "url": f"https://iforgot.apple.com/password/verify/appleid?appleid={email}",
            "method": "GET",
            "success_patterns": ["We’ve emailed you"],
            "failure_patterns": ["We can’t find an Apple ID"]
        },
        "Amazon": {
            "url": f"https://www.amazon.com/ap/forgotpassword?email={email}",
            "method": "GET",
            "success_patterns": ["We have emailed you"],
            "failure_patterns": ["There is no account"]
        },
        "Reddit": {
            "url": f"https://www.reddit.com/recover/initiate/?email={email}",
            "method": "GET",
            "success_patterns": ["reset link sent"],
            "failure_patterns": ["account not found"]
        },
        "Pinterest": {
            "url": f"https://www.pinterest.com/password_reset/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["email not found"]
        },
        "Quora": {
            "url": f"https://www.quora.com/password_reset",
            "method": "POST",
            "data": {"email": email},
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["No account found"]
        },
        "Slack": {
            "url": f"https://slack.com/forgot-password?email={email}",
            "method": "POST",
            "data": {"email": email},
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["We couldn’t find your workspace"]
        },
        "Zoom": {
            "url": f"https://zoom.us/signin?returnurl=https%3A%2F%2Fzoom.us%2Fforgot_password&email={email}",
            "method": "GET",
            "success_patterns": ["We have sent you a reset link"],
            "failure_patterns": ["Account not found"]
        },
        "Dropbox": {
            "url": f"https://www.dropbox.com/reset_password?email={email}",
            "method": "GET",
            "success_patterns": ["We have sent you a password reset link"],
            "failure_patterns": ["No account found"]
        },
        "GitHub": {
            "url": f"https://github.com/recover/initiate/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["We couldn't find your account"]
        },
        "PayPal": {
            "url": f"https://www.paypal.com/signin/recovery?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["Account not found"]
        },
        "eBay": {
            "url": f"https://signin.ebay.com/ws/eBayISAPI.dll?ResetPwd&email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["We cannot find your eBay account"]
        },
        "Netflix": {
            "url": f"https://www.netflix.com/PasswordReset",
            "method": "POST",
            "data": {"email": email},
            "success_patterns": ["password reset email sent"],
            "failure_patterns": ["We cannot find an account with that email"]
        },
        "Spotify": {
            "url": f"https://www.spotify.com/password-reset/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["404"]
        },
        "TikTok": {
            "url": f"https://www.tiktok.com/recover/initiate/?email={email}",
            "method": "GET",
            "success_patterns": ["password reset sent"],
            "failure_patterns": ["404"]
        }
    }

    # Function to perform SMTP verification (advanced)
    def smtp_verify(email):
        domain = email.split('@')[-1]
        try:
            # Retrieve MX records
            answers = dns.resolver.resolve(domain, 'MX')
            mx_records = sorted([(r.preference, r.exchange.to_text()) for r in answers], key=lambda x: x[0])
            if not mx_records:
                print(f"[+] SMTP Verification: No MX records found for {domain}")
                return
            for preference, exchange in mx_records:
                try:
                    server = exchange.rstrip('.')
                    with smtplib.SMTP(server, 25, timeout=10) as smtp:
                        smtp.helo('localhost')
                        smtp.mail('no-reply@localhost')
                        code, message = smtp.rcpt(email)
                        if code == 250:
                            print(f"[+] SMTP Verification: Email {email} exists on {server}")
                            with open(f"{email}.txt", "a") as f:
                                f.write(f"SMTP Verification: Found account for {email} on {server}\n")
                            return
                except smtplib.SMTPServerDisconnected:
                    continue
                except smtplib.SMTPConnectError:
                    continue
                except smtplib.SMTPException as e:
                    logging.error(f"SMTP Verification Error for {exchange}: {e}")
                    continue
            print(f"[+] SMTP Verification: Unable to verify email {email} via SMTP")
        except dns.resolver.NoAnswer:
            print(f"[+] SMTP Verification: No MX records found for {domain}")
        except dns.resolver.NXDOMAIN:
            print(f"[+] SMTP Verification: Domain {domain} does not exist")
        except Exception as e:
            print(f"[!] SMTP Verification: Error retrieving MX records for {domain}")
            logging.error(f"SMTP Verification Error: {e}")
    
        time.sleep(random.randint(1,3))

    # Function to perform TheHarvester searches (optional)
    def use_theharvester(domain, email):
        try:
            import subprocess
            result_file = 'temp_results.html'
            subprocess.run(['theharvester', '-d', domain, '-l', '100', '-b', 'all', '-f', result_file], check=True)
            with open(result_file, 'r') as f:
                content = f.read()
                if email.lower() in content.lower():
                    print(f"[+] TheHarvester: Found {email} in {domain}")
                    with open(f"{email}.txt", "a") as out_file:
                        out_file.write(f"TheHarvester: Found account for {email} in {domain}\n")
                else:
                    print(f"[+] TheHarvester: No account found for {email} in {domain}")
            # Clean up
            subprocess.run(['rm', result_file])
        except subprocess.CalledProcessError as e:
            print(f"[!] TheHarvester: Error - {e}")
            logging.error(f"TheHarvester Error: {e}")
        except FileNotFoundError:
            print("[!] TheHarvester: Not installed or not found in PATH.")
            logging.error("TheHarvester not installed or not found in PATH.")

    # Function to perform Have I Been Pwned (HIBP) check (requires API key)
    def check_hibp(email):
        # Note: Scraping HIBP is against their terms of service.
        # Use their API responsibly with proper API keys.
        api_key = 'YOUR_HIBP_API_KEY'  # Replace with your actual API key
        headers = {
            'User-Agent': 'OSINT Email Finder v2.0',
            'hibp-api-key': api_key
        }
        url = f"https://haveibeenpwned.com/api/v3/breachedaccount/{email}?truncateResponse=false"
        try:
            response = requests.get(url, headers=headers, timeout=10)
            if response.status_code == 200:
                breaches = response.json()
                if breaches:
                    print(f"[+] HIBP: Breaches found for {email}")
                    with open(f"{email}.txt", "a") as f:
                        for breach in breaches:
                            f.write(f"HIBP: Found breach '{breach['Name']}' for {email}\n")
                else:
                    print(f"[+] HIBP: No breaches found for {email}")
            elif response.status_code == 404:
                print(f"[+] HIBP: No breaches found for {email}")
            else:
                print(f"[!] HIBP: Unexpected response {response.status_code}")
                logging.error(f"HIBP Unexpected Response: {response.status_code} - {response.text}")
        except requests.RequestException as e:
            print(f"[!] HIBP: Error - {e}")
            logging.error(f"HIBP Error: {e}")
    
        time.sleep(random.randint(1,3))

    # Function to perform parallel service checks
    def parallel_checks(services, email):
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = []
            for service, details in services.items():
                futures.append(executor.submit(check_service, service, details, email))
            for future in as_completed(futures):
                pass  # All output is handled within check_service

    # Start scanning
    parallel_checks(services, email)

    # Additional Searches
    search_google(email)
    search_reddit(email)

    # SMTP Verification (optional)
    smtp_verify(email)

    # TheHarvester Usage (optional, specify relevant domains)
    # Define domains associated with the email for TheHarvester
    # domains = ["example.com", "anotherdomain.com"]
    # for domain in domains:
    #     use_theharvester(domain, email)

    # HIBP Check (requires API key)
    # Uncomment the line below after adding your HIBP API key
    # check_hibp(email)

    print(f"\n[+] Scanning complete. Results saved to {email}.txt if any accounts were found.\n")

if __name__ == "__main__":
    main()
