package com.billbridge.dto;

import com.billbridge.entity.IdType;
import com.billbridge.entity.IdentityReviewStatus;
import java.time.Instant;
import java.util.UUID;

/** What the applicant sees about their own submission. The full ID number is never returned. */
public record IdentityVerificationResponse(UUID id, IdType idType, String idNumberLast4,
                                           IdentityReviewStatus status, Instant submittedAt,
                                           Instant reviewedAt, String rejectionReason) {}
