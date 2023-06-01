## Github Settings ##

GITHUB_TOKEN="ghp_GH_SECRET_TOKEN" # with Read Access to pull requests
GH_PER_PAGE="100"              # Per page JSON objects to be downloaded via github API
GH_PAGES_LIMIT="5"             # Setting this variable will limit the crawler depth, and removing this variable will crawl all PR pages.

## Program Settings ##
TMP_DIR="/tmp/.crawlghpr"      # Directory for temporary files # will use in few KB's.
DAYS_TO_CHECK="7"              # Days to store crawled PR's before processing

## Email / SMTP Settings ##
sender_email="sender_email@example.com"
sender_password="$ender_Email_Passw0rd"

# For crawlghpr_seamless.sh # preferred for docker 
recipient_email="receiver_email@example.com"
GITHUB_REPO="bitcoin/bitcoin"                   # github org+repo name
