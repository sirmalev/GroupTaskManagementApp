// This Firebase Cloud Functions script sends a Firebase Cloud Messaging (FCM) notification
// to a specified device token using the Firebase Admin SDK.

const functions = require("firebase-functions");
const request = require("request");

// Firebase Server Key
const SERVER_KEY =
  "AAAATDlN2Hs:APA91bE_FWaOEPvCF_SZeglbeNSLbWmNyFnEfTkr_QBpqZTSRQjFWGP6iJ-tNih4n1D297k2QHm5dITAIfaImTLrQXVuH3iNBi9P57INrHcgweqhXUBrA8o6rjgysbWFnPk8ZEfcWldJ";

// Define the Firebase Cloud Function that sends FCM notifications
exports.sendFCMNotification = functions.https.onCall((data, context) => {
  // Extract data from the request
  const toToken = data.toToken; // Device token to send the notification to
  const title = data.title; // Notification title
  const body = data.body; // Notification body

  // Define the HTTP request options
  const options = {
    uri: "https://fcm.googleapis.com/fcm/send",
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: "key=" + SERVER_KEY, // Include your server key here
    },
    json: {
      to: toToken, // Target device token
      notification: {
        title: title, // Notification title
        body: body, // Notification body
      },
      data: {
        // You can add custom data here if needed
      },
    },
  };

  // Send the FCM notification
  return new Promise((resolve, reject) => {
    request(options, (error, response, body) => {
      if (error) {
        console.error("Error sending notification:", error);
        reject(error);
      } else {
        console.log("Notification sent:", body);
        resolve(body);
      }
    });
  });
});
