#!/bin/bash
set -e

DID="did:cow:8BC101ABF5BcF8b6209FaaAD4D761C1ED14999Be:plc:pyzlzqt6b2nyrha7smfry6rv"

echo "Initializing $DID"
python3 "$(dirname "$0")/cow.py" initialize "$DID"
echo ""
python3 "$(dirname "$0")/cow.py" describe "$DID"
