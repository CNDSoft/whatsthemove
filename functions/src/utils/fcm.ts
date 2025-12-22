import * as admin from "firebase-admin";

export interface PushNotificationPayload {
  title: string;
  body: string;
  type: "Event" | "Deadline" | "Registration" | "General";
  notificationId: string;
  eventId?: string;
  actionUrl?: string;
}

export async function sendPushNotification(
  fcmToken: string,
  payload: PushNotificationPayload
): Promise<void> {
  try {
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        notificationId: payload.notificationId,
        ...(payload.eventId && { eventId: payload.eventId }),
        ...(payload.actionUrl && { actionUrl: payload.actionUrl }),
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    console.log(`Sending push notification to token: ${fcmToken.substring(0, 20)}...`);
    console.log(`  Title: ${payload.title}`);
    console.log(`  Body: ${payload.body}`);
    
    await admin.messaging().send(message);
    console.log(`✓ Push notification sent successfully`);
  } catch (error) {
    console.error(`✗ Failed to send push notification:`, error);
    throw error;
  }
}

export async function sendBatchPushNotifications(
  tokens: string[],
  payload: PushNotificationPayload
): Promise<void> {
  console.log(`Sending batch push notifications to ${tokens.length} tokens...`);
  
  const batchSize = 500;
  const batches: string[][] = [];

  for (let i = 0; i < tokens.length; i += batchSize) {
    batches.push(tokens.slice(i, i + batchSize));
  }

  for (const batch of batches) {
    const messages: admin.messaging.Message[] = batch.map((token) => ({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        notificationId: payload.notificationId,
        ...(payload.eventId && { eventId: payload.eventId }),
        ...(payload.actionUrl && { actionUrl: payload.actionUrl }),
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    }));

    try {
      const response = await admin.messaging().sendEach(messages);
      console.log(`✓ Batch sent: ${response.successCount} successful, ${response.failureCount} failed`);
      
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`  ✗ Failed for token ${batch[idx].substring(0, 20)}...: ${resp.error}`);
          }
        });
      }
    } catch (error) {
      console.error(`✗ Failed to send batch notifications:`, error);
    }
  }
}

