package io.github.paulovieirajr.controller;

import io.github.paulovieirajr.service.ShortenerUrlService;
import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import org.apache.http.HttpStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.Optional;

import static io.github.paulovieirajr.commons.QuarkusTestConstants.*;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

@QuarkusTest
class ShortenerUrlResourceTest {

    @InjectMock
    ShortenerUrlService shortenerUrlService;

    @Test
    @DisplayName("Should create a shortened url")
    void shouldCreateShortenerUrl() {
        Mockito.when(shortenerUrlService.createShortenerUrl(VALID_URL))
                .thenReturn("http:localhost:8080/" + SEED);

        given()
                .body(VALID_URL)
                .when().post("/shortener")
                .then()
                .statusCode(HttpStatus.SC_CREATED);
    }

    @Test
    @DisplayName("Should return bad request if an url has an invalid format")
    void shouldResponseBadRequestWhenUrlIsInvalid() {
        given()
                .body(INVALID_URL)
                .when().post("/shortener")
                .then()
                .statusCode(HttpStatus.SC_BAD_REQUEST);
    }

    @Test
    @DisplayName("Should response with a redirect for original url")
    void shouldResponseWithOriginalUrlWhenExistsInDatabase() {
        Mockito.when(shortenerUrlService.fetchShortenerUrl(SEED))
                .thenReturn(Optional.of(VALID_URL));

        given()
                .redirects().follow(false)
                .when().get("/" + SEED)
                .then()
                .statusCode(HttpStatus.SC_MOVED_TEMPORARILY)
                .header("Location", equalTo(VALID_URL));
    }

    @Test
    @DisplayName("Should response with no content if url does not exist in database")
    void shouldResponseWithNoContentIfUrlIsNotFound() {
        given()
                .when().get("/" + SEED)
                .then()
                .statusCode(HttpStatus.SC_NO_CONTENT);
    }
}