#!/bin/bash

echo "Starting Firebase Functions Emulator..."
echo "========================================"
echo ""

npm run build

echo ""
echo "Starting emulator on port 5002..."
echo "Test endpoint: http://localhost:5002/eventbooking-fd7c2/us-central1/testSendNotificationToToken"
echo ""

firebase emulators:start --only functions

