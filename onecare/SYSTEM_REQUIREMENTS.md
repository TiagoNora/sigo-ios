# System Requirements Specification
## SIGO OneCare Firebase Notification Service

---

## 1. System Overview

### 1.1 Purpose
The SIGO OneCare Firebase Notification Service is a backend microservice designed to automatically deliver push notifications to mobile devices based on ticket system events. The system consumes ticket events from Kafka and sends notifications via Firebase Cloud Messaging (FCM) to registered users.

### 1.2 Architecture Overview
The system operates with an **event-driven architecture**:
1. **Mobile app** registers device tokens with backend (one-time on login)
2. **Kafka consumer** listens to ticket (TTK) events in real-time
3. **Backend automatically** sends push notifications when ticket events occur
4. **No manual notification API calls** required from the mobile app

### 1.3 Scope
This system provides:
- Automated push notification delivery via Firebase Cloud Messaging based on Kafka events
- Device token registration for mobile apps
- User-to-token mapping for targeted notifications
- Kafka event consumption from ticket tracking system (TTK)

---

## 2. Core Functional Requirements

### 2.1 Primary Mobile App Integration

#### FR-1: Register Device Token with Language Preference (REQUIRED FOR APP)
**Priority**: Critical
**Description**: Mobile apps must register their FCM device token along with user's language preference to receive translated notifications.

**Acceptance Criteria**:
- Accept userId, deviceToken, and language preference as input
- Store token-user mapping with language preference in persistent storage
- Support token update if the same token is re-registered (upsert operation)
- Store registration timestamp for audit purposes
- Validate that userId, deviceToken, and language are non-empty
- Default to 'en' if language is not provided

**API Endpoint**: `POST /api/tokens/register`

**Request Schema**:
```json
{
  "userId": "string (required)",
  "deviceToken": "string (required)",
  "language": "string (required - ISO 639-1 code: en, pt, es, fr, etc.)"
}
```

**Response Schema**:
```json
{
  "message": "Device token registered successfully",
  "userId": "string",
  "deviceToken": "string",
  "language": "string"
}
```

**Mobile App Integration**:
```dart
// Flutter example - called once on user login
Future<void> registerDeviceToken(String userId) async {
  final token = await FirebaseMessaging.instance.getToken();

  // Get device language
  final deviceLanguage = PlatformDispatcher.instance.locale.languageCode;

  final response = await http.post(
    Uri.parse('${backendUrl}/api/tokens/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'deviceToken': token,
      'language': deviceLanguage,  // "pt", "en", "es", etc.
    }),
  );
}
```

#### FR-2: Token Refresh Handling (REQUIRED FOR APP)
**Priority**: High
**Description**: Mobile apps must re-register tokens when Firebase refreshes them, maintaining user's language preference.

**Acceptance Criteria**:
- Listen to Firebase token refresh events
- Automatically call register endpoint with new token
- Use same userId and language preference to maintain user settings

**Mobile App Integration**:
```dart
// Flutter example - handle token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  final currentLanguage = await getStoredLanguagePreference();
  await registerDeviceToken(currentUserId, currentLanguage);
});
```

#### FR-2.1: Update Language Preference (REQUIRED FOR APP)
**Priority**: High
**Description**: Mobile apps must update the backend when user changes their language preference in app settings.

**Acceptance Criteria**:
- Accept userId, deviceToken, and new language preference
- Update language preference in database for the specific device token
- Allow users to change language independent of device settings
- Validate language code against supported languages

**API Endpoint**: `PUT /api/tokens/update-language`

**Request Schema**:
```json
{
  "userId": "string (required)",
  "deviceToken": "string (required)",
  "language": "string (required - ISO 639-1 code: en, pt, es, fr, etc.)"
}
```

**Response Schema**:
```json
{
  "message": "Language updated successfully",
  "userId": "string",
  "language": "string"
}
```

**Mobile App Integration**:
```dart
// Flutter example - called when user changes language in settings
Future<void> updateLanguagePreference(String userId, String newLanguage) async {
  final token = await FirebaseMessaging.instance.getToken();

  final response = await http.put(
    Uri.parse('${backendUrl}/api/tokens/update-language'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': userId,
      'deviceToken': token,
      'language': newLanguage,  // "pt", "en", "es", etc.
    }),
  );

  if (response.statusCode == 200) {
    // Update app locale
    await context.setLocale(Locale(newLanguage));
  }
}
```

### 2.2 Automated Notification Processing (Core System Function)

#### FR-3: Consume TTK Events from Kafka
**Priority**: Critical
**Description**: The system shall automatically consume ticket events from Kafka and send notifications to relevant users based on their relationship to the ticket, excluding the user who performed the action.

**Acceptance Criteria**:
- Connect to Kafka broker at configured address
- Subscribe to topic "sigo-ttk"
- Process messages with schema "TTK"
- Extract ticket information (id, name, status, changes, creator, action performer, assigned teams)
- **Apply notification filtering rules** (see FR-3.1 below)
- Build notification title from ticket ID and event type
- Build notification body from ticket changes (field changes, notes, status)
- Include ticket metadata in notification data payload
- Handle failed notifications by removing invalid tokens
- Run on virtual threads for efficient concurrency
- **No manual trigger required** - fully automated based on Kafka events

#### FR-3.1: Notification Filtering Rules
**Priority**: Critical
**Description**: The system must apply intelligent filtering to determine which users receive notifications for each ticket event.

**Filtering Logic**:

1. **User Eligibility** - A user receives a notification if ANY of these conditions are true:
   - User is a member of a team assigned to the ticket
   - User is the creator of the ticket
   - User is explicitly assigned to the ticket

2. **Self-Action Exclusion** - A user does NOT receive a notification if:
   - The user is the one who performed the action that triggered the event
   - Example: If Alice updates a ticket, Alice should not receive a notification about her own update

3. **Combined Rule**:
   ```
   SEND notification IF:
     (user in ticket.teams OR user == ticket.creator OR user in ticket.assignees)
     AND
     user != event.performedBy
   ```

**Examples**:

| Scenario | Ticket Creator | Assigned Team | Action By | Who Gets Notified |
|----------|---------------|---------------|-----------|-------------------|
| Alice creates ticket TKT-1 | Alice | Team A | Alice | Team A members (except Alice) |
| Bob updates TKT-1 status | Alice | Team A | Bob | Alice + Team A members (except Bob) |
| Carol adds note to TKT-1 | Alice | Team A | Carol | Alice + Team A members (except Carol) |
| TKT-2 assigned to Team B | Dave | Team B | Dave | Team B members (except Dave) |
| Alice reassigns TKT-1 to Team B | Alice | Team A → Team B | Alice | Team B members (except Alice) |

**Kafka Configuration**:
- Bootstrap servers: 10.113.140.101:30140
- Topic: sigo-ttk
- Deserializer: StringDeserializer
- Channel: ttk-in

**Expected Kafka Message Schema**:
```json
{
  "header": {
    "schema": "TTK",
    "eventType": "created|updated|closed|...",
    "performedBy": "string (userId who performed the action)"
  },
  "data": {
    "value": {
      "id": "string",
      "name": "string",
      "status": "string",
      "createdBy": "string (userId of ticket creator)",
      "assignedTeams": ["string (team IDs or names)"],
      "assignedUsers": ["string (userIds explicitly assigned)"]
    },
    "changes": [
      {
        "type": "FieldChange|Note",
        "fieldName": "string",
        "oldValue": "string",
        "newValue": "string"
      }
    ]
  }
}
```

**Required Fields for Notification Filtering**:
- `header.performedBy`: UserId of the person who performed the action (to exclude from notifications)
- `data.value.createdBy`: UserId of the ticket creator (eligible for notifications)
- `data.value.assignedTeams`: Array of team IDs/names assigned to the ticket
- `data.value.assignedUsers`: Array of userIds explicitly assigned to the ticket (optional)

#### FR-3.2: Language Grouping and Server-Side Translation
**Priority**: Critical
**Description**: The system shall group eligible users by their language preference and send translated notifications to ensure users receive notifications in their preferred language even when the app is terminated.

**Translation Logic**:

1. **After filtering eligible users**, group them by stored language preference
2. **For each language group**, translate notification content to that language
3. **Send one multicast notification** per language group with pre-translated content
4. **Users receive notifications** in their language even when app is completely closed

**Implementation Steps**:
```
1. Determine eligible users (filtering rules from FR-3.1)
   Result: {alice, bob, charlie, dave}

2. Query language preferences and group tokens by language
   Result: {
     "pt": [token1, token2, token4],  // alice, dave
     "en": [token3],                   // bob
     "es": [token5, token6]           // charlie
   }

3. For each language group:
   a. Translate title: translate("ticket.updated", "pt", ticketId)
      → "Ticket TKT-123 atualizado"

   b. Translate body: translate changes to Portuguese
      → "Estado: Novo → Em Progresso"

   c. Send multicast to all tokens in this language group
      sendMulticastNotification([token1, token2, token4], title_pt, body_pt, data)

4. Repeat for each language
   - Portuguese group receives Portuguese notification
   - English group receives English notification
   - Spanish group receives Spanish notification
```

**Supported Languages** (Minimum Requirement):
- `en` - English
- `pt` - Portuguese
- `es` - Spanish
- `fr` - French (optional)

**Translation Keys**:
```java
// Title translations
"ticket.created" → "Ticket {0} created" / "Ticket {0} criado" / "Ticket {0} creado"
"ticket.updated" → "Ticket {0} updated" / "Ticket {0} atualizado" / "Ticket {0} actualizado"
"ticket.closed" → "Ticket {0} closed" / "Ticket {0} fechado" / "Ticket {0} cerrado"

// Body translations
"field.changed" → "{0}: {1} → {2}"
"note.added" → "Note added" / "Nota adicionada" / "Nota añadida"
"status.label" → "Status" / "Estado" / "Estado"
```

**Efficiency**:
- Instead of N notifications (one per user), send M notifications (one per language)
- Example: 100 users in 3 languages = 3 FCM calls instead of 100

**Automated Notification Format** (Translated):
- Title: Translated based on language ("Ticket TKT-123 atualizado" for Portuguese)
- Body: Translated changes ("Estado: Novo → Em Progresso" for Portuguese)
- Data payload (same for all languages):
  - `ticketId`: Ticket identifier
  - `eventType`: Event type
  - `changes`: Serialized JSON array of changes

**Example Notification Sent**:
```json
{
  "title": "Ticket TKT-12345 updated",
  "body": "status: New → In Progress | Priority updated",
  "data": {
    "ticketId": "TKT-12345",
    "changes": "[{\"type\":\"FieldChange\",\"fieldName\":\"status\",\"oldValue\":\"New\",\"newValue\":\"In Progress\"}]"
  }
}
```

#### FR-4: User-Team Membership Resolution
**Priority**: Critical
**Description**: The system must be able to resolve which users belong to each team to properly filter notification recipients.

**Acceptance Criteria**:
- Maintain mapping of team IDs to user IDs
- Support querying all users in a given team
- Support multiple teams per user


#### FR-5: Invalid Token Cleanup
**Priority**: High
**Description**: When notification delivery fails due to invalid or expired tokens, the system shall automatically remove those tokens from storage.

**Acceptance Criteria**:
- Detect failed notification results from Firebase
- Identify tokens that caused failures (invalid, unregistered, expired)
- Automatically unregister failed tokens
- Log warnings for failed token deliveries
- Prevent repeated attempts to invalid tokens

---

## 3. System Flow Diagram

```
┌─────────────────┐
│  Mobile App     │
│  (Flutter)      │
└────────┬────────┘
         │
         │ 1. On Login: POST /api/tokens/register
         │    { userId: "user123",
         │      deviceToken: "fcm-token-xyz",
         │      language: "pt" }
         ▼
┌────────────────────────────────────────────────────────────────────────┐
│  Backend Service                                                       │
│  ┌──────────────────────────────┐  ┌────────────────────────────┐     │
│  │ TokenStorageService          │  │ UserTeamService            │     │
│  │ (SQLite)                     │  │ Resolves team membership   │     │
│  │ Stores: user → token +       │  │                            │     │
│  │         language mapping     │  │                            │     │
│  └──────────────────────────────┘  └────────────────────────────┘     │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐    │
│  │ KafkaNotificationConsumer                                     │◄───┼─ 2. Kafka: sigo-ttk
│  │ Listens to TTK events                                         │    │    { ticket event }
│  └───────┬───────────────────────────────────────────────────────┘    │
│          │                                                             │
│          │ 3. On event received:                                      │
│          │    a) Extract: createdBy, assignedTeams,                   │
│          │                assignedUsers, performedBy                   │
│          │    b) Determine eligible users (filtering):                │
│          │       - Get all users in assignedTeams                     │
│          │       - Add createdBy user                                 │
│          │       - Add assignedUsers                                  │
│          │       - Remove performedBy user (no self-notify)           │
│          │    c) Group users by language preference:                  │
│          │       - Query tokens with languages                        │
│          │       - Group: {"pt": [tokens], "en": [tokens]}           │
│          │    d) For EACH language group:                             │
│          │       - Translate title & body to that language            │
│          │       - Send multicast to language group                   │
│          ▼                                                             │
│  ┌──────────────────────────────┐  ┌─────────────────────────────┐   │
│  │ TranslationService           │  │ FirebaseService             │   │
│  │ Translates notifications     │→ │ Sends to language groups    │   │
│  │ (en, pt, es, fr)            │  │ One multicast per language  │   │
│  └──────────────────────────────┘  └───────┬─────────────────────┘   │
└────────────────────────────────────────────┼───────────────────────────┘
                                             │
                                             │ 4. Push notifications via FCM
                                             │    (translated per language)
                                             ▼
                            ┌────────────────────────────────┐
                            │  Mobile Devices                │
                            │  ──────────────────────────── │
                            │  PT device: "Ticket atualizado"│
                            │  EN device: "Ticket updated"   │
                            │  ES device: "Ticket actualizado"│
                            └────────────────────────────────┘
```

**Key Points**:
- Mobile app **registers token WITH language** preference (step 1)
- Kafka events **automatically trigger** notifications (steps 2-4)
- **Intelligent filtering** ensures only relevant users are notified
- **No self-notifications** - users don't get notified of their own actions
- **Team-based targeting** - notifications go to all team members
- **Language grouping** - users grouped by language for efficient translation
- **Server-side translation** - each language group receives pre-translated notifications
- **Works when app closed** - notifications arrive already translated

---


## 4. Technical Architecture

### 4.1 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Runtime | Java | 21 |
| Framework | Quarkus | 3.30.4 |
| Push Notifications | Firebase Admin SDK | 9.4.1 |
| Database | SQLite JDBC | 3.45.3.0 |
| Messaging | Quarkus Kafka | Latest |
| REST API | Quarkus REST with Jackson | Latest |
| Build Tool | Maven | 3.x |

### 4.2 System Components

#### 4.2.1 Core Components (Required)
- **KafkaNotificationConsumer**: Kafka message consumer for TTK events (PRIMARY COMPONENT)
  - Consumes ticket events from Kafka
  - Applies notification filtering rules
  - Groups users by language preference
  - Coordinates with UserTeamService, TokenStorageService, and TranslationService
  - Triggers notification sending via FirebaseService
- **FirebaseService**: Firebase integration and message sending
  - Initializes Firebase Admin SDK
  - Sends multicast notifications to device tokens
  - Returns success/failure results per token
- **TokenStorageService**: SQLite-based token persistence
  - Stores userId → deviceToken → language mapping
  - Supports registration, lookup, language update, and cleanup
  - Groups tokens by language for efficient translation
- **UserTeamService**: User-team membership resolution (IMPLEMENTED)
  - Resolves which users belong to which teams
  - Required for notification filtering
  - SQLite-based storage
- **TranslationService**: Server-side notification translation (TO BE IMPLEMENTED)
  - Translates notification titles and bodies to multiple languages
  - Supports en, pt, es, fr (extensible)
  - Uses translation key system with parameter substitution
  - Enables notifications to work when app is terminated

#### 4.2.2 API Components (Supporting)
- **TokenResource**: Device token registration endpoint
- **NotificationResource**: Optional administrative endpoints

#### 4.2.3 Data Transfer Objects
- **DeviceTokenRequest**: Token registration payload
- **NotificationRequest**: Manual notification payload (admin only)
- **UserNotificationRequest**: User-targeted notification payload
- **NotificationResponse**: Notification delivery results

### 4.3 Data Model

#### 4.3.1 Token Storage Schema
```sql
CREATE TABLE tokens (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'en',
  saved_at INTEGER NOT NULL
)
```

**Fields**:
- `token`: FCM device token (unique identifier)
- `user_id`: User identifier for token-to-user mapping
- `language`: User's preferred language (ISO 639-1 code: en, pt, es, fr, etc.)
- `saved_at`: Unix timestamp (milliseconds) of registration

**Language Support**:
- Stores language preference per device token
- Enables server-side translation for notifications
- Allows same user with multiple devices to have different languages
- Default language is 'en' (English) if not specified

#### 4.3.2 User-Team Mapping Schema (To Be Implemented)

The system requires user-team membership data to filter notification recipients. This can be implemented using one of the following approaches:

**Option A - Local Database Table**:
```sql
CREATE TABLE user_teams (
  user_id TEXT NOT NULL,
  team_id TEXT NOT NULL,
  added_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, team_id)
);

CREATE INDEX idx_user_teams_user ON user_teams(user_id);
CREATE INDEX idx_user_teams_team ON user_teams(team_id);
```

**Option B - External Service Integration**:
- Query existing user management API/database
- Cache results temporarily to reduce API calls
- Refresh on demand or periodic sync

**Option C - Kafka Event Sync**:
- Subscribe to user/team management events
- Maintain local cache synchronized with source of truth
- Handle user joins team, user leaves team events

**Required Data**:
- `user_id`: User identifier
- `team_id`: Team identifier
- Bidirectional lookup support (users in team, teams for user)

### 4.4 Configuration Properties

| Property | Description | Value |
|----------|-------------|-------|
| firebase.service.account.path | Firebase credentials JSON | sigo-b8b43-firebase-adminsdk-fbsvc-e377444873.json |
| kafka.bootstrap.servers | Kafka broker address | 10.113.140.101:30140 |
| mp.messaging.incoming.ttk-in.connector | Kafka connector type | smallrye-kafka |
| mp.messaging.incoming.ttk-in.topic | Kafka topic name | sigo-ttk |
| mp.messaging.incoming.ttk-in.value.deserializer | Message deserializer | StringDeserializer |
| mp.messaging.incoming.ttk-in.enabled | Enable Kafka consumer | true |

---

## 5. Mobile App Integration Guide

### 5.1 Required Integration Steps

#### Step 1: Initialize Firebase in Flutter App
```yaml
# pubspec.yaml
dependencies:
  firebase_core: latest
  firebase_messaging: latest
  http: latest
```

#### Step 2: Register Token on Login
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String backendUrl = 'http://your-backend:8080';

  // Call this when user logs in
  Future<void> registerToken(String userId) async {
    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      // Register with backend
      final response = await http.post(
        Uri.parse('$backendUrl/api/tokens/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'deviceToken': token,
        }),
      );

      if (response.statusCode == 200) {
        print('Token registered successfully');
      }
    }
  }

  // Handle token refresh
  void setupTokenRefreshListener(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerToken(userId);
    });
  }
}
```

#### Step 3: Handle Received Notifications
```dart
// Handle foreground notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Notification received: ${message.notification?.title}');

  // Access custom data
  final ticketId = message.data['ticketId'];
  final changes = message.data['changes'];

  // Show in-app notification or navigate to ticket
});

// Handle background/terminated notifications
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // User tapped notification
  final ticketId = message.data['ticketId'];
  // Navigate to ticket details
});
```

### 5.2 What the App Does NOT Need

- ❌ Call any endpoint to send notifications
- ❌ Manage notification content or timing
- ❌ Poll for ticket updates
- ❌ Handle notification logic

### 5.3 What the Backend Handles Automatically

- ✅ Listens to Kafka for ticket events
- ✅ Determines which users to notify
- ✅ Builds notification content from ticket data
- ✅ Sends notifications via Firebase
- ✅ Cleans up invalid tokens

---

## 6. Deployment Requirements

#### DEP-1: Firebase Credentials
**Requirements**:
- Place `sigo-b8b43-firebase-adminsdk-fbsvc-e377444873.json` in `src/main/resources/`
- **Never commit to Git** - add to `.gitignore`
- Ensure file has proper read permissions

---

## 7. Security Considerations

### 7.1 Credential Security

#### SEC-1: Firebase Service Account Protection
**Requirements**:
- Service account JSON in `.gitignore`
- Use environment-specific credentials
- Restrict file permissions to application user only

### 7.2 API Security

#### SEC-2: Token Registration Endpoint
**Recommendation**: Add authentication to `/api/tokens/register` endpoint to prevent unauthorized token registration

#### SEC-3: Administrative Endpoints
**Recommendation**: Restrict access to optional admin endpoints (send, stats, etc.) via authentication/authorization

---

## 8. Testing Requirements

### 8.1 Integration Testing

#### TEST-1: Kafka Message Processing
**Test**: Send test TTK message to Kafka topic, verify notification sent to registered "sigocloud" user

#### TEST-2: Token Registration
**Test**: Register token via API, verify stored in database

#### TEST-3: Notification Delivery
**Test**: Trigger Kafka event, verify notification received on real device

#### TEST-4: Invalid Token Cleanup
**Test**: Send notification to invalid token, verify token removed from database

---

## 9. Summary of Mobile App Requirements

### What Mobile App Must Do:
1. **Register device token WITH language** on user login via `POST /api/tokens/register`
   - Include device language: `language: "pt"` (ISO 639-1 code)
2. **Update language preference** when user changes language in app settings via `PUT /api/tokens/update-language`
3. **Re-register on token refresh** using Firebase token refresh listener (maintain language preference)
4. **Handle received notifications** in foreground and background

### What Mobile App Should NOT Do:
- ❌ Call any notification sending endpoints
- ❌ Manage notification content
- ❌ Poll for updates
- ❌ Determine who should receive notifications
- ❌ Translate notifications (backend handles this)

### Backend Handles Everything Else Automatically
The backend automatically:
- Listens to Kafka events for ticket changes
- **Intelligently determines recipients** based on:
  - Team membership (users in assigned teams)
  - Ticket ownership (ticket creator)
  - Direct assignment (assigned users)
- **Excludes the action performer** to prevent self-notifications
- **Groups users by language preference** for efficient translation
- **Translates notifications** to each user's preferred language
- **Sends one multicast per language group** (e.g., 3 FCM calls for 100 users in 3 languages)
- Builds notification content from ticket data
- Sends notifications via Firebase
- Cleans up invalid tokens

### Critical Notification Filtering Rules
Users receive notifications for a ticket ONLY if:
1. ✅ User is in a team assigned to the ticket, OR
2. ✅ User created the ticket, OR
3. ✅ User is directly assigned to the ticket

AND:
4. ✅ User is NOT the one who performed the action

**Example**: When Bob updates a ticket created by Alice and assigned to Team A:
- ✅ Alice receives notification (she's the creator, and Bob made the change)
- ✅ Team A members receive notification (except Bob)
- ❌ Bob does NOT receive notification (he performed the action)

---

## 10. Multi-Language Notification Support

### Overview
The system supports **server-side translation** to ensure users receive notifications in their preferred language, even when the mobile app is completely terminated.

### How It Works

#### Step 1: User Registration
```dart
// Mobile app sends language preference
POST /api/tokens/register
{
  "userId": "alice",
  "deviceToken": "token-123",
  "language": "pt"  // Portuguese
}
```

#### Step 2: Language Storage
```sql
-- Backend stores in database
INSERT INTO tokens (token, user_id, language, saved_at)
VALUES ('token-123', 'alice', 'pt', 1234567890)
```

#### Step 3: Event Processing & Translation
```
Kafka Event → Determine Eligible Users → Group by Language

Example:
  Eligible Users: {alice, bob, charlie}

  Group by Language:
    "pt": [alice-token]      → Portuguese users
    "en": [bob-token]        → English users
    "es": [charlie-token]    → Spanish users

  For EACH language:
    Translate title: "Ticket TKT-123 atualizado" (Portuguese)
    Translate body: "Estado: Novo → Em Progresso"
    Send FCM multicast to Portuguese tokens

    Translate title: "Ticket TKT-123 updated" (English)
    Translate body: "Status: New → In Progress"
    Send FCM multicast to English tokens

    ... and so on
```

#### Step 4: User Receives Translated Notification
```
Alice's Phone (Portuguese):
┌──────────────────────────────┐
│ 🔔 SIGO                      │
│ Ticket TKT-123 atualizado    │
│ Estado: Novo → Em Progresso  │
└──────────────────────────────┘

Bob's Phone (English):
┌──────────────────────────────┐
│ 🔔 SIGO                      │
│ Ticket TKT-123 updated       │
│ Status: New → In Progress    │
└──────────────────────────────┘

Charlie's Phone (Spanish):
┌──────────────────────────────┐
│ 🔔 SIGO                      │
│ Ticket TKT-123 actualizado   │
│ Estado: Nuevo → En Progreso  │
└──────────────────────────────┘
```

### Language Change Support

When user changes language in app settings:

```dart
// Mobile app updates backend
PUT /api/tokens/update-language
{
  "userId": "alice",
  "deviceToken": "token-123",
  "language": "en"  // Changed from "pt" to "en"
}
```

Future notifications will be sent in English.

### Key Benefits
- ✅ **Works when app is closed** - Notifications arrive pre-translated
- ✅ **Efficient** - One FCM call per language, not per user
- ✅ **Scalable** - 1000 users in 3 languages = 3 FCM calls
- ✅ **Per-device language** - Same user can have different languages on different devices

### Supported Languages
- **Minimum**: English (en), Portuguese (pt), Spanish (es)
- **Extensible**: Easy to add more languages (French, German, etc.)

---

**End of Requirements Specification Document**
