#!/bin/bash

TAILORING_FILE="$LANDSCAPE_ATTACHMENTS/jammy-cis-level-1-server.xml"

sudo usg audit --tailoring-file "$TAILORING_FILE"

KEY="cis_audit"
VALUE="$(date +%Y-%m-%d)"
ANNOTATION_DIR="/var/lib/landscape/client/annotations.d"

echo "$VALUE" > "$ANNOTATION_DIR/$KEY"