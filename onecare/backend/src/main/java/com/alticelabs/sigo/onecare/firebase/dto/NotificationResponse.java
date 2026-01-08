package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.ArrayList;
import java.util.List;

public class NotificationResponse {
    private int successCount;
    private int failureCount;
    private List<NotificationResult> results;

    public NotificationResponse() {
        this.results = new ArrayList<>();
    }

    public NotificationResponse(int successCount, int failureCount, List<NotificationResult> results) {
        this.successCount = successCount;
        this.failureCount = failureCount;
        this.results = results;
    }

    public int getSuccessCount() {
        return successCount;
    }

    public void setSuccessCount(int successCount) {
        this.successCount = successCount;
    }

    public int getFailureCount() {
        return failureCount;
    }

    public void setFailureCount(int failureCount) {
        this.failureCount = failureCount;
    }

    public List<NotificationResult> getResults() {
        return results;
    }

    public void setResults(List<NotificationResult> results) {
        this.results = results;
    }

    public static class NotificationResult {
        private String token;
        private boolean success;
        private String messageId;
        private String error;

        public NotificationResult() {
        }

        public NotificationResult(String token, boolean success, String messageId, String error) {
            this.token = token;
            this.success = success;
            this.messageId = messageId;
            this.error = error;
        }

        public String getToken() {
            return token;
        }

        public void setToken(String token) {
            this.token = token;
        }

        public boolean isSuccess() {
            return success;
        }

        public void setSuccess(boolean success) {
            this.success = success;
        }

        public String getMessageId() {
            return messageId;
        }

        public void setMessageId(String messageId) {
            this.messageId = messageId;
        }

        public String getError() {
            return error;
        }

        public void setError(String error) {
            this.error = error;
        }
    }
}
