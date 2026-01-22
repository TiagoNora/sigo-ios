package com.alticelabs.sigo.onecare.firebase;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;

@QuarkusTest
class NotificationResourceTest {

  @Test
  void sendToTopicRequiresType() {
    given()
        .contentType(ContentType.JSON)
        .body("{\"topic\":\"tenant\"}")
        .when().post("/api/notifications/send-to-topic")
        .then()
        .statusCode(400)
        .body("error", is("type is required"));
  }
}
