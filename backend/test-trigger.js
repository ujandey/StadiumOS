// Script to test the end-to-end flow locally
const fetch = require('node-fetch'); // Ensure node-fetch is installed or use native fetch if Node 18+

// 1. Replace this with the UID from your Flutter app (Look at Firestore 'fans' collection)
const TEST_UID = "REPLACE_WITH_YOUR_UID";

async function runTest() {
  if (TEST_UID === "REPLACE_WITH_YOUR_UID") {
    console.error("Please update TEST_UID in test-trigger.js with the uid of your logged-in app user.");
    return;
  }

  const payload = {
    uid: TEST_UID,
    triggerType: "Queue Drop",
    location: "Section 112 Food Stand",
    context: "Wait time dropped to 3 minutes"
  };

  // Convert payload to base64 to simulate Pub/Sub behavior
  const base64Data = Buffer.from(JSON.stringify(payload)).toString('base64');

  const pubSubMessage = {
    message: {
      data: base64Data,
      messageId: "12345",
      publishTime: new Date().toISOString()
    }
  };

  console.log(`Sending simulated Pub/Sub event to backend for UID: ${TEST_UID}...`);

  try {
    const response = await fetch('http://localhost:8080/api/alerts/pubsub', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pubSubMessage)
    });

    const result = await response.text();
    console.log(`Backend Response [${response.status}]: ${result}`);
  } catch (error) {
    console.error("Failed to reach backend:", error);
  }
}

runTest();
