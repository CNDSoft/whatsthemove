import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { Timestamp } from "firebase-admin/firestore";

admin.initializeApp();

export { helloWorld } from "./test";

export { sendNotificationToToken, testSendNotificationToToken } from "./notifications/sendToToken";

const DEFAULT_TIMEZONE = "America/New_York";

function getDateInTimezone(date: Date, timezone: string): Date {
  try {
    const formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
    });

    const parts = formatter.formatToParts(date);
    const getPart = (type: string) => parts.find((p) => p.type === type)?.value || "0";

    return new Date(
      parseInt(getPart("year")),
      parseInt(getPart("month")) - 1,
      parseInt(getPart("day")),
      parseInt(getPart("hour")),
      parseInt(getPart("minute")),
      parseInt(getPart("second"))
    );
  } catch (error) {
    console.log(`getDateInTimezone - Invalid timezone ${timezone}, using default`);
    return getDateInTimezone(date, DEFAULT_TIMEZONE);
  }
}

function getMidnightInTimezone(date: Date, timezone: string): Date {
  const localDate = getDateInTimezone(date, timezone);
  localDate.setHours(0, 0, 0, 0);
  return localDate;
}

function calculateDaysUntilInTimezone(
  nowUtc: Date,
  eventDateUtc: Date,
  timezone: string
): number {
  const nowLocal = getMidnightInTimezone(nowUtc, timezone);
  const eventLocal = getMidnightInTimezone(eventDateUtc, timezone);
  return Math.round((eventLocal.getTime() - nowLocal.getTime()) / (24 * 60 * 60 * 1000));
}

// Hours calculation uses UTC directly - no timezone conversion needed
function calculateHoursUntil(nowUtc: Date, eventDateUtc: Date): number {
  return (eventDateUtc.getTime() - nowUtc.getTime()) / (60 * 60 * 1000);
}

// Combines the DATE from eventDate with the TIME from startTime (both in UTC)
function combineEventDateWithStartTime(eventDate: Date, startTime: Date | null): Date {
  if (!startTime) {
    return eventDate;
  }

  // Use UTC methods to avoid any timezone conversion issues
  return new Date(Date.UTC(
    eventDate.getUTCFullYear(),
    eventDate.getUTCMonth(),
    eventDate.getUTCDate(),
    startTime.getUTCHours(),
    startTime.getUTCMinutes(),
    0
  ));
}

export const eventReminders = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("America/New_York")
  .onRun(async () => {
    console.log("EventReminders - Scheduled execution started");

    try {
      const db = admin.firestore();
      const now = Timestamp.now();
      const nowDate = now.toDate();

      // Use start of today (UTC) for query since eventDate time component is arbitrary
      // This is intentionally broad - precise filtering happens per-user with their timezone
      const startOfTodayUTC = new Date(Date.UTC(
        nowDate.getUTCFullYear(),
        nowDate.getUTCMonth(),
        nowDate.getUTCDate(),
        0, 0, 0, 0
      ));

      const oneWeekFromNow = new Date(nowDate.getTime() + 7 * 24 * 60 * 60 * 1000);

      console.log(`EventReminders - Query range: ${startOfTodayUTC.toISOString()} to ` +
        `${oneWeekFromNow.toISOString()}`);

      const eventsSnapshot = await db
        .collection("events")
        .where("eventDate", ">=", Timestamp.fromDate(startOfTodayUTC))
        .where("eventDate", "<=", Timestamp.fromDate(oneWeekFromNow))
        .get();

      console.log(`EventReminders - Found ${eventsSnapshot.size} upcoming events`);

      const { sendPushNotification } = await import("./utils/fcm");
      const { getUser, createNotification } = await import("./utils/firestore");

      let notificationsSent = 0;

      for (const eventDoc of eventsSnapshot.docs) {
        const event = { id: eventDoc.id, ...eventDoc.data() } as any;

        console.log(`EventReminders - Processing event: ${event.name} (${event.id})`);

        const user = await getUser(event.userId);
        if (!user) {
          console.log(`EventReminders - User not found for event ${event.id}`);
          continue;
        }

        const prefs = user.notificationPreferences || {
          eventRemindersEnabled: true,
          reminderWeekBefore: true,
          reminderDayBefore: true,
          reminder3Hours: true,
          reminderInterestedDayBefore: true,
        };

        if (!prefs.eventRemindersEnabled) {
          console.log(`EventReminders - Reminders disabled for user ${user.id}`);
          continue;
        }

        const eventDate = event.eventDate.toDate();
        const startTime = event.startTime ? event.startTime.toDate() : null;
        const nowDate = now.toDate();
        const userTimezone = user.timezone || DEFAULT_TIMEZONE;

        // Days calculation needs timezone for calendar day comparison
        const daysUntil = calculateDaysUntilInTimezone(nowDate, eventDate, userTimezone);

        // Hours calculation uses UTC directly - combine eventDate + startTime
        const effectiveStartDateTime = combineEventDateWithStartTime(eventDate, startTime);
        const hoursUntil = calculateHoursUntil(nowDate, effectiveStartDateTime);

        console.log(`EventReminders - timezone: ${userTimezone}, days: ${daysUntil}, ` +
          `hours: ${hoursUntil.toFixed(2)}, hasStartTime: ${!!startTime}`);

        // Skip events that have already passed
        if (hoursUntil < 0) {
          console.log(`EventReminders - Event ${event.id} has already passed, skipping`);
          continue;
        }

        let reminderType: string | null = null;
        let reminderText = "";
        let isEnabled = false;

        if (event.status === "Going") {
          if (daysUntil === 7 && prefs.reminderWeekBefore) {
            reminderType = "1week";
            reminderText = "in one week";
            isEnabled = true;
          } else if (daysUntil === 1 && prefs.reminderDayBefore) {
            reminderType = "1day";
            reminderText = "tomorrow";
            isEnabled = true;
          } else if (hoursUntil <= 3 && hoursUntil > 2 && prefs.reminder3Hours) {
            reminderType = "3hours";
            reminderText = "in 3 hours";
            isEnabled = true;
          }
        } else if (event.status === "Interested") {
          if (daysUntil === 1 && prefs.reminderInterestedDayBefore) {
            reminderType = "1day";
            reminderText = "tomorrow";
            isEnabled = true;
          }
        }

        if (reminderType && isEnabled) {
          const docId = `${event.userId}_${event.id}`;
          const scheduledNotifRef = db.collection("scheduledNotifications").doc(docId);

          try {
            const shouldSendNotification = await db.runTransaction(async (transaction) => {
              const scheduledDoc = await transaction.get(scheduledNotifRef);
              const scheduledData = scheduledDoc.exists ? scheduledDoc.data() : null;
              const sentReminders = scheduledData?.scheduledReminders || [];

              if (sentReminders.includes(reminderType)) {
                console.log(`EventReminders - ${reminderType} already sent for event ${event.id}`);
                return false;
              }

              const updatedReminders = [...sentReminders, reminderType];
              transaction.set(scheduledNotifRef, {
                eventId: event.id,
                userId: event.userId,
                scheduledReminders: updatedReminders,
                lastChecked: Timestamp.now(),
              }, { merge: true });

              return true;
            });

            if (!shouldSendNotification) {
              continue;
            }
          } catch (error) {
            console.error(`EventReminders - Transaction failed for event ${event.id}:`, error);
            continue;
          }

          console.log(`EventReminders - Sending ${reminderType} reminder for event ${event.id}`);

          const notificationId = `${event.id}_${reminderType}_${Date.now()}`;
          const notification = {
            id: notificationId,
            userId: user.id,
            type: "Event" as const,
            title: "Event Reminder",
            message: `${event.name} is ${reminderText}!`,
            actionText: "View Event",
            actionUrl: `/events/${event.id}`,
            eventId: event.id,
            isRead: false,
            timestamp: Timestamp.now(),
            createdAt: Timestamp.now(),
          };

          await createNotification(notification);

          if (user.fcmToken) {
            await sendPushNotification(user.fcmToken, {
              title: notification.title,
              body: notification.message,
              type: notification.type,
              eventId: event.id,
              notificationId: notificationId,
              actionUrl: notification.actionUrl,
            });
          }

          notificationsSent++;
          console.log(`EventReminders - ${reminderType} reminder sent for event ${event.id}`);
        }
      }

      console.log(`EventReminders - Completed. Sent ${notificationsSent} notifications`);
      return null;
    } catch (error: any) {
      console.error("EventReminders - Error:", error);
      throw error;
    }
  });

export const registrationDeadlines = functions.pubsub
  .schedule("every 6 hours")
  .timeZone("America/New_York")
  .onRun(async () => {
    console.log("RegistrationDeadlines - Scheduled execution started");

    try {
      const db = admin.firestore();
      const now = Timestamp.now();
      const threeDaysFromNow = new Date(now.toDate().getTime() + 3 * 24 * 60 * 60 * 1000);

      const eventsSnapshot = await db
        .collection("events")
        .where("requiresRegistration", "==", true)
        .get();

      const eventsWithUpcomingDeadlines = eventsSnapshot.docs.filter((doc) => {
        const data = doc.data();
        if (!data.registrationDeadline) return false;
        const deadline = data.registrationDeadline.toDate();
        return deadline >= now.toDate() && deadline <= threeDaysFromNow;
      });

      console.log(`RegistrationDeadlines - Found ${eventsWithUpcomingDeadlines.length} events with upcoming deadlines`);

      const { sendPushNotification } = await import("./utils/fcm");
      const { getUser, createNotification } = await import("./utils/firestore");

      let notificationsSent = 0;

      for (const eventDoc of eventsWithUpcomingDeadlines) {
        const event = { id: eventDoc.id, ...eventDoc.data() } as any;

        if (event.status === "Going" || event.status === "Interested") {
          const user = await getUser(event.userId);

          if (!user) {
            continue;
          }

          const prefs = user.notificationPreferences || {
            registrationDeadlinesEnabled: true,
          };

          if (!prefs.registrationDeadlinesEnabled) {
            continue;
          }

          const docId = `${event.userId}_${event.id}`;
          const scheduledNotifRef = db.collection("scheduledNotifications").doc(docId);

          try {
            const shouldSendNotification = await db.runTransaction(async (transaction) => {
              const scheduledDoc = await transaction.get(scheduledNotifRef);
              const scheduledData = scheduledDoc.exists ? scheduledDoc.data() : null;

              if (scheduledData?.registrationDeadlineSent) {
                console.log(`RegistrationDeadlines - Already sent for event ${event.id}`);
                return false;
              }

              transaction.set(scheduledNotifRef, {
                eventId: event.id,
                userId: event.userId,
                registrationDeadlineSent: true,
                lastChecked: Timestamp.now(),
              }, { merge: true });

              return true;
            });

            if (!shouldSendNotification) {
              continue;
            }
          } catch (error) {
            console.error(`RegistrationDeadlines - Transaction failed for event ${event.id}:`, error);
            continue;
          }

          const registrationDeadline = event.registrationDeadline.toDate();
          const nowDate = now.toDate();
          const userTimezone = user.timezone || DEFAULT_TIMEZONE;

          const daysUntilDeadline = calculateDaysUntilInTimezone(nowDate, registrationDeadline, userTimezone);

          console.log(`RegistrationDeadlines - User timezone: ${userTimezone}, Event ${event.id}: ${daysUntilDeadline} days until deadline`);

          const deadlineText =
            daysUntilDeadline === 0 ? "today" :
              daysUntilDeadline === 1 ? "tomorrow" :
                `in ${daysUntilDeadline} days`;

          const notificationId = `${event.id}_registration_${Date.now()}`;
          const notification = {
            id: notificationId,
            userId: user.id,
            type: "Deadline" as const,
            title: "Registration Deadline",
            message: `Registration for ${event.name} closes ${deadlineText}!`,
            actionText: "Register Now",
            actionUrl: event.urlLink || `/events/${event.id}`,
            eventId: event.id,
            isRead: false,
            timestamp: Timestamp.now(),
            createdAt: Timestamp.now(),
          };

          await createNotification(notification);

          if (user.fcmToken) {
            await sendPushNotification(user.fcmToken, {
              title: notification.title,
              body: notification.message,
              type: notification.type,
              eventId: event.id,
              notificationId: notificationId,
              actionUrl: notification.actionUrl,
            });
          }

          notificationsSent++;
          console.log(`RegistrationDeadlines - Sent notification for event ${event.id}`);
        }
      }

      console.log(`RegistrationDeadlines - Completed. Sent ${notificationsSent} notifications`);
      return null;
    } catch (error: any) {
      console.error("RegistrationDeadlines - Error:", error);
      throw error;
    }
  });
