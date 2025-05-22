package io.github.paulovieirajr.util;

import jakarta.enterprise.context.ApplicationScoped;
import org.apache.commons.validator.routines.UrlValidator;

@ApplicationScoped
public class UrlValidatorUtils {

    private final UrlValidator validator = new UrlValidator(new String[]{"http", "https"});

    public boolean isValid(String url) {
        return validator.isValid(url);
    }
}
