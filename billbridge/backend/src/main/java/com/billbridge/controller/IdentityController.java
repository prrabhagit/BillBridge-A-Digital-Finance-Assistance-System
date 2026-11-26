package com.billbridge.controller;

import com.billbridge.dto.IdentitySubmitRequest;
import com.billbridge.dto.IdentityVerificationResponse;
import com.billbridge.security.AuthenticatedUser;
import com.billbridge.service.IdentityVerificationService;
import com.billbridge.util.ClientInfo;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/identity-verifications")
@RequiredArgsConstructor
@Tag(name = "Identity verification")
public class IdentityController {

    private final IdentityVerificationService service;

    /** multipart/form-data: part "data" (JSON) + part "document" (JPEG, PNG or PDF, max 5 MB). */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public IdentityVerificationResponse submit(@AuthenticationPrincipal AuthenticatedUser me,
                                               @Valid @RequestPart("data") IdentitySubmitRequest data,
                                               @RequestPart("document") MultipartFile document,
                                               HttpServletRequest http) {
        return service.submit(me.id(), data, document, ClientInfo.from(http));
    }

    @GetMapping("/mine")
    public IdentityVerificationResponse mine(@AuthenticationPrincipal AuthenticatedUser me) {
        return service.latestForUser(me.id());
    }
}
