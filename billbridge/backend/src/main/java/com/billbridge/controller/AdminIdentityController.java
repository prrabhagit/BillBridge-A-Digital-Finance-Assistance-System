package com.billbridge.controller;

import com.billbridge.dto.AdminIdentityVerificationResponse;
import com.billbridge.dto.PageResponse;
import com.billbridge.dto.RejectRequest;
import com.billbridge.entity.IdentityReviewStatus;
import com.billbridge.security.AuthenticatedUser;
import com.billbridge.service.IdentityVerificationService;
import com.billbridge.util.ClientInfo;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
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
    }

    @GetMapping("/{id}/document")
    public ResponseEntity<byte[]> document(@PathVariable UUID id, @AuthenticationPrincipal AuthenticatedUser admin,
                                           HttpServletRequest http) {
        IdentityVerificationService.StoredDocument doc = service.loadDocumentForReview(id, admin.id(), ClientInfo.from(http));
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(doc.contentType()))
                .cacheControl(CacheControl.noStore())
                .header("X-Content-Type-Options", "nosniff")
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"document\"")
                .body(doc.bytes());
    }

    @PostMapping("/{id}/approve")
    public AdminIdentityVerificationResponse approve(@PathVariable UUID id,
                                                     @AuthenticationPrincipal AuthenticatedUser admin,
                                                     HttpServletRequest http) {
        return service.approve(id, admin.id(), ClientInfo.from(http));
    }

    @PostMapping("/{id}/reject")
    public AdminIdentityVerificationResponse reject(@PathVariable UUID id,
                                                    @AuthenticationPrincipal AuthenticatedUser admin,
                                                    @Valid @RequestBody RejectRequest request, HttpServletRequest http) {
        return service.reject(id, admin.id(), request.reason(), ClientInfo.from(http));
    }
}
