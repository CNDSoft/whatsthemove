import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { Timestamp } from "firebase-admin/firestore";

admin.initializeApp();

export { sendNotificationToToken, testSendNotificationToToken } from "./notifications/sendToToken";

export const testEventReminders = functions.https.onRequest(async (req, res) => {
  console.log("Manual trigger for testEventReminders");
  
  try {
    const db = admin.firestore();
    const now = Timestamp.now();
    const oneWeekFromNow = new Date(now.toDate().getTime() + 7 * 24 * 60 * 60 * 1000);
    
    console.log("Starting event reminders check...");
    
    const eventsSnapshot = await db
      .collection("events")
      .where("eventDate", ">=", now)
      .where("eventDate", "<=", Timestamp.fromDate(oneWeekFromNow))
      .get();
    
    console.log(`Found ${eventsSnapshot.size} upcoming events`);
    
    const { sendPushNotification } = await import("./utils/fcm");
    const { getUser, createNotification, getScheduledNotification, updateScheduledNotification } = await import("./utils/firestore");
    
    let notificationsSent = 0;
    
    for (const eventDoc of eventsSnapshot.docs) {
      const event = { id: eventDoc.id, ...eventDoc.data() } as any;
      
      console.log(`\n--- Processing event: ${event.name} (${event.id}) ---`);
      console.log(`   Status: ${event.status}`);
      console.log(`   Event Date: ${event.eventDate?.toDate()}`);
      
      const user = await getUser(event.userId);
      if (!user) {
        console.log(`   ❌ User not found for event ${event.id}`);
        continue;
      }
      
      console.log(`   User: ${user.id} (FCM: ${user.fcmToken ? 'Yes' : 'No'})`);
      
      // Default notification preferences to true if not set
      const prefs = user.notificationPreferences || {
        eventRemindersEnabled: true,
        reminderWeekBefore: true,
        reminderDayBefore: true,
        reminder3Hours: true,
        reminderInterestedDayBefore: true,
      };
      
      if (!prefs.eventRemindersEnabled) {
        console.log(`   ❌ Event reminders disabled for user ${user.id}`);
        continue;
      }
      
      const eventDate = event.eventDate.toDate();
      const scheduledData = await getScheduledNotification(event.userId, event.id);
      const sentReminders = scheduledData?.scheduledReminders || [];
      
      console.log(`   Sent reminders: ${sentReminders.length > 0 ? sentReminders.join(', ') : 'none'}`);
      
      const timeDiff = eventDate.getTime() - now.toDate().getTime();
      const daysUntil = timeDiff / (24 * 60 * 60 * 1000);
      const hoursUntil = timeDiff / (60 * 60 * 1000);
      
      console.log(`   Time until event: ${daysUntil.toFixed(2)} days (${hoursUntil.toFixed(2)} hours)`);
      
      let reminderType: string | null = null;
      let reminderText = "";
      let isEnabled = false;
      
      if (event.status === "Going") {
        console.log(`   Checking reminders for "Going" status...`);
        if (daysUntil <= 7 && daysUntil > 6) {
          console.log(`      1 week check: ${!sentReminders.includes("1week") ? 'not sent' : 'already sent'}, enabled: ${prefs.reminderWeekBefore}`);
          if (!sentReminders.includes("1week") && prefs.reminderWeekBefore) {
            reminderType = "1week";
            reminderText = "in one week";
            isEnabled = true;
          }
        } else if (daysUntil <= 1 && daysUntil > 0.8) {
          console.log(`      1 day check: ${!sentReminders.includes("1day") ? 'not sent' : 'already sent'}, enabled: ${prefs.reminderDayBefore}`);
          if (!sentReminders.includes("1day") && prefs.reminderDayBefore) {
            reminderType = "1day";
            reminderText = "tomorrow";
            isEnabled = true;
          }
        } else if (hoursUntil <= 3 && hoursUntil > 2) {
          console.log(`      3 hours check: ${!sentReminders.includes("3hours") ? 'not sent' : 'already sent'}, enabled: ${prefs.reminder3Hours}`);
          if (!sentReminders.includes("3hours") && prefs.reminder3Hours) {
            reminderType = "3hours";
            reminderText = "in 3 hours";
            isEnabled = true;
          }
        } else {
          console.log(`      ⏭  No reminder window matched (not 7 days, 1 day, or 3 hours before)`);
        }
      } else if (event.status === "Interested") {
        console.log(`   Checking reminders for "Interested" status...`);
        if (daysUntil <= 1 && daysUntil > 0.8) {
          console.log(`      1 day check: ${!sentReminders.includes("1day") ? 'not sent' : 'already sent'}, enabled: ${prefs.reminderInterestedDayBefore}`);
          if (!sentReminders.includes("1day") && prefs.reminderInterestedDayBefore) {
            reminderType = "1day";
            reminderText = "tomorrow";
            isEnabled = true;
          }
        } else {
          console.log(`      ⏭  Not within 1 day window`);
        }
      } else {
        console.log(`   ⏭  Status "${event.status}" - skipping (not Going or Interested)`);
      }
      
      if (reminderType && isEnabled) {
        console.log(`   ✅ Sending ${reminderType} reminder for event ${event.id}`);
        
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
        
        sentReminders.push(reminderType);
        await updateScheduledNotification(user.id, event.id, {
          eventId: event.id,
          userId: user.id,
          scheduledReminders: sentReminders,
          lastChecked: Timestamp.now(),
        });
        
        notificationsSent++;
        console.log(`   ✅ ${reminderType} reminder sent successfully for event ${event.id}`);
      } else if (!reminderType) {
        console.log(`   ⏭  No reminder to send at this time`);
      }
    }
    
    console.log("Event reminders check completed");
    
    res.status(200).json({
      success: true,
      message: "Event reminders check executed successfully",
      eventsChecked: eventsSnapshot.size,
      notificationsSent,
    });
  } catch (error: any) {
    console.error("Error executing event reminders:", error);
    res.status(500).json({
      success: false,
      error: error.message || String(error),
    });
  }
});

export const testRegistrationDeadlines = functions.https.onRequest(async (req, res) => {
  console.log("Manual trigger for testRegistrationDeadlines");
  
  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const threeDaysFromNow = new Date(now.toDate().getTime() + 3 * 24 * 60 * 60 * 1000);
    
    const eventsSnapshot = await db
      .collection("events")
      .where("requiresRegistration", "==", true)
      .where("registrationDeadline", ">=", now)
      .where("registrationDeadline", "<=", admin.firestore.Timestamp.fromDate(threeDaysFromNow))
      .get();
    
    console.log(`Found ${eventsSnapshot.size} events with upcoming registration deadlines`);
    
    const { sendPushNotification } = await import("./utils/fcm");
    const { getUser, createNotification, getScheduledNotification, updateScheduledNotification } = await import("./utils/firestore");
    
    let notificationsSent = 0;
    
    for (const eventDoc of eventsSnapshot.docs) {
      const event = { id: eventDoc.id, ...eventDoc.data() } as any;
      
      if (event.status === "Going" || event.status === "Interested") {
        const user = await getUser(event.userId);
        
        if (!user) {
          continue;
        }
        
        // Default notification preferences to true if not set
        const prefs = user.notificationPreferences || {
          registrationDeadlinesEnabled: true,
        };
        
        if (!prefs.registrationDeadlinesEnabled) {
          continue;
        }
        
        const scheduledData = await getScheduledNotification(event.userId, event.id);
        if (scheduledData?.registrationDeadlineSent) {
          console.log(`Registration deadline already sent for event ${event.id}`);
          continue;
        }
        
        const registrationDeadline = event.registrationDeadline.toDate();
        const daysUntilDeadline = Math.ceil(
          (registrationDeadline.getTime() - now.toDate().getTime()) / (24 * 60 * 60 * 1000)
        );
        
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
        
        await updateScheduledNotification(user.id, event.id, {
          eventId: event.id,
          userId: user.id,
          registrationDeadlineSent: true,
          lastChecked: admin.firestore.Timestamp.now(),
        });
        
        notificationsSent++;
        console.log(`Registration deadline notification sent for event ${event.id}`);
      }
    }
    
    res.status(200).json({
      success: true,
      message: "Registration deadlines check executed successfully",
      eventsChecked: eventsSnapshot.size,
      notificationsSent,
    });
  } catch (error: any) {
    console.error("Error executing registration deadlines:", error);
    res.status(500).json({
      success: false,
      error: error.message || String(error),
    });
  }
});
