import * as admin from "firebase-admin";

admin.initializeApp();

export { sendNotificationToToken, testSendNotificationToToken } from "./notifications/sendToToken";
