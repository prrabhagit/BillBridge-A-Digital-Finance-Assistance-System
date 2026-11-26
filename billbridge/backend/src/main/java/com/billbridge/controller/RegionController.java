package com.billbridge.controller;

import com.billbridge.dto.CountryResponse;
import com.billbridge.dto.CreateRegionRequest;
import com.billbridge.dto.RegionResponse;
import com.billbridge.security.AuthenticatedUser;
import com.billbridge.service.RegionService;
import com.billbridge.util.ClientInfo;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Countries and regions")
public class RegionController {

    private final RegionService regionService;

    /** Public: powers the country picker (and shows which currency each country uses). */
    @GetMapping("/countries")
    public List<CountryResponse> countries() {
        return regionService.listCountries();
    }

    /** Public: regions the user can choose from for their country, e.g. ?country=NP */
    @GetMapping("/regions")
    public List<RegionResponse> regions(@RequestParam("country") String country) {
        return regionService.listRegions(country);
    }

    /** Admin-only (enforced in SecurityConfig for /admin/**): add regions for any country. */
    @PostMapping("/admin/regions")
    @ResponseStatus(HttpStatus.CREATED)
    public RegionResponse createRegion(@AuthenticationPrincipal AuthenticatedUser admin,
                                       @Valid @RequestBody CreateRegionRequest request, HttpServletRequest http) {
        return regionService.create(admin.id(), request, ClientInfo.from(http));
    }
}
