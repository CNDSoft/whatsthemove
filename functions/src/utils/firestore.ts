import * as admin from "firebase-admin";

export interface Notification {
  id: string;
  userId: string;
  type: string;
  title: string;
  message: string;
  actionText?: string;
  actionUrl?: string;
  isRead: boolean;
  timestamp: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
}

export async function createNotification(
  notification: Notification
): Promise<void> {
  const db = admin.firestore();
  await db.collection("notifications").doc(notification.id).set(notification);
  console.log(`Created notification: ${notification.id}`);
}

export async function getUserFcmToken(userId: string): Promise<string | null> {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) {
    console.log(`User ${userId} not found`);
    return null;
  }

  const userData = userDoc.data();
  return userData?.fcmToken || null;
}

