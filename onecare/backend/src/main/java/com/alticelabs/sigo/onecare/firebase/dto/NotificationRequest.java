package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.List;
import java.util.Map;

public class NotificationRequest {
    private String title;
    private String body;
    private String titleLocKey;
    private java.util.List<String> titleLocArgs;
    private String bodyLocKey;
    private java.util.List<String> bodyLocArgs;
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
