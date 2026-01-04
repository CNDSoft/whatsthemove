import * as admin from "firebase-admin";

export interface Notification {
  id: string;
  userId: string;
  type: string;
  title: string;
  message: string;
  actionText?: string;
  actionUrl?: string;
  eventId?: string;
  isRead: boolean;
  timestamp: admin.firestore.Timestamp;
  createdAt: admin.firestore.Timestamp;
}

export interface User {
  id: string;
  fcmToken?: string;
  timezone?: string;
  notificationPreferences: {
    eventRemindersEnabled: boolean;
    registrationDeadlinesEnabled: boolean;
    systemNotificationsEnabled: boolean;
    reminderWeekBefore: boolean;
    reminderDayBefore: boolean;
    reminder3Hours: boolean;
    reminderInterestedDayBefore: boolean;
  };
}

export interface ScheduledNotification {
  eventId: string;
  userId: string;
  scheduledReminders?: string[];
  registrationDeadlineSent?: boolean;
  lastChecked: admin.firestore.Timestamp;
}

export async function createNotification(
  notification: Notification
): Promise<void> {
  const db = admin.firestore();

  // Save to user's subcollection: users/{userId}/notifications/{notificationId}
  await db
    .collection("users")
    .doc(notification.userId)
    .collection("notifications")
    .doc(notification.id)
    .set(notification);

  console.log(`Created notification: ${notification.id} for user: ${notification.userId}`);
}

export async function getUser(userId: string): Promise<User | null> {
  const db = admin.firestore();
  const userDoc = await db.collection("users").doc(userId).get();

  if (!userDoc.exists) {
    console.log(`User ${userId} not found`);
    return null;
  }

  return { id: userDoc.id, ...userDoc.data() } as User;
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

export async function getScheduledNotification(
  userId: string,
  eventId: string
): Promise<ScheduledNotification | null> {
  const db = admin.firestore();
  const docId = `${userId}_${eventId}`;
  const doc = await db.collection("scheduledNotifications").doc(docId).get();

  if (!doc.exists) {
    return null;
  }

  return doc.data() as ScheduledNotification;
}

export async function updateScheduledNotification(
  userId: string,
  eventId: string,
  data: Partial<ScheduledNotification>
): Promise<void> {
  const db = admin.firestore();
  const docId = `${userId}_${eventId}`;
  await db.collection("scheduledNotifications").doc(docId).set(data, { merge: true });
  console.log(`Updated scheduled notification: ${docId}`);
}

