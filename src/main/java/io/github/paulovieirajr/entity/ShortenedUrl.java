package io.github.paulovieirajr.entity;

import jakarta.nosql.Column;
import jakarta.nosql.Entity;
import jakarta.nosql.Id;

import java.util.Date;

@Entity
public record ShortenedUrl(

        @Id
        String id,

        @Column
        String url,

        @Column
        Date expiresAt
) {
}
