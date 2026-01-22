package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.Map;

public class UserNotificationRequest {
    private String userId;
    private String title;
    private String body;
    private String titleLocKey;
    private java.util.List<String> titleLocArgs;
    private String bodyLocKey;
    private java.util.List<String> bodyLocArgs;
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

    public String getTitleLocKey() {
        return titleLocKey;
    }

    public void setTitleLocKey(String titleLocKey) {
        this.titleLocKey = titleLocKey;
    }

    public java.util.List<String> getTitleLocArgs() {
        return titleLocArgs;
    }

    public void setTitleLocArgs(java.util.List<String> titleLocArgs) {
        this.titleLocArgs = titleLocArgs;
    }

    public String getBodyLocKey() {
        return bodyLocKey;
    }

    public void setBodyLocKey(String bodyLocKey) {
        this.bodyLocKey = bodyLocKey;
    }

    public java.util.List<String> getBodyLocArgs() {
        return bodyLocArgs;
    }

    public void setBodyLocArgs(java.util.List<String> bodyLocArgs) {
        this.bodyLocArgs = bodyLocArgs;
    }

    public Map<String, String> getData() {
        return data;
    }

    public void setData(Map<String, String> data) {
        this.data = data;
    }
}
