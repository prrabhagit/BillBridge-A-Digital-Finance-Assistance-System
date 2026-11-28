package com.billbridge.dto;

import com.billbridge.entity.IdType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record IdentitySubmitRequest(
        @NotNull IdType idType,
        @NotBlank @Size(min = 4, max = 40) String idNumber,
        @NotBlank @Size(min = 2, max = 160) String fullNameOnId) {}
