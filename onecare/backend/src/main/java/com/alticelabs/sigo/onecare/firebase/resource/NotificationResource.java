package com.alticelabs.sigo.onecare.firebase.resource;

import com.alticelabs.sigo.onecare.firebase.dto.NotificationRequest;
import com.alticelabs.sigo.onecare.firebase.dto.NotificationResponse;
import com.alticelabs.sigo.onecare.firebase.dto.UserNotificationRequest;
import com.alticelabs.sigo.onecare.firebase.service.FirebaseService;
import com.alticelabs.sigo.onecare.firebase.service.TokenStorageService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/api/notifications")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NotificationResource {

    @Inject
    FirebaseService firebaseService;

    @Inject
    TokenStorageService tokenStorageService;

    @POST
    @Path("/send")
    public Response sendNotification(NotificationRequest request) {
        try {
            if (request.getTokens() == null || request.getTokens().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Device tokens are required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (request.getTitle() == null || request.getTitle().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Notification title is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            NotificationResponse result = firebaseService.sendMulticastNotification(
                    request.getTokens(),
                    request.getTitle(),
                    request.getBody(),
                    request.getData()
            );

            return Response.ok(result).build();

        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(errorResponse)
                    .build();
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to send notifications: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @POST
    @Path("/send-to-user")
    public Response sendToUser(UserNotificationRequest request) {
        try {
            if (request.getUserId() == null || request.getUserId().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "userId is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (request.getTitle() == null || request.getTitle().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Notification title is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            // Get tokens for the user
            List<String> tokens = tokenStorageService.getTokensForUser(request.getUserId());

            if (tokens.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "No device tokens found for user: " + request.getUserId());
                return Response.status(Response.Status.NOT_FOUND)
                        .entity(errorResponse)
                        .build();
            }

            // Send notification to all user's devices
            NotificationResponse result = firebaseService.sendMulticastNotification(
                    tokens,
                    request.getTitle(),
                    request.getBody(),
                    request.getData()
            );

            return Response.ok(result).build();

        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(errorResponse)
                    .build();
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to send notifications: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/health")
    public Response health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "ok");
        response.put("service", "Firebase Notification Service");
        return Response.ok(response).build();
    }
}
