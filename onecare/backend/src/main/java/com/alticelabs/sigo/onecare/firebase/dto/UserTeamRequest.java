package com.alticelabs.sigo.onecare.firebase.dto;

import java.util.List;

public class UserTeamRequest {
    private String userId;
    private String teamId;
    private List<String> userIds; // For batch operations

    public UserTeamRequest() {
    }

    public UserTeamRequest(String userId, String teamId) {
        this.userId = userId;
        this.teamId = teamId;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getTeamId() {
        return teamId;
    }

    public void setTeamId(String teamId) {
        this.teamId = teamId;
    }

    public List<String> getUserIds() {
        return userIds;
    }

    public void setUserIds(List<String> userIds) {
        this.userIds = userIds;
    }
}
