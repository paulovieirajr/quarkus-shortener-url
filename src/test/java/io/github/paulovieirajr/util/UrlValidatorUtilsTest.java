package io.github.paulovieirajr.util;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static io.github.paulovieirajr.commons.QuarkusTestConstants.INVALID_URL;
import static io.github.paulovieirajr.commons.QuarkusTestConstants.VALID_URL;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@QuarkusTest
class UrlValidatorUtilsTest {

    @InjectSpy
    UrlValidatorUtils urlValidatorUtils;

    @Test
    @DisplayName("Should assert true when an url is valid")
    void testIsValidUrl() {
        assertTrue(urlValidatorUtils.isValid(VALID_URL));
    }

    @Test
    @DisplayName("Should assert false when an url is invalid")
    void testIsValidInvalidUrl() {
        assertFalse(urlValidatorUtils.isValid(INVALID_URL));
    }
}