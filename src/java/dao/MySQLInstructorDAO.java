package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import config.DatabaseConfig;
import model.Instructor;

public class MySQLInstructorDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.mysqlUrl == null) {
            throw new SQLException("MySQL URL is not initialized.");
        }
        return DriverManager.getConnection(DatabaseConfig.mysqlUrl, DatabaseConfig.mysqlUser, DatabaseConfig.mysqlPassword);
    }

    public List<Instructor> getAllInstructors() throws SQLException {
        List<Instructor> list = new ArrayList<>();
        String sql = "SELECT * FROM VIEWTABLE_FOR_INSTRUCTORS ORDER BY last_name ASC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Instructor i = new Instructor();
                i.setInstructorId(rs.getInt("instructor_id"));
                i.setLastName(rs.getString("last_name"));
                i.setFirstName(rs.getString("first_name"));
                i.setDepartment(rs.getString("department"));
                i.setCoursesTaught(rs.getString("courses_taught"));
                list.add(i);
            }
        }
        return list;
    }

    public boolean addInstructor(String lastName, String firstName, String department, Integer userId) throws SQLException {
        String sql = "INSERT INTO Instructors (last_name, first_name, department, user_id) VALUES (?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, lastName.trim());
            pstmt.setString(2, firstName.trim());
            pstmt.setString(3, department.trim());
            if (userId != null) pstmt.setInt(4, userId); else pstmt.setNull(4, Types.INTEGER);
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean updateInstructor(int instructorId, String lastName, String firstName, String department, Integer userId) throws SQLException {
        String sql = "UPDATE Instructors SET last_name = ?, first_name = ?, department = ?, user_id = ? WHERE instructor_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, lastName.trim());
            pstmt.setString(2, firstName.trim());
            pstmt.setString(3, department.trim());
            if (userId != null) pstmt.setInt(4, userId); else pstmt.setNull(4, Types.INTEGER);
            pstmt.setInt(5, instructorId);
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean deleteInstructor(int instructorId) throws SQLException {
        String sql = "DELETE FROM Instructors WHERE instructor_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, instructorId);
            return pstmt.executeUpdate() > 0;
        }
    }
}
