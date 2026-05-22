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
import model.ReportLog;

public class PostgreSQLAuditDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.postgresUrl == null) {
            throw new SQLException("PostgreSQL URL is not initialized.");
        }
        try {
            System.out.println("[DEBUG] PostgreSQLAuditDAO: attempting connection to: " + DatabaseConfig.postgresUrl + " user: " + DatabaseConfig.postgresUser);
            Connection conn = DriverManager.getConnection(DatabaseConfig.postgresUrl, DatabaseConfig.postgresUser, DatabaseConfig.postgresPassword);
            System.out.println("[DEBUG] PostgreSQLAuditDAO: connection established");
            return conn;
        } catch (SQLException e) {
            System.err.println("[ERROR] PostgreSQLAuditDAO: connection failed: " + e.getMessage());
            throw e;
        }
    }

    public void logReport(String generatedBy, String reportType, String filename) {
        String sql = "INSERT INTO ReportLogs (generated_by, report_type, filename, generated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, generatedBy);
            pstmt.setString(2, reportType);
            pstmt.setString(3, filename);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.err.println("Audit trail log write failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public List<ReportLog> getReportLogs() throws SQLException {
        List<ReportLog> list = new ArrayList<>();
        String sql = "SELECT * FROM ReportLogs ORDER BY generated_at DESC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                ReportLog r = new ReportLog();
                r.setReportId(rs.getLong("report_id"));
                r.setGeneratedBy(rs.getString("generated_by"));
                r.setReportType(rs.getString("report_type"));
                r.setFilename(rs.getString("filename"));
                r.setGeneratedAt(rs.getTimestamp("generated_at"));
                list.add(r);
            }
        }
        return list;
    }

    public List<ReportLog> getReportLogsFiltered(Timestamp start, Timestamp end) throws SQLException {
        List<ReportLog> list = new ArrayList<>();
        String sql = "SELECT * FROM ReportLogs WHERE generated_at BETWEEN ? AND ? ORDER BY generated_at DESC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setTimestamp(1, start);
            pstmt.setTimestamp(2, end);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    ReportLog r = new ReportLog();
                    r.setReportId(rs.getLong("report_id"));
                    r.setGeneratedBy(rs.getString("generated_by"));
                    r.setReportType(rs.getString("report_type"));
                    r.setFilename(rs.getString("filename"));
                    r.setGeneratedAt(rs.getTimestamp("generated_at"));
                    list.add(r);
                }
            }
        }
        return list;
    }
}
