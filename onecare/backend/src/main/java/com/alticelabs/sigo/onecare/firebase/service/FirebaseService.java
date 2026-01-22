package com.alticelabs.sigo.onecare.firebase.service;

import com.alticelabs.sigo.onecare.firebase.dto.NotificationResponse;
import com.alticelabs.sigo.onecare.firebase.dto.TopicNotificationResponse;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

@ApplicationScoped
public class FirebaseService {

    private static final Logger LOGGER = Logger.getLogger(FirebaseService.class.getName());
    private static final String ANDROID_CHANNEL_ID = "sigo_default_channel";

    @ConfigProperty(name = "firebase.service.account.path")
    String serviceAccountPath;

    @PostConstruct
    public void initialize() {
        try {
            InputStream serviceAccount = getClass().getClassLoader()
                    .getResourceAsStream(serviceAccountPath);

            if (serviceAccount == null) {
                throw new IllegalStateException("Firebase service account file not found: " + serviceAccountPath);
            }

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                LOGGER.info("Firebase Admin SDK initialized successfully");
            }
        } catch (IOException e) {
            LOGGER.severe("Failed to initialize Firebase: " + e.getMessage());
            throw new RuntimeException("Failed to initialize Firebase", e);
        }
    }

    public NotificationResponse sendMulticastNotification(
            List<String> tokens,
            String title,
            String body,
            Map<String, String> data,
            String titleLocKey,
            List<String> titleLocArgs,
            String bodyLocKey,
            List<String> bodyLocArgs
    ) {
        try {
            if (tokens == null || tokens.isEmpty()) {
                throw new IllegalArgumentException("Device tokens list cannot be empty");
            }

            MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
                    .addAllTokens(tokens);

            // Only set notification content if there's something to display
            boolean hasLocKeys = !isBlank(titleLocKey) || !isBlank(bodyLocKey);
            boolean hasContent = !isBlank(title) || !isBlank(body);

            if (!hasLocKeys && hasContent) {
                messageBuilder.setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());
            }

            // Only set platform-specific notification configs if there's content to display
            // Data-only messages should not have notification configs to avoid OS-level notifications
            if (hasLocKeys || hasContent) {
                messageBuilder.setAndroidConfig(
                        buildAndroidConfig(title, body, titleLocKey, titleLocArgs, bodyLocKey, bodyLocArgs));
                messageBuilder.setApnsConfig(
                        buildApnsConfig(title, body, titleLocKey, titleLocArgs, bodyLocKey, bodyLocArgs));
            } else {
                // Data-only message - set high priority to ensure delivery
                messageBuilder.setAndroidConfig(AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .build());
                // iOS: set content-available for background delivery
                messageBuilder.setApnsConfig(ApnsConfig.builder()
                        .setAps(Aps.builder()
                                .setContentAvailable(true)
                                .build())
                        .build());
            }

            if (data != null && !data.isEmpty()) {
                messageBuilder.putAllData(data);
            }

            MulticastMessage message = messageBuilder.build();
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);

            LOGGER.info(String.format("Successfully sent %d notifications, %d failed",
                    response.getSuccessCount(), response.getFailureCount()));

            return buildNotificationResponse(tokens, response);

        } catch (FirebaseMessagingException e) {
            LOGGER.severe("Failed to send notifications: " + e.getMessage());
            throw new RuntimeException("Failed to send notifications", e);
        }
    }

    public TopicNotificationResponse sendTopicNotification(
            String topic,
            String title,
            String body,
            Map<String, String> data,
            String titleLocKey,
            List<String> titleLocArgs,
            String bodyLocKey,
            List<String> bodyLocArgs
    ) {
        try {
            if (isBlank(topic)) {
                throw new IllegalArgumentException("Topic cannot be empty");
            }

            Message.Builder messageBuilder = Message.builder()
                    .setTopic(topic);

            boolean hasLocKeys = !isBlank(titleLocKey) || !isBlank(bodyLocKey);
            boolean hasContent = !isBlank(title) || !isBlank(body);

            if (!hasLocKeys && hasContent) {
                messageBuilder.setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());
            }

            // Only set platform-specific notification configs if there's notification content
            // Data-only messages should not have notification configs to avoid duplicate notifications
            if (hasLocKeys || hasContent) {
                messageBuilder.setAndroidConfig(
                        buildAndroidConfig(title, body, titleLocKey, titleLocArgs, bodyLocKey, bodyLocArgs));
                messageBuilder.setApnsConfig(
                        buildApnsConfig(title, body, titleLocKey, titleLocArgs, bodyLocKey, bodyLocArgs));
            } else {
                // Data-only message - set high priority to ensure delivery
                messageBuilder.setAndroidConfig(AndroidConfig.builder()
                        .setPriority(AndroidConfig.Priority.HIGH)
                        .build());
                // iOS: set content-available for background delivery
                messageBuilder.setApnsConfig(ApnsConfig.builder()
                        .setAps(Aps.builder()
                                .setContentAvailable(true)
                                .build())
                        .build());
            }

            if (data != null && !data.isEmpty()) {
                messageBuilder.putAllData(data);
            }

            Message message = messageBuilder.build();
            String messageId = FirebaseMessaging.getInstance().send(message);
            LOGGER.info(String.format("Successfully sent topic notification to %s", topic));
            return new TopicNotificationResponse(topic, messageId);

        } catch (FirebaseMessagingException e) {
            LOGGER.severe("Failed to send topic notification: " + e.getMessage());
            throw new RuntimeException("Failed to send topic notification", e);
        }
    }

    private AndroidConfig buildAndroidConfig(
            String title,
            String body,
            String titleLocKey,
            List<String> titleLocArgs,
            String bodyLocKey,
            List<String> bodyLocArgs
    ) {
        AndroidNotification.Builder notificationBuilder = AndroidNotification.builder();

        // Only set static title/body if no localization keys are provided
        // When localization keys are set, they take precedence
        if (!isBlank(titleLocKey)) {
            notificationBuilder.setTitleLocalizationKey(titleLocKey);
            if (titleLocArgs != null && !titleLocArgs.isEmpty()) {
                notificationBuilder.addAllTitleLocalizationArgs(titleLocArgs);
            }
        } else if (!isBlank(title)) {
            notificationBuilder.setTitle(title);
        }

        if (!isBlank(bodyLocKey)) {
            notificationBuilder.setBodyLocalizationKey(bodyLocKey);
            if (bodyLocArgs != null && !bodyLocArgs.isEmpty()) {
                notificationBuilder.addAllBodyLocalizationArgs(bodyLocArgs);
            }
        } else if (!isBlank(body)) {
            notificationBuilder.setBody(body);
        }

        return AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setNotification(notificationBuilder
                        .setChannelId(ANDROID_CHANNEL_ID)
                        .build())
                .build();
    }

    private ApnsConfig buildApnsConfig(
            String title,
            String body,
            String titleLocKey,
            List<String> titleLocArgs,
            String bodyLocKey,
            List<String> bodyLocArgs
    ) {
        ApsAlert.Builder alertBuilder = ApsAlert.builder();

        // Only set static title/body if no localization keys are provided
        // When localization keys are set, they take precedence
        if (!isBlank(titleLocKey)) {
            alertBuilder.setTitleLocalizationKey(titleLocKey);
            if (titleLocArgs != null && !titleLocArgs.isEmpty()) {
                alertBuilder.addAllTitleLocArgs(titleLocArgs);
            }
        } else if (!isBlank(title)) {
            alertBuilder.setTitle(title);
        }

        if (!isBlank(bodyLocKey)) {
            alertBuilder.setLocalizationKey(bodyLocKey);
            if (bodyLocArgs != null && !bodyLocArgs.isEmpty()) {
                alertBuilder.addAllLocalizationArgs(bodyLocArgs);
            }
        } else if (!isBlank(body)) {
            alertBuilder.setBody(body);
        }

        return ApnsConfig.builder()
                .setAps(Aps.builder()
                        .setAlert(alertBuilder.build())
                        .build())
                .build();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private NotificationResponse buildNotificationResponse(List<String> tokens, BatchResponse batchResponse) {
        List<NotificationResponse.NotificationResult> results = new ArrayList<>();
        List<SendResponse> responses = batchResponse.getResponses();

        for (int i = 0; i < responses.size(); i++) {
            SendResponse response = responses.get(i);
            String token = tokens.get(i);

            if (response.isSuccessful()) {
                results.add(new NotificationResponse.NotificationResult(
                        token,
                        true,
                        response.getMessageId(),
                        null
                ));
            } else {
                String errorMessage = response.getException() != null
                        ? response.getException().getMessage()
                        : "Unknown error";
                results.add(new NotificationResponse.NotificationResult(
                        token,
                        false,
                        null,
                        errorMessage
                ));
            }
        }

        return new NotificationResponse(
                batchResponse.getSuccessCount(),
                batchResponse.getFailureCount(),
                results
        );
    }
}
