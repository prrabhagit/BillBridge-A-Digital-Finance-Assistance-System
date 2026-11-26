package com.billbridge.controller;

import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
/** Access restricted to ROLE_ADMIN by SecurityConfig */
@RestController
@RequestMapping("/api/v1/admin/identity-verifications")
@RequiredArgsConstructor
@Tag(name = "Admin: identity verification")
public class AdminIdentityController {

    private final IdentityVerificationService service;

    @GetMapping
    public PageResponse<AdminIdentityVerificationResponse> list(
            @RequestParam(defaultValue = "PENDING") IdentityReviewStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.ASC) Pageable pageable) {
        return service.list(status, pageable);
