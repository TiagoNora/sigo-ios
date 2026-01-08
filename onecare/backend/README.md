# Firebase Notification Service

A Quarkus-based backend service for sending push notifications to mobile devices using Firebase Cloud Messaging (FCM).

## Features

- Send push notifications to multiple devices simultaneously
- Send notifications to users by userId (automatic token lookup)
- Device token registration and management
- In-memory token storage (mapped by userId)
- RESTful API for easy integration
- Supports custom data payloads
- Detailed response with success/failure per device token

## Firebase Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Once created, go to Project Settings (gear icon)

### 2. Generate Service Account Key

1. In Project Settings, go to "Service Accounts" tab
2. Click "Generate New Private Key"
3. Download the JSON file
4. Replace the content of `src/main/resources/firebase-service-account.json` with your downloaded file

**IMPORTANT**: Never commit your actual service account JSON to version control. Add it to `.gitignore`:

```
src/main/resources/firebase-service-account.json
```

### 3. Enable Firebase Cloud Messaging

1. In Firebase Console, go to "Cloud Messaging" in the left menu
2. Enable the Firebase Cloud Messaging API if not already enabled

## API Endpoints

### Send Notification

Send push notifications to one or more devices.

**Endpoint**: `POST /api/notifications/send`

**Request Body**:
```json
{
  "title": "Hello from Backend!",
  "body": "This is a test notification",
  "tokens": [
    "device-token-1",
    "device-token-2"
  ],
  "data": {
    "customKey": "customValue",
    "action": "openScreen"
  }
}
```

**Response**:
```json
{
  "successCount": 2,
  "failureCount": 0,
  "results": [
    {
      "token": "device-token-1",
      "success": true,
      "messageId": "projects/your-project/messages/0:1234567890",
      "error": null
    },
    {
      "token": "device-token-2",
      "success": true,
      "messageId": "projects/your-project/messages/0:0987654321",
      "error": null
    }
  ]
}
```

**cURL Example**:
```bash
curl -X POST http://localhost:8080/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "Hello from the backend!",
    "tokens": ["your-device-token-here"]
  }'
```

### Send Notification to User

Send push notification to a user by their userId. Automatically looks up all registered device tokens for that user.

**Endpoint**: `POST /api/notifications/send-to-user`

**Request Body**:
```json
{
  "userId": "user123",
  "title": "Hello User!",
  "body": "This is a personalized notification",
  "data": {
    "orderId": "12345",
    "action": "viewOrder"
  }
}
```

**Response**: Same as `/send` endpoint

**cURL Example**:
```bash
curl -X POST http://localhost:8080/api/notifications/send-to-user \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "title": "Order Update",
    "body": "Your order has been shipped!"
  }'
```

### Register Device Token

Register a device token for a specific user. The mobile app should call this when it obtains a FCM token.

**Endpoint**: `POST /api/tokens/register`

**Request Body**:
```json
{
  "userId": "user123",
  "deviceToken": "fcm-device-token-here"
}
```

**Response**:
```json
{
  "message": "Device token registered successfully",
  "userId": "user123",
  "deviceToken": "fcm-device-token-here"
}
```

**cURL Example**:
```bash
curl -X POST http://localhost:8080/api/tokens/register \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "deviceToken": "your-fcm-token"
  }'
```

### Unregister Device Token

Remove a device token from storage (e.g., when user logs out or uninstalls app).

**Endpoint**: `DELETE /api/tokens/unregister?token={deviceToken}`

**Response**:
```json
{
  "message": "Device token unregistered successfully",
  "deviceToken": "fcm-device-token-here"
}
```

**cURL Example**:
```bash
curl -X DELETE "http://localhost:8080/api/tokens/unregister?token=your-fcm-token"
```

### Get User's Tokens

Retrieve all registered device tokens for a specific user.

**Endpoint**: `GET /api/tokens/user/{userId}`

**Response**:
```json
{
  "userId": "user123",
  "tokens": ["token1", "token2"],
  "tokenCount": 2
}
```

### Get Token Statistics

Get statistics about registered tokens and users.

**Endpoint**: `GET /api/tokens/stats`

**Response**:
```json
{
  "totalUsers": 150,
  "totalTokens": 203
}
```

### Health Check

Check if the notification service is running.

**Endpoint**: `GET /api/notifications/health`

**Response**:
```json
{
  "status": "ok",
  "service": "Firebase Notification Service"
}
```

## Flutter Integration

To integrate with your Flutter app:

1. Add Firebase to your Flutter app following the [official guide](https://firebase.google.com/docs/flutter/setup)
2. Install the `firebase_messaging` package
3. Get the device token and register it with your backend:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> registerDeviceToken(String userId) async {
  // Get FCM token
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();

  if (token != null) {
    // Register token with backend
    final response = await http.post(
      Uri.parse('http://your-backend-url:8080/api/tokens/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'deviceToken': token,
      }),
    );

    if (response.statusCode == 200) {
      print('Token registered successfully');
    } else {
      print('Failed to register token: ${response.body}');
    }
  }
}

// Call this when user logs in
await registerDeviceToken('user123');
```

4. Listen for token refresh and re-register:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
  // Re-register the new token
  await registerDeviceToken('user123');
});
```

5. Unregister token when user logs out:

```dart
Future<void> unregisterDeviceToken() async {
  String? token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await http.delete(
      Uri.parse('http://your-backend-url:8080/api/tokens/unregister?token=$token'),
    );
  }
}
```

6. Your backend can now send notifications using:
   - `/api/notifications/send-to-user` - Send to specific user by userId
   - `/api/notifications/send` - Send to specific device tokens

## Troubleshooting

### Firebase not initializing

- Ensure `firebase-service-account.json` exists in `src/main/resources/`
- Verify the JSON file is valid and contains all required fields
- Check application logs for detailed error messages

### Notifications not being received

- Verify device tokens are valid and up-to-date
- Ensure FCM is enabled in Firebase Console
- Check if the Flutter app has notification permissions
- Verify the app is properly configured with Firebase

### HTTP 400 Bad Request

- Check that request body contains required fields (title, tokens)
- Ensure tokens list is not empty
- Verify JSON format is correct

### HTTP 500 Internal Server Error

- Check Firebase service account credentials
- Verify network connectivity to Firebase servers
- Review application logs for detailed error messages

---

## About Quarkus

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: <https://quarkus.io/>.

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:

```shell script
./mvnw quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at <http://localhost:8080/q/dev/>.

## Packaging and running the application

The application can be packaged using:

```shell script
./mvnw package
```

It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:

```shell script
./mvnw package -Dquarkus.package.jar.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using:

```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using:

```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/firebase-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult <https://quarkus.io/guides/maven-tooling>.

## Provided Code

### REST

Easily start your REST Web Services

[Related guide section...](https://quarkus.io/guides/getting-started-reactive#reactive-jax-rs-resources)
