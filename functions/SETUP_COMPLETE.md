# Firebase Functions Setup - Complete! ✓

Your Firebase Functions for sending notifications to specific FCM tokens is now ready to test with the emulator.

## What Was Created

### 1. Project Configuration Files
- `package.json` - Dependencies and scripts
- `tsconfig.json` - TypeScript configuration  
- `firebase.json` - Firebase emulator configuration
- `.firebaserc` - Firebase project settings
- `.eslintrc.js` - Code linting rules
- `.gitignore` - Git ignore patterns

### 2. Source Files (TypeScript)

**Main Entry:**
- `src/index.ts` - Exports all cloud functions

**Notification Functions:**
- `src/notifications/sendToToken.ts` - Two functions:
  - `sendNotificationToToken` - Authenticated callable function (for production)
  - `testSendNotificationToToken` - HTTP endpoint for testing (no auth required)

**Utilities:**
- `src/utils/fcm.ts` - FCM messaging utilities
  - `sendPushNotification()` - Send to single token
  - `sendBatchPushNotifications()` - Send to multiple tokens (batches of 500)
- `src/utils/firestore.ts` - Firestore utilities

### 3. Testing Tools
- `test-notification.sh` - Interactive test script
- `example-requests.json` - Sample request payloads

### 4. Documentation
- `README.md` - Complete documentation
- `QUICKSTART.md` - Quick start guide
- `SETUP_COMPLETE.md` - This file

## Quick Start Testing

### Step 1: Start the Emulator

```bash
cd functions
npm run serve
```

Wait for the emulator to start. You'll see:
```
functions[us-central1-testSendNotificationToToken]: http function initialized
```

### Step 2: Get Your FCM Token

In your iOS app, add this code:

```swift
import FirebaseMessaging

Messaging.messaging().token { token, error in
    if let token = token {
        print("FCM Token: \(token)")
        // Copy this token for testing
    }
}
```

### Step 3: Send a Test Notification

**Option A - Interactive Script:**
```bash
cd functions
./test-notification.sh
```

**Option B - Direct cURL:**
```bash
curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_TOKEN_HERE",
    "title": "Hello",
    "body": "Test from emulator!",
    "type": "general"
  }'
```

## Function API

### testSendNotificationToToken (HTTP - For Testing)

**Endpoint:** `POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken`

**Request Body:**
```json
{
  "fcmToken": "string",           // Single token
  "fcmTokens": ["string"],        // OR array of tokens
  "title": "string",              // Required
  "body": "string",               // Required
  "type": "string",               // Optional (default: "general")
  "eventId": "string",            // Optional
  "actionUrl": "string"           // Optional (deep link)
}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification(s) sent successfully",
  "tokensSent": 1,
  "payload": { ... }
}
```

### sendNotificationToToken (Callable - For Production)

This is an authenticated callable function. Call from your iOS app:

```swift
let functions = Functions.functions()
functions.httpsCallable("sendNotificationToToken").call([
    "fcmToken": token,
    "title": "Event Reminder",
    "body": "Your event starts soon!",
    "type": "event_reminder",
    "eventId": "123",
    "actionUrl": "whatsthemove://events/123"
]) { result, error in
    // Handle result
}
```

## Notification Types

Suggested notification types for your app:
- `general` - General announcements
- `event_reminder` - Event reminders
- `registration_deadline` - Registration deadlines
- `event_update` - Event updates
- `friend_activity` - Friend activity notifications
- `system` - System notifications

## Emulator Ports

- Functions: http://localhost:5001
- Firestore: http://localhost:8080
- Emulator UI: http://localhost:4000

## File Structure

```
functions/
├── src/                          # TypeScript source files
│   ├── index.ts                 # Main entry point
│   ├── notifications/
│   │   └── sendToToken.ts       # Notification functions
│   └── utils/
│       ├── fcm.ts               # FCM utilities
│       └── firestore.ts         # Firestore utilities
├── lib/                          # Compiled JavaScript (auto-generated)
├── node_modules/                 # Dependencies
├── package.json                  # Project configuration
├── tsconfig.json                 # TypeScript config
├── firebase.json                 # Firebase config
├── .firebaserc                   # Firebase project
├── .eslintrc.js                  # Linting rules
├── test-notification.sh          # Test script
├── example-requests.json         # Example payloads
├── QUICKSTART.md                 # Quick start guide
├── README.md                     # Full documentation
└── SETUP_COMPLETE.md            # This file
```

## Next Steps

1. ✓ Start the emulator: `npm run serve`
2. ✓ Get FCM token from your iOS app
3. ✓ Test with `./test-notification.sh` or cURL
4. ✓ Verify notification appears on your device
5. ✓ Once working, integrate callable function in your app
6. ✓ Deploy when ready: `npm run deploy`

## Troubleshooting

**Build errors?**
```bash
cd functions
rm -rf node_modules package-lock.json
npm install
npm run build
```

**Port already in use?**
```bash
lsof -ti:5001 | xargs kill -9
firebase emulators:start --only functions
```

**Notifications not arriving?**
- Check FCM token is valid and current
- Verify Firebase Cloud Messaging is configured in Firebase Console
- Check device has notification permissions enabled
- Look at emulator logs for errors

## Support

For issues or questions:
1. Check the logs in the emulator terminal
2. Review Firebase documentation: https://firebase.google.com/docs/functions
3. Check FCM setup: https://firebase.google.com/docs/cloud-messaging

---

**Status:** ✅ Ready to test with emulator
**Build:** ✅ Compiled successfully
**Functions:** 2 (1 HTTP test endpoint + 1 callable function)

