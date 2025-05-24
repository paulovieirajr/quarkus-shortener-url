package io.github.paulovieirajr.service;

import io.github.paulovieirajr.entity.ShortenedUrl;
import io.github.paulovieirajr.service.contract.ShortenedUrlService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.jnosql.databases.mongodb.mapping.MongoDBTemplate;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

/**
 * Service for creating and fetching shortened URLs.
 * <p>
 * This service uses a MongoDB template to store and retrieve shortened URLs.
 * </p>
 */
@ApplicationScoped
public class ShortenerUrlServiceMongo implements ShortenedUrlService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShortenerUrlServiceMongo.class);

    @Inject
    MongoDBTemplate mongoDBTemplate;

    @Inject
    @ConfigProperty(name = "mongodb.column.expiresat.ttl")
    Long ttl;

    public String createShortenedUrl(String url) {
        LOGGER.info("Creating shortened url for the following url: {}", url);
        String seed;
        do {
            seed = generateUrlSeed();
        } while (seedExists(seed));
        mongoDBTemplate
                .insert(new ShortenedUrl(seed, url, getExpirationDate()));
        LOGGER.info("Created shortened url");
        return seed;
    }

    public Optional<String> fetchShortenedUrl(String seed) {
        LOGGER.info("Fetching shortened url for the following seed: {}", seed);
        return mongoDBTemplate
                .find(ShortenedUrl.class, seed)
                .map(ShortenedUrl::url);
    }

    private boolean seedExists(String seed) {
        LOGGER.info("Checking if seed {} already exists", seed);
        return mongoDBTemplate
                .find(ShortenedUrl.class, seed)
                .isPresent();
    }

    protected String generateUrlSeed() {
        return UUID.randomUUID()
                .toString()
                .substring(0, 8);
    }

    private LocalDate getExpirationDate() {
        return Instant.now()
                .plus(Duration.ofSeconds(ttl))
                .atZone(ZoneId.systemDefault())
                .toLocalDate();
    }
}
