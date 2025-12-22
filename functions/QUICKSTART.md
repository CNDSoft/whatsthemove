# Quick Start - Testing Notifications with Emulator

Follow these steps to test the notification function with Firebase Emulator:

## 1. Install Dependencies (First Time Only)

```bash
cd functions
npm install
```

## 2. Build the Functions

```bash
npm run build
```

## 3. Start Firebase Emulator

```bash
npm run serve
```

Or from the project root:

```bash
firebase emulators:start --only functions
```

You should see output like:
```
functions: Emulator started at http://127.0.0.1:5001
functions[us-central1-testSendNotificationToToken]: http function initialized (http://127.0.0.1:5001/whatsthemove/us-central1/testSendNotificationToToken).
```

## 4. Test the Function

### Method 1: Using the Test Script (Recommended)

```bash
cd functions
./test-notification.sh
```

Follow the prompts to enter:
- FCM Token
- Title
- Body
- Type
- Action URL (optional)

### Method 2: Using cURL Directly

**Single Token:**

```bash
curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN_HERE",
    "title": "Test Notification",
    "body": "This is a test message",
    "type": "general"
  }'
```

**Multiple Tokens:**

```bash
curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmTokens": ["TOKEN_1", "TOKEN_2"],
    "title": "Batch Test",
    "body": "Testing multiple devices"
  }'
```

## 5. Get Your FCM Token from iOS App

Add this code to your iOS app to print the FCM token:

```swift
import FirebaseMessaging

Messaging.messaging().token { token, error in
    if let token = token {
        print("FCM Token: \(token)")
    }
}
```

Copy the printed token and use it for testing.

## Expected Response

Success:
```json
{
  "success": true,
  "message": "Notification(s) sent successfully",
  "tokensSent": 1,
  "payload": {
    "title": "Test Notification",
    "body": "This is a test message",
    "type": "general",
    "notificationId": "test_notification_1234567890"
  }
}
```

## Troubleshooting

**Port already in use:**
```bash
lsof -ti:5001 | xargs kill -9
```

**Emulator not finding functions:**
- Make sure you ran `npm run build` first
- Check that `lib/index.js` exists

**FCM token not working:**
- Make sure you're using a real FCM token from a device
- Check that Firebase Cloud Messaging is set up in your Firebase project
- Token must be from the same Firebase project

## Next Steps

1. Test with your real iOS app FCM token
2. Check that notifications appear on your device
3. Once working, you can call the authenticated `sendNotificationToToken` function from your app

