package com.alticelabs.sigo.onecare.firebase.resource;

import com.alticelabs.sigo.onecare.firebase.dto.UserTeamRequest;
import com.alticelabs.sigo.onecare.firebase.service.UserTeamService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/api/user-teams")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserTeamResource {

    @Inject
    UserTeamService userTeamService;

    @POST
    @Path("/add")
    public Response addUserToTeam(UserTeamRequest request) {
        try {
            if (request.getUserId() == null || request.getUserId().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "userId is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (request.getTeamId() == null || request.getTeamId().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "teamId is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            userTeamService.addUserToTeam(request.getUserId(), request.getTeamId());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "User added to team successfully");
            response.put("userId", request.getUserId());
            response.put("teamId", request.getTeamId());

            return Response.ok(response).build();

        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(errorResponse)
                    .build();
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to add user to team: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @POST
    @Path("/add-batch")
    public Response addUsersToTeam(UserTeamRequest request) {
        try {
            if (request.getUserIds() == null || request.getUserIds().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "userIds list is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (request.getTeamId() == null || request.getTeamId().isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "teamId is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            userTeamService.addUsersToTeam(request.getUserIds(), request.getTeamId());

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Users added to team successfully");
            response.put("userCount", request.getUserIds().size());
            response.put("teamId", request.getTeamId());

            return Response.ok(response).build();

        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(errorResponse)
                    .build();
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to add users to team: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @DELETE
    @Path("/remove")
    public Response removeUserFromTeam(@QueryParam("userId") String userId, @QueryParam("teamId") String teamId) {
        try {
            if (userId == null || userId.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "userId query parameter is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            if (teamId == null || teamId.isEmpty()) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "teamId query parameter is required");
                return Response.status(Response.Status.BAD_REQUEST)
                        .entity(errorResponse)
                        .build();
            }

            boolean removed = userTeamService.removeUserFromTeam(userId, teamId);

            if (removed) {
                Map<String, Object> response = new HashMap<>();
                response.put("message", "User removed from team successfully");
                response.put("userId", userId);
                response.put("teamId", teamId);
                return Response.ok(response).build();
            } else {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "User-team membership not found");
                return Response.status(Response.Status.NOT_FOUND)
                        .entity(errorResponse)
                        .build();
            }

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to remove user from team: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/team/{teamId}/users")
    public Response getUsersInTeam(@PathParam("teamId") String teamId) {
        try {
            List<String> users = userTeamService.getUsersInTeam(teamId);

            Map<String, Object> response = new HashMap<>();
            response.put("teamId", teamId);
            response.put("users", users);
            response.put("userCount", users.size());

            return Response.ok(response).build();

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve team users: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/user/{userId}/teams")
    public Response getTeamsForUser(@PathParam("userId") String userId) {
        try {
            List<String> teams = userTeamService.getTeamsForUser(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("teams", teams);
            response.put("teamCount", teams.size());

            return Response.ok(response).build();

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to retrieve user teams: " + e.getMessage());
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(errorResponse)
                    .build();
        }
    }

    @GET
    @Path("/stats")
    public Response getStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalTeams", userTeamService.getTeamCount());
        stats.put("totalMemberships", userTeamService.getMembershipCount());
        return Response.ok(stats).build();
    }
}
