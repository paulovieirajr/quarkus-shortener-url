package io.github.paulovieirajr.commons;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

public class QuarkusTestConstants {

    public static final String VALID_URL = "https://quarkus.io/";
    public static final String INVALID_URL = "quarkus-invalid-url";
    public static final String SEED = UUID.randomUUID()
            .toString()
            .substring(0, 8);
    public static final LocalDate TTL = Instant.now()
            .plus(Duration.ofSeconds(300))
            .atZone(ZoneId.systemDefault())
            .toLocalDate();
}
