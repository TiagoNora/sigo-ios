package com.alticelabs.sigo.onecare.firebase.dto;

public class TopicNotificationResponse {
    private String topic;
    private String messageId;

    public TopicNotificationResponse() {
    }

    public TopicNotificationResponse(String topic, String messageId) {
        this.topic = topic;
        this.messageId = messageId;
    }

    public String getTopic() {
        return topic;
    }

    public void setTopic(String topic) {
        this.topic = topic;
    }

    public String getMessageId() {
        return messageId;
    }

    public void setMessageId(String messageId) {
        this.messageId = messageId;
    }
}
