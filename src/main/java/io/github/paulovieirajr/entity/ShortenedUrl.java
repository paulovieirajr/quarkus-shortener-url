package io.github.paulovieirajr.entity;

import jakarta.nosql.Column;
import jakarta.nosql.Entity;
import jakarta.nosql.Id;

import java.time.LocalDate;
import java.util.Date;

/**
 * Represents a shortened URL entity.
 * <p>
 * This class is used to store the mapping between the shortened URL ID and the original URL.
 * It also includes an expiration date for the shortened URL.
 * </p>
 */
@Entity
public record ShortenedUrl(

        @Id
        String id,

        @Column
        String url,

        @Column
        LocalDate expiresAt
) {
}
