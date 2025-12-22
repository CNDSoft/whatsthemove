# Firebase Functions - WhatsTheMove

This directory contains Firebase Cloud Functions for the WhatsTheMove application.

## Setup

### Prerequisites
- Node.js 18 or higher
- Firebase CLI installed globally: `npm install -g firebase-tools`
- Firebase project configured

### Installation

```bash
cd functions
npm install
```

## Development

### Building the Functions

```bash
npm run build
```

### Watch Mode (Auto-compile on changes)

```bash
npm run build:watch
```

## Testing with Firebase Emulator

### Starting the Emulator

```bash
npm run serve
```

This will start:
- Functions emulator on port 5001
- Firestore emulator on port 8080
- Firebase Emulator UI on port 4000

Visit http://localhost:4000 to access the Emulator UI.

### Testing the Notification Function

#### Using HTTP Endpoint (for testing)

The `testSendNotificationToToken` function is an HTTP endpoint that bypasses authentication for easy testing.

**Single Token:**

```bash
curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN_HERE",
    "title": "Test Notification",
    "body": "This is a test message",
    "type": "general",
    "actionUrl": "whatsthemove://events/123"
  }'
```

**Multiple Tokens:**

```bash
curl -X POST http://localhost:5001/whatsthemove/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmTokens": ["TOKEN_1", "TOKEN_2", "TOKEN_3"],
    "title": "Test Notification",
    "body": "This is a test message to multiple devices",
    "type": "event_reminder",
    "eventId": "event123",
    "actionUrl": "whatsthemove://events/123"
  }'
```

#### Using Callable Function (requires authentication)

The `sendNotificationToToken` is a callable function that requires authentication.

From your iOS app:

```swift
let functions = Functions.functions()
let data: [String: Any] = [
    "fcmToken": "YOUR_FCM_TOKEN",
    "title": "Hello",
    "body": "This is a notification",
    "type": "general"
]

functions.httpsCallable("sendNotificationToToken").call(data) { result, error in
    if let error = error {
        print("Error: \(error)")
        return
    }
    
    if let result = result?.data as? [String: Any] {
        print("Success: \(result)")
    }
}
```

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `fcmToken` | string | No* | Single FCM token to send notification to |
| `fcmTokens` | string[] | No* | Array of FCM tokens for batch sending |
| `title` | string | Yes | Notification title |
| `body` | string | Yes | Notification body/message |
| `type` | string | No | Notification type (default: "general") |
| `eventId` | string | No | Associated event ID |
| `actionUrl` | string | No | Deep link URL for notification action |

*Either `fcmToken` or `fcmTokens` must be provided.

### Response Format

**Success Response:**

```json
{
  "success": true,
  "message": "Notification(s) sent successfully",
  "tokensSent": 1,
  "payload": {
    "title": "Test Notification",
    "body": "This is a test message",
    "type": "general",
    "notificationId": "test_notification_1234567890",
    "actionUrl": "whatsthemove://events/123"
  }
}
```

**Error Response:**

```json
{
  "success": false,
  "error": "Error message here"
}
```

## Available Functions

### `sendNotificationToToken` (Callable)
Authenticated function to send notifications to specific FCM tokens. Requires user authentication.

### `testSendNotificationToToken` (HTTP)
Test endpoint for sending notifications without authentication. Use only for development/testing.

## Deployment

```bash
npm run deploy
```

Or deploy specific function:

```bash
firebase deploy --only functions:sendNotificationToToken
```

## Project Structure

```
functions/
├── src/
│   ├── index.ts                    # Main entry point
│   ├── notifications/
│   │   └── sendToToken.ts          # Notification functions
│   └── utils/
│       ├── fcm.ts                  # FCM messaging utilities
│       └── firestore.ts            # Firestore utilities
├── lib/                            # Compiled JavaScript (auto-generated)
├── package.json
└── tsconfig.json
```

## Troubleshooting

### Emulator Not Starting
- Make sure no other service is using ports 5001, 8080, or 4000
- Check Firebase CLI is updated: `firebase --version`

### FCM Token Issues
- Make sure the FCM token is valid and not expired
- Test with a real device token from your iOS app
- Check that Firebase Cloud Messaging is properly configured in your Firebase project

### Build Errors
- Delete `node_modules` and `package-lock.json`, then run `npm install` again
- Ensure TypeScript version is compatible: `npm list typescript`

## Getting FCM Token from iOS App

To test with a real FCM token, add this to your iOS app:

```swift
import FirebaseMessaging

Messaging.messaging().token { token, error in
    if let error = error {
        print("Error fetching FCM token: \(error)")
    } else if let token = token {
        print("FCM Token: \(token)")
        // Use this token for testing
    }
}
```

## Notes

- The test endpoint (`testSendNotificationToToken`) should only be used in development
- For production, always use the authenticated callable function (`sendNotificationToToken`)
- FCM tokens can expire, always handle token refresh in your app
- Batch notifications are sent in batches of 500 tokens maximum
