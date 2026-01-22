package com.alticelabs.sigo.onecare.firebase;

import java.util.HashMap;
import java.util.Map;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/hello")
@Produces(MediaType.APPLICATION_JSON)
public class ExampleResource {

    @GET
    public Response hello() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello World");

        return Response.ok(response).build();
    }
}
