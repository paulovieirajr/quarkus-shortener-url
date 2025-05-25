package io.github.paulovieirajr.service.contract;

import io.github.paulovieirajr.entity.ShortenedUrl;

import java.util.Optional;

/**
 * Service interface for managing shortened URLs.
 * <p>
 * This interface provides methods to create and fetch shortened URLs.
 * </p>
 */
public interface ShortenedUrlService {

    /**
     * Creates a shortened URL for the given URL.
     * @param url the URL to be shortened
     * @return the shortened URL
     */
    String createShortenedUrl(String url);

    /**
     * Fetches the shortened URL entity for the given original URL.
     * @param originalUrl the original URL
     * @return an Optional containing the ShortenedUrl entity if found, or an empty Optional if not found
     */
    Optional<ShortenedUrl> findShortenedUrlByOriginalUrl(String originalUrl);

    /**
     * Fetches the original URL for the given shortened URL seed.
     * @param seed the shortened URL seed
     * @return an Optional containing the original URL if found, or an empty Optional if not found
     */
    Optional<String> findShortenedUrlBySeed(String seed);
}
