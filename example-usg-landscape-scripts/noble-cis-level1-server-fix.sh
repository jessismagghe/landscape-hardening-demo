#!/bin/bash

TAILORING_FILE="$LANDSCAPE_ATTACHMENTS/noble-cis-level-1-server.xml"

sudo usg fix --tailoring-file "$TAILORING_FILE"

sudo reboot