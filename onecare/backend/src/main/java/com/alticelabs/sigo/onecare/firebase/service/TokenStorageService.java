package com.alticelabs.sigo.onecare.firebase.service;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.logging.Logger;

@ApplicationScoped
public class TokenStorageService {

    private static final Logger LOGGER = Logger.getLogger(TokenStorageService.class.getName());

    private static final String DB_FILENAME = "tokens.db";
    private static final String DB_URL_PREFIX = "jdbc:sqlite:";
    private Connection connection;

    @PostConstruct
    void init() {
        try {
            Path dbPath = Path.of(DB_FILENAME).toAbsolutePath();
            if (dbPath.getParent() != null && !Files.exists(dbPath.getParent())) {
                Files.createDirectories(dbPath.getParent());
            }
            Class.forName("org.sqlite.JDBC");
            connection = DriverManager.getConnection(DB_URL_PREFIX + dbPath);
            createTablesIfNeeded();
            LOGGER.info("TokenStorageService initialized with SQLite at " + dbPath);
        } catch (Exception e) {
            LOGGER.severe("Failed to initialize SQLite token storage: " + e.getMessage());
            throw new IllegalStateException("Cannot initialize token storage", e);
        }
    }

    private void createTablesIfNeeded() throws SQLException {
        try (Statement stmt = connection.createStatement()) {
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS tokens (
                  token TEXT PRIMARY KEY,
                  user_id TEXT NOT NULL,
                  saved_at INTEGER NOT NULL
                )
                """);
        }
    }

    /**
     * Register a device token for a user
     */
    public void registerToken(String userId, String deviceToken) {
        if (userId == null || userId.isEmpty()) {
            throw new IllegalArgumentException("userId cannot be null or empty");
        }
        if (deviceToken == null || deviceToken.isEmpty()) {
            throw new IllegalArgumentException("deviceToken cannot be null or empty");
        }

        final String sql = "INSERT INTO tokens (token, user_id, saved_at) VALUES (?, ?, ?) " +
                "ON CONFLICT(token) DO UPDATE SET user_id = excluded.user_id, saved_at = excluded.saved_at";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, deviceToken);
            ps.setString(2, userId);
            ps.setLong(3, System.currentTimeMillis());
            ps.executeUpdate();
            LOGGER.info(String.format("Registered token for user %s", userId));
        } catch (SQLException e) {
            throw new IllegalArgumentException("Failed to persist token: " + e.getMessage(), e);
        }
    }

    /**
     * Unregister a device token
     */
    public boolean unregisterToken(String deviceToken) {
        if (deviceToken == null || deviceToken.isEmpty()) {
            return false;
        }

        final String sql = "DELETE FROM tokens WHERE token = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, deviceToken);
            int rows = ps.executeUpdate();
            LOGGER.info("Unregistered token: " + deviceToken);
            return rows > 0;
        } catch (SQLException e) {
            LOGGER.severe("Failed to unregister token: " + e.getMessage());
            return false;
        }
    }

    /**
     * Get all tokens for a specific user
     */
    public List<String> getTokensForUser(String userId) {
        if (userId == null || userId.isEmpty()) {
            return Collections.emptyList();
        }

        final String sql = "SELECT token FROM tokens WHERE user_id = ?";
        List<String> result = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(rs.getString("token"));
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to fetch tokens for user " + userId + ": " + e.getMessage());
        }
        return result;
    }

    /**
     * Get userId for a specific token
     */
    public String getUserIdForToken(String deviceToken) {
        final String sql = "SELECT user_id FROM tokens WHERE token = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, deviceToken);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("user_id");
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to fetch user for token: " + e.getMessage());
        }
        return null;
    }

    /**
     * Get all registered tokens (for broadcast scenarios)
     */
    public List<String> getAllTokens() {
        final String sql = "SELECT token FROM tokens";
        List<String> result = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(rs.getString("token"));
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to fetch all tokens: " + e.getMessage());
        }
        return result;
    }

    /**
     * Get total number of registered users
     */
    public int getUserCount() {
        final String sql = "SELECT COUNT(DISTINCT user_id) AS cnt FROM tokens";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to count users: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Get total number of registered tokens
     */
    public int getTokenCount() {
        final String sql = "SELECT COUNT(*) AS cnt FROM tokens";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to count tokens: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Clear all tokens (for testing/admin purposes)
     */
    public void clearAll() {
        try (Statement stmt = connection.createStatement()) {
            stmt.executeUpdate("DELETE FROM tokens");
            LOGGER.info("Cleared all device tokens from storage");
        } catch (SQLException e) {
            LOGGER.severe("Failed to clear tokens: " + e.getMessage());
        }
    }
}
