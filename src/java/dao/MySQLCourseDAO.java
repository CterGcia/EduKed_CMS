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
import model.Course;
import model.Schedule;

public class MySQLCourseDAO {

    private Connection getConnection() throws SQLException {
        if (DatabaseConfig.mysqlUrl == null) {
            throw new SQLException("MySQL URL is not initialized.");
        }
        return DriverManager.getConnection(DatabaseConfig.mysqlUrl, DatabaseConfig.mysqlUser, DatabaseConfig.mysqlPassword);
    }

    public List<Course> getAllCourses() throws SQLException {
        List<Course> list = new ArrayList<>();
        String sql = "SELECT * FROM VIEWTABLE_FOR_COURSES ORDER BY course_code ASC";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Course c = new Course();
                c.setCourseId(rs.getInt("course_id"));
                c.setCourseCode(rs.getString("course_code"));
                c.setTitle(rs.getString("title"));
                c.setDescription(rs.getString("description"));
                c.setUnits(rs.getInt("units"));
                c.setDayName(rs.getString("day_name"));
                c.setFormattedSchedule(rs.getString("formatted_schedule"));
                c.setRoom(rs.getString("room"));
                c.setInstructorName(rs.getString("instructor_name"));
                list.add(c);
            }
        }
        return list;
    }

    public boolean addCourse(String courseCode, String title, String description, int units, Integer scheduleId, Integer instructorId) throws SQLException {
        String sql = "INSERT INTO Courses (course_code, title, description, units, schedule_id, instructor_id) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, courseCode);
            pstmt.setString(2, title);
            pstmt.setString(3, description);
            pstmt.setInt(4, units);
            if (scheduleId != null) pstmt.setInt(5, scheduleId); else pstmt.setNull(5, Types.INTEGER);
            if (instructorId != null) pstmt.setInt(6, instructorId); else pstmt.setNull(6, Types.INTEGER);
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean updateCourse(int courseId, String courseCode, String title, String description, int units, Integer scheduleId, Integer instructorId) throws SQLException {
        String sql = "UPDATE Courses SET course_code = ?, title = ?, description = ?, units = ?, schedule_id = ?, instructor_id = ? WHERE course_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, courseCode);
            pstmt.setString(2, title);
            pstmt.setString(3, description);
            pstmt.setInt(4, units);
            if (scheduleId != null) pstmt.setInt(5, scheduleId); else pstmt.setNull(5, Types.INTEGER);
            if (instructorId != null) pstmt.setInt(6, instructorId); else pstmt.setNull(6, Types.INTEGER);
            pstmt.setInt(7, courseId);
            return pstmt.executeUpdate() > 0;
        }
    }

    public boolean deleteCourse(int courseId) throws SQLException {
        String sql = "DELETE FROM Courses WHERE course_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, courseId);
            return pstmt.executeUpdate() > 0;
        }
    }

    public List<Schedule> getAllSchedules() throws SQLException {
        List<Schedule> list = new ArrayList<>();
        String sql = "SELECT * FROM Schedules ORDER BY day_of_week, start_time";
        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Schedule s = new Schedule();
                s.setScheduleId(rs.getInt("schedule_id"));
                s.setDayOfWeek(rs.getInt("day_of_week"));
                s.setStartTime(rs.getTime("start_time"));
                s.setEndTime(rs.getTime("end_time"));
                s.setRoom(rs.getString("room"));
                list.add(s);
            }
        }
        return list;
    }
}
