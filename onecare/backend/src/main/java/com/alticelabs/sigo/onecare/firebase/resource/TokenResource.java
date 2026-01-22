package com.alticelabs.sigo.onecare.firebase.resource;

import com.alticelabs.sigo.onecare.firebase.dto.DeviceTokenRequest;
import com.alticelabs.sigo.onecare.firebase.service.TokenStorageService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/api/tokens")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class TokenResource {

    @Inject
    TokenStorageService tokenStorageService;

    @POST
    @Path("/register")
    public Response registerToken(DeviceTokenRequest request) {
        try {
            if (request.getUserId() == null || request.getUserId().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "userId is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (request.getDeviceToken() == null || request.getDeviceToken().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "deviceToken is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            tokenStorageService.registerToken(request.getUserId(), request.getDeviceToken());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Device token registered successfully");
            response.put("userId", request.getUserId());
            response.put("deviceToken", request.getDeviceToken());

            return Response.ok(response).build();

        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(errorResponse)
                    .build();
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to register token: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @DELETE
    @Path("/unregister")
    public Response unregisterToken(@QueryParam("token") String deviceToken) {
        try {
            if (deviceToken == null || deviceToken.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "token query parameter is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            boolean removed = tokenStorageService.unregisterToken(deviceToken);

            if (removed) {
                Map<String, Object> response = new HashMap<>();
                response.put("message", "Device token unregistered successfully");
                response.put("deviceToken", deviceToken);
                return Response.ok(response).build();
            } else {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Token not found");
                return Response.status(Response.Status.NOT_FOUND)
                        .entity(errorResponse)
                        .build();
            }

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to unregister token: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/user/{userId}")
    public Response getUserTokens(@PathParam("userId") String userId) {
        try {
            List<String> tokens = tokenStorageService.getTokensForUser(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("tokens", tokens);
            response.put("tokenCount", tokens.size());

            return Response.ok(response).build();

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve tokens: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/stats")
    public Response getStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", tokenStorageService.getUserCount());
        stats.put("totalTokens", tokenStorageService.getTokenCount());
        return Response.ok(stats).build();
    }
}
