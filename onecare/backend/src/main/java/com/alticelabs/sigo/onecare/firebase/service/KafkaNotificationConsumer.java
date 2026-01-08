package com.alticelabs.sigo.onecare.firebase.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.smallrye.common.annotation.RunOnVirtualThread;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Incoming;

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

            String ticketId = dataNode.path("id").asText("unknown");
            String ticketName = dataNode.path("name").asText("");

            List<String> tokens = collectTokens(root);
            if (tokens.isEmpty()) {
                LOGGER.info("No tokens for ticket " + ticketId + ", skipping notification.");
                return;
            }

            String title = String.format("Ticket %s %s", ticketId, summarizeEvent(eventType));
            JsonNode changesNode = resolveChanges(root);
            String body = buildBody(changesNode, dataNode);

            Map<String, String> data = new HashMap<>();
            data.put("ticketId", ticketId);
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
            int changeCount = changesNode != null && changesNode.isArray() ? changesNode.size() : 0;

            LOGGER.info(String.format(
                    "Prepared notification for ticket %s with %d change(s) and data payload: %s",
                    ticketId, changeCount, data));

            var response = firebaseService.sendMulticastNotification(tokens, title, body, data);
            response.getResults().stream()
                .filter(r -> !r.isSuccess())
                .forEach(r -> {
                    LOGGER.warning("Notification failed for token " + r.getToken() + " error=" + r.getError());
                    // Remove invalid token to avoid repeated failures
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
     * Determine eligible users for notification based on filtering rules:
     * - User is in assigned teams OR
     * - User is the ticket creator OR
     * - User is directly assigned to the ticket
     * BUT
     * - User is NOT the one who performed the action (no self-notifications)
     */
    private List<String> collectTokens(JsonNode root) {
        Set<String> eligibleUsers = new HashSet<>();

        // Extract ticket metadata
        JsonNode dataNode = root.path("data").path("value");
        String performedBy = optionalText(root, "header", "performedBy");
        String createdBy = dataNode.path("createdBy").asText(null);

        // Get assigned teams
        JsonNode assignedTeamsNode = dataNode.path("assignedTeams");
        List<String> assignedTeams = new ArrayList<>();
        if (assignedTeamsNode.isArray()) {
            for (JsonNode teamNode : assignedTeamsNode) {
                String teamId = teamNode.asText();
                if (teamId != null && !teamId.isEmpty()) {
                    assignedTeams.add(teamId);
                }
            }
        }

        // Get directly assigned users
        JsonNode assignedUsersNode = dataNode.path("assignedUsers");
        List<String> assignedUsers = new ArrayList<>();
        if (assignedUsersNode.isArray()) {
            for (JsonNode userNode : assignedUsersNode) {
                String userId = userNode.asText();
                if (userId != null && !userId.isEmpty()) {
                    assignedUsers.add(userId);
                }
            }
        }

        // Rule 1: Add all users from assigned teams
        if (!assignedTeams.isEmpty()) {
            Set<String> teamMembers = userTeamService.getUsersInTeams(assignedTeams);
            eligibleUsers.addAll(teamMembers);
            LOGGER.info(String.format("Found %d users in teams %s", teamMembers.size(), assignedTeams));
        }

        // Rule 2: Add ticket creator
        if (createdBy != null && !createdBy.isEmpty()) {
            eligibleUsers.add(createdBy);
            LOGGER.info("Added ticket creator: " + createdBy);
        }

        // Rule 3: Add directly assigned users
        if (!assignedUsers.isEmpty()) {
            eligibleUsers.addAll(assignedUsers);
            LOGGER.info(String.format("Added %d directly assigned users", assignedUsers.size()));
        }

        // Rule 4: Remove the action performer (no self-notifications)
        if (performedBy != null && !performedBy.isEmpty()) {
            boolean wasRemoved = eligibleUsers.remove(performedBy);
            if (wasRemoved) {
                LOGGER.info("Excluded action performer from notifications: " + performedBy);
            }
        }

        // Collect all device tokens for eligible users
        List<String> allTokens = new ArrayList<>();
        for (String userId : eligibleUsers) {
            List<String> userTokens = tokenStorageService.getTokensForUser(userId);
            allTokens.addAll(userTokens);
        }

        LOGGER.info(String.format(
                "Notification filtering: %d eligible users, %d total tokens (creator=%s, teams=%s, performedBy=%s)",
                eligibleUsers.size(), allTokens.size(), createdBy, assignedTeams, performedBy));

        return allTokens;
    }

    private String buildBody(JsonNode changes, JsonNode dataNode) {
        List<String> parts = new ArrayList<>();
        if (changes.isArray()) {
            for (JsonNode change : changes) {
                String type = change.path("type").asText("");
                if ("FieldChange".equalsIgnoreCase(type)) {
                    String field = change.path("fieldName").asText("");
                    String oldVal = change.path("oldValue").asText("");
                    String newVal = change.path("newValue").asText("");
                    parts.add(String.format("%s: %s → %s", field, oldVal, newVal));
                } else if ("Note".equalsIgnoreCase(type)) {
                    parts.add("Note added");
                } else {
                    parts.add(type);
                }
            }
        }

        if (parts.isEmpty()) {
            parts.add("Ticket updated");
        }

        String status = dataNode.path("status").asText("");
        if (!status.isEmpty()) {
            parts.add("Status: " + status);
        }

        return String.join(" | ", parts);
    }

    private String summarizeEvent(String eventType) {
        if (eventType == null || eventType.isEmpty()) return "updated";
        return eventType.toLowerCase(Locale.ROOT);
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
}
