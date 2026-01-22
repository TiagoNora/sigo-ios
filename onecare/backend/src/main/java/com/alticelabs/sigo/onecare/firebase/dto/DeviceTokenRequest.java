package com.alticelabs.sigo.onecare.firebase.dto;

public class DeviceTokenRequest {
    private String userId;
    private String deviceToken;

    public DeviceTokenRequest() {
    }

    public DeviceTokenRequest(String userId, String deviceToken) {
        this.userId = userId;
        this.deviceToken = deviceToken;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getDeviceToken() {
        return deviceToken;
    }

    public void setDeviceToken(String deviceToken) {
        this.deviceToken = deviceToken;
    }
}
