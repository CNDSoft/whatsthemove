import * as functions from "firebase-functions";

export const helloWorld = functions.https.onRequest((req, res) => {
  res.json({
    message: "Hello from Firebase Functions!",
    timestamp: new Date().toISOString(),
  });
});

