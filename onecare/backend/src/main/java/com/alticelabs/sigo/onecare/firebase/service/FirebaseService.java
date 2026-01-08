package com.alticelabs.sigo.onecare.firebase.service;

import com.alticelabs.sigo.onecare.firebase.dto.NotificationResponse;
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

    public NotificationResponse sendMulticastNotification(List<String> tokens, String title, String body, Map<String, String> data) {
        try {
            if (tokens == null || tokens.isEmpty()) {
                throw new IllegalArgumentException("Device tokens list cannot be empty");
            }

            MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .addAllTokens(tokens);

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
