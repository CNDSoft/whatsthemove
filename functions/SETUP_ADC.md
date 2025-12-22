# Setting Up Application Default Credentials (ADC)

This is the recommended approach for local development with Firebase Functions.

## One-Time Setup

### 1. Install Google Cloud SDK (if not already installed)

Check if gcloud is installed:
```bash
gcloud --version
```

If not installed, install it:
```bash
brew install --cask google-cloud-sdk
```

Or download from: https://cloud.google.com/sdk/docs/install

### 2. Login and Set Application Default Credentials

```bash
gcloud auth application-default login
```

This will:
- Open your browser
- Ask you to login with your Google account (cem.sertkaya@cndsoftware.com)
- Save credentials locally at `~/.config/gcloud/application_default_credentials.json`
- These credentials will be automatically used by Firebase Admin SDK

### 3. Set the Project

```bash
gcloud config set project eventbooking-fd7c2
```

### 4. Verify Setup

```bash
gcloud config get-value project
gcloud auth application-default print-access-token
```

You should see your project ID and an access token.

## Running the Emulator

Now you can start the emulator normally:

```bash
cd functions
npm run serve
```

The Firebase Admin SDK will automatically use your Application Default Credentials.

## Testing

```bash
curl -X POST http://localhost:5002/eventbooking-fd7c2/us-central1/testSendNotificationToToken \
  -H "Content-Type: application/json" \
  -d '{
    "fcmToken": "YOUR_FCM_TOKEN",
    "title": "Test Notification",
    "body": "Testing with ADC!",
    "type": "general"
  }'
```

## Troubleshooting

### "Could not load default credentials" Error

Run:
```bash
gcloud auth application-default login
```

### "Insufficient Permission" Error

Make sure your Google account has the necessary permissions in the Firebase project:
- Go to: https://console.firebase.google.com/project/eventbooking-fd7c2/settings/iam
- Your account should have "Firebase Admin" or "Editor" role

### Token Expired

If you get authentication errors after some time:
```bash
gcloud auth application-default login --force
```

## Why ADC is Better Than Service Account Keys

| Aspect | ADC | Service Account Key |
|--------|-----|-------------------|
| Security | ✅ Credentials tied to your account | ❌ Key file can be leaked |
| Management | ✅ Auto-refreshes | ❌ Manual rotation needed |
| Setup | ✅ One command | ❌ Download & store file |
| Best Practice | ✅ Recommended by Google | ❌ Not recommended for local dev |
| Git Safety | ✅ No files to exclude | ❌ Must be in .gitignore |

## For Production (Deployment)

When you deploy to Firebase, it will automatically use the Firebase service account:

```bash
firebase deploy --only functions
```

No additional configuration needed! Firebase handles the credentials automatically.

