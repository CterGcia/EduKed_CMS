package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import config.DatabaseConfig;
import model.Student;

public class MySQLStudentDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.mysqlUrl == null) {
            throw new SQLException("MySQL URL is not initialized.");
        }
        return DriverManager.getConnection(DatabaseConfig.mysqlUrl, DatabaseConfig.mysqlUser, DatabaseConfig.mysqlPassword);
    }

    public List<Student> getAllStudents() throws SQLException {
        List<Student> list = new ArrayList<>();
        String sql = "SELECT * FROM VIEWTABLE_FOR_STUDENTS ORDER BY last_name ASC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Student s = new Student();
                s.setStudentId(rs.getInt("student_id"));
                s.setStudentNo(rs.getString("student_no"));
                s.setLastName(rs.getString("last_name"));
                s.setFirstName(rs.getString("first_name"));
                s.setStudentName(rs.getString("student_name"));
                s.setEmail(rs.getString("email"));
                s.setYearLevel(rs.getInt("year_level"));
                s.setProgram(rs.getString("program"));
                list.add(s);
            }
        }
        return list;
    }

    public boolean addStudent(String studentNo, String lastName, String firstName, String email, int yearLevel, String program) throws SQLException {
        String sql = "INSERT INTO Students (student_no, last_name, first_name, email, year_level, program) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, studentNo.trim());
            pstmt.setString(2, lastName.trim());
            pstmt.setString(3, firstName.trim());
            pstmt.setString(4, email.trim());
            pstmt.setInt(5, yearLevel);
            pstmt.setString(6, program.trim());
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean updateStudent(int studentId, String studentNo, String lastName, String firstName, String email, int yearLevel, String program) throws SQLException {
        String sql = "UPDATE Students SET student_no = ?, last_name = ?, first_name = ?, email = ?, year_level = ?, program = ? WHERE student_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, studentNo.trim());
            pstmt.setString(2, lastName.trim());
            pstmt.setString(3, firstName.trim());
            pstmt.setString(4, email.trim());
            pstmt.setInt(5, yearLevel);
            pstmt.setString(6, program.trim());
            pstmt.setInt(7, studentId);
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean deleteStudent(int studentId) throws SQLException {
        String sql = "DELETE FROM Students WHERE student_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, studentId);
            return pstmt.executeUpdate() > 0;
        }
    }
}
