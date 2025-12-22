#!/bin/bash

echo "WhatsTheMove - Test Notification Script"
echo "========================================"
echo ""

read -p "Enter FCM Token: " FCM_TOKEN

if [ -z "$FCM_TOKEN" ]; then
    echo "Error: FCM Token is required"
    exit 1
fi

read -p "Enter Notification Title [Test Notification]: " TITLE
TITLE=${TITLE:-"Test Notification"}

read -p "Enter Notification Body [This is a test message]: " BODY
BODY=${BODY:-"This is a test message"}

read -p "Enter Notification Type [general]: " TYPE
TYPE=${TYPE:-"general"}

read -p "Enter Action URL (optional): " ACTION_URL

echo ""
echo "Sending notification..."
echo ""

PAYLOAD=$(cat <<EOF
{
  "fcmToken": "$FCM_TOKEN",
  "title": "$TITLE",
  "body": "$BODY",
  "type": "$TYPE"
  $([ ! -z "$ACTION_URL" ] && echo ", \"actionUrl\": \"$ACTION_URL\"" || echo "")
}
EOF
)

curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  | python3 -m json.tool

echo ""
echo "Done!"

