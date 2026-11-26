package com.billbridge.controller;

import com.billbridge.dto.AuthResponse;
import com.billbridge.dto.LoginRequest;
import com.billbridge.dto.MessageResponse;
import com.billbridge.dto.RefreshRequest;
import com.billbridge.dto.RegisterRequest;
import com.billbridge.dto.UserResponse;
import com.billbridge.dto.VerifyEmailRequest;
import com.billbridge.service.AuthService;
import com.billbridge.service.EmailVerificationService;
import com.billbridge.util.ClientInfo;
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
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication")
public class AuthController {

    private final AuthService authService;
    private final EmailVerificationService emailVerification;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse register(@Valid @RequestBody RegisterRequest request, HttpServletRequest http) {
        return authService.register(request, ClientInfo.from(http));
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest http) {
        return authService.login(request, ClientInfo.from(http));
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request, HttpServletRequest http) {
        return authService.refresh(request.refreshToken(), ClientInfo.from(http));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest request) {
        authService.logout(request.refreshToken());
    }

    /** POST (not GET): a state-changing action must not be triggerable by link prefetchers or email scanners. */
    @PostMapping("/verify-email")
    public MessageResponse verifyEmail(@Valid @RequestBody VerifyEmailRequest request, HttpServletRequest http) {
        emailVerification.verify(request.token(), ClientInfo.from(http));
        return new MessageResponse("Email verified");
    }
}
