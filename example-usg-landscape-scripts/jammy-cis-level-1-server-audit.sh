#!/bin/bash

TAILORING_FILE="$LANDSCAPE_ATTACHMENTS/jammy-cis-level-1-server.xml"

sudo usg audit --tailoring-file "$TAILORING_FILE"