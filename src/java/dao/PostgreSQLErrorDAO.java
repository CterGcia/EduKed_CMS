package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import config.DatabaseConfig;
import model.ErrorLog;

public class PostgreSQLErrorDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.postgresUrl == null) {
            throw new SQLException("PostgreSQL URL is not initialized.");
        }
        try {
            System.out.println("[DEBUG] PostgreSQLErrorDAO: attempting connection to: " + DatabaseConfig.postgresUrl + " user: " + DatabaseConfig.postgresUser);
            Connection conn = DriverManager.getConnection(DatabaseConfig.postgresUrl, DatabaseConfig.postgresUser, DatabaseConfig.postgresPassword);
            System.out.println("[DEBUG] PostgreSQLErrorDAO: connection established");
            return conn;
        } catch (SQLException e) {
            System.err.println("[ERROR] PostgreSQLErrorDAO: connection failed: " + e.getMessage());
            throw e;
        }
    }

    public void logError(String errorCode, String message, String stack) {
        String sql = "INSERT INTO ErrorLogs (error_code, message, stack, timestamp) VALUES (?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, errorCode);
            pstmt.setString(2, message);
            pstmt.setString(3, stack);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("Failed to log error to PostgreSQL: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public List<ErrorLog> getErrorLogs() throws SQLException {
        List<ErrorLog> list = new ArrayList<>();
        String sql = "SELECT * FROM ErrorLogs ORDER BY timestamp DESC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                ErrorLog e = new ErrorLog();
                e.setErrorId(rs.getLong("error_id"));
                e.setErrorCode(rs.getString("error_code"));
                e.setMessage(rs.getString("message"));
                e.setStack(rs.getString("stack"));
                e.setTimestamp(rs.getTimestamp("timestamp"));
                list.add(e);
            }
        }
        return list;
    }

    public List<ErrorLog> getErrorLogsFiltered(Timestamp start, Timestamp end) throws SQLException {
        List<ErrorLog> list = new ArrayList<>();
        String sql = "SELECT * FROM ErrorLogs WHERE timestamp BETWEEN ? AND ? ORDER BY timestamp DESC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, start);
            pstmt.setTimestamp(2, end);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ErrorLog e = new ErrorLog();
                    e.setErrorId(rs.getLong("error_id"));
                    e.setErrorCode(rs.getString("error_code"));
                    e.setMessage(rs.getString("message"));
                    e.setStack(rs.getString("stack"));
                    e.setTimestamp(rs.getTimestamp("timestamp"));
                    list.add(e);
                }
            }
        }
        return list;
    }
}
