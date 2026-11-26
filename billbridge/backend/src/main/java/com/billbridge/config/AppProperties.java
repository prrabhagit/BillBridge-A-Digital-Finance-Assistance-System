package com.billbridge.config;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "billbridge")
public record AppProperties(Jwt jwt, Auth auth, RateLimit rateLimit, Storage storage,
                            Identity identity, Bootstrap bootstrap, Cors cors) {

    public record Jwt(String secret, Duration accessTtl, Duration refreshTtl, String issuer) {}

    public record Auth(boolean requireEmailVerification, int maxFailedAttempts,
                       Duration lockDuration, Duration emailTokenTtl) {}

    public record RateLimit(int authPerMinute) {}

    public record Storage(String localRoot) {}

    public record Identity(String hmacKey) {}

    public record Bootstrap(String adminEmail, String adminPassword, String adminCountry) {}

    public record Cors(List<String> allowedOrigins) {}
}
