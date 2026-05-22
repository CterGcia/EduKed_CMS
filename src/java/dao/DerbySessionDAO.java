package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import config.DatabaseConfig;
import model.UserSession;

public class DerbySessionDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.derbyUrl == null) {
            throw new SQLException("Derby URL is not initialized.");
        }
        try {
            System.out.println("[DEBUG] DerbySessionDAO: attempting connection to: " + DatabaseConfig.derbyUrl);
            Connection conn;
            if (DatabaseConfig.derbyUser != null && DatabaseConfig.derbyPassword != null) {
                System.out.println("[DEBUG] DerbySessionDAO: using credentials user=" + DatabaseConfig.derbyUser);
                conn = DriverManager.getConnection(DatabaseConfig.derbyUrl, DatabaseConfig.derbyUser, DatabaseConfig.derbyPassword);
            } else {
                conn = DriverManager.getConnection(DatabaseConfig.derbyUrl);
            }
            System.out.println("[DEBUG] DerbySessionDAO: connection established");
            return conn;
        } catch (SQLException e) {
            System.err.println("[ERROR] DerbySessionDAO: connection failed: " + e.getMessage());
            throw e;
        }
    }

    public int createSession(int userId) throws SQLException {
        String sql = "INSERT INTO Sessions (user_id, login_time) VALUES (?, CURRENT_TIMESTAMP)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setInt(1, userId);
            pstmt.executeUpdate();
            
            try (ResultSet rs = pstmt.getGeneratedKeys()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return -1;
    }

    public boolean endSession(int sessionId) throws SQLException {
        String sql = "UPDATE Sessions SET logout_time = CURRENT_TIMESTAMP WHERE session_id = ? AND logout_time IS NULL";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, sessionId);
            return pstmt.executeUpdate() > 0;
        }
    }

    public List<UserSession> getSessionHistory(int userId) throws SQLException {
        List<UserSession> history = new ArrayList<>();
        String sql = "SELECT s.session_id, s.user_id, s.login_time, s.logout_time, u.username " +
                     "FROM Sessions s " +
                     "JOIN Users u ON s.user_id = u.user_id " +
                     "WHERE s.user_id = ? " +
                     "ORDER BY s.login_time DESC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    UserSession us = new UserSession();
                    us.setSessionId(rs.getInt("session_id"));
                    us.setUserId(rs.getInt("user_id"));
                    us.setUsername(rs.getString("username"));
                    us.setLoginTime(rs.getTimestamp("login_time"));
                    us.setLogoutTime(rs.getTimestamp("logout_time"));
                    history.add(us);
                }
            }
        }
        return history;
    }
}
