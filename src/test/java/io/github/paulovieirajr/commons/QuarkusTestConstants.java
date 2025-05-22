package io.github.paulovieirajr.commons;

import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

public class QuarkusTestConstants {

    public static final String VALID_URL = "https://quarkus.io/";
    public static final String INVALID_URL = "quarkus-invalid-url";
    public static final String SEED = UUID.randomUUID().toString().substring(0, 8);
    public static final Date TTL = Date.from(Instant.now().plus(Duration.ofSeconds(300)));
}
