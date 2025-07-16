#!/bin/bash

set -e
source "$(dirname "$0")/box-msg.sh"

# General configs
LXD_PROJECT="Landscape-25-04-Demo-Project"

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


# Check if project exists before trying to delete it
if ! lxc project show "$LXD_PROJECT" &>/dev/null; then
  log_error "Demo project: $LXD_PROJECT does not exist."
  exit 0
fi

# Get user confirmation before we nuke it
log_orange "You are about to permanently delete the LXD project: $LXD_PROJECT including all it's containers and images"

read -rp "Type 'yes' to confirm: " confirm
case "$confirm" in
  [Yy][Ee][Ss]|[Yy])
    ;;
  *)
    log_blue "Teardown canceled.."
    exit 0
    ;;
esac

log_blue "Tearing down all demo containers in project: $LXD_PROJECT..."

# Delete all containers
for container in $(lxc list --project "$LXD_PROJECT" -c n --format csv); do
  echo "Stopping container: $container"
  lxc stop "$container" --project "$LXD_PROJECT" || true
  echo "Deleting container: $container"
  lxc delete "$container" --project "$LXD_PROJECT"
done

log_blue "Removing images in project $LXD_PROJECT..."

# Delete all images
for image in $(lxc image list --project "$LXD_PROJECT" -c f --format csv ); do
  echo "Deleting image: $image"
  lxc image delete "$image" --project "$LXD_PROJECT"
done

# Delete the project
log_blue "Deleting LXD project: $LXD_PROJECT"
lxc project delete "$LXD_PROJECT"

log_green "Teardown complete!"