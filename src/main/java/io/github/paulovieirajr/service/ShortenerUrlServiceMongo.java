package io.github.paulovieirajr.service;

import io.github.paulovieirajr.entity.ShortenedUrl;
import io.github.paulovieirajr.service.contract.ShortenedUrlService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.jnosql.communication.semistructured.CriteriaCondition;
import org.eclipse.jnosql.communication.semistructured.SelectQuery;
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

    /**
     * Creates a shortened URL for the given URL.
     *
     * @param url the URL to be shortened
     * @return the shortened URL
     */
    public String createShortenedUrl(String url) {
        Optional<ShortenedUrl> shortenedUrl = findShortenedUrlByOriginalUrl(url);
        if (shortenedUrl.isPresent()) {
            LOGGER.info("Url already exists, returning existing seed");
            return shortenedUrl.get().id();
        }
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

    /**
     * Fetches the shortened URL entity for the given original URL.
     *
     * @param originalUrl the original URL
     * @return an Optional containing the ShortenedUrl entity if found, or an empty Optional if not found
     */
    public Optional<ShortenedUrl> findShortenedUrlByOriginalUrl(String originalUrl) {
        LOGGER.info("Checking if url exists");

        return mongoDBTemplate.singleResult(
                SelectQuery.builder()
                        .from("ShortenedUrl")
                        .where(CriteriaCondition.eq("url", originalUrl))
                        .build()
        );
    }

    /**
     * Fetches the original URL for the given shortened URL seed.
     *
     * @param seed the shortened URL seed
     * @return an Optional containing the original URL if found, or an empty Optional if not found
     */
    public Optional<String> findShortenedUrlBySeed(String seed) {
        LOGGER.info("Fetching shortened url for the following seed: {}", seed);
        return mongoDBTemplate
                .find(ShortenedUrl.class, seed)
                .map(ShortenedUrl::url);
    }

    /**
     * Checks if a seed already exists in the database.
     *
     * @param seed the seed to check
     * @return true if the seed exists, false otherwise
     */
    private boolean seedExists(String seed) {
        LOGGER.info("Checking if seed {} already exists", seed);
        return mongoDBTemplate
                .find(ShortenedUrl.class, seed)
                .isPresent();
    }

    /**
     * Generates a random seed for the shortened URL.
     *
     * @return a random seed
     */
    protected String generateUrlSeed() {
        return UUID.randomUUID()
                .toString()
                .substring(0, 8);
    }

    /**
     * Gets the expiration date for the shortened URL.
     *
     * @return the expiration date
     */
    private LocalDate getExpirationDate() {
        return Instant.now()
                .plus(Duration.ofSeconds(ttl))
                .atZone(ZoneId.systemDefault())
                .toLocalDate();
    }
}
