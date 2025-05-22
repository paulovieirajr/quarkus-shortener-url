package io.github.paulovieirajr.service;

import io.github.paulovieirajr.entity.ShortenedUrl;
import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.mockito.InjectSpy;
import org.eclipse.jnosql.databases.mongodb.mapping.MongoDBTemplate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.List;
import java.util.Optional;

import static io.github.paulovieirajr.commons.QuarkusTestConstants.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@QuarkusTest
class ShortenerUrlServiceTest {

    @InjectMock
    MongoDBTemplate mongoDBTemplate;

    @InjectSpy
    ShortenerUrlService shortenerUrlService;

    @Test
    @DisplayName("Should create a shortened url")
    void shouldCreateShortenedUrl() {
        Mockito.doReturn(SEED).when(shortenerUrlService).generateUrlSeed();
        Mockito.when(mongoDBTemplate.insert(Mockito.anyCollection()))
                .thenReturn(List.of(new ShortenedUrl(SEED, VALID_URL, TTL)));

        String result = shortenerUrlService.createShortenerUrl(VALID_URL);
        assertEquals(SEED, result);
    }

    @Test
    @DisplayName("Should recover the original url")
    void shouldRecoverOriginalUrl() {
        Mockito.when(mongoDBTemplate.find(ShortenedUrl.class, SEED))
                .thenReturn(Optional.of(new ShortenedUrl(SEED, VALID_URL, TTL)));

        Optional<String> result = shortenerUrlService.fetchShortenerUrl(SEED);

        assertTrue(result.isPresent());
        assertEquals(VALID_URL, result.get());
    }
}