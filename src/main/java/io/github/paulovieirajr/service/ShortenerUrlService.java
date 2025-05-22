package io.github.paulovieirajr.service;

import io.github.paulovieirajr.entity.ShortenedUrl;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.jnosql.databases.mongodb.mapping.MongoDBTemplate;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@ApplicationScoped
public class ShortenerUrlService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShortenerUrlService.class);

    @Inject
    MongoDBTemplate mongoDBTemplate;

    @Inject
    @ConfigProperty(name = "mongodb.column.expiresat.ttl")
    Long ttl;

    public String createShortenerUrl(String url) {
        LOGGER.info("Creating shortened url for the following url: {}", url);
        String seed;
        do {
            seed = generateUrlSeed();
        } while (seedExists(seed));
        mongoDBTemplate
                .insert(new ShortenedUrl(seed, url, Date.from(Instant.now().plus(Duration.ofSeconds(ttl)))));
        LOGGER.info("Created shortened url");
        return seed;
    }

    public Optional<String> fetchShortenerUrl(String seed) {
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
}
