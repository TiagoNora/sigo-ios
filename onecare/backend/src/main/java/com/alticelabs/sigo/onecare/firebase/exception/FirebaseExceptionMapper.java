package com.alticelabs.sigo.onecare.firebase.exception;

import com.google.firebase.messaging.FirebaseMessagingException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

@Provider
public class FirebaseExceptionMapper implements ExceptionMapper<FirebaseMessagingException> {

    private static final Logger LOGGER = Logger.getLogger(FirebaseExceptionMapper.class.getName());

    @Override
    public Response toResponse(FirebaseMessagingException exception) {
        LOGGER.severe("Firebase Messaging Exception: " + exception.getMessage());

        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put("error", "Firebase messaging error");
        errorResponse.put("message", exception.getMessage());

        String errorCode = exception.getMessagingErrorCode() != null
                ? exception.getMessagingErrorCode().name()
                : "UNKNOWN";
        errorResponse.put("errorCode", errorCode);

        Response.Status status = determineHttpStatus(errorCode);

        return Response.status(status)
                .entity(errorResponse)
                .type(MediaType.APPLICATION_JSON)
                .build();
    }

    private Response.Status determineHttpStatus(String errorCode) {
        return switch (errorCode) {
            case "INVALID_ARGUMENT", "UNREGISTERED" -> Response.Status.BAD_REQUEST;
            case "THIRD_PARTY_AUTH_ERROR", "QUOTA_EXCEEDED" -> Response.Status.FORBIDDEN;
            case "UNAVAILABLE", "INTERNAL" -> Response.Status.INTERNAL_SERVER_ERROR;
            default -> Response.Status.INTERNAL_SERVER_ERROR;
        };
    }
}
