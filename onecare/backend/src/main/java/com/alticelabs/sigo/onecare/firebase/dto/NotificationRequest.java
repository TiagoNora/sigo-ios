package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.List;
import java.util.Map;

public class NotificationRequest {
    private String title;
    private String body;
    private List<String> tokens;
    private Map<String, String> data;

    public NotificationRequest() {
    }

    public NotificationRequest(String title, String body, List<String> tokens, Map<String, String> data) {
        this.title = title;
        this.body = body;
        this.tokens = tokens;
        this.data = data;
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

    public List<String> getTokens() {
        return tokens;
    }

    public void setTokens(List<String> tokens) {
        this.tokens = tokens;
    }

    public Map<String, String> getData() {
        return data;
    }

    public void setData(Map<String, String> data) {
        this.data = data;
    }
}
