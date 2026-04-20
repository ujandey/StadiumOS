# StadiumOS — End-to-End Functional Build Plan

## Overview
StadiumOS is a Flutter mobile app (iOS + Android) backed by Google Cloud that transforms the live stadium experience through real-time intelligence. It is built on three pillars: Flow Oracle (crowd routing), Pulse Network (personalized alerts), and Squad Sync (group coordination). The technical foundation spans Firebase, BigQuery, Vertex AI, Pub/Sub, Dataflow, Cloud Run, and Google Maps Platform.

## PHASE 0 — Foundation (Weeks 1–4)

### Step 1: Flutter Project Setup (COMPLETE)
- Flutter 3.x, package name stadium_os
- Deps: provider, go_router, google_fonts, flutter_animate, shared_preferences, firebase_core, firebase_auth, firebase_database, cloud_firestore, firebase_messaging, google_maps_flutter, flutter_blue_plus
- Design system: AppColors (#0A0C10 bg, #00E5FF accent), AppTypography, AppTheme dark
- Folder structure: features/, core/, models/, services/

### Step 2: Google Cloud Infrastructure
- GCP project stadiumos-prod, enable all required APIs
- Firebase project: Auth (anonymous + Google), Firestore, RTDB, FCM
- BigQuery tables: venue_state, venue_forecast (both partitioned by date)
- Secret Manager for POS/ticketing credentials
- IAM service accounts with least-privilege roles

### Step 3: BigQuery Schema
- venue_state: event_id, venue_id, zone_id, section_id, timestamp, estimated_density, density_percentile, data_source
- venue_forecast: event_id, venue_id, zone_id, forecast_time, horizon_minutes, predicted_density, confidence

### Step 4: Simulated Sensor Data Generator
- Python script publishing 10,000 synthetic events/min to density-events Pub/Sub
- Simulates BLE, WiFi, turnstile, POS, game events for testing

## PHASE 1 — Venue Sensor Integration (Weeks 5–10)

### Step 5: Edge Gateway
- Google Distributed Cloud Edge nodes at venue network boundary
- BLE beacons (Estimote/Kontakt.io): RSSI -> anonymized zone count every 8s, no device IDs transmitted
- WiFi AP probe counting via Cisco Spaces / Aruba AIOps: zone count every 15s
- Pub/Sub publisher to density-events topic

### Step 6: POS and Ticketing Webhooks
- Appetize / Oracle MICROS webhook -> pos-events topic
- Turnstile REST webhook -> gate-events topic
- HMAC payload signing, retry/dead-letter queue

### Step 7: Dataflow Streaming Pipelines
- Pipeline A (density-aggregation): 8-second tumbling window per zone, enrich with venue metadata, write to BigQuery venue_state via Streaming Inserts (<1s latency)
- Pipeline B (event-enrichment): join gate/POS/game events with metadata, publish to alert-triggers topic

## PHASE 2 — Core Fan App (Weeks 5–12, parallel)

### Step 8: Onboarding Flow (COMPLETE - UI)
- Screen 1: QR scan (camera) OR 6-char event code -> anonymous Firebase Auth
- Screen 2: BLE section detection -> confirm Section/Row/Seat
- Screen 3: Squad join code OR create squad (skippable)
- Target: fully functional in under 30 seconds

### Step 9: Home Screen (COMPLETE - UI)
- Live score card from game-events -> Firestore current_game doc
- Top Pulse alert banner from Firestore fan_alerts collection
- Gemini timing window nudge from Vertex AI forecast
- Mini heatmap grid (8s refresh via FCM silent push)
- Quick actions: Route, Squad, Exit

### Step 10: Map Screen — Flow Oracle (COMPLETE - UI)
- Google Maps SDK Flutter with Indoor Maps floor plan overlay
- Real-time density heatmap: section-level, 8-second FCM silent push refresh
- BLE zone resolution -> pulsing You Are Here dot
- Layer toggles: Density / My Route / Squad
- Route calculation: POST /api/route -> Cloud Run -> Maps Indoor routing -> lowest-congestion path
- Dashed cyan route overlay with ETA bottom sheet

### Step 11: Pulse Screen (COMPLETE - UI)
- FCM foreground + background message handling
- Alert feed sorted by recency and urgency
- 4 alert type filters with per-category mute (stored in Firestore)
- Max 3 alerts/hour, min 15min gap per category (Cloud Run enforced)
- Alert detail modal with action button

### Step 12: Squad Screen — Squad Sync (COMPLETE - UI)
- Firebase RTDB node: squads/{joinCode}/members/{userId}/location (section precision, no GPS)
- Live squad map tab: section grid + member dots from RTDB
- Squad list tab: intent status + navigate-to
- Proposal card: majority vote -> Cloud Function -> routing directions to all agreers
- Rate limit: max 1 location write per 3 seconds client-side

### Step 13: Profile Screen (COMPLETE - UI)
- Seat info, alert category toggles, accessibility mode toggle
- Event history stats from Firestore
- Privacy and data section

## PHASE 3 — AI Layer (Weeks 11–16)

### Step 14: Gemini Prediction Model on Vertex AI
- Fine-tune Gemini 2.0 Flash on historical crowd flow + game event sequences
- Inputs: 18-zone density feature vector, game clock, recent events (goals/cards)
- Outputs: per-zone density forecast for T+2, T+5, T+10 minutes + confidence score
- Target: >75% accuracy on T+5 forecasts, <800ms inference P95
- Prediction Service (Cloud Run): polls BigQuery every 30s -> Vertex AI -> writes venue_forecast -> FCM delivery

### Step 15: Alert Generation Service (Cloud Run)
- Consumes alert-triggers Pub/Sub topic
- 4 trigger rules: queue drop (40% POS velocity drop in 60s), timing window, exit pre-alert (85th min), goal-while-away
- Firestore throttle state: last alert time per category per fan
- Gemini API prompt: fan_seat + stand_name + queue_estimate + game_clock -> first-person copy (max 12 words)
- FCM delivery via Firebase Admin SDK

### Step 16: Game Data Integration
- Sportradar Push API webhook -> Cloud Run -> game-events Pub/Sub
- Event types: goal, card, half-time, full-time, substitution
- Game clock normalization for all alert copy and prediction inputs

## PHASE 4 — Pilot Event (Weeks 17–18)

### Step 17: Integration Testing
- Load test 500 concurrent users
- Verify: <12s density latency, <500ms alert delivery, <100ms Squad Sync
- FCM fallback: 30s polling when no FCM message in 45s
- Vertex AI fallback: real-time density-only mode when endpoint unavailable
- Offline mode: last-known heatmap + squad positions on connectivity loss

### Step 18: Ops Dashboard
- BigQuery views over venue_state + venue_forecast
- Looker Studio: live heatmap, gate flow rates, queue indicators (30s refresh)
- Surge alerts: >80% capacity forecast in any zone -> ops team FCM
- Incident tagging: ops marks zone as incident -> route API excludes zone

## PHASE 5 — Scale and Iterate (Weeks 19–26)

### Step 19: Multi-Venue Deployment
- Venue onboarding checklist: floor plan GeoJSON, beacon install, POS webhook, ticketing webhook
- Maps Indoor floor plan upload per venue
- RTDB sharding: one Firebase RTDB database per venue
- Vertex AI model fine-tuning per venue (min 5 prior events of data)

### Step 20: PWA and Venue SDK
- Flutter Web PWA build as fallback for non-app users
- Venue SDK: Flutter plugin wrapping full StadiumOS features for white-label integration

### Step 21: Accessibility Mode (P1)
- Route API filter: accessible_only=true (elevators, ramps, wide concourses)
- Map overlay: distinct color for accessible routes
- WCAG 2.1 AA: 4.5:1 contrast, 44x44pt tap targets, VoiceOver/TalkBack semantic labels

## MVP Feature Status

| ID | Feature | Status |
|----|---------|--------|
| FA-01 | Onboarding under 30s, anonymous auth | UI Complete |
| FA-02 | Live venue heatmap 8s refresh | UI Complete |
| FA-03 | Seat entry and BLE section detection | UI Complete |
| FA-04 | Pulse alert delivery, history, mute | UI Complete |
| FA-05 | Flow Oracle routing lowest-congestion | UI Complete |
| FA-06 | Squad creation and joining | UI Complete |
| FA-07 | Squad live map RTDB under 100ms | UI Complete |
| FA-08 | Intent status broadcasting | UI Complete |
| FA-09 | Group proposal and majority vote routing | UI Complete |
| FA-10 | Exit routing 85th min (P1) | Backend pending |
| FA-11 | Accessibility mode (P1) | Backend pending |
| FA-12 | Offline mode (P1) | Backend pending |
| OD-01 | Ops live venue heatmap | Backend pending |
| OD-02 | Gate flow rates | Backend pending |
| OD-03 | Surge prediction alerts | Backend pending |
| OD-04 | Concession queue indicators | Backend pending |

## Next Steps to Make It Production-Ready

1. Run flutterfire configure and add Firebase SDK packages
2. Add google_maps_flutter with a valid Maps API key and Indoor Maps floor plan
3. Add flutter_blue_plus for real BLE section detection
4. Deploy Cloud Run alert service consuming Pub/Sub and calling Gemini API
5. Deploy Dataflow pipelines for density aggregation
6. Train Vertex AI Gemini fine-tune on historical venue crowd data
7. Replace all MockData calls with real Firestore listeners and FCM message handlers
8. Implement Firestore Security Rules and Firebase RTDB rules
9. Set up Sportradar webhook and game-events pipeline
10. Complete load testing at 50,000 concurrent user scale before live pilot event
