import * as functions from "firebase-functions";
import { sendPushNotification, sendBatchPushNotifications } from "../utils/fcm";

interface SendNotificationRequest {
  fcmToken?: string;
  fcmTokens?: string[];
  title: string;
  body: string;
  type?: string;
  eventId?: string;
  actionUrl?: string;
}

export const sendNotificationToToken = functions.https.onCall(
  async (data: SendNotificationRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to send notifications"
      );
    }

    const { fcmToken, fcmTokens, title, body, type, eventId, actionUrl } = data;

    if (!title || !body) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Title and body are required"
      );
    }

    if (!fcmToken && (!fcmTokens || fcmTokens.length === 0)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "At least one FCM token is required"
      );
    }

    const notificationPayload = {
      title,
      body,
      type: (type || "General") as "Event" | "Deadline" | "Registration" | "General",
      notificationId: `notification_${Date.now()}`,
      eventId,
      actionUrl,
    };

    try {
      if (fcmToken) {
        await sendPushNotification(fcmToken, notificationPayload);
        return {
          success: true,
          message: "Notification sent successfully",
          tokensSent: 1,
        };
      } else if (fcmTokens) {
        await sendBatchPushNotifications(fcmTokens, notificationPayload);
        return {
          success: true,
          message: "Batch notifications sent successfully",
          tokensSent: fcmTokens.length,
        };
      }

      throw new functions.https.HttpsError(
        "invalid-argument",
        "No valid FCM tokens provided"
      );
    } catch (error) {
      console.error("Error sending notification:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification",
        error
      );
    }
  }
);

export const testSendNotificationToToken = functions.https.onRequest(
  async (req, res) => {
    console.log("Test endpoint for sending notification to FCM token");

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    const { fcmToken, fcmTokens, title, body, type, eventId, actionUrl } = req.body;

    if (!title || !body) {
      res.status(400).json({
        success: false,
        error: "Title and body are required",
      });
      return;
    }

    if (!fcmToken && (!fcmTokens || fcmTokens.length === 0)) {
      res.status(400).json({
        success: false,
        error: "At least one FCM token is required (fcmToken or fcmTokens array)",
      });
      return;
    }

    const notificationPayload = {
      title,
      body,
      type: (type || "General") as "Event" | "Deadline" | "Registration" | "General",
      notificationId: `test_notification_${Date.now()}`,
      eventId,
      actionUrl,
    };

    try {
      let tokensSent = 0;

      if (fcmToken) {
        await sendPushNotification(fcmToken, notificationPayload);
        tokensSent = 1;
      } else if (fcmTokens && Array.isArray(fcmTokens)) {
        await sendBatchPushNotifications(fcmTokens, notificationPayload);
        tokensSent = fcmTokens.length;
      }

      res.status(200).json({
        success: true,
        message: "Notification(s) sent successfully",
        tokensSent,
        payload: notificationPayload,
      });
    } catch (error: any) {
      console.error("Error sending notification:", error);
      res.status(500).json({
        success: false,
        error: error.message || String(error),
      });
    }
  }
);

