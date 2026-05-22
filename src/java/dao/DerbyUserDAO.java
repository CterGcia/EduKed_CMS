package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import config.DatabaseConfig;
import exceptions.AuthenticationException;
import model.User;

public class DerbyUserDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.derbyUrl == null) {
            throw new SQLException("Derby URL is not initialized.");
        }
        try {
            System.out.println("[DEBUG] DerbyUserDAO: attempting connection to: " + DatabaseConfig.derbyUrl);
            Connection conn;
            if (DatabaseConfig.derbyUser != null && DatabaseConfig.derbyPassword != null) {
                System.out.println("[DEBUG] DerbyUserDAO: using credentials user=" + DatabaseConfig.derbyUser);
                conn = DriverManager.getConnection(DatabaseConfig.derbyUrl, DatabaseConfig.derbyUser, DatabaseConfig.derbyPassword);
            } else {
                conn = DriverManager.getConnection(DatabaseConfig.derbyUrl);
            }
            System.out.println("[DEBUG] DerbyUserDAO: connection established");
            return conn;
        } catch (SQLException e) {
            System.err.println("[ERROR] DerbyUserDAO: connection failed: " + e.getMessage());
            throw e;
        }
    }

    public User authenticate(String username, String passwordHash) throws AuthenticationException, SQLException {
        String sql = "SELECT user_id, username, password, role, created_at FROM Users WHERE username = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username != null ? username.trim() : "");
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    String dbPass = rs.getString("password");
                    if (dbPass.equals(passwordHash)) {
                        User user = new User();
                        user.setUserId(rs.getInt("user_id"));
                        user.setUsername(rs.getString("username"));
                        user.setRole(rs.getString("role"));
                        user.setCreatedAt(rs.getTimestamp("created_at"));
                        return user;
                    } else {
                        throw new AuthenticationException("Incorrect password for user: " + username);
                    }
                } else {
                    throw new AuthenticationException("Username not found: " + username);
                }
            }
        }
    }

    public boolean changePassword(String username, String oldPasswordHash, String newPasswordHash) throws SQLException, AuthenticationException {
        // Authenticate first to verify old password
        authenticate(username, oldPasswordHash);
        
        String sql = "UPDATE Users SET password = ? WHERE username = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, newPasswordHash);
            pstmt.setString(2, username);
            return pstmt.executeUpdate() > 0;
        }
    }

    public List<User> getAllUsers() throws SQLException {
        List<User> list = new ArrayList<>();
        String sql = "SELECT user_id, username, role, created_at FROM Users ORDER BY username ASC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_id"));
                user.setUsername(rs.getString("username"));
                user.setRole(rs.getString("role"));
                user.setCreatedAt(rs.getTimestamp("created_at"));
                list.add(user);
            }
        }
        return list;
    }

    public boolean addUser(String username, String passwordHash, String role) throws SQLException {
        String sql = "INSERT INTO Users (username, password, role) VALUES (?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username.trim());
            pstmt.setString(2, passwordHash);
            pstmt.setString(3, role.trim().toLowerCase());
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean updateUser(String username, String passwordHash, String role) throws SQLException {
        String sql;
        if (passwordHash != null && !passwordHash.trim().isEmpty()) {
            sql = "UPDATE Users SET password = ?, role = ? WHERE username = ?";
        } else {
            sql = "UPDATE Users SET role = ? WHERE username = ?";
        }
        
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            if (passwordHash != null && !passwordHash.trim().isEmpty()) {
                pstmt.setString(1, passwordHash);
                pstmt.setString(2, role.trim().toLowerCase());
                pstmt.setString(3, username.trim());
            } else {
                pstmt.setString(1, role.trim().toLowerCase());
                pstmt.setString(2, username.trim());
            }
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean deleteUser(String username) throws SQLException {
        // We must delete the sessions first if needed, or foreign key will prevent it.
        // Actually, we can delete the sessions first in a transaction:
        try (Connection conn = getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Get user ID
                int userId = -1;
                try (PreparedStatement p1 = conn.prepareStatement("SELECT user_id FROM Users WHERE username = ?")) {
                    p1.setString(1, username);
                    try (ResultSet rs = p1.executeQuery()) {
                        if (rs.next()) userId = rs.getInt("user_id");
                    }
                }
                
                if (userId != -1) {
                    // Delete sessions
                    try (PreparedStatement p2 = conn.prepareStatement("DELETE FROM Sessions WHERE user_id = ?")) {
                        p2.setInt(1, userId);
                        p2.executeUpdate();
                    }
                    // Delete user
                    try (PreparedStatement p3 = conn.prepareStatement("DELETE FROM Users WHERE user_id = ?")) {
                        p3.setInt(1, userId);
                        p3.executeUpdate();
                    }
                }
                conn.commit();
                return true;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }
}
