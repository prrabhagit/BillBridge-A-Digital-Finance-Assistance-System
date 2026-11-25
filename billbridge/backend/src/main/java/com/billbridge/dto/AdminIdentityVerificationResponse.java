package com.billbridge.dto;

import com.billbridge.entity.IdType;
import com.billbridge.entity.IdentityReviewStatus;
import java.time.Instant;
import java.util.UUID;

public record AdminIdentityVerificationResponse(UUID id, UUID userId, String userDisplayName, String countryCode,
                                                IdType idType, String idNumberLast4, String fullNameOnId,
                                                IdentityReviewStatus status, Instant submittedAt,
                                                Instant reviewedAt, String rejectionReason) {}
