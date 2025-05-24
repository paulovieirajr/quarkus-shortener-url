package io.github.paulovieirajr.controller;

import io.github.paulovieirajr.service.contract.ShortenedUrlService;
import io.github.paulovieirajr.util.UrlValidatorUtils;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.UriInfo;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;

/**
 * ShortenerUrlResource is a RESTful resource that provides endpoints for URL shortening and retrieval.
 * It allows users to shorten a given URL and retrieve the original URL using a shortened seed.
 */
@Tag(name = "ShortenerUrlResource", description = "Generate compact URL and fetch the original")
@RequestScoped
@Path("/")
public class ShortenerUrlResource {

    private static final Logger log = LoggerFactory.getLogger(ShortenerUrlResource.class);

    @Inject
    ShortenedUrlService shortenerUrlService;

    @Inject
    UrlValidatorUtils urlValidatorUtils;

    @POST
    @Path("/shortener")
    @Consumes(MediaType.TEXT_PLAIN)
    @Produces(MediaType.TEXT_PLAIN)
    @Operation(summary = "Shorten a URL")
    @APIResponse(responseCode = "201", description = "URL shortened successfully")
    @APIResponse(responseCode = "400", description = "Invalid URL format")
    @APIResponse(responseCode = "500", description = "Internal server error")
    public Response shortenUrl(String url, @Context UriInfo uriInfo) {
        if (!urlValidatorUtils.isValid(url)) {
            log.error("Invalid URL: {}", url);
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Invalid URL format")
                    .build();
        }


        String baseUri = uriInfo.getBaseUri().toString();
        log.info("Shortening URL: {} | Base URI: {}", url, baseUri);
        String shortenerUrl = shortenerUrlService.createShortenedUrl(url);
        return Response
                .created(URI.create(shortenerUrl))
                .entity(baseUri.concat(shortenerUrl))
                .type(MediaType.TEXT_PLAIN)
                .build();
    }

    @GET
    @Path("/{seed}")
    @Operation(summary = "Fetch the original URL", hidden = true)
    @APIResponse(responseCode = "204", description = "Shortened URL not found")
    @APIResponse(responseCode = "302", description = "Original URL found")
    @APIResponse(responseCode = "500", description = "Internal server error")
    public Response getOriginalUrl(@PathParam("seed") String seed, @Context UriInfo uriInfo) {
        String baseUri = uriInfo.getBaseUri().toString();
        log.info("Recovering URL for seed: {} | Base URI: {}", seed, baseUri);
        return shortenerUrlService.fetchShortenedUrl(seed)
                .map(originalUrl -> {
                    log.info("Original URL has been found: {}", originalUrl);
                    return Response
                            .status(Response.Status.FOUND)
                            .header("Location", originalUrl)
                            .build();
                })
                .orElseGet(() -> {
                    log.info("Original URL hasn't been found");
                    return Response.status(Response.Status.NO_CONTENT).build();
                });
    }
}
