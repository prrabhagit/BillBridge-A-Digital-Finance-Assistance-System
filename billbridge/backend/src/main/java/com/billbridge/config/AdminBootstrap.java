package com.billbridge.config;
public package com.billbridge.config;
import com.billbridge.audit.AuditService;
import com.billbridge.entity.Role;
import com.billbridge.entity.RoleName;
import com.billbridge.entity.User;
import com.billbridge.repository.RoleRepository;
import com.billbridge.repository.UserRepository;
import com.billbridge.util.CountryCurrency;
import java.util.Locale;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Creates the first administrator from environment variables, only if no admin exists yet.
 * There is deliberately no public way to register an admin.
 */
@Component
@RequiredArgsConstructor
public class AdminBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminBootstrap.class);

    private final AppProperties props;
    private final UserRepository users;
    private final RoleRepository roles;
    private final PasswordEncoder encoder;
    private final AuditService audit;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        AppProperties.Bootstrap b = props.bootstrap();
        if (b == null || isBlank(b.adminEmail()) || isBlank(b.adminPassword())) {
            return;
        }
        if (users.existsByRoles_Name(RoleName.ADMIN)) {
            return;
        }
        if (b.adminPassword().length() < 12) {
            throw new IllegalStateException("BOOTSTRAP_ADMIN_PASSWORD must be at least 12 characters");
        }
        String country = (isBlank(b.adminCountry()) ? "NP" : b.adminCountry()).toUpperCase(Locale.ROOT);
        String currency = CountryCurrency.currencyFor(country)
                .orElseThrow(() -> new IllegalStateException("Invalid BOOTSTRAP_ADMIN_COUNTRY: " + country));
        Role adminRole = roles.findByName(RoleName.ADMIN).orElseThrow();

        User admin = new User();
        admin.setEmail(b.adminEmail().trim().toLowerCase(Locale.ROOT));
        admin.setPasswordHash(encoder.encode(b.adminPassword()));
        admin.setDisplayName("Administrator");
        admin.setCountryCode(country);
        admin.setCurrencyCode(currency);
        admin.setEmailVerified(true);
        admin.getRoles().add(adminRole);
        users.save(admin);
        audit.record(null, "ADMIN_BOOTSTRAPPED", "USER", admin.getId().toString(), Map.of(), null);
        log.info("Bootstrap administrator created: {}", admin.getEmail());
    }
private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}