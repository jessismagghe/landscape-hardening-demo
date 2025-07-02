#!/bin/bash

set -e
source "$(dirname "$0")/box-msg.sh"

# General configs
NUM_JAMMY_CLIENTS=2
NUM_NOBLE_CLIENTS=2
LXD_PROJECT="Landscape-Demo-25-04"
LANDSCAPE_SERVER="landscape-demo-server-25-04"
LANDSCAPE_IP=''

# Logging colors
BLUE='\033[38;2;0;255;255m'
ORANGE='\033[38;2;233;84;32m'
GREEN='\033[38;2;51;255;0m'
RED='\033[38;2;255;59;48m'
NONE='\033[0m'

#Logging functions
log_blue() { echo -e "${BLUE}$*${NONE}"; }
log_orange() { echo -e "${ORANGE}$(box-msg "$@")${NONE}"; }
log_green() { echo -e "${GREEN}$(box-msg "$@")${NONE}"; }
log_error() { echo -e "${RED}$(box-msg "[ERROR] $@")${NONE}"; }

deploy_client() {
    RELEASE=$1
    CLIENT_INDEX=$2
    CLIENT_NAME="${RELEASE}-client-${CLIENT_INDEX}"
    TAGS="${RELEASE},${CLIENT_NAME}"

    # Launch client container
    lxc launch ubuntu:$RELEASE "$CLIENT_NAME" --project "$LXD_PROJECT"

    # Ensure it is running properly before continuing 
    log_blue "Waiting for $CLIENT_NAME to initialize..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- bash -c '
        while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] &&
            [ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do
        sleep 1
        done
    '
    
    log_green "LXD container $CLIENT_NAME has been initialized..."

    # Add the Landscape PPA and install client
    log_blue "Installing the Landscape 25.04 client on $CLIENT_NAME..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- bash -c "
        apt update &&
        apt install -y ca-certificates software-properties-common curl gnupg &&
        add-apt-repository -y ppa:landscape/latest-stable &&
        apt update &&
        apt install -y landscape-client
    "

    # Set up container
    log_orange "Activating Ubuntu Pro..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- pro attach "$PRO_TOKEN"

    log_orange "Enabling the Ubuntu Security Guide..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- pro enable usg

    log_green "Fetching Landscape Server certificate..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- bash -c "
    echo | openssl s_client -connect $LANDSCAPE_IP:443 -servername $LANDSCAPE_IP 2>/dev/null |
    openssl x509 | tee /etc/landscape/server.pem
    "

    # Create Landscape config file with 'USGManager' plugin
    log_green "Creating /etc/landscape/client.conf..."
    cat > client.conf <<EOF
[client]
log_level = info
url = https://$LANDSCAPE_IP/message-system
ping_url = http://$LANDSCAPE_IP/ping
data_path = /var/lib/landscape/client
ssl_public_key = /etc/landscape/server.pem
account_name = standalone
computer_title = $CLIENT_NAME
include_manager_plugins = ScriptExecution,UsgManager
script_users = landscape,ubuntu,root
tags = $TAGS
EOF

    # Push landscape config file to the client
    lxc file push client.conf "$CLIENT_NAME"/etc/landscape/client.conf --project "$LXD_PROJECT"
    rm client.conf

    # Connect to Landscape
    log_blue "Running client registration..."
    lxc exec "$CLIENT_NAME" --project "$LXD_PROJECT" -- landscape-config --silent
    log_green "$CLIENT_NAME has been registered to Landscape."
    echo ""
}

log_orange "Automating Compliance and System Hardening in Landscape"
log_blue "This demo script will..."

echo -e $"1. Deploy a 25.04 Landscape Server\n\
2. Deploy Ubuntu 24.04 and 22.04 client containers\n\
3. Configure client containers with:\n\
    - Ubuntu Pro\n\
    - Ubuntu Security Guide\n\
    - Security Profiles Landscape Plugin\n\
4. Enroll clients with your Landscape server"

# Ask for Pro Token
echo ""
read -rp "$(echo -e "Enter your ${ORANGE}Ubuntu Pro token${NONE}: ")" PRO_TOKEN
echo ""

# Pro token can't be empty.
if [ -z "$PRO_TOKEN" ]; then
  log_error "No Ubuntu Pro token provided..."
  exit 1
fi

# Create a project for the demo
if ! lxc project show "$LXD_PROJECT" &>/dev/null; then
  log_green "Creating LXD project $LXD_PROJECT..."
  lxc project create "$LXD_PROJECT" 
  lxc project set "$LXD_PROJECT" features.profiles=false
  lxc project set "$LXD_PROJECT" user.description="Landscape Security Profiles Demo"
fi

# Create LXD project with default profile
if ! lxc profile show default --project "$LXD_PROJECT" &>/dev/null; then
  log_error "LXD default profile is missing. This demo is not designed to run without it :("
  exit 1
fi

# Deploy the Landscape server
if lxc info "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" &>/dev/null; then
  log_blue "Landscape server container $LANDSCAPE_SERVER already exists. Skipping creation."
else
    lxc launch ubuntu:noble "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" --profile default
    log_blue "Waiting for $LANDSCAPE_SERVER to initialize..."

    # Wait for container to be ready 
    lxc exec "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" -- bash -c '
        while [ "$(systemctl is-system-running 2>/dev/null)" != "running" ] &&
            [ "$(systemctl is-system-running 2>/dev/null)" != "degraded" ]; do
        sleep 1
        done
    '
    # Activate Ubuntu Pro
    log_orange "Activating Ubuntu Pro..."
    lxc exec "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" -- pro attach "$PRO_TOKEN"

    # Install the quick start version of Landscape
    log_green "Installing Landscape server..."
    lxc exec "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" -- bash -c "
        apt update &&
        apt install -y ca-certificates software-properties-common &&
        add-apt-repository -y ppa:landscape/latest-stable &&
        apt update &&
        DEBIAN_FRONTEND=noninteractive apt install -y landscape-server-quickstart
    "
fi

# Get IP address of Landscape server
log_blue "Fetching IP address of Landscape server..."
LANDSCAPE_IP=$(lxc exec "$LANDSCAPE_SERVER" --project "$LXD_PROJECT" -- hostname -I | awk '{print $1}')
# TODO make this better
if [ -z "$LANDSCAPE_IP" ]; then
    log_error "No IP address was found for your Landscape server..."
    exit 1
fi

log_green "Landscape Server is up and running!"
echo ""
log_blue "Please create your Landscape credentials"

#TO DO
# - Provide better follow up instructions 
log_orange " Access it at: https://$LANDSCAPE_IP/"

# Open Landscape UI
xdg-open "https://$LANDSCAPE_IP/" >/dev/null 2>&1 || true


# Prompt user to confirm that they have set up their Landscape login
while true; do
  read -rp "$(echo -e "Have you created your ${ORANGE}Landscape admin credentials?${NONE} (yes/y): ")"  confirm
  case "$confirm" in
    [Yy][Ee][Ss]|[Yy])
      break
      ;;
    *)
      echo "Please set up your Landscape admin credentials. When you have finished type 'yes' or 'y'"
      echo ""
      ;;
  esac
done

log_green "Deploying client LXD containers"

# Deploy 24.04 client containers
for i in $(seq 1 $NUM_NOBLE_CLIENTS); do
  deploy_client "noble" "$i"
done

# Deploy 22.04 client containers
for i in $(seq 1 $NUM_JAMMY_CLIENTS); do
  deploy_client "jammy" "$i"
done

# Open the Landscape UI 
log_orange "All clients deployed and connected to Landscape! Access at: https://$LANDSCAPE_IP/"
xdg-open "https://$LANDSCAPE_IP/new_dashboard/overview" >/dev/null 2>&1 || true

