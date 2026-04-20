# StadiumOS

StadiumOS is an ambient intelligence platform that transforms large-scale sporting venues into responsive, fan-aware environments. Built on Google Cloud and powered by Gemini 2.0, StadiumOS acts as the nervous system for stadiums—predicting crowd flow, preventing congestion, and keeping fan groups coordinated in real-time.

## 🎯 Chosen Vertical
**Smart Venues & Ambient Intelligence (Sports & Entertainment)**
Traditional venue apps offer static maps and basic schedules. StadiumOS creates a proactive, real-time intelligence layer over the venue using IoT sensor data, game-clock context, and Gemini-powered prediction. 

## 🧠 Approach and Logic
Our approach is guided by the principle of **"Proactive over Reactive"**. Fans do not want to manage dashboards or interpret heatmaps while trying to enjoy a game. 

1. **Flow Oracle (Spatial Intelligence):** Instead of telling a fan a concession stand is busy *now*, we use predictive modeling to identify that the stand *will* be busy in 5 minutes based on the game clock and crowd momentum.
2. **Pulse Network (Contextual Intelligence):** Alerts are generated based on hyper-local triggers (e.g., POS queue velocity dropping) and fed to Gemini to generate accessible, first-person, conversational nudges.
3. **Squad Sync (Social Intelligence):** Group coordination is moved out of chaotic text threads and onto a live spatial map synced via Firebase Realtime Database in sub-100ms latency.

## ⚙️ How the Solution Works
StadiumOS relies on a highly decoupled, cloud-native architecture:

1. **The Edge (Data Ingestion):** Anonymized BLE beacon and Wi-Fi probe counts estimate zone density. Turnstile and POS transaction webhooks provide queue velocity and exit rate data.
2. **The Brain (Google Cloud & Gemini):** 
   - A Node.js Express service (designed for Cloud Run) consumes Pub/Sub triggers representing venue events.
   - It performs a rate-limiting check against Firestore to prevent alert fatigue.
   - It invokes the `@google/genai` (Gemini 2.5 Flash) API to generate concise, 12-word conversational alerts based on the trigger context.
   - It pushes these alerts to the fan's device via Firebase Cloud Messaging (FCM).
3. **The App (Flutter Client):** A responsive, beautiful Flutter app that provides a live heatmap, tracks Squad members via Firebase RTDB, and receives predictive Pulse alerts. 

## 📝 Assumptions Made
1. **Sensor Availability:** We assume the venue operator can provide basic anonymized zone counts (either via existing Cisco/Aruba Wi-Fi or a StadiumOS-provided BLE beacon mesh).
2. **Privacy by Default:** We assume fans will only adopt the app if it requires zero PII. The app relies exclusively on Firebase Anonymous Authentication.
3. **Connectivity:** Large venues are notorious for poor cellular reception. We assume a baseline latency where Firebase RTDB WebSockets can survive, and we employ graceful degradation (local cache fallbacks) when offline.

## 🛠️ Tech Stack
- **AI**: Google Gemini 2.0 (`gemini-2.5-flash`) via `@google/genai`
- **Backend**: Node.js, Express, TypeScript, Jest
- **Cloud Infrastructure**: Google Cloud Pub/Sub, Cloud Run, Firebase Admin SDK
- **Real-Time Data**: Firebase Firestore, Firebase Realtime Database
- **Client App**: Flutter (iOS & Android)
