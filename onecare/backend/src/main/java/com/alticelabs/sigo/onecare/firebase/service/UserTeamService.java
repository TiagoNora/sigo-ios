package com.alticelabs.sigo.onecare.firebase.service;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.logging.Logger;

@ApplicationScoped
public class UserTeamService {

    private static final Logger LOGGER = Logger.getLogger(UserTeamService.class.getName());

    private static final String DB_FILENAME = "tokens.db"; // Reuse same database
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
            LOGGER.info("UserTeamService initialized with SQLite at " + dbPath);
        } catch (Exception e) {
            LOGGER.severe("Failed to initialize SQLite user-team storage: " + e.getMessage());
            throw new IllegalStateException("Cannot initialize user-team storage", e);
        }
    }

    private void createTablesIfNeeded() throws SQLException {
        try (Statement stmt = connection.createStatement()) {
            stmt.execute("""
                CREATE TABLE IF NOT EXISTS user_teams (
                  user_id TEXT NOT NULL,
                  team_id TEXT NOT NULL,
                  added_at INTEGER NOT NULL,
                  PRIMARY KEY (user_id, team_id)
                )
                """);

            // Create indexes for efficient lookups
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_user_teams_user ON user_teams(user_id)");
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_user_teams_team ON user_teams(team_id)");

            LOGGER.info("User-team tables created/verified successfully");
        }
    }

    /**
     * Add a user to a team
     */
    public void addUserToTeam(String userId, String teamId) {
        if (userId == null || userId.isEmpty()) {
            throw new IllegalArgumentException("userId cannot be null or empty");
        }
        if (teamId == null || teamId.isEmpty()) {
            throw new IllegalArgumentException("teamId cannot be null or empty");
        }

        final String sql = "INSERT INTO user_teams (user_id, team_id, added_at) VALUES (?, ?, ?) " +
                "ON CONFLICT(user_id, team_id) DO UPDATE SET added_at = excluded.added_at";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, teamId);
            ps.setLong(3, System.currentTimeMillis());
            ps.executeUpdate();
            LOGGER.info(String.format("Added user %s to team %s", userId, teamId));
        } catch (SQLException e) {
            throw new IllegalArgumentException("Failed to add user to team: " + e.getMessage(), e);
        }
    }

    /**
     * Remove a user from a team
     */
    public boolean removeUserFromTeam(String userId, String teamId) {
        if (userId == null || userId.isEmpty() || teamId == null || teamId.isEmpty()) {
            return false;
        }

        final String sql = "DELETE FROM user_teams WHERE user_id = ? AND team_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, teamId);
            int rows = ps.executeUpdate();
            if (rows > 0) {
                LOGGER.info(String.format("Removed user %s from team %s", userId, teamId));
            }
            return rows > 0;
        } catch (SQLException e) {
            LOGGER.severe("Failed to remove user from team: " + e.getMessage());
            return false;
        }
    }

    /**
     * Get all users in a specific team
     */
    public List<String> getUsersInTeam(String teamId) {
        if (teamId == null || teamId.isEmpty()) {
            return new ArrayList<>();
        }

        final String sql = "SELECT user_id FROM user_teams WHERE team_id = ?";
        List<String> result = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(rs.getString("user_id"));
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to fetch users for team " + teamId + ": " + e.getMessage());
        }
        return result;
    }

    /**
     * Get all users in multiple teams (union)
     */
    public Set<String> getUsersInTeams(List<String> teamIds) {
        if (teamIds == null || teamIds.isEmpty()) {
            return new HashSet<>();
        }

        Set<String> allUsers = new HashSet<>();
        for (String teamId : teamIds) {
            allUsers.addAll(getUsersInTeam(teamId));
        }
        return allUsers;
    }

    /**
     * Get all teams for a specific user
     */
    public List<String> getTeamsForUser(String userId) {
        if (userId == null || userId.isEmpty()) {
            return new ArrayList<>();
        }

        final String sql = "SELECT team_id FROM user_teams WHERE user_id = ?";
        List<String> result = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(rs.getString("team_id"));
                }
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to fetch teams for user " + userId + ": " + e.getMessage());
        }
        return result;
    }

    /**
     * Check if a user is in a specific team
     */
    public boolean isUserInTeam(String userId, String teamId) {
        if (userId == null || userId.isEmpty() || teamId == null || teamId.isEmpty()) {
            return false;
        }

        final String sql = "SELECT 1 FROM user_teams WHERE user_id = ? AND team_id = ? LIMIT 1";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, teamId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to check user-team membership: " + e.getMessage());
            return false;
        }
    }

    /**
     * Get total number of teams
     */
    public int getTeamCount() {
        final String sql = "SELECT COUNT(DISTINCT team_id) AS cnt FROM user_teams";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to count teams: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Get total number of user-team memberships
     */
    public int getMembershipCount() {
        final String sql = "SELECT COUNT(*) AS cnt FROM user_teams";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to count memberships: " + e.getMessage());
        }
        return 0;
    }

    /**
     * Remove all memberships for a user (e.g., when user leaves organization)
     */
    public int removeUserFromAllTeams(String userId) {
        if (userId == null || userId.isEmpty()) {
            return 0;
        }

        final String sql = "DELETE FROM user_teams WHERE user_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, userId);
            int rows = ps.executeUpdate();
            LOGGER.info(String.format("Removed user %s from %d teams", userId, rows));
            return rows;
        } catch (SQLException e) {
            LOGGER.severe("Failed to remove user from all teams: " + e.getMessage());
            return 0;
        }
    }

    /**
     * Remove all users from a team (e.g., when team is deleted)
     */
    public int removeAllUsersFromTeam(String teamId) {
        if (teamId == null || teamId.isEmpty()) {
            return 0;
        }

        final String sql = "DELETE FROM user_teams WHERE team_id = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, teamId);
            int rows = ps.executeUpdate();
            LOGGER.info(String.format("Removed %d users from team %s", rows, teamId));
            return rows;
        } catch (SQLException e) {
            LOGGER.severe("Failed to remove all users from team: " + e.getMessage());
            return 0;
        }
    }

    /**
     * Clear all user-team memberships (for testing/admin purposes)
     */
    public void clearAll() {
        try (Statement stmt = connection.createStatement()) {
            stmt.executeUpdate("DELETE FROM user_teams");
            LOGGER.info("Cleared all user-team memberships from storage");
        } catch (SQLException e) {
            LOGGER.severe("Failed to clear user-team memberships: " + e.getMessage());
        }
    }

    /**
     * Batch add users to a team (more efficient for bulk operations)
     */
    public void addUsersToTeam(List<String> userIds, String teamId) {
        if (userIds == null || userIds.isEmpty() || teamId == null || teamId.isEmpty()) {
            return;
        }

        final String sql = "INSERT INTO user_teams (user_id, team_id, added_at) VALUES (?, ?, ?) " +
                "ON CONFLICT(user_id, team_id) DO UPDATE SET added_at = excluded.added_at";

        try {
            connection.setAutoCommit(false);
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                long timestamp = System.currentTimeMillis();
                for (String userId : userIds) {
                    ps.setString(1, userId);
                    ps.setString(2, teamId);
                    ps.setLong(3, timestamp);
                    ps.addBatch();
                }
                ps.executeBatch();
                connection.commit();
                LOGGER.info(String.format("Added %d users to team %s", userIds.size(), teamId));
            } catch (SQLException e) {
                connection.rollback();
                throw e;
            } finally {
                connection.setAutoCommit(true);
            }
        } catch (SQLException e) {
            LOGGER.severe("Failed to batch add users to team: " + e.getMessage());
            throw new IllegalArgumentException("Failed to batch add users to team", e);
        }
    }
}
