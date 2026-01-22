package com.alticelabs.sigo.onecare.firebase.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

@ApplicationScoped
public class KafkaNotificationConsumer {

    private static final Logger LOGGER = Logger.getLogger(KafkaNotificationConsumer.class.getName());

    @Inject
    ObjectMapper objectMapper;

    @Inject
    TokenStorageService tokenStorageService;

    @Inject
    FirebaseService firebaseService;

    @Inject
    UserTeamService userTeamService;

    @Incoming("ttk-in")
    @RunOnVirtualThread
    public void onMessage(String payload) {
        try {
            LOGGER.info("Received Kafka payload: " + payload);
            JsonNode root = objectMapper.readTree(payload);
            String schema = optionalText(root, "header", "schema");
            if (!"TTK".equalsIgnoreCase(schema)) {
                return; // ignore other schemas
            }

            String eventType = optionalText(root, "header", "eventType");
            JsonNode dataNode = root.path("data").path("value");
            if (dataNode.isMissingNode() || !dataNode.isObject()) {
                LOGGER.warning("No data.value present, skipping message");
                return;
            }

            // Only process tickets with origin "Onecare"
            String origin = dataNode.path("origin").asText("");
            if (!"Onecare".equalsIgnoreCase(origin)) {
                LOGGER.info("Skipping ticket with origin: " + origin + " (only Onecare tickets are processed)");
                return;
            }

            // Only process messages that contain a status, note, or attachment change
            JsonNode changesArray = resolveChanges(root);
            if (!hasRelevantChange(changesArray, dataNode)) {
                LOGGER.info("Skipping message without relevant change");
                return;
            }

            String ticketId = dataNode.path("id").asText("unknown");
            String ticketName = dataNode.path("name").asText("");
            String createdBy = dataNode.path("createdBy").asText("");
            String actionUsername = optionalText(root, "data", "userInfo", "username");

            // Get all tokens except the action performer
            List<String> tokens = tokenStorageService.getAllTokensExceptUser(actionUsername);
            if (tokens.isEmpty()) {
                LOGGER.info("No tokens for ticket " + ticketId + ", skipping notification.");
                return;
            }

            JsonNode changesNode = resolveChanges(root);
            String titleKey = resolveTitleKey(eventType);
            String bodyKey = resolveBodyKey(changesNode, dataNode);

            // Build data payload with localization keys for client-side translation
            Map<String, String> data = new HashMap<>();
            data.put("ticketId", ticketId);
            data.put("createdBy", createdBy);
            data.put("actionUsername", actionUsername != null ? actionUsername : "");
            data.put("titleKey", titleKey);
            data.put("bodyKey", bodyKey);
            String changesString;
            try {
                if (changesNode != null && !changesNode.isMissingNode() && !changesNode.isNull()) {
                    changesString = objectMapper.writeValueAsString(changesNode);
                } else {
                    changesString = "[]";
                }
            } catch (Exception e) {
                changesString = "[]";
                LOGGER.warning("Failed to serialize changes node: " + e.getMessage());
            }
            data.put("changes", changesString);

            // Send data-only notification - client will handle translation
            LOGGER.info(String.format(
                    "Sending notification for ticket %s to %d tokens (titleKey=%s, bodyKey=%s)",
                    ticketId, tokens.size(), titleKey, bodyKey));

            var response = firebaseService.sendMulticastNotification(
                    tokens,
                    null, // No title - client will translate
                    null, // No body - client will translate
                    data,
                    null,
                    null,
                    null,
                    null
            );

            response.getResults().stream()
                .filter(r -> !r.isSuccess())
                .forEach(r -> {
                    LOGGER.warning("Notification failed for token " + r.getToken() + " error=" + r.getError());
                    tokenStorageService.unregisterToken(r.getToken());
                });

            LOGGER.info(String.format(
                    "Sent notification for ticket %s to %d tokens (success=%d, failure=%d)",
                    ticketId, tokens.size(), response.getSuccessCount(), response.getFailureCount()));
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to process Kafka message", e);
        }
    }

    /**
     * Get all tokens except for the user who performed the action.
     * First iteration: send to all users except the action performer.
     */
    private List<String> collectTokens(JsonNode root) {
        // Get the user who performed the action from data.userInfo.username
        String actionUsername = optionalText(root, "data", "userInfo", "username");

        // Get all tokens except the action performer
        List<String> tokens = tokenStorageService.getAllTokensExceptUser(actionUsername);

        LOGGER.info(String.format(
                "Notification targeting: %d tokens (excluding actionUsername=%s)",
                tokens.size(), actionUsername));

        return tokens;
    }

    private String buildBody(JsonNode changes, JsonNode dataNode) {
        if (changes.isArray()) {
            for (JsonNode change : changes) {
                String type = change.path("type").asText("");
                if ("Create".equalsIgnoreCase(type) || "Created".equalsIgnoreCase(type)) {
                    return "New ticket created";
                }
                if ("FieldChange".equalsIgnoreCase(type)) {
                    String field = change.path("fieldName").asText("");
                    String oldVal = change.path("oldValue").asText("");
                    String newVal = change.path("newValue").asText("");

                    if ("status".equalsIgnoreCase(field)) {
                        if (!oldVal.isEmpty() && !newVal.isEmpty()) {
                            return String.format("Status: %s -> %s", oldVal, newVal);
                        }
                        if (!newVal.isEmpty()) {
                            return "Status: " + newVal;
                        }
                    }
                    if ("impact".equalsIgnoreCase(field)) {
                        if (!oldVal.isEmpty() && !newVal.isEmpty()) {
                            return String.format("Impact: %s -> %s", oldVal, newVal);
                        }
                        if (!newVal.isEmpty()) {
                            return "Impact: " + newVal;
                        }
                    }
                    if ("severity".equalsIgnoreCase(field)) {
                        if (!oldVal.isEmpty() && !newVal.isEmpty()) {
                            return String.format("Severity: %s -> %s", oldVal, newVal);
                        }
                        if (!newVal.isEmpty()) {
                            return "Severity: " + newVal;
                        }
                    }
                } else if ("Note".equalsIgnoreCase(type)) {
                    return "Note added";
                } else if ("Attachment".equalsIgnoreCase(type)) {
                    String action = change.path("action").asText("");
                    if ("ADD".equalsIgnoreCase(action)) {
                        return "Attachment added";
                    }
                    if ("REMOVE".equalsIgnoreCase(action)) {
                        return "Attachment removed";
                    }
                    return "Attachment updated";
                }
            }
        }

        if (isNoteUpdate(dataNode)) {
            return "Note added";
        }
        if (isAttachmentUpdate(dataNode)) {
            return "Attachment added";
        }

        return "Ticket updated";
    }

    private String summarizeEvent(String eventType) {
        if (eventType == null || eventType.isEmpty()) return "updated";
        return eventType.toLowerCase(Locale.ROOT);
    }

    private String resolveTitleKey(String eventType) {
        if (eventType == null) {
            return "ticket_updated_title";
        }
        String normalized = eventType.toLowerCase(Locale.ROOT);
        if (normalized.contains("create")) {
            return "ticket_created_title";
        }
        if (normalized.contains("resolve")) {
            return "ticket_resolved_title";
        }
        if (normalized.contains("close")) {
            return "ticket_closed_title";
        }
        if (normalized.contains("cancel")) {
            return "ticket_cancelled_title";
        }
        if (normalized.contains("reopen")) {
            return "ticket_reopened_title";
        }
        return "ticket_updated_title";
    }

    private String resolveBodyKey(JsonNode changesNode, JsonNode dataNode) {
        if (changesNode != null && changesNode.isArray() && !changesNode.isEmpty()) {
            for (JsonNode change : changesNode) {
                String type = change.path("type").asText("");
                if ("Create".equalsIgnoreCase(type) || "Created".equalsIgnoreCase(type)) {
                    return "body_ticket_created";
                }
                if ("FieldChange".equalsIgnoreCase(type)) {
                    String fieldName = change.path("fieldName").asText("");
                    if ("status".equalsIgnoreCase(fieldName)) {
                        return "body_status_changed";
                    }
                    if ("impact".equalsIgnoreCase(fieldName)) {
                        return "body_impact_changed";
                    }
                    if ("severity".equalsIgnoreCase(fieldName)) {
                        return "body_severity_changed";
                    }
                } else if ("Note".equalsIgnoreCase(type)) {
                    return "body_note_added";
                } else if ("Attachment".equalsIgnoreCase(type)) {
                    String action = change.path("action").asText("");
                    if ("ADD".equalsIgnoreCase(action)) {
                        return "body_attachment_added";
                    }
                    if ("REMOVE".equalsIgnoreCase(action)) {
                        return "body_attachment_removed";
                    }
                    return "body_attachment_added";
                }
            }
        }

        if (isNoteUpdate(dataNode)) {
            return "body_note_added";
        }
        if (isAttachmentUpdate(dataNode)) {
            return "body_attachment_added";
        }

        return "ticket_updated";
    }

    private JsonNode resolveChanges(JsonNode root) {
        JsonNode changes = root.path("changes");
        if (changes != null && changes.isArray() && changes.size() > 0) {
            return changes;
        }
        JsonNode dataChanges = root.path("data").path("changes");
        if (dataChanges != null && dataChanges.isArray()) {
            return dataChanges;
        }
        return objectMapper.createArrayNode();
    }

    private String optionalText(JsonNode root, String... path) {
        JsonNode current = root;
        for (String p : path) {
            current = current.path(p);
        }
        return current.isMissingNode() ? null : current.asText();
    }

    private boolean hasRelevantChange(JsonNode changesNode, JsonNode dataNode) {
        if (changesNode != null && changesNode.isArray() && !changesNode.isEmpty()) {
            for (JsonNode change : changesNode) {
                String type = change.path("type").asText("");
                if ("Create".equalsIgnoreCase(type) || "Created".equalsIgnoreCase(type)) {
                    return true;
                }
                if ("FieldChange".equalsIgnoreCase(type)) {
                    String fieldName = change.path("fieldName").asText("");
                    if ("status".equalsIgnoreCase(fieldName) ||
                            "impact".equalsIgnoreCase(fieldName) ||
                            "severity".equalsIgnoreCase(fieldName)) {
                        return true;
                    }
                } else if ("Note".equalsIgnoreCase(type) || "Attachment".equalsIgnoreCase(type)) {
                    return true;
                }
            }
        }

        return isNoteUpdate(dataNode) || isAttachmentUpdate(dataNode);
    }

    private String resolveBodyLocKey(JsonNode changesNode, String status, JsonNode dataNode) {
        if (changesNode != null && changesNode.isArray() && !changesNode.isEmpty()) {
            for (JsonNode change : changesNode) {
                String type = change.path("type").asText("");
                if ("Create".equalsIgnoreCase(type) || "Created".equalsIgnoreCase(type)) {
                    return "notif_body_ticket_created";
                }
                if ("FieldChange".equalsIgnoreCase(type)) {
                    String fieldName = change.path("fieldName").asText("");
                    if ("status".equalsIgnoreCase(fieldName)) {
                        return status.isEmpty() ? "notif_ticket_generic_body" : "notif_ticket_status_body";
                    }
                    if ("impact".equalsIgnoreCase(fieldName)) {
                        return "notif_body_impact_changed";
                    }
                    if ("severity".equalsIgnoreCase(fieldName)) {
                        return "notif_body_severity_changed";
                    }
                } else if ("Note".equalsIgnoreCase(type)) {
                    return "notif_body_note_added";
                } else if ("Attachment".equalsIgnoreCase(type)) {
                    String action = change.path("action").asText("");
                    if ("ADD".equalsIgnoreCase(action)) {
                        return "notif_body_attachment_added";
                    }
                    if ("REMOVE".equalsIgnoreCase(action)) {
                        return "notif_body_attachment_removed";
                    }
                    return "notif_body_attachment_updated";
                }
            }
        }

        if (isNoteUpdate(dataNode)) {
            return "notif_body_note_added";
        }
        if (isAttachmentUpdate(dataNode)) {
            return "notif_body_attachment_added";
        }

        return status.isEmpty() ? "notif_ticket_generic_body" : "notif_ticket_status_body";
    }

    private boolean isNoteUpdate(JsonNode dataNode) {
        return isRecentUpdate(dataNode, "notes", "creationDate");
    }

    private boolean isAttachmentUpdate(JsonNode dataNode) {
        return isRecentUpdate(dataNode, "attachments", "creationDate");
    }

    private boolean isRecentUpdate(JsonNode dataNode, String arrayField, String dateField) {
        if (dataNode == null || dataNode.isMissingNode()) {
            return false;
        }
        String lastUpdate = dataNode.path("lastUpdate").asText("");
        Instant lastUpdateInstant = parseInstant(lastUpdate);
        if (lastUpdateInstant == null) {
            return false;
        }

        JsonNode items = dataNode.path(arrayField);
        if (!items.isArray() || items.isEmpty()) {
            return false;
        }

        Instant latest = null;
        for (JsonNode item : items) {
            String createdAt = item.path(dateField).asText("");
            Instant createdInstant = parseInstant(createdAt);
            if (createdInstant == null) {
                continue;
            }
            if (latest == null || createdInstant.isAfter(latest)) {
                latest = createdInstant;
            }
        }

        if (latest == null) {
            return false;
        }

        long seconds = Math.abs(Duration.between(lastUpdateInstant, latest).getSeconds());
        return seconds <= 5;
    }

    private Instant parseInstant(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Instant.parse(value);
        } catch (Exception e) {
            return null;
        }
    }

}
