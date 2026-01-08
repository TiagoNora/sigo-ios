package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.Map;

public class UserNotificationRequest {
    private String userId;
    private String title;
    private String body;
    private Map<String, String> data;

    public UserNotificationRequest() {
    }

    public UserNotificationRequest(String userId, String title, String body, Map<String, String> data) {
        this.userId = userId;
        this.title = title;
        this.body = body;
        this.data = data;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public Map<String, String> getData() {
        return data;
    }

    public void setData(Map<String, String> data) {
        this.data = data;
    }
}
