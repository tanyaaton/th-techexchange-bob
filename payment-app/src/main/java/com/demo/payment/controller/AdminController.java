package com.demo.payment.controller;

import com.demo.payment.service.CacheService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@CrossOrigin(origins = "${cors.allowed.origins:http://localhost:3000}")
public class AdminController {

    private final CacheService cacheService;
    
    // SECURITY FIX: Admin API key loaded from environment variables
    @Value("${admin.api.key:}")
    private String adminApiKey;

    public AdminController(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @PostMapping("/cache/clear")
    public ResponseEntity<Map<String, String>> clearCache(
            @RequestHeader(value = "X-Admin-API-Key", required = false) String providedApiKey) {
        
        // Validate API key
        if (adminApiKey == null || adminApiKey.isEmpty()) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Admin API key not configured");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
        
        if (providedApiKey == null || !adminApiKey.equals(providedApiKey)) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Unauthorized: Invalid or missing API key");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }
        
        try {
            cacheService.clearAllCaches();
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "All caches cleared successfully");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Failed to clear cache: " + e.getMessage());
            
            return ResponseEntity.internalServerError().body(response);
        }
    }
}

// Made with Bob
